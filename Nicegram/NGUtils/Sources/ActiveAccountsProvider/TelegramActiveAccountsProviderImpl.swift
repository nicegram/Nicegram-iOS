import Combine
import MemberwiseInit
import NGCore
import SwiftSignalKit
import TelegramBridge
import TelegramCore

@MemberwiseInit(.public)
public final class TelegramActiveAccountsProviderImpl {
    @Init(.public) private let sharedContextProvider: SharedContextProvider
}

extension TelegramActiveAccountsProviderImpl: TelegramActiveAccountsProvider {
    public func loadedAccounts() async -> [TelegramActiveAccount] {
        // The publisher never completes: only a cancelled task gets nothing.
        (try? await loadedAccountsPublisher().awaitForFirstValue()) ?? []
    }

    public func loadedAccountsPublisher() -> AnyPublisher<[TelegramActiveAccount], Never> {
        let signal = sharedContextProvider.sharedContextSignal()
        |> mapToSignal { sharedContext in
            sharedContext.activeAccountsWithInfo
            |> map {
                $0.accounts.map { account in
                    TelegramActiveAccount(
                        peer: account.peer._asPeer().toTelegramBridgePeer()
                    )
                }
            }
        }
        
        return signal
            .toPublisher()
            .eraseToAnyPublisher()
    }

    public func signedInAccountIds() async -> Set<TelegramAccountId> {
        // The publisher never completes: only a cancelled task gets nothing, so a caller that acts
        // on an empty set checks for cancellation first.
        (try? await signedInAccountIdsPublisher().awaitForFirstValue()) ?? []
    }

    public func signedInAccountIdsPublisher() -> AnyPublisher<Set<TelegramAccountId>, Never> {
        let signal = sharedContextProvider.sharedContextSignal()
        |> mapToSignal { sharedContext in
            sharedContext.accountManager.accountRecords()
            |> map { view in
                Self.signedInAccountIds(
                    in: view.records,
                    temporarySessionId: sharedContext.accountManager.temporarySessionId
                )
            }
        }
        
        return signal
            .toPublisher()
            .eraseToAnyPublisher()
    }
}

private extension TelegramActiveAccountsProviderImpl {
    /// The same signed-in rule as `managedCleanupAccounts` (`AccountManager.swift`): a record is an
    /// account until it is marked logged out, and a record another launch left behind is not one.
    static func signedInAccountIds(
        in records: [AccountRecord<TelegramAccountManagerTypes.Attribute>],
        temporarySessionId: Int64
    ) -> Set<TelegramAccountId> {
        let signedIn = records.filter { record in
            let isLoggedOut = record.attributes.contains { $0.isLoggedOutAccountAttribute }
            let isOfThisLaunch = record.temporarySessionId == nil || record.temporarySessionId == temporarySessionId
            return !isLoggedOut && isOfThisLaunch
        }
        return Set(signedIn.map { TelegramAccountId($0.id) })
    }
}
