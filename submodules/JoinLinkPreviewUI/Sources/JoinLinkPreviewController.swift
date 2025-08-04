// Nicegram
import FeatAttentionEconomy
//
import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import AlertUI
import PresentationDataUtils
import UndoUI
import OldChannelsController

public final class LegacyJoinLinkPreviewController: ViewController {
    private var controllerNode: JoinLinkPreviewControllerNode {
        return self.displayNode as! JoinLinkPreviewControllerNode
    }
    
    private var animatedIn = false
    
    private let context: AccountContext
    private let link: String
    private var isRequest = false
    private var isGroup = false
    private let navigateToPeer: (EnginePeer, ChatPeekTimeout?) -> Void
    private let parentNavigationController: NavigationController?
    private var resolvedState: ExternalJoiningChatState?
    private var presentationData: PresentationData
    
    private let disposable = MetaDisposable()
    
    public init(context: AccountContext, link: String, navigateToPeer: @escaping (EnginePeer, ChatPeekTimeout?) -> Void, parentNavigationController: NavigationController?, resolvedState: ExternalJoiningChatState? = nil) {
        self.context = context
        self.link = link
        self.navigateToPeer = navigateToPeer
        self.parentNavigationController = parentNavigationController
        self.resolvedState = resolvedState
        
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: nil)
        
        self.statusBar.statusBarStyle = .Ignore
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.disposable.dispose()
    }
    
    override public func loadDisplayNode() {
        self.displayNode = JoinLinkPreviewControllerNode(context: self.context, requestLayout: { [weak self] transition in
            self?.requestLayout(transition: transition)
        })
        self.controllerNode.dismiss = { [weak self] in
            self?.presentingViewController?.dismiss(animated: false, completion: nil)
        }
        self.controllerNode.cancel = { [weak self] in
            self?.dismiss()
        }
        self.controllerNode.join = { [weak self] in
            self?.join()
        }
        self.displayNodeDidLoad()
        
        let signal: Signal<ExternalJoiningChatState, JoinLinkInfoError>
        if let resolvedState = self.resolvedState {
            signal = .single(resolvedState)
        } else {
            signal = self.context.engine.peers.joinLinkInformation(self.link)
        }
        
        self.disposable.set((signal
        |> deliverOnMainQueue).start(next: { [weak self] result in
            if let strongSelf = self {
                strongSelf.resolvedState = result
                switch result {
                    case let .invite(invite):
                        if invite.flags.requestNeeded {
                            strongSelf.isRequest = true
                            strongSelf.isGroup = !invite.flags.isBroadcast
                            // Nicegram ATT, inviteHash added
                            strongSelf.controllerNode.setRequestPeer(inviteHash: strongSelf.link, image: invite.photoRepresentation, title: invite.title, about: invite.about, memberCount: invite.participantsCount, isGroup: !invite.flags.isBroadcast, isVerified: invite.flags.isVerified, isFake: invite.flags.isFake, isScam: invite.flags.isScam)
                        } else {
                            let data = JoinLinkPreviewData(isGroup: !invite.flags.isBroadcast, isJoined: false)
                            // Nicegram ATT, inviteHash added
                            strongSelf.controllerNode.setInvitePeer(inviteHash: strongSelf.link, image: invite.photoRepresentation, title: invite.title, about: invite.about, memberCount: invite.participantsCount, members: invite.participants?.map({ $0 }) ?? [], data: data)
                        }
                    case let .alreadyJoined(peer):
                        strongSelf.navigateToPeer(peer, nil)
                        strongSelf.dismiss()
                    case let .peek(peer, deadline):
                        strongSelf.navigateToPeer(peer, ChatPeekTimeout(deadline: deadline, linkData: strongSelf.link))
                        strongSelf.dismiss()
                    case .invalidHash:
                        let presentationData = strongSelf.context.sharedContext.currentPresentationData.with { $0 }
                        Queue.mainQueue().after(0.2) {
                            strongSelf.present(UndoOverlayController(presentationData: presentationData, content: .linkRevoked(text: presentationData.strings.InviteLinks_InviteLinkExpired), elevatedLayout: true, animateInAsReplacement: true, action: { _ in return false }), in: .window(.root))
                            strongSelf.dismiss()
                        }
                }
            }
        }, error: { [weak self] error in
            if let strongSelf = self {
                switch error {
                    case .flood:
                        strongSelf.present(textAlertController(context: strongSelf.context, title: nil, text: strongSelf.presentationData.strings.TwoStepAuth_FloodError, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.Common_OK, action: {})]), in: .window(.root))
                    default:
                        break
                }
                strongSelf.dismiss()
            }
        }))
        self.ready.set(self.controllerNode.ready.get())
    }
    
    override public func loadView() {
        super.loadView()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.animatedIn {
            self.animatedIn = true
            self.controllerNode.animateIn()
        }
    }
    
    override public func dismiss(completion: (() -> Void)? = nil) {
        self.controllerNode.animateOut(completion: completion)
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationLayout(layout: layout).navigationFrame.maxY, transition: transition)
    }
    
    private func join() {
        self.disposable.set((self.context.engine.peers.joinChatInteractively(with: self.link) |> deliverOnMainQueue).start(next: { [weak self] peer in
            if let strongSelf = self {
                // Nicegram ATT
                Task {
                    await AttCoreModule.shared.claimOngoingActionUseCase()
                        .claimSubscribeIfNeeded(
                            chatId: peer?.id.ng_toInt64(),
                            inviteHash: strongSelf.link
                        )
                }
                //
                
                if strongSelf.isRequest {
                    strongSelf.present(UndoOverlayController(presentationData: strongSelf.presentationData, content: .inviteRequestSent(title: strongSelf.presentationData.strings.MemberRequests_RequestToJoinSent, text: strongSelf.isGroup ? strongSelf.presentationData.strings.MemberRequests_RequestToJoinSentDescriptionGroup : strongSelf.presentationData.strings.MemberRequests_RequestToJoinSentDescriptionChannel ), elevatedLayout: true, animateInAsReplacement: false, action: { _ in return false }), in: .window(.root))
                } else {
                    if let peer = peer {
                        strongSelf.navigateToPeer(peer, nil)
                    }
                }
                strongSelf.dismiss()
            }
        }, error: { [weak self] error in
            if let strongSelf = self {
                switch error {
                    case .tooMuchJoined:
                        if let parentNavigationController = strongSelf.parentNavigationController {
                            let context = strongSelf.context
                            let link = strongSelf.link
                            let navigateToPeer = strongSelf.navigateToPeer
                            let resolvedState = strongSelf.resolvedState
                            parentNavigationController.pushViewController(oldChannelsController(context: strongSelf.context, intent: .join, completed: { [weak parentNavigationController] value in
                                if value {
                                    (parentNavigationController?.viewControllers.last as? ViewController)?.present(JoinLinkPreviewController(context: context, link: link, navigateToPeer: navigateToPeer, parentNavigationController: parentNavigationController, resolvedState: resolvedState), in: .window(.root))
                                }
                            }))
                        } else {
                            strongSelf.present(textAlertController(context: strongSelf.context, title: nil, text: strongSelf.presentationData.strings.Join_ChannelsTooMuch, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.Common_OK, action: {})]), in: .window(.root))
                        }
                    case .tooMuchUsers:
                        strongSelf.present(textAlertController(context: strongSelf.context, title: nil, text: strongSelf.presentationData.strings.Conversation_UsersTooMuchError, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.Common_OK, action: {})]), in: .window(.root))
                    case .requestSent:
                        if strongSelf.isRequest {
                            strongSelf.present(UndoOverlayController(presentationData: strongSelf.presentationData, content: .inviteRequestSent(title: strongSelf.presentationData.strings.MemberRequests_RequestToJoinSent, text: strongSelf.isGroup ? strongSelf.presentationData.strings.MemberRequests_RequestToJoinSentDescriptionGroup : strongSelf.presentationData.strings.MemberRequests_RequestToJoinSentDescriptionChannel ), elevatedLayout: true, animateInAsReplacement: false, action: { _ in return false }), in: .window(.root))
                        }
                    case .flood:
                        strongSelf.present(textAlertController(context: strongSelf.context, title: nil, text: strongSelf.presentationData.strings.TwoStepAuth_FloodError, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.Common_OK, action: {})]), in: .window(.root))
                    case .generic:
                        break
                }
                strongSelf.dismiss()
            }
        }))
    }
}

