# Wave 36: `ContactListPeer.peer: Peer → EnginePeer` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the public enum case `ContactListPeer.peer(peer: Peer, isGlobal: Bool, participantCount: Int32?)` from the Postbox `Peer` protocol to the TelegramCore `EnginePeer` enum in a single atomic commit. Cascading changes: change `ContactListPeer.indexName` return type from `PeerIndexNameRepresentation` to `EnginePeer.IndexName` (drops 2 `EnginePeer.IndexName(...)` wraps at one call site); rewrite the enum's custom `==` to use `EnginePeer`'s synthesized Equatable; drop 20 outflow `._asPeer()` bridges, 16 inflow `EnginePeer(peer)` wraps; rewrite 2 Postbox-concrete cast chains to EnginePeer case patterns.

**Architecture:** One atomic commit. The enum-case payload change is necessarily atomic. `ContactListPeer` lives in `submodules/AccountContext/Sources/ContactSelectionController.swift`; 7 consumer files touched in addition. 2 consumer files verified untouched (`ComposeController.swift`, `ChatSendAudioMessageContextPreview.swift`). No new wrappers, no new typealiases. `import Postbox` stays in every touched consumer (follow-up unused-import sweep handles it).

**Tech Stack:** Swift, Bazel build via Make.py wrapper. No tests — verification is build success + targeted grep checks.

**Spec:** `docs/superpowers/specs/2026-04-24-contactlistpeer-engine-peer-migration-design.md`

---

## File Structure

**Modified files (8 expected — 1 definition + 7 consumer. Plus 2 verify-only.)**

| File | Edits | Categories |
|---|---|---|
| `submodules/AccountContext/Sources/ContactSelectionController.swift` | 3 (case type + indexName return type + `==` body) | α |
| `submodules/ContactListUI/Sources/ContactListNode.swift` | ~21 (12 outflow + 4 inflow + 2 cast rewrites [L182-186, L1968] + 2 IndexName wraps [L517]) | β + δ + φ + ε′ |
| `submodules/ContactListUI/Sources/ContactsController.swift` | 1 (inflow wrap at L294) | δ |
| `submodules/ContactListUI/Sources/ContactsSearchContainerNode.swift` | 7 (3 outflow + 4 inflow) | β + δ |
| `submodules/TelegramUI/Sources/ContactMultiselectionController.swift` | 6 (2 outflow + 4 inflow) | β + δ |
| `submodules/TelegramUI/Sources/ContactMultiselectionControllerNode.swift` | 2 (1 outflow + 1 inflow) | β + δ |
| `submodules/TelegramUI/Sources/ContactSelectionController.swift` | 2 (inflow wraps L517/527) | δ |
| `submodules/TelegramUI/Sources/ContactSelectionControllerNode.swift` | 2 (outflow bridges L160/230) | β |

**Verify-only (no edits expected):**

| File | Reason |
|---|---|
| `submodules/TelegramUI/Sources/ComposeController.swift` | Destructures at L120/160 access `.id` only. Same-type access works on EnginePeer. |
| `submodules/TelegramUI/Components/Chat/ChatSendAudioMessageContextPreview/Sources/ChatSendAudioMessageContextPreview.swift` | Only holds `[ContactListPeer]` at collection level; no `.peer` destructures. |

**EnginePeer enum case mapping (used in cast rewrites):**

| Postbox concrete | EnginePeer case |
|---|---|
| `TelegramUser` | `.user(TelegramUser)` |
| `TelegramGroup` | `.legacyGroup(TelegramGroup)` |
| `TelegramChannel` | `.channel(TelegramChannel)` |

**Sites that stay as `._asPeer()` bridges (NOT in wave scope):**

- `submodules/ContactListUI/Sources/ContactsSearchContainerNode.swift:488, 528, 562` — `canSendMessagesToPeer(peer._asPeer())` / `canSendMessagesToPeer(peer.peer._asPeer())`. `canSendMessagesToPeer(_: Peer)` migration is a deferred future wave.
- `submodules/TelegramUI/Sources/ContactMultiselectionController.swift:171, 201, 748` — `peerTokenTitle(accountPeerId:..., peer: peer._asPeer(), strings:...)`. `peerTokenTitle(peer: Peer)` migration is out of scope.

---

## Task 1: Edit `AccountContext/Sources/ContactSelectionController.swift` — definition

**Files:**
- Modify: `submodules/AccountContext/Sources/ContactSelectionController.swift`

Foundational change. Without it, none of the consumer edits compile.

- [ ] **Step 1.1: Update the case payload type, `indexName` return type, and `==` operator body**

Edit using the Edit tool:

