import Foundation
import Postbox
import TelegramApi

public final class CachedPeerBotInfo: PostboxCoding, Equatable {
    public let peerId: PeerId
    public let botInfo: BotInfo
    
    public init(peerId: PeerId, botInfo: BotInfo) {
        self.peerId = peerId
        self.botInfo = botInfo
    }
    
    public init(decoder: PostboxDecoder) {
        self.peerId = PeerId(decoder.decodeInt64ForKey("p", orElse: 0))
        self.botInfo = decoder.decodeObjectForKey("i", decoder: { return BotInfo(decoder: $0) }) as! BotInfo
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt64(self.peerId.toInt64(), forKey: "p")
        encoder.encodeObject(self.botInfo, forKey: "i")
    }
    
    public static func ==(lhs: CachedPeerBotInfo, rhs: CachedPeerBotInfo) -> Bool {
        return lhs.peerId == rhs.peerId && lhs.botInfo == rhs.botInfo
    }
}

public struct CachedGroupFlags: OptionSet {
    public var rawValue: Int32
    
    public init() {
        self.rawValue = 0
    }
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    public static let canChangeUsername = CachedGroupFlags(rawValue: 1 << 0)
    public static let translationHidden = CachedGroupFlags(rawValue: 1 << 1)
}

public enum PeerAllowedReactions: Equatable, Codable {
    private enum Discriminant: Int32 {
        case all = 0
        case limited = 1
        case empty = 2
    }
    
    case all
    case limited([MessageReaction.Reaction])
    case empty
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        
        let discriminant = try container.decode(Int32.self, forKey: "_d")
        switch discriminant {
        case Discriminant.all.rawValue:
            self = .all
        case Discriminant.limited.rawValue:
            self = .limited(try container.decode([MessageReaction.Reaction].self, forKey: "r"))
        case Discriminant.empty.rawValue:
            self = .empty
        default:
            assertionFailure()
            self = .all
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        
        switch self {
        case .all:
            try container.encode(Discriminant.all.rawValue, forKey: "_d")
        case let .limited(reactions):
            try container.encode(Discriminant.limited.rawValue, forKey: "_d")
            try container.encode(reactions, forKey: "r")
        case .empty:
            try container.encode(Discriminant.empty.rawValue, forKey: "_d")
        }
    }
}

extension PeerAllowedReactions {
    init(apiReactions: Api.ChatReactions) {
        switch apiReactions {
        case .chatReactionsAll:
            self = .all
        case let .chatReactionsSome(reactions):
            self = .limited(reactions.compactMap(MessageReaction.Reaction.init(apiReaction:)))
        case .chatReactionsNone:
            self = .empty
        }
    }
}

public final class PeerReactionSettings: Equatable, Codable {
    public let allowedReactions: PeerAllowedReactions
    public let maxReactionCount: Int32?
    public let starsAllowed: Bool?
    
    public init(allowedReactions: PeerAllowedReactions, maxReactionCount: Int32?, starsAllowed: Bool?) {
        self.allowedReactions = allowedReactions
        self.maxReactionCount = maxReactionCount
        self.starsAllowed = starsAllowed
    }
    
    public static func ==(lhs: PeerReactionSettings, rhs: PeerReactionSettings) -> Bool {
        if lhs === rhs {
            return true
        }
        if lhs.allowedReactions != rhs.allowedReactions {
            return false
        }
        if lhs.maxReactionCount != rhs.maxReactionCount {
            return false
        }
        if lhs.starsAllowed != rhs.starsAllowed {
            return false
        }
        return true
    }
}

public final class CachedGroupData: CachedPeerData {
    public let participants: CachedGroupParticipants?
    public let exportedInvitation: ExportedInvitation?
    public let botInfos: [CachedPeerBotInfo]
    public let peerStatusSettings: PeerStatusSettings?
    public let pinnedMessageId: MessageId?
    public let about: String?
    public let flags: CachedGroupFlags
    public let hasScheduledMessages: Bool
    public let invitedBy: PeerId?
    public let photo: TelegramMediaImage?
    public let autoremoveTimeout: CachedPeerAutoremoveTimeout
    public let activeCall: CachedChannelData.ActiveCall?
    public let callJoinPeerId: PeerId?
    public let chatTheme: ChatTheme?
    public let inviteRequestsPending: Int32?
    
    public let reactionSettings: EnginePeerCachedInfoItem<PeerReactionSettings>
    
