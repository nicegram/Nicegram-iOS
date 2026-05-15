# Wave 44 — RenderedChannelParticipant.peers Engine-Peer Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `RenderedChannelParticipant.peers: [PeerId: Peer]` to `[EnginePeer.Id: EnginePeer]`. Closes the wave-41 ratchet — the public struct no longer leaks raw Postbox `Peer` in any field.

**Architecture:** Single atomic commit. Declaration in TelegramCore changes; 8 TelegramCore producer functions wrap raw `Peer` values at their local-dict insertion points (inside transactions that already read from Postbox); 11 consumer-surface bridges drop (6 `EnginePeer(peer)` read-wraps + 5 `.mapValues({ $0._asPeer() })` constructor-unwrap transforms); 1 consumer-surface unwrap is added where an extracted `EnginePeer` value flows into a `SimpleDictionary<PeerId, Peer>`.

**Tech Stack:** Swift, Bazel (via `python3 build-system/Make/Make.py`), Postbox, TelegramCore, TelegramEngine. No unit tests — full-build verification only.

**Spec:** `docs/superpowers/specs/2026-04-24-rcp-peers-engine-migration-design.md`

---

## File Structure

All edits happen in existing files — no new files created. Touched files:

**TelegramCore (declaration + producers, 9 files):**
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelParticipants.swift` (declaration)
- `submodules/TelegramCore/Sources/TelegramEngine/Messages/RequestStartBot.swift`
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelOwnershipTransfer.swift`
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/JoinChannel.swift`
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/AddPeerMember.swift`
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/PeerAdmins.swift`
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelBlacklist.swift`
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/Ranks.swift`
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelMembers.swift`

**Consumers (drops + 1 add, 5 files):**
- `submodules/PeerInfoUI/Sources/ChannelAdminsController.swift`
- `submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift`
- `submodules/PeerInfoUI/Sources/ChannelMembersSearchControllerNode.swift`
- `submodules/PeerInfoUI/Sources/ChannelBlacklistController.swift`
- `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsHistoryTransition.swift`

**Total:** 14 files, ~30 edits, one atomic commit.

---

## Task 1: Pre-flight re-verification

**Purpose:** Confirm the grep surface matches the spec before editing anything. If any site count diverges, stop and update the spec.

**Files:** None modified.

- [ ] **Step 1.1: Verify 7 `participant.peers[...]` consumer read sites**

Run:
```bash
grep -rnE "participant\.peers\[|rcp\.peers\[|renderedParticipant\.peers\[" --include="*.swift" submodules/ 2>/dev/null
```

Expected output — exactly 6 bracketed-indexing sites (the 7th site, iteration without bracket-indexing, is checked in Step 1.2):
- `submodules/PeerInfoUI/Sources/ChannelAdminsController.swift:293`
- `submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift:835`
- `submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift:869`
- `submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift:1087`
- `submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift:1121`
- `submodules/PeerInfoUI/Sources/ChannelBlacklistController.swift:164`

If any line numbers differ by more than ±3 lines, re-read surrounding context to confirm identity. If a NEW site appears that isn't in the spec, STOP and update the spec before proceeding.

- [ ] **Step 1.2: Verify the iteration site is still at the expected line**

Run:
```bash
grep -nE "for \(.*,.* peer\) in participant\.peers" submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsHistoryTransition.swift
```

Expected: `672:            for (_, peer) in participant.peers {`

- [ ] **Step 1.3: Verify all 8 TelegramCore producers still build `var peers: [PeerId: Peer] = [:]` locally**

Run:
```bash
grep -rnE "^[[:space:]]+var peers: \[PeerId: Peer\] = \[:\]" submodules/TelegramCore/Sources/TelegramEngine/ 2>/dev/null
```

Expected 8 matches, one per producer file:
- `Messages/RequestStartBot.swift:61`
- `Peers/ChannelOwnershipTransfer.swift:170`
- `Peers/JoinChannel.swift:59`
- `Peers/AddPeerMember.swift:242`
- `Peers/PeerAdmins.swift:251`
- `Peers/ChannelBlacklist.swift:128`
- `Peers/Ranks.swift:60`
- `Peers/ChannelMembers.swift:102`

