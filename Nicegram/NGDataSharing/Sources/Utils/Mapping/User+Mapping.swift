import FeatDataSharing
import TelegramCore

extension User {
    static func build(
        user: TelegramUser,
        botInfo: BotUserInfo,
        botInfoDetails: BotInfo?,
        langCode: String?
    ) -> User {
        let botFlags = botInfo.flags
        let userFlags = user.flags
    
        let payload = UserPayload(
            bot: true,
            botAttachMenu: botFlags.contains(.canBeAddedToAttachMenu),
            botCanEdit: botFlags.contains(.canEdit),
            botChatHistory: botFlags.contains(.hasAccessToChatHistory),
            botInlineGeo: botFlags.contains(.requiresGeolocationForInlineRequests),
            botInlinePlaceholder: botInfo.inlinePlaceholder,
            botNochats: !botFlags.contains(.worksWithGroups),
            deleted: user.isDeleted,
            description: botInfoDetails?.description,
            fake: user.isFake,
            firstName: user.firstName,
            langCode: langCode,
            lastName: user.lastName,
            phone: user.phone,
            premium: user.isPremium,
            restricted: user.restrictionInfo != nil,
            restrictionReason: .init(user.restrictionInfo),
            scam: user.isScam,
            subscriberCount: user.subscriberCount,
            support: userFlags.contains(.isSupport),
            username: user.username,
            usernames: user.usernames.map {
                .init(
                    active: $0.isActive,
                    editable: $0.flags.contains(.isEditable),
                    username: $0.username
                )
            },
            verified: user.isVerified
        )
        
        return User(
            id: user.id.ng_toInt64(),
            payload: payload
        )
    }
}
