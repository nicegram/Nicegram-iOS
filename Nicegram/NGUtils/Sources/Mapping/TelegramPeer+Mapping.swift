import AccountContext
import TelegramApi
import TelegramBridge
import TelegramCore

public extension EngineRawPeer {
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

            let participationStatus: TelegramBridge.TelegramChannelParticipationStatus = switch channel.participationStatus {
            case .member: .member
            case .left: .left
            case .kicked: .kicked
            }
            
            return TelegramBridge.TelegramChannel(
                displayName: displayName,
                id: id,
                info: info,
                participationStatus: participationStatus,
                username: username
            )
        case let .community(community):
            // Upstream 12.9.2 added `EnginePeer.community`. `TelegramSealedPeer`
            // has no community case, and adding one is an assistant-side change,
            // so map it to the closest existing shape: a group-like channel. A
            // community is a CloudChannel-namespace peer with member/left
            // participation and group admin/banned rights.
            let participationStatus: TelegramBridge.TelegramChannelParticipationStatus = switch community.participationStatus {
            case .member: .member
            case .left: .left
            case .kicked: .kicked
            }

            return TelegramBridge.TelegramChannel(
                displayName: displayName,
                id: id,
                info: .group,
                participationStatus: participationStatus,
                username: username
            )
        case let .legacyGroup(group):
            let participationStatus: TelegramBridge.TelegramChannelParticipationStatus = switch group.membership {
            case .Member: .member
            case .Left: .left
            case .Removed: .kicked
            }
            
            return TelegramBridge.TelegramGroup(
                displayName: displayName,
                id: id,
                participationStatus: participationStatus,
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
                firstName: user.firstName,
                id: id,
                isPremium: user.flags.contains(.isPremium),
                lastName: user.lastName,
                phone: user.phone,
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
        return try TelegramRawApi.inputPeer(peer).unwrap()
    }
    
    func toTelegramPeer(
        context: AccountContext
    ) async throws -> EngineRawPeer {
        try await context.engine.data
            .get(TelegramEngine.EngineData.Item.Peer.Peer(id: EnginePeer.Id(id)))
            .awaitForFirstValue()
            .unwrap()
            ._asPeer()
    }
}
