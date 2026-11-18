import Combine
import MemberwiseInit
import NGUtils
import TelegramBridge

@MemberwiseInit
final class TelegramIdProviderImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramIdProviderImpl: TelegramIdProvider {
    func telegramAccountId() -> TelegramAccountId? {
        guard let context = contextProvider.context() else {
            return nil
        }
        return TelegramAccountId(context.account.id)
    }

    func telegramAccountIdPublisher() -> AnyPublisher<TelegramAccountId?, Never> {
        contextProvider.contextPublisher()
            .map { context in
                context.map { TelegramAccountId($0.account.id) }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func telegramId() -> TelegramId? {
        guard let context = contextProvider.context() else {
            return nil
        }
        return TelegramId(context.account.peerId)
    }
}
