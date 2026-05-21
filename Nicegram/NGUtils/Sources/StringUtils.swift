import Foundation

public extension String {
    var replacingTelegramWithNicegram: String {
        return self.replacingOccurrences(of: "Telegram", with: "Nicegram")
    }
}