    public let peerIds: Set<PeerId>
    public let messageIds: Set<MessageId>
    public let associatedHistoryMessageId: MessageId? = nil
    
    public init() {
        self.participants = nil
        self.exportedInvitation = nil
        self.botInfos = []
        self.peerStatusSettings = nil
        self.pinnedMessageId = nil
        self.messageIds = Set()
        self.peerIds = Set()
        self.about = nil
        self.flags = CachedGroupFlags()
        self.hasScheduledMessages = false
        self.invitedBy = nil
        self.photo = nil
        self.autoremoveTimeout = .unknown
        self.activeCall = nil
        self.callJoinPeerId = nil
        self.chatTheme = nil
        self.inviteRequestsPending = nil
        self.reactionSettings = .unknown
    }
    
    public init(
        participants: CachedGroupParticipants?,
        exportedInvitation: ExportedInvitation?,
        botInfos: [CachedPeerBotInfo],
        peerStatusSettings: PeerStatusSettings?,
        pinnedMessageId: MessageId?,
        about: String?,
        flags: CachedGroupFlags,
        hasScheduledMessages: Bool,
        invitedBy: PeerId?,
        photo: TelegramMediaImage?,
        activeCall: CachedChannelData.ActiveCall?,
        autoremoveTimeout: CachedPeerAutoremoveTimeout,
        callJoinPeerId: PeerId?,
        chatTheme: ChatTheme?,
        inviteRequestsPending: Int32?,
        reactionSettings: EnginePeerCachedInfoItem<PeerReactionSettings>
    ) {
        self.participants = participants
        self.exportedInvitation = exportedInvitation
        self.botInfos = botInfos
        self.peerStatusSettings = peerStatusSettings
        self.pinnedMessageId = pinnedMessageId
        self.about = about
        self.flags = flags
        self.hasScheduledMessages = hasScheduledMessages
        self.invitedBy = invitedBy
        self.photo = photo
        self.activeCall = activeCall
        self.autoremoveTimeout = autoremoveTimeout
        self.callJoinPeerId = callJoinPeerId
        self.chatTheme = chatTheme
        self.inviteRequestsPending = inviteRequestsPending
        self.reactionSettings = reactionSettings
        
        var messageIds = Set<MessageId>()
        if let pinnedMessageId = self.pinnedMessageId {
            messageIds.insert(pinnedMessageId)
        }
        self.messageIds = messageIds
        
        var peerIds = Set<PeerId>()
        if let participants = participants {
            for participant in participants.participants {
                peerIds.insert(participant.peerId)
            }
        }
        for botInfo in botInfos {
            peerIds.insert(botInfo.peerId)
        }
        if let invitedBy = invitedBy {
            peerIds.insert(invitedBy)
        }
        self.peerIds = peerIds
    }
    
