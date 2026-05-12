# Wave 47 — `PeerInfoHeaderNode.peer` stored field `Peer? → EnginePeer?`

**Date:** 2026-04-25
**Predecessor:** Wave 46 (commit `5ca99da5a7`) — PeerInfo avatar chain.
**Shape:** Single-file stored-field type migration. No external API change (field is `private`).

## Target

`submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoHeaderNode.swift`, stored field `private var peer: Peer?` at line 92.

## Pre-flight inventory

`grep -n "self\.peer\b" PeerInfoHeaderNode.swift` returns exactly 3 references:

| Line | Code | Site type | Action |
|------|------|-----------|--------|
| 426 | `if let peer = self.peer, peer.profileImageRepresentations.isEmpty && gallery {` | Read | None — `profileImageRepresentations` is forwarded by `EnginePeer` (see `submodules/TelegramCore/Sources/TelegramEngine/Peers/Peer.swift:485`). Compiles unchanged. |
| 521 | `self.peer = peer?._asPeer()` | Assignment | Drop the bridge → `self.peer = peer`. The `peer` parameter is already `EnginePeer?` after wave 45. |
| 2049–2054 | `guard let self, let peer = self.peer, ...` followed by `peer: EnginePeer(peer),` | Read | Drop the wrap at line 2054 → `peer: peer,`. |

External access check: `grep -rn "headerNode\.peer\b" submodules/ Telegram/` returns empty. The field is private; only same-file siblings touch it.

EnginePeer forwarding (re-confirmed at plan time):
- `profileImageRepresentations` — forwarded (Peer.swift:485). ✓
- `EnginePeer(peer)` (PHN:2054) — accepts `EnginePeer` directly when the local is already `EnginePeer`; drop the constructor.

Field-declaration change is the only "type" change needed. The 3 callers' adjustments are mechanical bridge drops.

## Edit list

1. Line 92: `private var peer: Peer?` → `private var peer: EnginePeer?`
2. Line 521: `self.peer = peer?._asPeer()` → `self.peer = peer`
3. Line 2054: `peer: EnginePeer(peer),` → `peer: peer,`

Total: 3 edits in 1 file.

## Out of scope

- `PeerInfoData.swift:355,487` — different classes' `self.peer` assignments (different types). Audit confirms these are `RenderedChannelParticipant.peer` and similar — already migrated in earlier waves or owned by other types.
- `PeerInfoAvatarTransformContainerNode.peer` (line 223) — already `EnginePeer?` after wave 46.

## Build & verify

```sh
source ~/.zshrc 2>/dev/null; \
python3 build-system/Make/Make.py --overrideXcodeVersion \
  --cacheDir ~/telegram-bazel-cache build \
  --configurationPath build-system/appstore-configuration.json \
  --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
  --gitCodesigningType development --gitCodesigningUseCurrent \
  --buildNumber=1 --configuration=debug_sim_arm64
```

Expected: 1-iteration first-pass-clean. Only PeerInfoScreen + TelegramUI recompile.

## Commit

`Postbox -> TelegramEngine wave 47`. Body lists the 3-edit summary and notes -3 internal bridges.

## Outcome capture

Append a Wave 47 entry to `docs/superpowers/postbox-refactor-log.md` and update memory file `project_postbox_refactor_next_wave.md`.
