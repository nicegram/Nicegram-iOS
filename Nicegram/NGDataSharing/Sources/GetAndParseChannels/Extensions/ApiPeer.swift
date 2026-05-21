import TelegramApi

extension Api.Peer {
    var id: Int64 {
        switch self {
        case let .peerChannel(peerChannel): peerChannel.channelId
        case let .peerChat(peerChat): peerChat.chatId
        case let .peerUser(peerUser): peerUser.userId
        }
    }
}