If a producer is missing from this grep, check whether it now receives `peers` as a parameter rather than building locally — if so, STOP and update the spec (chain-migration needed).

- [ ] **Step 1.4: Verify no `as?` / `is TelegramX` casts exist on extracted dict values**

Run:
```bash
grep -rnE "peer = participant\.peers" --include="*.swift" -A 4 submodules/ 2>/dev/null | grep -E "as\?|is Telegram"
```

Expected output: empty. If this returns non-empty, STOP and update the spec.

- [ ] **Step 1.5: Verify no one is assigning into `participant.peers` (writes would break the migration)**

Run:
```bash
grep -rnE "participant\.peers\[[^]]+\][[:space:]]*=" --include="*.swift" submodules/ 2>/dev/null
```

Expected output: empty (`.peers` is a `let`; no writes possible anyway, but double-check).

---

## Task 2: Migrate declaration in ChannelParticipants.swift

**Purpose:** Change the struct field type and init default.

**Files:**
- Modify: `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelParticipants.swift:11, 14`

- [ ] **Step 2.1: Change field declaration**

In `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelParticipants.swift`, line 11:

```swift
// before
    public let peers: [PeerId: Peer]

// after
    public let peers: [EnginePeer.Id: EnginePeer]
```

- [ ] **Step 2.2: Change init default**

Same file, line 14:

```swift
// before
    public init(participant: ChannelParticipant, peer: EnginePeer, peers: [PeerId: Peer] = [:], presences: [PeerId: PeerPresence] = [:]) {

// after
    public init(participant: ChannelParticipant, peer: EnginePeer, peers: [EnginePeer.Id: EnginePeer] = [:], presences: [PeerId: PeerPresence] = [:]) {
```

Do NOT commit yet — this leaves the repo in a broken state until producers and consumers are updated.

---

## Task 3: Migrate TelegramCore producers (8 files)

**Purpose:** Each of the 8 TelegramCore producers builds a local `peers: [PeerId: Peer] = [:]` dict from raw Postbox peers inside a transaction. Migrate each local dict to `[EnginePeer.Id: EnginePeer] = [:]` and wrap every insertion value with `EnginePeer(...)`.

**Pattern (applies to every sub-step):**
```swift
// before
var peers: [PeerId: Peer] = [:]
peers[X.id] = X

// after
var peers: [EnginePeer.Id: EnginePeer] = [:]
peers[X.id] = EnginePeer(X)
```

The surrounding `presences: [PeerId: PeerPresence]` dict and the `RCP(..., peer: EnginePeer(X), ...)` wrap on the primary `peer` field both stay unchanged.

- [ ] **Step 3.1: Migrate `RequestStartBot.swift`**

File: `submodules/TelegramCore/Sources/TelegramEngine/Messages/RequestStartBot.swift`

Line 61: `var peers: [PeerId: Peer] = [:]` → `var peers: [EnginePeer.Id: EnginePeer] = [:]`
Line 64: `peers[peer.id] = peer` → `peers[peer.id] = EnginePeer(peer)`

- [ ] **Step 3.2: Migrate `ChannelOwnershipTransfer.swift`**

File: `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelOwnershipTransfer.swift`

Line 170: `var peers: [PeerId: Peer] = [:]` → `var peers: [EnginePeer.Id: EnginePeer] = [:]`
Line 172: `peers[accountUser.id] = accountUser` → `peers[accountUser.id] = EnginePeer(accountUser)`
Line 176: `peers[user.id] = user` → `peers[user.id] = EnginePeer(user)`

Line 180 is a double-RCP-construction; `peers:` reuses the same local — no change at line 180.

- [ ] **Step 3.3: Migrate `JoinChannel.swift`**

File: `submodules/TelegramCore/Sources/TelegramEngine/Peers/JoinChannel.swift`