```swift
// OLD (lines 61-99)
public enum ContactListPeer: Equatable {
    case peer(peer: Peer, isGlobal: Bool, participantCount: Int32?)
    case deviceContact(DeviceContactStableId, DeviceContactBasicData)
    
    public var id: ContactListPeerId {
        switch self {
        case let .peer(peer, _, _):
            return .peer(peer.id)
        case let .deviceContact(id, _):
            return .deviceContact(id)
        }
    }
    
    public var indexName: PeerIndexNameRepresentation {
        switch self {
        case let .peer(peer, _, _):
            return peer.indexName
        case let .deviceContact(_, contact):
            return .personName(first: contact.firstName, last: contact.lastName, addressNames: [], phoneNumber: "")
        }
    }
    
    public static func ==(lhs: ContactListPeer, rhs: ContactListPeer) -> Bool {
        switch lhs {
        case let .peer(lhsPeer, lhsIsGlobal, lhsParticipantCount):
            if case let .peer(rhsPeer, rhsIsGlobal, rhsParticipantCount) = rhs, lhsPeer.isEqual(rhsPeer), lhsIsGlobal == rhsIsGlobal, lhsParticipantCount == rhsParticipantCount {
                return true
            } else {
                return false
            }
        case let .deviceContact(id, contact):
            if case .deviceContact(id, contact) = rhs {
                return true
            } else {
                return false
            }
        }
    }
}
```

```swift
// NEW
public enum ContactListPeer: Equatable {
    case peer(peer: EnginePeer, isGlobal: Bool, participantCount: Int32?)
    case deviceContact(DeviceContactStableId, DeviceContactBasicData)
    
    public var id: ContactListPeerId {
        switch self {
        case let .peer(peer, _, _):
            return .peer(peer.id)
        case let .deviceContact(id, _):
            return .deviceContact(id)
        }
    }
    
    public var indexName: EnginePeer.IndexName {
        switch self {
        case let .peer(peer, _, _):
            return peer.indexName
        case let .deviceContact(_, contact):
            return .personName(first: contact.firstName, last: contact.lastName, addressNames: [], phoneNumber: "")
        }
    }
    
    public static func ==(lhs: ContactListPeer, rhs: ContactListPeer) -> Bool {
        switch lhs {
        case let .peer(lhsPeer, lhsIsGlobal, lhsParticipantCount):
            if case let .peer(rhsPeer, rhsIsGlobal, rhsParticipantCount) = rhs, lhsPeer == rhsPeer, lhsIsGlobal == rhsIsGlobal, lhsParticipantCount == rhsParticipantCount {
                return true
            } else {
                return false
            }
        case let .deviceContact(id, contact):
            if case .deviceContact(id, contact) = rhs {
                return true
            } else {
                return false
            }
        }
    }
}
```

Three changes in this edit:
1. Line 62: `peer: Peer` → `peer: EnginePeer`
2. Line 74: return type `PeerIndexNameRepresentation` → `EnginePeer.IndexName`
3. Line 86 (inside the `==` operator): `lhsPeer.isEqual(rhsPeer)` → `lhsPeer == rhsPeer`

`EnginePeer.IndexName.personName(first:last:addressNames:phoneNumber:)` has the same labels/types as `PeerIndexNameRepresentation.personName`, so line 79 body is untouched — only its return target enum changes.

- [ ] **Step 1.2: Verify**

Run:

```bash
grep -nE "case peer\(peer:|public var indexName:|\.isEqual\(" submodules/AccountContext/Sources/ContactSelectionController.swift
```

Expected output:
- Line 62: `case peer(peer: EnginePeer, ...)`
- Line 74: `public var indexName: EnginePeer.IndexName {`
- No `isEqual(` match on the `==` path (the only remaining occurrences would be unrelated).

Do not commit yet.

---

## Task 2: Edit `ContactListNode.swift` — largest consumer, multi-category

**Files:**
- Modify: `submodules/ContactListUI/Sources/ContactListNode.swift`

Most changes happen here: 12 outflow bridges + 4 inflow wraps + 2 cast chain rewrites + 2 IndexName wrap drops.

- [ ] **Step 2.1: Drop the 12 outflow `._asPeer()` bridges via `replace_all`**

All 12 `._asPeer()` bridges at ContactListPeer.peer construction sites follow the shape `._asPeer(), isGlobal:`. Non-construction `._asPeer()` uses in this file (if any) feed other functions and do NOT use this exact substring.

Pre-flight verify:

```bash
grep -cE "\._asPeer\(\), isGlobal:" submodules/ContactListUI/Sources/ContactListNode.swift
```

Expected: `12`.

If the count is 12, apply the Edit tool with `replace_all=true`:
- `old_string`: `._asPeer(), isGlobal:`
- `new_string`: `, isGlobal:`

If the count is not 12, fall back to per-site Edits at lines 632, 690, 701, 747, 765, 1365, 1647, 1656, 1693, 1731, 1942, 1944 using enough surrounding context to make each `old_string` unique.

- [ ] **Step 2.2: Verify the 12 outflow drops**

