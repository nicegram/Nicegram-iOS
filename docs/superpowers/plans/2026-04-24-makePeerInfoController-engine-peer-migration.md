# Wave 39 — `makePeerInfoController` Peer → EnginePeer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the `peer:` parameter of `AccountContext.makePeerInfoController` from raw `Peer` to `EnginePeer`, dropping 61 `_asPeer()` bridges and adding 12 `EnginePeer(...)` wraps.

**Architecture:** Body-shadow pattern (wave-38 style). The protocol and impl signatures change to `peer: EnginePeer`. Inside the impl body, a `let peer = peer._asPeer()` shadow preserves the downstream `peerInfoControllerImpl` (private, same file) as a raw-`Peer` consumer — out of scope for this wave.

**Tech Stack:** Swift, Bazel, iOS; TelegramCore / AccountContext / TelegramUI submodules.

**Spec:** `docs/superpowers/specs/2026-04-24-makePeerInfoController-engine-peer-migration-design.md`

---

## File touch summary

- **Signature** (2 files): `submodules/AccountContext/Sources/AccountContext.swift`, `submodules/TelegramUI/Sources/SharedAccountContext.swift`.
- **Shape-A-variant** (1 file): `submodules/SettingsUI/Sources/Search/SettingsSearchableItems.swift` (3 sites).
- **Shape-C** (8 files, 12 sites): BlockedPeersController, ChannelMembersController, ChannelBlacklistController, ChatRecentActionsControllerNode, PeerInfoScreen, ChatControllerNavigationButtonAction (4), ChatControllerOpenPeer (2), ChatControllerLoadDisplayNode.
- **Shape-A** (~42 files, 58 sites): inline `peer: x._asPeer()` → `peer: x` drops.

Total: ~50 files.

---

### Task 1: Update `AccountContext` protocol signature

**Files:**
- Modify: `submodules/AccountContext/Sources/AccountContext.swift:1371`

- [ ] **Step 1: Apply edit**

Change the protocol declaration to take `peer: EnginePeer` instead of `peer: Peer`.

```swift
// old_string
    func makePeerInfoController(context: AccountContext, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)?, peer: Peer, mode: PeerInfoControllerMode, avatarInitiallyExpanded: Bool, fromChat: Bool, requestsContext: PeerInvitationImportersContext?) -> ViewController?

// new_string
    func makePeerInfoController(context: AccountContext, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)?, peer: EnginePeer, mode: PeerInfoControllerMode, avatarInitiallyExpanded: Bool, fromChat: Bool, requestsContext: PeerInvitationImportersContext?) -> ViewController?
```

---

### Task 2: Update `SharedAccountContext` implementation + body-shadow + 3 self-call Shape-A drops

**Files:**
- Modify: `submodules/TelegramUI/Sources/SharedAccountContext.swift:1937` (signature + body)
- Modify: `submodules/TelegramUI/Sources/SharedAccountContext.swift:3335, 3483, 4016` (Shape-A drops — 3 sites where `self.makePeerInfoController(...)` or `context.sharedContext.makePeerInfoController(...)` is called with `peer: peer._asPeer()`)

- [ ] **Step 1: Update the impl signature and add body-shadow**

```swift
// old_string
    public func makePeerInfoController(context: AccountContext, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)?, peer: Peer, mode: PeerInfoControllerMode, avatarInitiallyExpanded: Bool, fromChat: Bool, requestsContext: PeerInvitationImportersContext?) -> ViewController? {
        let controller = peerInfoControllerImpl(context: context, updatedPresentationData: updatedPresentationData, peer: peer, mode: mode, avatarInitiallyExpanded: avatarInitiallyExpanded, isOpenedFromChat: fromChat)
        controller?.navigationPresentation = .modalInLargeLayout
        return controller
    }

// new_string
    public func makePeerInfoController(context: AccountContext, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)?, peer: EnginePeer, mode: PeerInfoControllerMode, avatarInitiallyExpanded: Bool, fromChat: Bool, requestsContext: PeerInvitationImportersContext?) -> ViewController? {
        let peer = peer._asPeer()
        let controller = peerInfoControllerImpl(context: context, updatedPresentationData: updatedPresentationData, peer: peer, mode: mode, avatarInitiallyExpanded: avatarInitiallyExpanded, isOpenedFromChat: fromChat)
        controller?.navigationPresentation = .modalInLargeLayout
        return controller
    }
```