Line 59: `var peers: [PeerId: Peer] = [:]` → `var peers: [EnginePeer.Id: EnginePeer] = [:]`
Line 64: `peers[account.peerId] = peer` → `peers[account.peerId] = EnginePeer(peer)`
Line 77: `peers[peer.id] = peer` → `peers[peer.id] = EnginePeer(peer)`

- [ ] **Step 3.4: Migrate `AddPeerMember.swift`**

File: `submodules/TelegramCore/Sources/TelegramEngine/Peers/AddPeerMember.swift`

Line 242: `var peers: [PeerId: Peer] = [:]` → `var peers: [EnginePeer.Id: EnginePeer] = [:]`
Line 244: `peers[memberPeer.id] = memberPeer` → `peers[memberPeer.id] = EnginePeer(memberPeer)`
Line 251: `peers[peer.id] = peer` → `peers[peer.id] = EnginePeer(peer)`

- [ ] **Step 3.5: Migrate `PeerAdmins.swift`**

File: `submodules/TelegramCore/Sources/TelegramEngine/Peers/PeerAdmins.swift`

Line 251: `var peers: [PeerId: Peer] = [:]` → `var peers: [EnginePeer.Id: EnginePeer] = [:]`
Line 253: `peers[adminPeer.id] = adminPeer` → `peers[adminPeer.id] = EnginePeer(adminPeer)`
Line 259: `peers[peer.id] = peer` → `peers[peer.id] = EnginePeer(peer)`

- [ ] **Step 3.6: Migrate `ChannelBlacklist.swift`**

File: `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelBlacklist.swift`

Line 128: `var peers: [PeerId: Peer] = [:]` → `var peers: [EnginePeer.Id: EnginePeer] = [:]`
Line 130: `peers[memberPeer.id] = memberPeer` → `peers[memberPeer.id] = EnginePeer(memberPeer)`
Line 136: `peers[peer.id] = peer` → `peers[peer.id] = EnginePeer(peer)`

- [ ] **Step 3.7: Migrate `Ranks.swift`**

File: `submodules/TelegramCore/Sources/TelegramEngine/Peers/Ranks.swift`

Line 60: `var peers: [PeerId: Peer] = [:]` → `var peers: [EnginePeer.Id: EnginePeer] = [:]`
Line 62: `peers[user.id] = user` → `peers[user.id] = EnginePeer(user)`
Line 68: `peers[peer.id] = peer` → `peers[peer.id] = EnginePeer(peer)`

- [ ] **Step 3.8: Migrate `ChannelMembers.swift`**

File: `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelMembers.swift`

Line 102: `var peers: [PeerId: Peer] = [:]` → `var peers: [EnginePeer.Id: EnginePeer] = [:]`
Line 105: `peers[peer.id] = peer` → `peers[peer.id] = EnginePeer(peer)`

- [ ] **Step 3.9: Post-producer verification**

Run:
```bash
grep -rnE "^[[:space:]]+var peers: \[PeerId: Peer\] = \[:\]" submodules/TelegramCore/Sources/TelegramEngine/ 2>/dev/null
```

Expected: no output (all 8 have been converted).

Run:
```bash
grep -rnE "^[[:space:]]+var peers: \[EnginePeer\.Id: EnginePeer\] = \[:\]" submodules/TelegramCore/Sources/TelegramEngine/ 2>/dev/null | wc -l
```

Expected: `8` (or `       8`).

---

## Task 4: Drop 5 consumer `.mapValues({ $0._asPeer() })` transforms

**Purpose:** These consumer-side constructors build a `[EnginePeer.Id: EnginePeer]` source dict locally and currently unwrap to `[PeerId: Peer]` via `.mapValues({ $0._asPeer() })` to feed the old constructor signature. After Task 2, the constructor expects engine values directly — the transform becomes a no-op and is removed.

**Pattern (applies to every sub-step):**
```swift
// before
peers: peers.mapValues({ $0._asPeer() })

// after
peers: peers
```

