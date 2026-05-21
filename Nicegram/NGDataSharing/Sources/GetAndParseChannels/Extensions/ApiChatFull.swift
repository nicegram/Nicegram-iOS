import TelegramApi

extension Api.ChatFull {
    var channelFull: Cons_channelFull? {
        if case let .channelFull(channelFull) = self {
            channelFull
        } else {
            nil
        }
    }
}