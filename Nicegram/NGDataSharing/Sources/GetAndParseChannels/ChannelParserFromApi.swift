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
        let channel = try apiChat.channel.unwrap()
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
        case let .resolvedPeer(resolvedPeer):
            return try resolvedPeer.chats.first.unwrap()
        }
    }
    
    func getFullChannel(
        _ channel: Api.Chat.Cons_channel
    ) async throws -> Api.ChatFull.Cons_channelFull {
        let result = try await context.account.network
            .request(
                Api.functions.channels.getFullChannel(
                    channel: .inputChannel(
                        .init(
                            channelId: channel.id,
                            accessHash: channel.accessHash ?? 0
                        )
                    )
                )
            )
            .awaitForFirstValue()
        
        switch result {
        case let .chatFull(chatFull):
            return try chatFull.fullChat.channelFull.unwrap()
        }
    }
    
    func getLastMessages(
        _ channel: Api.Chat.Cons_channel
    ) async throws -> [Message] {
        let config = getConfigUseCase()

        let result = try await context.account.network
            .request(
                Api.functions.messages.getHistory(
                    peer: .inputPeerChannel(
                        .init(
                            channelId: channel.id,
                            accessHash: channel.accessHash ?? 0
                        )
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
        case let .channelMessages(channelMessages):
            messages = channelMessages.messages
            chats = channelMessages.chats
            users = channelMessages.users
        case let .messages(_messages):
            messages = _messages.messages
            chats = _messages.chats
            users = _messages.users
        case let .messagesSlice(messagesSlice):
            messages = messagesSlice.messages
            chats = messagesSlice.chats
            users = messagesSlice.users
        default:
            return []
        }
        
        var resultMessages = [Message](messages: messages, chats: chats, users: users)
        resultMessages.reverse()
        return resultMessages
    }
    
    func getChatPhotoData(
        _ channel: Api.Chat.Cons_channel
    ) async throws -> Data {
        guard case let .chatPhoto(chatPhoto) = channel.photo else {
            throw UnexpectedError()
        }
        
        let url = try await ApiMediaFetcher(context: context)
            .fetch(
                datacenterId: Int(chatPhoto.dcId),
                location: .inputPeerPhotoFileLocation(
                    .init(
                        flags: chatPhoto.flags,
                        peer: .inputPeerChannel(
                            .init(
                                channelId: channel.id,
                                accessHash: channel.accessHash ?? 0
                            )
                        ),
                        photoId: chatPhoto.photoId
                    )
                )
            )
        defer {
            try? FileManager.default.removeItem(at: url)
        }
        return try Data(contentsOf: url)
    }
    
    func getSimilarChannels(
        _ channel: Api.Chat.Cons_channel
    ) async throws -> [Channel] {
        var flags: Int32 = 0
        flags |= (1 << 0)
        
        let result = try await context.account.network
            .request(
                Api.functions.channels.getChannelRecommendations(
                    flags: flags,
                    channel: .inputChannel(
                        .init(
                            channelId: channel.id,
                            accessHash: channel.accessHash ?? 0
                        )
                    )
                )
            )
            .awaitForFirstValue()
        
        let chats: [Api.Chat]
        switch result {
        case let .chats(_chats):
            chats = _chats.chats
        case let .chatsSlice(chatsSlice):
            chats = chatsSlice.chats
        }
        
        return chats.compactMap { apiChat in
            try? Channel.build(
                peer: peer(with: apiChat),
                participantsCount: apiChat.channel?.participantsCount
            )
        }
    }
}
