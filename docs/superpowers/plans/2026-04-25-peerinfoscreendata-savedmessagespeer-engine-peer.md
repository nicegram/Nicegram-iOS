# Wave 48 — `PeerInfoScreenData.savedMessagesPeer` `Peer? → EnginePeer?`

**Date:** 2026-04-25
**Predecessor:** Wave 47 (commit `d7b7536440`) — stored PHN.peer single-file private migration.
**Shape:** Cross-file struct-field migration. Storage class is internal to PeerInfoScreen module; no external consumer references PSD.savedMessagesPeer.

## Target

`submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoData.swift`, `PeerInfoScreenData.savedMessagesPeer: Peer?` at line 388.

## Pre-flight inventory

`grep -rEn "(\w+\??)\.savedMessagesPeer\b" submodules/ Telegram/` → matches only inside `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/`. No external consumer. The same field name appears in unrelated places (TelegramEngineMessages.swift, ChatListUI, etc.) but those are different declarations on different types.

Within PeerInfoScreen module:

| Site | Code | Action |
|------|------|--------|
| `PeerInfoData.swift:388` | `let savedMessagesPeer: Peer?` (struct field decl) | Type change → `EnginePeer?` |
| `PeerInfoData.swift:444` | `savedMessagesPeer: Peer?,` (init param) | Type change → `EnginePeer?` |
| `PeerInfoData.swift:489` | `self.savedMessagesPeer = savedMessagesPeer` (assignment) | No change (passthrough) |
| `PeerInfoData.swift:1029` | `savedMessagesPeer: nil,` (init kwarg) | No change (`nil` works for either) |
| `PeerInfoData.swift:1102` | `savedMessagesPeer: nil,` | No change |
| `PeerInfoData.swift:1313–1317` | `let savedMessagesPeer: Signal<EnginePeer?, NoError>` (local) | No change — already `EnginePeer?` |
| `PeerInfoData.swift:1622` | `savedMessagesPeer: savedMessagesPeer?._asPeer(),` | **Drop bridge** → `savedMessagesPeer: savedMessagesPeer,` |
| `PeerInfoData.swift:1869` | `savedMessagesPeer: nil,` | No change |
| `PeerInfoData.swift:2207` | `savedMessagesPeer: nil,` | No change |
| `PeerInfoScreen.swift:5399` | `peer: self.data?.savedMessagesPeer.flatMap(EnginePeer.init) ?? self.data?.peer,` | **Drop bridge** → `peer: self.data?.savedMessagesPeer ?? self.data?.peer,` |
| `PeerInfoScreen.swift:5805` | same as :5399 | Same drop |

Total edits: 5 (3 in PID, 2 in PIS).

## EnginePeer / read-site audit

The local signal at `PeerInfoData.swift:1313` already produces `EnginePeer?` from `engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.Peer(...))`. The `?._asPeer()` at line 1622 was an artificial demotion. Migrating the field type to `EnginePeer?` removes both the demotion at the storage site and the `flatMap(EnginePeer.init)` re-promotions at the read sites — a clean ratchet.

PIS:5399 and :5805 use the field as input to `headerNode.update(... peer: ...)`, whose `peer` parameter has been `EnginePeer?` since wave 45. The `??` coalescing operand is `self.data?.peer` (already `EnginePeer?`). Result: drop the `.flatMap(EnginePeer.init)` and the expression compiles.

## Edit list

### PeerInfoData.swift (3 edits)

1. Line 388: `let savedMessagesPeer: Peer?` → `let savedMessagesPeer: EnginePeer?`
2. Line 444: `savedMessagesPeer: Peer?,` → `savedMessagesPeer: EnginePeer?,`
3. Line 1622: `savedMessagesPeer: savedMessagesPeer?._asPeer(),` → `savedMessagesPeer: savedMessagesPeer,`

### PeerInfoScreen.swift (2 edits, identical text)

4. Line 5399: `peer: self.data?.savedMessagesPeer.flatMap(EnginePeer.init) ?? self.data?.peer,` → `peer: self.data?.savedMessagesPeer ?? self.data?.peer,`
5. Line 5805: same

Use `replace_all=true` for the PIS edit since the matched text appears at both call sites verbatim.

## Out of scope

- `PeerInfoScreenData.chatPeer` — large blast radius (5 `as? TelegramX` checks downstream + ClearPeerHistory init parameter), defer.
- `PeerInfoScreenData.linkedDiscussionPeer`, `linkedMonoforumPeer` — both have `as? TelegramChannel` consumer sites in `PeerInfoProfileItems.swift`. Defer.
- `PeerInfoScreenMemberItem.enclosingPeer` — defer (separate target).

## Build & verify

Same Bazel command as wave 47. Expected 1-iteration first-pass-clean (single-pattern bridge removal, no enum-case rewrites, no Peer-only property access).

## Commit

`Postbox -> TelegramEngine wave 48`. Body lists the 5-edit summary and notes −3 internal bridges (1 PID + 2 PIS, identical PIS text appears twice).

## Outcome capture

Append a Wave 48 entry to `docs/superpowers/postbox-refactor-log.md` and update memory file `project_postbox_refactor_next_wave.md`.
