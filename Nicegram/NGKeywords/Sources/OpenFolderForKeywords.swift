import AccountContext
import AccountUtils
import Display
import FeatKeywords
import Foundation
import NGUI
import Postbox
import SwiftSignalKit
import TelegramCore
import TelegramStringFormatting
import UIKit

//  MARK: - Public

@available(iOS 15.0, *)
@MainActor
public func openFolderForKeywords(
    context: AccountContext,
    navigationController: NavigationController
) {
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let locale = localeWithStrings(presentationData.strings)
    let primaryColor = presentationData.theme.rootController.navigationBar.blurredBackgroundColor
    let secondaryColor = presentationData.theme.list.plainBackgroundColor
    let tertiaryColor = presentationData.theme.rootController.navigationSearchBar.inputFillColor
    let accentColor = presentationData.theme.list.itemAccentColor
    let overallDarkAppearance = presentationData.theme.overallDarkAppearance
    
    let keywordsController = KeywordsPresenter().makeController(
        with: context.account.peerId.toInt64(),
        theme: KeywordsPresenter.Theme(
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            tertiaryColor: tertiaryColor,
            accentColor: accentColor,
            overallDarkAppearance: overallDarkAppearance
        ),
        locale: locale,
        openMessage: { id, peerId in
            openMessage(
                context: context,
                navigationController: navigationController,
                id: id,
                peerId: peerId
            )
        },
        openSettings: {
            openSettings(
                context: context,
                navigationController: navigationController
            )
        }
    )
    
    let wrapper = NativeControllerWrapper(
        controller: keywordsController,
        accountContext: context
    )
    
    navigationController.pushViewController(wrapper, animated: true)
}

//  MARK: - Private

private func openSettings(
    context: AccountContext,
    navigationController: NavigationController
) {
    Task { @MainActor in
        let accountsAndPeers = try await activeAccountsAndPeers(context: context).awaitForFirstValue().1
        navigationController.pushViewController(
            nicegramSettingsController(
                context: context,
                accountsContexts: accountsAndPeers.map { ($0.0, $0.1) }
            )
        )
    }
}

private func openMessage(
    context: AccountContext,
    navigationController: NavigationController,
    id: Int32,
    peerId: Int64
) {
    Task {
        let peerId = PeerId(peerId)
        let messageId = MessageId(peerId: peerId, namespace: 0, id: id)
        
        let message = try? await context.engine.messages
            .getMessagesLoadIfNecessary([messageId])
            .toPublisher()
            .compactMap { result in
                if case let .result(messages) = result {
                    messages
                } else {
                    nil
                }
            }
            .awaitForFirstValue()
            .first
        
        let peer = try await context.engine.data.get(
            TelegramEngine.EngineData.Item.Peer.Peer(id: peerId)
        ).awaitForFirstValue().unwrap()
        
        let chatLocation: NavigateToChatControllerParams.Location
        if case let .channel(channel) = peer,
           channel.isForumOrMonoForum,
           let threadId = message?.threadId {
            chatLocation = .replyThread(
                .init(
                    peerId: peerId,
                    threadId: threadId,
                    channelMessageId: nil,
                    isChannelPost: false,
                    isForumPost: true,
                    isMonoforumPost: false,
                    maxMessage: nil,
                    maxReadIncomingMessageId: nil,
                    maxReadOutgoingMessageId: nil,
                    unreadCount: 0,
                    initialFilledHoles: IndexSet(),
                    initialAnchor: .automatic,
                    isNotAvailable: false
                )
            )
        } else {
            chatLocation = .peer(peer)
        }
        
        context.sharedContext.navigateToChatController(
            NavigateToChatControllerParams(
                navigationController: navigationController,
                context: context,
                chatLocation: chatLocation,
                subject: .message(
                    id: .id(messageId),
                    highlight: .init(),
                    timecode: nil,
                    setupReply: false
                )
            )
        )
    }
}
