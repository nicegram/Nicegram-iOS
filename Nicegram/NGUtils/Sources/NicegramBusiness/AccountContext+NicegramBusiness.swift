import AccountContext
import FeatNicegramBusiness
import TelegramBridge

public extension AccountContext {
    var nicegramBusiness: NicegramBusiness {
        NicegramBusiness(telegramAccountId: TelegramAccountId(account.id))
    }
}
