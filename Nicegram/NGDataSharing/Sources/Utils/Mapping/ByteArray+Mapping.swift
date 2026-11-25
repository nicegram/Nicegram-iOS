import FeatDataSharing
import TelegramApi

extension Buffer {
    func toByteArray() -> ByteArray {
        ByteArray(makeData())
    }
}
