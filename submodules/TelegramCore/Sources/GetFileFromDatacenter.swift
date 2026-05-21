import Foundation
import TelegramApi
import Postbox

public func peer(with chat: Api.Chat?) -> Peer? {
    guard let chat else { return nil }
    
    return parseTelegramGroupOrChannel(chat: chat)
}
