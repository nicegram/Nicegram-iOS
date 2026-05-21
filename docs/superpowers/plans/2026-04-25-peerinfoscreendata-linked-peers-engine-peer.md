# Wave 49 — `PeerInfoScreenData.linkedDiscussionPeer` + `.linkedMonoforumPeer` `Peer? → EnginePeer?` (bundle)

**Date:** 2026-04-25
**Predecessor:** Wave 48 (commit `1e4c2eea33`) — savedMessagesPeer single-field migration.
**Shape:** Cross-file bundled struct-field migration (2 sibling fields, 2 files). Both fields are module-internal; no external consumer references them on `PeerInfoScreenData`. Bundled because both fields:
- Share a sibling declaration site in `PeerInfoData.swift`.
- Have parallel local-source patterns (raw `Peer?` from `peerView.peers[id]` dict lookup; **not** an engine signal as in wave 48).
- Are both consumed in `PeerInfoProfileItems.swift` only.
- Migrating one without the other adds friction at the source-construction sites where they're computed together.

## Pre-flight inventory

`grep -rEn "(\w+\??)\.linkedDiscussionPeer\b|(\w+\??)\.linkedMonoforumPeer\b" submodules/ Telegram/`:
- `submodules/PeerInfoUI/Sources/ChannelDiscussionGroupSetupController.swift:600,651` — references are on a local `view` object (different type, NOT PeerInfoScreenData). Out of scope.
- All `data.linkedDiscussionPeer` / `data.linkedMonoforumPeer` accesses live in PIPI within the PeerInfoScreen module.

Within scope:

### `PeerInfoData.swift` (storage class + 2 init sites that compute the locals)

| Site | Code | Action |
|------|------|--------|
| :396 | `let linkedDiscussionPeer: Peer?` (field decl) | Type → `EnginePeer?` |
| :397 | `let linkedMonoforumPeer: Peer?` (field decl) | Type → `EnginePeer?` |
| :453 | `linkedDiscussionPeer: Peer?,` (init param) | Type → `EnginePeer?` |
| :454 | `linkedMonoforumPeer: Peer?,` (init param) | Type → `EnginePeer?` |
| :498 | `self.linkedDiscussionPeer = linkedDiscussionPeer` | No change |
| :499 | `self.linkedMonoforumPeer = linkedMonoforumPeer` | No change |
| :1038, :1111, :1631 | `linkedDiscussionPeer: nil,` (init kwargs) | No change |
| :1039, :1112, :1632 | `linkedMonoforumPeer: nil,` (init kwargs) | No change |
| :1836 | `var discussionPeer: Peer?` (local) | Type → `EnginePeer?` |
| :1838 | `discussionPeer = peer` (where `peer = peerView.peers[linkedDiscussionPeerId]`, raw `Peer`) | Wrap → `discussionPeer = EnginePeer(peer)` |
| :1841 | `var monoforumPeer: Peer?` (local) | Type → `EnginePeer?` |
| :1843 | `monoforumPeer = peerView.peers[linkedMonoforumId]` (dict lookup, `Peer?`) | Wrap → `monoforumPeer = peerView.peers[linkedMonoforumId].flatMap(EnginePeer.init)` |
| :2131 | `var discussionPeer: Peer?` (local, parallel to :1836) | Type → `EnginePeer?` |
| :2133 | `discussionPeer = peer` (parallel to :1838) | Wrap → `discussionPeer = EnginePeer(peer)` |
| :2136 | `var monoforumPeer: Peer?` (local, parallel to :1841) | Type → `EnginePeer?` |
| :2138 | `monoforumPeer = peerView.peers[linkedMonoforumId]` (parallel to :1843) | Wrap with `.flatMap(EnginePeer.init)` |
| :1878, :1879, :2216, :2217 | init kwargs `linkedDiscussionPeer: discussionPeer,` / `linkedMonoforumPeer: monoforumPeer,` | No change (locals migrate; pass through) |

That's **12 edits** in PID. Note the `var` declarations and assignments at :1836–:1843 and :2131–:2138 are *parallel pairs* (verified by grep). Use `replace_all=true` for the duplicate snippets.

### `PeerInfoProfileItems.swift` (3 edits)

