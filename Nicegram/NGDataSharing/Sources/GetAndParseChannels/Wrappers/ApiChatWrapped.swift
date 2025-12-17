import CasePaths
import TelegramApi

@CasePathable
@dynamicMemberLookup
public enum ApiChatWrapped {
    case channel(Channel)
    case channelForbidden(ChannelForbidden)
    case chat(ChatInfo)
    case chatEmpty(ChatEmpty)
    case chatForbidden(ChatForbidden)

    public struct Channel {
        public let flags: Int32
        public let flags2: Int32
        public let id: Int64
        public let accessHash: Int64?
        public let title: String
        public let username: String?
        public let photo: Api.ChatPhoto
        public let date: Int32
        public let restrictionReason: [Api.RestrictionReason]?
        public let adminRights: Api.ChatAdminRights?
        public let bannedRights: Api.ChatBannedRights?
        public let defaultBannedRights: Api.ChatBannedRights?
        public let participantsCount: Int32?
        public let usernames: [Api.Username]?
        public let storiesMaxId: Api.RecentStory?
        public let color: Api.PeerColor?
        public let profileColor: Api.PeerColor?
        public let emojiStatus: Api.EmojiStatus?
        public let level: Int32?
        public let subscriptionUntilDate: Int32?
        public let botVerificationIcon: Int64?
        public let sendPaidMessagesStars: Int64?
        public let linkedMonoforumId: Int64?
    }

    public struct ChannelForbidden {
        public let flags: Int32
        public let id: Int64
        public let accessHash: Int64
        public let title: String
        public let untilDate: Int32?
    }

    public struct ChatInfo {
        public let flags: Int32
        public let id: Int64
        public let title: String
        public let photo: Api.ChatPhoto
        public let participantsCount: Int32
        public let date: Int32
        public let version: Int32
        public let migratedTo: Api.InputChannel?
        public let adminRights: Api.ChatAdminRights?
        public let defaultBannedRights: Api.ChatBannedRights?
    }

    public struct ChatEmpty {
        public let id: Int64
    }

    public struct ChatForbidden {
        public let id: Int64
        public let title: String
    }

    public init(_ apiChat: Api.Chat) {
        switch apiChat {
        case let .channel(flags, flags2, id, accessHash, title, username, photo, date, restrictionReason, adminRights, bannedRights, defaultBannedRights, participantsCount, usernames, storiesMaxId, color, profileColor, emojiStatus, level, subscriptionUntilDate, botVerificationIcon, sendPaidMessagesStars, linkedMonoforumId):
            self = .channel(Channel(flags: flags, flags2: flags2, id: id, accessHash: accessHash, title: title, username: username, photo: photo, date: date, restrictionReason: restrictionReason, adminRights: adminRights, bannedRights: bannedRights, defaultBannedRights: defaultBannedRights, participantsCount: participantsCount, usernames: usernames, storiesMaxId: storiesMaxId, color: color, profileColor: profileColor, emojiStatus: emojiStatus, level: level, subscriptionUntilDate: subscriptionUntilDate, botVerificationIcon: botVerificationIcon, sendPaidMessagesStars: sendPaidMessagesStars, linkedMonoforumId: linkedMonoforumId))
        case let .channelForbidden(flags, id, accessHash, title, untilDate):
            self = .channelForbidden(ChannelForbidden(flags: flags, id: id, accessHash: accessHash, title: title, untilDate: untilDate))
        case let .chat(flags, id, title, photo, participantsCount, date, version, migratedTo, adminRights, defaultBannedRights):
            self = .chat(ChatInfo(flags: flags, id: id, title: title, photo: photo, participantsCount: participantsCount, date: date, version: version, migratedTo: migratedTo, adminRights: adminRights, defaultBannedRights: defaultBannedRights))
        case let .chatEmpty(id):
            self = .chatEmpty(ChatEmpty(id: id))
        case let .chatForbidden(id, title):
            self = .chatForbidden(ChatForbidden(id: id, title: title))
        }
    }
}

extension Api.Chat {
    func wrapped() -> ApiChatWrapped {
        .init(self)
    }
}
