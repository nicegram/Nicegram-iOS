import Postbox
import TelegramCore

public extension PeerId {
    func ng_toInt64() -> Int64 {
        let originalId = id._internalGetInt64Value()
        
        var stringId = "\(originalId)"
        if namespace == Namespaces.Peer.CloudChannel {
            stringId = "-100\(stringId)"
        }
        
        return Int64(stringId) ?? originalId
    }
}

public func extractPeerId(peer: Peer) -> Int64 {
    peer.id.ng_toInt64()
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
