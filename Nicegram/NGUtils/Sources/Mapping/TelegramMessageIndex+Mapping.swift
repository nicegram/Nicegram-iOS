import TelegramBridge
import TelegramCore

public extension EngineMessage.Index {
    init(_ index: TelegramBridge.TelegramMessageIndex) {
        self.init(
            id: .init(index.id),
            timestamp: Int32(index.timestamp)
        )
    }
}
