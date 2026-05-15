# Wave 42 plan: `PeerInfoScreenData.peer: Peer? → EnginePeer?`

Date: 2026-04-24
Preceding waves: 41 (`RenderedChannelParticipant.peer`), 40 (`makeChatQrCodeScreen`/`makeChatRecentActionsController`), 39 (`makePeerInfoController`)
Scope (confirmed with user): only `PeerInfoScreenData.peer`. Sibling fields (`chatPeer`, `savedMessagesPeer`, `linkedDiscussionPeer`, `linkedMonoforumPeer`) are follow-up-wave candidates.

## Change target

File: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoData.swift`

- L386: `let peer: Peer?` → `let peer: EnginePeer?`
- L442: `peer: Peer?,` → `peer: EnginePeer?,`
- Store unchanged (`self.peer = peer`)

## Construction sites (5, all in PeerInfoData.swift)

| Line | Current `peer:` arg | Rewrite |
|------|---------------------|---------|
| 1027 | `peer: peer` (local, `Peer?` from `peerView.peers[peerId]`) | `peer: peer.flatMap(EnginePeer.init)` |
| 1100 | `peer: nil` | unchanged |
| 1620 | `peer: peer` (local, `Peer?` from `peerView.peers[userPeerId]`) | `peer: peer.flatMap(EnginePeer.init)` |
| 1867 | `peer: peerView.peers[peerId]` | `peer: peerView.peers[peerId].flatMap(EnginePeer.init)` |
| 2205 | `peer: peerView.peers[groupId]` | `peer: peerView.peers[groupId].flatMap(EnginePeer.init)` |

## Consumer migration patterns (across 18 files, ~114 `data.peer` accesses)

### Pattern A — as-cast → enum pattern match (~20 sites)

```swift
// before
if let user = data.peer as? TelegramUser, user.botInfo == nil { ... }

// after
if case let .user(user) = data.peer, user.botInfo == nil { ... }
```

Scope both sides consistently. A cast inside a larger `guard let ..., let user = ... as? TelegramUser else { return }` becomes `guard ..., case let .user(user) = data.peer else { return }`.

### Pattern B — `is TelegramXxx` check → enum case pattern (~5 sites)

The wave-41 lesson: `-warnings-as-errors` catches always-false `is` checks.

```swift
// before
if let peer = self.data?.peer, peer is TelegramChannel { ... }
if peer is TelegramGroup { ... }

// after
if case .channel = self.data?.peer { ... }
if case .legacyGroup = peer { ... }
```

`TelegramGroup` maps to `.legacyGroup`. `TelegramChannel` maps to `.channel`. `TelegramUser` maps to `.user`. `TelegramSecretChat` maps to `.secretChat`.

Known sites in PeerInfoScreen.swift (inventory): L3981, L4133, L4192, L4194 (and L7421 for `chatPeer`-bound — chatPeer stays raw, so L7421 is out of scope). Use repo grep on `PeerInfoScreen/Sources` with token `is Telegram(Channel|User|Group|SecretChat)` to catch other sites.

### Pattern C — existing `EnginePeer(peer)` wraps where `peer` was bound from `data.peer` — DROP (15+ sites)

```swift
// before
if let peer = self.data?.peer {
    self.joinChannel(peer: EnginePeer(peer))  // wave-40 wrap
}

// after
if let peer = self.data?.peer {
    self.joinChannel(peer: peer)  // peer is now EnginePeer already
}
```

Care needed: only drop the wrap where the bound `peer` variable comes from `data.peer`. Wraps on `chatPeer`, `currentPeer`, `user` (bound via `as? TelegramUser`), `groupPeer`, or PeerView lookups stay. The lexical scope makes this judgeable.

Known drop sites (PeerInfoScreen.swift): 1331, 1339, 1346, 1561, 2353, 2405, 3409, 3459, 3624, 3747, 4306, 4573 (inner — review scope), 4623. PeerInfoHeaderNode.swift: 571, 1218, 2054 (if bound from data.peer). PeerInfoScreenOpenChat.swift: 25, 40, 51, 57, 80, 89, 115. Verify each by backtracking the `if let peer = ...` binding.

### Pattern D — helper call sites still taking `Peer?` (ADD-WRAP, ~10 sites)

`canEditPeerInfo`, `peerInfoIsChatMuted`, `peerInfoHeaderButtons`, `peerInfoHeaderActionButtons`, `peerInfoCanEdit`, `availableActionsForMemberOfPeer` all keep `peer: Peer?` in this wave. Call sites must bridge:

```swift
// before
peerInfoIsChatMuted(peer: self.data?.peer, ...)