- [ ] **Step 2: Drop `._asPeer()` at line 3335** (inside `openProfileImpl = { [weak self, weak controller] peer in ...`)

```swift
// old_string
                peer: peer._asPeer(),
                mode: .generic,
                avatarInitiallyExpanded: peer.smallProfileImage != nil,
                fromChat: false,
                requestsContext: nil
            ) {
                controller.replace(with: infoController)

// new_string
                peer: peer,
                mode: .generic,
                avatarInitiallyExpanded: peer.smallProfileImage != nil,
                fromChat: false,
                requestsContext: nil
            ) {
                controller.replace(with: infoController)
```

- [ ] **Step 3: Drop `._asPeer()` at line 3483**

Read 10 lines of context around 3483 to select a unique `old_string` and replace the `peer: peer._asPeer(),` line with `peer: peer,`. The surrounding arguments vary from the line-3335 site, so use a larger surrounding context (6+ lines) to make `old_string` unique.

- [ ] **Step 4: Drop `._asPeer()` at line 4016** (inside `navigateToPeer: { [weak self] peer in ...` in `makeStarsTransferScreen`)

```swift
// old_string
                peer: peer._asPeer(),
                mode: .generic,
                avatarInitiallyExpanded: peer.smallProfileImage != nil,
                fromChat: false,
                requestsContext: nil
            ) {
                if let navigationController = self.mainWindow?.viewController as? NavigationController {
                    navigationController.pushViewController(infoController)

// new_string
                peer: peer,
                mode: .generic,
                avatarInitiallyExpanded: peer.smallProfileImage != nil,
                fromChat: false,
                requestsContext: nil
            ) {
                if let navigationController = self.mainWindow?.viewController as? NavigationController {
                    navigationController.pushViewController(infoController)
```

---

### Task 3: Shape-A-variant drops in `SettingsSearchableItems.swift`

**Files:**
- Modify: `submodules/SettingsUI/Sources/Search/SettingsSearchableItems.swift` (lines 1020, 1046, 1080 — the guard statements upstream of the makePeerInfoController calls at 1023, 1049, 1083)

The call-site line (`peer: peer,`) does not change — the upstream `guard let peer = peer?._asPeer() else` changes to `guard let peer = peer else`, making the local `peer` stay as `EnginePeer` instead of being unwrapped to raw `Peer`.

- [ ] **Step 1: Line 1020** (inside the `id: "my-profile"` item)

```swift
// old_string
                |> deliverOnMainQueue).start(next: { peer in
                    guard let peer = peer?._asPeer() else {
                        return
                    }
                    let controller = context.sharedContext.makePeerInfoController(
                        context: context,
                        updatedPresentationData: nil,
                        peer: peer,
                        mode: .myProfile,

// new_string
                |> deliverOnMainQueue).start(next: { peer in
                    guard let peer = peer else {
                        return
                    }
                    let controller = context.sharedContext.makePeerInfoController(
                        context: context,
                        updatedPresentationData: nil,
                        peer: peer,
                        mode: .myProfile,
```

- [ ] **Step 2: Line 1046** (inside the `id: "my-profile/edit"` item)

The `old_string` is nearly identical to Step 1. Since Edit tool requires uniqueness, use a broader context including the distinguishing `controller.activateEdit()` suffix (at line ~1062) or use `replace_all=false` with a larger context block. Recommended: include the `Queue.mainQueue().justDispatch { if let controller = controller as? PeerInfoScreen { controller.activateEdit() } }` block below the `present(.push, controller)` line to disambiguate.

```swift
// old_string
                |> deliverOnMainQueue).start(next: { peer in
                    guard let peer = peer?._asPeer() else {
                        return
                    }
                    let controller = context.sharedContext.makePeerInfoController(
                        context: context,
                        updatedPresentationData: nil,
                        peer: peer,
                        mode: .myProfile,
                        avatarInitiallyExpanded: false,
                        fromChat: false,
                        requestsContext: nil
                    )
                    present(.push, controller)
                    
                    Queue.mainQueue().justDispatch {
                        if let controller = controller as? PeerInfoScreen {
                            controller.activateEdit()
                        }
                    }
                })

// new_string
                |> deliverOnMainQueue).start(next: { peer in
                    guard let peer = peer else {
                        return
                    }
                    let controller = context.sharedContext.makePeerInfoController(
                        context: context,
                        updatedPresentationData: nil,
                        peer: peer,
                        mode: .myProfile,
                        avatarInitiallyExpanded: false,
                        fromChat: false,
                        requestsContext: nil
                    )
                    present(.push, controller)
                    
                    Queue.mainQueue().justDispatch {
                        if let controller = controller as? PeerInfoScreen {
                            controller.activateEdit()
                        }
                    }
                })
```

