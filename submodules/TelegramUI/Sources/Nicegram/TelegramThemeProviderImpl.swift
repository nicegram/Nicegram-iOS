import Combine
import MemberwiseInit
import NGUtils
import SwiftSignalKit
import TelegramBridge

@MemberwiseInit
class TelegramThemeProviderImpl {
    @Init(.internal) private let sharedContextProvider: SharedContextProvider
}

extension TelegramThemeProviderImpl: TelegramThemeProvider {
    func get() async -> TelegramTheme {
        do {
            return try await publisher().awaitForFirstValue()
        } catch {
            return .defaultTheme
        }
    }
    
    func publisher() -> AnyPublisher<TelegramTheme, Never> {
        let presentationDataSignal = sharedContextProvider.sharedContextSignal()
        |> mapToSignal { $0.presentationData }

        return presentationDataSignal
            .toPublisher()
            .map { TelegramTheme($0) }
            .eraseToAnyPublisher()
    }
}
