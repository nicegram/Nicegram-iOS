import Combine
import MemberwiseInit
import NGUtils
import TelegramBridge

@MemberwiseInit
class TelegramThemeProviderImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramThemeProviderImpl: TelegramThemeProvider {
    func currentTheme() -> AnyPublisher<TelegramTheme, Never> {
        contextProvider.contextPublisher()
            .compactMap { $0 }
            .map { accountContext in
                accountContext.sharedContext.presentationData
                    .toPublisher()
                    .map { TelegramTheme($0) }
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