// after
peerInfoIsChatMuted(peer: self.data?.peer?._asPeer(), ...)
```

Site count (from grep): PeerInfoHeaderNode.swift:548/549/2361, PeerInfoScreenAvatarSetup.swift:435, PeerInfoScreenPerformButtonAction.swift:62/397/398, PeerInfoEditingAvatarNode.swift:66, PeerInfoScreen.swift:1905/1961/5857, PeerInfoHeaderEditingContentNode.swift:59/88/93/159/162, PeerInfoEditingAvatarOverlayNode.swift:85. But the local `peer` at some of these is already narrowed via `as? TelegramUser` (now `case let .user(user)`); in that case the helper gets `user` (still `Peer`-conforming), no bridge needed. Bridge only where the raw `data.peer` flows into the helper.

These ADD-WRAP markers become ratchet-drops for a follow-up wave that migrates the helper signatures.

### Pattern E — `EnginePeer?` passed as `EnginePeer?` directly (DROP wraps on callback args)

Where `data.peer` feeds `makePeerInfoController(peer: EnginePeer)` / `chatInterfaceInteraction.openPeer(_ peer: EnginePeer, ...)` / `.peer(EnginePeer)` ChatLocation / `AvatarGalleryController(peer: EnginePeer)` / `makeChatQrCodeScreen(peer: EnginePeer)` / `makeChatRecentActionsController(peer: EnginePeer)` — drop the `EnginePeer(...)` wrap; pass directly.

### Pattern F — `EnginePeer(peer).displayTitle(...)` / `.compactDisplayTitle` usage (DROP wrap)

```swift
// before
EnginePeer(peer).displayTitle(strings: ..., displayOrder: ...)

