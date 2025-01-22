import AccountContext
import NicegramWallet
import Postbox
import TelegramCore

public struct WalletTgUtils {}

public extension WalletTgUtils {
    static func peerById(
        _ id: PeerId,
        context: AccountContext
    ) async -> EnginePeer? {
        try? await context.engine.data
            .get(
                TelegramEngine.EngineData.Item.Peer.Peer(
                    id: id
                )
            )
            .awaitForFirstValue()
    }
    
    static func peerToWalletContact(
        peer: EnginePeer
    ) -> WalletContact {
        let username: String
        if let addressName = peer.addressName, !addressName.isEmpty {
            username = "@\(addressName)"
        } else {
            username = ""
        }
        
        return WalletContact(
            id: .init(peer.id),
            name: peer.compactDisplayTitle,
            username: username
        )
    }
    
    static func peerToWalletContact(
        id: PeerId,
        context: AccountContext
    ) async -> WalletContact? {
        if let peer = await peerById(id, context: context) {
            peerToWalletContact(peer: peer)
        } else {
            nil
        }
    }
}
