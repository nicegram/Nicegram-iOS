# Wave 41 — `RenderedChannelParticipant.peer → EnginePeer` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `TelegramCore.RenderedChannelParticipant.peer` from Postbox `Peer` to TelegramCore `EnginePeer`. Drop ~37 bridges (net ~−14 after adds) and eliminate 2 Shape-C ratchet wraps installed by wave 39.

**Architecture:** Single atomic commit. One TelegramCore struct field change + 16 TelegramCore internal construction sites wrapped with `EnginePeer(peer)` + 17 consumer files updated: ZERO sites untouched (~160), ~32 DROP sites unwrapped, 9 CAST sites rewritten to pattern-match, 3 ADD-ASPEER sites append `._asPeer()`, 7 ADD-WRAP consumer constructors wrap raw `Peer` with `EnginePeer`.

**Tech Stack:** Swift, Bazel (`Make.py` wrapper), TelegramCore, Postbox → TelegramEngine refactor conventions per `CLAUDE.md`.

**Build command:**
```sh
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 --configuration=debug_sim_arm64 --continueOnError
```

---

## File Structure

**Created:** none.

**Modified (27 files):**

TelegramCore (10 files):
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelParticipants.swift` — struct field type + init param + Equatable impl
- `submodules/TelegramCore/Sources/TelegramEngine/Messages/RequestStartBot.swift` — 1 constructor wrap
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/AddPeerMember.swift` — 1 constructor wrap
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelAdminEventLogs.swift` — 7 constructor wraps
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelBlacklist.swift` — 1 constructor wrap
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelMembers.swift` — 1 constructor wrap
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelOwnershipTransfer.swift` — 2 constructor wraps
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/JoinChannel.swift` — 1 constructor wrap
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/PeerAdmins.swift` — 1 constructor wrap
- `submodules/TelegramCore/Sources/TelegramEngine/Peers/Ranks.swift` — 1 constructor wrap

PeerInfoUI (6 files):
- `submodules/PeerInfoUI/Sources/ChannelAdminsController.swift`
- `submodules/PeerInfoUI/Sources/ChannelBlacklistController.swift`
- `submodules/PeerInfoUI/Sources/ChannelMembersController.swift`
- `submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift`
- `submodules/PeerInfoUI/Sources/ChannelMembersSearchControllerNode.swift`
- `submodules/PeerInfoUI/Sources/ChannelPermissionsController.swift`

Other consumers (11 files):
- `submodules/SearchPeerMembers/Sources/SearchPeerMembers.swift`
- `submodules/TelegramUI/Components/AdminUserActionsSheet/Sources/AdminUserActionsSheet.swift`
- `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsController.swift`
- `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsFilterController.swift`
- `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsHistoryTransition.swift`
- `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoMembers.swift`
- `submodules/TelegramUI/Components/ShareWithPeersScreen/Sources/ShareWithPeersScreenState.swift`
- `submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryContentLiveChatComponent.swift`
- `submodules/TelegramUI/Sources/ChatControllerAdminBanUsers.swift`
- `submodules/TemporaryCachedPeerDataManager/Sources/ChannelMemberCategoryListContext.swift` *(no `participant.peer` edits needed — all ZERO; file touched only if build surfaces type issues)*
- `submodules/TemporaryCachedPeerDataManager/Sources/PeerChannelMemberCategoriesContextsManager.swift` *(no edits expected — only `item.peer.id` reference is ZERO)*

---

## Task 1: Migrate the struct definition

**File:** `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelParticipants.swift`

- [ ] **Step 1.1: Edit struct field, init param, and Equatable impl**

Replace the entire struct body:

```swift
public struct RenderedChannelParticipant: Equatable {
    public let participant: ChannelParticipant
    public let peer: EnginePeer
    public let peers: [PeerId: Peer]
    public let presences: [PeerId: PeerPresence]

    public init(participant: ChannelParticipant, peer: EnginePeer, peers: [PeerId: Peer] = [:], presences: [PeerId: PeerPresence] = [:]) {
        self.participant = participant
        self.peer = peer
        self.peers = peers
        self.presences = presences
    }

    public static func ==(lhs: RenderedChannelParticipant, rhs: RenderedChannelParticipant) -> Bool {
        return lhs.participant == rhs.participant && lhs.peer == rhs.peer
    }
}
```