// after (peer is now EnginePeer already)
peer.displayTitle(strings: ..., displayOrder: ...)
```

### Pattern G — `.isPremium` on `peer?` inside construction site (L1060, L1626, L1902, L2242)

`peerView.peers[peerId]?.isPremium` — `Peer` protocol exposes `isPremium`. But the construction site receives raw `Peer?` and then we wrap via `flatMap(EnginePeer.init)`. The `peer?.isPremium` in the same construction scope still refers to the *local* raw peer variable (type unchanged), not `self.peer`. **No change needed at construction sites for `.isPremium` accesses on the local raw `peer`.** Only change `.isPremium` accesses on `data.peer` (which is now `EnginePeer?`) — `EnginePeer.isPremium` exists.

## File-by-file plan

1. **PeerInfoData.swift** — declaration + init + 5 constructions. Also review L1529 (`peerView.peers[peerView.peerId] is TelegramUser`) — OUT OF SCOPE (not `data.peer`); don't touch. Helper functions L2265/2314/2434/2447/2585/2633 stay `peer: Peer?` — DO NOT TOUCH.

2. **PeerInfoScreen.swift** — largest consumer, ~70+ sites. Walk every `data.peer` / `data?.peer` / `self.data?.peer` / `self.data.peer`. Apply A/B/C/E/F patterns. For `if let peer = data.peer` bindings, subsequent uses of `peer` now have type `EnginePeer` — drop wraps on those uses.

3. **PeerInfoScreenOpenChat.swift, PeerInfoScreenOpenBio.swift, PeerInfoScreenOpenMember.swift, PeerInfoScreenOpenPeerInfoContextMenu.swift, PeerInfoScreenOpenUsername.swift, PeerInfoScreenCallActions.swift, PeerInfoScreenMessageActions.swift, PeerInfoScreenPerformButtonAction.swift, PeerInfoScreenAvatarSetup.swift, PeerInfoScreenSettingsActions.swift, PeerInfoScreenDisplayGiftsContextMenu.swift, PeerInfoScreenDisplayMediaGalleryContextMenu.swift** — various `data?.peer as? TelegramXxx` (A), helper bridges (D), wrap drops (C/E).

4. **PeerInfoPaneContainerNode.swift** — L1252 `as? TelegramChannel` (A).

5. **PeerInfoProfileItems.swift, PeerInfoSettingsItems.swift, ListItems/PeerInfoScreenPersonalChannelItem.swift** — `data.peer as? TelegramUser` style consumers (A).

6. **PeerInfoHeaderNode.swift, PeerInfoEditingAvatarNode.swift, PeerInfoEditingAvatarOverlayNode.swift, PeerInfoHeaderEditingContentNode.swift** — these files receive `peer` as a parameter (not directly `data.peer`). Only touch if a parameter type declared as `Peer?` is the field from `data.peer` being passed in; otherwise leave.

## Replace_all guidance (wave-41 lesson)

Several wraps repeat identically. Where a file has multiple identical `EnginePeer(peer)` expressions in scopes where `peer` is now `EnginePeer`, use `replace_all=true` on the unique full expression. BUT verify each such file has no same-pattern wrap where `peer` is still raw (chatPeer-bound, currentPeer-bound, etc.) — such wraps must survive.

Safer alternative: edit each site individually.

## Out of scope (enumerated)

- `PeerInfoScreenData.chatPeer`, `.savedMessagesPeer`, `.linkedDiscussionPeer`, `.linkedMonoforumPeer` — stay `Peer?`.
- Internal helpers `canEditPeerInfo` / `peerInfoIsChatMuted` / etc. — stay `peer: Peer?`.
- `peerView.peers[...]` access inside PeerInfoData.swift — stays raw `Peer?`.
- Any `is TelegramXxx` check on a non-`data.peer`-derived variable.

## Build methodology

1. Apply declaration + init + construction edits.
2. Apply consumer edits file by file.
3. `source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 --configuration=debug_sim_arm64 --continueOnError`
4. Iterate on errors. Budget: 2–4 iterations (wave-41 lesson: foundational-type property-access migrations are not first-pass-clean).

## Expected ratchet math

- Drops: 15+ wave-40 wraps, ~20 as-cast patterns collapsed, ~5 is-checks rewritten, several `EnginePeer(peer).displayTitle` wraps dropped.
- Adds: ~10 `?._asPeer()` helper bridges, 4 `flatMap(EnginePeer.init)` at construction.
- Net: ~15–25 bridges dropped.

## WIP interference check

Pre-existing WIP in tree (per memory):
- `submodules/TelegramUI/Sources/ChatMessageTransitionNode.swift` — modified, unrelated animation WIP. DO NOT TOUCH.
- `submodules/TgVoip/`, `third-party/libx264/`, `build-system/tulsi/` — untracked, unrelated.
- `build-system/bazel-rules/sourcekit-bazel-bsp` — submodule marker, unrelated.

Wave-42 files are all in `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/` — no overlap with WIP. Commit with explicit file list (wave-39/41 lesson).

## Post-commit followups

- Update `docs/superpowers/postbox-refactor-log.md` with "Wave 42 outcome".
- Update `memory/project_postbox_refactor_next_wave.md` with wave 43 candidates:
  - Wave 42.x sibling: `PeerInfoScreenData.chatPeer` / `.savedMessagesPeer` / `.linkedDiscussionPeer` / `.linkedMonoforumPeer` as a bundle (same file, narrow blast radius).
  - Wave 42.y: PeerInfo-internal helper signatures (drops the ~10 ADD-WRAP markers).
  - Option 2 from wave-42 shortlist: `RenderedChannelParticipant.peers` dict.
