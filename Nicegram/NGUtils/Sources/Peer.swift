import Postbox
import TelegramCore

private let namespacePrefixes = [
    (Namespaces.Peer.CloudChannel, "-100"),
    (Namespaces.Peer.CloudGroup, "-"),
]

public extension PeerId {
    static func ng_fromInt64(_ id: Int64) -> PeerId {
        let stringId = String(id)
        for (namespace, prefix) in namespacePrefixes {
            if stringId.hasPrefix(prefix) {
                let id = Int64(stringId.removing(prefix: prefix)) ?? id
                return PeerId(
                    namespace: namespace,
                    id: ._internalFromInt64Value(id)
                )
            }
        }
        
        return PeerId(
            namespace: Namespaces.Peer.CloudUser,
            id: ._internalFromInt64Value(id)
        )
    }
    
    func ng_toInt64() -> Int64 {
        let id = id._internalGetInt64Value()
        
        let prefix = namespacePrefixes.first { $0.0 == namespace }?.1
        if let prefix {
            let stringId = "\(prefix)\(id)"
            return Int64(stringId) ?? id
        } else {
            return id
        }
    }
    
    func ng_toInt64Text() -> String {
        String(ng_toInt64())
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