Run:

```bash
grep -nE "\._asPeer\(\), isGlobal:" submodules/ContactListUI/Sources/ContactListNode.swift
```

Expected: zero matches.

- [ ] **Step 2.3: Drop 2 inflow wraps at L204**

Read lines 200–210 first to confirm the line text.

Edit:

```swift
// OLD  (line 204)
                        itemPeer = .peer(peer: EnginePeer(peer), chatPeer: EnginePeer(peer))
```

```swift
// NEW
                        itemPeer = .peer(peer: peer, chatPeer: peer)
```

- [ ] **Step 2.4: Drop 1 inflow wrap at L252**

Read lines 248–256 first to confirm.

Edit:

```swift
// OLD  (line 252)
                        interaction.openDisabledPeer(EnginePeer(peer), requiresPremiumForMessaging ? .premiumRequired : .generic)
```

```swift
// NEW
                        interaction.openDisabledPeer(peer, requiresPremiumForMessaging ? .premiumRequired : .generic)
```

- [ ] **Step 2.5: Drop 1 inflow wrap at L844**

Read lines 840–848 first to confirm.

Edit:

```swift
// OLD  (line 844)
            if let isPeerEnabled, !isPeerEnabled(EnginePeer(peer)) {
```

```swift
// NEW
            if let isPeerEnabled, !isPeerEnabled(peer) {
```

- [ ] **Step 2.6: Rewrite the L182-186 cast chain to EnginePeer case patterns**

Read lines 176–200 first. The cast chain is inside the ContactListPeer.peer destructure at line 177.

Edit:

```swift
// OLD  (lines 182-186)
                        } else {
                            if let _ = peer as? TelegramUser {
                                status = .presence(presence ?? EnginePeer.Presence(status: .longTimeAgo, lastActivity: 0), dateTimeFormat)
                            } else if let group = peer as? TelegramGroup {
                                status = .custom(string: NSAttributedString(string: strings.Conversation_StatusMembers(Int32(group.participantCount))), multiline: false, isActive: false, icon: nil)
                            } else if let channel = peer as? TelegramChannel {
```

```swift
// NEW
                        } else {
                            if case .user = peer {
                                status = .presence(presence ?? EnginePeer.Presence(status: .longTimeAgo, lastActivity: 0), dateTimeFormat)
                            } else if case let .legacyGroup(group) = peer {
                                status = .custom(string: NSAttributedString(string: strings.Conversation_StatusMembers(Int32(group.participantCount))), multiline: false, isActive: false, icon: nil)
                            } else if case let .channel(channel) = peer {
```

`channel.info` access inside the surviving inner block continues to compile unchanged (`EnginePeer.channel` wraps `TelegramChannel`). `group.participantCount` inside the `legacyGroup` branch works identically. The first branch doesn't bind the user — the `case .user = peer` form preserves that.

- [ ] **Step 2.7: Rewrite the L1968 cast to an EnginePeer case pattern**

Read lines 1964–1976 first. The cast is inside the ContactListPeer.peer destructure at line 1966.

Edit:

```swift
// OLD  (lines 1967-1968)
                                    if requirePhoneNumbers,
                                       let user = peer as? TelegramUser {
```

```swift
// NEW
                                    if requirePhoneNumbers,
                                       case let .user(user) = peer {
```

`user.phone` on the following line continues to compile (`EnginePeer.user` wraps `TelegramUser`).

- [ ] **Step 2.8: Drop 2 IndexName wraps at L517**

Read lines 515–522 first.

Edit:

```swift
// OLD  (line 517)
                let result = EnginePeer.IndexName(lhs.indexName).isLessThan(other: EnginePeer.IndexName(rhs.indexName), ordering: sortOrder)
```

```swift
// NEW
                let result = lhs.indexName.isLessThan(other: rhs.indexName, ordering: sortOrder)
```

`ContactListPeer.indexName` now returns `EnginePeer.IndexName` (from Task 1), and `isLessThan(other:ordering:)` is defined on `EnginePeer.IndexName` at `submodules/LocalizedPeerData/Sources/PeerTitle.swift:64`, so the wrap idiom is no longer required.

- [ ] **Step 2.9: Verify ContactListNode.swift changes**

Run:

```bash
grep -nE "\._asPeer\(\), isGlobal:|EnginePeer\(peer\)|peer as\? Telegram(User|Group|Channel)\b|EnginePeer\.IndexName\(lhs\.indexName\)|EnginePeer\.IndexName\(rhs\.indexName\)" submodules/ContactListUI/Sources/ContactListNode.swift
```

Expected output: only `EnginePeer(peer)` matches at lines 1819 and 1825 (out-of-scope; `peer` there is from `entryData.renderedPeer.peer`, raw `Peer`, wraps stay). Similarly, `peer as? TelegramChannel` at 1802/1820 and `peer is TelegramGroup` at 1818 stay.

