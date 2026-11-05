import TelegramCore

public extension EnginePeer.Id {
    static var nicegramSupportBot: EnginePeer.Id {
        .init(
            namespace: ._internalFromInt32Value(0),
            id: ._internalFromInt64Value(7381687765)
        )
    }
}
