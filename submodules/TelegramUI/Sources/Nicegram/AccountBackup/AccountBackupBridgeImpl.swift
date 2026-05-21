import FeatAccountBackup
import MemberwiseInit
import NGUtils

@MemberwiseInit
class AccountBackupBridgeImpl {
    @Init(.internal) private let sharedContextProvider: SharedContextProvider
}

extension AccountBackupBridgeImpl: AccountBackupBridge {
    func accountsImporter() -> AccountsImporter {
        AccountsImporterImpl(sharedContextProvider: sharedContextProvider)
    }
    
    func accountsRemover() -> AccountsRemover {
        AccountsRemoverImpl(sharedContextProvider: sharedContextProvider)
    }
    
    func activeAccountsProvider() -> ActiveAccountsProvider {
        ActiveAccountsProviderImpl(sharedContextProvider: sharedContextProvider)
    }
}