Note: the file already imports both `Postbox` (for `Peer`/`PeerId`/`PeerPresence`) and TelegramCore internal symbols (`EnginePeer` visible from within the same module). No import changes needed.

---

## Task 2: Wrap TelegramCore-internal constructor sites

Each site receives a raw `Peer` and must now wrap it with `EnginePeer(peer)`. All edits are identical in shape.

- [ ] **Step 2.1:** `submodules/TelegramCore/Sources/TelegramEngine/Messages/RequestStartBot.swift:65`

Before:
```swift
return .channelParticipant(RenderedChannelParticipant(participant: participant, peer: peer, peers: peers, presences: presences))
```
After:
```swift
return .channelParticipant(RenderedChannelParticipant(participant: participant, peer: EnginePeer(peer), peers: peers, presences: presences))
```

- [ ] **Step 2.2:** `submodules/TelegramCore/Sources/TelegramEngine/Peers/AddPeerMember.swift:255`

Before:
```swift
return (currentParticipant, RenderedChannelParticipant(participant: updatedParticipant, peer: memberPeer, peers: peers, presences: presences))
```
After:
```swift
return (currentParticipant, RenderedChannelParticipant(participant: updatedParticipant, peer: EnginePeer(memberPeer), peers: peers, presences: presences))
```

- [ ] **Step 2.3:** `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelAdminEventLogs.swift` — 7 constructor wraps

Line 271:
```swift
action = .participantInvite(RenderedChannelParticipant(participant: participant, peer: peer))
// becomes:
action = .participantInvite(RenderedChannelParticipant(participant: participant, peer: EnginePeer(peer)))
```

Line 279 (two constructors on one line):
```swift
action = .participantToggleBan(prev: RenderedChannelParticipant(participant: prevParticipant, peer: prevPeer), new: RenderedChannelParticipant(participant: newParticipant, peer: newPeer))
// becomes:
action = .participantToggleBan(prev: RenderedChannelParticipant(participant: prevParticipant, peer: EnginePeer(prevPeer)), new: RenderedChannelParticipant(participant: newParticipant, peer: EnginePeer(newPeer)))
```

Line 287 (two constructors on one line):
```swift
action = .participantToggleAdmin(prev: RenderedChannelParticipant(participant: prevParticipant, peer: prevPeer), new: RenderedChannelParticipant(participant: newParticipant, peer: newPeer))
// becomes:
action = .participantToggleAdmin(prev: RenderedChannelParticipant(participant: prevParticipant, peer: EnginePeer(prevPeer)), new: RenderedChannelParticipant(participant: newParticipant, peer: EnginePeer(newPeer)))
```

Line 483 (two constructors on one line):
```swift
action = .participantSubscriptionExtended(prev: RenderedChannelParticipant(participant: prevParticipant, peer: prevPeer), new: RenderedChannelParticipant(participant: newParticipant, peer: newPeer))
// becomes:
action = .participantSubscriptionExtended(prev: RenderedChannelParticipant(participant: prevParticipant, peer: EnginePeer(prevPeer)), new: RenderedChannelParticipant(participant: newParticipant, peer: EnginePeer(newPeer)))
```

- [ ] **Step 2.4:** `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelBlacklist.swift:140`

Before:
```swift
return (currentParticipant, RenderedChannelParticipant(participant: updatedParticipant, peer: memberPeer, peers: peers, presences: presences), isMember)
```
After:
```swift
return (currentParticipant, RenderedChannelParticipant(participant: updatedParticipant, peer: EnginePeer(memberPeer), peers: peers, presences: presences), isMember)
```

- [ ] **Step 2.5:** `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelMembers.swift:115`

Before:
```swift
items.append(RenderedChannelParticipant(participant: participant, peer: peer, peers: peers, presences: renderedPresences))
```
After:
```swift
items.append(RenderedChannelParticipant(participant: participant, peer: EnginePeer(peer), peers: peers, presences: renderedPresences))
```

- [ ] **Step 2.6:** `submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelOwnershipTransfer.swift:180`

Before:
```swift
return [(currentCreator, RenderedChannelParticipant(participant: updatedPreviousCreator, peer: accountUser, peers: peers, presences: presences)), (currentParticipant, RenderedChannelParticipant(participant: updatedParticipant, peer: user, peers: peers, presences: presences))]
```
After:
```swift
return [(currentCreator, RenderedChannelParticipant(participant: updatedPreviousCreator, peer: EnginePeer(accountUser), peers: peers, presences: presences)), (currentParticipant, RenderedChannelParticipant(participant: updatedParticipant, peer: EnginePeer(user), peers: peers, presences: presences))]
```

