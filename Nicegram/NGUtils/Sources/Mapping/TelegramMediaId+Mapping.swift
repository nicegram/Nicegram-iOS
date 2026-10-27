import TelegramBridge
import TelegramCore

public extension EngineMedia.Id {
    init(_ id: TelegramMediaId) {
        self.init(
            namespace: id.namespace,
            id: id.id
        )
    }
}

public extension TelegramMediaId {
    init(_ id: EngineMedia.Id) {
        self.init(
            namespace: id.namespace,
            id: id.id
        )
    }
}