If any other match appears, re-examine that site and apply the matching fix.

---

## Task 3: Edit `ContactsController.swift` — 1 inflow wrap drop

**Files:**
- Modify: `submodules/ContactListUI/Sources/ContactsController.swift`

- [ ] **Step 3.1: Drop inflow wrap at L294**

Read lines 285–300 first.

Edit:

```swift
// OLD  (line 294)
                            strongSelf.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: strongSelf.context, chatLocation: .peer(EnginePeer(peer)), purposefulAction: { [weak self] in
```

```swift
// NEW
                            strongSelf.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: strongSelf.context, chatLocation: .peer(peer), purposefulAction: { [weak self] in
```

`peer` here is destructured from the ContactListPeer.peer case at line 287; post-migration it is already `EnginePeer`. `chatLocation: .peer(EnginePeer)` case takes `EnginePeer`.

- [ ] **Step 3.2: Verify**

Run:

```bash
grep -nE "chatLocation: \.peer\(EnginePeer\(peer\)\)" submodules/ContactListUI/Sources/ContactsController.swift
```

Expected: zero matches.

---

## Task 4: Edit `ContactsSearchContainerNode.swift` — 3 outflow + 4 inflow

**Files:**
- Modify: `submodules/ContactListUI/Sources/ContactsSearchContainerNode.swift`

- [ ] **Step 4.1: Drop the 3 outflow `._asPeer()` bridges at L494/535/569**

Use the same `._asPeer(), isGlobal:` pattern as Task 2.1. The 3 bridges at `ContactListPeer.peer(...)` constructions all match this substring; the 3 unrelated bridges at L488/528/562 (`canSendMessagesToPeer(...)` sites) do NOT match (they lack the `, isGlobal:` suffix).

Pre-flight verify:

```bash
grep -cE "\._asPeer\(\), isGlobal:" submodules/ContactListUI/Sources/ContactsSearchContainerNode.swift
```

Expected: `3`.

Apply Edit with `replace_all=true`:
- `old_string`: `._asPeer(), isGlobal:`
- `new_string`: `, isGlobal:`

- [ ] **Step 4.2: Drop 4 inflow wraps at L164/165/181**

Read lines 160–185 first.

Three edits, each targeting one source line.

Edit (line 164 — 2 wraps in one expression):

```swift
// OLD
                        peerItem = .peer(peer: EnginePeer(peer), chatPeer: EnginePeer(peer))
```

```swift
// NEW
                        peerItem = .peer(peer: peer, chatPeer: peer)
```

Edit (line 165):

```swift
// OLD
                        nativePeer = EnginePeer(peer)
```

```swift
// NEW
                        nativePeer = peer
```

Edit (line 181):

```swift
// OLD
                        openDisabledPeer(EnginePeer(peer), requiresPremiumForMessaging ? .premiumRequired : .generic)
```

```swift
// NEW
                        openDisabledPeer(peer, requiresPremiumForMessaging ? .premiumRequired : .generic)
```

- [ ] **Step 4.3: Verify**

Run:

```bash
grep -nE "\._asPeer\(\), isGlobal:|EnginePeer\(peer\)" submodules/ContactListUI/Sources/ContactsSearchContainerNode.swift
```

Expected: zero matches.

The `._asPeer()` calls at L488/528/562 (feeding `canSendMessagesToPeer`) should remain. Verify:

```bash
grep -nE "canSendMessagesToPeer\(.*\._asPeer\(\)\)" submodules/ContactListUI/Sources/ContactsSearchContainerNode.swift
```

Expected: 3 matches (L488, L528, L562).

---

## Task 5: Edit `TelegramUI/Sources/ContactMultiselectionController.swift` — 2 outflow + 4 inflow

**Files:**
- Modify: `submodules/TelegramUI/Sources/ContactMultiselectionController.swift`

- [ ] **Step 5.1: Drop 2 outflow bridges at L451/459 via `replace_all`**

Pre-flight verify:

```bash
grep -cE "\._asPeer\(\), isGlobal:" submodules/TelegramUI/Sources/ContactMultiselectionController.swift
```

Expected: `2`.

Apply Edit with `replace_all=true`:
- `old_string`: `._asPeer(), isGlobal:`
- `new_string`: `, isGlobal:`

Unrelated `._asPeer()` calls at L171/201/748 (feeding `peerTokenTitle(peer: Peer, ...)`) do NOT use this substring and stay.

- [ ] **Step 5.2: Drop 4 inflow wraps at L386/403/481/491**

Read the file around each site to confirm exact text. Two wraps (L386, L403) have identical text; the other two (L481, L491) have distinct tails.

Edit for L386 and L403 — `replace_all=true` on the substring:

Pre-flight verify:

```bash
grep -cE "subject: \.peer\(EnginePeer\(peer\)\)" submodules/TelegramUI/Sources/ContactMultiselectionController.swift
```

