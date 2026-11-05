import MtProtoKit
import Postbox
import SwiftSignalKit
public import TelegramApi

// The only way Nicegram code outside TelegramCore reaches the Telegram API: since 13.1.1
// TelegramApi is visible to TelegramCore alone and the helpers called below are internal there.
// Requests go out as is: nothing is written to Postbox and Api.Updates in a response are not
// applied; a FLOOD_WAIT is waited out and the request retried.
// Never name a member after the internal function it calls: the call resolves to the member
// itself and recurses.
public enum TelegramRawApi {
    public typealias Function<Result> = (FunctionDescription, Buffer, DeserializeFunctionResponse<Result>)
}

// MARK: - Transport

public extension TelegramRawApi {
    static func addUpdateSink(
        _ sink: NetworkEngineUpdateSink,
        network: Network
    ) {
        network.addUpdateSink(sink)
    }

    static func request<Result>(
        _ function: Function<Result>,
        network: Network
    ) -> Signal<Result, MTRpcError> {
        network.request(function)
    }
}

// MARK: - TelegramCore models -> Api

public extension TelegramRawApi {
    static func inputPeer(_ peer: Peer) -> Api.InputPeer? {
        apiInputPeer(peer)
    }
}

// MARK: - Api -> TelegramCore models

public extension TelegramRawApi {
    static func botInfo(_ botInfo: Api.BotInfo) -> BotInfo {
        BotInfo(apiBotInfo: botInfo)
    }

    static func exportedInvitation(_ invite: Api.ExportedChatInvite) -> ExportedInvitation {
        ExportedInvitation(apiExportedInvite: invite)
    }

    static func geoLocation(_ location: Api.ChannelLocation) -> PeerGeoLocation? {
        PeerGeoLocation(apiLocation: location)
    }

    static func media(_ media: Api.MessageMedia?) -> Media? {
        textMediaAndExpirationTimerFromApiMedia(
            media,
            .init(
                namespace: Namespaces.Peer.CloudChannel,
                id: ._internalFromInt64Value(0)
            )
        ).media
    }

    static func messages(
        _ messages: Api.messages.Messages,
        accountPeerId: PeerId
    ) -> [Message] {
        let apiMessages: [Api.Message]
        let chats: [Api.Chat]
        let users: [Api.User]
        switch messages {
        case let .channelMessages(channelMessages):
            apiMessages = channelMessages.messages
            chats = channelMessages.chats
            users = channelMessages.users
        case let .messages(_messages):
            apiMessages = _messages.messages
            chats = _messages.chats
            users = _messages.users
        case let .messagesSlice(messagesSlice):
            apiMessages = messagesSlice.messages
            chats = messagesSlice.chats
            users = messagesSlice.users
        case .messagesNotModified:
            apiMessages = []
            chats = []
            users = []
        }

        let peers = AccumulatedPeers(
            chats: chats,
            users: users
        )

        return apiMessages.compactMap { message in
            let peer = message.peerId.flatMap { peers.get($0) }

            let storeMessage = StoreMessage(
                apiMessage: message,
                accountPeerId: accountPeerId,
                peerIsForum: peer?.isForumOrMonoForum ?? false
            )
            guard let storeMessage else { return nil }

            return locallyRenderedMessage(
                message: storeMessage,
                peers: peers
            )
        }
    }

    static func peer(_ chat: Api.Chat) -> Peer? {
        parseTelegramGroupOrChannel(chat: chat)
    }

    static func peerId(_ peer: Api.Peer) -> PeerId {
        peer.peerId
    }

    static func peerId(_ user: Api.User) -> PeerId {
        user.peerId
    }

    static func reactions(_ reactions: Api.MessageReactions) -> ReactionsMessageAttribute {
        ReactionsMessageAttribute(apiReactions: reactions)
    }

    static func user(_ user: Api.User) -> TelegramUser {
        TelegramUser(user: user)
    }

    static func username(_ username: Api.Username) -> TelegramPeerUsername {
        TelegramPeerUsername(apiUsername: username)
    }
}
