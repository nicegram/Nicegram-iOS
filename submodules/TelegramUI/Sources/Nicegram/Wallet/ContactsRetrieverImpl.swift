import AccountContext
import NGUtils
import NicegramWallet
import TelegramCore

struct ContactsRetrieverImpl {
    static func getContacts(
        context: AccountContext
    ) async -> [WalletContact] {
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
                .map { peer in
                    WalletTgUtils.peerToWalletContact(
                        peer: peer
                    )
                }
                .filter { !$0.name.isEmpty }
        } catch {
            return []
        }
    }
}