- [ ] **Step 2.7:** `submodules/TelegramCore/Sources/TelegramEngine/Peers/JoinChannel.swift:82`

Before:
```swift
return RenderedChannelParticipant(participant: updatedParticipant, peer: peer, peers: peers, presences: presences)
```
After:
```swift
return RenderedChannelParticipant(participant: updatedParticipant, peer: EnginePeer(peer), peers: peers, presences: presences)
```

- [ ] **Step 2.8:** `submodules/TelegramCore/Sources/TelegramEngine/Peers/PeerAdmins.swift:262`

Before:
```swift
return (currentParticipant, RenderedChannelParticipant(participant: updatedParticipant, peer: adminPeer, peers: peers, presences: presences))
```
After:
```swift
return (currentParticipant, RenderedChannelParticipant(participant: updatedParticipant, peer: EnginePeer(adminPeer), peers: peers, presences: presences))
```

- [ ] **Step 2.9:** `submodules/TelegramCore/Sources/TelegramEngine/Peers/Ranks.swift:95`

Before:
```swift
return (currentParticipant, RenderedChannelParticipant(participant: updatedParticipant, peer: user, peers: peers, presences: presences))
```
After:
```swift
return (currentParticipant, RenderedChannelParticipant(participant: updatedParticipant, peer: EnginePeer(user), peers: peers, presences: presences))
```

---

## Task 3: Consumer — PeerInfoUI/ChannelAdminsController.swift

**File:** `submodules/PeerInfoUI/Sources/ChannelAdminsController.swift`

- [ ] **Step 3.1:** Line 326 — DROP `EnginePeer(participant.peer)` wrap.

Before:
```swift
return ItemListPeerItem(presentationData: presentationData, systemStyle: .glass, dateTimeFormat: dateTimeFormat, nameDisplayOrder: nameDisplayOrder, context: arguments.context, peer: EnginePeer(participant.peer), presence: participant.presences[participant.peer.id].flatMap { EnginePeer.Presence($0) }, text: peerText.isEmpty ? .presence : .text(peerText, .secondary), label: label, editing: editing, revealOptions: revealOptions, switchValue: nil, enabled: enabled, selectable: true, sectionId: self.section, action: action, setPeerIdWithRevealedOptions: { previousId, id in
```
After: replace `peer: EnginePeer(participant.peer)` → `peer: participant.peer` (leave the rest of the line intact).

- [ ] **Step 3.2:** Line 921 — DROP `._asPeer()` in constructor.

Before:
```swift
result.append(RenderedChannelParticipant(participant: .creator(id: peer.id, adminInfo: nil, rank: rank), peer: peer._asPeer(), presences: presences))
```
After:
```swift
result.append(RenderedChannelParticipant(participant: .creator(id: peer.id, adminInfo: nil, rank: rank), peer: peer, presences: presences))
```
(`peer` here is already `EnginePeer` — confirmed by surrounding code where `creatorPeer: EnginePeer?` is assigned from this same loop variable.)

- [ ] **Step 3.3:** Line 926 — DROP `._asPeer()` in constructor.

Before:
```swift
result.append(RenderedChannelParticipant(participant: .member(id: peer.id, invitedAt: 0, adminInfo: ChannelParticipantAdminInfo(rights: TelegramChatAdminRights(rights: .internal_groupSpecific), promotedBy: creator.id, canBeEditedByAccountPeer: creator.id == context.account.peerId), banInfo: nil, rank: rank, subscriptionUntilDate: nil), peer: peer._asPeer(), peers: peers.mapValues({ $0._asPeer() }), presences: presences))
```
After: change `peer: peer._asPeer()` → `peer: peer`. Leave `peers.mapValues({ $0._asPeer() })` intact — `peers` field is unchanged.

---

## Task 4: Consumer — PeerInfoUI/ChannelBlacklistController.swift

**File:** `submodules/PeerInfoUI/Sources/ChannelBlacklistController.swift`

- [ ] **Step 4.1:** Line 170 (or 381 — the site installed by wave 39; the file has one site `EnginePeer(participant.peer)`)

