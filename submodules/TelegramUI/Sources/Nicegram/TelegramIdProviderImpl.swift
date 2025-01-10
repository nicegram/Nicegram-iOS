import MemberwiseInit
import NGUtils
import TelegramBridge

@MemberwiseInit
class TelegramIdProviderImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramIdProviderImpl: TelegramIdProvider {
    func getTelegramId() -> TelegramId? {
        guard let context = contextProvider.context() else {
            return nil
        }
        return TelegramId(context.account.peerId)
    }
}