- [ ] **Step 4.1: `ChannelAdminsController.swift:926`**

File: `submodules/PeerInfoUI/Sources/ChannelAdminsController.swift`

Line 926 (long line): locate the substring `peers: peers.mapValues({ $0._asPeer() })` and replace with `peers: peers`.

- [ ] **Step 4.2: `ChannelMembersSearchContainerNode.swift:994`**

File: `submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift`

Line 994: replace `peers: peers.mapValues({ $0._asPeer() })` → `peers: peers`.

- [ ] **Step 4.3: `ChannelMembersSearchContainerNode.swift:998`**

Same file, line 998: replace `peers: peers.mapValues({ $0._asPeer() })` → `peers: peers`.

- [ ] **Step 4.4: `ChannelMembersSearchControllerNode.swift:409`**

File: `submodules/PeerInfoUI/Sources/ChannelMembersSearchControllerNode.swift`

Line 409: replace `peers: peers.mapValues({ $0._asPeer() })` → `peers: peers`.

- [ ] **Step 4.5: `ChannelMembersSearchControllerNode.swift:413`**

Same file, line 413: replace `peers: peers.mapValues({ $0._asPeer() })` → `peers: peers`.

- [ ] **Step 4.6: Post-Task-4 verification**

Run:
```bash
grep -rnE "peers\.mapValues\(\{ \$0\._asPeer\(\) \}\)" --include="*.swift" submodules/ 2>/dev/null
```

Expected: no output (all 5 drops applied). If any remain, locate and drop.

---

## Task 5: Drop 6 consumer `EnginePeer(peer).displayTitle(...)` read-wraps

**Purpose:** Each site extracts `peer` from `participant.peers[X]`, wraps with `EnginePeer(peer)` to call `.displayTitle(...)`. After Task 2 the extracted `peer` is already `EnginePeer` — drop the wrap.

**Pattern (applies to every sub-step):**
```swift
// before
EnginePeer(peer).displayTitle(strings: ..., displayOrder: ...)

// after
peer.displayTitle(strings: ..., displayOrder: ...)
```

- [ ] **Step 5.1: `ChannelAdminsController.swift:297`**

File: `submodules/PeerInfoUI/Sources/ChannelAdminsController.swift`, line 297.

Replace:
```swift
peerText = strings.Channel_Management_PromotedBy(EnginePeer(peer).displayTitle(strings: strings, displayOrder: nameDisplayOrder)).string
```
with:
```swift
peerText = strings.Channel_Management_PromotedBy(peer.displayTitle(strings: strings, displayOrder: nameDisplayOrder)).string
```

The adjacent `peer.id == participant.peer.id` comparison at line 294 stays unchanged (both are `EnginePeer.Id`).

- [ ] **Step 5.2: `ChannelMembersSearchContainerNode.swift:839`**

File: `submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift`, line 839.

Replace:
```swift
label = presentationData.strings.Channel_Management_PromotedBy(EnginePeer(peer).displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)).string
```
with:
```swift
label = presentationData.strings.Channel_Management_PromotedBy(peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)).string
```

- [ ] **Step 5.3: `ChannelMembersSearchContainerNode.swift:870`**

Same file, line 870.

Replace:
```swift
label = presentationData.strings.Channel_Management_RemovedBy(EnginePeer(peer).displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)).string
```
with:
```swift
label = presentationData.strings.Channel_Management_RemovedBy(peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)).string
```

- [ ] **Step 5.4: `ChannelMembersSearchContainerNode.swift:1091`**

Same file, line 1091.

Replace:
```swift
label = presentationData.strings.Channel_Management_PromotedBy(EnginePeer(peer).displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)).string
```
with:
```swift
label = presentationData.strings.Channel_Management_PromotedBy(peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)).string
```

- [ ] **Step 5.5: `ChannelMembersSearchContainerNode.swift:1122`**

Same file, line 1122.

