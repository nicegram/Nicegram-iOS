import CasePaths
import TelegramApi

@CasePathable
@dynamicMemberLookup
public enum ApiChatFullWrapped {
    case channelFull(ChannelFull)
    case chatFull(ChatFull)

    public struct ChannelFull {
        public let flags: Int32
        public let flags2: Int32
        public let id: Int64
        public let about: String
        public let participantsCount: Int32?
        public let adminsCount: Int32?
        public let kickedCount: Int32?
        public let bannedCount: Int32?
        public let onlineCount: Int32?
        public let readInboxMaxId: Int32
        public let readOutboxMaxId: Int32
        public let unreadCount: Int32
        public let chatPhoto: Api.Photo
        public let notifySettings: Api.PeerNotifySettings
        public let exportedInvite: Api.ExportedChatInvite?
        public let botInfo: [Api.BotInfo]
        public let migratedFromChatId: Int64?
        public let migratedFromMaxId: Int32?
        public let pinnedMsgId: Int32?
        public let stickerset: Api.StickerSet?
        public let availableMinId: Int32?
        public let folderId: Int32?
        public let linkedChatId: Int64?
        public let location: Api.ChannelLocation?
        public let slowmodeSeconds: Int32?
        public let slowmodeNextSendDate: Int32?
        public let statsDc: Int32?
        public let pts: Int32
        public let call: Api.InputGroupCall?
        public let ttlPeriod: Int32?
        public let pendingSuggestions: [String]?
        public let groupcallDefaultJoinAs: Api.Peer?
        public let themeEmoticon: String?
        public let requestsPending: Int32?
        public let recentRequesters: [Int64]?
        public let defaultSendAs: Api.Peer?
        public let availableReactions: Api.ChatReactions?
        public let reactionsLimit: Int32?
        public let stories: Api.PeerStories?
        public let wallpaper: Api.WallPaper?
        public let boostsApplied: Int32?
        public let boostsUnrestrict: Int32?
        public let emojiset: Api.StickerSet?
        public let botVerification: Api.BotVerification?
        public let stargiftsCount: Int32?
        public let sendPaidMessagesStars: Int64?
        public let mainTab: Api.ProfileTab?
    }

    public struct ChatFull {
        public let flags: Int32
        public let id: Int64
        public let about: String
        public let participants: Api.ChatParticipants
        public let chatPhoto: Api.Photo?
        public let notifySettings: Api.PeerNotifySettings
        public let exportedInvite: Api.ExportedChatInvite?
        public let botInfo: [Api.BotInfo]?
        public let pinnedMsgId: Int32?
        public let folderId: Int32?
        public let call: Api.InputGroupCall?
        public let ttlPeriod: Int32?
        public let groupcallDefaultJoinAs: Api.Peer?
        public let themeEmoticon: String?
        public let requestsPending: Int32?
        public let recentRequesters: [Int64]?
        public let availableReactions: Api.ChatReactions?
        public let reactionsLimit: Int32?
    }

    public init(_ apiChatFull: Api.ChatFull) {
        switch apiChatFull {
        case let .channelFull(flags, flags2, id, about, participantsCount, adminsCount, kickedCount, bannedCount, onlineCount, readInboxMaxId, readOutboxMaxId, unreadCount, chatPhoto, notifySettings, exportedInvite, botInfo, migratedFromChatId, migratedFromMaxId, pinnedMsgId, stickerset, availableMinId, folderId, linkedChatId, location, slowmodeSeconds, slowmodeNextSendDate, statsDc, pts, call, ttlPeriod, pendingSuggestions, groupcallDefaultJoinAs, themeEmoticon, requestsPending, recentRequesters, defaultSendAs, availableReactions, reactionsLimit, stories, wallpaper, boostsApplied, boostsUnrestrict, emojiset, botVerification, stargiftsCount, sendPaidMessagesStars, mainTab):
            self = .channelFull(ChannelFull(
                flags: flags,
                flags2: flags2,
                id: id,
                about: about,
                participantsCount: participantsCount,
                adminsCount: adminsCount,
                kickedCount: kickedCount,
                bannedCount: bannedCount,
                onlineCount: onlineCount,
                readInboxMaxId: readInboxMaxId,
                readOutboxMaxId: readOutboxMaxId,
                unreadCount: unreadCount,
                chatPhoto: chatPhoto,
                notifySettings: notifySettings,
                exportedInvite: exportedInvite,
                botInfo: botInfo,
                migratedFromChatId: migratedFromChatId,
                migratedFromMaxId: migratedFromMaxId,
                pinnedMsgId: pinnedMsgId,
                stickerset: stickerset,
                availableMinId: availableMinId,
                folderId: folderId,
                linkedChatId: linkedChatId,
                location: location,
                slowmodeSeconds: slowmodeSeconds,
                slowmodeNextSendDate: slowmodeNextSendDate,
                statsDc: statsDc,
                pts: pts,
                call: call,
                ttlPeriod: ttlPeriod,
                pendingSuggestions: pendingSuggestions,
                groupcallDefaultJoinAs: groupcallDefaultJoinAs,
                themeEmoticon: themeEmoticon,
                requestsPending: requestsPending,
                recentRequesters: recentRequesters,
                defaultSendAs: defaultSendAs,
                availableReactions: availableReactions,
                reactionsLimit: reactionsLimit,
                stories: stories,
                wallpaper: wallpaper,
                boostsApplied: boostsApplied,
                boostsUnrestrict: boostsUnrestrict,
                emojiset: emojiset,
                botVerification: botVerification,
                stargiftsCount: stargiftsCount,
                sendPaidMessagesStars: sendPaidMessagesStars,
                mainTab: mainTab
            ))
        case let .chatFull(flags, id, about, participants, chatPhoto, notifySettings, exportedInvite, botInfo, pinnedMsgId, folderId, call, ttlPeriod, groupcallDefaultJoinAs, themeEmoticon, requestsPending, recentRequesters, availableReactions, reactionsLimit):
            self = .chatFull(ChatFull(
                flags: flags,
                id: id,
                about: about,
                participants: participants,
                chatPhoto: chatPhoto,
                notifySettings: notifySettings,
                exportedInvite: exportedInvite,
                botInfo: botInfo,
                pinnedMsgId: pinnedMsgId,
                folderId: folderId,
                call: call,
                ttlPeriod: ttlPeriod,
                groupcallDefaultJoinAs: groupcallDefaultJoinAs,
                themeEmoticon: themeEmoticon,
                requestsPending: requestsPending,
                recentRequesters: recentRequesters,
                availableReactions: availableReactions,
                reactionsLimit: reactionsLimit
            ))
        }
    }
}

extension Api.ChatFull {
    func wrapped() -> ApiChatFullWrapped {
        .init(self)
    }
}
