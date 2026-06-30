# tgcalls Library

The tgcalls VoIP library source. See the root `CLAUDE.md` for build instructions and the project overview.

## macOS Build Support

This repo has been patched to support native macOS arm64 builds (`darwin_arm64` CPU) in addition to the original iOS targets. Changes made:
- `third-party/webrtc/BUILD` — added `@platforms//os:linux` to `arch_specific_cflags` select (fixes macOS getting Linux flags via `//conditions:default`); moved `cocoa_threading.mm` from `cc_library` to `webrtc_platform_helpers` `objc_library` (Bazel 8 rejects `.mm` in `cc_library`); replaced UIKit with AppKit for macOS
- `third-party/openh264/BUILD` — added `//conditions:default` to `select()` statements
- `third-party/webrtc/absl/absl/base/attributes.h` — disabled `ABSL_ATTRIBUTE_LIFETIME_BOUND` (newer Xcode clang rejects it on void-returning functions)
- 8 third-party BUILD files + 8 build shell scripts — added `darwin_arm64 -> macos_arm64` architecture support (opus, libvpx, ffmpeg, dav1d, mozjpeg, webp, libjxl, td)

## Linux Build Support

The repo supports native Linux arm64 and x86_64 builds. Key changes from the iOS/macOS-only baseline:
- `.bazelrc` — Apple toolchain settings under `build:macos`, Linux uses default CC toolchain via `build:linux` (auto-selected by `--enable_platform_specific_config`)
- `build-system/BUILD` — `linux_arm64` and `linux_x86_64` config_settings
- `objc_library` → `cc_library` conversions for pure C/C++ targets (ogg, opusfile, rnnoise, opus, libvpx, dav1d, ffmpeg wrappers, WebRTC main target)
- WebRTC BUILD — platform flags via `select()` (`-DWEBRTC_LINUX` vs `-DWEBRTC_MAC`), stdlib task queue instead of GCD on Linux, macOS-only sources excluded
- Third-party genrule build scripts — Linux architecture cases added (libvpx, dav1d, ffmpeg), system cmake/meson/ninja used instead of downloaded macOS binaries
- BoringSSL — `_Generic` C11 guarded for C++ mode (GCC compatibility)
- tgcalls headers — `#include <cstdint>` added for GCC 15 strictness

## SCTP Signaling

### Writable Gate (role-based handshake ordering)

tgcalls uses a custom SCTP association (via dc-sctp) over the signaling channel for reliable message delivery. `SignalingSctpConnection` wraps `DcSctpTransport` with a `SignalingPacketTransport` shim.

The SCTP handshake is ordered using DcSctpTransport's writable gate (`MaybeConnectSocket()`), mirroring how WebRTC PeerConnection uses DTLS writable state to control SCTP connection timing:

- **Caller** (`isOutgoing=true`): `SignalingPacketTransport` starts writable → `Connect()` fires immediately → sends INIT
- **Callee** (`isOutgoing=false`): starts not-writable → `Connect()` deferred → on first `receiveExternal()`, `setWritable(true)` fires `SignalWritableState` → `MaybeConnectSocket()` → `Connect()`

The callee's `Connect()` and processing of the caller's INIT happen synchronously within the same `BlockingCall` on the network thread (RFC 4960 §5.2.1 simultaneous-open).

Key files:
- `SignalingSctpConnection.cpp` — `SignalingPacketTransport` writable state, `setWritable()`, constructor takes `isInitiator`
- `InstanceV2Impl.cpp` / `InstanceV2ReferenceImpl.cpp` — pass `_encryptionKey.isOutgoing` as `isInitiator`
- `third-party/webrtc/webrtc/media/sctp/dcsctp_transport.cc:662-667` — `MaybeConnectSocket()` gate (unmodified)

### Timer Tuning (CustomDcSctpSocket)

