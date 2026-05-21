# Wave 34: `FoundPeer.peer: Peer → EnginePeer` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the public field `FoundPeer.peer` from the Postbox `Peer` protocol to the TelegramCore `EnginePeer` enum in a single atomic commit. Drops 5 `._asPeer()` bridges (most added in wave 33), eliminates 22 `EnginePeer(peer.peer)` redundant wraps, rewrites 30 Postbox-concrete-type downcasts to enum patterns, and adds bridges where `peer.peer` flows out to APIs that still take raw `Peer`.

**Architecture:** One atomic commit. The field-type change is necessarily atomic (half-migrated FoundPeer doesn't compile), so all edits land together. TelegramCore's `_internal_searchPeers` keeps `import Postbox` — only `FoundPeer`'s public surface changes. No new wrappers, no new typealiases beyond what already exists.

**Tech Stack:** Swift, Bazel build via Make.py wrapper. No tests — verification is build success + targeted grep checks.

**Spec:** `docs/superpowers/specs/2026-04-24-foundpeer-engine-peer-migration-design.md`

---

## File Structure

**Modified files (8 total — 1 TelegramCore + 7 consumer):**

| File | Edit count |
|---|---|
| `submodules/TelegramCore/Sources/TelegramEngine/Peers/SearchPeers.swift` | ~13 spot edits (struct change + 6 filter rewrites + 4 constructor wraps + manual `==` body) |
| `submodules/TelegramCallsUI/Sources/VideoChatScreen.swift` | 1 (bridge-drop at line 1833) |
| `submodules/TelegramCallsUI/Sources/VideoChatScreenMoreMenu.swift` | 7 (3 C2 downcasts + 4 C3 wraps) |
| `submodules/ContactListUI/Sources/ContactListNode.swift` | ~21 (3 C4 + 13 C2 + 0 C3 + 3 outflow bridges; some lines have multiple edits) |
| `submodules/ChatListUI/Sources/ChatListSearchListPaneNode.swift` | ~17 (8 C2 + ~9 C3) |
| `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenCallActions.swift` | ~10 (2 C4 + 3 C2 + 4 C3 + 1 outflow bridge at line 161 — verify) |
| `submodules/TelegramBaseController/Sources/TelegramBaseController.swift` | 6 (1 C4 + 3 C2 + 2 C3) |
| `submodules/SettingsUI/Sources/Data and Storage/StorageUsageExceptionsScreen.swift` | 3 (1 C4 + 2 C3) |

Note: line counts above are approximations from spec — execution may surface additional outflow-bridge sites caught by the build pass (Task 10).

**EnginePeer enum case mapping (used throughout):**

| Postbox concrete | EnginePeer case |
|---|---|
| `TelegramUser` | `.user(TelegramUser)` |
| `TelegramSecretChat` | `.secretChat(TelegramSecretChat)` |
| `TelegramGroup` | `.legacyGroup(TelegramGroup)` |
| `TelegramChannel` | `.channel(TelegramChannel)` |

---

## Task 1: Edit `SearchPeers.swift` — struct definition + body rewrites

**Files:**
- Modify: `submodules/TelegramCore/Sources/TelegramEngine/Peers/SearchPeers.swift`

This is the foundational change. Without it, none of the consumer edits compile in the right direction.

- [ ] **Step 1.1: Update the FoundPeer struct field, init parameter, and `==` body**

Edit:

```swift
// OLD
public struct FoundPeer: Equatable {
    public let peer: Peer
    public let subscribers: Int32?
    
    public init(peer: Peer, subscribers: Int32?) {
        self.peer = peer
        self.subscribers = subscribers
    }
    
    public static func ==(lhs: FoundPeer, rhs: FoundPeer) -> Bool {
        return lhs.peer.isEqual(rhs.peer) && lhs.subscribers == rhs.subscribers
    }
}
```

```swift
// NEW
public struct FoundPeer: Equatable {
    public let peer: EnginePeer
    public let subscribers: Int32?
    
    public init(peer: EnginePeer, subscribers: Int32?) {
        self.peer = peer
        self.subscribers = subscribers
    }
    
    public static func ==(lhs: FoundPeer, rhs: FoundPeer) -> Bool {
        return lhs.peer == rhs.peer && lhs.subscribers == rhs.subscribers
    }
}
```

Use the Edit tool with the OLD block as `old_string` and the NEW block as `new_string`.

- [ ] **Step 1.2: Wrap raw peer values in the four constructor sites inside `_internal_searchPeers`**

There are four `FoundPeer(peer: peer, subscribers: …)` calls inside `_internal_searchPeers` at lines 70, 72, 85, 87. Each wraps `peer` (a raw `Peer` from `parsedPeers.get(peerId)`) with `EnginePeer(peer)`.

Edit (replace_all=false because there are 4 distinct contexts; use enough surrounding context per edit to make each unique):

For lines 70 and 72 (inside the `myResults` loop):

```swift
// OLD
                            if let user = peer as? TelegramUser {
                                renderedMyPeers.append(FoundPeer(peer: peer, subscribers: user.subscriberCount))
                            } else {
                                renderedMyPeers.append(FoundPeer(peer: peer, subscribers: subscribers[peerId]))
                            }
```

```swift
// NEW
                            if let user = peer as? TelegramUser {
                                renderedMyPeers.append(FoundPeer(peer: EnginePeer(peer), subscribers: user.subscriberCount))
                            } else {
                                renderedMyPeers.append(FoundPeer(peer: EnginePeer(peer), subscribers: subscribers[peerId]))
                            }
```

For lines 85 and 87 (inside the `results` loop):

```swift
// OLD
                            if let user = peer as? TelegramUser {
                                renderedPeers.append(FoundPeer(peer: peer, subscribers: user.subscriberCount))
                            } else {
                                renderedPeers.append(FoundPeer(peer: peer, subscribers: subscribers[peerId]))
                            }
```

```swift
// NEW
                            if let user = peer as? TelegramUser {
                                renderedPeers.append(FoundPeer(peer: EnginePeer(peer), subscribers: user.subscriberCount))
                            } else {
                                renderedPeers.append(FoundPeer(peer: EnginePeer(peer), subscribers: subscribers[peerId]))
                            }
```

- [ ] **Step 1.3: Rewrite the six scope-filter expressions to enum-pattern form**

For `.channels` scope (two filter blocks; identical bodies — use one Edit per block, NOT replace_all, since the surrounding `renderedMyPeers =` vs `renderedPeers =` differs):

```swift
// OLD (renderedMyPeers, lines ~96-102)
                    case .channels:
                        renderedMyPeers = renderedMyPeers.filter { item in
                            if let channel = item.peer as? TelegramChannel, case .broadcast = channel.info {
                                return true
                            } else {
                                return false
                            }
                        }
                        renderedPeers = renderedPeers.filter { item in
                            if let channel = item.peer as? TelegramChannel, case .broadcast = channel.info {
                                return true
                            } else {
                                return false
                            }
                        }
```

```swift
// NEW
                    case .channels:
                        renderedMyPeers = renderedMyPeers.filter { item in
                            if case let .channel(channel) = item.peer, case .broadcast = channel.info {
                                return true
                            } else {
                                return false
                            }
                        }
                        renderedPeers = renderedPeers.filter { item in
                            if case let .channel(channel) = item.peer, case .broadcast = channel.info {
                                return true
                            } else {
                                return false
                            }
                        }
```

For `.groups` scope (two filter blocks):

```swift
// OLD
                    case .groups:
                        renderedMyPeers = renderedMyPeers.filter { item in
                            if let channel = item.peer as? TelegramChannel, case .group = channel.info {
                                return true
                            } else if item.peer is TelegramGroup {
                                return true
                            } else {
                                return false
                            }
                        }
                        renderedPeers = renderedPeers.filter { item in
                            if let channel = item.peer as? TelegramChannel, case .group = channel.info {
                                return true
                            } else if item.peer is TelegramGroup {
                                return true
                            } else {
                                return false
                            }
                        }
```

```swift
// NEW
                    case .groups:
                        renderedMyPeers = renderedMyPeers.filter { item in
                            if case let .channel(channel) = item.peer, case .group = channel.info {
                                return true
                            } else if case .legacyGroup = item.peer {
                                return true
                            } else {
                                return false
                            }
                        }
                        renderedPeers = renderedPeers.filter { item in
                            if case let .channel(channel) = item.peer, case .group = channel.info {
                                return true
                            } else if case .legacyGroup = item.peer {
                                return true
                            } else {
                                return false
                            }
                        }
```

For `.privateChats` scope:

```swift
// OLD
                    case .privateChats:
                        renderedMyPeers = renderedMyPeers.filter { item in
                            if item.peer is TelegramUser {
                                return true
                            } else {
                                return false
                            }
                        }
                        renderedPeers = renderedPeers.filter { item in
                            if item.peer is TelegramUser {
                                return true
                            } else {
                                return false
                            }
                        }
```

```swift
// NEW
                    case .privateChats:
                        renderedMyPeers = renderedMyPeers.filter { item in
                            if case .user = item.peer {
                                return true
                            } else {
                                return false
                            }
                        }
                        renderedPeers = renderedPeers.filter { item in
                            if case .user = item.peer {
                                return true
                            } else {
                                return false
                            }
                        }
```

- [ ] **Step 1.4: Verify** — read the updated file from line 1 to ~155 and confirm there are no remaining `item.peer as? Telegram*` or `item.peer is Telegram*` patterns and the four `FoundPeer(peer: peer, ...)` constructions are now `FoundPeer(peer: EnginePeer(peer), ...)`. Do not commit yet.

---

## Task 2: Edit `VideoChatScreen.swift`

**Files:**
- Modify: `submodules/TelegramCallsUI/Sources/VideoChatScreen.swift`

- [ ] **Step 2.1: Drop `._asPeer()` bridge in the FoundPeer constructor at line 1833**

Edit:

```swift
// OLD
                    |> map { peer in
                        return [FoundPeer(peer: peer._asPeer(), subscribers: nil)]
                    }
```

```swift
// NEW
                    |> map { peer in
                        return [FoundPeer(peer: peer, subscribers: nil)]
                    }
```

The surrounding context (`|> mapToSignal { peer -> Signal<EnginePeer, NoError>` two lines earlier) confirms `peer` is `EnginePeer`. The `._asPeer()` bridge becomes unnecessary.

---

## Task 3: Edit `VideoChatScreenMoreMenu.swift`

**Files:**
- Modify: `submodules/TelegramCallsUI/Sources/VideoChatScreenMoreMenu.swift`

7 edits in this file: 4 C3 wrap-drops + 3 C2 downcast rewrites.

- [ ] **Step 3.1: Drop the two `EnginePeer(peer.peer)` wraps on line 171**

Edit:

```swift
// OLD
                    items.append(.action(ContextMenuActionItem(text: environment.strings.VoiceChat_DisplayAs, textLayout: .secondLineWithValue(EnginePeer(peer.peer).displayTitle(strings: environment.strings, displayOrder: currentCall.accountContext.sharedContext.currentPresentationData.with({ $0 }).nameDisplayOrder)), icon: { _ in nil }, iconSource: ContextMenuActionItemIconSource(size: avatarSize, signal: peerAvatarCompleteImage(account: currentCall.accountContext.account, peer: EnginePeer(peer.peer), size: avatarSize)), action: { [weak self] c, _ in
```

```swift
// NEW
                    items.append(.action(ContextMenuActionItem(text: environment.strings.VoiceChat_DisplayAs, textLayout: .secondLineWithValue(peer.peer.displayTitle(strings: environment.strings, displayOrder: currentCall.accountContext.sharedContext.currentPresentationData.with({ $0 }).nameDisplayOrder)), icon: { _ in nil }, iconSource: ContextMenuActionItemIconSource(size: avatarSize, signal: peerAvatarCompleteImage(account: currentCall.accountContext.account, peer: peer.peer, size: avatarSize)), action: { [weak self] c, _ in
```

- [ ] **Step 3.2: Rewrite the C2 downcasts at lines 628–648**

Edit:

```swift
// OLD (around lines 627-635)
            for peer in displayAsPeers {
                if peer.peer is TelegramGroup {
                    isGroup = true
                    break
                } else if let peer = peer.peer as? TelegramChannel, case .group = peer.info {
                    isGroup = true
                    break
                }
            }
```

```swift
// NEW
            for peer in displayAsPeers {
                if case .legacyGroup = peer.peer {
                    isGroup = true
                    break
                } else if case let .channel(channel) = peer.peer, case .group = channel.info {
                    isGroup = true
                    break
                }
            }
```

(Note the `else if let peer = peer.peer as? TelegramChannel` shadowed the outer loop `peer` with a new `peer: TelegramChannel`. The rewrite uses `channel` to avoid further shadowing the EnginePeer loop variable.)

Edit (around line 648):

```swift
// OLD
                } else if let subscribers = peer.subscribers {
                    if let peer = peer.peer as? TelegramChannel, case .broadcast = peer.info {
                        subtitle = environment.strings.Conversation_StatusSubscribers(subscribers)
                    } else {
                        subtitle = environment.strings.Conversation_StatusMembers(subscribers)
                    }
                }
```

```swift
// NEW
                } else if let subscribers = peer.subscribers {
                    if case let .channel(channel) = peer.peer, case .broadcast = channel.info {
                        subtitle = environment.strings.Conversation_StatusSubscribers(subscribers)
                    } else {
                        subtitle = environment.strings.Conversation_StatusMembers(subscribers)
                    }
                }
```

- [ ] **Step 3.3: Drop the `EnginePeer(peer.peer)` wrap at line 658**

Edit:

```swift
// OLD
                let avatarSignal = peerAvatarCompleteImage(account: groupCall.accountContext.account, peer: EnginePeer(peer.peer), size: avatarSize)
```

```swift
// NEW
                let avatarSignal = peerAvatarCompleteImage(account: groupCall.accountContext.account, peer: peer.peer, size: avatarSize)
```

- [ ] **Step 3.4: Drop the `EnginePeer(peer.peer)` wrap at line 679**

Edit:

```swift
// OLD
                items.append(.action(ContextMenuActionItem(text: EnginePeer(peer.peer).displayTitle(strings: environment.strings, displayOrder: groupCall.accountContext.sharedContext.currentPresentationData.with({ $0 }).nameDisplayOrder), textLayout: subtitle.flatMap { .secondLineWithValue($0) } ?? .singleLine, icon: { _ in nil }, iconSource: ContextMenuActionItemIconSource(size: isSelected ? extendedAvatarSize : avatarSize, signal: avatarSignal), action: { [weak self] _, f in
```

```swift
// NEW
                items.append(.action(ContextMenuActionItem(text: peer.peer.displayTitle(strings: environment.strings, displayOrder: groupCall.accountContext.sharedContext.currentPresentationData.with({ $0 }).nameDisplayOrder), textLayout: subtitle.flatMap { .secondLineWithValue($0) } ?? .singleLine, icon: { _ in nil }, iconSource: ContextMenuActionItemIconSource(size: isSelected ? extendedAvatarSize : avatarSize, signal: avatarSignal), action: { [weak self] _, f in
```

---

## Task 4: Edit `ContactListNode.swift`

**Files:**
- Modify: `submodules/ContactListUI/Sources/ContactListNode.swift`

The largest file: 3 C4 (constructor) edits, 13 C2 (downcast) rewrites, and 3 outflow bridges where `peer.peer` is passed to `.peer(peer:)` (raw-Peer-taking enum case).

- [ ] **Step 4.1: Bridge-drop at constructor lines 1485 and 1517**

Edit:

```swift
// OLD (line 1485)
                                        resultPeers.append(FoundPeer(peer: mainPeer._asPeer(), subscribers: nil))
```

```swift
// NEW
                                        resultPeers.append(FoundPeer(peer: mainPeer, subscribers: nil))
```

(Verification: `mainPeer` is bound from `peer.chatMainPeer` at line 1479. `chatMainPeer` returns `EnginePeer?` on `EngineRenderedPeer`. After migration this needs no bridge.)

Edit:

```swift
// OLD (line 1517)
                            return (peers.map({ FoundPeer(peer: $0._asPeer(), subscribers: nil) }), presences)
```

```swift
// NEW
                            return (peers.map({ FoundPeer(peer: $0, subscribers: nil) }), presences)
```

(Verification: `peers` comes from `context.engine.contacts.searchContacts(query:)` whose return type's first element is `[EnginePeer]`. Confirmed by inspection.)

- [ ] **Step 4.2: Rewrite the C2 downcast at line 1501**

Edit:

```swift
// OLD
                                    if let _ = peer.peer as? TelegramChannel {
```

```swift
// NEW
                                    if case .channel = peer.peer {
```

- [ ] **Step 4.3: Rewrite the three identical C2 sites at lines 1563, 1569, 1574**

These three lines have the SAME pattern (`if let user = peer.peer as? TelegramUser, user.flags.contains(.requirePremium) {`). Use `replace_all=true` since the line is identical (verify uniqueness by grepping first).

Edit (`replace_all=true`):

```swift
// OLD
                                if let user = peer.peer as? TelegramUser, user.flags.contains(.requirePremium) {
```

```swift
// NEW
                                if case let .user(user) = peer.peer, user.flags.contains(.requirePremium) {
```

Verify `replace_all` actually replaced exactly 3 sites (count occurrences before and after; if not 3, something else uses the same pattern and you must split into individual edits).

- [ ] **Step 4.4: Add `._asPeer()` outflow bridges at lines 1656, 1693, 1731**

These are `peers.append(.peer(peer: peer.peer, ...))` where `.peer(peer:)` is `ContactListPeer.peer(peer:isGlobal:participantCount:)` taking raw `Peer`. Add bridge.

Edit (line 1656):

```swift
// OLD
                                peers.append(.peer(peer: peer.peer, isGlobal: false, participantCount: peer.subscribers))
```

```swift
// NEW
                                peers.append(.peer(peer: peer.peer._asPeer(), isGlobal: false, participantCount: peer.subscribers))
```

Edit (line 1693):

```swift
// OLD
                                    peers.append(.peer(peer: peer.peer, isGlobal: true, participantCount: peer.subscribers))
```

```swift
// NEW
                                    peers.append(.peer(peer: peer.peer._asPeer(), isGlobal: true, participantCount: peer.subscribers))
```

The same pattern appears at line 1731 — apply the same edit. Use `replace_all` if and only if the second occurrence is identical (it is, but verify).

- [ ] **Step 4.5: Rewrite the C2 sites at lines 1658, 1665, 1673, 1675, 1695, 1703, 1711, 1713, 1733**

These are scattered through three nearly-identical loop bodies (`localPeersAndStatuses.0`, `remotePeers.0`, `remotePeers.1`). The patterns:

For lines 1658, 1695, 1733 (`if searchDeviceContacts, let user = peer.peer as? TelegramUser, let phone = user.phone`):

Edit (`replace_all=true` if the 3 occurrences are textually identical — verify):

```swift
// OLD
                                if searchDeviceContacts,
                                   let user = peer.peer as? TelegramUser,
                                   let phone = user.phone {
```

```swift
// NEW
                                if searchDeviceContacts,
                                   case let .user(user) = peer.peer,
                                   let phone = user.phone {
```

For line 1665 and 1703 (single-condition `if let user = peer.peer as? TelegramUser {`):

Edit (`replace_all=true` if textually identical):

```swift
// OLD
                                if let user = peer.peer as? TelegramUser {
```

```swift
// NEW
                                if case let .user(user) = peer.peer {
```

For line 1673 (`if peer.peer is TelegramGroup && searchGroups`):

Edit:

```swift
// OLD
                                    if peer.peer is TelegramGroup && searchGroups {
                                        matches = true
                                    } else if let channel = peer.peer as? TelegramChannel {
```

```swift
// NEW
                                    if case .legacyGroup = peer.peer, searchGroups {
                                        matches = true
                                    } else if case let .channel(channel) = peer.peer {
```

For line 1711 (`if peer.peer is TelegramGroup`):

Edit:

```swift
// OLD
                                    if peer.peer is TelegramGroup {
                                        matches = searchGroups
                                    } else if let channel = peer.peer as? TelegramChannel {
```

```swift
// NEW
                                    if case .legacyGroup = peer.peer {
                                        matches = searchGroups
                                    } else if case let .channel(channel) = peer.peer {
```

(Note that line 1675 and 1713 carry the same `else if let channel = peer.peer as? TelegramChannel` pattern that is folded into the edits above. Confirm both got rewritten.)

- [ ] **Step 4.6: Verify** — grep for remaining FoundPeer-relevant Postbox patterns in the file:

Run: `grep -nE "peer\.peer\s+(as\?|is)\s+Telegram|EnginePeer\(peer\.peer\)|FoundPeer\(peer:\s+\w+\._asPeer\(\)" submodules/ContactListUI/Sources/ContactListNode.swift`

Expected: zero matches if the C2/C3/C4 edits are complete.

---

## Task 5: Edit `ChatListSearchListPaneNode.swift`

**Files:**
- Modify: `submodules/ChatListUI/Sources/ChatListSearchListPaneNode.swift`

8 C2 downcasts + 9 C3 wrap drops.

- [ ] **Step 5.1a: Add outflow bridge at line 1018**

Edit:

```swift
// OLD
                    enabled = canSendMessagesToPeer(peer.peer)
```

```swift
// NEW
                    enabled = canSendMessagesToPeer(peer.peer._asPeer())
```

(`canSendMessagesToPeer(_ peer: Peer, ...)` in `submodules/TelegramCore/Sources/Utils/CanSendMessagesToPeer.swift` takes raw `Peer`, so the bridge is required.)

- [ ] **Step 5.1b: Rewrite the disjunction at line 1024 using `switch`**

Edit:

```swift
// OLD
                if filter.contains(.onlyPrivateChats) {
                    if !(peer.peer is TelegramUser || peer.peer is TelegramSecretChat) {
                        enabled = false
                    }
                }
```

```swift
// NEW
                if filter.contains(.onlyPrivateChats) {
                    switch peer.peer {
                    case .user, .secretChat:
                        break
                    default:
                        enabled = false
                    }
                }
```

The `switch ... case .user, .secretChat: break / default: enabled = false` form preserves the negation semantics of the original `if !(... || ...)` and reads cleanly.

- [ ] **Step 5.1c: Rewrite C2 downcasts at lines 1029-1030**

Edit (lines 1029-1030):

```swift
// OLD
                    if let _ = peer.peer as? TelegramGroup {
                    } else if let peer = peer.peer as? TelegramChannel, case .group = peer.info {
```

```swift
// NEW
                    if case .legacyGroup = peer.peer {
                    } else if case let .channel(channel) = peer.peer, case .group = channel.info {
```

Edit (lines 1038-1040):

```swift
// OLD
                    if peer.peer is TelegramUser {
```

(continues `} else if let channel = peer.peer as? TelegramChannel, case .broadcast = channel.info {` at line 1040)

```swift
// NEW
                    if case .user = peer.peer {
```

```swift
// OLD
                    } else if let channel = peer.peer as? TelegramChannel, case .broadcast = channel.info {
```

```swift
// NEW
                    } else if case let .channel(channel) = peer.peer, case .broadcast = channel.info {
```

(If line 1040's old form is used elsewhere in the file, scope the Edit by including more surrounding context.)

- [ ] **Step 5.2: Drop C3 wraps on line 1075**

Edit:

```swift
// OLD
                return ContactsPeerItem(presentationData: ItemListPresentationData(presentationData), sortOrder: nameSortOrder, displayOrder: nameDisplayOrder, context: context, peerMode: .generalSearch(isSavedMessages: isSavedMessages), peer: .peer(peer: EnginePeer(peer.peer), chatPeer: EnginePeer(peer.peer)), status: .addressName(suffixString), badge: badge, requiresPremiumForMessaging: requiresPremiumForMessaging, enabled: enabled, selection: .none, editing: ContactsPeerItemEditing(editable: false, editing: false, revealed: false), index: nil, header: header, searchQuery: query, isAd: false, action: { _ in
```

```swift
// NEW
                return ContactsPeerItem(presentationData: ItemListPresentationData(presentationData), sortOrder: nameSortOrder, displayOrder: nameDisplayOrder, context: context, peerMode: .generalSearch(isSavedMessages: isSavedMessages), peer: .peer(peer: peer.peer, chatPeer: peer.peer), status: .addressName(suffixString), badge: badge, requiresPremiumForMessaging: requiresPremiumForMessaging, enabled: enabled, selection: .none, editing: ContactsPeerItemEditing(editable: false, editing: false, revealed: false), index: nil, header: header, searchQuery: query, isAd: false, action: { _ in
```

- [ ] **Step 5.3: Drop C3 wraps on lines 1076, 1078, 1081**

Edit (line 1076):

```swift
// OLD
                    interaction.peerSelected(EnginePeer(peer.peer), nil, nil, nil, false)
```

```swift
// NEW
                    interaction.peerSelected(peer.peer, nil, nil, nil, false)
```

Edit (line 1078):

```swift
// OLD
                    interaction.disabledPeerSelected(EnginePeer(peer.peer), nil, requiresPremiumForMessaging ? .premiumRequired : .generic)
```

```swift
// NEW
                    interaction.disabledPeerSelected(peer.peer, nil, requiresPremiumForMessaging ? .premiumRequired : .generic)
```

Edit (line 1081):

```swift
// OLD
                        peerContextAction(EnginePeer(peer.peer), .search(nil), node, gesture, location)
```

```swift
// NEW
                        peerContextAction(peer.peer, .search(nil), node, gesture, location)
```

- [ ] **Step 5.4: Rewrite the C2 downcasts at lines 1500 and 1507 (inside `filteredPeerSearchQueryResults`)**

Edit (line 1500, inside `value.0.filter`):

```swift
// OLD
            value.0.filter { peer in
                if let channel = peer.peer as? TelegramChannel, case .broadcast = channel.info {
                    return true
                } else {
                    return false
                }
            },
```

```swift
// NEW
            value.0.filter { peer in
                if case let .channel(channel) = peer.peer, case .broadcast = channel.info {
                    return true
                } else {
                    return false
                }
            },
```

Edit (line 1507, inside `value.1.filter`):

```swift
// OLD
            value.1.filter { peer in
                if let channel = peer.peer as? TelegramChannel, case .broadcast = channel.info {
                    return true
                } else {
                    return false
                }
            }
```

```swift
// NEW
            value.1.filter { peer in
                if case let .channel(channel) = peer.peer, case .broadcast = channel.info {
                    return true
                } else {
                    return false
                }
            }
```

- [ ] **Step 5.5: Drop C3 wraps in `foundRemotePeers` loops (lines 3088, 3096, 3214, 3216, 3241)**

Edit (`replace_all=true` for the lines that match exactly the same pattern, otherwise individual Edits):

```swift
// OLD (occurs at 3088, 3096, 3214, 3241 — the FoundPeer wrap; the EnginePeer(accountPeer) wrap stays since `accountPeer` is raw Peer)
                    if !existingPeerIds.contains(peer.peer.id), filteredPeer(EnginePeer(peer.peer), EnginePeer(accountPeer)) {
```

```swift
// NEW
                    if !existingPeerIds.contains(peer.peer.id), filteredPeer(peer.peer, EnginePeer(accountPeer)) {
```

If `replace_all=true`, verify the count is exactly 4 by grep before and after.

Edit (line 3216 separately — different pattern):

```swift
// OLD
                        entries.append(.localPeer(EnginePeer(peer.peer), nil, nil, index, presentationData.theme, presentationData.strings, presentationData.nameSortOrder, presentationData.nameDisplayOrder, localExpandType, nil, false, false))
```

```swift
// NEW
                        entries.append(.localPeer(peer.peer, nil, nil, index, presentationData.theme, presentationData.strings, presentationData.nameSortOrder, presentationData.nameDisplayOrder, localExpandType, nil, false, false))
```

(Note: this assumes `.localPeer(EnginePeer, ...)` accepts EnginePeer directly. If the build fails saying it expected raw `Peer`, add `._asPeer()` instead. Verify in build pass.)

- [ ] **Step 5.6: Verify** — grep:

Run: `grep -nE "peer\.peer\s+(as\?|is)\s+Telegram|EnginePeer\(peer\.peer\)" submodules/ChatListUI/Sources/ChatListSearchListPaneNode.swift`

Expected: zero matches.

---

## Task 6: Edit `PeerInfoScreenCallActions.swift`

**Files:**
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenCallActions.swift`

2 C4 bridge-drops + 3 C2 downcasts + 4 C3 wraps. The function is duplicated almost verbatim at the second site (line 156 vs 265).

- [ ] **Step 6.1: Bridge-drops at lines 156 and 265**

Edit (`replace_all=true` if the line is literally identical at both sites):

```swift
// OLD
            return [FoundPeer(peer: peer._asPeer(), subscribers: nil)]
```

```swift
// NEW
            return [FoundPeer(peer: peer, subscribers: nil)]
```

Verify `replace_all` got exactly 2 sites.

- [ ] **Step 6.2: Rewrite C2 downcasts at lines 175, 178, 193**

Edit (lines 175 and 178 form one if-else chain):

```swift
// OLD
                for peer in peers {
                    if peer.peer is TelegramGroup {
                        isGroup = true
                        break
                    } else if let peer = peer.peer as? TelegramChannel, case .group = peer.info {
                        isGroup = true
                        break
                    }
                }
```

```swift
// NEW
                for peer in peers {
                    if case .legacyGroup = peer.peer {
                        isGroup = true
                        break
                    } else if case let .channel(channel) = peer.peer, case .group = channel.info {
                        isGroup = true
                        break
                    }
                }
```

Edit (line 193 — inside the second `for peer in peers` loop):

```swift
// OLD
                    } else if let subscribers = peer.subscribers {
                        if let peer = peer.peer as? TelegramChannel, case .broadcast = peer.info {
                            subtitle = strongSelf.presentationData.strings.Conversation_StatusSubscribers(subscribers)
                        } else {
                            subtitle = strongSelf.presentationData.strings.Conversation_StatusMembers(subscribers)
                        }
                    }
```

```swift
// NEW
                    } else if let subscribers = peer.subscribers {
                        if case let .channel(channel) = peer.peer, case .broadcast = channel.info {
                            subtitle = strongSelf.presentationData.strings.Conversation_StatusSubscribers(subscribers)
                        } else {
                            subtitle = strongSelf.presentationData.strings.Conversation_StatusMembers(subscribers)
                        }
                    }
```

- [ ] **Step 6.3: Drop C3 wraps at lines 201, 202**

Edit:

```swift
// OLD
                    let avatarSignal = peerAvatarCompleteImage(account: strongSelf.context.account, peer: EnginePeer(peer.peer), size: avatarSize)
                    items.append(.action(ContextMenuActionItem(text: EnginePeer(peer.peer).displayTitle(strings: strongSelf.presentationData.strings, displayOrder: strongSelf.presentationData.nameDisplayOrder), textLayout: subtitle.flatMap { .secondLineWithValue($0) } ?? .singleLine, icon: { _ in nil }, iconSource: ContextMenuActionItemIconSource(size: avatarSize, signal: avatarSignal), action: { _, f in
```

```swift
// NEW
                    let avatarSignal = peerAvatarCompleteImage(account: strongSelf.context.account, peer: peer.peer, size: avatarSize)
                    items.append(.action(ContextMenuActionItem(text: peer.peer.displayTitle(strings: strongSelf.presentationData.strings, displayOrder: strongSelf.presentationData.nameDisplayOrder), textLayout: subtitle.flatMap { .secondLineWithValue($0) } ?? .singleLine, icon: { _ in nil }, iconSource: ContextMenuActionItemIconSource(size: avatarSize, signal: avatarSignal), action: { _, f in
```

- [ ] **Step 6.4: Drop two C3 wraps on line 288**

Edit:

```swift
// OLD
                    items.append(.action(ContextMenuActionItem(text: strongSelf.presentationData.strings.VoiceChat_DisplayAs, textLayout: .secondLineWithValue(EnginePeer(peer.peer).displayTitle(strings: strongSelf.presentationData.strings, displayOrder: strongSelf.presentationData.nameDisplayOrder)), icon: { _ in nil }, iconSource: ContextMenuActionItemIconSource(size: avatarSize, signal: peerAvatarCompleteImage(account: strongSelf.context.account, peer: EnginePeer(peer.peer), size: avatarSize)), action: { c, f in
```

```swift
// NEW
                    items.append(.action(ContextMenuActionItem(text: strongSelf.presentationData.strings.VoiceChat_DisplayAs, textLayout: .secondLineWithValue(peer.peer.displayTitle(strings: strongSelf.presentationData.strings, displayOrder: strongSelf.presentationData.nameDisplayOrder)), icon: { _ in nil }, iconSource: ContextMenuActionItemIconSource(size: avatarSize, signal: peerAvatarCompleteImage(account: strongSelf.context.account, peer: peer.peer, size: avatarSize)), action: { c, f in
```

- [ ] **Step 6.5: Verify** — grep:

Run: `grep -nE "peer\.peer\s+(as\?|is)\s+Telegram|EnginePeer\(peer\.peer\)" submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenCallActions.swift`

Expected: zero matches.

---

## Task 7: Edit `TelegramBaseController.swift`

**Files:**
- Modify: `submodules/TelegramBaseController/Sources/TelegramBaseController.swift`

1 C4 bridge-drop + 3 C2 downcasts + 2 C3 wraps.

- [ ] **Step 7.1: Bridge-drop at line 208**

Edit:

```swift
// OLD
            |> map { peer in
                return [FoundPeer(peer: peer._asPeer(), subscribers: nil)]
            }
```

```swift
// NEW
            |> map { peer in
                return [FoundPeer(peer: peer, subscribers: nil)]
            }
```

- [ ] **Step 7.2: Rewrite C2 downcasts at lines 243, 246, 258**

Edit (lines 243 and 246 form one if-else chain):

```swift
// OLD
                        for peer in peers {
                            if peer.peer is TelegramGroup {
                                isGroup = true
                                break
                            } else if let peer = peer.peer as? TelegramChannel, case .group = peer.info {
                                isGroup = true
                                break
                            }
                        }
```

```swift
// NEW
                        for peer in peers {
                            if case .legacyGroup = peer.peer {
                                isGroup = true
                                break
                            } else if case let .channel(channel) = peer.peer, case .group = channel.info {
                                isGroup = true
                                break
                            }
                        }
```

Edit (line 258):

```swift
// OLD
                            } else if let subscribers = peer.subscribers {
                                if let peer = peer.peer as? TelegramChannel, case .broadcast = peer.info {
                                    subtitle = strongSelf.presentationData.strings.Conversation_StatusSubscribers(subscribers)
                                } else {
                                    subtitle = strongSelf.presentationData.strings.Conversation_StatusMembers(subscribers)
                                }
                            }
```

```swift
// NEW
                            } else if let subscribers = peer.subscribers {
                                if case let .channel(channel) = peer.peer, case .broadcast = channel.info {
                                    subtitle = strongSelf.presentationData.strings.Conversation_StatusSubscribers(subscribers)
                                } else {
                                    subtitle = strongSelf.presentationData.strings.Conversation_StatusMembers(subscribers)
                                }
                            }
```

- [ ] **Step 7.3: Drop two C3 wraps on line 265**

Edit:

```swift
// OLD
                            items.append(VoiceChatPeerActionSheetItem(context: context, peer: EnginePeer(peer.peer), title: EnginePeer(peer.peer).displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder), subtitle: subtitle ?? "", action: {
```

```swift
// NEW
                            items.append(VoiceChatPeerActionSheetItem(context: context, peer: peer.peer, title: peer.peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder), subtitle: subtitle ?? "", action: {
```

- [ ] **Step 7.4: Verify** — grep:

Run: `grep -nE "peer\.peer\s+(as\?|is)\s+Telegram|EnginePeer\(peer\.peer\)" submodules/TelegramBaseController/Sources/TelegramBaseController.swift`

Expected: zero matches.

---

## Task 8: Edit `StorageUsageExceptionsScreen.swift`

**Files:**
- Modify: `submodules/SettingsUI/Sources/Data and Storage/StorageUsageExceptionsScreen.swift`

1 C4 wrap-needed + 2 C3 wrap-drops.

- [ ] **Step 8.1: Drop C3 wrap at line 173**

Edit:

```swift
// OLD
                title = EnginePeer(peer.peer).displayTitle(strings: presentationData.strings, displayOrder: .firstLast)
```

```swift
// NEW
                title = peer.peer.displayTitle(strings: presentationData.strings, displayOrder: .firstLast)
```

- [ ] **Step 8.2: Drop C3 wrap at line 176**

Edit:

```swift
// OLD
            return ItemListDisclosureItem(presentationData: presentationData, icon: nil, context: arguments.context, iconPeer: EnginePeer(peer.peer), title: title, enabled: true, titleFont: .bold, label: optionText, labelStyle: .text, additionalDetailLabel: additionalDetailLabel, sectionId: self.section, style: .blocks, disclosureStyle: .optionArrows, action: {
```

```swift
// NEW
            return ItemListDisclosureItem(presentationData: presentationData, icon: nil, context: arguments.context, iconPeer: peer.peer, title: title, enabled: true, titleFont: .bold, label: optionText, labelStyle: .text, additionalDetailLabel: additionalDetailLabel, sectionId: self.section, style: .blocks, disclosureStyle: .optionArrows, action: {
```

- [ ] **Step 8.3: Add EnginePeer wrap at constructor line 288**

Edit:

```swift
// OLD
                result.append((peer: FoundPeer(peer: peer, subscribers: subscriberCount), value: value))
```

```swift
// NEW
                result.append((peer: FoundPeer(peer: EnginePeer(peer), subscribers: subscriberCount), value: value))
```

(Verification: `peer` here is bound from a Postbox transaction higher up — it is a raw `Peer`. The wrap is required.)

- [ ] **Step 8.4: Verify** — grep:

Run: `grep -nE "EnginePeer\(peer\.peer\)" "submodules/SettingsUI/Sources/Data and Storage/StorageUsageExceptionsScreen.swift"`

Expected: zero matches.

---

## Task 9: Build verification (first pass)

- [ ] **Step 9.1: Run the full build with `--continueOnError`**

Run:

```bash
source ~/.zshrc 2>/dev/null && python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 --configuration=debug_sim_arm64 --continueOnError 2>&1 | tee /tmp/wave34-build.log
```

Expected outcome: ideally clean. Realistic outcome: a small number of errors at sites the inventory missed.

- [ ] **Step 9.2: Triage build errors**

Likely error patterns and their fixes:

| Error | Fix |
|---|---|
| `cannot convert value of type 'EnginePeer' to expected argument type 'Peer'` at site `<api>(peer.peer, ...)` | Add `._asPeer()` bridge: `<api>(peer.peer._asPeer(), ...)` |
| `value of type 'EnginePeer' has no member 'isEqual'` | Replace with `==`: `peer.peer == otherPeer` |
| `cannot convert value of type 'EnginePeer' to expected argument type 'Peer?'` | Same as above: `._asPeer()` bridge |
| `pattern of type 'TelegramX' cannot match values of type 'EnginePeer'` | Missed C2 site — rewrite to `if case .X = peer.peer` form |
| `extraneous argument 'EnginePeer'` (when `.localPeer` etc. expected raw Peer) | Add `._asPeer()` bridge |

For each error, identify the file:line, apply the appropriate fix, and re-run the build (Step 9.1) until clean.

- [ ] **Step 9.3: Iterate to clean build**

Re-run the build after each batch of fixes. The wave is complete when the build returns 0 errors.

If 10+ unexpected errors surface, halt and reassess: the inventory was significantly incomplete and the wave may need to be split into pre-cleanup commits. Discuss with user.

---

## Task 10: Post-build grep validations

- [ ] **Step 10.1: Bridge-drop validation**

Run:

```bash
grep -rn "FoundPeer(peer:.*\._asPeer()" submodules/ --include="*.swift" | grep -v "^submodules/TelegramCore/" | grep -v "^submodules/Postbox/"
```

Expected: zero hits. If any remain, they are missed bridge-drops — fix and re-build.

- [ ] **Step 10.2: C3 wrap validation**

Run for each touched consumer file:

```bash
for f in submodules/TelegramCallsUI/Sources/VideoChatScreen.swift \
         submodules/TelegramCallsUI/Sources/VideoChatScreenMoreMenu.swift \
         submodules/ContactListUI/Sources/ContactListNode.swift \
         submodules/ChatListUI/Sources/ChatListSearchListPaneNode.swift \
         submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenCallActions.swift \
         submodules/TelegramBaseController/Sources/TelegramBaseController.swift \
         "submodules/SettingsUI/Sources/Data and Storage/StorageUsageExceptionsScreen.swift"; do
  echo "=== $f ==="
  grep -n "EnginePeer(peer\.peer)" "$f"
done
```

Expected: zero hits in each touched file.

- [ ] **Step 10.3: C2 downcast validation**

Run:

```bash
for f in submodules/TelegramCallsUI/Sources/VideoChatScreenMoreMenu.swift \
         submodules/ContactListUI/Sources/ContactListNode.swift \
         submodules/ChatListUI/Sources/ChatListSearchListPaneNode.swift \
         submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenCallActions.swift \
         submodules/TelegramBaseController/Sources/TelegramBaseController.swift; do
  echo "=== $f ==="
  grep -nE "peer\.peer\s+(as\?|is)\s+Telegram" "$f"
done
```

Expected: zero hits.

If any of the validations fail, return to Task 9 to fix.

---

## Task 11: Single atomic commit + memory + log update

- [ ] **Step 11.1: Stage and review**

Run:

```bash
git status --short
git diff --stat
```

Confirm exactly 8 modified files (1 TelegramCore + 7 consumer) and no other unintended changes. WIP from earlier (`build-system/bazel-rules/sourcekit-bazel-bsp`, `ChatListFilterPresetController.swift`, `ChatListFilterPresetListController.swift`, untracked `build-system/tulsi/`, `submodules/TgVoip/`, `third-party/libx264/`) should NOT be staged.

- [ ] **Step 11.2: Stage only the wave-34 files**

Run:

```bash
git add submodules/TelegramCore/Sources/TelegramEngine/Peers/SearchPeers.swift \
        submodules/TelegramCallsUI/Sources/VideoChatScreen.swift \
        submodules/TelegramCallsUI/Sources/VideoChatScreenMoreMenu.swift \
        submodules/ContactListUI/Sources/ContactListNode.swift \
        submodules/ChatListUI/Sources/ChatListSearchListPaneNode.swift \
        submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenCallActions.swift \
        submodules/TelegramBaseController/Sources/TelegramBaseController.swift \
        "submodules/SettingsUI/Sources/Data and Storage/StorageUsageExceptionsScreen.swift"
```

- [ ] **Step 11.3: Commit**

Run:

```bash
git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 34: FoundPeer.peer Peer -> EnginePeer

Migrates the public field `FoundPeer.peer` from the Postbox `Peer` protocol
to the TelegramCore `EnginePeer` enum. The `_internal_searchPeers` body
keeps `import Postbox` (it still calls `postbox.transaction`) and wraps raw
peer values with `EnginePeer(peer)` at the FoundPeer constructor sites.

Consumer-side cascade in 7 files:
  - 5 `._asPeer()` bridge-drops at FoundPeer constructor sites
  - 22 redundant `EnginePeer(peer.peer)` wrap drops (the field is now
    EnginePeer, so the wrap fails to compile)
  - 30 `peer.peer as? TelegramX` / `is TelegramX` Postbox-concrete
    downcasts rewritten to `if case .X = peer.peer` enum-pattern form
  - 3 `._asPeer()` bridges added where `peer.peer` flows into
    `ContactListPeer.peer(peer:)` (downstream API still takes raw Peer)
  - Manual `==` body updated from `lhs.peer.isEqual(rhs.peer)` to
    `lhs.peer == rhs.peer` (EnginePeer is Equatable)

Files modified:
  submodules/TelegramCore/Sources/TelegramEngine/Peers/SearchPeers.swift
  submodules/TelegramCallsUI/Sources/VideoChatScreen.swift
  submodules/TelegramCallsUI/Sources/VideoChatScreenMoreMenu.swift
  submodules/ContactListUI/Sources/ContactListNode.swift
  submodules/ChatListUI/Sources/ChatListSearchListPaneNode.swift
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenCallActions.swift
  submodules/TelegramBaseController/Sources/TelegramBaseController.swift
  submodules/SettingsUI/Sources/Data and Storage/StorageUsageExceptionsScreen.swift

Plan: docs/superpowers/plans/2026-04-24-foundpeer-engine-peer-migration.md
Spec: docs/superpowers/specs/2026-04-24-foundpeer-engine-peer-migration-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 11.4: Update CLAUDE.md wave counter**

Edit `CLAUDE.md` to bump the "Waves landed so far" line from "33 waves" to "34 waves" and update the "as of" date if changed.

- [ ] **Step 11.5: Append wave outcome to the postbox-refactor-log**

Append a new "Wave 34 outcome" section to `docs/superpowers/postbox-refactor-log.md` documenting the migration, the actual edit count (in case it differed from the planned ~70), and any lessons learned. Keep concise.

- [ ] **Step 11.6: Commit the docs update**

Run:

```bash
git add CLAUDE.md docs/superpowers/postbox-refactor-log.md
git commit -m "$(cat <<'EOF'
docs: add wave 34 outcome (FoundPeer.peer Peer→EnginePeer)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 11.7: Update the next-wave memory**

Update `/Users/isaac/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`:
- Add wave 34 to the "Latest commits" section
- Move FoundPeer migration from "Wave 34+ candidates" to landed
- Reframe remaining work: SendAsPeer, makePeerInfoController, etc., are now the next ring of Peer-typed-API waves
- Note any newly-surfaced bridge-add sites (the 3 `._asPeer()` bridges in ContactListNode point to `ContactListPeer.peer(peer:)` as the next downstream-API migration target)

Use the Edit tool on the memory file. No git commit needed for the memory file (it's outside the repo).

---

## Risks and notes

- **Inner `peer` shadowing.** Several rewrites collapse `else if let peer = peer.peer as? TelegramChannel` patterns where the inner `peer` shadows the loop variable. The rewrites use `channel` as the new binding name to avoid double shadowing of the EnginePeer loop variable. Confirm subsequent uses of the bound name within the if-let scope are updated (e.g., `peer.info` becomes `channel.info`).
- **`replace_all` correctness.** Whenever the plan suggests `replace_all=true`, verify the count first via grep. If the count is unexpected, revert to per-site Edits with surrounding context.
- **Outflow-bridge surprises.** The plan enumerates 3 `._asPeer()` outflow bridges in ContactListNode. The build pass (Task 9) may surface 1–3 more in other touched files (e.g., ChatListSearchListPaneNode's `.localPeer` case). Apply the bridge pattern to each and iterate.
- **WIP isolation.** Pre-existing modifications to `ChatListFilterPresetController.swift`, `ChatListFilterPresetListController.swift`, the `sourcekit-bazel-bsp` submodule marker, and untracked `build-system/tulsi/` / `submodules/TgVoip/` / `third-party/libx264/` are user WIP — do NOT stage them. Use the explicit `git add <files>` form in Step 11.2.
