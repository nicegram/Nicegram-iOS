import TelegramBridge
import TelegramCore

public extension TelegramBridge.TelegramId {
    init(_ peerId: EnginePeer.Id) {
        self.init(
            namespace: peerId.namespace._internalGetInt32Value(),
            id: peerId.id._internalGetInt64Value()
        )
    }
}

public extension EnginePeer.Id {
    init(_ id: TelegramBridge.TelegramId) {
        self.init(
            namespace: ._internalFromInt32Value(id.namespace),
            id: ._internalFromInt64Value(id.id)
        )
    }
}
