import AccountContext
import FeatAccountBackup
import MemberwiseInit
import NGUtils
import TelegramCore

@MemberwiseInit
class AccountsRemoverImpl {
    @Init(.internal) private let sharedContextProvider: SharedContextProvider
}

extension AccountsRemoverImpl: AccountsRemover {
    func removeAccounts(accountIds: [Int64]) async throws {
        try await sharedContextProvider.sharedContext().accountManager
            .transaction { transaction in
                for accountId in accountIds {
                    let accountId = AccountRecordId(rawValue: accountId)
                    transaction.updateRecord(accountId) { record in
                        guard let record else { return nil }
                        
                        var attributes = record.attributes
                        attributes.appendLoggedOutAttributeIfNeeded()
                        attributes.updateNicegramAttribute {
                            $0.skipRemoteLogout = true
                        }
                        
                        return record.with(attributes: attributes)
                    }
                }
            }
            .awaitForFirstValue()
    }
}

private extension [TelegramAccountManagerTypes.Attribute] {
    mutating func appendLoggedOutAttributeIfNeeded() {
        let hasLoggedOutAttribute = self.contains {
            if case .loggedOut = $0 {
                true
            } else {
                false
            }
        }
        if !hasLoggedOutAttribute {
            self.append(.loggedOut(LoggedOutAccountAttribute()))
        }
    }
}
