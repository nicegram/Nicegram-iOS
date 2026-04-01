import struct Postbox.MessageIndex
import TelegramBridge

public extension Postbox.MessageIndex {
    init(_ index: TelegramBridge.TelegramMessageIndex) {
        self.init(
            id: .init(index.id),
            timestamp: Int32(index.timestamp)
        )
    }
}
