import CasePaths
import TelegramApi

@CasePathable
@dynamicMemberLookup
public enum ApiUserWrapped {
    case user(User)
    case userEmpty(Int64)

    public struct User {
        public let flags: Int32
        public let flags2: Int32
        public let id: Int64
        public let accessHash: Int64?
        public let firstName: String?
        public let lastName: String?
        public let username: String?
        public let phone: String?
        public let photo: Api.UserProfilePhoto?
        public let status: Api.UserStatus?
        public let botInfoVersion: Int32?
        public let restrictionReason: [Api.RestrictionReason]?
        public let botInlinePlaceholder: String?
        public let langCode: String?
        public let emojiStatus: Api.EmojiStatus?
        public let usernames: [Api.Username]?
        public let storiesMaxId: Api.RecentStory?
        public let color: Api.PeerColor?
        public let profileColor: Api.PeerColor?
        public let botActiveUsers: Int32?
        public let botVerificationIcon: Int64?
        public let sendPaidMessagesStars: Int64?
    }

    public init(_ apiUser: Api.User) {
        switch apiUser {
        case let .user(flags, flags2, id, accessHash, firstName, lastName, username, phone, photo, status, botInfoVersion, restrictionReason, botInlinePlaceholder, langCode, emojiStatus, usernames, storiesMaxId, color, profileColor, botActiveUsers, botVerificationIcon, sendPaidMessagesStars):
            self = .user(User(
                flags: flags,
                flags2: flags2,
                id: id,
                accessHash: accessHash,
                firstName: firstName,
                lastName: lastName,
                username: username,
                phone: phone,
                photo: photo,
                status: status,
                botInfoVersion: botInfoVersion,
                restrictionReason: restrictionReason,
                botInlinePlaceholder: botInlinePlaceholder,
                langCode: langCode,
                emojiStatus: emojiStatus,
                usernames: usernames,
                storiesMaxId: storiesMaxId,
                color: color,
                profileColor: profileColor,
                botActiveUsers: botActiveUsers,
                botVerificationIcon: botVerificationIcon,
                sendPaidMessagesStars: sendPaidMessagesStars
            ))
        case let .userEmpty(id):
            self = .userEmpty(id)
        }
    }
}

extension Api.User {
    func wrapped() -> ApiUserWrapped {
        .init(self)
    }
}
