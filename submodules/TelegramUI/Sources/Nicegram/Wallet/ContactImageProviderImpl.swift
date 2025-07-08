import AccountContext
import MemberwiseInit
import NGUtils
import NicegramWallet
import Postbox
import TelegramCore
import UIKit

@MemberwiseInit
class ContactImageProviderImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension ContactImageProviderImpl: ContactImageProvider {
    func image(for contact: WalletContact) async -> UIImage? {
        guard let context = contextProvider.context() else {
            return nil
        }
        
        let peerId = PeerId(contact.id)
        
        guard let peer = await WalletTgUtils.peerById(
            peerId,
            context: context
        ) else {
            return nil
        }
        
        let imageData = try? await MediaFetcher(context: context)
            .getAvatarImage(
                peer: peer._asPeer(),
                options: .init(
                    fetchIfMissing: true,
                    fetchTimeout: 10
                )
            )
        guard let imageData else { return nil }
        
        return UIImage(data: imageData)
    }
}