Before:
```swift
peer: EnginePeer(participant.peer)
```
After:
```swift
peer: participant.peer
```

Note: the file may have a single such site; use:
```
grep -n 'EnginePeer(participant\.peer)' submodules/PeerInfoUI/Sources/ChannelBlacklistController.swift
```
and DROP every match.

---

## Task 5: Consumer — PeerInfoUI/ChannelMembersController.swift

**File:** `submodules/PeerInfoUI/Sources/ChannelMembersController.swift`

- [ ] **Step 5.1:** Line 305 — CAST rewrite.

Before:
```swift
if let user = participant.peer as? TelegramUser, let _ = user.botInfo {
```
After:
```swift
if case let .user(user) = participant.peer, let _ = user.botInfo {
```

- [ ] **Step 5.2:** Line 334 — DROP wrap.

Before:
```swift
peer: EnginePeer(participant.peer)
```
After:
```swift
peer: participant.peer
```

- [ ] **Step 5.3:** Line 707 — DROP wrap (the wave-39-installed Shape-C wrap).

Before:
```swift
peer: EnginePeer(participant.peer)
```
After:
```swift
peer: participant.peer
```

---

## Task 6: Consumer — PeerInfoUI/ChannelMembersSearchContainerNode.swift

**File:** `submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift`

This file has the most sites (4 CAST, 3 DROP pairs, 3 ADD-WRAP constructor sites).

- [ ] **Step 6.1:** Line 212 — DROP two wraps on one line.

Before:
```swift
peer: .peer(peer: EnginePeer(participant.peer), chatPeer: EnginePeer(participant.peer)),
```
After:
```swift
peer: .peer(peer: participant.peer, chatPeer: participant.peer),
```

- [ ] **Step 6.2:** Line 223 — DROP wrap.

Before:
```swift
interaction.peerSelected(EnginePeer(participant.peer), participant)
```
After:
```swift
interaction.peerSelected(participant.peer, participant)
```

- [ ] **Step 6.3:** Line 752 — CAST rewrite.

Before:
```swift
if excludeBots, let user = participant.peer as? TelegramUser, user.botInfo != nil {
```
After:
```swift
if excludeBots, case let .user(user) = participant.peer, user.botInfo != nil {
```

- [ ] **Step 6.4:** Line 884 — CAST rewrite. Same pattern as 6.3.

- [ ] **Step 6.5:** Line 987 — ADD-WRAP constructor.

Before:
```swift
renderedParticipant = RenderedChannelParticipant(participant: .creator(id: peer.id, adminInfo: nil, rank: nil), peer: peer)
```
After:
```swift
renderedParticipant = RenderedChannelParticipant(participant: .creator(id: peer.id, adminInfo: nil, rank: nil), peer: EnginePeer(peer))
```
(`peer` here is raw `Peer` from `peerView.peers[participant.peerId]` — confirmed by surrounding iteration code.)

- [ ] **Step 6.6:** Line 994 — ADD-WRAP constructor.

Change `peer: peer` to `peer: EnginePeer(peer)`. Full site for reference:
```swift
renderedParticipant = RenderedChannelParticipant(participant: .member(id: peer.id, invitedAt: 0, adminInfo: ChannelParticipantAdminInfo(rights: TelegramChatAdminRights(rights: TelegramChatAdminRightsFlags.peerSpecific(peer: .legacyGroup(group))), promotedBy: creatorPeer?.id ?? context.account.peerId, canBeEditedByAccountPeer: creatorPeer?.id == context.account.peerId), banInfo: nil, rank: nil, subscriptionUntilDate: nil), peer: peer, peers: peers.mapValues({ $0._asPeer() }))
```
Change only `peer: peer,` → `peer: EnginePeer(peer),`.

- [ ] **Step 6.7:** Line 998 — ADD-WRAP constructor.

```swift
renderedParticipant = RenderedChannelParticipant(participant: .member(id: peer.id, invitedAt: 0, adminInfo: nil, banInfo: nil, rank: nil, subscriptionUntilDate: nil), peer: peer, peers: peers.mapValues({ $0._asPeer() }))
```
Change only `peer: peer,` → `peer: EnginePeer(peer),`.

- [ ] **Step 6.8:** Line 1052 — CAST rewrite. Same pattern as 6.3.

- [ ] **Step 6.9:** Line 1136 — CAST rewrite. Same pattern as 6.3.

