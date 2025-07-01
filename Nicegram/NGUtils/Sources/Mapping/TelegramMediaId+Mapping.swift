import Postbox
import TelegramBridge

public extension MediaId {
    init(_ id: TelegramMediaId) {
        self.init(
            namespace: id.namespace,
            id: id.id
        )
    }
}

public extension TelegramMediaId {
    init(_ id: MediaId) {
        self.init(
            namespace: id.namespace,
            id: id.id
        )
    }
}
