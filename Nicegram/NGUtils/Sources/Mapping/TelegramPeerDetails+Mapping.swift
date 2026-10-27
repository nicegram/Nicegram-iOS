import TelegramBridge
import TelegramCore

extension EngineRawPeer {
    func toTelegramBridgePeerDetails(
        cachedData: EngineCachedPeerData?
    ) -> any TelegramBridge.TelegramPeerDetails {
        let peer = toTelegramBridgePeer()
        
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
