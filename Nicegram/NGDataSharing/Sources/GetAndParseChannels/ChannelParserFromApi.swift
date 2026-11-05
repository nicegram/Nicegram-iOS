import AccountContext
import Factory
import FeatDataSharing
import NGCore
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
        
        let recommendedChannels = (try? await getSimilarChannels(channel)) ?? []
        
        return try Channel.build(
            peer: TelegramRawApi.peer(apiChat),
            channelFull: .init(channelFull),
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
        let resolvedPeer = try await TelegramRawApi
            .request(
                Api.functions.contacts.resolveUsername(
                    flags: 0,
                    username: username,
                    referer: nil
                ),
                network: context.account.network
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
        let result = try await TelegramRawApi
            .request(
                Api.functions.channels.getFullChannel(
                    channel: .inputChannel(
                        .init(
                            channelId: channel.id,
                            accessHash: channel.accessHash ?? 0
                        )
                    )
                ),
                network: context.account.network
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

        let result = try await TelegramRawApi
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
                ),
                network: context.account.network
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
    
    func getSimilarChannels(
        _ channel: Api.Chat.Cons_channel
    ) async throws -> [Channel] {
        var flags: Int32 = 0
        flags |= (1 << 0)
        
        let result = try await TelegramRawApi
            .request(
                Api.functions.channels.getChannelRecommendations(
                    flags: flags,
                    channel: .inputChannel(
                        .init(
                            channelId: channel.id,
                            accessHash: channel.accessHash ?? 0
                        )
                    )
                ),
                network: context.account.network
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
                peer: TelegramRawApi.peer(apiChat),
                participantsCount: apiChat.channel?.participantsCount
            )
        }
    }
}