---

## Task 7: Consumer — PeerInfoUI/ChannelMembersSearchControllerNode.swift

**File:** `submodules/PeerInfoUI/Sources/ChannelMembersSearchControllerNode.swift`

- [ ] **Step 7.1:** Line 148 — DROP wrap.

Before:
```swift
peer: EnginePeer(participant.peer)
```
After:
```swift
peer: participant.peer
```
(The line has the wrap appearing twice — search the file for `EnginePeer(participant.peer)` and drop each occurrence. Use Edit with `replace_all` if unambiguous.)

- [ ] **Step 7.2:** Line 404 — ADD-WRAP constructor.

Before:
```swift
renderedParticipant = RenderedChannelParticipant(participant: .creator(id: peer.id, adminInfo: nil, rank: nil), peer: peer, presences: peerView.peerPresences)
```
After:
```swift
renderedParticipant = RenderedChannelParticipant(participant: .creator(id: peer.id, adminInfo: nil, rank: nil), peer: EnginePeer(peer), presences: peerView.peerPresences)
```

- [ ] **Step 7.3:** Line 409 — ADD-WRAP constructor.

Change `peer: peer,` → `peer: EnginePeer(peer),` in the full line:
```swift
renderedParticipant = RenderedChannelParticipant(participant: .member(id: peer.id, invitedAt: 0, adminInfo: ChannelParticipantAdminInfo(rights: TelegramChatAdminRights(rights: TelegramChatAdminRightsFlags.peerSpecific(peer: EnginePeer(mainPeer))), promotedBy: creator.id, canBeEditedByAccountPeer: creator.id == context.account.peerId), banInfo: nil, rank: nil, subscriptionUntilDate: nil), peer: peer, peers: peers.mapValues({ $0._asPeer() }), presences: peerView.peerPresences)
```

- [ ] **Step 7.4:** Line 413 — ADD-WRAP constructor. Same `peer: peer,` → `peer: EnginePeer(peer),`.

- [ ] **Step 7.5:** Line 516 — CAST rewrite.

Before:
```swift
if let user = participant.peer as? TelegramUser, user.botInfo != nil {
```
After:
```swift
if case let .user(user) = participant.peer, user.botInfo != nil {
```

- [ ] **Step 7.6:** Line 558 — CAST rewrite. Same pattern as 7.5.

---

## Task 8: Consumer — PeerInfoUI/ChannelPermissionsController.swift

**File:** `submodules/PeerInfoUI/Sources/ChannelPermissionsController.swift`

- [ ] **Step 8.1:** Lines 480 and 483 — DROP wraps.

Both lines contain `EnginePeer(participant.peer)`. Change each to `participant.peer`.

If the two occurrences are unambiguous, use Edit with `replace_all=true` on `EnginePeer(participant.peer)` → `participant.peer`.

---

## Task 9: Consumer — SearchPeerMembers/SearchPeerMembers.swift

**File:** `submodules/SearchPeerMembers/Sources/SearchPeerMembers.swift`

- [ ] **Step 9.1:** Lines 30, 36, 61, 76 — DROP wraps.

All four sites are `EnginePeer(participant.peer)`. Use Edit with `replace_all=true`:
- old: `EnginePeer(participant.peer)`
- new: `participant.peer`

Verify with `grep -n 'EnginePeer(participant\.peer)' submodules/SearchPeerMembers/Sources/SearchPeerMembers.swift` → should return empty after edit.

---

## Task 10: Consumer — ChatRecentActionsController.swift

**File:** `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsController.swift`

- [ ] **Step 10.1:** Line 359 — DROP wrap.

Before:
```swift
EnginePeer(participant.peer)
```
After:
```swift
participant.peer
```

---

## Task 11: Consumer — ChatRecentActionsFilterController.swift

**File:** `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsFilterController.swift`

- [ ] **Step 11.1:** Line 217 — DROP wrap.

Change `EnginePeer(participant.peer)` → `participant.peer` on line 217.

- [ ] **Step 11.2:** Line 445 — ADD-WRAP constructor rewrite.

