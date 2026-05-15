public extension Api.account {
    enum ResolvedBusinessChatLinks: TypeConstructorDescription {
        public class Cons_resolvedBusinessChatLinks: TypeConstructorDescription {
            public var flags: Int32
            public var peer: Api.Peer
            public var message: String
            public var entities: [Api.MessageEntity]?
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(flags: Int32, peer: Api.Peer, message: String, entities: [Api.MessageEntity]?, chats: [Api.Chat], users: [Api.User]) {
                self.flags = flags
                self.peer = peer
                self.message = message
                self.entities = entities
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("resolvedBusinessChatLinks", [("flags", ConstructorParameterDescription(self.flags)), ("peer", ConstructorParameterDescription(self.peer)), ("message", ConstructorParameterDescription(self.message)), ("entities", ConstructorParameterDescription(self.entities)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case resolvedBusinessChatLinks(Cons_resolvedBusinessChatLinks)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .resolvedBusinessChatLinks(let _data):
                if boxed {
                    buffer.appendInt32(-1708937439)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                _data.peer.serialize(buffer, true)
                serializeString(_data.message, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.entities!.count))
                    for item in _data.entities! {
                        item.serialize(buffer, true)
                    }
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.chats.count))
                for item in _data.chats {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.users.count))
                for item in _data.users {
                    item.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .resolvedBusinessChatLinks(let _data):
                return ("resolvedBusinessChatLinks", [("flags", ConstructorParameterDescription(_data.flags)), ("peer", ConstructorParameterDescription(_data.peer)), ("message", ConstructorParameterDescription(_data.message)), ("entities", ConstructorParameterDescription(_data.entities)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_resolvedBusinessChatLinks(_ reader: BufferReader) -> ResolvedBusinessChatLinks? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.Peer?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.Peer
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: [Api.MessageEntity]?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                if let _ = reader.readInt32() {
                    _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.MessageEntity.self)
                }
            }
            var _5: [Api.Chat]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _6: [Api.User]?
            if let _ = reader.readInt32() {
                _6 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.account.ResolvedBusinessChatLinks.resolvedBusinessChatLinks(Cons_resolvedBusinessChatLinks(flags: _1!, peer: _2!, message: _3!, entities: _4, chats: _5!, users: _6!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.account {
    enum SavedMusicIds: TypeConstructorDescription {
        public class Cons_savedMusicIds: TypeConstructorDescription {
            public var ids: [Int64]
            public init(ids: [Int64]) {
                self.ids = ids
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("savedMusicIds", [("ids", ConstructorParameterDescription(self.ids))])
            }
        }
        case savedMusicIds(Cons_savedMusicIds)
        case savedMusicIdsNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .savedMusicIds(let _data):
                if boxed {
                    buffer.appendInt32(-1718786506)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.ids.count))
                for item in _data.ids {
                    serializeInt64(item, buffer: buffer, boxed: false)
                }
                break
            case .savedMusicIdsNotModified:
                if boxed {
                    buffer.appendInt32(1338514798)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .savedMusicIds(let _data):
                return ("savedMusicIds", [("ids", ConstructorParameterDescription(_data.ids))])
            case .savedMusicIdsNotModified:
                return ("savedMusicIdsNotModified", [])
            }
        }

        public static func parse_savedMusicIds(_ reader: BufferReader) -> SavedMusicIds? {
            var _1: [Int64]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 570911930, elementType: Int64.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.account.SavedMusicIds.savedMusicIds(Cons_savedMusicIds(ids: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_savedMusicIdsNotModified(_ reader: BufferReader) -> SavedMusicIds? {
            return Api.account.SavedMusicIds.savedMusicIdsNotModified
        }
    }
}
public extension Api.account {
    enum SavedRingtone: TypeConstructorDescription {
        public class Cons_savedRingtoneConverted: TypeConstructorDescription {
            public var document: Api.Document
            public init(document: Api.Document) {
                self.document = document
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("savedRingtoneConverted", [("document", ConstructorParameterDescription(self.document))])
            }
        }
        case savedRingtone
        case savedRingtoneConverted(Cons_savedRingtoneConverted)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .savedRingtone:
                if boxed {
                    buffer.appendInt32(-1222230163)
                }
                break
            case .savedRingtoneConverted(let _data):
                if boxed {
                    buffer.appendInt32(523271863)
                }
                _data.document.serialize(buffer, true)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .savedRingtone:
                return ("savedRingtone", [])
            case .savedRingtoneConverted(let _data):
                return ("savedRingtoneConverted", [("document", ConstructorParameterDescription(_data.document))])
            }
        }

        public static func parse_savedRingtone(_ reader: BufferReader) -> SavedRingtone? {
            return Api.account.SavedRingtone.savedRingtone
        }
        public static func parse_savedRingtoneConverted(_ reader: BufferReader) -> SavedRingtone? {
            var _1: Api.Document?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.Document
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.account.SavedRingtone.savedRingtoneConverted(Cons_savedRingtoneConverted(document: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.account {
    enum SavedRingtones: TypeConstructorDescription {
        public class Cons_savedRingtones: TypeConstructorDescription {
            public var hash: Int64
            public var ringtones: [Api.Document]
            public init(hash: Int64, ringtones: [Api.Document]) {
                self.hash = hash
                self.ringtones = ringtones
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("savedRingtones", [("hash", ConstructorParameterDescription(self.hash)), ("ringtones", ConstructorParameterDescription(self.ringtones))])
            }
        }
        case savedRingtones(Cons_savedRingtones)
        case savedRingtonesNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .savedRingtones(let _data):
                if boxed {
                    buffer.appendInt32(-1041683259)
                }
                serializeInt64(_data.hash, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.ringtones.count))
                for item in _data.ringtones {
                    item.serialize(buffer, true)
                }
                break
            case .savedRingtonesNotModified:
                if boxed {
                    buffer.appendInt32(-67704655)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .savedRingtones(let _data):
                return ("savedRingtones", [("hash", ConstructorParameterDescription(_data.hash)), ("ringtones", ConstructorParameterDescription(_data.ringtones))])
            case .savedRingtonesNotModified:
                return ("savedRingtonesNotModified", [])
            }
        }

        public static func parse_savedRingtones(_ reader: BufferReader) -> SavedRingtones? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: [Api.Document]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Document.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.account.SavedRingtones.savedRingtones(Cons_savedRingtones(hash: _1!, ringtones: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_savedRingtonesNotModified(_ reader: BufferReader) -> SavedRingtones? {
            return Api.account.SavedRingtones.savedRingtonesNotModified
        }
    }
}
public extension Api.account {
    enum SentEmailCode: TypeConstructorDescription {
        public class Cons_sentEmailCode: TypeConstructorDescription {
            public var emailPattern: String
            public var length: Int32
            public init(emailPattern: String, length: Int32) {
                self.emailPattern = emailPattern
                self.length = length
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentEmailCode", [("emailPattern", ConstructorParameterDescription(self.emailPattern)), ("length", ConstructorParameterDescription(self.length))])
            }
        }
        case sentEmailCode(Cons_sentEmailCode)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .sentEmailCode(let _data):
                if boxed {
                    buffer.appendInt32(-2128640689)
                }
                serializeString(_data.emailPattern, buffer: buffer, boxed: false)
                serializeInt32(_data.length, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .sentEmailCode(let _data):
                return ("sentEmailCode", [("emailPattern", ConstructorParameterDescription(_data.emailPattern)), ("length", ConstructorParameterDescription(_data.length))])
            }
        }

        public static func parse_sentEmailCode(_ reader: BufferReader) -> SentEmailCode? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int32?
            _2 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.account.SentEmailCode.sentEmailCode(Cons_sentEmailCode(emailPattern: _1!, length: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.account {
    enum Takeout: TypeConstructorDescription {
        public class Cons_takeout: TypeConstructorDescription {
            public var id: Int64
            public init(id: Int64) {
                self.id = id
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("takeout", [("id", ConstructorParameterDescription(self.id))])
            }
        }
        case takeout(Cons_takeout)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .takeout(let _data):
                if boxed {
                    buffer.appendInt32(1304052993)
                }
                serializeInt64(_data.id, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .takeout(let _data):
                return ("takeout", [("id", ConstructorParameterDescription(_data.id))])
            }
        }

        public static func parse_takeout(_ reader: BufferReader) -> Takeout? {
            var _1: Int64?
            _1 = reader.readInt64()
            let _c1 = _1 != nil
            if _c1 {
                return Api.account.Takeout.takeout(Cons_takeout(id: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.account {
    enum Themes: TypeConstructorDescription {
        public class Cons_themes: TypeConstructorDescription {
            public var hash: Int64
            public var themes: [Api.Theme]
            public init(hash: Int64, themes: [Api.Theme]) {
                self.hash = hash
                self.themes = themes
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("themes", [("hash", ConstructorParameterDescription(self.hash)), ("themes", ConstructorParameterDescription(self.themes))])
            }
        }
        case themes(Cons_themes)
        case themesNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .themes(let _data):
                if boxed {
                    buffer.appendInt32(-1707242387)
                }
                serializeInt64(_data.hash, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.themes.count))
                for item in _data.themes {
                    item.serialize(buffer, true)
                }
                break
            case .themesNotModified:
                if boxed {
                    buffer.appendInt32(-199313886)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .themes(let _data):
                return ("themes", [("hash", ConstructorParameterDescription(_data.hash)), ("themes", ConstructorParameterDescription(_data.themes))])
            case .themesNotModified:
                return ("themesNotModified", [])
            }
        }

        public static func parse_themes(_ reader: BufferReader) -> Themes? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: [Api.Theme]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Theme.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.account.Themes.themes(Cons_themes(hash: _1!, themes: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_themesNotModified(_ reader: BufferReader) -> Themes? {
            return Api.account.Themes.themesNotModified
        }
    }
}
public extension Api.account {
    enum TmpPassword: TypeConstructorDescription {
        public class Cons_tmpPassword: TypeConstructorDescription {
            public var tmpPassword: Buffer
            public var validUntil: Int32
            public init(tmpPassword: Buffer, validUntil: Int32) {
                self.tmpPassword = tmpPassword
                self.validUntil = validUntil
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("tmpPassword", [("tmpPassword", ConstructorParameterDescription(self.tmpPassword)), ("validUntil", ConstructorParameterDescription(self.validUntil))])
            }
        }
        case tmpPassword(Cons_tmpPassword)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .tmpPassword(let _data):
                if boxed {
                    buffer.appendInt32(-614138572)
                }
                serializeBytes(_data.tmpPassword, buffer: buffer, boxed: false)
                serializeInt32(_data.validUntil, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .tmpPassword(let _data):
                return ("tmpPassword", [("tmpPassword", ConstructorParameterDescription(_data.tmpPassword)), ("validUntil", ConstructorParameterDescription(_data.validUntil))])
            }
        }

        public static func parse_tmpPassword(_ reader: BufferReader) -> TmpPassword? {
            var _1: Buffer?
            _1 = parseBytes(reader)
            var _2: Int32?
            _2 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.account.TmpPassword.tmpPassword(Cons_tmpPassword(tmpPassword: _1!, validUntil: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.account {
    enum WallPapers: TypeConstructorDescription {
        public class Cons_wallPapers: TypeConstructorDescription {
            public var hash: Int64
            public var wallpapers: [Api.WallPaper]
            public init(hash: Int64, wallpapers: [Api.WallPaper]) {
                self.hash = hash
                self.wallpapers = wallpapers
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("wallPapers", [("hash", ConstructorParameterDescription(self.hash)), ("wallpapers", ConstructorParameterDescription(self.wallpapers))])
            }
        }
        case wallPapers(Cons_wallPapers)
        case wallPapersNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .wallPapers(let _data):
                if boxed {
                    buffer.appendInt32(-842824308)
                }
                serializeInt64(_data.hash, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.wallpapers.count))
                for item in _data.wallpapers {
                    item.serialize(buffer, true)
                }
                break
            case .wallPapersNotModified:
                if boxed {
                    buffer.appendInt32(471437699)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .wallPapers(let _data):
                return ("wallPapers", [("hash", ConstructorParameterDescription(_data.hash)), ("wallpapers", ConstructorParameterDescription(_data.wallpapers))])
            case .wallPapersNotModified:
                return ("wallPapersNotModified", [])
            }
        }

        public static func parse_wallPapers(_ reader: BufferReader) -> WallPapers? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: [Api.WallPaper]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.WallPaper.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.account.WallPapers.wallPapers(Cons_wallPapers(hash: _1!, wallpapers: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_wallPapersNotModified(_ reader: BufferReader) -> WallPapers? {
            return Api.account.WallPapers.wallPapersNotModified
        }
    }
}
public extension Api.account {
    enum WebAuthorizations: TypeConstructorDescription {
        public class Cons_webAuthorizations: TypeConstructorDescription {
            public var authorizations: [Api.WebAuthorization]
            public var users: [Api.User]
            public init(authorizations: [Api.WebAuthorization], users: [Api.User]) {
                self.authorizations = authorizations
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("webAuthorizations", [("authorizations", ConstructorParameterDescription(self.authorizations)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case webAuthorizations(Cons_webAuthorizations)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .webAuthorizations(let _data):
                if boxed {
                    buffer.appendInt32(-313079300)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.authorizations.count))
                for item in _data.authorizations {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.users.count))
                for item in _data.users {
                    item.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .webAuthorizations(let _data):
                return ("webAuthorizations", [("authorizations", ConstructorParameterDescription(_data.authorizations)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_webAuthorizations(_ reader: BufferReader) -> WebAuthorizations? {
            var _1: [Api.WebAuthorization]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.WebAuthorization.self)
            }
            var _2: [Api.User]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.account.WebAuthorizations.webAuthorizations(Cons_webAuthorizations(authorizations: _1!, users: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.aicompose {
    enum Tones: TypeConstructorDescription {
        public class Cons_tones: TypeConstructorDescription {
            public var hash: Int64
            public var tones: [Api.AiComposeTone]
            public var users: [Api.User]
            public init(hash: Int64, tones: [Api.AiComposeTone], users: [Api.User]) {
                self.hash = hash
                self.tones = tones
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("tones", [("hash", ConstructorParameterDescription(self.hash)), ("tones", ConstructorParameterDescription(self.tones)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case tones(Cons_tones)
        case tonesNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .tones(let _data):
                if boxed {
                    buffer.appendInt32(1822232318)
                }
                serializeInt64(_data.hash, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.tones.count))
                for item in _data.tones {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.users.count))
                for item in _data.users {
                    item.serialize(buffer, true)
                }
                break
            case .tonesNotModified:
                if boxed {
                    buffer.appendInt32(-1040948989)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .tones(let _data):
                return ("tones", [("hash", ConstructorParameterDescription(_data.hash)), ("tones", ConstructorParameterDescription(_data.tones)), ("users", ConstructorParameterDescription(_data.users))])
            case .tonesNotModified:
                return ("tonesNotModified", [])
            }
        }

        public static func parse_tones(_ reader: BufferReader) -> Tones? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: [Api.AiComposeTone]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.AiComposeTone.self)
            }
            var _3: [Api.User]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.aicompose.Tones.tones(Cons_tones(hash: _1!, tones: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_tonesNotModified(_ reader: BufferReader) -> Tones? {
            return Api.aicompose.Tones.tonesNotModified
        }
    }
}
public extension Api.auth {
    enum Authorization: TypeConstructorDescription {
        public class Cons_authorization: TypeConstructorDescription {
            public var flags: Int32
            public var otherwiseReloginDays: Int32?
            public var tmpSessions: Int32?
            public var futureAuthToken: Buffer?
            public var user: Api.User
            public init(flags: Int32, otherwiseReloginDays: Int32?, tmpSessions: Int32?, futureAuthToken: Buffer?, user: Api.User) {
                self.flags = flags
                self.otherwiseReloginDays = otherwiseReloginDays
                self.tmpSessions = tmpSessions
                self.futureAuthToken = futureAuthToken
                self.user = user
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("authorization", [("flags", ConstructorParameterDescription(self.flags)), ("otherwiseReloginDays", ConstructorParameterDescription(self.otherwiseReloginDays)), ("tmpSessions", ConstructorParameterDescription(self.tmpSessions)), ("futureAuthToken", ConstructorParameterDescription(self.futureAuthToken)), ("user", ConstructorParameterDescription(self.user))])
            }
        }
        public class Cons_authorizationSignUpRequired: TypeConstructorDescription {
            public var flags: Int32
            public var termsOfService: Api.help.TermsOfService?
            public init(flags: Int32, termsOfService: Api.help.TermsOfService?) {
                self.flags = flags
                self.termsOfService = termsOfService
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("authorizationSignUpRequired", [("flags", ConstructorParameterDescription(self.flags)), ("termsOfService", ConstructorParameterDescription(self.termsOfService))])
            }
        }
        case authorization(Cons_authorization)
        case authorizationSignUpRequired(Cons_authorizationSignUpRequired)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .authorization(let _data):
                if boxed {
                    buffer.appendInt32(782418132)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeInt32(_data.otherwiseReloginDays!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeInt32(_data.tmpSessions!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeBytes(_data.futureAuthToken!, buffer: buffer, boxed: false)
                }
                _data.user.serialize(buffer, true)
                break
            case .authorizationSignUpRequired(let _data):
                if boxed {
                    buffer.appendInt32(1148485274)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    _data.termsOfService!.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .authorization(let _data):
                return ("authorization", [("flags", ConstructorParameterDescription(_data.flags)), ("otherwiseReloginDays", ConstructorParameterDescription(_data.otherwiseReloginDays)), ("tmpSessions", ConstructorParameterDescription(_data.tmpSessions)), ("futureAuthToken", ConstructorParameterDescription(_data.futureAuthToken)), ("user", ConstructorParameterDescription(_data.user))])
            case .authorizationSignUpRequired(let _data):
                return ("authorizationSignUpRequired", [("flags", ConstructorParameterDescription(_data.flags)), ("termsOfService", ConstructorParameterDescription(_data.termsOfService))])
            }
        }

        public static func parse_authorization(_ reader: BufferReader) -> Authorization? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _2 = reader.readInt32()
            }
            var _3: Int32?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _3 = reader.readInt32()
            }
            var _4: Buffer?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _4 = parseBytes(reader)
            }
            var _5: Api.User?
            if let signature = reader.readInt32() {
                _5 = Api.parse(reader, signature: signature) as? Api.User
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.auth.Authorization.authorization(Cons_authorization(flags: _1!, otherwiseReloginDays: _2, tmpSessions: _3, futureAuthToken: _4, user: _5!))
            }
            else {
                return nil
            }
        }
        public static func parse_authorizationSignUpRequired(_ reader: BufferReader) -> Authorization? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.help.TermsOfService?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.help.TermsOfService
                }
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _2 != nil
            if _c1 && _c2 {
                return Api.auth.Authorization.authorizationSignUpRequired(Cons_authorizationSignUpRequired(flags: _1!, termsOfService: _2))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.auth {
    enum CodeType: TypeConstructorDescription {
        case codeTypeCall
        case codeTypeFlashCall
        case codeTypeFragmentSms
        case codeTypeMissedCall
        case codeTypeSms

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .codeTypeCall:
                if boxed {
                    buffer.appendInt32(1948046307)
                }
                break
            case .codeTypeFlashCall:
                if boxed {
                    buffer.appendInt32(577556219)
                }
                break
            case .codeTypeFragmentSms:
                if boxed {
                    buffer.appendInt32(116234636)
                }
                break
            case .codeTypeMissedCall:
                if boxed {
                    buffer.appendInt32(-702884114)
                }
                break
            case .codeTypeSms:
                if boxed {
                    buffer.appendInt32(1923290508)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .codeTypeCall:
                return ("codeTypeCall", [])
            case .codeTypeFlashCall:
                return ("codeTypeFlashCall", [])
            case .codeTypeFragmentSms:
                return ("codeTypeFragmentSms", [])
            case .codeTypeMissedCall:
                return ("codeTypeMissedCall", [])
            case .codeTypeSms:
                return ("codeTypeSms", [])
            }
        }

        public static func parse_codeTypeCall(_ reader: BufferReader) -> CodeType? {
            return Api.auth.CodeType.codeTypeCall
        }
        public static func parse_codeTypeFlashCall(_ reader: BufferReader) -> CodeType? {
            return Api.auth.CodeType.codeTypeFlashCall
        }
        public static func parse_codeTypeFragmentSms(_ reader: BufferReader) -> CodeType? {
            return Api.auth.CodeType.codeTypeFragmentSms
        }
        public static func parse_codeTypeMissedCall(_ reader: BufferReader) -> CodeType? {
            return Api.auth.CodeType.codeTypeMissedCall
        }
        public static func parse_codeTypeSms(_ reader: BufferReader) -> CodeType? {
            return Api.auth.CodeType.codeTypeSms
        }
    }
}
public extension Api.auth {
    enum ExportedAuthorization: TypeConstructorDescription {
        public class Cons_exportedAuthorization: TypeConstructorDescription {
            public var id: Int64
            public var bytes: Buffer
            public init(id: Int64, bytes: Buffer) {
                self.id = id
                self.bytes = bytes
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("exportedAuthorization", [("id", ConstructorParameterDescription(self.id)), ("bytes", ConstructorParameterDescription(self.bytes))])
            }
        }
        case exportedAuthorization(Cons_exportedAuthorization)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .exportedAuthorization(let _data):
                if boxed {
                    buffer.appendInt32(-1271602504)
                }
                serializeInt64(_data.id, buffer: buffer, boxed: false)
                serializeBytes(_data.bytes, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .exportedAuthorization(let _data):
                return ("exportedAuthorization", [("id", ConstructorParameterDescription(_data.id)), ("bytes", ConstructorParameterDescription(_data.bytes))])
            }
        }

        public static func parse_exportedAuthorization(_ reader: BufferReader) -> ExportedAuthorization? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: Buffer?
            _2 = parseBytes(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.auth.ExportedAuthorization.exportedAuthorization(Cons_exportedAuthorization(id: _1!, bytes: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.auth {
    enum LoggedOut: TypeConstructorDescription {
        public class Cons_loggedOut: TypeConstructorDescription {
            public var flags: Int32
            public var futureAuthToken: Buffer?
            public init(flags: Int32, futureAuthToken: Buffer?) {
                self.flags = flags
                self.futureAuthToken = futureAuthToken
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("loggedOut", [("flags", ConstructorParameterDescription(self.flags)), ("futureAuthToken", ConstructorParameterDescription(self.futureAuthToken))])
            }
        }
        case loggedOut(Cons_loggedOut)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .loggedOut(let _data):
                if boxed {
                    buffer.appendInt32(-1012759713)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeBytes(_data.futureAuthToken!, buffer: buffer, boxed: false)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .loggedOut(let _data):
                return ("loggedOut", [("flags", ConstructorParameterDescription(_data.flags)), ("futureAuthToken", ConstructorParameterDescription(_data.futureAuthToken))])
            }
        }

        public static func parse_loggedOut(_ reader: BufferReader) -> LoggedOut? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Buffer?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _2 = parseBytes(reader)
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _2 != nil
            if _c1 && _c2 {
                return Api.auth.LoggedOut.loggedOut(Cons_loggedOut(flags: _1!, futureAuthToken: _2))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.auth {
    enum LoginToken: TypeConstructorDescription {
        public class Cons_loginToken: TypeConstructorDescription {
            public var expires: Int32
            public var token: Buffer
            public init(expires: Int32, token: Buffer) {
                self.expires = expires
                self.token = token
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("loginToken", [("expires", ConstructorParameterDescription(self.expires)), ("token", ConstructorParameterDescription(self.token))])
            }
        }
        public class Cons_loginTokenMigrateTo: TypeConstructorDescription {
            public var dcId: Int32
            public var token: Buffer
            public init(dcId: Int32, token: Buffer) {
                self.dcId = dcId
                self.token = token
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("loginTokenMigrateTo", [("dcId", ConstructorParameterDescription(self.dcId)), ("token", ConstructorParameterDescription(self.token))])
            }
        }
        public class Cons_loginTokenSuccess: TypeConstructorDescription {
            public var authorization: Api.auth.Authorization
            public init(authorization: Api.auth.Authorization) {
                self.authorization = authorization
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("loginTokenSuccess", [("authorization", ConstructorParameterDescription(self.authorization))])
            }
        }
        case loginToken(Cons_loginToken)
        case loginTokenMigrateTo(Cons_loginTokenMigrateTo)
        case loginTokenSuccess(Cons_loginTokenSuccess)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .loginToken(let _data):
                if boxed {
                    buffer.appendInt32(1654593920)
                }
                serializeInt32(_data.expires, buffer: buffer, boxed: false)
                serializeBytes(_data.token, buffer: buffer, boxed: false)
                break
            case .loginTokenMigrateTo(let _data):
                if boxed {
                    buffer.appendInt32(110008598)
                }
                serializeInt32(_data.dcId, buffer: buffer, boxed: false)
                serializeBytes(_data.token, buffer: buffer, boxed: false)
                break
            case .loginTokenSuccess(let _data):
                if boxed {
                    buffer.appendInt32(957176926)
                }
                _data.authorization.serialize(buffer, true)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .loginToken(let _data):
                return ("loginToken", [("expires", ConstructorParameterDescription(_data.expires)), ("token", ConstructorParameterDescription(_data.token))])
            case .loginTokenMigrateTo(let _data):
                return ("loginTokenMigrateTo", [("dcId", ConstructorParameterDescription(_data.dcId)), ("token", ConstructorParameterDescription(_data.token))])
            case .loginTokenSuccess(let _data):
                return ("loginTokenSuccess", [("authorization", ConstructorParameterDescription(_data.authorization))])
            }
        }

        public static func parse_loginToken(_ reader: BufferReader) -> LoginToken? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Buffer?
            _2 = parseBytes(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.auth.LoginToken.loginToken(Cons_loginToken(expires: _1!, token: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_loginTokenMigrateTo(_ reader: BufferReader) -> LoginToken? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Buffer?
            _2 = parseBytes(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.auth.LoginToken.loginTokenMigrateTo(Cons_loginTokenMigrateTo(dcId: _1!, token: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_loginTokenSuccess(_ reader: BufferReader) -> LoginToken? {
            var _1: Api.auth.Authorization?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.auth.Authorization
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.auth.LoginToken.loginTokenSuccess(Cons_loginTokenSuccess(authorization: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.auth {
    enum PasskeyLoginOptions: TypeConstructorDescription {
        public class Cons_passkeyLoginOptions: TypeConstructorDescription {
            public var options: Api.DataJSON
            public init(options: Api.DataJSON) {
                self.options = options
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("passkeyLoginOptions", [("options", ConstructorParameterDescription(self.options))])
            }
        }
        case passkeyLoginOptions(Cons_passkeyLoginOptions)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .passkeyLoginOptions(let _data):
                if boxed {
                    buffer.appendInt32(-503089271)
                }
                _data.options.serialize(buffer, true)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .passkeyLoginOptions(let _data):
                return ("passkeyLoginOptions", [("options", ConstructorParameterDescription(_data.options))])
            }
        }

        public static func parse_passkeyLoginOptions(_ reader: BufferReader) -> PasskeyLoginOptions? {
            var _1: Api.DataJSON?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.DataJSON
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.auth.PasskeyLoginOptions.passkeyLoginOptions(Cons_passkeyLoginOptions(options: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.auth {
    enum PasswordRecovery: TypeConstructorDescription {
        public class Cons_passwordRecovery: TypeConstructorDescription {
            public var emailPattern: String
            public init(emailPattern: String) {
                self.emailPattern = emailPattern
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("passwordRecovery", [("emailPattern", ConstructorParameterDescription(self.emailPattern))])
            }
        }
        case passwordRecovery(Cons_passwordRecovery)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .passwordRecovery(let _data):
                if boxed {
                    buffer.appendInt32(326715557)
                }
                serializeString(_data.emailPattern, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .passwordRecovery(let _data):
                return ("passwordRecovery", [("emailPattern", ConstructorParameterDescription(_data.emailPattern))])
            }
        }

        public static func parse_passwordRecovery(_ reader: BufferReader) -> PasswordRecovery? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.auth.PasswordRecovery.passwordRecovery(Cons_passwordRecovery(emailPattern: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.auth {
    enum SentCode: TypeConstructorDescription {
        public class Cons_sentCode: TypeConstructorDescription {
            public var flags: Int32
            public var type: Api.auth.SentCodeType
            public var phoneCodeHash: String
            public var nextType: Api.auth.CodeType?
            public var timeout: Int32?
            public init(flags: Int32, type: Api.auth.SentCodeType, phoneCodeHash: String, nextType: Api.auth.CodeType?, timeout: Int32?) {
                self.flags = flags
                self.type = type
                self.phoneCodeHash = phoneCodeHash
                self.nextType = nextType
                self.timeout = timeout
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCode", [("flags", ConstructorParameterDescription(self.flags)), ("type", ConstructorParameterDescription(self.type)), ("phoneCodeHash", ConstructorParameterDescription(self.phoneCodeHash)), ("nextType", ConstructorParameterDescription(self.nextType)), ("timeout", ConstructorParameterDescription(self.timeout))])
            }
        }
        public class Cons_sentCodePaymentRequired: TypeConstructorDescription {
            public var storeProduct: String
            public var phoneCodeHash: String
            public var supportEmailAddress: String
            public var supportEmailSubject: String
            public var premiumDays: Int32
            public var currency: String
            public var amount: Int64
            public init(storeProduct: String, phoneCodeHash: String, supportEmailAddress: String, supportEmailSubject: String, premiumDays: Int32, currency: String, amount: Int64) {
                self.storeProduct = storeProduct
                self.phoneCodeHash = phoneCodeHash
                self.supportEmailAddress = supportEmailAddress
                self.supportEmailSubject = supportEmailSubject
                self.premiumDays = premiumDays
                self.currency = currency
                self.amount = amount
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCodePaymentRequired", [("storeProduct", ConstructorParameterDescription(self.storeProduct)), ("phoneCodeHash", ConstructorParameterDescription(self.phoneCodeHash)), ("supportEmailAddress", ConstructorParameterDescription(self.supportEmailAddress)), ("supportEmailSubject", ConstructorParameterDescription(self.supportEmailSubject)), ("premiumDays", ConstructorParameterDescription(self.premiumDays)), ("currency", ConstructorParameterDescription(self.currency)), ("amount", ConstructorParameterDescription(self.amount))])
            }
        }
        public class Cons_sentCodeSuccess: TypeConstructorDescription {
            public var authorization: Api.auth.Authorization
            public init(authorization: Api.auth.Authorization) {
                self.authorization = authorization
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCodeSuccess", [("authorization", ConstructorParameterDescription(self.authorization))])
            }
        }
        case sentCode(Cons_sentCode)
        case sentCodePaymentRequired(Cons_sentCodePaymentRequired)
        case sentCodeSuccess(Cons_sentCodeSuccess)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .sentCode(let _data):
                if boxed {
                    buffer.appendInt32(1577067778)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                _data.type.serialize(buffer, true)
                serializeString(_data.phoneCodeHash, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    _data.nextType!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeInt32(_data.timeout!, buffer: buffer, boxed: false)
                }
                break
            case .sentCodePaymentRequired(let _data):
                if boxed {
                    buffer.appendInt32(-125665601)
                }
                serializeString(_data.storeProduct, buffer: buffer, boxed: false)
                serializeString(_data.phoneCodeHash, buffer: buffer, boxed: false)
                serializeString(_data.supportEmailAddress, buffer: buffer, boxed: false)
                serializeString(_data.supportEmailSubject, buffer: buffer, boxed: false)
                serializeInt32(_data.premiumDays, buffer: buffer, boxed: false)
                serializeString(_data.currency, buffer: buffer, boxed: false)
                serializeInt64(_data.amount, buffer: buffer, boxed: false)
                break
            case .sentCodeSuccess(let _data):
                if boxed {
                    buffer.appendInt32(596704836)
                }
                _data.authorization.serialize(buffer, true)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .sentCode(let _data):
                return ("sentCode", [("flags", ConstructorParameterDescription(_data.flags)), ("type", ConstructorParameterDescription(_data.type)), ("phoneCodeHash", ConstructorParameterDescription(_data.phoneCodeHash)), ("nextType", ConstructorParameterDescription(_data.nextType)), ("timeout", ConstructorParameterDescription(_data.timeout))])
            case .sentCodePaymentRequired(let _data):
                return ("sentCodePaymentRequired", [("storeProduct", ConstructorParameterDescription(_data.storeProduct)), ("phoneCodeHash", ConstructorParameterDescription(_data.phoneCodeHash)), ("supportEmailAddress", ConstructorParameterDescription(_data.supportEmailAddress)), ("supportEmailSubject", ConstructorParameterDescription(_data.supportEmailSubject)), ("premiumDays", ConstructorParameterDescription(_data.premiumDays)), ("currency", ConstructorParameterDescription(_data.currency)), ("amount", ConstructorParameterDescription(_data.amount))])
            case .sentCodeSuccess(let _data):
                return ("sentCodeSuccess", [("authorization", ConstructorParameterDescription(_data.authorization))])
            }
        }

        public static func parse_sentCode(_ reader: BufferReader) -> SentCode? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.auth.SentCodeType?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.auth.SentCodeType
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: Api.auth.CodeType?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let signature = reader.readInt32() {
                    _4 = Api.parse(reader, signature: signature) as? Api.auth.CodeType
                }
            }
            var _5: Int32?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _5 = reader.readInt32()
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.auth.SentCode.sentCode(Cons_sentCode(flags: _1!, type: _2!, phoneCodeHash: _3!, nextType: _4, timeout: _5))
            }
            else {
                return nil
            }
        }
        public static func parse_sentCodePaymentRequired(_ reader: BufferReader) -> SentCode? {
            var _1: String?
            _1 = parseString(reader)
            var _2: String?
            _2 = parseString(reader)
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            _4 = parseString(reader)
            var _5: Int32?
            _5 = reader.readInt32()
            var _6: String?
            _6 = parseString(reader)
            var _7: Int64?
            _7 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            let _c7 = _7 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 {
                return Api.auth.SentCode.sentCodePaymentRequired(Cons_sentCodePaymentRequired(storeProduct: _1!, phoneCodeHash: _2!, supportEmailAddress: _3!, supportEmailSubject: _4!, premiumDays: _5!, currency: _6!, amount: _7!))
            }
            else {
                return nil
            }
        }
        public static func parse_sentCodeSuccess(_ reader: BufferReader) -> SentCode? {
            var _1: Api.auth.Authorization?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.auth.Authorization
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.auth.SentCode.sentCodeSuccess(Cons_sentCodeSuccess(authorization: _1!))
            }
            else {
                return nil
            }
        }
    }
}
