import Foundation
import TelegramCore

public extension TelegramUser {
    /// User-facing name fallback used when `username` can be missing.
    ///
    /// Order:
    /// - `firstName`
    /// - `lastName`
    /// - `username`
    var displayedName: String? {
        if let firstName, !firstName.isEmpty {
            return firstName
        }
        if let lastName, !lastName.isEmpty {
            return lastName
        }
        if let username, !username.isEmpty {
            return username
        }
        return nil
    }
}

