import AccountContext
import protocol Postbox.Peer
import struct Postbox.PeerId
import TelegramApi
import TelegramBridge
import TelegramCore

private struct TelegramPeerImpl: TelegramBridge.TelegramPeer {
    let displayName: String
    let id: TelegramId
    let username: String?
}

public extension Postbox.Peer {
    func toTelegramBridgePeer() -> TelegramBridge.TelegramPeer {
        TelegramPeerImpl(
            displayName: debugDisplayTitle,
            id: .init(id),
            username: addressName
        )
    }
}

public extension TelegramBridge.TelegramPeer {
    func toTelegramApiInputPeer(
        context: AccountContext
    ) async throws -> Api.InputPeer {
        let peer = try await toTelegramPeer(context: context)
        return try apiInputPeer(peer).unwrap()
    }
    
    func toTelegramPeer(
        context: AccountContext
    ) async throws -> Postbox.Peer {
        let peerId = PeerId(id)
        let peerView = try await context.account.postbox
            .peerView(id: peerId)
            .awaitForFirstValue()
        return try peerView.peers[peerId].unwrap()
    }
}