Before:
```swift
if let peer = peer, case let .user(user) = peer {
    return RenderedChannelParticipant(participant: .member(id: user.id, invitedAt: 0, adminInfo: nil, banInfo: nil, rank: nil, subscriptionUntilDate: nil), peer: user)
}
```
After:
```swift
if let peer = peer, case let .user(user) = peer {
    return RenderedChannelParticipant(participant: .member(id: user.id, invitedAt: 0, adminInfo: nil, banInfo: nil, rank: nil, subscriptionUntilDate: nil), peer: .user(user))
}
```
(`.user(user)` is the enum case `EnginePeer.user(TelegramUser)`. Alternative: `peer: EnginePeer(user)` or `peer: peer` — but `peer: peer` reuses the already-unwrapped EnginePeer and is the cleanest. Use `peer: peer`.)

Preferred after:
```swift
if let peer = peer, case let .user(user) = peer {
    return RenderedChannelParticipant(participant: .member(id: user.id, invitedAt: 0, adminInfo: nil, banInfo: nil, rank: nil, subscriptionUntilDate: nil), peer: peer)
}
```

---

## Task 12: Consumer — ChatRecentActionsHistoryTransition.swift

**File:** `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsHistoryTransition.swift`

This is the highest-volume consumer file (12 `EnginePeer(new.peer)` sites + 2 ADD-ASPEER sites).

- [ ] **Step 12.1:** DROP all `EnginePeer(new.peer)` wraps.

Use Edit with `replace_all=true`:
- old: `EnginePeer(new.peer)`
- new: `new.peer`

After: grep `EnginePeer(new\.peer)` should return empty.

- [ ] **Step 12.2:** Line 675 — ADD-ASPEER.

Before:
```swift
peers[participant.peer.id] = participant.peer
```
After:
```swift
peers[participant.peer.id] = participant.peer._asPeer()
```
(Target dict is `SimpleDictionary<PeerId, Peer>`; the value side needs raw Peer.)

- [ ] **Step 12.3:** Line 2275 — ADD-ASPEER.

Before:
```swift
peers[new.peer.id] = new.peer
```
After:
```swift
peers[new.peer.id] = new.peer._asPeer()
```

---

## Task 13: Consumer — PeerInfoMembers.swift

**File:** `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoMembers.swift`

- [ ] **Step 13.1:** Line 33 — ADD-ASPEER.

Before:
```swift
var peer: Peer {
    switch self {
    case let .channelMember(participant, _):
        return participant.peer
```
After:
```swift
var peer: Peer {
    switch self {
    case let .channelMember(participant, _):
        return participant.peer._asPeer()
```

No other edits in this file. The `participant.peer.id` accesses at lines 22, 44 are ZERO; `item.peer.id` at line 171 is ZERO.

---

## Task 14: Consumer — ShareWithPeersScreenState.swift

**File:** `submodules/TelegramUI/Components/ShareWithPeersScreen/Sources/ShareWithPeersScreenState.swift`

- [ ] **Step 14.1:** Line 558 — DROP wrap.

Before:
```swift
peers.append(EnginePeer(participant.peer))
```
After:
```swift
peers.append(participant.peer)
```

- [ ] **Step 14.2:** Line 566 — CAST rewrite.

Before:
```swift
if let user = participant.peer as? TelegramUser, user.botInfo != nil {
```
After:
```swift
if case let .user(user) = participant.peer, user.botInfo != nil {
```

- [ ] **Step 14.3:** Line 576 — DROP wrap.

Before:
```swift
peers.append(EnginePeer(participant.peer))
```
After:
```swift
peers.append(participant.peer)
```

---

## Task 15: Consumer — AdminUserActionsSheet.swift

**File:** `submodules/TelegramUI/Components/AdminUserActionsSheet/Sources/AdminUserActionsSheet.swift`

This file has ~6 `EnginePeer(peer.peer)` / `EnginePeer(component.peers[0].peer)` wraps and many ZERO sites.

- [ ] **Step 15.1:** Use Edit with `replace_all=true`:
- old: `EnginePeer(peer.peer)`
- new: `peer.peer`

This covers lines 284, 522, 523.

- [ ] **Step 15.2:** Edit the `EnginePeer(component.peers[0].peer)` sites at lines 404, 416, 417.

Use Edit with `replace_all=true`:
- old: `EnginePeer(component.peers[0].peer)`
- new: `component.peers[0].peer`

- [ ] **Step 15.3:** Verify no other `EnginePeer(` wraps around `.peer` accesses remain on `RenderedChannelParticipant`. Run:
```
grep -n 'EnginePeer(.*\.peer)' submodules/TelegramUI/Components/AdminUserActionsSheet/Sources/AdminUserActionsSheet.swift
```
Confirm remaining matches are on non-RCP types (e.g., some other context-derived peer).

