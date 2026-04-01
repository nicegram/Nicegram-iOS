import class Postbox.PeerView
import TelegramBridge
import TelegramCore

public extension Postbox.PeerView {
    func toTelegramBridgePeerDetails() -> (any TelegramBridge.TelegramPeerDetails)? {
        guard let peer = peers[peerId]?.toTelegramBridgePeer() else {
            return nil
        }
        
        let about = cachedData?.aboutText ?? ""
        
        switch peer.sealed {
        case let .channel(channel):
            let cachedData = cachedData as? CachedChannelData
            return TelegramBridge.TelegramChannelDetails(
                peer: channel,
                about: about,
                participantsCount: cachedData?.participantsSummary.memberCount.flatMap(Int.init)
            )
        case let .group(group):
            let cachedData = cachedData as? CachedGroupData
            return TelegramBridge.TelegramGroupDetails(
                peer: group,
                about: about,
                participantsCount: cachedData?.participants?.participants.count
            )
        case let .secretChat(secretChat):
            return TelegramBridge.TelegramSecretChatDetails(
                peer: secretChat
            )
        case let .user(user):
            let cachedData = cachedData as? CachedUserData
            return TelegramBridge.TelegramUserDetails(
                peer: user,
                about: about,
                birthday: .init(cachedData?.birthday)
            )
        }
    }
}