Expected: `2`.

Apply Edit with `replace_all=true`:
- `old_string`: `subject: .peer(EnginePeer(peer))`
- `new_string`: `subject: .peer(peer)`

Edit for L481:

```swift
// OLD
                    self.params.sendMessage?(EnginePeer(peer))
```

```swift
// NEW
                    self.params.sendMessage?(peer)
```

Edit for L491:

```swift
// OLD
                    self.params.openProfile?(EnginePeer(peer))
```

```swift
// NEW
                    self.params.openProfile?(peer)
```

- [ ] **Step 5.3: Verify**

Run:

```bash
grep -nE "\._asPeer\(\), isGlobal:|subject: \.peer\(EnginePeer\(peer\)\)|sendMessage\?\(EnginePeer\(peer\)\)|openProfile\?\(EnginePeer\(peer\)\)" submodules/TelegramUI/Sources/ContactMultiselectionController.swift
```

Expected: zero matches.

Preserved bridge sites (sanity check):

```bash
grep -nE "peerTokenTitle\(.*\._asPeer\(\)" submodules/TelegramUI/Sources/ContactMultiselectionController.swift
```

Expected: 3 matches (L171, L201, L748).

---

## Task 6: Edit `TelegramUI/Sources/ContactMultiselectionControllerNode.swift` — 1 outflow + 1 inflow

**Files:**
- Modify: `submodules/TelegramUI/Sources/ContactMultiselectionControllerNode.swift`

- [ ] **Step 6.1: Drop 1 outflow bridge at L317**

Read lines 315–320 first.

Edit:

```swift
// OLD  (line 317)
                self?.openPeer?(.peer(peer: peer._asPeer(), isGlobal: false, participantCount: nil))
```

```swift
// NEW
                self?.openPeer?(.peer(peer: peer, isGlobal: false, participantCount: nil))
```

- [ ] **Step 6.2: Drop 1 inflow wrap at L492**

Read lines 488–495 first.

Edit:

```swift
// OLD  (line 492)
                        callTitle = self.presentationData.strings.NewCall_ActionCallSingle(EnginePeer(peer).compactDisplayTitle).string
```

```swift
// NEW
                        callTitle = self.presentationData.strings.NewCall_ActionCallSingle(peer.compactDisplayTitle).string
```

- [ ] **Step 6.3: Verify**

Run:

```bash
grep -nE "\._asPeer\(\), isGlobal:|EnginePeer\(peer\)\.compactDisplayTitle" submodules/TelegramUI/Sources/ContactMultiselectionControllerNode.swift
```

Expected: zero matches.

---

## Task 7: Edit `TelegramUI/Sources/ContactSelectionController.swift` — 2 inflow wraps

**Files:**
- Modify: `submodules/TelegramUI/Sources/ContactSelectionController.swift`

- [ ] **Step 7.1: Drop 2 inflow wraps at L517/527**

Read lines 510–535 first. Both sites are inside the destructure at L504.

Edit for L517:

```swift
// OLD
                    self.sendMessage?(EnginePeer(peer))
```

```swift
// NEW
                    self.sendMessage?(peer)
```

Edit for L527:

```swift
// OLD
                    self.openProfile?(EnginePeer(peer))
```

```swift
// NEW
                    self.openProfile?(peer)
```

- [ ] **Step 7.2: Verify**

Run:

```bash
grep -nE "sendMessage\?\(EnginePeer\(peer\)\)|openProfile\?\(EnginePeer\(peer\)\)" submodules/TelegramUI/Sources/ContactSelectionController.swift
```

Expected: zero matches.

---

## Task 8: Edit `TelegramUI/Sources/ContactSelectionControllerNode.swift` — 2 outflow bridges

**Files:**
- Modify: `submodules/TelegramUI/Sources/ContactSelectionControllerNode.swift`

- [ ] **Step 8.1: Drop 2 outflow bridges at L160/230 via `replace_all`**

Pre-flight verify:

```bash
grep -cE "\._asPeer\(\), isGlobal:" submodules/TelegramUI/Sources/ContactSelectionControllerNode.swift
```

Expected: `2`.

Apply Edit with `replace_all=true`:
- `old_string`: `._asPeer(), isGlobal:`
- `new_string`: `, isGlobal:`

- [ ] **Step 8.2: Verify**

Run:

```bash
grep -nE "\._asPeer\(\), isGlobal:" submodules/TelegramUI/Sources/ContactSelectionControllerNode.swift
```

Expected: zero matches.

---

## Task 9: Verify no-edit consumer files

**Files (read only):**
- Read: `submodules/TelegramUI/Sources/ComposeController.swift`
- Read: `submodules/TelegramUI/Components/Chat/ChatSendAudioMessageContextPreview/Sources/ChatSendAudioMessageContextPreview.swift`