    public init(decoder: PostboxDecoder) {
        let participants = decoder.decodeObjectForKey("p", decoder: { CachedGroupParticipants(decoder: $0) }) as? CachedGroupParticipants
        self.participants = participants
        self.exportedInvitation = decoder.decode(ExportedInvitation.self, forKey: "i")
        self.botInfos = decoder.decodeObjectArrayWithDecoderForKey("b") as [CachedPeerBotInfo]
        if let legacyValue = decoder.decodeOptionalInt32ForKey("pcs") {
            self.peerStatusSettings = PeerStatusSettings(flags: PeerStatusSettings.Flags(rawValue: legacyValue), geoDistance: nil, managingBot: nil)
        } else if let peerStatusSettings = decoder.decodeObjectForKey("pss", decoder: { PeerStatusSettings(decoder: $0) }) as? PeerStatusSettings {
            self.peerStatusSettings = peerStatusSettings
        } else {
            self.peerStatusSettings = nil
        }
        if let pinnedMessagePeerId = decoder.decodeOptionalInt64ForKey("pm.p"), let pinnedMessageNamespace = decoder.decodeOptionalInt32ForKey("pm.n"), let pinnedMessageId = decoder.decodeOptionalInt32ForKey("pm.i") {
            self.pinnedMessageId = MessageId(peerId: PeerId(pinnedMessagePeerId), namespace: pinnedMessageNamespace, id: pinnedMessageId)
        } else {
            self.pinnedMessageId = nil
        }
        self.about = decoder.decodeOptionalStringForKey("ab")
        self.flags = CachedGroupFlags(rawValue: decoder.decodeInt32ForKey("fl", orElse: 0))
        self.hasScheduledMessages = decoder.decodeBoolForKey("hsm", orElse: false)
        self.autoremoveTimeout = decoder.decodeObjectForKey("artv", decoder: CachedPeerAutoremoveTimeout.init(decoder:)) as? CachedPeerAutoremoveTimeout ?? .unknown
        
        self.invitedBy = decoder.decodeOptionalInt64ForKey("invBy").flatMap(PeerId.init)
        
        if let photo = decoder.decodeObjectForKey("ph", decoder: { TelegramMediaImage(decoder: $0) }) as? TelegramMediaImage {
            self.photo = photo
        } else {
            self.photo = nil
        }
            
        if let activeCall = decoder.decodeObjectForKey("activeCall", decoder: { CachedChannelData.ActiveCall(decoder: $0) }) as? CachedChannelData.ActiveCall {
            self.activeCall = activeCall
        } else {
            self.activeCall = nil
        }
        
        self.callJoinPeerId = decoder.decodeOptionalInt64ForKey("callJoinPeerId").flatMap(PeerId.init)
        
        if let chatThemeData = decoder.decodeDataForKey("ct"), let chatTheme = try? AdaptedPostboxDecoder().decode(ChatTheme.self, from: chatThemeData) {
            self.chatTheme = chatTheme
        } else if let themeEmoticon = decoder.decodeOptionalStringForKey("te") {
            self.chatTheme = .emoticon(themeEmoticon)
        } else {
            self.chatTheme = nil
        }
        
        self.inviteRequestsPending = decoder.decodeOptionalInt32ForKey("irp")
        
        if let reactionSettings = decoder.decode(PeerReactionSettings.self, forKey: "reactionSettings") {
            self.reactionSettings = .known(reactionSettings)
        } else if let legacyAllowedReactions = decoder.decodeOptionalStringArrayForKey("allowedReactions") {
            let allowedReactions: PeerAllowedReactions = .limited(legacyAllowedReactions.map(MessageReaction.Reaction.builtin))
            self.reactionSettings = .known(PeerReactionSettings(allowedReactions: allowedReactions, maxReactionCount: nil, starsAllowed: nil))
        } else if let allowedReactions = decoder.decode(PeerAllowedReactions.self, forKey: "allowedReactionSet") {
            let allowedReactions = allowedReactions
            self.reactionSettings = .known(PeerReactionSettings(allowedReactions: allowedReactions, maxReactionCount: nil, starsAllowed: nil))
        } else {
            self.reactionSettings = .unknown
        }
        
        var messageIds = Set<MessageId>()
        if let pinnedMessageId = self.pinnedMessageId {
            messageIds.insert(pinnedMessageId)
        }
        self.messageIds = messageIds
        
        var peerIds = Set<PeerId>()
        if let participants = participants {
            for participant in participants.participants {
                peerIds.insert(participant.peerId)
            }
        }
        for botInfo in self.botInfos {
            peerIds.insert(botInfo.peerId)
        }
        
        self.peerIds = peerIds
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        if let participants = self.participants {
            encoder.encodeObject(participants, forKey: "p")
        } else {
            encoder.encodeNil(forKey: "p")
        }
        if let exportedInvitation = self.exportedInvitation {
            encoder.encode(exportedInvitation, forKey: "i")
        } else {
            encoder.encodeNil(forKey: "i")
        }
        encoder.encodeObjectArray(self.botInfos, forKey: "b")
        if let peerStatusSettings = self.peerStatusSettings {
            encoder.encodeObject(peerStatusSettings, forKey: "pss")
        } else {
            encoder.encodeNil(forKey: "pss")
        }
        if let pinnedMessageId = self.pinnedMessageId {
            encoder.encodeInt64(pinnedMessageId.peerId.toInt64(), forKey: "pm.p")
            encoder.encodeInt32(pinnedMessageId.namespace, forKey: "pm.n")
            encoder.encodeInt32(pinnedMessageId.id, forKey: "pm.i")
        } else {
            encoder.encodeNil(forKey: "pm.p")
            encoder.encodeNil(forKey: "pm.n")
            encoder.encodeNil(forKey: "pm.i")
        }
        if let about = self.about {
            encoder.encodeString(about, forKey: "ab")
        } else {
            encoder.encodeNil(forKey: "ab")
        }
        encoder.encodeInt32(self.flags.rawValue, forKey: "fl")
        encoder.encodeBool(self.hasScheduledMessages, forKey: "hsm")
        encoder.encodeObject(self.autoremoveTimeout, forKey: "artv")
        
        if let invitedBy = self.invitedBy {
            encoder.encodeInt64(invitedBy.toInt64(), forKey: "invBy")
        } else {
            encoder.encodeNil(forKey: "invBy")
        }
        
        if let photo = self.photo {
            encoder.encodeObject(photo, forKey: "ph")
        } else {
            encoder.encodeNil(forKey: "ph")
        }
        
        if let activeCall = self.activeCall {
            encoder.encodeObject(activeCall, forKey: "activeCall")
        } else {
            encoder.encodeNil(forKey: "activeCall")
        }
        
        if let callJoinPeerId = self.callJoinPeerId {
            encoder.encodeInt64(callJoinPeerId.toInt64(), forKey: "callJoinPeerId")
        } else {
            encoder.encodeNil(forKey: "callJoinPeerId")
        }
        
        if let chatTheme = self.chatTheme, let chatThemeData = try? AdaptedPostboxEncoder().encode(chatTheme) {
            encoder.encodeData(chatThemeData, forKey: "ct")
        } else {
            encoder.encodeNil(forKey: "ct")
        }
        
        if let inviteRequestsPending = self.inviteRequestsPending {
            encoder.encodeInt32(inviteRequestsPending, forKey: "irp")
        } else {
            encoder.encodeNil(forKey: "irp")
        }
        
        switch self.reactionSettings {
        case .unknown:
            encoder.encodeNil(forKey: "reactionSettings")
        case let .known(value):
            encoder.encode(value, forKey: "reactionSettings")
        }
    }
    
