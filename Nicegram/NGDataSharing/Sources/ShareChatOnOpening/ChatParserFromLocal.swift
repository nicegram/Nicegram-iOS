import AccountContext
import Factory
import FeatDataSharing
import Foundation
import NGCore
import NGUtils
import Postbox
import SwiftSignalKit
import TelegramCore

class ChatParserFromLocal {
    let context: AccountContext

    @Injected(\DataSharingModule.getConfigUseCase)
    private var getConfigUseCase
    
    init(context: AccountContext) {
        self.context = context
    }
}

extension ChatParserFromLocal {
    func parse(id: PeerId) async throws -> ShareChatOnOpeningUseCase.Peer {
        let peerView = try await getPeerView(id)
        let peer = try peerView.peers[id].unwrap()
        let cachedData = try peerView.cachedData.unwrap()
        
        switch peer {
        case let user as TelegramUser:
            return try await .user(
                getUser(
                    user: user,
                    cachedData: cachedData
                )
            )
        case let channel as TelegramChannel:
            return try await .channel(
                getChannel(
                    channel: channel,
                    cachedData: cachedData
                )
            )
        default:
            throw UnexpectedError()
        }
    }
}

//  MARK: - Channel

private extension ChatParserFromLocal {
    func getChannel(
        channel: TelegramChannel,
        cachedData: CachedPeerData?
    ) async throws -> Channel {
        let cachedData = cachedData as? CachedChannelData
        
        async let icon = getIcon(channel)
        async let inviteLinks = getInviteLinks(channel.id)
        async let messages = getMessages(channel.id)
        async let similarChannels = getSimilarChannels(channel.id)
        
        return try await Channel.build(
            peer: channel,
            channelFull: .init(cachedData),
            icon: icon,
            inviteLinks: inviteLinks,
            messages: messages,
            similarChannels: similarChannels
        )
    }
    
    func getInviteLinks(_ id: PeerId) async -> [InviteLink] {
        do {
            let signal = context.engine.peers.direct_peerExportedInvitations(
                peerId: id,
                revoked: false
            )
            |> timeout(
                10,
                queue: Queue.concurrentDefaultQueue(),
                alternate: .single(nil)
            )
            let result = try await signal
                .awaitForFirstValue()
                .unwrap()
            return try .init(result.list.unwrap())
        } catch {
            return []
        }
    }
    
    func getSimilarChannels(_ id: PeerId) async -> [Channel] {
        do {
            try? await context.engine.peers.requestRecommendedChannels(peerId: id)
                .awaitForCompletion()
            
            let result = try await context.engine.peers
                .recommendedChannels(peerId: id)
                .awaitForFirstValue()
                .unwrap()
            return result.channels.compactMap { channel in
                try? Channel.build(
                    peer: channel.peer._asPeer(),
                    participantsCount: channel.subscribers
                )
            }
        } catch {
            return []
        }
    }
}

//  MARK: - Bot

private extension ChatParserFromLocal {
    func getUser(
        user: TelegramUser,
        cachedData: CachedPeerData?
    ) async throws -> User {
        let botInfo = try user.botInfo.unwrap()
        
        let messages = await getMessages(user.id)
        let langCode = getLanguageCode(messages: messages)
        
        return await User.build(
            user: user,
            botInfo: botInfo,
            cachedData: cachedData,
            icon: getIcon(user),
            langCode: langCode
        )
    }
}

//  MARK: - General

private extension ChatParserFromLocal {
    func getPeerView(_ id: PeerId) async throws -> PeerView {
        try await context.account.viewTracker
            .peerView(id, updateData: true)
            .awaitForFirstValue()
    }
    
    func getMessages(_ id: PeerId) async -> [FeatDataSharing.Message] {
        do {
            let config = getConfigUseCase()

            let result = try await context.account.viewTracker
                .aroundMessageHistoryViewForLocation(
                    .peer(
                        peerId: id,
                        threadId: nil
                    ),
                    index: .upperBound,
                    anchorIndex: .upperBound,
                    count: config.messagesFetchLimit,
                    fixedCombinedReadStates: nil
                )
                .toPublisher()
                .filter {
                    let view = $0.0
                    let isLoading = view.isLoading || view.isLoadingEarlier
                    return !isLoading
                }
                .awaitForFirstValue()
            
            let messages = result.0.entries.map(\.message)
            return messages.map { .init($0) }
        } catch {
            return []
        }
    }
    
    func getIcon(_ peer: Peer) async -> String? {
        try? await MediaFetcher(context: context)
            .getAvatarImage(
                peer: peer,
                options: .init(
                    fetchIfMissing: true,
                    fetchTimeout: 10
                )
            )
            .base64EncodedString()
    }
}
