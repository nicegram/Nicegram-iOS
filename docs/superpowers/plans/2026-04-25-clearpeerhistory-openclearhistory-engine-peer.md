# Wave 54: ClearPeerHistory.init + openClearHistory `chatPeer: Peer → EnginePeer`

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate the `chatPeer:` parameter type on both `ClearPeerHistory.init` and `openClearHistory` from `Peer` to `EnginePeer`. Closes wave-53's deferred sibling.

**Wave shape:** Bundled method-signature migration (familiar from waves 41/44/47/50/53). Mechanical `as?`/`is` cluster on a single field, with EnginePeer.init boundary lifts at each call site.

**Tech Stack:** Swift, Bazel, Make.py.

---

## Pre-Flight Inventory (validated 2026-04-25)

**2 files modified, 16 edits.**

### File 1: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift` (PIS)

| Line | Current | After | Note |
|---|---|---|---|
| 3213 | `func openClearHistory(... peer: Peer, chatPeer: Peer) {` | `... chatPeer: EnginePeer)` | type-site |
| 3230 | `EnginePeer(chatPeer).compactDisplayTitle` | `chatPeer.compactDisplayTitle` | drop wrap |
| 3232 | `EnginePeer(chatPeer).compactDisplayTitle` | `chatPeer.compactDisplayTitle` | drop wrap |
| 3251 | `EnginePeer(chatPeer).compactDisplayTitle` | `chatPeer.compactDisplayTitle` | drop wrap |
| 3269 | `EnginePeer(chatPeer).compactDisplayTitle` | `chatPeer.compactDisplayTitle` | drop wrap |
| 7416 | `init(... peer: Peer, chatPeer: Peer, cachedData: ...)` | `... chatPeer: EnginePeer, cachedData: ...` | type-site |
| 7421 | `} else if chatPeer is TelegramSecretChat {` | `} else if case .secretChat = chatPeer {` | conversion |
| 7425 | `} else if let group = chatPeer as? TelegramGroup {` | `} else if case let .legacyGroup(group) = chatPeer {` | conversion |
| 7436 | `} else if let channel = chatPeer as? TelegramChannel {` | `} else if case let .channel(channel) = chatPeer {` | conversion |
| 7464 | `if let user = chatPeer as? TelegramUser, user.botInfo != nil {` | `if case let .user(user) = chatPeer, user.botInfo != nil {` | conversion |

`peer:` parameter stays Peer-typed in both functions: `openClearHistory` doesn't reference `peer` in its body; `ClearPeerHistory.init` uses only `peer.id == context.account.peerId` (line 7417), which works on Peer (and would also work on EnginePeer, but migrating it would require 6 boundary lifts at PISPBA call sites for no internal benefit).

### File 2: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenPerformButtonAction.swift` (PISPBA)

| Line | Current | After | Note |
|---|---|---|---|
| 851 | `chatPeer: chatPeer._asPeer()` | `chatPeer: chatPeer` | drop wave-53 ADD |
| 857 | `chatPeer: user` | `chatPeer: EnginePeer(user)` | boundary lift (TelegramUser) |
| 1067 | `chatPeer: channel` | `chatPeer: EnginePeer(channel)` | boundary lift (TelegramChannel) |
| 1073 | `chatPeer: channel` | `chatPeer: EnginePeer(channel)` | boundary lift (TelegramChannel) |
| 1234 | `chatPeer: group` | `chatPeer: EnginePeer(group)` | boundary lift (TelegramGroup) |
| 1240 | `chatPeer: group` | `chatPeer: EnginePeer(group)` | boundary lift (TelegramGroup) |

### Net accounting

- **Drops:** 5 (4 `EnginePeer(chatPeer).compactDisplayTitle` + 1 `_asPeer()` bridge from wave 53).
- **Adds:** 5 boundary lifts (5 `EnginePeer(...)` wraps at PISPBA call sites).
- **Conversions:** 4 (`is`/`as?` → `case let`).
- **Type-site:** 2 (signature changes on PIS:3213 and PIS:7416).

Net internal-bridge progress: `5 drops − 5 adds = 0 raw count`. But ratchet kills 4 internal display-call wraps (`EnginePeer(chatPeer).compactDisplayTitle` patterns) which is the hot path; only call-site boundary lifts remain. Closes wave-53's deferred ADD at PISPBA:851.

---

## Tasks

### Task 1: PIS signature edits + body wrap drops

- [ ] **Step 1: Edit `openClearHistory` signature at PIS:3213**

Replace `peer: Peer, chatPeer: Peer)` with `peer: Peer, chatPeer: EnginePeer)`.

- [ ] **Step 2: Drop 4 `EnginePeer(chatPeer).compactDisplayTitle` wraps**

`replace_all=true` of `EnginePeer(chatPeer).compactDisplayTitle` → `chatPeer.compactDisplayTitle`. (Only 4 occurrences in the file, all in `openClearHistory` body; verified by grep.)

- [ ] **Step 3: Edit `ClearPeerHistory.init` signature at PIS:7416**

Replace `peer: Peer, chatPeer: Peer, cachedData:` with `peer: Peer, chatPeer: EnginePeer, cachedData:`.

- [ ] **Step 4: Convert PIS:7421 `is TelegramSecretChat`**

Replace `} else if chatPeer is TelegramSecretChat {` with `} else if case .secretChat = chatPeer {`.

- [ ] **Step 5: Convert PIS:7425 `as? TelegramGroup`**

Replace `} else if let group = chatPeer as? TelegramGroup {` with `} else if case let .legacyGroup(group) = chatPeer {`.

- [ ] **Step 6: Convert PIS:7436 `as? TelegramChannel`**

Replace `} else if let channel = chatPeer as? TelegramChannel {` with `} else if case let .channel(channel) = chatPeer {`.

- [ ] **Step 7: Convert PIS:7464 `as? TelegramUser`**

Replace `if let user = chatPeer as? TelegramUser, user.botInfo != nil {` with `if case let .user(user) = chatPeer, user.botInfo != nil {`.

### Task 2: PISPBA call-site lifts + bridge drop

- [ ] **Step 1: Drop wave-53 `_asPeer()` bridge at PISPBA:851**

Replace `chatPeer: chatPeer._asPeer()` with `chatPeer: chatPeer`.

- [ ] **Step 2: Lift PISPBA:857 `chatPeer: user`**

Replace `peer: user, chatPeer: user)` with `peer: user, chatPeer: EnginePeer(user))`.

- [ ] **Step 3: Lift channel call sites (PISPBA:1067 + 1073)**

`replace_all=true` of `chatPeer: channel` → `chatPeer: EnginePeer(channel)`. Verify exactly 2 hits flipped.

- [ ] **Step 4: Lift group call sites (PISPBA:1234 + 1240)**

`replace_all=true` of `chatPeer: group` → `chatPeer: EnginePeer(group)`. Verify exactly 2 hits flipped.

### Task 3: Build verification

- [ ] **Step 1: Run full build with `--continueOnError`.**

Forecast 1 iteration. Risk: hidden `chatPeer` access on Peer-typed shape elsewhere (none expected — body audit complete).

### Task 4: Commit + log

- [ ] **Step 1: Commit wave with the two file paths explicitly.**
- [ ] **Step 2: Update `docs/superpowers/postbox-refactor-log.md` and the memory file.**
- [ ] **Step 3: Commit log.**
