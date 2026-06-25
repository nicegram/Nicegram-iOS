import AccountContext
import FeatAttentionEconomy
import Postbox
import TelegramCore

final class ChatNicegramAdsContext {
    let accountContext: AccountContext
    let headerAdViewModel: ChatHeaderAdViewModel
    
    init(accountContext: AccountContext) {
        self.accountContext = accountContext
        self.headerAdViewModel = ChatHeaderAdViewModel()
    }
}

extension ChatNicegramAdsContext: ChatStateObserver {
    func update(hasTelegramHeaderAd: Bool) {
        updateChatContext {
            $0.telegramAdsState.hasHeaderAd = hasTelegramHeaderAd
        }
    }
    
    func update(isScreenVisible: Bool) {
        headerAdViewModel.update(isHostVisible: isScreenVisible)
    }
    
    func update(peerView: PeerView?) {
        guard let peerView,
              let peer = peerView.peers[peerView.peerId] else {
            return
        }
        
        let participantsCount: Int
        let type: FeatAttentionEconomy.ChatContext.PeerType
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
        
        let isRestricted = peer.restrictionText(
            platform: "ios",
            contentSettings: accountContext.currentContentSettings.with { $0 }
        ) != nil
        
        let resolvedPeer = FeatAttentionEconomy.ChatContext.Peer(
            isRestricted: isRestricted,
            participantsCount: participantsCount,
            type: type,
            username: peer.addressName
        )
        
        updateChatContext {
            $0.peer = resolvedPeer
        }
    }
}

private extension ChatNicegramAdsContext {
    func updateChatContext(_ updater: (inout FeatAttentionEconomy.ChatContext) -> Void) {
        headerAdViewModel.updateChatContext(updater)
    }
}
