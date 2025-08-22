import Postbox
import TelegramBridge

public extension MessageId {
    init(_ id: TelegramMessageId) {
        self.init(
            peerId: .init(id.peerId),
            namespace: id.namespace,
            id: id.id
        )
    }
}

public extension TelegramMessageId {
    init(_ id: MessageId) {
        self.init(
            peerId: .init(id.peerId),
            namespace: id.namespace,
            id: id.id
        )
    }
}