    public func isEqual(to: CachedPeerData) -> Bool {
        guard let other = to as? CachedGroupData else {
            return false
        }
        
        if self.activeCall != other.activeCall {
            return false
        }
        
        if self.callJoinPeerId != other.callJoinPeerId {
            return false
        }
        
        if self.reactionSettings != other.reactionSettings {
            return false
        }
        
        return self.participants == other.participants && self.exportedInvitation == other.exportedInvitation && self.botInfos == other.botInfos && self.peerStatusSettings == other.peerStatusSettings && self.pinnedMessageId == other.pinnedMessageId && self.about == other.about && self.flags == other.flags && self.hasScheduledMessages == other.hasScheduledMessages && self.autoremoveTimeout == other.autoremoveTimeout && self.invitedBy == other.invitedBy && self.chatTheme == other.chatTheme && self.inviteRequestsPending == other.inviteRequestsPending
    }
    
    public func withUpdatedParticipants(_ participants: CachedGroupParticipants?) -> CachedGroupData {
        return CachedGroupData(participants: participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedExportedInvitation(_ exportedInvitation: ExportedInvitation?) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedBotInfos(_ botInfos: [CachedPeerBotInfo]) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedPeerStatusSettings(_ peerStatusSettings: PeerStatusSettings?) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }

    public func withUpdatedPinnedMessageId(_ pinnedMessageId: MessageId?) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedAbout(_ about: String?) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedFlags(_ flags: CachedGroupFlags) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedHasScheduledMessages(_ hasScheduledMessages: Bool) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedInvitedBy(_ invitedBy: PeerId?) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedPhoto(_ photo: TelegramMediaImage?) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedActiveCall(_ activeCall: CachedChannelData.ActiveCall?) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedAutoremoveTimeout(_ autoremoveTimeout: CachedPeerAutoremoveTimeout) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedCallJoinPeerId(_ callJoinPeerId: PeerId?) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedChatTheme(_ chatTheme: ChatTheme?) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedInviteRequestsPending(_ inviteRequestsPending: Int32?) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: inviteRequestsPending, reactionSettings: self.reactionSettings)
    }
    
    public func withUpdatedReactionSettings(_ reactionSettings: EnginePeerCachedInfoItem<PeerReactionSettings>) -> CachedGroupData {
        return CachedGroupData(participants: self.participants, exportedInvitation: self.exportedInvitation, botInfos: self.botInfos, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, about: self.about, flags: self.flags, hasScheduledMessages: self.hasScheduledMessages, invitedBy: self.invitedBy, photo: self.photo, activeCall: self.activeCall, autoremoveTimeout: self.autoremoveTimeout, callJoinPeerId: self.callJoinPeerId, chatTheme: self.chatTheme, inviteRequestsPending: self.inviteRequestsPending, reactionSettings: reactionSettings)
    }
}