| Site | Code | Action |
|------|------|--------|
| :1098 | `if let peer = data.linkedDiscussionPeer { ... }` | No change (binding works on `EnginePeer?`) |
| :1099 | `if let addressName = peer.addressName, !addressName.isEmpty {` | No change — `EnginePeer.addressName` forwarded (verified at `submodules/TelegramCore/Sources/TelegramEngine/Peers/Peer.swift:461`) |
| :1102 | `discussionGroupTitle = EnginePeer(peer).displayTitle(strings: ..., displayOrder: ...)` | **Drop wrap** → `peer.displayTitle(...)` |
| :1197 | `if let monoforumPeer = data.linkedMonoforumPeer as? TelegramChannel {` | **Pattern rewrite** → `if case let .channel(monoforumPeer) = data.linkedMonoforumPeer {` |
| :1198 | `monoforumPeer.sendPaidMessageStars` | No change — `sendPaidMessageStars` is a `TelegramChannel` property (`SyncCore_TelegramChannel.swift:215`); `case .channel` binds to `TelegramChannel` |
| :1404 | `if let linkedDiscussionPeer = data.linkedDiscussionPeer {` | No change (binding works) |
| :1406 | `if let addressName = linkedDiscussionPeer.addressName, !addressName.isEmpty {` | No change (forwarded) |
| :1409 | `peerTitle = EnginePeer(linkedDiscussionPeer).displayTitle(...)` | **Drop wrap** → `linkedDiscussionPeer.displayTitle(...)` |

3 edits in PIPI.

## EnginePeer property forwarding audit

- `EnginePeer.addressName` — forwarded at `Peer.swift:461`. ✓
- `EnginePeer.displayTitle(strings:displayOrder:)` — defined as `EnginePeer` instance method (used elsewhere via `EnginePeer(...).displayTitle(...)` pattern; once we have an `EnginePeer`, it's directly callable). ✓
- `case .channel` binding payload is `TelegramChannel`. ✓
- `TelegramChannel.sendPaidMessageStars` — exists (`SyncCore_TelegramChannel.swift:215`). ✓

## Net bridge count

- **ADDs (4):** boundary lifts at PID:1838 (`EnginePeer(peer)`), PID:1843 (`.flatMap(EnginePeer.init)`), PID:2133, PID:2138. These lift the Postbox-typed `peerView.peers[...]` value to the engine type at the boundary — the correct semantic position for a Postbox→Engine refactor (mirrors wave 42 where `peer.flatMap(EnginePeer.init)` lift was added at PID:1620).
- **DROPs (2):** PIPI:1102 and :1409 lose `EnginePeer(...)` wraps around `displayTitle` calls.
- **Net text bridges:** +2. **But:** the ADDs are correct boundary lifts; the field-typed-as-`EnginePeer?` is the canonical state. The 2 displayTitle DROPs are the actual ratchet value.
- **Plus:** 1 cleaner pattern (PIPI:1197 `as?` cast → `case let .channel`), no text saving but better Swift idiom.

## Edit list

### `PeerInfoData.swift` (12 edits, but Edit text uses `replace_all=true` to bundle parallel pairs)

1. Line 396: `let linkedDiscussionPeer: Peer?` → `let linkedDiscussionPeer: EnginePeer?`
2. Line 397: `let linkedMonoforumPeer: Peer?` → `let linkedMonoforumPeer: EnginePeer?`
3. Line 453: `linkedDiscussionPeer: Peer?,` → `linkedDiscussionPeer: EnginePeer?,`
4. Line 454: `linkedMonoforumPeer: Peer?,` → `linkedMonoforumPeer: EnginePeer?,`
5. Lines 1836 + 2131 (`replace_all=true` over `var discussionPeer: Peer?`): → `var discussionPeer: EnginePeer?`
6. Lines 1838 + 2133 (`replace_all=true` over `discussionPeer = peer`): → `discussionPeer = EnginePeer(peer)`
7. Lines 1841 + 2136 (`replace_all=true` over `var monoforumPeer: Peer?`): → `var monoforumPeer: EnginePeer?`
8. Lines 1843 + 2138 (`replace_all=true` over `monoforumPeer = peerView.peers[linkedMonoforumId]`): → `monoforumPeer = peerView.peers[linkedMonoforumId].flatMap(EnginePeer.init)`

### `PeerInfoProfileItems.swift` (3 edits)

9. Line 1102: `discussionGroupTitle = EnginePeer(peer).displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)` → `discussionGroupTitle = peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)`
10. Line 1197: `if let monoforumPeer = data.linkedMonoforumPeer as? TelegramChannel {` → `if case let .channel(monoforumPeer) = data.linkedMonoforumPeer {`
11. Line 1409: `peerTitle = EnginePeer(linkedDiscussionPeer).displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)` → `peerTitle = linkedDiscussionPeer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)`

## Out of scope

- `PeerInfoScreenData.chatPeer` — large blast radius. Defer.
- `PeerInfoScreenMemberItem.enclosingPeer`. Defer.

## Build & verify

Standard Bazel command. Expected 1 iteration if forwarding audit holds; 2 if a `displayTitle` overload-resolution surprise surfaces.

## Commit

`Postbox -> TelegramEngine wave 49`. Body: bundle + edits summary + ADD/DROP accounting.

## Outcome capture

Append Wave 49 entry to `docs/superpowers/postbox-refactor-log.md`; update memory file.
