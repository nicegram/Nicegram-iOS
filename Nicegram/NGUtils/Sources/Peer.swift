import Postbox
import TelegramCore

public func extractPeerId(peer: Peer) -> Int64 {
    let enginePeer = EnginePeer(peer)
    
    let idText: String
    switch enginePeer {
    case .user, .legacyGroup, .secretChat:
        idText = "\(peer.id.id._internalGetInt64Value())"
    case .channel:
        idText = "-100\(peer.id.id._internalGetInt64Value())"
    }
    
    return Int64(idText) ?? peer.id.id._internalGetInt64Value()
}

public func getMembersCount(cachedPeerData: CachedPeerData?) -> Int? {
    guard let cachedPeerData else {
        return nil
    }
    
    switch cachedPeerData {
    case let channel as CachedChannelData:
        return channel.participantsSummary.memberCount.flatMap(Int.init)
    case let group as CachedGroupData:
        return group.participants?.participants.count
    default:
        return nil
    }
}
