import AccountContext
import Factory
import FeatDataSharing
import Foundation
import NGCore
import NGUtils
import TelegramApi
import TelegramCore

class ChannelParserFromApi {
    let context: AccountContext

    @Injected(\DataSharingModule.getConfigUseCase)
    private var getConfigUseCase
    
    init(context: AccountContext) {
        self.context = context
    }
}

extension ChannelParserFromApi {
    func parse(
        _ username: String
    ) async throws -> Channel {
        let apiChat = try await resolveUsername(username)
        let channel = try apiChat.wrapped().channel.unwrap()
        let channelFull = try await getFullChannel(channel)
        
        let messages = (try? await getLastMessages(channel)) ?? []
        
        let icon = try? await getChatPhotoData(channel).base64EncodedString()
        
        let recommendedChannels = (try? await getSimilarChannels(channel)) ?? []
        
        return try Channel.build(
            peer: peer(with: apiChat),
            channelFull: .init(channelFull),
            icon: icon,
            inviteLinks: .init(channelFull.exportedInvite),
            messages: messages,
            participantsCount: channel.participantsCount,
            similarChannels: recommendedChannels
        )
    }
}

private extension ChannelParserFromApi {
    func resolveUsername(
        _ username: String
    ) async throws -> Api.Chat {
        let resolvedPeer = try await context.account.network
            .request(
                Api.functions.contacts.resolveUsername(
                    flags: 0,
                    username: username,
                    referer: nil
                )
            )
            .awaitForFirstValue()
        
        switch resolvedPeer {
        case let .resolvedPeer(_, chats, _):
            return try chats.first.unwrap()
        }
    }
    
    func getFullChannel(
        _ channel: ApiChatWrapped.Channel
    ) async throws -> ApiChatFullWrapped.ChannelFull {
        let result = try await context.account.network
            .request(
                Api.functions.channels.getFullChannel(
                    channel: .inputChannel(
                        channelId: channel.id,
                        accessHash: channel.accessHash ?? 0
                    )
                )
            )
            .awaitForFirstValue()
        
        switch result {
        case let .chatFull(fullChat, _, _):
            return try fullChat.wrapped().channelFull.unwrap()
        }
    }
    
    func getLastMessages(
        _ channel: ApiChatWrapped.Channel
    ) async throws -> [Message] {
        let config = getConfigUseCase()

        let result = try await context.account.network
            .request(
                Api.functions.messages.getHistory(
                    peer: .inputPeerChannel(
                        channelId: channel.id,
                        accessHash: channel.accessHash ?? 0
                    ),
                    offsetId: 0,
                    offsetDate: 0,
                    addOffset: 0,
                    limit: Int32(config.messagesFetchLimit),
                    maxId: 0,
                    minId: 0,
                    hash: 0
                )
            )
            .awaitForFirstValue()
        
        let messages: [Api.Message]
        let chats: [Api.Chat]
        let users: [Api.User]
        switch result {
        case let .channelMessages(_, _, _, _, _messages, _, _chats, _users):
            messages = _messages
            chats = _chats
            users = _users
        case let .messages(_messages, _, _chats, _users):
            messages = _messages
            chats = _chats
            users = _users
        case let .messagesSlice(_, _, _, _, _, _messages, _, _chats, _users):
            messages = _messages
            chats = _chats
            users = _users
        default:
            return []
        }
        
        var resultMessages = [Message](messages: messages, chats: chats, users: users)
        resultMessages.reverse()
        return resultMessages
    }
    
    func getChatPhotoData(
        _ channel: ApiChatWrapped.Channel
    ) async throws -> Data {
        guard case let .chatPhoto(flags, photoId, _, dcId) = channel.photo else {
            throw UnexpectedError()
        }
        
        let url = try await ApiMediaFetcher(context: context)
            .fetch(
                datacenterId: Int(dcId),
                location: .inputPeerPhotoFileLocation(
                    flags: flags,
                    peer: .inputPeerChannel(
                        channelId: channel.id,
                        accessHash: channel.accessHash ?? 0
                    ),
                    photoId: photoId
                )
            )
        defer {
            try? FileManager.default.removeItem(at: url)
        }
        return try Data(contentsOf: url)
    }
    
    func getSimilarChannels(
        _ channel: ApiChatWrapped.Channel
    ) async throws -> [Channel] {
        var flags: Int32 = 0
        flags |= (1 << 0)
        
        let result = try await context.account.network
            .request(
                Api.functions.channels.getChannelRecommendations(
                    flags: flags,
                    channel: .inputChannel(
                        channelId: channel.id,
                        accessHash: channel.accessHash ?? 0
                    )
                )
            )
            .awaitForFirstValue()
        
        let chats: [Api.Chat]
        switch result {
        case .chats(let _chats), .chatsSlice(_, let _chats):
            chats = _chats
        }
        
        return chats.compactMap { apiChat in
            try? Channel.build(
                peer: peer(with: apiChat),
                participantsCount: apiChat.wrapped().channel?.participantsCount
            )
        }
    }
}
