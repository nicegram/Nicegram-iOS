import Foundation
import UIKit
import Display
import AccountContext
import SwiftSignalKit
import Postbox
import TelegramCore

extension PeerInfoScreenNode {
    func openChatWithMessageSearch() {
        if let navigationController = (self.controller?.navigationController as? NavigationController) {
            if case let .replyThread(currentMessage) = self.chatLocation, let current = navigationController.viewControllers.first(where: { controller in
                if let controller = controller as? ChatController, case let .replyThread(message) = controller.chatLocation, message.peerId == currentMessage.peerId, message.threadId == currentMessage.threadId {
                    return true
                }
                return false
            }) as? ChatController {
                var viewControllers = navigationController.viewControllers
                if let index = viewControllers.firstIndex(of: current) {
                    viewControllers.removeSubrange(index + 1 ..< viewControllers.count)
                }
                navigationController.setViewControllers(viewControllers, animated: true)
                current.activateSearch(domain: .everything, query: "")
            } else if let peer = self.data?.chatPeer {
                self.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: self.context, chatLocation: .peer(peer), keepStack: .default, activateMessageSearch: (.everything, "")))
            }
        }
    }
    
    func openChatForReporting(title: String, option: Data, message: String?) {
        if let peer = self.data?.peer, let navigationController = (self.controller?.navigationController as? NavigationController) {
            if case let .channel(channel) = peer, channel.isForumOrMonoForum {
                //let _ = self.context.engine.peers.reportPeer(peerId: peer.id, reason: reason, message: "").startStandalone()
                //self.controller?.present(UndoOverlayController(presentationData: self.presentationData, content: .emoji(name: "PoliceCar", text: self.presentationData.strings.Report_Succeed), elevatedLayout: false, action: { _ in return false }), in: .current)
            } else {
                self.context.sharedContext.navigateToChatController(
                    NavigateToChatControllerParams(
                        navigationController: navigationController,
                        context: self.context,
                        chatLocation: .peer(peer),
                        keepStack: .default,
                        reportReason: NavigateToChatControllerParams.ReportReason(title: title, option: option, message: message)
                    )
                )
            }
        }
    }
    
    func openChatForThemeChange() {
        if let peer = self.data?.peer, let navigationController = (self.controller?.navigationController as? NavigationController) {
            self.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: self.context, chatLocation: .peer(peer), keepStack: .default, changeColors: true))
        }
    }

    func openChatForTranslation() {
        if let peer = self.data?.peer, let navigationController = (self.controller?.navigationController as? NavigationController) {
            self.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: self.context, chatLocation: .peer(peer), keepStack: .default, changeColors: false))
        }
    }

    func openChat(peerId: EnginePeer.Id?) {
        if let peerId {
            let _ = (self.context.engine.data.get(
                TelegramEngine.EngineData.Item.Peer.Peer(id: peerId)
            )
            |> deliverOnMainQueue).startStandalone(next: { [weak self] peer in
                guard let self, let peer else {
                    return
                }
                guard let navigationController = self.controller?.navigationController as? NavigationController else {
                    return
                }
                
                self.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: self.context, chatLocation: .peer(peer), keepStack: .always))
            })
            return
        }
        
        if let peer = self.data?.peer, let navigationController = self.controller?.navigationController as? NavigationController {
            self.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: self.context, chatLocation: .peer(peer), keepStack: .default))
        }
    }
    
    func openDeleteReaction(messageId: MessageId) {
        guard let authorPeer = self.data?.peer?._asPeer(), let navigationController = self.controller?.navigationController as? NavigationController else {
            return
        }

        let _ = (self.context.engine.data.get(
            TelegramEngine.EngineData.Item.Peer.Peer(id: messageId.peerId),
            TelegramEngine.EngineData.Item.Messages.Message(id: messageId)
        )
        |> deliverOnMainQueue).startStandalone(next: { [weak self] sourcePeer, sourceMessage in
            guard let self, let sourcePeer, let sourceMessage = sourceMessage?._asMessage() else {
                return
            }
            guard let channel = sourceMessage.peers[sourceMessage.id.peerId] as? TelegramChannel, channel.hasPermission(.deleteAllMessages) else {
                return
            }

            var hasReaction = false
            for attribute in sourceMessage.attributes {
                guard let attribute = attribute as? ReactionsMessageAttribute else {
                    continue
                }
                if attribute.recentPeers.contains(where: { $0.peerId == authorPeer.id }) || attribute.topPeers.contains(where: { $0.peerId == authorPeer.id }) {
                    hasReaction = true
                    break
                }
            }
            guard hasReaction else {
                return
            }

            let chatLocation: NavigateToChatControllerParams.Location
            if case let .channel(channel) = sourcePeer, channel.isForumOrMonoForum, let threadId = sourceMessage.threadId {
                chatLocation = .replyThread(ChatReplyThreadMessage(peerId: sourcePeer.id, threadId: threadId, channelMessageId: nil, isChannelPost: false, isForumPost: true, isMonoforumPost: channel.isMonoForum, maxMessage: nil, maxReadIncomingMessageId: nil, maxReadOutgoingMessageId: nil, unreadCount: 0, initialFilledHoles: IndexSet(), initialAnchor: .automatic, isNotAvailable: false))
            } else {
                chatLocation = .peer(sourcePeer)
            }

            self.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: self.context, chatLocation: chatLocation, subject: .message(id: .id(messageId), highlight: ChatControllerSubject.MessageHighlight(quote: nil), timecode: nil, setupReply: false), keepStack: .always, useExisting: true, completion: { chatController in
                chatController.presentReactionDeletionOptions(author: authorPeer, messageId: messageId)
            }))
        })
    }

    func openChatWithClearedHistory(type: InteractiveHistoryClearingType) {
        guard let peer = self.data?.chatPeer, let navigationController = self.controller?.navigationController as? NavigationController else {
            return
        }
        
        self.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: self.context, chatLocation: .peer(peer), keepStack: .default, setupController: { controller in
            controller.beginClearHistory(type: type)
        }))
    }

    func openChannelMessages() {
        guard case let .channel(channel) = self.data?.peer, let linkedMonoforumId = channel.linkedMonoforumId else {
            return
        }
        let _ = (self.context.engine.data.get(
            TelegramEngine.EngineData.Item.Peer.Peer(id: linkedMonoforumId)
        )
        |> deliverOnMainQueue).startStandalone(next: { [weak self] peer in
            guard let self, let peer else {
                return
            }
            if let controller = self.controller, let navigationController = controller.navigationController as? NavigationController {
                self.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: self.context, chatLocation: .peer(peer)))
            }
        })
    }

    func openRecentActions() {
        guard let peer = self.data?.peer else {
            return
        }
        let controller = self.context.sharedContext.makeChatRecentActionsController(context: self.context, peer: peer, adminPeerId: nil, starsState: self.data?.starsRevenueStatsState)
        self.controller?.push(controller)
    }
}