Replace:
```swift
label = presentationData.strings.Channel_Management_RemovedBy(EnginePeer(peer).displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)).string
```
with:
```swift
label = presentationData.strings.Channel_Management_RemovedBy(peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)).string
```

- [ ] **Step 5.6: `ChannelBlacklistController.swift:165`**

File: `submodules/PeerInfoUI/Sources/ChannelBlacklistController.swift`, line 165.

Replace:
```swift
text = .text(strings.Channel_Management_RemovedBy(EnginePeer(peer).displayTitle(strings: strings, displayOrder: nameDisplayOrder)).string, .secondary)
```
with:
```swift
text = .text(strings.Channel_Management_RemovedBy(peer.displayTitle(strings: strings, displayOrder: nameDisplayOrder)).string, .secondary)
```

- [ ] **Step 5.7: Post-Task-5 verification**

Run:
```bash
grep -rnE "EnginePeer\(peer\)\.displayTitle" --include="*.swift" submodules/PeerInfoUI/ 2>/dev/null
```

Expected: no output within PeerInfoUI. (Other modules may still have unrelated `EnginePeer(peer).displayTitle` usages on non-RCP-peers peers — those are out of scope.)

Run specifically for the 6 migrated sites:
```bash
grep -n "EnginePeer(peer)\.displayTitle" submodules/PeerInfoUI/Sources/ChannelAdminsController.swift submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift submodules/PeerInfoUI/Sources/ChannelBlacklistController.swift 2>/dev/null
```

Expected: no output.

---

## Task 6: Add 1 consumer unwrap at ChatRecentActionsHistoryTransition

**Purpose:** The one site that iterates `participant.peers` and inserts values into a `SimpleDictionary<PeerId, Peer>` container. After Task 2, the iterated `peer` is `EnginePeer`; the outer container still expects raw `Peer`. Unwrap at the insertion site.

**Files:**
- Modify: `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsHistoryTransition.swift:673`

- [ ] **Step 6.1: Replace insertion line**

In `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsHistoryTransition.swift`:

Context (lines 672–674, unchanged outside line 673):
```swift
for (_, peer) in participant.peers {
    peers[peer.id] = peer
}
```

After edit:
```swift
for (_, peer) in participant.peers {
    peers[peer.id] = peer._asPeer()
}
```

- [ ] **Step 6.2: Spot-check nearby wave-41 unwrap (reference, no change)**

Line 675 in the same function is `peers[participant.peer.id] = participant.peer._asPeer()` — a wave-41 artifact, unrelated to this wave. Leave unchanged.

---

## Task 7: Full build verification

**Purpose:** Verify the atomic change set compiles. Produces the ONLY real test signal for this wave.

**Files:** None modified; this is a build run.

- [ ] **Step 7.1: Run the full build**

Run:
```bash
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 --configuration=debug_sim_arm64 \
 --continueOnError
```

Expected: build succeeds. Look for `INFO: Build completed successfully` near the end.

- [ ] **Step 7.2: If build fails — triage**

Expected failure patterns (from wave-41 lesson, budget 2–3 iterations):

1. **Missing producer wrap** — compiler error `cannot assign value of type 'Peer' to subscript of type 'EnginePeer'` (or similar) at a TelegramCore producer file → check that file's `var peers:` decl was converted AND all insertion RHS values are wrapped.
2. **Missed consumer site** — compiler error at a `.displayTitle` call on a raw Peer → find `EnginePeer(peer).displayTitle` site that Task 5 missed; drop the wrap.
3. **Mismatched mapValues drop** — `cannot convert value of type '[EnginePeer.Id: EnginePeer]' to expected argument type '[PeerId: Peer]'` → the spec's risk #3 triggered (a `.mapValues` site had a raw-Peer source after all); replace the drop with `peers.mapValues(EnginePeer.init)` at that site instead.
4. **New grep surface** — compiler complains about a site not in this plan → add it to the commit's scope; log it to the outcome doc.

Apply fixes, re-run Step 7.1. Repeat up to 3 iterations before re-evaluating scope.

