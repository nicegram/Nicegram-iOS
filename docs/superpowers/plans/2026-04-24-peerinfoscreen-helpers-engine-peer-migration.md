# Wave 43 plan: PeerInfoScreen helpers `peer: Peer?` → `peer: EnginePeer?`

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate six PeerInfoScreen module helpers (`canEditPeerInfo`, `availableActionsForMemberOfPeer`, `peerInfoHeaderActionButtons`, `peerInfoHeaderButtons`, `peerInfoCanEdit`, `peerInfoIsChatMuted`) from `peer: Peer?` to `peer: EnginePeer?`, rewriting internal `as?`/`is` against concrete `TelegramX` subclasses to `case let .x` / `case .x` enum patterns on `EnginePeer`, and updating all 21 call sites to drop wave-42-installed `._asPeer()` / `?._asPeer()` bridges or add `.flatMap(EnginePeer.init)` / `EnginePeer(...)` wraps as appropriate.

**Architecture:** In-place signature migration following wave-42 precedent — no new typealiases, no engine wrapper structs, no TelegramCore changes. All edits within `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/` (10 files). Single atomic commit.

**Tech Stack:** Swift, Bazel build, `EnginePeer` enum cases (`.user(TelegramUser)`, `.legacyGroup(TelegramGroup)`, `.channel(TelegramChannel)`, `.secretChat(TelegramSecretChat)`).

**Preceding waves:** 42 (`PeerInfoScreenData.peer: Peer? → EnginePeer?`) on 2026-04-24. This wave drops ~7 `?._asPeer()` / `._asPeer()` bridges installed then.

**Expected net wrap change:** ~7 DROPs vs ~12 ADDs → net roughly 0. The headline win is helper-signature migration, not wrap count. Follow-up waves migrating `PeerInfoHeaderEditingContentNode.update`, `PeerInfoEditingAvatarNode.update`, `PeerInfoEditingAvatarOverlayNode.update`, `PeerInfoHeaderNode.update`, `PeerInfoScreenMemberItem.enclosingPeer`, `PeerInfoMembersPane` enclosingPeer param will drop the ADDs introduced here.

**Build expectation:** 2 iterations likely (per wave-41 lesson — foundational-type migrations rarely first-pass-clean). Hedge for iteration-3 if unexpected property accesses surface.

---

## Pre-flight facts (verified from repo 2026-04-24)

### EnginePeer cases (from `submodules/TelegramCore/Sources/TelegramEngine/Peers/Peer.swift:177`)

```
case user(TelegramUser)
case legacyGroup(TelegramGroup)
case channel(TelegramChannel)
case secretChat(TelegramSecretChat)
```

Forwarded property subset on `EnginePeer` includes `id`, `addressName`, `usernames`, `indexName`, `debugDisplayTitle`, `displayLetters`, `profileImageRepresentations`, `smallProfileImage`, `largeProfileImage`, `isDeleted`, `isScam`, `isFake`, `isVerified`, `isPremium`, `isSubscription`, `isService`, `nameColor`, `verificationIconFileId`, `profileColor`, `effectiveProfileColor`, `emojiStatus`, `backgroundEmojiId`, `profileBackgroundEmojiId`, and (via `LocalizedPeerData/Sources/PeerTitle.swift`) `compactDisplayTitle`, `displayTitle(strings:displayOrder:)`. **Not** forwarded: Peer-specific members like `isCopyProtectionEnabled`, `hasPermission(_:)`, `hasBannedPermission(_:)`, `isDeleted` on user (WAIT: yes forwarded). **Internal helper bodies do not access any non-forwarded Peer members** — all their concrete-type work happens via `as? TelegramX`, which is enum-rewrite territory. Confirmed by reading helper bodies (PeerInfoData.swift:2255–2670).

### Helper call sites inventory (21 sites across 10 files)

Running command:

```bash
grep -rn "\bcanEditPeerInfo\b\|\bavailableActionsForMemberOfPeer\b\|\bpeerInfoHeaderActionButtons\b\|\bpeerInfoHeaderButtons\b\|\bpeerInfoCanEdit\b\|\bpeerInfoIsChatMuted\b" submodules/ --include="*.swift" | grep -v PeerInfoData.swift
```

All 21 call sites:

