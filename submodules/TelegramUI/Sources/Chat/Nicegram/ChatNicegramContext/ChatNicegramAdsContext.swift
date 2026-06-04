import FeatAdsgram
import Postbox
import TelegramCore

final class ChatNicegramAdsContext {
    let headerAdViewModel = ChatHeaderAdViewModel()
    let messageAdViewModel = ChatMessageAdViewModel()
}

extension ChatNicegramAdsContext: ChatStateObserver {
    func update(hasTelegramHeaderAd: Bool) {
        updatePlacementContext {
            $0.telegramAdsState.hasHeaderAd = hasTelegramHeaderAd
        }
    }
    
    func update(hasTelegramMessageAd: Bool) {
        updatePlacementContext {
            $0.telegramAdsState.hasLastMessageAd = hasTelegramMessageAd
        }
    }
    
    func update(isScreenVisible: Bool) {
        headerAdViewModel.updateVisibility {
            $0.isHostVisible = isScreenVisible
            $0.visibleFraction = 1
        }
        messageAdViewModel.updateVisibility {
            $0.isHostVisible = isScreenVisible
        }
    }
    
    func update(peerView: PeerView?) {
        guard let peerView,
              let peer = peerView.peers[peerView.peerId] else {
            return
        }
        
        let participantsCount: Int
        let type: FeatAdsgram.ChatContext.PeerType
        switch peer {
        case let user as TelegramUser:
            participantsCount = 2
            type = (user.botInfo == nil) ? .user : .bot
        case let channel as TelegramChannel:
            let cachedData = peerView.cachedData as? CachedChannelData
            
            participantsCount = cachedData?.participantsSummary.memberCount.flatMap(Int.init) ?? 0
            type = switch channel.info {
            case .broadcast: .channel
            case .group: .group
            }
        case _ as TelegramGroup:
            let cachedData = peerView.cachedData as? CachedGroupData
            
            participantsCount = cachedData?.participants?.participants.count ?? 0
            type = .group
        default:
            return
        }
        
        let resolvedPeer = FeatAdsgram.ChatContext.Peer(
            id: peer.id.ng_toInt64(),
            participantsCount: participantsCount,
            type: type,
            username: peer.addressName
        )
        
        updatePlacementContext {
            $0.peer = resolvedPeer
        }
    }
}

private extension ChatNicegramAdsContext {
    func updatePlacementContext(_ updater: (inout FeatAdsgram.ChatContext) -> Void) {
        headerAdViewModel.updatePlacementContext(updater)
        messageAdViewModel.updatePlacementContext(updater)
    }
}
