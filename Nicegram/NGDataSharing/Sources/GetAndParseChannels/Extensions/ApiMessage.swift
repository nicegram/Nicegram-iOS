import TelegramApi

extension Api.Message {
    var message: Cons_message? {
        if case let .message(message) = self {
            message
        } else {
            nil
        }
    }
}