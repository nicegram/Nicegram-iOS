import Postbox
import TelegramBridge

public extension TelegramBridge.TelegramId {
    init(_ peerId: PeerId) {
        self.init(
            namespace: peerId.namespace._internalGetInt32Value(),
            id: peerId.id._internalGetInt64Value()
        )
    }
}

public extension PeerId {
    init(_ id: TelegramBridge.TelegramId) {
        self.init(
            namespace: ._internalFromInt32Value(id.namespace),
            id: ._internalFromInt64Value(id.id)
        )
    }
}
