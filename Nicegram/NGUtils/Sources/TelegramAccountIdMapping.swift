import TelegramBridge
import TelegramCore

public extension TelegramBridge.TelegramAccountId {
    init(_ id: AccountRecordId) {
        self.init(value: id.int64)
    }
}