WebRTC's stock `DcSctpSocket` has a bug: `max_timer_backoff_duration` is wired to the T3-rtx (data retransmission) timer but **not** to the t1_init and t1_cookie (handshake) timers. The handshake timers use unlimited exponential backoff (1000, 2000, 4000, 8000ms...), causing the SCTP handshake to stall for 20+ seconds under packet loss with simultaneous-open (both sides call `Connect()`).

Fix: `CustomDcSctpSocket` (in `tgcalls/v2/`) is a copy of `DcSctpSocket` with the 6-line fix that passes `max_timer_backoff_duration` to the t1_init and t1_cookie timer constructors. A `CustomDcSctpSocketFactory` in `SignalingSctpConnection.cpp` creates it instead of the stock socket, with configurable timer overrides. WebRTC source is **untouched**.

Default signaling SCTP timer values (set in `SignalingSctpConnection::Options`):

| Setting | WebRTC Default | Signaling Override |
|---|---|---|
| `t1_init_timeout` | 1000ms | 400ms |
| `t1_cookie_timeout` | 1000ms | 400ms |
| `max_timer_backoff_duration` | 3000ms | 750ms |
| `max_init_retransmits` | 8 | unlimited (from `DcSctpTransport::Start`) |

Retry pattern: 400ms, 750ms, 750ms, 750ms... (~18 attempts in 15s). At 30% loss, 100% success rate over 5000 runs.

These values are configurable via JSON custom parameters (passed to `InstanceV2Impl` via `config.customParameters`):
- `network_sctp_t1_init_ms` — T1-init timeout (0 = use default 400ms)
- `network_sctp_t1_cookie_ms` — T1-cookie timeout (0 = use default 400ms)
- `network_sctp_max_backoff_ms` — max timer backoff cap (0 = use default 750ms)

Key files:
- `tgcalls/v2/CustomDcSctpSocket.h/.cpp` — patched `DcSctpSocket` copy
- `tgcalls/v2/SignalingSctpConnection.cpp` — `CustomDcSctpSocketFactory`, timer option plumbing
- `tgcalls/v2/InstanceV2Impl.cpp` — reads JSON params, passes `Options` to `SignalingSctpConnection`

## InstanceV2CompatImpl (version 14.0.0)

A cross-version interop implementation that uses WebRTC PeerConnection internally (like InstanceV2ReferenceImpl) but speaks V2Impl's signaling protocol (`InitialSetupMessage`, `NegotiateChannelsMessage`, `CandidatesMessage`). This enables bidirectional calls between PeerConnection-based clients and V2Impl-based clients (versions 7.0.0–13.0.0).

### Architecture

```
PeerConnection <-> SignalingTranslator <-> EncryptedConnection <-> SignalingSctpConnection
```