public func JoinLinkPreviewController(
    context: AccountContext,
    link: String,
    navigateToPeer: @escaping (EnginePeer, ChatPeekTimeout?) -> Void,
    parentNavigationController: NavigationController?,
    resolvedState: ExternalJoiningChatState? = nil
) -> ViewController {
    if let data = context.currentAppConfiguration.with({ $0 }).data, data["ios_killswitch_legacy_join_link"] != nil {
        return LegacyJoinLinkPreviewController(context: context, link: link, navigateToPeer: navigateToPeer, parentNavigationController: parentNavigationController, resolvedState: resolvedState)
    } else if case let .invite(invite) = resolvedState, !invite.flags.requestNeeded, !invite.flags.isBroadcast, !invite.flags.canRefulfillSubscription { 
        var verificationStatus: JoinSubjectScreenMode.Group.VerificationStatus?
        if invite.flags.isFake {
            verificationStatus = .fake
        } else if invite.flags.isScam {
            verificationStatus = .scam
        } else if invite.flags.isVerified {
            verificationStatus = .verified
        }
        return context.sharedContext.makeJoinSubjectScreen(context: context, mode: .group(JoinSubjectScreenMode.Group(
            link: link,
            isGroup: !invite.flags.isChannel,
            isPublic: invite.flags.isPublic,
            isRequest: invite.flags.requestNeeded,
            verificationStatus: verificationStatus,
            image: invite.photoRepresentation,
            title: invite.title,
            about: invite.about,
            memberCount: invite.participantsCount,
            members: invite.participants ?? []
        )))
    } else {
        return LegacyJoinLinkPreviewController(context: context, link: link, navigateToPeer: navigateToPeer, parentNavigationController: parentNavigationController, resolvedState: resolvedState)
    }
}
