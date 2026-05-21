import CasePaths
import TelegramApi

extension Api.Peer {
    var id: Int64 {
        switch self {
        case let .peerChannel(channelId): channelId
        case let .peerChat(chatId): chatId
        case let .peerUser(userId): userId
        }
    }
}