- [ ] **Step 3: Line 1080** (inside the `id: "my-profile/gifts"` item — distinguished by `mode: .myProfileGifts`)

```swift
// old_string
                |> deliverOnMainQueue).start(next: { peer in
                    guard let peer = peer?._asPeer() else {
                        return
                    }
                    let controller = context.sharedContext.makePeerInfoController(
                        context: context,
                        updatedPresentationData: nil,
                        peer: peer,
                        mode: .myProfileGifts,

// new_string
                |> deliverOnMainQueue).start(next: { peer in
                    guard let peer = peer else {
                        return
                    }
                    let controller = context.sharedContext.makePeerInfoController(
                        context: context,
                        updatedPresentationData: nil,
                        peer: peer,
                        mode: .myProfileGifts,
```

---

### Task 4: Shape-C wraps (12 sites across 8 files)

**Files:**
- Modify: `submodules/SettingsUI/Sources/Privacy and Security/BlockedPeersController.swift:270`
- Modify: `submodules/PeerInfoUI/Sources/ChannelMembersController.swift:707`
- Modify: `submodules/PeerInfoUI/Sources/ChannelBlacklistController.swift:381`
- Modify: `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsControllerNode.swift:1011`
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift:4306`
- Modify: `submodules/TelegramUI/Sources/Chat/ChatControllerNavigationButtonAction.swift:441, 461, 471, 492`
- Modify: `submodules/TelegramUI/Sources/Chat/ChatControllerOpenPeer.swift:218, 359`
- Modify: `submodules/TelegramUI/Sources/Chat/ChatControllerLoadDisplayNode.swift:4362`

- [ ] **Step 1: BlockedPeersController.swift:270**

```swift
// old_string
    }, openPeer: { peer in
        if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
    }, openPeer: { peer in
        if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: EnginePeer(peer), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 2: ChannelMembersController.swift:707**

```swift
// old_string
            if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: participant.peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
                pushControllerImpl?(infoController)
            }
        }
    }, inviteViaLink: {

// new_string
            if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: EnginePeer(participant.peer), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
                pushControllerImpl?(infoController)
            }
        }
    }, inviteViaLink: {
```

- [ ] **Step 3: ChannelBlacklistController.swift:381**

```swift
// old_string
                } else if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: participant.peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
                    pushControllerImpl?(infoController)
                }
            }))

// new_string
                } else if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: EnginePeer(participant.peer), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
                    pushControllerImpl?(infoController)
                }
            }))
```

- [ ] **Step 4: ChatRecentActionsControllerNode.swift:1011**

```swift
// old_string
                    } else {
                        if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
                            strongSelf.pushController(infoController)
                        }
                    }

// new_string
                    } else {
                        if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: EnginePeer(peer), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
                            strongSelf.pushController(infoController)
                        }
                    }
```

- [ ] **Step 5: PeerInfoScreen.swift:4306** (inside `openPeerInfo(peer: Peer, isMember: Bool)`)

```swift
// old_string
    private func openPeerInfo(peer: Peer, isMember: Bool) {
        let mode: PeerInfoControllerMode = .generic
        if let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: peer, mode: mode, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
    private func openPeerInfo(peer: Peer, isMember: Bool) {
        let mode: PeerInfoControllerMode = .generic
        if let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: EnginePeer(peer), mode: mode, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 6: ChatControllerNavigationButtonAction.swift:441**

Context: the outer `if let peer = self.presentationInterfaceState.renderedPeer?.chatMainPeer` binds `peer` to raw `Peer` (from `RenderedPeer.chatMainPeer` in `TelegramCore/Sources/Utils/PeerUtils.swift:512`). Wrap at the call site.

```swift
// old_string
                                if let peer = self.presentationInterfaceState.renderedPeer?.chatMainPeer, let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: self.updatedPresentationData, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: true, requestsContext: nil) {
                                    self.effectiveNavigationController?.pushViewController(infoController)
                                }