---

## Task 16: Consumer — StoryContentLiveChatComponent.swift

**File:** `submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryContentLiveChatComponent.swift`

- [ ] **Step 16.1:** Line 370 — DROP `._asPeer()` in constructor.

Before:
```swift
peer: author._asPeer()
```
After:
```swift
peer: author
```
(`author` is `EnginePeer` — confirmed by the surrounding code that uses `author.id` and by the `chatPeer` signal's return type.)

---

## Task 17: Consumer — ChatControllerAdminBanUsers.swift

**File:** `submodules/TelegramUI/Sources/ChatControllerAdminBanUsers.swift`

- [ ] **Step 17.1:** Line 226 — ADD-WRAP constructor.

Before:
```swift
let peer = author
renderedParticipants.append(RenderedChannelParticipant(
    participant: participant,
    peer: peer
))
```
After:
```swift
let peer = author
renderedParticipants.append(RenderedChannelParticipant(
    participant: participant,
    peer: EnginePeer(peer)
))
```
(Confirmed `author` is raw `Peer` via `presentMultiBanMessageOptions(... authors: [Peer], ...)` signature on line 45.)

- [ ] **Step 17.2:** Line 372 — DROP `._asPeer()` in constructor.

Before:
```swift
peer: authorPeer._asPeer()
```
After:
```swift
peer: authorPeer
```
(Confirmed `authorPeer` is `EnginePeer?` at line 327 via `engine.data.get(Peer.Peer(id:))` signal; already guard-unwrapped.)

- [ ] **Step 17.3:** Line 757 — DROP `._asPeer()` in constructor.

Same edit pattern as 17.2: `peer: authorPeer._asPeer()` → `peer: authorPeer`.

---

## Task 18: Full build verification

- [ ] **Step 18.1:** Run the full build with `--continueOnError`.

```sh
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 --configuration=debug_sim_arm64 --continueOnError
```

Expected: build success. First-pass-clean is the goal (wave-39 pattern applies — classification is exact, migration is mechanical, no inference-bearing return types).

If the build fails, expect errors only in files in this plan. Any error outside the plan's file list is either:
- a pre-existing unrelated WIP (e.g., `ChatMessageTransitionNode.swift`) — not a wave-41 issue
- a genuine miss in pre-flight classification — record which file, update the plan, and re-run

For each error in wave-41 files:
1. Read the error
2. Classify: is it a shape we mis-identified (ZERO that's not actually transparent) or a new shape (dict subscript, function arg to a `Peer`-typed param, etc.)?
3. Apply the appropriate fix (`._asPeer()` if raw Peer needed; unwrap the wrap if EnginePeer needed)
4. Re-run the build

Budget: 1–3 build iterations.

- [ ] **Step 18.2:** Post-build grep verification.

Run these greps and confirm they return only the expected residual matches:

```sh
grep -rn 'EnginePeer(participant\.peer)' submodules/ --include='*.swift' | grep -v submodules/TelegramCore/ | grep -v submodules/Postbox/
```
Expected: empty.

```sh
grep -rn 'EnginePeer(new\.peer)' submodules/ --include='*.swift' | grep -v submodules/TelegramCore/
```
Expected: empty.

```sh
grep -rn 'participant\.peer as\? TelegramUser' submodules/ --include='*.swift'
```
Expected: empty.

```sh
grep -n 'public let peer:' submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelParticipants.swift
```
Expected: `public let peer: EnginePeer`.

---

## Task 19: Commit

- [ ] **Step 19.1:** Stage only wave-41 files (explicitly enumerate — wave-39 lesson).

```sh
git status --short
```

Inspect the output. Only wave-41 files should appear as modified. If pre-existing WIP (e.g., `submodules/TelegramUI/Sources/ChatMessageTransitionNode.swift`) is also modified, do NOT include it in the commit.

```sh
git add \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelParticipants.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Messages/RequestStartBot.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/AddPeerMember.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelAdminEventLogs.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelBlacklist.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelMembers.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/ChannelOwnershipTransfer.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/JoinChannel.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/PeerAdmins.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Peers/Ranks.swift \
  submodules/PeerInfoUI/Sources/ChannelAdminsController.swift \
  submodules/PeerInfoUI/Sources/ChannelBlacklistController.swift \
  submodules/PeerInfoUI/Sources/ChannelMembersController.swift \
  submodules/PeerInfoUI/Sources/ChannelMembersSearchContainerNode.swift \
  submodules/PeerInfoUI/Sources/ChannelMembersSearchControllerNode.swift \
  submodules/PeerInfoUI/Sources/ChannelPermissionsController.swift \
  submodules/SearchPeerMembers/Sources/SearchPeerMembers.swift \
  submodules/TelegramUI/Components/AdminUserActionsSheet/Sources/AdminUserActionsSheet.swift \
  submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsController.swift \
  submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsFilterController.swift \
  submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsHistoryTransition.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoMembers.swift \
  submodules/TelegramUI/Components/ShareWithPeersScreen/Sources/ShareWithPeersScreenState.swift \
  submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryContentLiveChatComponent.swift \
  submodules/TelegramUI/Sources/ChatControllerAdminBanUsers.swift \
  docs/superpowers/specs/2026-04-24-renderedchannelparticipant-peer-engine-peer-migration-design.md \
  docs/superpowers/plans/2026-04-24-renderedchannelparticipant-peer-engine-peer-migration.md
```

(Add any additional files the build iterations surfaced.)

Run `git status --short` and confirm only staged wave-41 files are green, and any unrelated WIP is still marked as unstaged.

- [ ] **Step 19.2:** Commit.

```sh
git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 41

Migrate RenderedChannelParticipant.peer from Postbox `Peer` to
TelegramCore `EnginePeer`. 27 files touched: 10 TelegramCore
(1 struct + 9 files with constructor wraps) + 17 consumer files.

Drops the 2 Shape-C wraps installed by wave 39 (ChannelMembersController
and ChannelBlacklistController) plus ~37 additional EnginePeer(...) /
._asPeer() bridges across the consumer surface. Net ~-14 bridges
after the 16 TelegramCore-internal EnginePeer(peer) wraps and the 7
consumer ADD-WRAP constructor sites. RCP.peers and RCP.presences
dictionaries remain Postbox-typed (deferred).
EOF
)"
```

- [ ] **Step 19.3:** Confirm commit landed and working tree is clean except for pre-existing WIP.

```sh
git status --short
git log -1 --oneline
```

---

## Task 20: Log the wave outcome

- [ ] **Step 20.1:** Append wave 41 entry to `docs/superpowers/postbox-refactor-log.md`.

Format (matching prior wave entries):

```markdown
## Wave 41 outcome — RenderedChannelParticipant.peer: Peer → EnginePeer (2026-04-24)

Landed as commit `<hash>`. 27 files / ~45 site edits / net ~-14 bridges.

**Shape distribution:**
- TelegramCore: 16 constructor sites wrapped with `EnginePeer(peer)` across 9 files + struct field migrated in ChannelParticipants.swift
- Consumers: ~32 DROP (EnginePeer/._asPeer unwraps), 9 CAST (as? TelegramUser → if case let .user), 3 ADD-ASPEER, 7 ADD-WRAP constructor sites

**First-pass-clean:** <yes|no, iterations count>. Extends wave-39 lesson: first-pass-clean
is achievable when classification is exact and all patterns are mechanical.

**Ratchet economics:** drops 2 wave-39 Shape-C wraps
(ChannelMembersController:707, ChannelBlacklistController:381) and installs 7 ADD-WRAP
consumer constructor sites as ratchet markers for a future
`RenderedChannelParticipant.peers: [PeerId: Peer] → [EnginePeer.Id: EnginePeer]` wave.

**Spec:** `docs/superpowers/specs/2026-04-24-renderedchannelparticipant-peer-engine-peer-migration-design.md`.
**Plan:** `docs/superpowers/plans/2026-04-24-renderedchannelparticipant-peer-engine-peer-migration.md`.
```

- [ ] **Step 20.2:** Update the `project_postbox_refactor_next_wave.md` memory file with the wave 41 outcome and the wave 42 candidate (likely `PeerInfoScreenData.peer → EnginePeer`).

- [ ] **Step 20.3:** Commit docs updates.

```sh
git add docs/superpowers/postbox-refactor-log.md
git commit -m "$(cat <<'EOF'
docs: log wave 41 outcome
EOF
)"
```