| # | File | Line | Current arg | Peer var origin | Action |
|---|------|------|-------------|-----------------|--------|
| 1 | `PeerInfoHeaderNode.swift` | 548 | `peer: peer` | method param `peer: Peer?` | ADD-WRAP: `peer: peer.flatMap(EnginePeer.init)` |
| 2 | `PeerInfoHeaderNode.swift` | 549 | `peer: peer` | same | ADD-WRAP |
| 3 | `PeerInfoHeaderNode.swift` | 2361 | `peer: peer` | same | ADD-WRAP |
| 4 | `PeerInfoEditingAvatarNode.swift` | 66 | `peer: peer` | method param `peer: Peer?` (unwrapped via `guard let peer = peer`) | ADD-WRAP: `peer: EnginePeer(peer)` (peer is non-optional `Peer` here) |
| 5 | `PeerInfoEditingAvatarOverlayNode.swift` | 85 | `peer: peer` | method param `peer: Peer?` (unwrapped via `guard let peer = peer`) | ADD-WRAP: `peer: EnginePeer(peer)` |
| 6 | `PeerInfoHeaderEditingContentNode.swift` | 59 | `peer: peer` | method param `peer: Peer?` | ADD-WRAP: `peer: peer.flatMap(EnginePeer.init)` |
| 7 | `PeerInfoHeaderEditingContentNode.swift` | 88 | `peer: peer` | same | ADD-WRAP |
| 8 | `PeerInfoHeaderEditingContentNode.swift` | 93 | `peer: peer` | same | ADD-WRAP |
| 9 | `PeerInfoHeaderEditingContentNode.swift` | 159 | `peer: peer` | same | ADD-WRAP |
| 10 | `PeerInfoHeaderEditingContentNode.swift` | 162 | `peer: peer` | same | ADD-WRAP |
| 11 | `PeerInfoScreenAvatarSetup.swift` | 435 | `peer: peer._asPeer()` | `peer = data.peer` (EnginePeer unwrapped) | DROP: `peer: peer` |
| 12 | `PeerInfoScreenPerformButtonAction.swift` | 62 | `peer: self.data?.peer?._asPeer()` | `self.data?.peer` is `EnginePeer?` | DROP: `peer: self.data?.peer` |
| 13 | `PeerInfoScreenPerformButtonAction.swift` | 397 | `peer: peer._asPeer()` | `peer = data.peer` unwrapped at line 381 | DROP: `peer: peer` |
| 14 | `PeerInfoScreenPerformButtonAction.swift` | 398 | `peer: peer._asPeer()` | same | DROP: `peer: peer` |
| 15 | `PeerInfoScreenOpenMember.swift` | 19 | `peer: enclosingPeer._asPeer()` | `enclosingPeer = self.data?.peer` unwrapped at line 14 | DROP: `peer: enclosingPeer` |
| 16 | `PeerInfoScreen.swift` | 1905 | `peer: group` | `group: TelegramGroup` from `if case let .legacyGroup(group) = data.peer` | CONVERT: `peer: data.peer` |
| 17 | `PeerInfoScreen.swift` | 1961 | `peer: channel` | `channel: TelegramChannel` from `if case let .channel(channel) = data.peer` | CONVERT: `peer: data.peer` |
| 18 | `PeerInfoScreen.swift` | 5857 | `peer: self.data?.peer?._asPeer()` | `self.data?.peer` is `EnginePeer?` | DROP: `peer: self.data?.peer` |
| 19 | `PeerInfoProfileItems.swift` | 853 | `peer: peer._asPeer()` | `peer = data.peer` unwrapped at line 821 | DROP: `peer: peer` |
| 20 | `PeerInfoScreenMemberItem.swift` | 178 | `peer: item.enclosingPeer` | `item.enclosingPeer: Peer` (stored raw) | ADD-WRAP: `peer: EnginePeer(item.enclosingPeer)` |
| 21 | `PeerInfoMembersPane.swift` | 139 | `peer: enclosingPeer` | `enclosingPeer: Peer` (local raw) | ADD-WRAP: `peer: EnginePeer(enclosingPeer)` |

**Summary:** 7 DROPs (sites 11–15, 18, 19), 10 ADD-WRAPs (1–10, 20, 21 = 12 total ADDs), 2 CONVERTs (16, 17 — from concrete-type arg to whole-EnginePeer; no wrap delta but simpler/safer).

### `is TelegramX` scan on helper bodies

Only `peerInfoIsChatMuted` has them (PeerInfoData.swift:2641, 2643). Rewrite pattern: `if peer is TelegramUser` → `if case .user = peer`, `else if peer is TelegramGroup` → `else if case .legacyGroup = peer`.

No `is TelegramX` checks exist at call sites for these specific helpers (wave-42 would have caught them since call-site `data.peer` is already `EnginePeer?`).

---

## File Structure

All edits within `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/`:

**Modify (helper definitions):**
- `PeerInfoData.swift:2265–2670` — 6 helper signatures + bodies

