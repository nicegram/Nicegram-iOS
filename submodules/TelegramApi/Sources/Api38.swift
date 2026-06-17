public extension Api.messages {
    enum SentEncryptedMessage: TypeConstructorDescription {
        public class Cons_sentEncryptedFile: TypeConstructorDescription {
            public var date: Int32
            public var file: Api.EncryptedFile
            public init(date: Int32, file: Api.EncryptedFile) {
                self.date = date
                self.file = file
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentEncryptedFile", [("date", ConstructorParameterDescription(self.date)), ("file", ConstructorParameterDescription(self.file))])
            }
        }
        public class Cons_sentEncryptedMessage: TypeConstructorDescription {
            public var date: Int32
            public init(date: Int32) {
                self.date = date
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentEncryptedMessage", [("date", ConstructorParameterDescription(self.date))])
            }
        }
        case sentEncryptedFile(Cons_sentEncryptedFile)
        case sentEncryptedMessage(Cons_sentEncryptedMessage)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .sentEncryptedFile(let _data):
                if boxed {
                    buffer.appendInt32(-1802240206)
                }
                serializeInt32(_data.date, buffer: buffer, boxed: false)
                _data.file.serialize(buffer, true)
                break
            case .sentEncryptedMessage(let _data):
                if boxed {
                    buffer.appendInt32(1443858741)
                }
                serializeInt32(_data.date, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .sentEncryptedFile(let _data):
                return ("sentEncryptedFile", [("date", ConstructorParameterDescription(_data.date)), ("file", ConstructorParameterDescription(_data.file))])
            case .sentEncryptedMessage(let _data):
                return ("sentEncryptedMessage", [("date", ConstructorParameterDescription(_data.date))])
            }
        }

        public static func parse_sentEncryptedFile(_ reader: BufferReader) -> SentEncryptedMessage? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.EncryptedFile?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.EncryptedFile
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.SentEncryptedMessage.sentEncryptedFile(Cons_sentEncryptedFile(date: _1!, file: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_sentEncryptedMessage(_ reader: BufferReader) -> SentEncryptedMessage? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.messages.SentEncryptedMessage.sentEncryptedMessage(Cons_sentEncryptedMessage(date: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum SponsoredMessages: TypeConstructorDescription {
        public class Cons_sponsoredMessages: TypeConstructorDescription {
            public var flags: Int32
            public var postsBetween: Int32?
            public var startDelay: Int32?
            public var betweenDelay: Int32?
            public var messages: [Api.SponsoredMessage]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(flags: Int32, postsBetween: Int32?, startDelay: Int32?, betweenDelay: Int32?, messages: [Api.SponsoredMessage], chats: [Api.Chat], users: [Api.User]) {
                self.flags = flags
                self.postsBetween = postsBetween
                self.startDelay = startDelay
                self.betweenDelay = betweenDelay
                self.messages = messages
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sponsoredMessages", [("flags", ConstructorParameterDescription(self.flags)), ("postsBetween", ConstructorParameterDescription(self.postsBetween)), ("startDelay", ConstructorParameterDescription(self.startDelay)), ("betweenDelay", ConstructorParameterDescription(self.betweenDelay)), ("messages", ConstructorParameterDescription(self.messages)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case sponsoredMessages(Cons_sponsoredMessages)
        case sponsoredMessagesEmpty

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .sponsoredMessages(let _data):
                if boxed {
                    buffer.appendInt32(-2464403)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeInt32(_data.postsBetween!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeInt32(_data.startDelay!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeInt32(_data.betweenDelay!, buffer: buffer, boxed: false)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.messages.count))
                for item in _data.messages {
                    item.serialize(buffer, true)
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
            case .sponsoredMessagesEmpty:
                if boxed {
                    buffer.appendInt32(406407439)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .sponsoredMessages(let _data):
                return ("sponsoredMessages", [("flags", ConstructorParameterDescription(_data.flags)), ("postsBetween", ConstructorParameterDescription(_data.postsBetween)), ("startDelay", ConstructorParameterDescription(_data.startDelay)), ("betweenDelay", ConstructorParameterDescription(_data.betweenDelay)), ("messages", ConstructorParameterDescription(_data.messages)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            case .sponsoredMessagesEmpty:
                return ("sponsoredMessagesEmpty", [])
            }
        }

        public static func parse_sponsoredMessages(_ reader: BufferReader) -> SponsoredMessages? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _2 = reader.readInt32()
            }
            var _3: Int32?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _3 = reader.readInt32()
            }
            var _4: Int32?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _4 = reader.readInt32()
            }
            var _5: [Api.SponsoredMessage]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.SponsoredMessage.self)
            }
            var _6: [Api.Chat]?
            if let _ = reader.readInt32() {
                _6 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _7: [Api.User]?
            if let _ = reader.readInt32() {
                _7 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            let _c7 = _7 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 {
                return Api.messages.SponsoredMessages.sponsoredMessages(Cons_sponsoredMessages(flags: _1!, postsBetween: _2, startDelay: _3, betweenDelay: _4, messages: _5!, chats: _6!, users: _7!))
            }
            else {
                return nil
            }
        }
        public static func parse_sponsoredMessagesEmpty(_ reader: BufferReader) -> SponsoredMessages? {
            return Api.messages.SponsoredMessages.sponsoredMessagesEmpty
        }
    }
}
public extension Api.messages {
    enum StickerSet: TypeConstructorDescription {
        public class Cons_stickerSet: TypeConstructorDescription {
            public var set: Api.StickerSet
            public var packs: [Api.StickerPack]
            public var keywords: [Api.StickerKeyword]
            public var documents: [Api.Document]
            public init(set: Api.StickerSet, packs: [Api.StickerPack], keywords: [Api.StickerKeyword], documents: [Api.Document]) {
                self.set = set
                self.packs = packs
                self.keywords = keywords
                self.documents = documents
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("stickerSet", [("set", ConstructorParameterDescription(self.set)), ("packs", ConstructorParameterDescription(self.packs)), ("keywords", ConstructorParameterDescription(self.keywords)), ("documents", ConstructorParameterDescription(self.documents))])
            }
        }
        case stickerSet(Cons_stickerSet)
        case stickerSetNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .stickerSet(let _data):
                if boxed {
                    buffer.appendInt32(1846886166)
                }
                _data.set.serialize(buffer, true)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.packs.count))
                for item in _data.packs {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.keywords.count))
                for item in _data.keywords {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.documents.count))
                for item in _data.documents {
                    item.serialize(buffer, true)
                }
                break
            case .stickerSetNotModified:
                if boxed {
                    buffer.appendInt32(-738646805)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .stickerSet(let _data):
                return ("stickerSet", [("set", ConstructorParameterDescription(_data.set)), ("packs", ConstructorParameterDescription(_data.packs)), ("keywords", ConstructorParameterDescription(_data.keywords)), ("documents", ConstructorParameterDescription(_data.documents))])
            case .stickerSetNotModified:
                return ("stickerSetNotModified", [])
            }
        }

        public static func parse_stickerSet(_ reader: BufferReader) -> StickerSet? {
            var _1: Api.StickerSet?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.StickerSet
            }
            var _2: [Api.StickerPack]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerPack.self)
            }
            var _3: [Api.StickerKeyword]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerKeyword.self)
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
                return Api.messages.StickerSet.stickerSet(Cons_stickerSet(set: _1!, packs: _2!, keywords: _3!, documents: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_stickerSetNotModified(_ reader: BufferReader) -> StickerSet? {
            return Api.messages.StickerSet.stickerSetNotModified
        }
    }
}
public extension Api.messages {
    enum StickerSetInstallResult: TypeConstructorDescription {
        public class Cons_stickerSetInstallResultArchive: TypeConstructorDescription {
            public var sets: [Api.StickerSetCovered]
            public init(sets: [Api.StickerSetCovered]) {
                self.sets = sets
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("stickerSetInstallResultArchive", [("sets", ConstructorParameterDescription(self.sets))])
            }
        }
        case stickerSetInstallResultArchive(Cons_stickerSetInstallResultArchive)
        case stickerSetInstallResultSuccess

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .stickerSetInstallResultArchive(let _data):
                if boxed {
                    buffer.appendInt32(904138920)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.sets.count))
                for item in _data.sets {
                    item.serialize(buffer, true)
                }
                break
            case .stickerSetInstallResultSuccess:
                if boxed {
                    buffer.appendInt32(946083368)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .stickerSetInstallResultArchive(let _data):
                return ("stickerSetInstallResultArchive", [("sets", ConstructorParameterDescription(_data.sets))])
            case .stickerSetInstallResultSuccess:
                return ("stickerSetInstallResultSuccess", [])
            }
        }

        public static func parse_stickerSetInstallResultArchive(_ reader: BufferReader) -> StickerSetInstallResult? {
            var _1: [Api.StickerSetCovered]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerSetCovered.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.messages.StickerSetInstallResult.stickerSetInstallResultArchive(Cons_stickerSetInstallResultArchive(sets: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_stickerSetInstallResultSuccess(_ reader: BufferReader) -> StickerSetInstallResult? {
            return Api.messages.StickerSetInstallResult.stickerSetInstallResultSuccess
        }
    }
}
public extension Api.messages {
    enum Stickers: TypeConstructorDescription {
        public class Cons_stickers: TypeConstructorDescription {
            public var hash: Int64
            public var stickers: [Api.Document]
            public init(hash: Int64, stickers: [Api.Document]) {
                self.hash = hash
                self.stickers = stickers
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("stickers", [("hash", ConstructorParameterDescription(self.hash)), ("stickers", ConstructorParameterDescription(self.stickers))])
            }
        }
        case stickers(Cons_stickers)
        case stickersNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .stickers(let _data):
                if boxed {
                    buffer.appendInt32(816245886)
                }
                serializeInt64(_data.hash, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.stickers.count))
                for item in _data.stickers {
                    item.serialize(buffer, true)
                }
                break
            case .stickersNotModified:
                if boxed {
                    buffer.appendInt32(-244016606)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .stickers(let _data):
                return ("stickers", [("hash", ConstructorParameterDescription(_data.hash)), ("stickers", ConstructorParameterDescription(_data.stickers))])
            case .stickersNotModified:
                return ("stickersNotModified", [])
            }
        }

        public static func parse_stickers(_ reader: BufferReader) -> Stickers? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: [Api.Document]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Document.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.Stickers.stickers(Cons_stickers(hash: _1!, stickers: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_stickersNotModified(_ reader: BufferReader) -> Stickers? {
            return Api.messages.Stickers.stickersNotModified
        }
    }
}
public extension Api.messages {
    enum TranscribedAudio: TypeConstructorDescription {
        public class Cons_transcribedAudio: TypeConstructorDescription {
            public var flags: Int32
            public var transcriptionId: Int64
            public var text: String
            public var trialRemainsNum: Int32?
            public var trialRemainsUntilDate: Int32?
            public init(flags: Int32, transcriptionId: Int64, text: String, trialRemainsNum: Int32?, trialRemainsUntilDate: Int32?) {
                self.flags = flags
                self.transcriptionId = transcriptionId
                self.text = text
                self.trialRemainsNum = trialRemainsNum
                self.trialRemainsUntilDate = trialRemainsUntilDate
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("transcribedAudio", [("flags", ConstructorParameterDescription(self.flags)), ("transcriptionId", ConstructorParameterDescription(self.transcriptionId)), ("text", ConstructorParameterDescription(self.text)), ("trialRemainsNum", ConstructorParameterDescription(self.trialRemainsNum)), ("trialRemainsUntilDate", ConstructorParameterDescription(self.trialRemainsUntilDate))])
            }
        }
        case transcribedAudio(Cons_transcribedAudio)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .transcribedAudio(let _data):
                if boxed {
                    buffer.appendInt32(-809903785)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt64(_data.transcriptionId, buffer: buffer, boxed: false)
                serializeString(_data.text, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeInt32(_data.trialRemainsNum!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeInt32(_data.trialRemainsUntilDate!, buffer: buffer, boxed: false)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .transcribedAudio(let _data):
                return ("transcribedAudio", [("flags", ConstructorParameterDescription(_data.flags)), ("transcriptionId", ConstructorParameterDescription(_data.transcriptionId)), ("text", ConstructorParameterDescription(_data.text)), ("trialRemainsNum", ConstructorParameterDescription(_data.trialRemainsNum)), ("trialRemainsUntilDate", ConstructorParameterDescription(_data.trialRemainsUntilDate))])
            }
        }

        public static func parse_transcribedAudio(_ reader: BufferReader) -> TranscribedAudio? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int64?
            _2 = reader.readInt64()
            var _3: String?
            _3 = parseString(reader)
            var _4: Int32?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _4 = reader.readInt32()
            }
            var _5: Int32?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _5 = reader.readInt32()
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.messages.TranscribedAudio.transcribedAudio(Cons_transcribedAudio(flags: _1!, transcriptionId: _2!, text: _3!, trialRemainsNum: _4, trialRemainsUntilDate: _5))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum TranslatedText: TypeConstructorDescription {
        public class Cons_translateResult: TypeConstructorDescription {
            public var result: [Api.TextWithEntities]
            public init(result: [Api.TextWithEntities]) {
                self.result = result
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("translateResult", [("result", ConstructorParameterDescription(self.result))])
            }
        }
        case translateResult(Cons_translateResult)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .translateResult(let _data):
                if boxed {
                    buffer.appendInt32(870003448)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.result.count))
                for item in _data.result {
                    item.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .translateResult(let _data):
                return ("translateResult", [("result", ConstructorParameterDescription(_data.result))])
            }
        }

        public static func parse_translateResult(_ reader: BufferReader) -> TranslatedText? {
            var _1: [Api.TextWithEntities]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.TextWithEntities.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.messages.TranslatedText.translateResult(Cons_translateResult(result: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum VotesList: TypeConstructorDescription {
        public class Cons_votesList: TypeConstructorDescription {
            public var flags: Int32
            public var count: Int32
            public var votes: [Api.MessagePeerVote]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public var nextOffset: String?
            public init(flags: Int32, count: Int32, votes: [Api.MessagePeerVote], chats: [Api.Chat], users: [Api.User], nextOffset: String?) {
                self.flags = flags
                self.count = count
                self.votes = votes
                self.chats = chats
                self.users = users
                self.nextOffset = nextOffset
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("votesList", [("flags", ConstructorParameterDescription(self.flags)), ("count", ConstructorParameterDescription(self.count)), ("votes", ConstructorParameterDescription(self.votes)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users)), ("nextOffset", ConstructorParameterDescription(self.nextOffset))])
            }
        }
        case votesList(Cons_votesList)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .votesList(let _data):
                if boxed {
                    buffer.appendInt32(1218005070)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.votes.count))
                for item in _data.votes {
                    item.serialize(buffer, true)
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
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeString(_data.nextOffset!, buffer: buffer, boxed: false)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .votesList(let _data):
                return ("votesList", [("flags", ConstructorParameterDescription(_data.flags)), ("count", ConstructorParameterDescription(_data.count)), ("votes", ConstructorParameterDescription(_data.votes)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users)), ("nextOffset", ConstructorParameterDescription(_data.nextOffset))])
            }
        }

        public static func parse_votesList(_ reader: BufferReader) -> VotesList? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: [Api.MessagePeerVote]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.MessagePeerVote.self)
            }
            var _4: [Api.Chat]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _5: [Api.User]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            var _6: String?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _6 = parseString(reader)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.messages.VotesList.votesList(Cons_votesList(flags: _1!, count: _2!, votes: _3!, chats: _4!, users: _5!, nextOffset: _6))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum WebPage: TypeConstructorDescription {
        public class Cons_webPage: TypeConstructorDescription {
            public var webpage: Api.WebPage
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(webpage: Api.WebPage, chats: [Api.Chat], users: [Api.User]) {
                self.webpage = webpage
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("webPage", [("webpage", ConstructorParameterDescription(self.webpage)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case webPage(Cons_webPage)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .webPage(let _data):
                if boxed {
                    buffer.appendInt32(-44166467)
                }
                _data.webpage.serialize(buffer, true)
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
            case .webPage(let _data):
                return ("webPage", [("webpage", ConstructorParameterDescription(_data.webpage)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_webPage(_ reader: BufferReader) -> WebPage? {
            var _1: Api.WebPage?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.WebPage
            }
            var _2: [Api.Chat]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _3: [Api.User]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.messages.WebPage.webPage(Cons_webPage(webpage: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    indirect enum WebPagePreview: TypeConstructorDescription {
        public class Cons_webPagePreview: TypeConstructorDescription {
            public var media: Api.MessageMedia
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(media: Api.MessageMedia, chats: [Api.Chat], users: [Api.User]) {
                self.media = media
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("webPagePreview", [("media", ConstructorParameterDescription(self.media)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case webPagePreview(Cons_webPagePreview)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .webPagePreview(let _data):
                if boxed {
                    buffer.appendInt32(-1936029524)
                }
                _data.media.serialize(buffer, true)
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
            case .webPagePreview(let _data):
                return ("webPagePreview", [("media", ConstructorParameterDescription(_data.media)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_webPagePreview(_ reader: BufferReader) -> WebPagePreview? {
            var _1: Api.MessageMedia?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.MessageMedia
            }
            var _2: [Api.Chat]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _3: [Api.User]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.messages.WebPagePreview.webPagePreview(Cons_webPagePreview(media: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.payments {
    enum BankCardData: TypeConstructorDescription {
        public class Cons_bankCardData: TypeConstructorDescription {
            public var title: String
            public var openUrls: [Api.BankCardOpenUrl]
            public init(title: String, openUrls: [Api.BankCardOpenUrl]) {
                self.title = title
                self.openUrls = openUrls
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("bankCardData", [("title", ConstructorParameterDescription(self.title)), ("openUrls", ConstructorParameterDescription(self.openUrls))])
            }
        }
        case bankCardData(Cons_bankCardData)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .bankCardData(let _data):
                if boxed {
                    buffer.appendInt32(1042605427)
                }
                serializeString(_data.title, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.openUrls.count))
                for item in _data.openUrls {
                    item.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .bankCardData(let _data):
                return ("bankCardData", [("title", ConstructorParameterDescription(_data.title)), ("openUrls", ConstructorParameterDescription(_data.openUrls))])
            }
        }

        public static func parse_bankCardData(_ reader: BufferReader) -> BankCardData? {
            var _1: String?
            _1 = parseString(reader)
            var _2: [Api.BankCardOpenUrl]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.BankCardOpenUrl.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.payments.BankCardData.bankCardData(Cons_bankCardData(title: _1!, openUrls: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.payments {
    enum CheckCanSendGiftResult: TypeConstructorDescription {
        public class Cons_checkCanSendGiftResultFail: TypeConstructorDescription {
            public var reason: Api.TextWithEntities
            public init(reason: Api.TextWithEntities) {
                self.reason = reason
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("checkCanSendGiftResultFail", [("reason", ConstructorParameterDescription(self.reason))])
            }
        }
        case checkCanSendGiftResultFail(Cons_checkCanSendGiftResultFail)
        case checkCanSendGiftResultOk

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .checkCanSendGiftResultFail(let _data):
                if boxed {
                    buffer.appendInt32(-706379148)
                }
                _data.reason.serialize(buffer, true)
                break
            case .checkCanSendGiftResultOk:
                if boxed {
                    buffer.appendInt32(927967149)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .checkCanSendGiftResultFail(let _data):
                return ("checkCanSendGiftResultFail", [("reason", ConstructorParameterDescription(_data.reason))])
            case .checkCanSendGiftResultOk:
                return ("checkCanSendGiftResultOk", [])
            }
        }

        public static func parse_checkCanSendGiftResultFail(_ reader: BufferReader) -> CheckCanSendGiftResult? {
            var _1: Api.TextWithEntities?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.TextWithEntities
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.payments.CheckCanSendGiftResult.checkCanSendGiftResultFail(Cons_checkCanSendGiftResultFail(reason: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_checkCanSendGiftResultOk(_ reader: BufferReader) -> CheckCanSendGiftResult? {
            return Api.payments.CheckCanSendGiftResult.checkCanSendGiftResultOk
        }
    }
}
public extension Api.payments {
    enum CheckedGiftCode: TypeConstructorDescription {
        public class Cons_checkedGiftCode: TypeConstructorDescription {
            public var flags: Int32
            public var fromId: Api.Peer?
            public var giveawayMsgId: Int32?
            public var toId: Int64?
            public var date: Int32
            public var days: Int32
            public var usedDate: Int32?
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(flags: Int32, fromId: Api.Peer?, giveawayMsgId: Int32?, toId: Int64?, date: Int32, days: Int32, usedDate: Int32?, chats: [Api.Chat], users: [Api.User]) {
                self.flags = flags
                self.fromId = fromId
                self.giveawayMsgId = giveawayMsgId
                self.toId = toId
                self.date = date
                self.days = days
                self.usedDate = usedDate
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("checkedGiftCode", [("flags", ConstructorParameterDescription(self.flags)), ("fromId", ConstructorParameterDescription(self.fromId)), ("giveawayMsgId", ConstructorParameterDescription(self.giveawayMsgId)), ("toId", ConstructorParameterDescription(self.toId)), ("date", ConstructorParameterDescription(self.date)), ("days", ConstructorParameterDescription(self.days)), ("usedDate", ConstructorParameterDescription(self.usedDate)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case checkedGiftCode(Cons_checkedGiftCode)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .checkedGiftCode(let _data):
                if boxed {
                    buffer.appendInt32(-342343793)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 4) != 0 {
                    _data.fromId!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 3) != 0 {
                    serializeInt32(_data.giveawayMsgId!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeInt64(_data.toId!, buffer: buffer, boxed: false)
                }
                serializeInt32(_data.date, buffer: buffer, boxed: false)
                serializeInt32(_data.days, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeInt32(_data.usedDate!, buffer: buffer, boxed: false)
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
            case .checkedGiftCode(let _data):
                return ("checkedGiftCode", [("flags", ConstructorParameterDescription(_data.flags)), ("fromId", ConstructorParameterDescription(_data.fromId)), ("giveawayMsgId", ConstructorParameterDescription(_data.giveawayMsgId)), ("toId", ConstructorParameterDescription(_data.toId)), ("date", ConstructorParameterDescription(_data.date)), ("days", ConstructorParameterDescription(_data.days)), ("usedDate", ConstructorParameterDescription(_data.usedDate)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_checkedGiftCode(_ reader: BufferReader) -> CheckedGiftCode? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.Peer?
            if Int(_1 ?? 0) & Int(1 << 4) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.Peer
                }
            }
            var _3: Int32?
            if Int(_1 ?? 0) & Int(1 << 3) != 0 {
                _3 = reader.readInt32()
            }
            var _4: Int64?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _4 = reader.readInt64()
            }
            var _5: Int32?
            _5 = reader.readInt32()
            var _6: Int32?
            _6 = reader.readInt32()
            var _7: Int32?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _7 = reader.readInt32()
            }
            var _8: [Api.Chat]?
            if let _ = reader.readInt32() {
                _8 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _9: [Api.User]?
            if let _ = reader.readInt32() {
                _9 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 4) == 0) || _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 3) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            let _c7 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _7 != nil
            let _c8 = _8 != nil
            let _c9 = _9 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 && _c9 {
                return Api.payments.CheckedGiftCode.checkedGiftCode(Cons_checkedGiftCode(flags: _1!, fromId: _2, giveawayMsgId: _3, toId: _4, date: _5!, days: _6!, usedDate: _7, chats: _8!, users: _9!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.payments {
    enum ConnectedStarRefBots: TypeConstructorDescription {
        public class Cons_connectedStarRefBots: TypeConstructorDescription {
            public var count: Int32
            public var connectedBots: [Api.ConnectedBotStarRef]
            public var users: [Api.User]
            public init(count: Int32, connectedBots: [Api.ConnectedBotStarRef], users: [Api.User]) {
                self.count = count
                self.connectedBots = connectedBots
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("connectedStarRefBots", [("count", ConstructorParameterDescription(self.count)), ("connectedBots", ConstructorParameterDescription(self.connectedBots)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case connectedStarRefBots(Cons_connectedStarRefBots)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .connectedStarRefBots(let _data):
                if boxed {
                    buffer.appendInt32(-1730811363)
                }
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.connectedBots.count))
                for item in _data.connectedBots {
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
            case .connectedStarRefBots(let _data):
                return ("connectedStarRefBots", [("count", ConstructorParameterDescription(_data.count)), ("connectedBots", ConstructorParameterDescription(_data.connectedBots)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_connectedStarRefBots(_ reader: BufferReader) -> ConnectedStarRefBots? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.ConnectedBotStarRef]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.ConnectedBotStarRef.self)
            }
            var _3: [Api.User]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.payments.ConnectedStarRefBots.connectedStarRefBots(Cons_connectedStarRefBots(count: _1!, connectedBots: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.payments {
    enum ExportedInvoice: TypeConstructorDescription {
        public class Cons_exportedInvoice: TypeConstructorDescription {
            public var url: String
            public init(url: String) {
                self.url = url
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("exportedInvoice", [("url", ConstructorParameterDescription(self.url))])
            }
        }
        case exportedInvoice(Cons_exportedInvoice)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .exportedInvoice(let _data):
                if boxed {
                    buffer.appendInt32(-1362048039)
                }
                serializeString(_data.url, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .exportedInvoice(let _data):
                return ("exportedInvoice", [("url", ConstructorParameterDescription(_data.url))])
            }
        }

        public static func parse_exportedInvoice(_ reader: BufferReader) -> ExportedInvoice? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.payments.ExportedInvoice.exportedInvoice(Cons_exportedInvoice(url: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.payments {
    enum GiveawayInfo: TypeConstructorDescription {
        public class Cons_giveawayInfo: TypeConstructorDescription {
            public var flags: Int32
            public var startDate: Int32
            public var joinedTooEarlyDate: Int32?
            public var adminDisallowedChatId: Int64?
            public var disallowedCountry: String?
            public init(flags: Int32, startDate: Int32, joinedTooEarlyDate: Int32?, adminDisallowedChatId: Int64?, disallowedCountry: String?) {
                self.flags = flags
                self.startDate = startDate
                self.joinedTooEarlyDate = joinedTooEarlyDate
                self.adminDisallowedChatId = adminDisallowedChatId
                self.disallowedCountry = disallowedCountry
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("giveawayInfo", [("flags", ConstructorParameterDescription(self.flags)), ("startDate", ConstructorParameterDescription(self.startDate)), ("joinedTooEarlyDate", ConstructorParameterDescription(self.joinedTooEarlyDate)), ("adminDisallowedChatId", ConstructorParameterDescription(self.adminDisallowedChatId)), ("disallowedCountry", ConstructorParameterDescription(self.disallowedCountry))])
            }
        }
        public class Cons_giveawayInfoResults: TypeConstructorDescription {
            public var flags: Int32
            public var startDate: Int32
            public var giftCodeSlug: String?
            public var starsPrize: Int64?
            public var finishDate: Int32
            public var winnersCount: Int32
            public var activatedCount: Int32?
            public init(flags: Int32, startDate: Int32, giftCodeSlug: String?, starsPrize: Int64?, finishDate: Int32, winnersCount: Int32, activatedCount: Int32?) {
                self.flags = flags
                self.startDate = startDate
                self.giftCodeSlug = giftCodeSlug
                self.starsPrize = starsPrize
                self.finishDate = finishDate
                self.winnersCount = winnersCount
                self.activatedCount = activatedCount
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("giveawayInfoResults", [("flags", ConstructorParameterDescription(self.flags)), ("startDate", ConstructorParameterDescription(self.startDate)), ("giftCodeSlug", ConstructorParameterDescription(self.giftCodeSlug)), ("starsPrize", ConstructorParameterDescription(self.starsPrize)), ("finishDate", ConstructorParameterDescription(self.finishDate)), ("winnersCount", ConstructorParameterDescription(self.winnersCount)), ("activatedCount", ConstructorParameterDescription(self.activatedCount))])
            }
        }
        case giveawayInfo(Cons_giveawayInfo)
        case giveawayInfoResults(Cons_giveawayInfoResults)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .giveawayInfo(let _data):
                if boxed {
                    buffer.appendInt32(1130879648)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.startDate, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeInt32(_data.joinedTooEarlyDate!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeInt64(_data.adminDisallowedChatId!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 4) != 0 {
                    serializeString(_data.disallowedCountry!, buffer: buffer, boxed: false)
                }
                break
            case .giveawayInfoResults(let _data):
                if boxed {
                    buffer.appendInt32(-512366993)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.startDate, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 3) != 0 {
                    serializeString(_data.giftCodeSlug!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 4) != 0 {
                    serializeInt64(_data.starsPrize!, buffer: buffer, boxed: false)
                }
                serializeInt32(_data.finishDate, buffer: buffer, boxed: false)
                serializeInt32(_data.winnersCount, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeInt32(_data.activatedCount!, buffer: buffer, boxed: false)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .giveawayInfo(let _data):
                return ("giveawayInfo", [("flags", ConstructorParameterDescription(_data.flags)), ("startDate", ConstructorParameterDescription(_data.startDate)), ("joinedTooEarlyDate", ConstructorParameterDescription(_data.joinedTooEarlyDate)), ("adminDisallowedChatId", ConstructorParameterDescription(_data.adminDisallowedChatId)), ("disallowedCountry", ConstructorParameterDescription(_data.disallowedCountry))])
            case .giveawayInfoResults(let _data):
                return ("giveawayInfoResults", [("flags", ConstructorParameterDescription(_data.flags)), ("startDate", ConstructorParameterDescription(_data.startDate)), ("giftCodeSlug", ConstructorParameterDescription(_data.giftCodeSlug)), ("starsPrize", ConstructorParameterDescription(_data.starsPrize)), ("finishDate", ConstructorParameterDescription(_data.finishDate)), ("winnersCount", ConstructorParameterDescription(_data.winnersCount)), ("activatedCount", ConstructorParameterDescription(_data.activatedCount))])
            }
        }

        public static func parse_giveawayInfo(_ reader: BufferReader) -> GiveawayInfo? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _3 = reader.readInt32()
            }
            var _4: Int64?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _4 = reader.readInt64()
            }
            var _5: String?
            if Int(_1 ?? 0) & Int(1 << 4) != 0 {
                _5 = parseString(reader)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 4) == 0) || _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.payments.GiveawayInfo.giveawayInfo(Cons_giveawayInfo(flags: _1!, startDate: _2!, joinedTooEarlyDate: _3, adminDisallowedChatId: _4, disallowedCountry: _5))
            }
            else {
                return nil
            }
        }
        public static func parse_giveawayInfoResults(_ reader: BufferReader) -> GiveawayInfo? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: String?
            if Int(_1 ?? 0) & Int(1 << 3) != 0 {
                _3 = parseString(reader)
            }
            var _4: Int64?
            if Int(_1 ?? 0) & Int(1 << 4) != 0 {
                _4 = reader.readInt64()
            }
            var _5: Int32?
            _5 = reader.readInt32()
            var _6: Int32?
            _6 = reader.readInt32()
            var _7: Int32?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _7 = reader.readInt32()
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 3) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 4) == 0) || _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            let _c7 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _7 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 {
                return Api.payments.GiveawayInfo.giveawayInfoResults(Cons_giveawayInfoResults(flags: _1!, startDate: _2!, giftCodeSlug: _3, starsPrize: _4, finishDate: _5!, winnersCount: _6!, activatedCount: _7))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.payments {
    enum PaymentForm: TypeConstructorDescription {
        public class Cons_paymentForm: TypeConstructorDescription {
            public var flags: Int32
            public var formId: Int64
            public var botId: Int64
            public var title: String
            public var description: String
            public var photo: Api.WebDocument?
            public var invoice: Api.Invoice
            public var providerId: Int64
            public var url: String
            public var nativeProvider: String?
            public var nativeParams: Api.DataJSON?
            public var additionalMethods: [Api.PaymentFormMethod]?
            public var savedInfo: Api.PaymentRequestedInfo?
            public var savedCredentials: [Api.PaymentSavedCredentials]?
            public var users: [Api.User]
            public init(flags: Int32, formId: Int64, botId: Int64, title: String, description: String, photo: Api.WebDocument?, invoice: Api.Invoice, providerId: Int64, url: String, nativeProvider: String?, nativeParams: Api.DataJSON?, additionalMethods: [Api.PaymentFormMethod]?, savedInfo: Api.PaymentRequestedInfo?, savedCredentials: [Api.PaymentSavedCredentials]?, users: [Api.User]) {
                self.flags = flags
                self.formId = formId
                self.botId = botId
                self.title = title
                self.description = description
                self.photo = photo
                self.invoice = invoice
                self.providerId = providerId
                self.url = url
                self.nativeProvider = nativeProvider
                self.nativeParams = nativeParams
                self.additionalMethods = additionalMethods
                self.savedInfo = savedInfo
                self.savedCredentials = savedCredentials
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("paymentForm", [("flags", ConstructorParameterDescription(self.flags)), ("formId", ConstructorParameterDescription(self.formId)), ("botId", ConstructorParameterDescription(self.botId)), ("title", ConstructorParameterDescription(self.title)), ("description", ConstructorParameterDescription(self.description)), ("photo", ConstructorParameterDescription(self.photo)), ("invoice", ConstructorParameterDescription(self.invoice)), ("providerId", ConstructorParameterDescription(self.providerId)), ("url", ConstructorParameterDescription(self.url)), ("nativeProvider", ConstructorParameterDescription(self.nativeProvider)), ("nativeParams", ConstructorParameterDescription(self.nativeParams)), ("additionalMethods", ConstructorParameterDescription(self.additionalMethods)), ("savedInfo", ConstructorParameterDescription(self.savedInfo)), ("savedCredentials", ConstructorParameterDescription(self.savedCredentials)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        public class Cons_paymentFormStarGift: TypeConstructorDescription {
            public var formId: Int64
            public var invoice: Api.Invoice
            public init(formId: Int64, invoice: Api.Invoice) {
                self.formId = formId
                self.invoice = invoice
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("paymentFormStarGift", [("formId", ConstructorParameterDescription(self.formId)), ("invoice", ConstructorParameterDescription(self.invoice))])
            }
        }
        public class Cons_paymentFormStars: TypeConstructorDescription {
            public var flags: Int32
            public var formId: Int64
            public var botId: Int64
            public var title: String
            public var description: String
            public var photo: Api.WebDocument?
            public var invoice: Api.Invoice
            public var users: [Api.User]
            public init(flags: Int32, formId: Int64, botId: Int64, title: String, description: String, photo: Api.WebDocument?, invoice: Api.Invoice, users: [Api.User]) {
                self.flags = flags
                self.formId = formId
                self.botId = botId
                self.title = title
                self.description = description
                self.photo = photo
                self.invoice = invoice
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("paymentFormStars", [("flags", ConstructorParameterDescription(self.flags)), ("formId", ConstructorParameterDescription(self.formId)), ("botId", ConstructorParameterDescription(self.botId)), ("title", ConstructorParameterDescription(self.title)), ("description", ConstructorParameterDescription(self.description)), ("photo", ConstructorParameterDescription(self.photo)), ("invoice", ConstructorParameterDescription(self.invoice)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case paymentForm(Cons_paymentForm)
        case paymentFormStarGift(Cons_paymentFormStarGift)
        case paymentFormStars(Cons_paymentFormStars)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .paymentForm(let _data):
                if boxed {
                    buffer.appendInt32(-1610250415)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt64(_data.formId, buffer: buffer, boxed: false)
                serializeInt64(_data.botId, buffer: buffer, boxed: false)
                serializeString(_data.title, buffer: buffer, boxed: false)
                serializeString(_data.description, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 5) != 0 {
                    _data.photo!.serialize(buffer, true)
                }
                _data.invoice.serialize(buffer, true)
                serializeInt64(_data.providerId, buffer: buffer, boxed: false)
                serializeString(_data.url, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 4) != 0 {
                    serializeString(_data.nativeProvider!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 4) != 0 {
                    _data.nativeParams!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 6) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.additionalMethods!.count))
                    for item in _data.additionalMethods! {
                        item.serialize(buffer, true)
                    }
                }
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    _data.savedInfo!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.savedCredentials!.count))
                    for item in _data.savedCredentials! {
                        item.serialize(buffer, true)
                    }
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.users.count))
                for item in _data.users {
                    item.serialize(buffer, true)
                }
                break
            case .paymentFormStarGift(let _data):
                if boxed {
                    buffer.appendInt32(-1272590367)
                }
                serializeInt64(_data.formId, buffer: buffer, boxed: false)
                _data.invoice.serialize(buffer, true)
                break
            case .paymentFormStars(let _data):
                if boxed {
                    buffer.appendInt32(2079764828)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt64(_data.formId, buffer: buffer, boxed: false)
                serializeInt64(_data.botId, buffer: buffer, boxed: false)
                serializeString(_data.title, buffer: buffer, boxed: false)
                serializeString(_data.description, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 5) != 0 {
                    _data.photo!.serialize(buffer, true)
                }
                _data.invoice.serialize(buffer, true)
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
            case .paymentForm(let _data):
                return ("paymentForm", [("flags", ConstructorParameterDescription(_data.flags)), ("formId", ConstructorParameterDescription(_data.formId)), ("botId", ConstructorParameterDescription(_data.botId)), ("title", ConstructorParameterDescription(_data.title)), ("description", ConstructorParameterDescription(_data.description)), ("photo", ConstructorParameterDescription(_data.photo)), ("invoice", ConstructorParameterDescription(_data.invoice)), ("providerId", ConstructorParameterDescription(_data.providerId)), ("url", ConstructorParameterDescription(_data.url)), ("nativeProvider", ConstructorParameterDescription(_data.nativeProvider)), ("nativeParams", ConstructorParameterDescription(_data.nativeParams)), ("additionalMethods", ConstructorParameterDescription(_data.additionalMethods)), ("savedInfo", ConstructorParameterDescription(_data.savedInfo)), ("savedCredentials", ConstructorParameterDescription(_data.savedCredentials)), ("users", ConstructorParameterDescription(_data.users))])
            case .paymentFormStarGift(let _data):
                return ("paymentFormStarGift", [("formId", ConstructorParameterDescription(_data.formId)), ("invoice", ConstructorParameterDescription(_data.invoice))])
            case .paymentFormStars(let _data):
                return ("paymentFormStars", [("flags", ConstructorParameterDescription(_data.flags)), ("formId", ConstructorParameterDescription(_data.formId)), ("botId", ConstructorParameterDescription(_data.botId)), ("title", ConstructorParameterDescription(_data.title)), ("description", ConstructorParameterDescription(_data.description)), ("photo", ConstructorParameterDescription(_data.photo)), ("invoice", ConstructorParameterDescription(_data.invoice)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_paymentForm(_ reader: BufferReader) -> PaymentForm? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int64?
            _2 = reader.readInt64()
            var _3: Int64?
            _3 = reader.readInt64()
            var _4: String?
            _4 = parseString(reader)
            var _5: String?
            _5 = parseString(reader)
            var _6: Api.WebDocument?
            if Int(_1 ?? 0) & Int(1 << 5) != 0 {
                if let signature = reader.readInt32() {
                    _6 = Api.parse(reader, signature: signature) as? Api.WebDocument
                }
            }
            var _7: Api.Invoice?
            if let signature = reader.readInt32() {
                _7 = Api.parse(reader, signature: signature) as? Api.Invoice
            }
            var _8: Int64?
            _8 = reader.readInt64()
            var _9: String?
            _9 = parseString(reader)
            var _10: String?
            if Int(_1 ?? 0) & Int(1 << 4) != 0 {
                _10 = parseString(reader)
            }
            var _11: Api.DataJSON?
            if Int(_1 ?? 0) & Int(1 << 4) != 0 {
                if let signature = reader.readInt32() {
                    _11 = Api.parse(reader, signature: signature) as? Api.DataJSON
                }
            }
            var _12: [Api.PaymentFormMethod]?
            if Int(_1 ?? 0) & Int(1 << 6) != 0 {
                if let _ = reader.readInt32() {
                    _12 = Api.parseVector(reader, elementSignature: 0, elementType: Api.PaymentFormMethod.self)
                }
            }
            var _13: Api.PaymentRequestedInfo?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                if let signature = reader.readInt32() {
                    _13 = Api.parse(reader, signature: signature) as? Api.PaymentRequestedInfo
                }
            }
            var _14: [Api.PaymentSavedCredentials]?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let _ = reader.readInt32() {
                    _14 = Api.parseVector(reader, elementSignature: 0, elementType: Api.PaymentSavedCredentials.self)
                }
            }
            var _15: [Api.User]?
            if let _ = reader.readInt32() {
                _15 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = (Int(_1 ?? 0) & Int(1 << 5) == 0) || _6 != nil
            let _c7 = _7 != nil
            let _c8 = _8 != nil
            let _c9 = _9 != nil
            let _c10 = (Int(_1 ?? 0) & Int(1 << 4) == 0) || _10 != nil
            let _c11 = (Int(_1 ?? 0) & Int(1 << 4) == 0) || _11 != nil
            let _c12 = (Int(_1 ?? 0) & Int(1 << 6) == 0) || _12 != nil
            let _c13 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _13 != nil
            let _c14 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _14 != nil
            let _c15 = _15 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 && _c9 && _c10 && _c11 && _c12 && _c13 && _c14 && _c15 {
                return Api.payments.PaymentForm.paymentForm(Cons_paymentForm(flags: _1!, formId: _2!, botId: _3!, title: _4!, description: _5!, photo: _6, invoice: _7!, providerId: _8!, url: _9!, nativeProvider: _10, nativeParams: _11, additionalMethods: _12, savedInfo: _13, savedCredentials: _14, users: _15!))
            }
            else {
                return nil
            }
        }
        public static func parse_paymentFormStarGift(_ reader: BufferReader) -> PaymentForm? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: Api.Invoice?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.Invoice
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.payments.PaymentForm.paymentFormStarGift(Cons_paymentFormStarGift(formId: _1!, invoice: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_paymentFormStars(_ reader: BufferReader) -> PaymentForm? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int64?
            _2 = reader.readInt64()
            var _3: Int64?
            _3 = reader.readInt64()
            var _4: String?
            _4 = parseString(reader)
            var _5: String?
            _5 = parseString(reader)
            var _6: Api.WebDocument?
            if Int(_1 ?? 0) & Int(1 << 5) != 0 {
                if let signature = reader.readInt32() {
                    _6 = Api.parse(reader, signature: signature) as? Api.WebDocument
                }
            }
            var _7: Api.Invoice?
            if let signature = reader.readInt32() {
                _7 = Api.parse(reader, signature: signature) as? Api.Invoice
            }
            var _8: [Api.User]?
            if let _ = reader.readInt32() {
                _8 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = (Int(_1 ?? 0) & Int(1 << 5) == 0) || _6 != nil
            let _c7 = _7 != nil
            let _c8 = _8 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 {
                return Api.payments.PaymentForm.paymentFormStars(Cons_paymentFormStars(flags: _1!, formId: _2!, botId: _3!, title: _4!, description: _5!, photo: _6, invoice: _7!, users: _8!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.payments {
    enum PaymentReceipt: TypeConstructorDescription {
        public class Cons_paymentReceipt: TypeConstructorDescription {
            public var flags: Int32
            public var date: Int32
            public var botId: Int64
            public var providerId: Int64
            public var title: String
            public var description: String
            public var photo: Api.WebDocument?
            public var invoice: Api.Invoice
            public var info: Api.PaymentRequestedInfo?
            public var shipping: Api.ShippingOption?
            public var tipAmount: Int64?
            public var currency: String
            public var totalAmount: Int64
            public var credentialsTitle: String
            public var users: [Api.User]
            public init(flags: Int32, date: Int32, botId: Int64, providerId: Int64, title: String, description: String, photo: Api.WebDocument?, invoice: Api.Invoice, info: Api.PaymentRequestedInfo?, shipping: Api.ShippingOption?, tipAmount: Int64?, currency: String, totalAmount: Int64, credentialsTitle: String, users: [Api.User]) {
                self.flags = flags
                self.date = date
                self.botId = botId
                self.providerId = providerId
                self.title = title
                self.description = description
                self.photo = photo
                self.invoice = invoice
                self.info = info
                self.shipping = shipping
                self.tipAmount = tipAmount
                self.currency = currency
                self.totalAmount = totalAmount
                self.credentialsTitle = credentialsTitle
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("paymentReceipt", [("flags", ConstructorParameterDescription(self.flags)), ("date", ConstructorParameterDescription(self.date)), ("botId", ConstructorParameterDescription(self.botId)), ("providerId", ConstructorParameterDescription(self.providerId)), ("title", ConstructorParameterDescription(self.title)), ("description", ConstructorParameterDescription(self.description)), ("photo", ConstructorParameterDescription(self.photo)), ("invoice", ConstructorParameterDescription(self.invoice)), ("info", ConstructorParameterDescription(self.info)), ("shipping", ConstructorParameterDescription(self.shipping)), ("tipAmount", ConstructorParameterDescription(self.tipAmount)), ("currency", ConstructorParameterDescription(self.currency)), ("totalAmount", ConstructorParameterDescription(self.totalAmount)), ("credentialsTitle", ConstructorParameterDescription(self.credentialsTitle)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        public class Cons_paymentReceiptStars: TypeConstructorDescription {
            public var flags: Int32
            public var date: Int32
            public var botId: Int64
            public var title: String
            public var description: String
            public var photo: Api.WebDocument?
            public var invoice: Api.Invoice
            public var currency: String
            public var totalAmount: Int64
            public var transactionId: String
            public var users: [Api.User]
            public init(flags: Int32, date: Int32, botId: Int64, title: String, description: String, photo: Api.WebDocument?, invoice: Api.Invoice, currency: String, totalAmount: Int64, transactionId: String, users: [Api.User]) {
                self.flags = flags
                self.date = date
                self.botId = botId
                self.title = title
                self.description = description
                self.photo = photo
                self.invoice = invoice
                self.currency = currency
                self.totalAmount = totalAmount
                self.transactionId = transactionId
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("paymentReceiptStars", [("flags", ConstructorParameterDescription(self.flags)), ("date", ConstructorParameterDescription(self.date)), ("botId", ConstructorParameterDescription(self.botId)), ("title", ConstructorParameterDescription(self.title)), ("description", ConstructorParameterDescription(self.description)), ("photo", ConstructorParameterDescription(self.photo)), ("invoice", ConstructorParameterDescription(self.invoice)), ("currency", ConstructorParameterDescription(self.currency)), ("totalAmount", ConstructorParameterDescription(self.totalAmount)), ("transactionId", ConstructorParameterDescription(self.transactionId)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case paymentReceipt(Cons_paymentReceipt)
        case paymentReceiptStars(Cons_paymentReceiptStars)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .paymentReceipt(let _data):
                if boxed {
                    buffer.appendInt32(1891958275)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.date, buffer: buffer, boxed: false)
                serializeInt64(_data.botId, buffer: buffer, boxed: false)
                serializeInt64(_data.providerId, buffer: buffer, boxed: false)
                serializeString(_data.title, buffer: buffer, boxed: false)
                serializeString(_data.description, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    _data.photo!.serialize(buffer, true)
                }
                _data.invoice.serialize(buffer, true)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    _data.info!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    _data.shipping!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 3) != 0 {
                    serializeInt64(_data.tipAmount!, buffer: buffer, boxed: false)
                }
                serializeString(_data.currency, buffer: buffer, boxed: false)
                serializeInt64(_data.totalAmount, buffer: buffer, boxed: false)
                serializeString(_data.credentialsTitle, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.users.count))
                for item in _data.users {
                    item.serialize(buffer, true)
                }
                break
            case .paymentReceiptStars(let _data):
                if boxed {
                    buffer.appendInt32(-625215430)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.date, buffer: buffer, boxed: false)
                serializeInt64(_data.botId, buffer: buffer, boxed: false)
                serializeString(_data.title, buffer: buffer, boxed: false)
                serializeString(_data.description, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    _data.photo!.serialize(buffer, true)
                }
                _data.invoice.serialize(buffer, true)
                serializeString(_data.currency, buffer: buffer, boxed: false)
                serializeInt64(_data.totalAmount, buffer: buffer, boxed: false)
                serializeString(_data.transactionId, buffer: buffer, boxed: false)
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
            case .paymentReceipt(let _data):
                return ("paymentReceipt", [("flags", ConstructorParameterDescription(_data.flags)), ("date", ConstructorParameterDescription(_data.date)), ("botId", ConstructorParameterDescription(_data.botId)), ("providerId", ConstructorParameterDescription(_data.providerId)), ("title", ConstructorParameterDescription(_data.title)), ("description", ConstructorParameterDescription(_data.description)), ("photo", ConstructorParameterDescription(_data.photo)), ("invoice", ConstructorParameterDescription(_data.invoice)), ("info", ConstructorParameterDescription(_data.info)), ("shipping", ConstructorParameterDescription(_data.shipping)), ("tipAmount", ConstructorParameterDescription(_data.tipAmount)), ("currency", ConstructorParameterDescription(_data.currency)), ("totalAmount", ConstructorParameterDescription(_data.totalAmount)), ("credentialsTitle", ConstructorParameterDescription(_data.credentialsTitle)), ("users", ConstructorParameterDescription(_data.users))])
            case .paymentReceiptStars(let _data):
                return ("paymentReceiptStars", [("flags", ConstructorParameterDescription(_data.flags)), ("date", ConstructorParameterDescription(_data.date)), ("botId", ConstructorParameterDescription(_data.botId)), ("title", ConstructorParameterDescription(_data.title)), ("description", ConstructorParameterDescription(_data.description)), ("photo", ConstructorParameterDescription(_data.photo)), ("invoice", ConstructorParameterDescription(_data.invoice)), ("currency", ConstructorParameterDescription(_data.currency)), ("totalAmount", ConstructorParameterDescription(_data.totalAmount)), ("transactionId", ConstructorParameterDescription(_data.transactionId)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_paymentReceipt(_ reader: BufferReader) -> PaymentReceipt? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int64?
            _3 = reader.readInt64()
            var _4: Int64?
            _4 = reader.readInt64()
            var _5: String?
            _5 = parseString(reader)
            var _6: String?
            _6 = parseString(reader)
            var _7: Api.WebDocument?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                if let signature = reader.readInt32() {
                    _7 = Api.parse(reader, signature: signature) as? Api.WebDocument
                }
            }
            var _8: Api.Invoice?
            if let signature = reader.readInt32() {
                _8 = Api.parse(reader, signature: signature) as? Api.Invoice
            }
            var _9: Api.PaymentRequestedInfo?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                if let signature = reader.readInt32() {
                    _9 = Api.parse(reader, signature: signature) as? Api.PaymentRequestedInfo
                }
            }
            var _10: Api.ShippingOption?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let signature = reader.readInt32() {
                    _10 = Api.parse(reader, signature: signature) as? Api.ShippingOption
                }
            }
            var _11: Int64?
            if Int(_1 ?? 0) & Int(1 << 3) != 0 {
                _11 = reader.readInt64()
            }
            var _12: String?
            _12 = parseString(reader)
            var _13: Int64?
            _13 = reader.readInt64()
            var _14: String?
            _14 = parseString(reader)
            var _15: [Api.User]?
            if let _ = reader.readInt32() {
                _15 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            let _c7 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _7 != nil
            let _c8 = _8 != nil
            let _c9 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _9 != nil
            let _c10 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _10 != nil
            let _c11 = (Int(_1 ?? 0) & Int(1 << 3) == 0) || _11 != nil
            let _c12 = _12 != nil
            let _c13 = _13 != nil
            let _c14 = _14 != nil
            let _c15 = _15 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 && _c9 && _c10 && _c11 && _c12 && _c13 && _c14 && _c15 {
                return Api.payments.PaymentReceipt.paymentReceipt(Cons_paymentReceipt(flags: _1!, date: _2!, botId: _3!, providerId: _4!, title: _5!, description: _6!, photo: _7, invoice: _8!, info: _9, shipping: _10, tipAmount: _11, currency: _12!, totalAmount: _13!, credentialsTitle: _14!, users: _15!))
            }
            else {
                return nil
            }
        }
        public static func parse_paymentReceiptStars(_ reader: BufferReader) -> PaymentReceipt? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int64?
            _3 = reader.readInt64()
            var _4: String?
            _4 = parseString(reader)
            var _5: String?
            _5 = parseString(reader)
            var _6: Api.WebDocument?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                if let signature = reader.readInt32() {
                    _6 = Api.parse(reader, signature: signature) as? Api.WebDocument
                }
            }
            var _7: Api.Invoice?
            if let signature = reader.readInt32() {
                _7 = Api.parse(reader, signature: signature) as? Api.Invoice
            }
            var _8: String?
            _8 = parseString(reader)
            var _9: Int64?
            _9 = reader.readInt64()
            var _10: String?
            _10 = parseString(reader)
            var _11: [Api.User]?
            if let _ = reader.readInt32() {
                _11 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _6 != nil
            let _c7 = _7 != nil
            let _c8 = _8 != nil
            let _c9 = _9 != nil
            let _c10 = _10 != nil
            let _c11 = _11 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 && _c9 && _c10 && _c11 {
                return Api.payments.PaymentReceipt.paymentReceiptStars(Cons_paymentReceiptStars(flags: _1!, date: _2!, botId: _3!, title: _4!, description: _5!, photo: _6, invoice: _7!, currency: _8!, totalAmount: _9!, transactionId: _10!, users: _11!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.payments {
    indirect enum PaymentResult: TypeConstructorDescription {
        public class Cons_paymentResult: TypeConstructorDescription {
            public var updates: Api.Updates
            public init(updates: Api.Updates) {
                self.updates = updates
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("paymentResult", [("updates", ConstructorParameterDescription(self.updates))])
            }
        }
        public class Cons_paymentVerificationNeeded: TypeConstructorDescription {
            public var url: String
            public init(url: String) {
                self.url = url
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("paymentVerificationNeeded", [("url", ConstructorParameterDescription(self.url))])
            }
        }
        case paymentResult(Cons_paymentResult)
        case paymentVerificationNeeded(Cons_paymentVerificationNeeded)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .paymentResult(let _data):
                if boxed {
                    buffer.appendInt32(1314881805)
                }
                _data.updates.serialize(buffer, true)
                break
            case .paymentVerificationNeeded(let _data):
                if boxed {
                    buffer.appendInt32(-666824391)
                }
                serializeString(_data.url, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .paymentResult(let _data):
                return ("paymentResult", [("updates", ConstructorParameterDescription(_data.updates))])
            case .paymentVerificationNeeded(let _data):
                return ("paymentVerificationNeeded", [("url", ConstructorParameterDescription(_data.url))])
            }
        }

        public static func parse_paymentResult(_ reader: BufferReader) -> PaymentResult? {
            var _1: Api.Updates?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.Updates
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.payments.PaymentResult.paymentResult(Cons_paymentResult(updates: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_paymentVerificationNeeded(_ reader: BufferReader) -> PaymentResult? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.payments.PaymentResult.paymentVerificationNeeded(Cons_paymentVerificationNeeded(url: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.payments {
    enum ResaleStarGifts: TypeConstructorDescription {
        public class Cons_resaleStarGifts: TypeConstructorDescription {
            public var flags: Int32
            public var count: Int32
            public var gifts: [Api.StarGift]
            public var nextOffset: String?
            public var attributes: [Api.StarGiftAttribute]?
            public var attributesHash: Int64?
            public var chats: [Api.Chat]
            public var counters: [Api.StarGiftAttributeCounter]?
            public var users: [Api.User]
            public init(flags: Int32, count: Int32, gifts: [Api.StarGift], nextOffset: String?, attributes: [Api.StarGiftAttribute]?, attributesHash: Int64?, chats: [Api.Chat], counters: [Api.StarGiftAttributeCounter]?, users: [Api.User]) {
                self.flags = flags
                self.count = count
                self.gifts = gifts
                self.nextOffset = nextOffset
                self.attributes = attributes
                self.attributesHash = attributesHash
                self.chats = chats
                self.counters = counters
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("resaleStarGifts", [("flags", ConstructorParameterDescription(self.flags)), ("count", ConstructorParameterDescription(self.count)), ("gifts", ConstructorParameterDescription(self.gifts)), ("nextOffset", ConstructorParameterDescription(self.nextOffset)), ("attributes", ConstructorParameterDescription(self.attributes)), ("attributesHash", ConstructorParameterDescription(self.attributesHash)), ("chats", ConstructorParameterDescription(self.chats)), ("counters", ConstructorParameterDescription(self.counters)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case resaleStarGifts(Cons_resaleStarGifts)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .resaleStarGifts(let _data):
                if boxed {
                    buffer.appendInt32(-1803939105)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.gifts.count))
                for item in _data.gifts {
                    item.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeString(_data.nextOffset!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.attributes!.count))
                    for item in _data.attributes! {
                        item.serialize(buffer, true)
                    }
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeInt64(_data.attributesHash!, buffer: buffer, boxed: false)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.chats.count))
                for item in _data.chats {
                    item.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.counters!.count))
                    for item in _data.counters! {
                        item.serialize(buffer, true)
                    }
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
            case .resaleStarGifts(let _data):
                return ("resaleStarGifts", [("flags", ConstructorParameterDescription(_data.flags)), ("count", ConstructorParameterDescription(_data.count)), ("gifts", ConstructorParameterDescription(_data.gifts)), ("nextOffset", ConstructorParameterDescription(_data.nextOffset)), ("attributes", ConstructorParameterDescription(_data.attributes)), ("attributesHash", ConstructorParameterDescription(_data.attributesHash)), ("chats", ConstructorParameterDescription(_data.chats)), ("counters", ConstructorParameterDescription(_data.counters)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_resaleStarGifts(_ reader: BufferReader) -> ResaleStarGifts? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: [Api.StarGift]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StarGift.self)
            }
            var _4: String?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _4 = parseString(reader)
            }
            var _5: [Api.StarGiftAttribute]?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let _ = reader.readInt32() {
                    _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StarGiftAttribute.self)
                }
            }
            var _6: Int64?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _6 = reader.readInt64()
            }
            var _7: [Api.Chat]?
            if let _ = reader.readInt32() {
                _7 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _8: [Api.StarGiftAttributeCounter]?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                if let _ = reader.readInt32() {
                    _8 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StarGiftAttributeCounter.self)
                }
            }
            var _9: [Api.User]?
            if let _ = reader.readInt32() {
                _9 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _5 != nil
            let _c6 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _6 != nil
            let _c7 = _7 != nil
            let _c8 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _8 != nil
            let _c9 = _9 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 && _c9 {
                return Api.payments.ResaleStarGifts.resaleStarGifts(Cons_resaleStarGifts(flags: _1!, count: _2!, gifts: _3!, nextOffset: _4, attributes: _5, attributesHash: _6, chats: _7!, counters: _8, users: _9!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.payments {
    enum SavedInfo: TypeConstructorDescription {
        public class Cons_savedInfo: TypeConstructorDescription {
            public var flags: Int32
            public var savedInfo: Api.PaymentRequestedInfo?
            public init(flags: Int32, savedInfo: Api.PaymentRequestedInfo?) {
                self.flags = flags
                self.savedInfo = savedInfo
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("savedInfo", [("flags", ConstructorParameterDescription(self.flags)), ("savedInfo", ConstructorParameterDescription(self.savedInfo))])
            }
        }
        case savedInfo(Cons_savedInfo)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .savedInfo(let _data):
                if boxed {
                    buffer.appendInt32(-74456004)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    _data.savedInfo!.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .savedInfo(let _data):
                return ("savedInfo", [("flags", ConstructorParameterDescription(_data.flags)), ("savedInfo", ConstructorParameterDescription(_data.savedInfo))])
            }
        }

        public static func parse_savedInfo(_ reader: BufferReader) -> SavedInfo? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.PaymentRequestedInfo?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.PaymentRequestedInfo
                }
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _2 != nil
            if _c1 && _c2 {
                return Api.payments.SavedInfo.savedInfo(Cons_savedInfo(flags: _1!, savedInfo: _2))
            }
            else {
                return nil
            }
        }
    }
}
