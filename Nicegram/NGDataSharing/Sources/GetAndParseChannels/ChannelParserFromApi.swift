import AccountContext
import FeatDataSharing
import MemberwiseInit
import NGCore
import TelegramApi
import TelegramCore

struct ChannelUnavailableError: Error {}

struct HistoryUnavailableError: Error {
    let cause: Error
}

struct NotAChannelError: Error {}

@MemberwiseInit
final class ChannelParserFromApi {
    @Init(.internal) private let context: AccountContext
}

extension ChannelParserFromApi {
    func parse(
        _ username: String,
        limits: HistoryLimits
    ) async throws -> Channel {
        let apiChat = try await resolveUsername(username)
        let channel = try apiChat.channel.unwrap()
        let peer = TelegramRawApi.peer(apiChat)
        let kind = try Channel.Kind((peer as? TelegramChannel).unwrap().info)

        let channelFull = try await fullChannel(channel)
        let messages = try await history(
            of: channel,
            limit: limits.messageLimit(for: kind)
        )
        let similarChannels = try await similarChannelsIfAvailable(of: channel)

        return try Channel.build(
            peer: peer,
            channelFull: .init(channelFull),
            inviteLinks: .init(channelFull.exportedInvite),
            messages: messages,
            participantsCount: channel.participantsCount,
            similarChannels: similarChannels
        )
    }
}

private extension ChannelParserFromApi {
    func send<Result>(_ function: TelegramRawApi.Function<Result>) async throws -> Result {
        try await sendChannelCollectorRequest(
            function,
            network: context.account.network
        )
    }

    /// Decided from `peer`, never from `chats`: `chats` also lists related chats, so a linked
    /// chat may come first and a channel that banned the account appears as `channelForbidden`.
    func resolveUsername(_ username: String) async throws -> Api.Chat {
        let result = try await send(
            Api.functions.contacts.resolveUsername(
                flags: 0,
                username: username,
                referer: nil
            )
        )

        switch result {
        case let .resolvedPeer(resolvedPeer):
            switch resolvedPeer.peer {
            case .peerUser:
                throw NotAChannelError()
            case .peerChat:
                throw ChannelUnavailableError()
            case let .peerChannel(peerChannel):
                return try resolvedPeer.chats
                    .first { $0.channel?.id == peerChannel.channelId }
                    .unwrap(orThrow: ChannelUnavailableError())
            }
        }
    }

    func fullChannel(_ channel: Api.Chat.Cons_channel) async throws -> Api.ChatFull.Cons_channelFull {
        let result = try await send(
            Api.functions.channels.getFullChannel(
                channel: .inputChannel(
                    .init(
                        channelId: channel.id,
                        accessHash: channel.accessHash ?? 0
                    )
                )
            )
        )

        switch result {
        case let .chatFull(chatFull):
            return try chatFull.fullChat.channelFull.unwrap()
        }
    }

    func lastMessages(
        _ channel: Api.Chat.Cons_channel,
        limit: Int
    ) async throws -> [FeatDataSharing.Message] {
        let result = try await send(
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
                limit: Int32(limit),
                maxId: 0,
                minId: 0,
                hash: 0
            )
        )

        let messages: [Api.Message]
        switch result {
        case let .channelMessages(channelMessages):
            messages = channelMessages.messages
        case let .messages(_messages):
            messages = _messages.messages
        case let .messagesSlice(messagesSlice):
            messages = messagesSlice.messages
        case .messagesNotModified:
            return []
        }

        return [FeatDataSharing.Message](messages: messages).reversed()
    }

    /// A flood wait or an unavailable account stops the job here as anywhere else; any other
    /// history failure skips the channel. The server keeps the first result per username per day,
    /// so neither a channel without posts nor an error item may be sent for it.
    func history(
        of channel: Api.Chat.Cons_channel,
        limit: Int
    ) async throws -> [FeatDataSharing.Message] {
        do {
            return try await lastMessages(channel, limit: limit)
        } catch let error as ChannelCollectorRpcError where stopsTheJob(error) {
            throw error
        } catch {
            throw HistoryUnavailableError(cause: error)
        }
    }

    /// Best-effort, except a flood wait or an unavailable account: the next channel would
    /// walk into the same wall, so those stop the job.
    func similarChannelsIfAvailable(of channel: Api.Chat.Cons_channel) async throws -> [Channel] {
        do {
            return try await requestChannelRecommendations(of: channel)
        } catch let error as ChannelCollectorRpcError where stopsTheJob(error) {
            throw error
        } catch {
            return []
        }
    }

    func stopsTheJob(_ error: ChannelCollectorRpcError) -> Bool {
        switch ChannelParseOutcome.fromRpcError(code: error.code, name: error.name) {
        case .accountUnavailable, .floodWait:
            true
        default:
            false
        }
    }

    func requestChannelRecommendations(of channel: Api.Chat.Cons_channel) async throws -> [Channel] {
        var flags: Int32 = 0
        flags |= (1 << 0)

        let result = try await send(
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
