import AccountContext
import NicegramWallet
import Postbox
import TelegramCore

public struct WalletTgUtils {}

public extension WalletTgUtils {
    static func contactIdToPeerId(_ id: WalletContactId) -> PeerId? {
        guard let int64Id = Int64(id.id) else {
            return nil
        }
        return PeerId(
            namespace: ._internalFromInt32Value(id.namespace),
            id: ._internalFromInt64Value(int64Id)
        )
    }
    
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
            id: WalletContactId(
                namespace: peer.id.namespace._internalGetInt32Value(),
                id: String(peer.id.id._internalGetInt64Value())
            ),
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