**Modify (call sites):**
- `PeerInfoScreen.swift` (3 sites: 1905, 1961, 5857)
- `PeerInfoHeaderNode.swift` (3 sites: 548, 549, 2361)
- `PeerInfoEditingAvatarNode.swift` (1 site: 66)
- `PeerInfoEditingAvatarOverlayNode.swift` (1 site: 85)
- `PeerInfoHeaderEditingContentNode.swift` (5 sites: 59, 88, 93, 159, 162)
- `PeerInfoScreenAvatarSetup.swift` (1 site: 435)
- `PeerInfoScreenPerformButtonAction.swift` (3 sites: 62, 397, 398)
- `PeerInfoScreenOpenMember.swift` (1 site: 19)
- `PeerInfoProfileItems.swift` (1 site: 853)
- `ListItems/PeerInfoScreenMemberItem.swift` (1 site: 178)
- `Panes/PeerInfoMembersPane.swift` (1 site: 139)

Total: 10 files modified (PeerInfoData.swift counts once).

---

### Task 1: Migrate the six helper signatures and bodies in `PeerInfoData.swift`

**Files:**
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoData.swift:2265–2670`

- [ ] **Step 1: Migrate `canEditPeerInfo` (line 2265).** Signature: `peer: Peer?` → `peer: EnginePeer?`. Body rewrites:

```swift
// before (line 2269-2287)
if let user = peer as? TelegramUser, let botInfo = user.botInfo {
    return botInfo.flags.contains(.canEdit)
} else if let channel = peer as? TelegramChannel {
    if let threadData = threadData {
        if chatLocation.threadId == 1 {
            return false
        }
        if channel.hasPermission(.manageTopics) {
            return true
        }
        if threadData.author == context.account.peerId {
            return true
        }
    } else {
        if channel.hasPermission(.changeInfo) {
            return true
        }
    }
} else if let group = peer as? TelegramGroup {
    switch group.role {
    case .admin, .creator:
        return true
    case .member:
        break
    }
    if !group.hasBannedPermission(.banChangeInfo) {
        return true
    }
}

// after
if case let .user(user) = peer, let botInfo = user.botInfo {
    return botInfo.flags.contains(.canEdit)
} else if case let .channel(channel) = peer {
    if let threadData = threadData {
        if chatLocation.threadId == 1 {
            return false
        }
        if channel.hasPermission(.manageTopics) {
            return true
        }
        if threadData.author == context.account.peerId {
            return true
        }
    } else {
        if channel.hasPermission(.changeInfo) {
            return true
        }
    }
} else if case let .legacyGroup(group) = peer {
    switch group.role {
    case .admin, .creator:
        return true
    case .member:
        break
    }
    if !group.hasBannedPermission(.banChangeInfo) {
        return true
    }
}
```

The `if context.account.peerId == peer?.id` line (2266) stays identical (`.id` is forwarded by `EnginePeer`).

- [ ] **Step 2: Migrate `availableActionsForMemberOfPeer` (line 2314).** Signature: `peer: Peer?` → `peer: EnginePeer?`. Body rewrites — four `peer as? TelegramChannel/TelegramGroup` sites become `case let .channel/.legacyGroup` patterns:

```swift
// Line 2320: if let channel = peer as? TelegramChannel
// →       : if case let .channel(channel) = peer

// Line 2324: } else if let group = peer as? TelegramGroup {
// →       : } else if case let .legacyGroup(group) = peer {

// Line 2330: if let channel = peer as? TelegramChannel
// →       : if case let .channel(channel) = peer

