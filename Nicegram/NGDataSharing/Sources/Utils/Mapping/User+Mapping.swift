import FeatDataSharing
import Postbox
import TelegramCore

extension User {
    static func build(
        user: TelegramUser,
        botInfo: BotUserInfo,
        cachedData: CachedPeerData?,
        icon: String?,
        langCode: String?
    ) -> User {
        let cachedData = cachedData as? CachedUserData
        
        let botFlags = botInfo.flags
        let userFlags = user.flags
    
        let payload = UserPayload(
            deleted: user.isDeleted,
            bot: true,
            botChatHistory: botFlags.contains(.hasAccessToChatHistory),
            botNochats: !botFlags.contains(.worksWithGroups),
            verified: user.isVerified,
            restricted: user.restrictionInfo != nil,
            botInlineGeo: botFlags.contains(.requiresGeolocationForInlineRequests),
            support: userFlags.contains(.isSupport),
            scam: user.isScam,
            fake: user.isFake,
            botAttachMenu: botFlags.contains(.canBeAddedToAttachMenu),
            premium: user.isPremium,
            botCanEdit: botFlags.contains(.canEdit),
            firstName: user.firstName,
            lastName: user.lastName,
            username: user.username,
            phone: user.phone,
            photo: .init(user.profileImageRepresentations),
            restrictionReason: .init(user.restrictionInfo),
            botInlinePlaceholder: botInfo.inlinePlaceholder,
            langCode: langCode,
            usernames: user.usernames.map {
                .init(
                    editable: $0.flags.contains(.isEditable),
                    active: $0.isActive,
                    username: $0.username
                )
            },
            description: cachedData?.botInfo?.description
        )
        
        return User(
            id: user.id.ng_toInt64(),
            icon: icon,
            payload: payload
        )
    }
}