- [ ] **Step 9.1: Confirm ComposeController.swift has no inflow wraps, casts, or outflow bridges**

Run:

```bash
grep -nE "\.peer\(peer:|EnginePeer\(peer\)|peer as\? Telegram|\._asPeer\(\)" submodules/TelegramUI/Sources/ComposeController.swift
```

Expected: zero matches (destructures at L120/160 only access `.id`).

If any match appears, add the appropriate fix step here and re-run Task 9.1 before proceeding.

- [ ] **Step 9.2: Confirm ChatSendAudioMessageContextPreview.swift has no ContactListPeer.peer destructures**

Run:

```bash
grep -nE "case let \.peer\(peer, _, _\)|case \.peer\(let peer|EnginePeer\(peer\)|\.peer\(peer: " submodules/TelegramUI/Components/Chat/ChatSendAudioMessageContextPreview/Sources/ChatSendAudioMessageContextPreview.swift
```

Expected: zero matches. The file only references `[ContactListPeer]` at the collection level.

---

## Task 10: Build verification (first pass)

- [ ] **Step 10.1: Run the full build with `--continueOnError`**

Run:

```bash
source ~/.zshrc 2>/dev/null && python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 --configuration=debug_sim_arm64 --continueOnError 2>&1 | tee /tmp/wave36-build.log
```

Expected outcome: ideally clean. Realistic: 0–3 inventory-missed sites (wave 35 trend was 14% miss rate on a 7-file wave; this 8-file wave has a larger surface area, so budget for up to 3 misses).

- [ ] **Step 10.2: Triage build errors**

Likely patterns and fixes:

| Error | Fix |
|---|---|
| `cannot convert value of type 'EnginePeer' to expected argument type 'Peer'` at a call site | Add `._asPeer()` bridge. The callee takes raw `Peer` and is out of wave scope. |
| `cannot convert value of type 'Peer' to expected argument type 'EnginePeer'` at a `.peer(peer:, ...)` construction | Wrap raw peer with `EnginePeer(...)`. The raw-Peer source is probably from `transaction.getPeer(...)` or similar. |
| `value of type 'EnginePeer' has no member 'isEqual'` | Replace with `==`. |
| `type 'EnginePeer' cannot be cast to 'TelegramUser'` / `TelegramGroup` / `TelegramChannel` | Missed φ-category cast — rewrite to `case .user = peer` / `case let .legacyGroup(x) = peer` / `case let .channel(x) = peer`. |
| `cannot invoke initializer for type 'EnginePeer' with an argument list of type '(EnginePeer)'` | Missed inflow drop — strip `EnginePeer(...)` wrap. |
| `cannot convert value of type 'EnginePeer.IndexName' to expected argument type 'PeerIndexNameRepresentation'` | Either wrap the call site's expected-type change or adjust the consumer to accept `EnginePeer.IndexName`. Probably rare — ContactListPeer.indexName consumers were grepped in pre-flight and found only in ContactListNode. |
| `value of type 'EnginePeer' has no member '<postbox-Peer-only method>'` | That method is only on the Postbox `Peer` protocol. Bridge via `._asPeer()` OR find the EnginePeer-native equivalent. |

For each error: identify file:line, apply the fix, re-run the build until clean.

- [ ] **Step 10.3: Iterate to clean build**

Re-run the build after each batch of fixes. The wave is complete when the build returns 0 errors for the targeted configuration.

If 10+ unexpected errors surface, halt and reassess: the inventory may have significantly undercounted and the wave may need to be split. Discuss with the user before continuing.

---

## Task 11: Post-build grep validations

- [ ] **Step 11.1: Outflow-bridge-drop validation**

Run:

```bash
grep -rnE "\.peer\(peer: \w+\._asPeer\(\), isGlobal:" submodules/ --include="*.swift"
```

Expected: zero hits. Any remaining site is a missed outflow-bridge drop.

- [ ] **Step 11.2: Inflow-wrap-drop validation**

Run:

```bash
for f in submodules/ContactListUI/Sources/ContactListNode.swift \
         submodules/ContactListUI/Sources/ContactsController.swift \
         submodules/ContactListUI/Sources/ContactsSearchContainerNode.swift \
         submodules/TelegramUI/Sources/ContactMultiselectionController.swift \
         submodules/TelegramUI/Sources/ContactMultiselectionControllerNode.swift \
         submodules/TelegramUI/Sources/ContactSelectionController.swift; do
  echo "=== $f ==="
  grep -nE "EnginePeer\(peer\)" "$f"
done
```

Expected hits:
- ContactListNode.swift L1819, L1825 (raw `renderedPeer.peer`, out-of-scope wraps stay)
- Any other hit in the 6 listed files is a missed inflow drop — inspect and fix.

- [ ] **Step 11.3: Cast-rewrite validation**

Run:

```bash
grep -nE "\bpeer (as\?|as!|is) Telegram(User|Group|Channel)\b" submodules/ContactListUI/Sources/ContactListNode.swift
```

Expected: only L1802, L1818, L1820 remain (out-of-scope, `peer` is raw from `renderedPeer.peer`).

If L182, L184, L186, or L1968 appear, those are missed φ rewrites.

- [ ] **Step 11.4: IndexName wrap validation**

Run:

```bash
grep -nE "EnginePeer\.IndexName\(lhs\.indexName\)|EnginePeer\.IndexName\(rhs\.indexName\)" submodules/ContactListUI/Sources/ContactListNode.swift
```

Expected: zero matches.

- [ ] **Step 11.5: isEqual-in-==-operator validation**

Run:

```bash
grep -nE "lhsPeer\.isEqual\(rhsPeer\)" submodules/AccountContext/Sources/ContactSelectionController.swift
```

Expected: zero matches.

- [ ] **Step 11.6: Construction-site sanity sweep**

Run:

```bash
grep -rnE "ContactListPeer\.peer\(peer: |\.peer\(peer: \w+, isGlobal:" submodules/ --include="*.swift" | head -40
```

Inspect each hit. Expected forms:
- `.peer(peer: <EnginePeer-expr>, isGlobal: …)` where `<EnginePeer-expr>` is either a local already typed `EnginePeer` or `EnginePeer(<raw-Peer>)`.
- Anything of the form `.peer(peer: <raw-Peer>, isGlobal: …)` where `<raw-Peer>` is a Postbox `Peer` value is a miss (would surface as a build error — this is a belt-and-suspenders check).

If any validation fails, return to Task 10.

---

## Task 12: Atomic commit + memory + log update

- [ ] **Step 12.1: Stage and review**

Run:

```bash
git status --short
git diff --stat
```

Confirm exactly 8 modified Swift files:
- `submodules/AccountContext/Sources/ContactSelectionController.swift`
- `submodules/ContactListUI/Sources/ContactListNode.swift`
- `submodules/ContactListUI/Sources/ContactsController.swift`
- `submodules/ContactListUI/Sources/ContactsSearchContainerNode.swift`
- `submodules/TelegramUI/Sources/ContactMultiselectionController.swift`
- `submodules/TelegramUI/Sources/ContactMultiselectionControllerNode.swift`
- `submodules/TelegramUI/Sources/ContactSelectionController.swift`
- `submodules/TelegramUI/Sources/ContactSelectionControllerNode.swift`

Pre-existing WIP (`build-system/bazel-rules/sourcekit-bazel-bsp`, `ChatListFilterPresetController.swift`, `ChatListFilterPresetListController.swift`, untracked `build-system/tulsi/` / `submodules/TgVoip/` / `third-party/libx264/` / `docs/superpowers/plans/2026-04-22-claude-md-reorganization.md`) should NOT be staged.

- [ ] **Step 12.2: Stage only the wave-36 files**

Run:

```bash
git add submodules/AccountContext/Sources/ContactSelectionController.swift \
        submodules/ContactListUI/Sources/ContactListNode.swift \
        submodules/ContactListUI/Sources/ContactsController.swift \
        submodules/ContactListUI/Sources/ContactsSearchContainerNode.swift \
        submodules/TelegramUI/Sources/ContactMultiselectionController.swift \
        submodules/TelegramUI/Sources/ContactMultiselectionControllerNode.swift \
        submodules/TelegramUI/Sources/ContactSelectionController.swift \
        submodules/TelegramUI/Sources/ContactSelectionControllerNode.swift
```

If Task 10 introduced additional files (inventory-miss fixes), append them.

- [ ] **Step 12.3: Commit**

Run:

