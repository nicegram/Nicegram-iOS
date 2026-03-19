import Foundation

public extension String {
    var replacingTelegramWithNicrgram: String {
        return self.replacingOccurrences(of: "Telegram", with: "Nicrgram")
    }
}