- [ ] **Step 7.3: Post-build final grep audit**

Run:
```bash
grep -rnE "participant\.peers\[[^]]+\]" --include="*.swift" submodules/ 2>/dev/null
```

Expected: the same 6 read sites as Step 1.1 (now without `EnginePeer(peer)` wraps).

Run:
```bash
grep -rnE "peers\.mapValues\(\{ \$0\._asPeer\(\) \}\)" --include="*.swift" submodules/ 2>/dev/null
```

Expected: no output.

Run:
```bash
grep -n "public let peers: \[" submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelParticipants.swift
```

Expected: `11:    public let peers: [EnginePeer.Id: EnginePeer]`.

---

## Task 8: Atomic commit

**Purpose:** Land all wave-44 edits in ONE commit. Explicitly enumerate files in `git add` (wave-39 lesson — re-confirmed in waves 41, 42, 43) to avoid pulling in the pre-existing working-tree WIP listed in the spec's risk section (`ListView.swift`, `ChatMessageTransitionNode.swift`, tulsi/, TgVoip/, libx264/).

**Files:** Commits all 14 wave-44 files.

- [ ] **Step 8.1: Confirm working-tree state**

Run:
```bash
git status --short
```

Expected (pre-existing WIP, unchanged):
- ` m build-system/bazel-rules/sourcekit-bazel-bsp`
- ` M submodules/Display/Source/ListView.swift` (do NOT include)
- ` M submodules/TelegramUI/Sources/ChatMessageTransitionNode.swift` (do NOT include)
- `?? build-system/tulsi/` (do NOT include)
- `?? submodules/TgVoip/` (do NOT include)
- `?? third-party/libx264/` (do NOT include)

Plus the wave-44 modified files:
- ` M submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelParticipants.swift`
- ` M submodules/TelegramCore/Sources/TelegramEngine/Messages/RequestStartBot.swift`
- ` M submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelOwnershipTransfer.swift`
- ` M submodules/TelegramCore/Sources/TelegramEngine/Peers/JoinChannel.swift`
- ` M submodules/TelegramCore/Sources/TelegramEngine/Peers/AddPeerMember.swift`
- ` M submodules/TelegramCore/Sources/TelegramEngine/Peers/PeerAdmins.swift`
- ` M submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelBlacklist.swift`
- ` M submodules/TelegramCore/Sources/TelegramEngine/Peers/Ranks.swift`
- ` M submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelMembers.swift`
- ` M submodules/PeerInfoUI/Sources/ChannelAdminsController.swift`
- ` M submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift`
- ` M submodules/PeerInfoUI/Sources/ChannelMembersSearchControllerNode.swift`
- ` M submodules/PeerInfoUI/Sources/ChannelBlacklistController.swift`
- ` M submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsHistoryTransition.swift`

If the set of wave-44-modified files doesn't match exactly (extra or missing), STOP and investigate before committing.

- [ ] **Step 8.2: Stage only wave-44 files**

Run:
```bash
git add \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelParticipants.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Messages/RequestStartBot.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelOwnershipTransfer.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/JoinChannel.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/AddPeerMember.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/PeerAdmins.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelBlacklist.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/Ranks.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelMembers.swift \
  submodules/PeerInfoUI/Sources/ChannelAdminsController.swift \
  submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift \
  submodules/PeerInfoUI/Sources/ChannelMembersSearchControllerNode.swift \
  submodules/PeerInfoUI/Sources/ChannelBlacklistController.swift \
  submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsHistoryTransition.swift
```

- [ ] **Step 8.3: Verify staged set matches expected**

Run:
```bash
git diff --cached --stat
```

Expected: exactly 14 files staged, all from the wave-44 list. If `ListView.swift`, `ChatMessageTransitionNode.swift`, `bazel-rules/sourcekit-bazel-bsp`, `tulsi/`, `TgVoip/`, or `libx264/` appear here, unstage them.

- [ ] **Step 8.4: Commit**

