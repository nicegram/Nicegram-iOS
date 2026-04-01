import TelegramBridge
import TelegramCore

public extension TelegramBridge.TelegramBirthday {
    init(_ birthday: TelegramCore.TelegramBirthday) {
        self.init(
            day: birthday.day,
            month: birthday.month,
            year: birthday.year
        )
    }
    
    init?(_ birthday: TelegramCore.TelegramBirthday?) {
        if let birthday {
            self.init(birthday)
        } else {
            return nil
        }
    }
}