// new_string
                                if let peer = self.presentationInterfaceState.renderedPeer?.chatMainPeer, let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: self.updatedPresentationData, peer: EnginePeer(peer), mode: .generic, avatarInitiallyExpanded: false, fromChat: true, requestsContext: nil) {
                                    self.effectiveNavigationController?.pushViewController(infoController)
                                }
```

- [ ] **Step 7: ChatControllerNavigationButtonAction.swift:461**

Context: `peer` here is the outer `peer` bound from `peerView.peers[peerView.peerId]` (raw Peer) at line 418. Wrap at call site.

```swift
// old_string
                                if let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: self.updatedPresentationData, peer: peer, mode: mode, avatarInitiallyExpanded: expandAvatar, fromChat: true, requestsContext: self.contentData?.inviteRequestsContext) {
                                    self.effectiveNavigationController?.pushViewController(infoController)
                                }
                            }
                            
                            let _ = self.dismissPreviewing?(false)

// new_string
                                if let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: self.updatedPresentationData, peer: EnginePeer(peer), mode: mode, avatarInitiallyExpanded: expandAvatar, fromChat: true, requestsContext: self.contentData?.inviteRequestsContext) {
                                    self.effectiveNavigationController?.pushViewController(infoController)
                                }
                            }
                            
                            let _ = self.dismissPreviewing?(false)
```

- [ ] **Step 8: ChatControllerNavigationButtonAction.swift:471**

Context: `if let peer = self.presentationInterfaceState.renderedPeer?.peer` — raw Peer from Postbox RenderedPeer. Wrap at call site.

```swift
// old_string
                    if let peer = self.presentationInterfaceState.renderedPeer?.peer, case let .replyThread(replyThreadMessage) = self.chatLocation, replyThreadMessage.peerId == self.context.account.peerId {
                        if let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: self.updatedPresentationData, peer: peer, mode: .forumTopic(thread: replyThreadMessage), avatarInitiallyExpanded: false, fromChat: true, requestsContext: nil) {
                            self.effectiveNavigationController?.pushViewController(infoController)
                        }

// new_string
                    if let peer = self.presentationInterfaceState.renderedPeer?.peer, case let .replyThread(replyThreadMessage) = self.chatLocation, replyThreadMessage.peerId == self.context.account.peerId {
                        if let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: self.updatedPresentationData, peer: EnginePeer(peer), mode: .forumTopic(thread: replyThreadMessage), avatarInitiallyExpanded: false, fromChat: true, requestsContext: nil) {
                            self.effectiveNavigationController?.pushViewController(infoController)
                        }
```

- [ ] **Step 9: ChatControllerNavigationButtonAction.swift:492**

Context: `channel` is bound from `self.presentationInterfaceState.renderedPeer?.peer as? TelegramChannel` — raw `TelegramChannel`/`Peer`. Wrap at call site.

```swift
// old_string
                    } else if let channel = self.presentationInterfaceState.renderedPeer?.peer as? TelegramChannel, channel.isForumOrMonoForum, case let .replyThread(message) = self.chatLocation {
                        if let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: self.updatedPresentationData, peer: channel, mode: .forumTopic(thread: message), avatarInitiallyExpanded: false, fromChat: true, requestsContext: self.contentData?.inviteRequestsContext) {

// new_string
                    } else if let channel = self.presentationInterfaceState.renderedPeer?.peer as? TelegramChannel, channel.isForumOrMonoForum, case let .replyThread(message) = self.chatLocation {
                        if let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: self.updatedPresentationData, peer: EnginePeer(channel), mode: .forumTopic(thread: message), avatarInitiallyExpanded: false, fromChat: true, requestsContext: self.contentData?.inviteRequestsContext) {
```

- [ ] **Step 10: ChatControllerOpenPeer.swift:218**

Context: `peer` is raw Peer from the outer closure parameter.

```swift
// old_string
                                        if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: strongSelf.updatedPresentationData, peer: peer, mode: mode, avatarInitiallyExpanded: expandAvatar, fromChat: false, requestsContext: nil) {
                                            strongSelf.effectiveNavigationController?.pushViewController(infoController)
                                        }

// new_string
                                        if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: strongSelf.updatedPresentationData, peer: EnginePeer(peer), mode: mode, avatarInitiallyExpanded: expandAvatar, fromChat: false, requestsContext: nil) {
                                            strongSelf.effectiveNavigationController?.pushViewController(infoController)
                                        }
