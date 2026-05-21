import Combine
import MemberwiseInit
import SwiftSignalKit
import TelegramBridge

@MemberwiseInit(.public)
public final class TelegramActiveAccountsProviderImpl {
    @Init(.public) private let sharedContextProvider: SharedContextProvider
}

extension TelegramActiveAccountsProviderImpl: TelegramActiveAccountsProvider {
    public func publisher() -> AnyPublisher<[TelegramActiveAccount], Never> {
        let signal = sharedContextProvider.sharedContextSignal()
        |> mapToSignal { sharedContext in
            sharedContext.activeAccountsWithInfo
            |> map {
                $0.accounts.map { account in
                    TelegramActiveAccount(telegramId: .init(account.peer.id))
                }
            }
        }
        
        return signal
            .toPublisher()
            .eraseToAnyPublisher()
    }
}
