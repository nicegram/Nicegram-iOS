import CasePaths
import TelegramApi

@CasePathable
@dynamicMemberLookup
public enum ApiMessageWrapped {
    case message(Message)
    case messageEmpty(MessageEmpty)
    case messageService(MessageService)

    public struct Message {
        public let flags: Int32
        public let flags2: Int32
        public let id: Int32
        public let fromId: Api.Peer?
        public let fromBoostsApplied: Int32?
        public let peerId: Api.Peer
        public let savedPeerId: Api.Peer?
        public let fwdFrom: Api.MessageFwdHeader?
        public let viaBotId: Int64?
        public let viaBusinessBotId: Int64?
        public let replyTo: Api.MessageReplyHeader?
        public let date: Int32
        public let message: String
        public let media: Api.MessageMedia?
        public let replyMarkup: Api.ReplyMarkup?
        public let entities: [Api.MessageEntity]?
        public let views: Int32?
        public let forwards: Int32?
        public let replies: Api.MessageReplies?
        public let editDate: Int32?
        public let postAuthor: String?
        public let groupedId: Int64?
        public let reactions: Api.MessageReactions?
        public let restrictionReason: [Api.RestrictionReason]?
        public let ttlPeriod: Int32?
        public let quickReplyShortcutId: Int32?
        public let effect: Int64?
        public let factcheck: Api.FactCheck?
        public let reportDeliveryUntilDate: Int32?
        public let paidMessageStars: Int64?
        public let suggestedPost: Api.SuggestedPost?
        public let scheduleRepeatPeriod: Int32?
    }

    public struct MessageEmpty {
        public let flags: Int32
        public let id: Int32
        public let peerId: Api.Peer?
    }

    public struct MessageService {
        public let flags: Int32
        public let id: Int32
        public let fromId: Api.Peer?
        public let peerId: Api.Peer
        public let savedPeerId: Api.Peer?
        public let replyTo: Api.MessageReplyHeader?
        public let date: Int32
        public let action: Api.MessageAction
        public let reactions: Api.MessageReactions?
        public let ttlPeriod: Int32?
    }

    public init(_ apiMessage: Api.Message) {
        switch apiMessage {
        case let .message(flags, flags2, id, fromId, fromBoostsApplied, peerId, savedPeerId, fwdFrom, viaBotId, viaBusinessBotId, replyTo, date, message, media, replyMarkup, entities, views, forwards, replies, editDate, postAuthor, groupedId, reactions, restrictionReason, ttlPeriod, quickReplyShortcutId, effect, factcheck, reportDeliveryUntilDate, paidMessageStars, suggestedPost, scheduleRepeatPeriod):
            self = .message(Message(
                flags: flags,
                flags2: flags2,
                id: id,
                fromId: fromId,
                fromBoostsApplied: fromBoostsApplied,
                peerId: peerId,
                savedPeerId: savedPeerId,
                fwdFrom: fwdFrom,
                viaBotId: viaBotId,
                viaBusinessBotId: viaBusinessBotId,
                replyTo: replyTo,
                date: date,
                message: message,
                media: media,
                replyMarkup: replyMarkup,
                entities: entities,
                views: views,
                forwards: forwards,
                replies: replies,
                editDate: editDate,
                postAuthor: postAuthor,
                groupedId: groupedId,
                reactions: reactions,
                restrictionReason: restrictionReason,
                ttlPeriod: ttlPeriod,
                quickReplyShortcutId: quickReplyShortcutId,
                effect: effect,
                factcheck: factcheck,
                reportDeliveryUntilDate: reportDeliveryUntilDate,
                paidMessageStars: paidMessageStars,
                suggestedPost: suggestedPost,
                scheduleRepeatPeriod: scheduleRepeatPeriod
            ))
        case let .messageEmpty(flags, id, peerId):
            self = .messageEmpty(MessageEmpty(
                flags: flags,
                id: id,
                peerId: peerId
            ))
        case let .messageService(flags, id, fromId, peerId, savedPeerId, replyTo, date, action, reactions, ttlPeriod):
            self = .messageService(MessageService(
                flags: flags,
                id: id,
                fromId: fromId,
                peerId: peerId,
                savedPeerId: savedPeerId,
                replyTo: replyTo,
                date: date,
                action: action,
                reactions: reactions,
                ttlPeriod: ttlPeriod
            ))
        }
    }
}

extension Api.Message {
    func wrapped() -> ApiMessageWrapped {
        .init(self)
    }
}