- **SignalingTranslator** (`tgcalls/v2/SignalingTranslator.h/.cpp`): Converts between `cricket::SessionDescription` (PeerConnection's internal format) and V2Impl signaling messages. Uses `JsepSessionDescription` programmatic API — no SDP string round-trips.
- **Outbound**: PeerConnection generates offer/answer → SignalingTranslator extracts `InitialSetupMessage` (transport params) + `NegotiateChannelsMessage` (media contents)
- **Inbound**: Buffers both messages until complete → builds `cricket::SessionDescription` → wraps in `JsepSessionDescription` → `SetRemoteDescription`

### Key Design Decisions

- **No data channel with V2Impl peers**: WebRTC data channel requires PeerConnection on both sides. V2Impl uses NativeNetworkingImpl (no PeerConnection). When paired with V2Impl, the data channel m-line is padded as `rejected` in the remote answer so PeerConnection accepts it. For CompatImpl↔CompatImpl calls, the data channel works normally.
- **Caller-only renegotiation**: Only the outgoing side triggers offers from `onRenegotiationNeeded` to prevent unsolicited offer storms.
- **MediaState via signaling**: `MediaStateMessage` sent over the SCTP signaling channel (not data channel), ensuring it works with both V2Impl and CompatImpl peers.
- **Sequential content IDs**: Uses "0", "1", ... as m-line mids, matching PeerConnection's default scheme.
- **Shared conversion functions**: `convertContentInfoToSignalingContent()` and `convertSignalingContentToContentInfo()` extracted to `Signaling.h/.cpp` for use by both `ContentNegotiationContext` (V2Impl) and `SignalingTranslator` (CompatImpl).

### Cross-Version Testing

```bash
# CompatImpl caller → V2Impl callee
./bazel-bin/tools/tgcalls_cli/tgcalls_cli --mode p2p --version 14.0.0 --version2 13.0.0 --duration 10 --quiet

# V2Impl caller → CompatImpl callee
./bazel-bin/tools/tgcalls_cli/tgcalls_cli --mode p2p --version 13.0.0 --version2 14.0.0 --duration 10 --quiet

# With lossy signaling
./bazel-bin/tools/tgcalls_cli/tgcalls_cli --mode p2p --version 14.0.0 --version2 13.0.0 --duration 15 --drop-rate 0.3 --delay 50-200 --quiet
```

100% success rate at 30% loss in both directions (tested with 50 sequential + 20 parallel runs each direction).

Key files:
- `tgcalls/v2/InstanceV2CompatImpl.h/.cpp` — main implementation
- `tgcalls/v2/SignalingTranslator.h/.cpp` — cricket↔signaling conversion
- `tgcalls/v2/Signaling.h/.cpp` — shared conversion functions (`convertContentInfoToSignalingContent`, `convertSignalingContentToContentInfo`)

## GroupInstanceCustomImpl (Group Calls)

The group call implementation in `tgcalls/group/GroupInstanceCustomImpl.cpp` (~4700 lines). Uses a client-server model with an SFU, unlike 1:1 calls which are peer-to-peer.

### Protocol Stack
- **Join signaling**: JSON over application layer (`emitJoinPayload` → app sends to SFU → `setJoinResponsePayload`)
- **Transport**: ICE + DTLS-SRTP over UDP (standard WebRTC transport, NOT PeerConnection)
- **Media**: RTP/RTCP with Opus audio (48kHz, 2ch, 32kbps), optional VP8/H264/VP9 video
- **Control**: SCTP data channel over DTLS for Colibri protocol (video constraints, debug messages)

### Join Flow
1. Client calls `emitJoinPayload()` → generates JSON with audio SSRC, ICE ufrag/pwd, DTLS fingerprint
2. Application sends JSON to SFU server
3. Server responds with its ICE candidates, DTLS fingerprint, video codec info
4. Client calls `setJoinResponsePayload(json)` → ICE/DTLS negotiation begins
5. On connection: `networkStateUpdated` callback fires

### Participant Discovery
- Unknown SSRC arrives in RTP → `receiveUnknownSsrcPacket()` → `maybeRequestUnknownSsrc(ssrc)`
- App's `requestMediaChannelDescriptions` callback queries server for SSRC→participant mapping
- `addIncomingAudioChannel(ssrc, userId)` creates decoder channel

### Colibri Data Channel Messages
```json
// SFU → Client
{"colibriClass": "SenderVideoConstraints", "videoConstraints": {"idealHeight": 360}}

// Client → SFU
{"colibriClass": "ReceiverVideoConstraints", "defaultConstraints": {"maxHeight": 0},
 "constraints": {"endpoint1": {"minHeight": 720, "maxHeight": 720}}}
```

### Key Files
- `tgcalls/group/GroupInstanceCustomImpl.h/.cpp` — main implementation
- `tgcalls/group/GroupNetworkManager.h/.cpp` — ICE/DTLS/SRTP transport
- `tgcalls/group/GroupJoinPayloadInternal.h/.cpp` — join JSON serialization

## GroupInstanceReferenceImpl (PeerConnection-based Group Calls)

An alternative group call implementation that uses standard WebRTC PeerConnection instead of the manual ICE/DTLS/SRTP management in `GroupInstanceCustomImpl`. Supports both audio and video (H264 simulcast). Implements the same `GroupInstanceInterface`.

### Architecture

```
GroupInstanceReferenceImpl
  └── PeerConnection (single, to SFU)
        ├── sendrecv audio transceiver (outgoing audio)
        ├── sendonly video transceiver (outgoing H264 simulcast, SDP-munged SSRCs)
        ├── recvonly audio transceivers (one per remote SSRC, added dynamically)
        ├── recvonly video transceivers (one per remote endpoint, added dynamically)
        └── data channel ("data", for ActiveVideoSsrcs and Colibri video constraints)
```

### How It Differs from CustomImpl

| Aspect | CustomImpl | ReferenceImpl |
|--------|-----------|---------------|
| Transport | Manual ICE/DTLS/SRTP via GroupNetworkManager | WebRTC PeerConnection |
| SDP | None (custom JSON protocol) | Local SDP construction, translates to/from JSON |
| SSRC discovery | `unknownSsrcPacketReceived` on raw RTP | Audio: `GRAudioFrameTransformer` on mid=0's unsignaled receiver. Video: `ActiveVideoSsrcs` data channel message from SFU |
| Audio channels | Manual `IncomingAudioChannel` per SSRC | PeerConnection recvonly transceivers |
| Audio levels | RTP header extension parsing | Per-receiver `GRAudioLevelSink` reading real PCM levels |
| Video outgoing | Manual `cricket::VideoChannel` with direct SSRC control | PeerConnection sendonly transceiver + SDP munging for simulcast SSRCs |
| Video incoming | Manual `IncomingVideoChannel` per endpoint | PeerConnection recvonly transceivers with SSRCs in answer |
| Video decode | Manual decoder lifecycle | PeerConnection handles internally |
| Code size | ~4700 lines | ~1500 lines |

### Join Flow (SDP Translation)

1. Create PeerConnection with Opus audio transceiver, sendonly video transceiver (no track), and data channel
2. `createOffer` → munge video SSRCs (replace PeerConnection's auto-generated SSRCs with pre-allocated simulcast SSRCs) → `SetLocalDescription` → extract ICE/DTLS params from local SDP
3. Serialize as JSON (same format as CustomImpl): `{ssrc, ufrag, pwd, fingerprints, ssrc-groups}`
4. Parse SFU response JSON → construct `JsepSessionDescription("answer")` programmatically via `cricket::SessionDescription` API (no SDP string parsing)
5. `SetRemoteDescription` → ICE/DTLS connects via PeerConnection internals
6. Add remote ICE candidates via `AddIceCandidate` after `SetRemoteDescription`
7. Activate outgoing video: attach `FakeVideoTrackSource` track to the existing sendonly transceiver via `sender()->SetTrack()` — no renegotiation needed

### Dynamic Participant Handling

**Audio (per-receiver frame transformer):**
1. The first packet for an unknown SSRC X reaches mid=0's receiver — PeerConnection's catch-all for unsignaled audio. The voice channel creates a `WebRtcAudioReceiveStream` for X and attaches `GRAudioFrameTransformer` (registered as `unsignaled_frame_transformer_` on mid=0).
2. The transformer's `Transform(frame)` reads `frame->GetSsrc() = X`, sees X for the first time, **buffers the frame** in a per-SSRC FIFO, and posts the SSRC to the media thread.
3. `handleDiscoveredAudioSsrc(X)` inserts X into `_remoteSsrcs` with a fresh mid, fires `_requestMediaChannelDescriptions({X}, ...)` (matches CustomImpl's contract), and calls `scheduleDiscoveryRenegotiation()` (250 ms debounce).
4. After the debounce, `renegotiate()` adds a recvonly audio transceiver bound to mid=`_nextMid++` for every entry in `_remoteSsrcs` that doesn't have one. `buildRemoteAnswer` includes X on the new m-line; `WebRtcVoiceReceiveChannel::AddRecvStream(X)` PROMOTES the existing unsignaled stream in place (`webrtc_voice_engine.cc:2258-2266`) — the transformer stays attached.
5. `onRenegotiationComplete` runs `wireRemoteAudioLevelSinks()` (attaches `GRAudioLevelSink` per receiver), then calls `_audioFrameTransformer->releaseSsrc(ssrc)` for every SSRC whose transceiver now has a mid. The transformer drains the per-SSRC FIFO via `OnTransformedFrame` so the buffered audio plays without a startup gap.
6. Subsequent live frames for X take the transformer's `kDrained` branch (immediate passthrough). The per-receiver `GRAudioLevelSink` reads real PCM levels.

The `colibriClass=ActiveAudioSsrcs` data-channel mechanism (test-SFU only) was removed; the tap is the single audio-discovery path. Removed-SSRC handling is the same as CustomImpl: stale recvonly transceivers stay in the SDP indefinitely; participant departures are tracked at the application layer (MTProto).

The transformer is installed once on mid=0's receiver only — re-installing on the recvonly receivers triggers `Register{Sink,}TransformedFrameCallback` re-runs that overwrite valid registrations and misroute frames. Stream promotion keeps the single instance valid for every signaled SSRC.

**Video:**
1. SFU sends `ActiveVideoSsrcs` over data channel → forwarded to app via `dataChannelMessageReceived`
2. App calls `setRequestedVideoChannels()` → adds recvonly video transceivers, sends `ReceiverVideoConstraints` over data channel
3. Renegotiate: new offer → munge outgoing video SSRCs → `SetLocalDescription` → build answer with incoming video SSRCs → `SetRemoteDescription`
4. `wirePendingVideoSinks()`: attach `FakeVideoSink` to the recvonly transceiver's receiver track after `SetRemoteDescription` completes
5. Renegotiations are serialized (`_isRenegotiating` / `_pendingRenegotiation` flags) to prevent overlapping offer/answer cycles

### Outgoing Video: SDP Munging for Simulcast

PeerConnection's API doesn't support SSRC-based simulcast directly (only RID-based, which doesn't put SSRCs in the SDP). The workaround:

1. Pre-allocate 6 random video SSRCs at construction: 3 layers × (primary + RTX)
2. Add a sendonly video transceiver in `start()` with no track
3. Before `SetLocalDescription`, `mungeVideoSsrcsInOffer()` replaces the video m-line's auto-generated `StreamParams` with our pre-allocated SSRCs + SIM + FID groups
4. `UpdateLocalStreams_w()` in WebRTC's `channel.cc` sees SSRCs already present and skips generation
5. Later, `setVideoSource()` just calls `sender()->SetTrack()` — no renegotiation

### Incoming Video: SSRC-Based Demux

The answer for incoming video m-lines includes remote SSRCs from `VideoChannelDescription.ssrcGroups`. This is required because CustomImpl sets the `WebRTC-Video-DiscardPacketsWithUnknownSsrc` field trial process-wide, which disables unsignaled stream creation. Without explicit SSRCs, PeerConnection drops incoming video packets in mixed groups.

### Key Implementation Details

- **ICE roles**: PeerConnection uses standard ICE (full agent, controlling when remote is ICE-lite). The SFU uses `Accept` for PeerConnection clients vs `Dial` for CustomImpl clients.
- **Loopback**: `PeerConnectionFactory::Options::network_ignore_mask = 0` enables loopback interface gathering for localhost SFU
- **MID exclusion**: The `buildRemoteAnswer()` excludes the `urn:ietf:params:rtp-hdrext:sdes:mid` RTP header extension from ALL m-lines (audio and video). The SFU forwards raw RTP with the sender's MID value, which would cause the BUNDLE demuxer to route packets to the wrong channel. Without MID, PeerConnection falls back to SSRC/PT-based routing.
- **RTP header extensions**: Copied from the local offer per m-line (minus MID), ensuring BUNDLE-safe IDs. Hardcoding IDs risks collisions across the BUNDLE group.
- **SDP mid matching**: During renegotiation, the constructed remote answer mirrors the local offer's m-line structure and mids exactly. Mismatched mids cause `SetRemoteDescription` to fail.
- **Audio level reporting**: Uses synthetic levels (0.1) for all known remote SSRCs, since the SFU forwards RTP with extension IDs that may not match PeerConnection's negotiated mapping
- **Video sink wiring**: `OnTrack` doesn't fire for locally-created recvonly transceivers. Sinks are wired explicitly in `wirePendingVideoSinks()` after `SetRemoteDescription` completes, and also in `addIncomingVideoOutput()` if the track already exists.
- **H264 codec in answer**: PT 104 (primary) + PT 105 (RTX, apt=104), matching WebRTC's `assignPayloadTypes` order. RTCP feedback: nack, nack pli, ccm fir, goog-remb, transport-cc.
- **Renegotiation serialization**: Only one offer/answer cycle runs at a time. Deferred renegotiations only fire if there are unnegotiated transceivers (no mid assigned yet), avoiding redundant cycles.

### Key Files
- `tgcalls/group/GroupInstanceReferenceImpl.h/.cpp` — implementation
- `tgcalls/group/GroupInstanceImpl.h` — shared `GroupInstanceInterface`

## Video Support Pitfalls

Critical findings from implementing video in the test SFU — relevant for anyone working on group video:

### H264 Decoder Requires Two Build Flags
The WebRTC BUILD needs BOTH `-DWEBRTC_USE_H264` (encoder, OpenH264) AND `-DWEBRTC_USE_H264_DECODER` (decoder, FFmpeg). Without the decoder flag, `H264Decoder::Create()` returns nullptr and WebRTC silently falls back to `NullVideoDecoder` which accepts frames but never decodes them — no error logged. The encoder works fine without the decoder flag, making this easy to miss.

### FFmpeg 7+ Removed `reordered_opaque`
`h264_decoder_impl.cc` uses `AVCodecContext::reordered_opaque` and `AVFrame::reordered_opaque` for passing timestamps through the decode pipeline. FFmpeg 7+ removed this field. The fix uses `AVPacket::pts` instead. IMPORTANT: `AVCodecContext::opaque` is already used to store the `H264DecoderImpl*` pointer (line 74 of `AVGetBuffer2`) — do NOT use it for timestamps.

### Outgoing Video Channel Steals Incoming RTP
`GroupInstanceCustomImpl` creates separate `cricket::VideoChannel` objects for outgoing and incoming video, all sharing the same `RtpTransport`. The outgoing channel's `WebRtcVideoReceiveChannel` has an "unsignalled SSRC" handler that creates default receive streams for unknown SSRCs. When video RTP from other participants arrives before `IncomingVideoChannel` registers its SSRCs, the outgoing channel intercepts the packets permanently. Fix: enable the `WebRTC-Video-DiscardPacketsWithUnknownSsrc` field trial in the field trial string.

### Video Channel Setup Is Reactive, Not Pre-Registered
Video channels are set up reactively when `ActiveVideoSsrcs` arrives via the data channel — same as the real Telegram app. The `dataChannelMessageReceived` callback in `GroupInstanceDescriptor` forwards Colibri messages to the app, which calls `setRequestedVideoChannels`. The `DiscardPacketsWithUnknownSsrc` field trial prevents the outgoing channel from stealing RTP packets for SSRCs not yet registered. The SFU sends proactive PLI after constraints arrive, ensuring keyframes are produced after the incoming channel is ready.

### SFU Must Send Proactive PLI
WebRTC's `VideoReceiveStream2` doesn't immediately request a keyframe when a new receive stream is created — it waits until it detects missing packets or a timeout. The SFU must proactively send PLI to the sender when a receiver first requests video via `ReceiverVideoConstraints`. Without this, the decoder waits indefinitely for a keyframe.

### RTP/RTCP Demux: Marker Bit False Positives
RFC 5761 demux by second byte: RTCP types are 200-211. But RTP with Marker=1 and dynamic PT ≥ 96 gives byte[1] ≥ 224. Using `byte[1] >= 200` falsely classifies H264 RTP (PT=104, M=1 → byte[1]=232) as RTCP. Correct range: `byte[1] >= 200 && byte[1] < 224`.

### SRTCP Requires Separate Contexts from SRTP
Pion's `SessionSRTP` and `SessionSRTCP` can't share the same `net.Conn` (both start read loops that fight for packets). The solution: demux RTCP at the transport level (in `PacketDemux`), create separate `srtp.Context` instances for SRTCP decrypt/encrypt using the same DTLS-extracted keys, and handle RTCP manually without `SessionSRTCP`.

### PeerConnection Simulcast SSRCs Require SDP Munging
PeerConnection's API doesn't support SSRC-based simulcast (only RID-based). With RID-based simulcast, SSRCs are NOT in the `createOffer` SDP — they're generated internally during `SetLocalDescription` and not accessible via `sender->GetParameters()` (only primary SSRCs, not RTX). The workaround: add a single-encoding transceiver (no RIDs), then replace the auto-generated `StreamParams` in the offer with pre-allocated SSRCs + SIM + FID groups before calling `SetLocalDescription`. `UpdateLocalStreams_w()` skips generation when SSRCs already exist. IMPORTANT: `transceiver->mid()` is `nullopt` before `SetLocalDescription` — match by content direction, not mid.

### MID RTP Header Extension Causes Wrong Channel Routing in SFU
The SFU forwards raw RTP packets including all header extensions. If the sender's video RTP includes a MID extension (e.g., MID="1"), the receiver's PeerConnection BUNDLE demuxer routes the packet to its own mid=1 channel — which is the outgoing video, not the incoming video transceiver. Fix: exclude `urn:ietf:params:rtp-hdrext:sdes:mid` from ALL m-lines in `buildRemoteAnswer()`. Without MID negotiated, PeerConnection falls back to SSRC/PT-based routing. This must be done for ALL m-lines (including audio) because the BUNDLE transport shares the extension map across all channels.

### `DiscardPacketsWithUnknownSsrc` Is Process-Wide
CustomImpl calls `field_trial::InitFieldTrialsFromString(...)` which sets `WebRTC-Video-DiscardPacketsWithUnknownSsrc/Enabled/` globally for the process. In mixed groups, this prevents ReferenceImpl's PeerConnection from creating unsignaled receive streams for incoming video. Fix: include explicit remote video SSRCs in the `buildRemoteAnswer()` for incoming video m-lines, so PeerConnection registers SSRC-based demux entries instead of relying on unsignaled stream handling.

### `OnTrack` Doesn't Fire for Locally-Created Recvonly Transceivers
When you call `AddTransceiver(MEDIA_TYPE_VIDEO, {direction=recvonly})`, PeerConnection creates the transceiver and its receiver track immediately. `OnTrack` only fires when a REMOTE-initiated track is added. For locally-created recvonly transceivers, you must wire sinks explicitly after `SetRemoteDescription` completes — don't wait for `OnTrack`.

### SSRC Parsing: json11 int_value() Overflows for uint32 > INT_MAX
`GoSfu_QueryVideoSsrcs` returns SSRCs as `uint32` in JSON. For values > 2^31, json11's `int_value()` (which returns `int`) overflows to `INT_MAX` (2147483647). Fix: use `number_value()` (returns `double`) and cast via `int64_t` to `uint32_t`.

### Join Payload JSON Field Name: `"sources"` Not `"ssrcs"`
tgcalls serializes video SSRC groups in `GroupJoinInternalPayload::serialize()` using the key `"sources"` (not `"ssrcs"`). The Go SFU's JSON struct tags must match: `Sources []int32 \`json:"sources"\``.

### Simulcast Max Layers Depends on Source Resolution, Not Bitrate
WebRTC's `kSimulcastFormats` table in `video/config/simulcast.cc` hardcodes `max_layers` per resolution: 640x360 → 2 layers, 960x540 → 3 layers, 1280x720 → 3 layers. The `SimulcastEncoderAdapter` uses this to cap the number of encoders regardless of available bitrate. If you need 3 simulcast layers, the source must be at least 960x540. The `FakeVideoTrackSource` uses 1280x720 for this reason. With 1280x720 and scale factors /4, /2, /1, the layers are 320x180, 640x360, 1280x720.

### SFU Must Rewrite SSRCs When Switching Simulcast Layers
CustomImpl's `IncomingVideoChannel` calls `SetSink(_mainVideoSsrc, ...)` where `_mainVideoSsrc` is the first SSRC in the SIM group (layer 0). The video sink only receives decoded frames from that specific SSRC's receive stream. When the SFU forwards a higher layer's packets, it must rewrite bytes 8-11 of the RTP header to the primary (layer 0) SSRC. RTX packets must similarly be rewritten to the layer 0 FID SSRC. Without this, higher-layer packets are delivered to the wrong receive stream and produce zero decoded frames. This is standard SFU behavior for simulcast — Jitsi and mediasoup do the same.

### Sender BWE Start Bitrate Determines Initial Layer Count
`adjustBitratePreferences` sets `start_bitrate_bps = max(min_bitrate_bps, 400k)`. At 400kbps start, the `BitrateAllocator` gives L0 (60k) + L1 (110k) = 170k, leaving only 230k for L2 which needs min 300k. Layer 2 is disabled until the GCC ramps up. The SFU's transport-cc feedback enables this ramp-up. The `UpdateAllocationLimits` log shows `total_requested_max_bitrate` — if this is below the sum of all layers' min bitrates, some layers are excluded.

### `assignPayloadTypes` Codec Ordering
WebRTC's `assignPayloadTypes` assigns dynamic PTs starting at 100 in order: VP8 (100/101), VP9 (102/103), H264 (104/105). Both sender and receiver call this independently with the same codec list, so PTs match. The SFU's join response codec PTs (100 for H264 in our case) are used by `configureVideoParams` to SELECT which codec to use, but the actual PT assignment comes from `assignPayloadTypes`.

## Known Issues
- `ThreadLocalObject::~ThreadLocalObject()` posts fire-and-forget cleanup tasks to the tgcalls media thread. If the process does orderly static destruction, the static thread pool may be torn down while these tasks are still executing, causing "pure virtual function called". The CLI tool uses `_exit()` to avoid this. This is not a problem in the real Telegram app.
- `SignalingSctpConnection::OnReadyToSend()` had a missing `break` after the first send failure in its pending-data flush loop. This could cause application-level message reordering (though the application handles it gracefully via `_pendingIceCandidates` buffering). Fixed in our fork.
- `InstanceV2ReferenceImpl::writeStateLogRecords()` had a use-after-free: it captured a raw `Call*` pointer on the media thread and posted it to the worker thread. If `stop()` called `_peerConnection->Close()` (which destroys `Call`) between the post and worker thread execution, the worker thread would dereference a dangling pointer. The `call_ptr_` field in WebRTC's `PeerConnection` is `Call* const` and is never nulled, so the existing null check didn't catch this. Fixed with an `_isStopped` atomic flag checked in the worker thread lambda before accessing `call`. Manifested as ~2% segfault rate under 250-process parallel load; 100% pass rate after fix (5000/5000).
- WebRTC's `RTC_LOG` writes to stdout, not stderr. There is no way to separate it from application output within a single process. The local mass test harness (`run-local-test.sh`) works around this by using separate processes and checking exit codes rather than parsing output.
