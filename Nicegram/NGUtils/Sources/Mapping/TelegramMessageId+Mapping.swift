import TelegramBridge
import TelegramCore

public extension EngineMessage.Id {
    init(_ id: TelegramMessageId) {
        self.init(
            peerId: .init(id.peerId),
            namespace: id.namespace,
            id: id.id
        )
    }
}

public extension TelegramMessageId {
    init(_ id: EngineMessage.Id) {
        self.init(
            peerId: .init(id.peerId),
            namespace: id.namespace,
            id: id.id
        )
    }
}
