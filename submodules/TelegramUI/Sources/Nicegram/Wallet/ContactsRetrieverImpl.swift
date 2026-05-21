import AccountContext
import MemberwiseInit
import NGUtils
import NicegramWallet
import TelegramCore

@MemberwiseInit
class ContactsRetrieverImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension ContactsRetrieverImpl: ContactsRetriever {
    func getContacts() async -> [WalletContact] {
        guard let context = contextProvider.context() else {
            return []
        }
        
        do {
            return try await context.engine.data
                .get(
                    TelegramEngine.EngineData.Item.Contacts.List(includePresences: false)
                )
                .awaitForFirstValue()
                .peers
                .filter {
                    $0.id != context.account.peerId
                }
                .map { WalletContact($0) }
                .filter { !$0.name.isEmpty }
        } catch {
            return []
        }
    }
}
