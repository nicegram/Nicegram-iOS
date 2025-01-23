import Combine
import MemberwiseInit
import NGUtils
import TelegramBridge

@MemberwiseInit
class TelegramThemeProviderImpl {
    @Init(.internal) private let sharedContextProvider: SharedContextProvider
}

extension TelegramThemeProviderImpl: TelegramThemeProvider {
    func currentTheme() -> AnyPublisher<TelegramTheme, Never> {
        sharedContextProvider.sharedContextPublisher()
            .map { sharedContext in
                sharedContext.presentationData
                    .toPublisher()
                    .map { TelegramTheme($0) }
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
