import Postbox
import TelegramCore

public extension PeerId {
    static var nicegramSupportBot: PeerId {
        .init(
            namespace: ._internalFromInt32Value(0),
            id: ._internalFromInt64Value(7381687765)
        )
    }
}
