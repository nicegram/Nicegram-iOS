import AccountContext
import NGUtils
import NicegramWallet
import Postbox
import TelegramCore
import UIKit

struct ContactImageProviderImpl {
    static func image(
        context: AccountContext,
        contact: WalletContact
    ) async -> UIImage? {
        guard let peerId = WalletTgUtils.contactIdToPeerId(contact.id) else {
            return nil
        }
        
        guard let peer = await WalletTgUtils.peerById(
            peerId,
            context: context
        ) else {
            return nil
        }
        
        let imageData = try? await fetchAvatarImage(
            peer: peer._asPeer(),
            context: context
        ).awaitForFirstValue()
        guard let imageData else { return nil }
        
        return UIImage(data: imageData)
    }
}