// Line 2374: } else if let group = peer as? TelegramGroup {
// →       : } else if case let .legacyGroup(group) = peer {
```

The `if peer == nil` check (line 2317) stays identical (Optional == nil works on EnginePeer? too).

- [ ] **Step 3: Migrate `peerInfoHeaderActionButtons` (line 2434).** Signature: `peer: Peer?` → `peer: EnginePeer?`. Single body rewrite at line 2436:

```swift
// before
if !isContact && !isSecretChat, let user = peer as? TelegramUser, user.botInfo == nil {

// after
if !isContact && !isSecretChat, case let .user(user) = peer, user.botInfo == nil {
```

- [ ] **Step 4: Migrate `peerInfoHeaderButtons` (line 2447).** Signature: `peer: Peer?` → `peer: EnginePeer?`. Three body rewrites:

```swift
// Line 2449: if let user = peer as? TelegramUser {
// →       : if case let .user(user) = peer {

// Line 2483: } else if let channel = peer as? TelegramChannel {
// →       : } else if case let .channel(channel) = peer {

// Line 2558: } else if let group = peer as? TelegramGroup {
// →       : } else if case let .legacyGroup(group) = peer {
```

- [ ] **Step 5: Migrate `peerInfoCanEdit` (line 2585).** Signature: `peer: Peer?` → `peer: EnginePeer?`. Three body rewrites. Note: original shadows `peer` inside each branch (`let peer = peer as? TelegramX`). Rewrite preserves the shadowing via `case let`:

```swift
// Line 2586: if let user = peer as? TelegramUser {
// →       : if case let .user(user) = peer {

// Line 2597: } else if let peer = peer as? TelegramChannel {
// →       : } else if case let .channel(peer) = peer {
//           (intentional shadow of outer `peer` with inner `peer: TelegramChannel` — preserved)

// Line 2618: } else if let peer = peer as? TelegramGroup {
// →       : } else if case let .legacyGroup(peer) = peer {
```

- [ ] **Step 6: Migrate `peerInfoIsChatMuted` (line 2633).** Outer signature: `peer: Peer?` → `peer: EnginePeer?`. Inner function signature (line 2634) also migrates: `func isPeerMuted(peer: Peer?, ...)` → `func isPeerMuted(peer: EnginePeer?, ...)`. Body rewrites inside the inner function (line 2641–2651):

```swift
// before (line 2641)
if peer is TelegramUser {
    peerIsMuted = !globalNotificationSettings.privateChats.enabled
} else if peer is TelegramGroup {
    peerIsMuted = !globalNotificationSettings.groupChats.enabled
} else if let channel = peer as? TelegramChannel {
    switch channel.info {
    case .group:
        peerIsMuted = !globalNotificationSettings.groupChats.enabled
    case .broadcast:
        peerIsMuted = !globalNotificationSettings.channels.enabled
    }
}

// after
if case .user = peer {
    peerIsMuted = !globalNotificationSettings.privateChats.enabled
} else if case .legacyGroup = peer {
    peerIsMuted = !globalNotificationSettings.groupChats.enabled
} else if case let .channel(channel) = peer {
    switch channel.info {
    case .group:
        peerIsMuted = !globalNotificationSettings.groupChats.enabled
    case .broadcast:
        peerIsMuted = !globalNotificationSettings.channels.enabled
    }
}
```

The outer `if let peer = peer` (line 2640) stays unchanged (Optional binding works on EnginePeer?).

The inner `peerInfoIsChatMuted` body (line 2659–2669) calls `isPeerMuted(peer: peer, ...)` with the outer `peer` (now EnginePeer?) — works without change because inner signature now matches.

- [ ] **Step 7: Re-read PeerInfoData.swift lines 2265–2670 and visually verify no `as? TelegramX` or `is TelegramX` patterns remain.**

Run: `grep -n "as? TelegramUser\|as? TelegramChannel\|as? TelegramGroup\|is TelegramUser\|is TelegramChannel\|is TelegramGroup" submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoData.swift | awk -F: '$2 >= 2265 && $2 <= 2670'`
Expected: empty output.

---

### Task 2: Update call sites — DROPs (7 sites)

**Files:**
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenAvatarSetup.swift:435`
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenPerformButtonAction.swift:62,397,398`
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenOpenMember.swift:19`
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift:5857`
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoProfileItems.swift:853`

- [ ] **Step 1: DROP at `PeerInfoScreenAvatarSetup.swift:435`.**

```swift
// before
guard let data = self.controllerNode.data, let peer = data.peer, mode != .generic || canEditPeerInfo(context: self.context, peer: peer._asPeer(), chatLocation: self.chatLocation, threadData: data.threadData) else {

// after
guard let data = self.controllerNode.data, let peer = data.peer, mode != .generic || canEditPeerInfo(context: self.context, peer: peer, chatLocation: self.chatLocation, threadData: data.threadData) else {
```

- [ ] **Step 2: DROP at `PeerInfoScreenPerformButtonAction.swift:62`.**

```swift
// before
let chatIsMuted = peerInfoIsChatMuted(peer: self.data?.peer?._asPeer(), peerNotificationSettings: self.data?.peerNotificationSettings, threadNotificationSettings: self.data?.threadNotificationSettings, globalNotificationSettings: self.data?.globalNotificationSettings)

// after
let chatIsMuted = peerInfoIsChatMuted(peer: self.data?.peer, peerNotificationSettings: self.data?.peerNotificationSettings, threadNotificationSettings: self.data?.threadNotificationSettings, globalNotificationSettings: self.data?.globalNotificationSettings)
```

- [ ] **Step 3: DROP at `PeerInfoScreenPerformButtonAction.swift:397 and :398` (peerInfoHeaderButtons, two lines, same pattern `peer: peer._asPeer()` → `peer: peer`).**

Use Edit with `replace_all=true` on the substring `peer: peer._asPeer(), cachedData: data.cachedData` — this exact form appears exactly twice in the file (lines 397, 398), both targets.

```swift
// before (at both 397 and 398)
peerInfoHeaderButtons(peer: peer._asPeer(), cachedData: data.cachedData, isOpenedFromChat: ...

// after
peerInfoHeaderButtons(peer: peer, cachedData: data.cachedData, isOpenedFromChat: ...
```

Verification after edit:

```bash
grep -n "_asPeer()" submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenPerformButtonAction.swift
```
Expected: empty (all three DROPs done).

- [ ] **Step 4: DROP at `PeerInfoScreenOpenMember.swift:19`.**

```swift
// before
let actions = availableActionsForMemberOfPeer(accountPeerId: self.context.account.peerId, peer: enclosingPeer._asPeer(), member: member)

// after
let actions = availableActionsForMemberOfPeer(accountPeerId: self.context.account.peerId, peer: enclosingPeer, member: member)
```

- [ ] **Step 5: DROP at `PeerInfoScreen.swift:5857`.**

```swift
// before
} else if peerInfoCanEdit(peer: self.data?.peer?._asPeer(), chatLocation: self.chatLocation, threadData: self.data?.threadData, cachedData: self.data?.cachedData, isContact: self.data?.isContact) {

// after
} else if peerInfoCanEdit(peer: self.data?.peer, chatLocation: self.chatLocation, threadData: self.data?.threadData, cachedData: self.data?.cachedData, isContact: self.data?.isContact) {
```

- [ ] **Step 6: DROP at `PeerInfoProfileItems.swift:853`.**

Only the `availableActionsForMemberOfPeer` call — the sibling `enclosingPeer: peer._asPeer()` at line 852 is NOT a helper-migration target (it's `PeerInfoScreenMemberItem.enclosingPeer: Peer`, unchanged in this wave).

```swift
// before (line 853)
let actions = availableActionsForMemberOfPeer(accountPeerId: context.account.peerId, peer: peer._asPeer(), member: member)

// after
let actions = availableActionsForMemberOfPeer(accountPeerId: context.account.peerId, peer: peer, member: member)
```

---

### Task 3: Update call sites — CONVERTs (2 sites in PeerInfoScreen.swift)

**Files:**
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift:1905,1961`

At these sites the helper arg is currently a concrete `TelegramGroup` / `TelegramChannel` extracted via case pattern. After migration the helper takes `EnginePeer?`, so pass `data.peer` directly — the helper re-does the pattern match internally, semantics preserved.

- [ ] **Step 1: CONVERT at `PeerInfoScreen.swift:1905`.**

```swift
// before
} else if case let .legacyGroup(group) = data.peer, canEditPeerInfo(context: strongSelf.context, peer: group, chatLocation: chatLocation, threadData: data.threadData) {

// after
} else if case let .legacyGroup(group) = data.peer, canEditPeerInfo(context: strongSelf.context, peer: data.peer, chatLocation: chatLocation, threadData: data.threadData) {
```

`group` stays bound because the body below still uses it. Only the helper arg changes.

- [ ] **Step 2: CONVERT at `PeerInfoScreen.swift:1961`.**

```swift
// before
} else if case let .channel(channel) = data.peer, canEditPeerInfo(context: strongSelf.context, peer: channel, chatLocation: strongSelf.chatLocation, threadData: data.threadData) {

// after
} else if case let .channel(channel) = data.peer, canEditPeerInfo(context: strongSelf.context, peer: data.peer, chatLocation: strongSelf.chatLocation, threadData: data.threadData) {
```

---

### Task 4: Update call sites — ADD-WRAPs in internal-update methods (10 sites in 4 files)

These files' internal `.update(peer: Peer?, ...)` methods are NOT migrated in this wave (scope: helpers only). Each helper call inside bridges `peer` (raw `Peer?`) to `EnginePeer?` via `.flatMap(EnginePeer.init)`, or — where `peer` has already been unwrapped to non-optional `Peer` — via `EnginePeer(peer)`.

**Files:**
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoHeaderNode.swift:548,549,2361`
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoEditingAvatarNode.swift:66`
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoEditingAvatarOverlayNode.swift:85`
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoHeaderEditingContentNode.swift:59,88,93,159,162`

- [ ] **Step 1: ADD-WRAPs at `PeerInfoHeaderNode.swift:548,549,2361`.** At lines 548, 549, the local `peer` is the raw `Peer?` method parameter (line 496). At line 2361 likewise.

```swift
// before (line 548)
let actionButtonKeys: [PeerInfoHeaderButtonKey] = (self.isSettings || self.isMyProfile) ? [] : peerInfoHeaderActionButtons(peer: peer, isSecretChat: isSecretChat, isContact: isContact)

// after
let actionButtonKeys: [PeerInfoHeaderButtonKey] = (self.isSettings || self.isMyProfile) ? [] : peerInfoHeaderActionButtons(peer: peer.flatMap(EnginePeer.init), isSecretChat: isSecretChat, isContact: isContact)
```

```swift
// before (line 549)
let buttonKeys: [PeerInfoHeaderButtonKey] = (self.isSettings || self.isMyProfile) ? [] : peerInfoHeaderButtons(peer: peer, cachedData: cachedData, ...)

// after
let buttonKeys: [PeerInfoHeaderButtonKey] = (self.isSettings || self.isMyProfile) ? [] : peerInfoHeaderButtons(peer: peer.flatMap(EnginePeer.init), cachedData: cachedData, ...)
```

```swift
// before (line 2361)
let chatIsMuted = peerInfoIsChatMuted(peer: peer, peerNotificationSettings: peerNotificationSettings, threadNotificationSettings: threadNotificationSettings, globalNotificationSettings: globalNotificationSettings)

// after
let chatIsMuted = peerInfoIsChatMuted(peer: peer.flatMap(EnginePeer.init), peerNotificationSettings: peerNotificationSettings, threadNotificationSettings: threadNotificationSettings, globalNotificationSettings: globalNotificationSettings)
```

- [ ] **Step 2: ADD-WRAP at `PeerInfoEditingAvatarNode.swift:66`.** Here `peer` is non-optional `Peer` (unwrapped at line 62: `guard let peer = peer else { return }`). Use `EnginePeer(peer)`.

```swift
// before
let canEdit = canEditPeerInfo(context: self.context, peer: peer, chatLocation: chatLocation, threadData: threadData)

// after
let canEdit = canEditPeerInfo(context: self.context, peer: EnginePeer(peer), chatLocation: chatLocation, threadData: threadData)
```

- [ ] **Step 3: ADD-WRAP at `PeerInfoEditingAvatarOverlayNode.swift:85`.** Same shape — `peer` is non-optional `Peer` (unwrapped at line 64).

```swift
// before
if canEditPeerInfo(context: self.context, peer: peer, chatLocation: chatLocation, threadData: threadData)

// after
if canEditPeerInfo(context: self.context, peer: EnginePeer(peer), chatLocation: chatLocation, threadData: threadData)
```

- [ ] **Step 4: ADD-WRAPs at `PeerInfoHeaderEditingContentNode.swift:59,88,93,159,162`.** Here `peer` is the method's `peer: Peer?` parameter (line 52). Five identical bridge forms.

For each of lines 59, 88, 93, 159, 162, replace `peer: peer` (inside `canEditPeerInfo(... peer: peer, ...)`) with `peer: peer.flatMap(EnginePeer.init)`.

The simplest approach: issue five separate Edit calls, each scoped to a unique surrounding substring. Example:

```swift
// before (line 59)
if canEditPeerInfo(context: self.context, peer: peer, chatLocation: chatLocation, threadData: threadData)  {

// after
if canEditPeerInfo(context: self.context, peer: peer.flatMap(EnginePeer.init), chatLocation: chatLocation, threadData: threadData)  {
```

Note line 59's trailing double-space before `{` in the original — preserve it.

Lines 88, 93, 159 share an identical surrounding substring `if canEditPeerInfo(context: self.context, peer: peer, chatLocation: chatLocation, threadData: threadData) {` (no trailing double-space, no `|| isEditableBot`). To avoid collision with line 59, use `replace_all=true` on THIS exact string (matches 88, 93 — wait, 159 uses `isEnabled = canEditPeerInfo(...)`, different prefix). Safer plan: one Edit per line, each with enough surrounding context to be unique. Verify uniqueness after each edit with grep.

Line 88's surrounding context: inside `if let _ = peer as? TelegramGroup {` branch — preceded by `fieldKeys.append(.title)`.

Line 93's surrounding context: inside `if let _ = peer as? TelegramChannel {` branch — preceded by `fieldKeys.append(.title)`. Same inner phrase as 88 — so `fieldKeys.append(.title)\n            if canEditPeerInfo...` appears twice. Use line-specific context (preceding `else if let _ = peer as?` token).

Line 159: `isEnabled = canEditPeerInfo(context: self.context, peer: peer, chatLocation: chatLocation, threadData: threadData)` (no trailing text).

Line 162: `isEnabled = canEditPeerInfo(context: self.context, peer: peer, chatLocation: chatLocation, threadData: threadData) || isEditableBot`. Unique — contains ` || isEditableBot`.

Recommended: five sequential Edits with explicit line disambiguation via surrounding context. Do not bulk-replace-all — the identical `peer: peer, chatLocation: chatLocation, threadData: threadData)` substring appears at all five sites but their line-specific surroundings differ.

Verification after all five edits:

```bash
grep -c "peer: peer," submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoHeaderEditingContentNode.swift
```
Expected: 0 (no unmigrated call sites remain; other `peer:` occurrences in the file are either type annotations or at the method signature, which uses `peer: Peer?` not `peer: peer`).

---

### Task 5: Update call sites — ADD-WRAPs at raw-`Peer` member-item sites (2 sites)

**Files:**
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/ListItems/PeerInfoScreenMemberItem.swift:178`
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/Panes/PeerInfoMembersPane.swift:139`

At these sites `enclosingPeer` is non-optional `Peer` (raw, stored on the item / local). Wrap with `EnginePeer(...)`.

- [ ] **Step 1: ADD-WRAP at `PeerInfoScreenMemberItem.swift:178`.**

```swift
// before
let actions = availableActionsForMemberOfPeer(accountPeerId: item.context.accountPeerId, peer: item.enclosingPeer, member: item.member)

// after
let actions = availableActionsForMemberOfPeer(accountPeerId: item.context.accountPeerId, peer: EnginePeer(item.enclosingPeer), member: item.member)
```

- [ ] **Step 2: ADD-WRAP at `PeerInfoMembersPane.swift:139`.**

```swift
// before
let actions = availableActionsForMemberOfPeer(accountPeerId: context.account.peerId, peer: enclosingPeer, member: member)

// after
let actions = availableActionsForMemberOfPeer(accountPeerId: context.account.peerId, peer: EnginePeer(enclosingPeer), member: member)
```

---

### Task 6: Build and iterate

- [ ] **Step 1: Full project build with `--continueOnError` to surface all errors at once.**

```bash
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion \
  --cacheDir ~/telegram-bazel-cache \
  build \
  --configurationPath build-system/appstore-configuration.json \
  --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
  --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 \
  --configuration=debug_sim_arm64 --continueOnError
```

Expected: likely 2-iteration convergence. Budget up to iteration 3.

Likely categories of residual errors:

1. **Missed call sites** — grep-miss from planning. Remediate by adding `.flatMap(EnginePeer.init)` or `EnginePeer(...)` as appropriate.
2. **Missed `as? TelegramX` / `is TelegramX` inside helper bodies** — Swift compiler error "cannot convert value of type 'EnginePeer?' to expected argument type 'Peer?'" or warning "'is' test is always false". Fix with `case` pattern.
3. **Optional-lifting edge cases** — `if case let .user(user) = peer` may fail if Swift interprets `peer` as non-optional. If so, rewrite as `if let peer, case let .user(user) = peer`.
4. **Unused binding warnings** — e.g. `if case let .user(user) = peer` where `user` isn't used inside that branch. Swift's `-warnings-as-errors` (658/665 submodule BUILDs) promotes these. Rewrite as `if case .user = peer`.
5. **Unused variable `peer` or `group`/`channel` at CONVERT sites 16, 17** — lines 1905/1961 bind `group`/`channel` in the `case let` pattern; if the body body doesn't use it, Swift emits "value 'group' was never used" which `-warnings-as-errors` promotes to error. Since the body below DOES use them (updatePeerTitle(peerId: group.id, ...)` etc.), this should not trigger — but verify.

- [ ] **Step 2: For each error category above, apply the correct fix in-place and rebuild. Iterate until green.**

- [ ] **Step 3: After build is green, run the post-migration grep audit:**

```bash
# Should be empty — no _asPeer() bridges at helper call sites
grep -rn "canEditPeerInfo(.*_asPeer\|peerInfoIsChatMuted(.*_asPeer\|peerInfoHeaderButtons(.*_asPeer\|peerInfoHeaderActionButtons(.*_asPeer\|peerInfoCanEdit(.*_asPeer\|availableActionsForMemberOfPeer(.*_asPeer" submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/

# Should be empty — no concrete-type casts against peer param in helper bodies
grep -nE "as\?\s+TelegramUser|as\?\s+TelegramChannel|as\?\s+TelegramGroup|\bis\s+TelegramUser\b|\bis\s+TelegramChannel\b|\bis\s+TelegramGroup\b" submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoData.swift | awk -F: '$2 >= 2265 && $2 <= 2670'
```

Expected: both empty.

---

### Task 7: Commit

- [ ] **Step 1: Verify working tree only contains wave-43 edits + pre-existing WIP.**

```bash
git status --short
```

Expected (pre-existing WIP, NOT to be staged):

```
 m build-system/bazel-rules/sourcekit-bazel-bsp
 M submodules/TelegramUI/Sources/ChatMessageTransitionNode.swift
?? build-system/tulsi/
?? submodules/TgVoip/
?? third-party/libx264/
```

Plus wave-43 edits (all under `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/`):

```
 M submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoData.swift
 M submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift
 M submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoHeaderNode.swift
 M submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoEditingAvatarNode.swift
 M submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoEditingAvatarOverlayNode.swift
 M submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoHeaderEditingContentNode.swift
 M submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenAvatarSetup.swift
 M submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenPerformButtonAction.swift
 M submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenOpenMember.swift
 M submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoProfileItems.swift
 M submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/ListItems/PeerInfoScreenMemberItem.swift
 M submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/Panes/PeerInfoMembersPane.swift
```

- [ ] **Step 2: Explicitly stage only the wave-43 files (not the WIP).**

```bash
git add \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoData.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoHeaderNode.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoEditingAvatarNode.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoEditingAvatarOverlayNode.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoHeaderEditingContentNode.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenAvatarSetup.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenPerformButtonAction.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenOpenMember.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoProfileItems.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/ListItems/PeerInfoScreenMemberItem.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/Panes/PeerInfoMembersPane.swift \
  docs/superpowers/plans/2026-04-24-peerinfoscreen-helpers-engine-peer-migration.md
```

- [ ] **Step 3: Commit.**

Use a HEREDOC for the message:

```bash
git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 43

Migrate six PeerInfoScreen helpers (canEditPeerInfo,
availableActionsForMemberOfPeer, peerInfoHeaderActionButtons,
peerInfoHeaderButtons, peerInfoCanEdit, peerInfoIsChatMuted) from
`peer: Peer?` to `peer: EnginePeer?`. Internal `as? TelegramX` /
`is TelegramX` patterns rewritten to `case let .x` / `case .x` on
EnginePeer enum. All 21 call sites updated in the same commit: 7
`._asPeer()` bridges installed by wave 42 dropped; 12
`.flatMap(EnginePeer.init)` / `EnginePeer(...)` wraps added at sites
whose enclosing methods still take raw Peer?; 2 concrete-type args
converted to pass the whole EnginePeer value.

All edits within submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/.
No new engine typealiases. No TelegramCore changes.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: Verify commit.**

```bash
git log --oneline -1
git show --stat HEAD
```

Expected: one commit, ~10 files changed, clean diff.

---

## Self-review checklist (run before handoff)

**Spec coverage:**
- All 6 helper signatures migrated (Task 1 steps 1–6). ✓
- All 21 call sites touched (Tasks 2–5). ✓
- Build iteration explicit (Task 6). ✓
- Commit explicit (Task 7). ✓

**Type consistency:**
- Helper signatures all `peer: EnginePeer?` (consistent). ✓
- Call-site transforms: DROP/ADD/CONVERT actions match the inventory table. ✓
- `EnginePeer.init` constructor used both as `.flatMap(EnginePeer.init)` (Peer? → EnginePeer?) and `EnginePeer(...)` (Peer → EnginePeer) — both are valid (construction overloaded on EnginePeer extension at `TelegramCore/TelegramEngine/Peers/Peer.swift:564`). ✓

**Placeholder scan:**
- No "TBD" / "handle appropriately" / "similar to Task N" language — every step has its concrete code. ✓

**Risks flagged:**
- Wave-41 lesson: foundational-type migrations rarely first-pass-clean. Budget 2 iterations. ✓
- Wave-41 lesson: `-warnings-as-errors` promotes always-false `is` checks and unused bindings to build errors. Task 6 step 1 calls these out explicitly. ✓
- Wave-42 lesson: `EnginePeer` doesn't forward every Peer property. Helper bodies were verified to access only `.id`, which IS forwarded; other property accesses were on concrete types (`TelegramChannel.hasPermission(...)` etc.) which remain on concrete types post-migration. No forwarding-gap remediation expected in helpers. ✓
