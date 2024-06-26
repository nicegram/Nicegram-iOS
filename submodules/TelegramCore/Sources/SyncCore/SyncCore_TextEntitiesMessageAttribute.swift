import Foundation
import Postbox

public enum MessageTextEntityType: Equatable {
    public typealias CustomEntityType = Int32
    
    case Unknown
    case Mention
    case Hashtag
    case BotCommand
    case Url
    case Email
    case Bold
    case Italic
    case Code
    case Pre(language: String?)
    case TextUrl(url: String)
    case TextMention(peerId: PeerId)
    case PhoneNumber
    case Strikethrough
    case BlockQuote(isCollapsed: Bool)
    case Underline
    case BankCard
    case Spoiler
    case CustomEmoji(stickerPack: StickerPackReference?, fileId: Int64)
    case Custom(type: CustomEntityType)
}

public struct MessageTextEntity: PostboxCoding, Codable, Equatable {
    public var range: Range<Int>
    public var type: MessageTextEntityType
    
    public init(range: Range<Int>, type: MessageTextEntityType) {
        self.range = range
        self.type = type
    }
    
    public init(decoder: PostboxDecoder) {
        self.range = Int(decoder.decodeInt32ForKey("start", orElse: 0)) ..< Int(decoder.decodeInt32ForKey("end", orElse: 0))
        let type: Int32 = decoder.decodeInt32ForKey("_rawValue", orElse: 0)
        switch type {
            case 1:
                self.type = .Mention
            case 2:
                self.type = .Hashtag
            case 3:
                self.type = .BotCommand
            case 4:
                self.type = .Url
            case 5:
                self.type = .Email
            case 6:
                self.type = .Bold
            case 7:
                self.type = .Italic
            case 8:
                self.type = .Code
            case 9:
                self.type = .Pre(language: decoder.decodeOptionalStringForKey("language"))
            case 10:
                self.type = .TextUrl(url: decoder.decodeStringForKey("url", orElse: ""))
            case 11:
                self.type = .TextMention(peerId: PeerId(decoder.decodeInt64ForKey("peerId", orElse: 0)))
            case 12:
                self.type = .PhoneNumber
            case 13:
                self.type = .Strikethrough
            case 14:
                self.type = .BlockQuote(isCollapsed: decoder.decodeBoolForKey("cl", orElse: false))
            case 15:
                self.type = .Underline
            case 16:
                self.type = .BankCard
            case 17:
                self.type = .Spoiler
            case 18:
                let stickerPack = decoder.decodeObjectForKey("s", decoder: { StickerPackReference(decoder: $0) }) as? StickerPackReference
                self.type = .CustomEmoji(stickerPack: stickerPack, fileId: decoder.decodeInt64ForKey("f", orElse: 0))
            case Int32.max:
                self.type = .Custom(type: decoder.decodeInt32ForKey("type", orElse: 0))
            default:
                self.type = .Unknown
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        let rangeStart: Int32 = (try? container.decode(Int32.self, forKey: "start")) ?? 0
        var rangeEnd: Int32 = (try? container.decode(Int32.self, forKey: "end")) ?? 0
        rangeEnd = max(rangeEnd, rangeStart)

        let type: Int32 = (try? container.decode(Int32.self, forKey: "_rawValue")) ?? 0

        self.range = Int(rangeStart) ..< Int(rangeEnd)

        switch type {
            case 1:
                self.type = .Mention
            case 2:
                self.type = .Hashtag
            case 3:
                self.type = .BotCommand
            case 4:
                self.type = .Url
            case 5:
                self.type = .Email
            case 6:
                self.type = .Bold
            case 7:
                self.type = .Italic
            case 8:
                self.type = .Code
            case 9:
                self.type = .Pre(language: try? container.decodeIfPresent(String.self, forKey: "language"))
            case 10:
                let url = (try? container.decode(String.self, forKey: "url")) ?? ""
                self.type = .TextUrl(url: url)
            case 11:
                let peerId = (try? container.decode(Int64.self, forKey: "peerId")) ?? 0
                self.type = .TextMention(peerId: PeerId(peerId))
            case 12:
                self.type = .PhoneNumber
            case 13:
                self.type = .Strikethrough
            case 14:
                self.type = .BlockQuote(isCollapsed: try container.decodeIfPresent(Bool.self, forKey: "cl") ?? false)
            case 15:
                self.type = .Underline
            case 16:
                self.type = .BankCard
            case 17:
                self.type = .Spoiler
            case 18:
                self.type = .CustomEmoji(stickerPack: try container.decodeIfPresent(StickerPackReference.self, forKey: "s"), fileId: try container.decode(Int64.self, forKey: "f"))
            case Int32.max:
                let customType: Int32 = (try? container.decode(Int32.self, forKey: "type")) ?? 0
                self.type = .Custom(type: customType)
            default:
                self.type = .Unknown
        }
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(Int32(self.range.lowerBound), forKey: "start")
        encoder.encodeInt32(Int32(self.range.upperBound), forKey: "end")
        switch self.type {
            case .Unknown:
                encoder.encodeInt32(0, forKey: "_rawValue")
            case .Mention:
                encoder.encodeInt32(1, forKey: "_rawValue")
            case .Hashtag:
                encoder.encodeInt32(2, forKey: "_rawValue")
            case .BotCommand:
                encoder.encodeInt32(3, forKey: "_rawValue")
            case .Url:
                encoder.encodeInt32(4, forKey: "_rawValue")
            case .Email:
                encoder.encodeInt32(5, forKey: "_rawValue")
            case .Bold:
                encoder.encodeInt32(6, forKey: "_rawValue")
            case .Italic:
                encoder.encodeInt32(7, forKey: "_rawValue")
            case .Code:
                encoder.encodeInt32(8, forKey: "_rawValue")
            case let .Pre(language):
                encoder.encodeInt32(9, forKey: "_rawValue")
                if let language = language {
                    encoder.encodeString(language, forKey: "language")
                } else {
                    encoder.encodeNil(forKey: "language")
                }
            case let .TextUrl(url):
                encoder.encodeInt32(10, forKey: "_rawValue")
                encoder.encodeString(url, forKey: "url")
            case let .TextMention(peerId):
                encoder.encodeInt32(11, forKey: "_rawValue")
                encoder.encodeInt64(peerId.toInt64(), forKey: "peerId")
            case .PhoneNumber:
                encoder.encodeInt32(12, forKey: "_rawValue")
            case .Strikethrough:
                encoder.encodeInt32(13, forKey: "_rawValue")
            case let .BlockQuote(isCollapsed):
                encoder.encodeInt32(14, forKey: "_rawValue")
                encoder.encodeBool(isCollapsed, forKey: "cl")
            case .Underline:
                encoder.encodeInt32(15, forKey: "_rawValue")
            case .BankCard:
                encoder.encodeInt32(16, forKey: "_rawValue")
            case .Spoiler:
                encoder.encodeInt32(17, forKey: "_rawValue")
            case let .CustomEmoji(stickerPack, fileId):
                encoder.encodeInt32(18, forKey: "_rawValue")
                if let stickerPack = stickerPack {
                    encoder.encodeObject(stickerPack, forKey: "s")
                } else {
                    encoder.encodeNil(forKey: "s")
                }
                encoder.encodeInt64(fileId, forKey: "f")
            case let .Custom(type):
                encoder.encodeInt32(Int32.max, forKey: "_rawValue")
                encoder.encodeInt32(type, forKey: "type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode(Int32(self.range.lowerBound), forKey: "start")
        try container.encode(Int32(self.range.upperBound), forKey: "end")
        switch self.type {
            case .Unknown:
                try container.encode(0 as Int32, forKey: "_rawValue")
            case .Mention:
                try container.encode(1 as Int32, forKey: "_rawValue")
            case .Hashtag:
                try container.encode(2 as Int32, forKey: "_rawValue")
            case .BotCommand:
                try container.encode(3 as Int32, forKey: "_rawValue")
            case .Url:
                try container.encode(4 as Int32, forKey: "_rawValue")
            case .Email:
                try container.encode(5 as Int32, forKey: "_rawValue")
            case .Bold:
                try container.encode(6 as Int32, forKey: "_rawValue")
            case .Italic:
                try container.encode(7 as Int32, forKey: "_rawValue")
            case .Code:
                try container.encode(8 as Int32, forKey: "_rawValue")
            case let .Pre(language):
                try container.encode(9 as Int32, forKey: "_rawValue")
                try container.encodeIfPresent(language, forKey: "language")
            case let .TextUrl(url):
                try container.encode(10 as Int32, forKey: "_rawValue")
                try container.encode(url, forKey: "url")
            case let .TextMention(peerId):
                try container.encode(11 as Int32, forKey: "_rawValue")
                try container.encode(peerId.toInt64(), forKey: "peerId")
            case .PhoneNumber:
                try container.encode(12 as Int32, forKey: "_rawValue")
            case .Strikethrough:
                try container.encode(13 as Int32, forKey: "_rawValue")
            case let .BlockQuote(isCollapsed):
                try container.encode(14 as Int32, forKey: "_rawValue")
                try container.encode(isCollapsed, forKey: "cl")
            case .Underline:
                try container.encode(15 as Int32, forKey: "_rawValue")
            case .BankCard:
                try container.encode(16 as Int32, forKey: "_rawValue")
            case .Spoiler:
                try container.encode(17 as Int32, forKey: "_rawValue")
            case let .CustomEmoji(stickerPack, fileId):
                try container.encode(18 as Int32, forKey: "_rawValue")
                try container.encodeIfPresent(stickerPack, forKey: "s")
                try container.encode(fileId, forKey: "f")
            case let .Custom(type):
                try container.encode(Int32.max as Int32, forKey: "_rawValue")
                try container.encode(type as Int32, forKey: "type")
        }
    }
    
    public static func ==(lhs: MessageTextEntity, rhs: MessageTextEntity) -> Bool {
        return lhs.range == rhs.range && lhs.type == rhs.type
    }
}

extension MessageTextEntity {
    var associatedPeerIds: [PeerId] {
        switch self.type {
        case let .TextMention(peerId):
            return [peerId]
        default:
            return []
        }
    }
}

public class TextEntitiesMessageAttribute: MessageAttribute, Equatable {
    public let entities: [MessageTextEntity]
    
    public var associatedPeerIds: [PeerId] {
        var result: [PeerId] = []
        for entity in entities {
            switch entity.type {
                case let .TextMention(peerId):
                    result.append(peerId)
                default:
                    break
            }
        }
        return result
    }
    
    public var associatedMediaIds: [MediaId] {
        var result: [MediaId] = []
        for entity in self.entities {
            switch entity.type {
            case let .CustomEmoji(_, fileId):
                result.append(MediaId(namespace: Namespaces.Media.CloudFile, id: fileId))
            default:
                break
            }
        }
        if result.isEmpty {
            return result
        } else {
            return Array(Set(result))
        }
    }
    
    public init(entities: [MessageTextEntity]) {
        self.entities = entities
    }
    
    required public init(decoder: PostboxDecoder) {
        self.entities = decoder.decodeObjectArrayWithDecoderForKey("entities")
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeObjectArray(self.entities, forKey: "entities")
    }
    
    public static func ==(lhs: TextEntitiesMessageAttribute, rhs: TextEntitiesMessageAttribute) -> Bool {
        return lhs.entities == rhs.entities
    }
}

public func messageTextEntitiesInRange(entities: [MessageTextEntity], range: NSRange, onlyQuoteable: Bool) -> [MessageTextEntity] {
    let range: Range<Int> = range.lowerBound ..< range.upperBound
    var result: [MessageTextEntity] = []
    loop: for entity in entities {
        if onlyQuoteable {
            switch entity.type {
            case .Bold, .Italic, .Strikethrough, .Underline, .Spoiler, .CustomEmoji:
                break
            default:
                continue loop
            }
        }
        if entity.range.overlaps(range) {
            var mappedRange = entity.range.clamped(to: range)
            mappedRange = (mappedRange.lowerBound - range.lowerBound) ..< (mappedRange.upperBound - range.lowerBound)
            result.append(MessageTextEntity(range: mappedRange, type: entity.type))
        }
    }
    return result
}

public func quoteMaxLength(appConfig: AppConfiguration) -> Int {
    if let data = appConfig.data, let quoteLengthMax = data["quote_length_max"] as? Double {
        return Int(quoteLengthMax)
    }
    return 1024
}

public func trimStringWithEntities(string: String, entities: [MessageTextEntity], maxLength: Int) -> (string: String, entities: [MessageTextEntity]) {
    let nsString = string as NSString
    var range = 0 ..< nsString.length
    
    while range.lowerBound < nsString.length {
        let c = nsString.character(at: range.lowerBound)
        if c == 0x0a || c == 0x20 {
            range = (range.lowerBound + 1) ..< range.upperBound
        } else {
            break
        }
    }
    
    while range.upperBound > range.lowerBound {
        let c = nsString.character(at: range.upperBound - 1)
        if c == 0x0a || c == 0x20 {
            range = range.lowerBound ..< (range.upperBound - 1)
        } else {
            break
        }
    }
    
    while range.upperBound - range.lowerBound > maxLength {
        range = range.lowerBound ..< (range.upperBound - 1)
    }
    
    let nsRange = NSRange(location: range.lowerBound, length: range.upperBound - range.lowerBound)
    return (nsString.substring(with: nsRange), messageTextEntitiesInRange(entities: entities, range: nsRange, onlyQuoteable: false))
}
