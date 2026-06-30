public extension Api {
    enum RestrictionReason: TypeConstructorDescription {
        public class Cons_restrictionReason: TypeConstructorDescription {
            public var platform: String
            public var reason: String
            public var text: String
            public init(platform: String, reason: String, text: String) {
                self.platform = platform
                self.reason = reason
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("restrictionReason", [("platform", ConstructorParameterDescription(self.platform)), ("reason", ConstructorParameterDescription(self.reason)), ("text", ConstructorParameterDescription(self.text))])
            }
        }
        case restrictionReason(Cons_restrictionReason)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .restrictionReason(let _data):
                if boxed {
                    buffer.appendInt32(-797791052)
                }
                serializeString(_data.platform, buffer: buffer, boxed: false)
                serializeString(_data.reason, buffer: buffer, boxed: false)
                serializeString(_data.text, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .restrictionReason(let _data):
                return ("restrictionReason", [("platform", ConstructorParameterDescription(_data.platform)), ("reason", ConstructorParameterDescription(_data.reason)), ("text", ConstructorParameterDescription(_data.text))])
            }
        }

        public static func parse_restrictionReason(_ reader: BufferReader) -> RestrictionReason? {
            var _1: String?
            _1 = parseString(reader)
            var _2: String?
            _2 = parseString(reader)
            var _3: String?
            _3 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.RestrictionReason.restrictionReason(Cons_restrictionReason(platform: _1!, reason: _2!, text: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum RichMessage: TypeConstructorDescription {
        public class Cons_richMessage: TypeConstructorDescription {
            public var flags: Int32
            public var blocks: [Api.PageBlock]
            public var photos: [Api.Photo]
            public var documents: [Api.Document]
            public init(flags: Int32, blocks: [Api.PageBlock], photos: [Api.Photo], documents: [Api.Document]) {
                self.flags = flags
                self.blocks = blocks
                self.photos = photos
                self.documents = documents
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("richMessage", [("flags", ConstructorParameterDescription(self.flags)), ("blocks", ConstructorParameterDescription(self.blocks)), ("photos", ConstructorParameterDescription(self.photos)), ("documents", ConstructorParameterDescription(self.documents))])
            }
        }
        case richMessage(Cons_richMessage)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .richMessage(let _data):
                if boxed {
                    buffer.appendInt32(-1158439541)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.blocks.count))
                for item in _data.blocks {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.photos.count))
                for item in _data.photos {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.documents.count))
                for item in _data.documents {
                    item.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .richMessage(let _data):
                return ("richMessage", [("flags", ConstructorParameterDescription(_data.flags)), ("blocks", ConstructorParameterDescription(_data.blocks)), ("photos", ConstructorParameterDescription(_data.photos)), ("documents", ConstructorParameterDescription(_data.documents))])
            }
        }

        public static func parse_richMessage(_ reader: BufferReader) -> RichMessage? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.PageBlock]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.PageBlock.self)
            }
            var _3: [Api.Photo]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Photo.self)
            }
            var _4: [Api.Document]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Document.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.RichMessage.richMessage(Cons_richMessage(flags: _1!, blocks: _2!, photos: _3!, documents: _4!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    indirect enum RichText: TypeConstructorDescription {
        public class Cons_textAnchor: TypeConstructorDescription {
            public var text: Api.RichText
            public var name: String
            public init(text: Api.RichText, name: String) {
                self.text = text
                self.name = name
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textAnchor", [("text", ConstructorParameterDescription(self.text)), ("name", ConstructorParameterDescription(self.name))])
            }
        }
        public class Cons_textAutoEmail: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textAutoEmail", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textAutoPhone: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textAutoPhone", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textAutoUrl: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textAutoUrl", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textBankCard: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textBankCard", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textBold: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textBold", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textBotCommand: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textBotCommand", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textCashtag: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textCashtag", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textConcat: TypeConstructorDescription {
            public var texts: [Api.RichText]
            public init(texts: [Api.RichText]) {
                self.texts = texts
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textConcat", [("texts", ConstructorParameterDescription(self.texts))])
            }
        }
        public class Cons_textCustomEmoji: TypeConstructorDescription {
            public var documentId: Int64
            public var alt: String
            public init(documentId: Int64, alt: String) {
                self.documentId = documentId
                self.alt = alt
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textCustomEmoji", [("documentId", ConstructorParameterDescription(self.documentId)), ("alt", ConstructorParameterDescription(self.alt))])
            }
        }
        public class Cons_textDate: TypeConstructorDescription {
            public var flags: Int32
            public var text: Api.RichText
            public var date: Int32
            public init(flags: Int32, text: Api.RichText, date: Int32) {
                self.flags = flags
                self.text = text
                self.date = date
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textDate", [("flags", ConstructorParameterDescription(self.flags)), ("text", ConstructorParameterDescription(self.text)), ("date", ConstructorParameterDescription(self.date))])
            }
        }
        public class Cons_textEmail: TypeConstructorDescription {
            public var text: Api.RichText
            public var email: String
            public init(text: Api.RichText, email: String) {
                self.text = text
                self.email = email
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textEmail", [("text", ConstructorParameterDescription(self.text)), ("email", ConstructorParameterDescription(self.email))])
            }
        }
        public class Cons_textFixed: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textFixed", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textHashtag: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textHashtag", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textImage: TypeConstructorDescription {
            public var documentId: Int64
            public var w: Int32
            public var h: Int32
            public init(documentId: Int64, w: Int32, h: Int32) {
                self.documentId = documentId
                self.w = w
                self.h = h
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textImage", [("documentId", ConstructorParameterDescription(self.documentId)), ("w", ConstructorParameterDescription(self.w)), ("h", ConstructorParameterDescription(self.h))])
            }
        }
        public class Cons_textItalic: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textItalic", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textMarked: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textMarked", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textMath: TypeConstructorDescription {
            public var source: String
            public init(source: String) {
                self.source = source
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textMath", [("source", ConstructorParameterDescription(self.source))])
            }
        }
        public class Cons_textMention: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textMention", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textMentionName: TypeConstructorDescription {
            public var text: Api.RichText
            public var userId: Int64
            public init(text: Api.RichText, userId: Int64) {
                self.text = text
                self.userId = userId
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textMentionName", [("text", ConstructorParameterDescription(self.text)), ("userId", ConstructorParameterDescription(self.userId))])
            }
        }
        public class Cons_textPhone: TypeConstructorDescription {
            public var text: Api.RichText
            public var phone: String
            public init(text: Api.RichText, phone: String) {
                self.text = text
                self.phone = phone
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textPhone", [("text", ConstructorParameterDescription(self.text)), ("phone", ConstructorParameterDescription(self.phone))])
            }
        }
        public class Cons_textPlain: TypeConstructorDescription {
            public var text: String
            public init(text: String) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textPlain", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textSpoiler: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textSpoiler", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textStrike: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textStrike", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textSubscript: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textSubscript", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textSuperscript: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textSuperscript", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textUnderline: TypeConstructorDescription {
            public var text: Api.RichText
            public init(text: Api.RichText) {
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textUnderline", [("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_textUrl: TypeConstructorDescription {
            public var text: Api.RichText
            public var url: String
            public var webpageId: Int64
            public init(text: Api.RichText, url: String, webpageId: Int64) {
                self.text = text
                self.url = url
                self.webpageId = webpageId
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("textUrl", [("text", ConstructorParameterDescription(self.text)), ("url", ConstructorParameterDescription(self.url)), ("webpageId", ConstructorParameterDescription(self.webpageId))])
            }
        }
        case textAnchor(Cons_textAnchor)
        case textAutoEmail(Cons_textAutoEmail)
        case textAutoPhone(Cons_textAutoPhone)
        case textAutoUrl(Cons_textAutoUrl)
        case textBankCard(Cons_textBankCard)
        case textBold(Cons_textBold)
        case textBotCommand(Cons_textBotCommand)
        case textCashtag(Cons_textCashtag)
        case textConcat(Cons_textConcat)
        case textCustomEmoji(Cons_textCustomEmoji)
        case textDate(Cons_textDate)
        case textEmail(Cons_textEmail)
        case textEmpty
        case textFixed(Cons_textFixed)
        case textHashtag(Cons_textHashtag)
        case textImage(Cons_textImage)
        case textItalic(Cons_textItalic)
        case textMarked(Cons_textMarked)
        case textMath(Cons_textMath)
        case textMention(Cons_textMention)
        case textMentionName(Cons_textMentionName)
        case textPhone(Cons_textPhone)
        case textPlain(Cons_textPlain)
        case textSpoiler(Cons_textSpoiler)
        case textStrike(Cons_textStrike)
        case textSubscript(Cons_textSubscript)
        case textSuperscript(Cons_textSuperscript)
        case textUnderline(Cons_textUnderline)
        case textUrl(Cons_textUrl)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .textAnchor(let _data):
                if boxed {
                    buffer.appendInt32(894777186)
                }
                _data.text.serialize(buffer, true)
                serializeString(_data.name, buffer: buffer, boxed: false)
                break
            case .textAutoEmail(let _data):
                if boxed {
                    buffer.appendInt32(-984177571)
                }
                _data.text.serialize(buffer, true)
                break
            case .textAutoPhone(let _data):
                if boxed {
                    buffer.appendInt32(616720265)
                }
                _data.text.serialize(buffer, true)
                break
            case .textAutoUrl(let _data):
                if boxed {
                    buffer.appendInt32(-1402305622)
                }
                _data.text.serialize(buffer, true)
                break
            case .textBankCard(let _data):
                if boxed {
                    buffer.appendInt32(-1185513171)
                }
                _data.text.serialize(buffer, true)
                break
            case .textBold(let _data):
                if boxed {
                    buffer.appendInt32(1730456516)
                }
                _data.text.serialize(buffer, true)
                break
            case .textBotCommand(let _data):
                if boxed {
                    buffer.appendInt32(50276819)
                }
                _data.text.serialize(buffer, true)
                break
            case .textCashtag(let _data):
                if boxed {
                    buffer.appendInt32(2073958401)
                }
                _data.text.serialize(buffer, true)
                break
            case .textConcat(let _data):
                if boxed {
                    buffer.appendInt32(2120376535)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.texts.count))
                for item in _data.texts {
                    item.serialize(buffer, true)
                }
                break
            case .textCustomEmoji(let _data):
                if boxed {
                    buffer.appendInt32(-1570679104)
                }
                serializeInt64(_data.documentId, buffer: buffer, boxed: false)
                serializeString(_data.alt, buffer: buffer, boxed: false)
                break
            case .textDate(let _data):
                if boxed {
                    buffer.appendInt32(-1514906069)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                _data.text.serialize(buffer, true)
                serializeInt32(_data.date, buffer: buffer, boxed: false)
                break
            case .textEmail(let _data):
                if boxed {
                    buffer.appendInt32(-564523562)
                }
                _data.text.serialize(buffer, true)
                serializeString(_data.email, buffer: buffer, boxed: false)
                break
            case .textEmpty:
                if boxed {
                    buffer.appendInt32(-599948721)
                }
                break
            case .textFixed(let _data):
                if boxed {
                    buffer.appendInt32(1816074681)
                }
                _data.text.serialize(buffer, true)
                break
            case .textHashtag(let _data):
                if boxed {
                    buffer.appendInt32(1368728810)
                }
                _data.text.serialize(buffer, true)
                break
            case .textImage(let _data):
                if boxed {
                    buffer.appendInt32(136105807)
                }
                serializeInt64(_data.documentId, buffer: buffer, boxed: false)
                serializeInt32(_data.w, buffer: buffer, boxed: false)
                serializeInt32(_data.h, buffer: buffer, boxed: false)
                break
            case .textItalic(let _data):
                if boxed {
                    buffer.appendInt32(-653089380)
                }
                _data.text.serialize(buffer, true)
                break
            case .textMarked(let _data):
                if boxed {
                    buffer.appendInt32(55281185)
                }
                _data.text.serialize(buffer, true)
                break
            case .textMath(let _data):
                if boxed {
                    buffer.appendInt32(-1657885545)
                }
                serializeString(_data.source, buffer: buffer, boxed: false)
                break
            case .textMention(let _data):
                if boxed {
                    buffer.appendInt32(-853225660)
                }
                _data.text.serialize(buffer, true)
                break
            case .textMentionName(let _data):
                if boxed {
                    buffer.appendInt32(27917308)
                }
                _data.text.serialize(buffer, true)
                serializeInt64(_data.userId, buffer: buffer, boxed: false)
                break
            case .textPhone(let _data):
                if boxed {
                    buffer.appendInt32(483104362)
                }
                _data.text.serialize(buffer, true)
                serializeString(_data.phone, buffer: buffer, boxed: false)
                break
            case .textPlain(let _data):
                if boxed {
                    buffer.appendInt32(1950782688)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                break
            case .textSpoiler(let _data):
                if boxed {
                    buffer.appendInt32(1277844834)
                }
                _data.text.serialize(buffer, true)
                break
            case .textStrike(let _data):
                if boxed {
                    buffer.appendInt32(-1678197867)
                }
                _data.text.serialize(buffer, true)
                break
            case .textSubscript(let _data):
                if boxed {
                    buffer.appendInt32(-311786236)
                }
                _data.text.serialize(buffer, true)
                break
            case .textSuperscript(let _data):
                if boxed {
                    buffer.appendInt32(-939827711)
                }
                _data.text.serialize(buffer, true)
                break
            case .textUnderline(let _data):
                if boxed {
                    buffer.appendInt32(-1054465340)
                }
                _data.text.serialize(buffer, true)
                break
            case .textUrl(let _data):
                if boxed {
                    buffer.appendInt32(1009288385)
                }
                _data.text.serialize(buffer, true)
                serializeString(_data.url, buffer: buffer, boxed: false)
                serializeInt64(_data.webpageId, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .textAnchor(let _data):
                return ("textAnchor", [("text", ConstructorParameterDescription(_data.text)), ("name", ConstructorParameterDescription(_data.name))])
            case .textAutoEmail(let _data):
                return ("textAutoEmail", [("text", ConstructorParameterDescription(_data.text))])
            case .textAutoPhone(let _data):
                return ("textAutoPhone", [("text", ConstructorParameterDescription(_data.text))])
            case .textAutoUrl(let _data):
                return ("textAutoUrl", [("text", ConstructorParameterDescription(_data.text))])
            case .textBankCard(let _data):
                return ("textBankCard", [("text", ConstructorParameterDescription(_data.text))])
            case .textBold(let _data):
                return ("textBold", [("text", ConstructorParameterDescription(_data.text))])
            case .textBotCommand(let _data):
                return ("textBotCommand", [("text", ConstructorParameterDescription(_data.text))])
            case .textCashtag(let _data):
                return ("textCashtag", [("text", ConstructorParameterDescription(_data.text))])
            case .textConcat(let _data):
                return ("textConcat", [("texts", ConstructorParameterDescription(_data.texts))])
            case .textCustomEmoji(let _data):
                return ("textCustomEmoji", [("documentId", ConstructorParameterDescription(_data.documentId)), ("alt", ConstructorParameterDescription(_data.alt))])
            case .textDate(let _data):
                return ("textDate", [("flags", ConstructorParameterDescription(_data.flags)), ("text", ConstructorParameterDescription(_data.text)), ("date", ConstructorParameterDescription(_data.date))])
            case .textEmail(let _data):
                return ("textEmail", [("text", ConstructorParameterDescription(_data.text)), ("email", ConstructorParameterDescription(_data.email))])
            case .textEmpty:
                return ("textEmpty", [])
            case .textFixed(let _data):
                return ("textFixed", [("text", ConstructorParameterDescription(_data.text))])
            case .textHashtag(let _data):
                return ("textHashtag", [("text", ConstructorParameterDescription(_data.text))])
            case .textImage(let _data):
                return ("textImage", [("documentId", ConstructorParameterDescription(_data.documentId)), ("w", ConstructorParameterDescription(_data.w)), ("h", ConstructorParameterDescription(_data.h))])
            case .textItalic(let _data):
                return ("textItalic", [("text", ConstructorParameterDescription(_data.text))])
            case .textMarked(let _data):
                return ("textMarked", [("text", ConstructorParameterDescription(_data.text))])
            case .textMath(let _data):
                return ("textMath", [("source", ConstructorParameterDescription(_data.source))])
            case .textMention(let _data):
                return ("textMention", [("text", ConstructorParameterDescription(_data.text))])
            case .textMentionName(let _data):
                return ("textMentionName", [("text", ConstructorParameterDescription(_data.text)), ("userId", ConstructorParameterDescription(_data.userId))])
            case .textPhone(let _data):
                return ("textPhone", [("text", ConstructorParameterDescription(_data.text)), ("phone", ConstructorParameterDescription(_data.phone))])
            case .textPlain(let _data):
                return ("textPlain", [("text", ConstructorParameterDescription(_data.text))])
            case .textSpoiler(let _data):
                return ("textSpoiler", [("text", ConstructorParameterDescription(_data.text))])
            case .textStrike(let _data):
                return ("textStrike", [("text", ConstructorParameterDescription(_data.text))])
            case .textSubscript(let _data):
                return ("textSubscript", [("text", ConstructorParameterDescription(_data.text))])
            case .textSuperscript(let _data):
                return ("textSuperscript", [("text", ConstructorParameterDescription(_data.text))])
            case .textUnderline(let _data):
                return ("textUnderline", [("text", ConstructorParameterDescription(_data.text))])
            case .textUrl(let _data):
                return ("textUrl", [("text", ConstructorParameterDescription(_data.text)), ("url", ConstructorParameterDescription(_data.url)), ("webpageId", ConstructorParameterDescription(_data.webpageId))])
            }
        }

        public static func parse_textAnchor(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            var _2: String?
            _2 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.RichText.textAnchor(Cons_textAnchor(text: _1!, name: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_textAutoEmail(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textAutoEmail(Cons_textAutoEmail(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textAutoPhone(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textAutoPhone(Cons_textAutoPhone(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textAutoUrl(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textAutoUrl(Cons_textAutoUrl(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textBankCard(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textBankCard(Cons_textBankCard(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textBold(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textBold(Cons_textBold(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textBotCommand(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textBotCommand(Cons_textBotCommand(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textCashtag(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textCashtag(Cons_textCashtag(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textConcat(_ reader: BufferReader) -> RichText? {
            var _1: [Api.RichText]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.RichText.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textConcat(Cons_textConcat(texts: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textCustomEmoji(_ reader: BufferReader) -> RichText? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: String?
            _2 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.RichText.textCustomEmoji(Cons_textCustomEmoji(documentId: _1!, alt: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_textDate(_ reader: BufferReader) -> RichText? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.RichText?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            var _3: Int32?
            _3 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.RichText.textDate(Cons_textDate(flags: _1!, text: _2!, date: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_textEmail(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            var _2: String?
            _2 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.RichText.textEmail(Cons_textEmail(text: _1!, email: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_textEmpty(_ reader: BufferReader) -> RichText? {
            return Api.RichText.textEmpty
        }
        public static func parse_textFixed(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textFixed(Cons_textFixed(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textHashtag(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textHashtag(Cons_textHashtag(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textImage(_ reader: BufferReader) -> RichText? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            _3 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.RichText.textImage(Cons_textImage(documentId: _1!, w: _2!, h: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_textItalic(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textItalic(Cons_textItalic(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textMarked(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textMarked(Cons_textMarked(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textMath(_ reader: BufferReader) -> RichText? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textMath(Cons_textMath(source: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textMention(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textMention(Cons_textMention(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textMentionName(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            var _2: Int64?
            _2 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.RichText.textMentionName(Cons_textMentionName(text: _1!, userId: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_textPhone(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            var _2: String?
            _2 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.RichText.textPhone(Cons_textPhone(text: _1!, phone: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_textPlain(_ reader: BufferReader) -> RichText? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textPlain(Cons_textPlain(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textSpoiler(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textSpoiler(Cons_textSpoiler(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textStrike(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textStrike(Cons_textStrike(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textSubscript(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textSubscript(Cons_textSubscript(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textSuperscript(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textSuperscript(Cons_textSuperscript(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textUnderline(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.RichText.textUnderline(Cons_textUnderline(text: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_textUrl(_ reader: BufferReader) -> RichText? {
            var _1: Api.RichText?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.RichText
            }
            var _2: String?
            _2 = parseString(reader)
            var _3: Int64?
            _3 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.RichText.textUrl(Cons_textUrl(text: _1!, url: _2!, webpageId: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum SavedContact: TypeConstructorDescription {
        public class Cons_savedPhoneContact: TypeConstructorDescription {
            public var phone: String
            public var firstName: String
            public var lastName: String
            public var date: Int32
            public init(phone: String, firstName: String, lastName: String, date: Int32) {
                self.phone = phone
                self.firstName = firstName
                self.lastName = lastName
                self.date = date
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("savedPhoneContact", [("phone", ConstructorParameterDescription(self.phone)), ("firstName", ConstructorParameterDescription(self.firstName)), ("lastName", ConstructorParameterDescription(self.lastName)), ("date", ConstructorParameterDescription(self.date))])
            }
        }
        case savedPhoneContact(Cons_savedPhoneContact)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .savedPhoneContact(let _data):
                if boxed {
                    buffer.appendInt32(289586518)
                }
                serializeString(_data.phone, buffer: buffer, boxed: false)
                serializeString(_data.firstName, buffer: buffer, boxed: false)
                serializeString(_data.lastName, buffer: buffer, boxed: false)
                serializeInt32(_data.date, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .savedPhoneContact(let _data):
                return ("savedPhoneContact", [("phone", ConstructorParameterDescription(_data.phone)), ("firstName", ConstructorParameterDescription(_data.firstName)), ("lastName", ConstructorParameterDescription(_data.lastName)), ("date", ConstructorParameterDescription(_data.date))])
            }
        }

        public static func parse_savedPhoneContact(_ reader: BufferReader) -> SavedContact? {
            var _1: String?
            _1 = parseString(reader)
            var _2: String?
            _2 = parseString(reader)
            var _3: String?
            _3 = parseString(reader)
            var _4: Int32?
            _4 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.SavedContact.savedPhoneContact(Cons_savedPhoneContact(phone: _1!, firstName: _2!, lastName: _3!, date: _4!))
            }
            else {
                return nil
            }
        }
    }
}
