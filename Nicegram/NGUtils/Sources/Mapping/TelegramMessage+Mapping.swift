import AccountContext
import TelegramApi
import TelegramBridge
import TelegramCore

public extension TelegramBridge.TelegramMessage {
    init(_ message: EngineRawMessage) {
        self.init(
            author: message.author?.toTelegramBridgePeer(),
            forwardInfo: message.forwardInfo.flatMap {
                .init(
                    author: $0.author?.toTelegramBridgePeer()
                )
            },
            id: .init(message.id),
            media: message.media.toTelegramBridgeMedia(),
            replyInfo: message.replyMessageAttribute.flatMap {
                .init(
                    messageId: .init($0.messageId)
                )
            },
            text: message.text,
            timestamp: Int(message.timestamp)
        )
    }
}

public extension [TelegramBridge.TelegramMessage] {
    init(_ messages: [EngineRawMessage]) {
        self = messages.map { .init($0) }
    }
    
    init(
        apiMessages: Api.messages.Messages,
        context: AccountContext
    ) {
        let messages = TelegramRawApi.messages(
            apiMessages,
            accountPeerId: context.account.peerId
        )
        self = messages.map { .init($0) }
    }
}