```bash
git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 36: ContactListPeer.peer Peer -> EnginePeer

Migrates the public enum case `ContactListPeer.peer(peer: Peer, isGlobal:,
participantCount:)` from the Postbox `Peer` protocol to the TelegramCore
`EnginePeer` enum. Also cascades `ContactListPeer.indexName` return type
from `PeerIndexNameRepresentation` to `EnginePeer.IndexName` and rewrites
the enum's custom `==` operator to use EnginePeer's synthesized Equatable.

Consumer-side cascade in 7 files:
  - 20 `._asPeer()` outflow bridge-drops at ContactListPeer.peer
    construction sites (the payload is now EnginePeer)
  - 16 `EnginePeer(peer)` inflow wrap-drops at destructure sites (the
    destructured `peer` is already EnginePeer)
  - 2 `EnginePeer.IndexName(...)` wrap-drops at a sort-comparator (the
    indexName property now returns EnginePeer.IndexName directly)
  - 2 Postbox-concrete cast chains rewritten to EnginePeer case patterns
    (`peer as? TelegramUser` → `case .user = peer`, etc.)
  - `lhsPeer.isEqual(rhsPeer)` → `lhsPeer == rhsPeer` in the ==operator

Files modified:
  submodules/AccountContext/Sources/ContactSelectionController.swift
  submodules/ContactListUI/Sources/ContactListNode.swift
  submodules/ContactListUI/Sources/ContactsController.swift
  submodules/ContactListUI/Sources/ContactsSearchContainerNode.swift
  submodules/TelegramUI/Sources/ContactMultiselectionController.swift
  submodules/TelegramUI/Sources/ContactMultiselectionControllerNode.swift
  submodules/TelegramUI/Sources/ContactSelectionController.swift
  submodules/TelegramUI/Sources/ContactSelectionControllerNode.swift

Bridges intentionally retained (out-of-wave scope):
  - `canSendMessagesToPeer(peer._asPeer())` — callee takes Peer, deferred
  - `peerTokenTitle(peer: peer._asPeer(), ...)` — callee takes Peer,
    deferred

Plan: docs/superpowers/plans/2026-04-24-contactlistpeer-engine-peer-migration.md
Spec: docs/superpowers/specs/2026-04-24-contactlistpeer-engine-peer-migration-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 12.4: Update CLAUDE.md wave counter**

Edit `CLAUDE.md` to bump the "Waves landed so far" line from "35 waves" to "36 waves" and update the "as of" date if the commit lands after 2026-04-24.

- [ ] **Step 12.5: Append wave outcome to the postbox-refactor-log**

Append a "Wave 36 outcome" section to `docs/superpowers/postbox-refactor-log.md` documenting:
- Actual files touched + edit counts vs. plan
- Any inventory undercounts surfaced by Task 10 (file:line + missed-category)
- Any lessons learned (e.g., whether the γ category really had zero sites; how the φ cast-rewrites behaved; post-migration undercount percentage vs wave 35's 14%)
- Ratio of bridge-drops to bridge-additions (wave theme: removal-dominated)

Keep concise.

- [ ] **Step 12.6: Commit the docs update**

Run:

```bash
git add CLAUDE.md docs/superpowers/postbox-refactor-log.md
git commit -m "$(cat <<'EOF'
docs: add wave 36 outcome (ContactListPeer.peer Peer→EnginePeer)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 12.7: Update the next-wave memory**

Edit `/Users/isaac/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`:
- Add wave 36 to the "Latest commits" section.
- Move ContactListPeer migration from "Recommended wave 36 candidates" to landed.
- Record the inventory undercount ratio (actual-files-touched ÷ pre-flight-file-count) for calibration.
- Update the "Recommended wave 37" section. Promote candidates: `canSendMessagesToPeer(_:)` parameter (the ContactsSearchContainerNode `._asPeer()` bridges at L488/528/562 plus others elsewhere drop when this lands); `peerTokenTitle(peer:)` parameter (drops 3 bridges in ContactMultiselectionController); `makePeerInfoController` / `makeChatQrCodeScreen` / `makeChatRecentActionsController` AccountContext protocol methods (largest remaining Peer-typed-API); accountManager engine path; Shape-C `resourceData` module.

Use the Edit tool on the memory file. No git commit needed.

---

## Risks and notes

- **Inventory undercount.** Pre-flight caught several sites the Explore agent missed (inflow wraps at L481/491/517/527/492/844, cast rewrites at L182-186 and L1968). Budget for 1–3 additional misses surfacing in Task 10. If the build surfaces 5+ misses in new categories, stop and reassess.
- **`replace_all` usage.** Every `replace_all=true` Edit in this plan is gated by a pre-flight `grep -c` count check. If the count is wrong, fall back to per-site Edits with surrounding context.
- **Cast rewrite at L182-186.** The original cast chain binds `group` and `channel` (but not `user`). The EnginePeer case-pattern form preserves this: `case .user = peer` is a binding-free match, mirroring `if let _ = peer as? TelegramUser`.
- **`._asPeer()` sites that stay.** Tasks 4.3 and 5.3 explicitly verify that the 3 `canSendMessagesToPeer(peer._asPeer())` bridges and 3 `peerTokenTitle(peer: peer._asPeer(), ...)` bridges remain intact. Dropping these would be out-of-scope migration.
- **WIP isolation.** Pre-existing `ChatListFilterPresetController.swift` / `ChatListFilterPresetListController.swift` edits and untracked `build-system/tulsi/`, `submodules/TgVoip/`, `third-party/libx264/` paths are user WIP — do NOT stage them. Use the explicit `git add <files>` form in Step 12.2.
- **Scope boundary.** Task 10 errors surfacing in `TelegramCore`, `Postbox`, or `TelegramApi` mean the migration cascaded beyond its intended consumer scope. Halt and investigate — do NOT edit TelegramCore in this wave.
- **No new typealiases/wrappers.** Rule 2 and 3 of the Postbox refactor guidance apply — this wave stays inside.