```

- [ ] **Step 11: ChatControllerOpenPeer.swift:359**

Context: `let peer = self.presentationInterfaceState.renderedPeer?.chatMainPeer` — raw Peer.

```swift
// old_string
                guard let self, let peer = self.presentationInterfaceState.renderedPeer?.chatMainPeer else {
                    return
                }
                
                guard let controller = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {

// new_string
                guard let self, let peer = self.presentationInterfaceState.renderedPeer?.chatMainPeer else {
                    return
                }
                
                guard let controller = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: EnginePeer(peer), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {
```

- [ ] **Step 12: ChatControllerLoadDisplayNode.swift:4362**

Context: `let peer = self.presentationInterfaceState.renderedPeer?.peer` — raw Peer.

```swift
// old_string
                    guard let self, let peer = self.presentationInterfaceState.renderedPeer?.peer else {
                        return
                    }
                    if let controller = self.context.sharedContext.makePeerInfoController(
                        context: self.context,
                        updatedPresentationData: nil,
                        peer: peer,
                        mode: .gifts,

// new_string
                    guard let self, let peer = self.presentationInterfaceState.renderedPeer?.peer else {
                        return
                    }
                    if let controller = self.context.sharedContext.makePeerInfoController(
                        context: self.context,
                        updatedPresentationData: nil,
                        peer: EnginePeer(peer),
                        mode: .gifts,
```

---

### Task 5: Shape-A drops across 42 files (55 remaining sites)

Each Shape-A site swaps `peer: <expr>._asPeer()` for `peer: <expr>` at the listed line. Edits are mechanical; bundle into a single implementer dispatch if using subagent-driven development (wave-38 lesson).

**Files with single sites (replace `peer: <expr>._asPeer(),` or `peer: <expr>._asPeer()` with the `_asPeer()` dropped):**

Most sites have the pattern `peer: peer._asPeer()`. Use the full single-line `makePeerInfoController(...)` call as `old_string` when replacing to guarantee uniqueness. Two sites use different receivers:

- `submodules/TelegramUI/Components/PeerInfo/AffiliateProgramSetupScreen/Sources/JoinAffiliateProgramScreen.swift:878` uses `peer: component.sourcePeer._asPeer(),` — drop to `peer: component.sourcePeer,`.
- `submodules/TelegramUI/Sources/Chat/ChatControllerNavigationButtonAction.swift:486` uses `peer: peer._asPeer()` where `peer` is `EnginePeer` (local name shadowed earlier inside `Task {}`). Drop to `peer: peer,`.

- [ ] **Step 1: SelectivePrivacySettingsPeersController.swift:509**

```swift
// old_string
        guard let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {

// new_string
        guard let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {
```

- [ ] **Step 2: InstantPageControllerNode.swift:1766**

```swift
// old_string
                                            if let controller = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                                            if let controller = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 3: CallListController.swift:375**

```swift
// old_string
                    if let strongSelf = self, let peer = peer, let controller = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .calls(messages: messages.map({ $0._asMessage() })), avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                    if let strongSelf = self, let peer = peer, let controller = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer, mode: .calls(messages: messages.map({ $0._asMessage() })), avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 4: ContactsController.swift:777**

```swift
// old_string
                                        if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                                        if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 5: ContactContextMenus.swift:42**

```swift
// old_string
                        guard let peer = peer, let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {

// new_string
                        guard let peer = peer, let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {
```

- [ ] **Step 6: SecureIdAuthController.swift:343**

```swift
// old_string
                if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 7: ChannelAdminController.swift:1233**

```swift
// old_string
            if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: updatedPresentationData, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
            if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: updatedPresentationData, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 8: ChannelMembersController.swift:785**

```swift
// old_string
                if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 9: ChannelBannedMemberController.swift:785**

```swift
// old_string
            if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: updatedPresentationData, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
            if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: updatedPresentationData, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 10: ChannelPermissionsController.swift:1111**

```swift
// old_string
        if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
        if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 11: GroupStatsController.swift:883**

```swift
// old_string
                if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 12: MessageStatsController.swift:604**

```swift
// old_string
                        if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: peer.largeProfileImage != nil, fromChat: false, requestsContext: nil) {

// new_string
                        if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: peer.largeProfileImage != nil, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 13: InviteRequestsController.swift:379**

```swift
// old_string
        if let navigationController = controller?.navigationController as? NavigationController, let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: peer.largeProfileImage != nil, fromChat: false, requestsContext: nil) {

// new_string
        if let navigationController = controller?.navigationController as? NavigationController, let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: peer.largeProfileImage != nil, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 14: BrowserInstantPageContent.swift:1501**

```swift
// old_string
                                            if let controller = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                                            if let controller = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 15: WebAppController.swift:3375**

```swift
// old_string
                if let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                if let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 16: PeersNearbyController.swift:629**

```swift
// old_string
        if let navigationController = controller?.navigationController as? NavigationController, let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .nearbyPeer(distance: distance), avatarInitiallyExpanded: peer.largeProfileImage != nil, fromChat: false, requestsContext: nil) {

// new_string
        if let navigationController = controller?.navigationController as? NavigationController, let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .nearbyPeer(distance: distance), avatarInitiallyExpanded: peer.largeProfileImage != nil, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 17: ChatSendStarsScreen.swift:2296** (multi-line call; edit the `peer: peer._asPeer(),` line only; include surrounding lines for uniqueness)

Read the 5-line context around line 2296, then edit:

```swift
// old_string (substring)
                                            peer: peer._asPeer(),

// new_string
                                            peer: peer,
```

For uniqueness, include at least one neighboring argument line (e.g., the `mode:` line above or below) in the `old_string`. If truly unique (no other `peer: peer._asPeer(),` lines in this file), `replace_all=false` with this substring works.

- [ ] **Step 18: ChatRecentActionsControllerNode.swift:1031**

```swift
// old_string
                    if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                    if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 19: MiniAppListScreen.swift:230**

```swift
// old_string
            if let peerInfoScreen = component.context.sharedContext.makePeerInfoController(context: component.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
            if let peerInfoScreen = component.context.sharedContext.makePeerInfoController(context: component.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 20: JoinSubjectScreen.swift:320** (multi-line)

Same pattern as Step 17. The `peer: peer._asPeer(),` line at 320 is the only such substring in the file; include the surrounding `mode:` line for safety.

- [ ] **Step 21: NewContactScreen.swift:586**

```swift
// old_string
                                if let infoController = component.context.sharedContext.makePeerInfoController(context: component.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                                if let infoController = component.context.sharedContext.makePeerInfoController(context: component.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 22: StarsTransactionScreen.swift:1958**

```swift
// old_string
                    if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                    if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 23: StoryItemSetContainerComponent.swift:5629**

```swift
// old_string
                    guard let chatController = component.context.sharedContext.makePeerInfoController(context: component.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {

// new_string
                    guard let chatController = component.context.sharedContext.makePeerInfoController(context: component.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {
```

- [ ] **Step 24: StoryItemSetContainerComponent.swift:7619** (multi-line; same pattern as Step 17)

- [ ] **Step 25: StoryItemSetContainerViewSendMessage.swift:3132**

```swift
// old_string
                            if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                            if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 26: StoryItemSetContainerViewSendMessage.swift:3387**

```swift
// old_string
            if let infoController = component.context.sharedContext.makePeerInfoController(context: component.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: mode, avatarInitiallyExpanded: expandAvatar, fromChat: false, requestsContext: nil) {

// new_string
            if let infoController = component.context.sharedContext.makePeerInfoController(context: component.context, updatedPresentationData: nil, peer: peer, mode: mode, avatarInitiallyExpanded: expandAvatar, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 27: GiftViewScreen.swift:413, 561, 2252** (three multi-line sites in the same file; use `replace_all=false` with per-site surrounding context for uniqueness)

Each site has `peer: peer._asPeer(),`. Read 4-line contexts around each line number to construct unique `old_string` blocks. Replace `peer: peer._asPeer(),` with `peer: peer,` in each.

- [ ] **Step 28: GiftOptionsScreen.swift:930** (multi-line; same pattern as Step 17)

- [ ] **Step 29: StorageUsageScreen.swift:2078** (multi-line; same pattern as Step 17)

- [ ] **Step 30: TextProcessingScreen.swift:795**

```swift
// old_string
                            if let peerInfoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                            if let peerInfoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 31: PeerInfoScreen.swift:6915, 7218** (two sites — the `old_string`s look identical; use `replace_all=true` or larger per-site context)

Both lines are identical: `if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {`. If identical in full, `replace_all=true` with this `old_string` handles both. Verify by reading the two surrounding blocks first — if surrounding context differs, use two focused Edit calls instead.

```swift
// old_string (both occurrences)
                    if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                    if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 32: PeerInfoScreenOpenURL.swift:28**

```swift
// old_string
                    if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                    if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 33: JoinAffiliateProgramScreen.swift:878** (multi-line; `peer: component.sourcePeer._asPeer(),` → `peer: component.sourcePeer,`)

- [ ] **Step 34: ChatControllerScrollToPointInHistory.swift:162** (multi-line; `peer: peer._asPeer(),` → `peer: peer,`)

- [ ] **Step 35: OpenUrl.swift:175**

```swift
// old_string
                        if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                        if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 36: OpenUrl.swift:535** (multi-line; `peer: peer._asPeer(),` → `peer: peer,`)

- [ ] **Step 37: OpenResolvedUrl.swift:1810, 1831** (two multi-line sites; `peer: peer._asPeer(),` → `peer: peer,`; use per-site surrounding context for uniqueness)

- [ ] **Step 38: TextLinkHandling.swift:45**

```swift
// old_string
                            if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                            if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 39: ChatController.swift:9437**

```swift
// old_string
                            if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: strongSelf.updatedPresentationData, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                            if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: strongSelf.updatedPresentationData, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 40: ChatManagingBotTitlePanelNode.swift:356**

```swift
// old_string
                                    if let controller = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                                    if let controller = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 41: NavigateToChatController.swift:143**

```swift
// old_string
            if let controller = params.context.sharedContext.makePeerInfoController(context: params.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
            if let controller = params.context.sharedContext.makePeerInfoController(context: params.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 42: OverlayAudioPlayerControllerNode.swift:739** (multi-line)

- [ ] **Step 43: OpenAddContact.swift:28**

```swift
// old_string
                        if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                        if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 44: PollResultsController.swift:451**

```swift
// old_string
            if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
            if let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 45: ChatControllerOpenWebApp.swift:485**

```swift
// old_string
                    if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                    if let infoController = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 46: ChatControllerNavigationButtonAction.swift:486**

Context: inside `Task { @MainActor [weak self] in ...` — local `peer` was bound from `context.engine.data.get(...).get()` (returns `EnginePeer?`), and `_asPeer()` is called to pass to the current Peer-typed API.

```swift
// old_string
                                if let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: self.updatedPresentationData, peer: peer._asPeer(), mode: .monoforum(monoforumPeer.id), avatarInitiallyExpanded: false, fromChat: true, requestsContext: nil) {

// new_string
                                if let infoController = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: self.updatedPresentationData, peer: peer, mode: .monoforum(monoforumPeer.id), avatarInitiallyExpanded: false, fromChat: true, requestsContext: nil) {
```

- [ ] **Step 47: ChatListController.swift:1913**

```swift
// old_string
                        if let peerInfoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                        if let peerInfoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

- [ ] **Step 48: ChatListController.swift:3309**

```swift
// old_string
                                    guard let peer = peer, let controller = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {

// new_string
                                    guard let peer = peer, let controller = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {
```

- [ ] **Step 49: ChatListController.swift:3795**

```swift
// old_string
                    guard let sourceController = sourceController, let peer = peer, let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {

// new_string
                    guard let sourceController = sourceController, let peer = peer, let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {
```

- [ ] **Step 50: ChatListController.swift:7301**

```swift
// old_string
                        guard let self, let peer = peer, let controller = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {

// new_string
                        guard let self, let peer = peer, let controller = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {
```

- [ ] **Step 51: ChatListSearchListPaneNode.swift:4464**

```swift
// old_string
                                if let peerInfoScreen = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: peer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {

// new_string
                                if let peerInfoScreen = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) {
```

**Site count check:** 51 steps listed. Multi-line sites (Steps 17, 20, 24, 27, 28, 29, 33, 34, 36, 37, 42) contain 1–3 sub-sites each; Step 27 covers 3 GiftViewScreen sites, Step 31 covers 2 PeerInfoScreen sites, Step 37 covers 2 OpenResolvedUrl sites. Running total: 51 + 2 (step 27 extras) + 1 (step 31 extra) + 1 (step 37 extra) = 55 sites. Adding 3 self-call sites in Task 2 = 58 Shape-A total. Correct.

---

### Task 6: Full project build verification

- [ ] **Step 1: Run build with `--continueOnError`**

```bash
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 \
 --configuration=debug_sim_arm64 --continueOnError
```

Expected: build succeeds. If errors, collect the error output for Task 7.

Budget: 2–4 iterations. Expected runtime: 200–600 seconds per full build.

---

### Task 7: Fix iteration-surfaced errors (if any)

- [ ] **Step 1: Classify errors**

Common expected categories:
- **Stored-field type mismatches:** a call site passes `peer` declared as raw `Peer` where the migrated API now wants `EnginePeer`. Fix with `EnginePeer(peer)` wrap at the call site (new Shape-C).
- **Closure-parameter type mismatches:** an outer closure types `peer` as `Peer`, fixed by wrapping at the call site with `EnginePeer(peer)`.
- **Downstream inference cascades:** transient errors in Peer-typed helpers not directly calling `makePeerInfoController`. Verify the helper is not `peerInfoControllerImpl` — if it is, investigate whether the body-shadow boundary was violated (abandonment criterion).

- [ ] **Step 2: Apply fixes**

For each unique error site, apply the minimum wrap/drop/shadow change. Do not edit `peerInfoControllerImpl` or any file outside the consumer set. If an error surfaces in `TelegramCore`/`Postbox`/`TelegramApi`, abandon.

- [ ] **Step 3: Rerun the build**

Loop back to Task 6 Step 1. Halt at iteration 5 per abandonment criterion.

---

### Task 8: Commit atomically

- [ ] **Step 1: Review staged diff**

```bash
git status --short
git diff --stat
```

Expected: ~50 files touched. No unexpected files (e.g., `TelegramCore` or `Postbox` edits).

- [ ] **Step 2: Stage and commit**

```bash
git add \
  submodules/AccountContext/Sources/AccountContext.swift \
  submodules/TelegramUI/Sources/SharedAccountContext.swift \
  # ... (all touched files)

git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 39

Migrate AccountContext.makePeerInfoController's peer: parameter from
raw Peer to EnginePeer. Body-shadow pattern preserves downstream
peerInfoControllerImpl as a raw-Peer consumer (out of scope).

73 consumer call sites across ~50 files: 58 Shape-A _asPeer() drops,
3 Shape-A-variant guard-statement drops, 12 Shape-C EnginePeer(...)
wraps. Net -49 bridges.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 3: Verify commit**

```bash
git log --oneline -n 3
git show --stat HEAD
```

---

### Task 9: Update memory + log + CLAUDE.md

- [ ] **Step 1: Append outcome entry to `docs/superpowers/postbox-refactor-log.md`**

Append a "Wave 39 outcome" section with: commit SHA, file count, line-change count, Shape-A/Shape-A-variant/Shape-C tallies, build iteration count, any surprises, any lesson worth adding to wave-selection guidance.

- [ ] **Step 2: Update `project_postbox_refactor_next_wave.md` memory**

Rewrite "Latest commits" and "Wave 39/40 candidates" sections. Promote `makeChatQrCodeScreen` + `makeChatRecentActionsController` to wave 40 (the trivial follow-up). Keep `RenderedPeer → EngineRenderedPeer`, accountManager-side engine path, Shape-C resourceData, and cached-rep triple on the shortlist.

- [ ] **Step 3: Update `CLAUDE.md` wave tally**

The "Waves landed so far" line on CLAUDE.md:44 currently says "36 waves plus standalone cleanups" (stale — waves 37 and 38 landed 2026-04-24 but CLAUDE.md wasn't updated). Bump the tally to "39 waves plus standalone cleanups".

- [ ] **Step 4: Commit the docs update**

```bash
git add docs/superpowers/postbox-refactor-log.md CLAUDE.md
git commit -m "$(cat <<'EOF'
docs: log wave 39 outcome

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Memory file is in `~/.claude/projects/.../memory/` — saved via Write, not git-committed.

---

## Self-review checklist (run before handoff)

- [x] Every numbered Shape-A site in the spec has a corresponding Step in Task 5 (or Task 2/3 for in-signature-file sites).
- [x] Every Shape-C site in the spec table has a corresponding Step in Task 4.
- [x] Protocol + impl signatures shown verbatim.
- [x] Build command includes `source ~/.zshrc 2>/dev/null;` prefix and `--continueOnError`.
- [x] Abandonment criteria inherited from spec.
- [x] No placeholders, TBD, or "implement later".
- [x] Commit message matches the project's wave-NN style (see `git log` output for prior waves).
