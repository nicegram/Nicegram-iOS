import TelegramApi

extension Api.Chat {
    var channel: Cons_channel? {
        if case let .channel(channel) = self {
            channel
        } else {
            nil
        }
    }
}