Run:
```bash
git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 44

Migrate RenderedChannelParticipant.peers from [PeerId: Peer] to
[EnginePeer.Id: EnginePeer]. Closes the wave-41 ratchet — the public
struct no longer leaks raw Peer types in any field (presences stays
Postbox-typed; separate migration).

Consumer-surface: -10 bridges. Dropped 6 EnginePeer(peer) read-wraps
at participant.peers[...] extraction sites across
ChannelAdminsController, ChannelMembersSearchContainerNode,
ChannelBlacklistController. Dropped 5 .mapValues({ $0._asPeer() })
constructor-unwrap transforms in ChannelAdminsController,
ChannelMembersSearchContainerNode, ChannelMembersSearchControllerNode.
Added 1 ._asPeer() at ChatRecentActionsHistoryTransition.swift:673
where the iterated value is inserted into a raw-Peer SimpleDictionary.

TelegramCore producers: 8 files build the local peers dict inside
postbox.transaction and wrap at the insertion point. ChannelMembers,
RequestStartBot, ChannelOwnershipTransfer, JoinChannel, AddPeerMember,
PeerAdmins, ChannelBlacklist, Ranks.

No unit tests in this project; full Telegram/Telegram build verified
under configuration=debug_sim_arm64.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 8.5: Verify commit**

Run:
```bash
git log -1 --stat
```

Expected: commit with 14 files changed, message starting with `Postbox -> TelegramEngine wave 44`.

Run:
```bash
git status --short
```

Expected: no M- or A-flagged wave-44 files (all committed); only the pre-existing WIP (`ListView.swift`, `ChatMessageTransitionNode.swift`, etc.) remains.

---

## Rollback

If the wave cannot be completed (e.g., build fails after 4+ iterations and the scope balloons beyond plan):

```bash
git restore --staged \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelParticipants.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Messages/RequestStartBot.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelOwnershipTransfer.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/JoinChannel.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/AddPeerMember.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/PeerAdmins.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelBlacklist.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/Ranks.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelMembers.swift \
  submodules/PeerInfoUI/Sources/ChannelAdminsController.swift \
  submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift \
  submodules/PeerInfoUI/Sources/ChannelMembersSearchControllerNode.swift \
  submodules/PeerInfoUI/Sources/ChannelBlacklistController.swift \
  submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsHistoryTransition.swift

git checkout -- \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelParticipants.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Messages/RequestStartBot.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelOwnershipTransfer.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/JoinChannel.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/AddPeerMember.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/PeerAdmins.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelBlacklist.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/Ranks.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelMembers.swift \
  submodules/PeerInfoUI/Sources/ChannelAdminsController.swift \
  submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift \
  submodules/PeerInfoUI/Sources/ChannelMembersSearchControllerNode.swift \
  submodules/PeerInfoUI/Sources/ChannelBlacklistController.swift \
  submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsHistoryTransition.swift
```

Then document what was learned in an outcome doc and update `project_postbox_refactor_next_wave.md`.

---

## Success criteria (from spec)

1. ✅ `ChannelParticipants.swift` has `peers: [EnginePeer.Id: EnginePeer]` declaration (Task 2).
2. ✅ All 8 TelegramCore producers compile with wrapped inserts (Task 3).
3. ✅ All 5 consumer `.mapValues({ $0._asPeer() })` transforms are removed (Task 4).
4. ✅ All 6 consumer `EnginePeer(peer).displayTitle(...)` wraps on extracted dict values are removed (Task 5).
5. ✅ `ChatRecentActionsHistoryTransition.swift:673` uses `peer._asPeer()` for the SimpleDictionary insertion value (Task 6).
6. ✅ Full `Telegram/Telegram` build (`configuration=debug_sim_arm64`) is clean — **one** atomic commit (Tasks 7, 8).
7. ✅ Grep post-migration: `participant.peers[` returns only engine-typed call sites; no residual `EnginePeer(peer)` on `.peers[...]` extractions (Steps 5.7, 7.3).
