import AccountContext
import protocol Postbox.Peer
import struct Postbox.PeerId
import TelegramApi
import TelegramBridge
import TelegramCore

public extension Postbox.Peer {
    func toTelegramBridgePeer() -> TelegramBridge.TelegramPeer {
        let displayName = debugDisplayTitle
        let id = TelegramBridge.TelegramId(id)
        let username = addressName
        
        switch EnginePeer(self) {
        case let .channel(channel):
            let info: TelegramBridge.TelegramChannelInfo = switch channel.info {
            case .broadcast: .broadcast
            case .group: .group
            }
            
            return TelegramBridge.TelegramChannel(
                displayName: displayName,
                id: id,
                info: info,
                username: username
            )
        case .legacyGroup:
            return TelegramBridge.TelegramGroup(
                displayName: displayName,
                id: id,
                username: username
            )
        case .secretChat:
            return TelegramBridge.TelegramSecretChat(
                id: id
            )
        case let .user(user):
            return TelegramBridge.TelegramUser(
                botInfo: user.botInfo.flatMap { _ in .init() },
                displayName: displayName,
                id: id,
                isPremium: user.flags.contains(.isPremium),
                username: username
            )
        }
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
