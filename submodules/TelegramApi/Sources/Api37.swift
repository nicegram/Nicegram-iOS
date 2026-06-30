public extension Api.messages {
    enum HighScores: TypeConstructorDescription {
        public class Cons_highScores: TypeConstructorDescription {
            public var scores: [Api.HighScore]
            public var users: [Api.User]
            public init(scores: [Api.HighScore], users: [Api.User]) {
                self.scores = scores
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("highScores", [("scores", ConstructorParameterDescription(self.scores)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case highScores(Cons_highScores)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .highScores(let _data):
                if boxed {
                    buffer.appendInt32(-1707344487)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.scores.count))
                for item in _data.scores {
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
            case .highScores(let _data):
                return ("highScores", [("scores", ConstructorParameterDescription(_data.scores)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_highScores(_ reader: BufferReader) -> HighScores? {
            var _1: [Api.HighScore]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.HighScore.self)
            }
            var _2: [Api.User]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.HighScores.highScores(Cons_highScores(scores: _1!, users: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum HistoryImport: TypeConstructorDescription {
        public class Cons_historyImport: TypeConstructorDescription {
            public var id: Int64
            public init(id: Int64) {
                self.id = id
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("historyImport", [("id", ConstructorParameterDescription(self.id))])
            }
        }
        case historyImport(Cons_historyImport)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .historyImport(let _data):
                if boxed {
                    buffer.appendInt32(375566091)
                }
                serializeInt64(_data.id, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .historyImport(let _data):
                return ("historyImport", [("id", ConstructorParameterDescription(_data.id))])
            }
        }

        public static func parse_historyImport(_ reader: BufferReader) -> HistoryImport? {
            var _1: Int64?
            _1 = reader.readInt64()
            let _c1 = _1 != nil
            if _c1 {
                return Api.messages.HistoryImport.historyImport(Cons_historyImport(id: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum HistoryImportParsed: TypeConstructorDescription {
        public class Cons_historyImportParsed: TypeConstructorDescription {
            public var flags: Int32
            public var title: String?
            public init(flags: Int32, title: String?) {
                self.flags = flags
                self.title = title
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("historyImportParsed", [("flags", ConstructorParameterDescription(self.flags)), ("title", ConstructorParameterDescription(self.title))])
            }
        }
        case historyImportParsed(Cons_historyImportParsed)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .historyImportParsed(let _data):
                if boxed {
                    buffer.appendInt32(1578088377)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeString(_data.title!, buffer: buffer, boxed: false)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .historyImportParsed(let _data):
                return ("historyImportParsed", [("flags", ConstructorParameterDescription(_data.flags)), ("title", ConstructorParameterDescription(_data.title))])
            }
        }

        public static func parse_historyImportParsed(_ reader: BufferReader) -> HistoryImportParsed? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _2 = parseString(reader)
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _2 != nil
            if _c1 && _c2 {
                return Api.messages.HistoryImportParsed.historyImportParsed(Cons_historyImportParsed(flags: _1!, title: _2))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum InactiveChats: TypeConstructorDescription {
        public class Cons_inactiveChats: TypeConstructorDescription {
            public var dates: [Int32]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(dates: [Int32], chats: [Api.Chat], users: [Api.User]) {
                self.dates = dates
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inactiveChats", [("dates", ConstructorParameterDescription(self.dates)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case inactiveChats(Cons_inactiveChats)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .inactiveChats(let _data):
                if boxed {
                    buffer.appendInt32(-1456996667)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.dates.count))
                for item in _data.dates {
                    serializeInt32(item, buffer: buffer, boxed: false)
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
            case .inactiveChats(let _data):
                return ("inactiveChats", [("dates", ConstructorParameterDescription(_data.dates)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_inactiveChats(_ reader: BufferReader) -> InactiveChats? {
            var _1: [Int32]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: -1471112230, elementType: Int32.self)
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
                return Api.messages.InactiveChats.inactiveChats(Cons_inactiveChats(dates: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    indirect enum InvitedUsers: TypeConstructorDescription {
        public class Cons_invitedUsers: TypeConstructorDescription {
            public var updates: Api.Updates
            public var missingInvitees: [Api.MissingInvitee]
            public init(updates: Api.Updates, missingInvitees: [Api.MissingInvitee]) {
                self.updates = updates
                self.missingInvitees = missingInvitees
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("invitedUsers", [("updates", ConstructorParameterDescription(self.updates)), ("missingInvitees", ConstructorParameterDescription(self.missingInvitees))])
            }
        }
        case invitedUsers(Cons_invitedUsers)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .invitedUsers(let _data):
                if boxed {
                    buffer.appendInt32(2136862630)
                }
                _data.updates.serialize(buffer, true)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.missingInvitees.count))
                for item in _data.missingInvitees {
                    item.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .invitedUsers(let _data):
                return ("invitedUsers", [("updates", ConstructorParameterDescription(_data.updates)), ("missingInvitees", ConstructorParameterDescription(_data.missingInvitees))])
            }
        }

        public static func parse_invitedUsers(_ reader: BufferReader) -> InvitedUsers? {
            var _1: Api.Updates?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.Updates
            }
            var _2: [Api.MissingInvitee]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.MissingInvitee.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.InvitedUsers.invitedUsers(Cons_invitedUsers(updates: _1!, missingInvitees: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum MessageEditData: TypeConstructorDescription {
        public class Cons_messageEditData: TypeConstructorDescription {
            public var flags: Int32
            public init(flags: Int32) {
                self.flags = flags
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("messageEditData", [("flags", ConstructorParameterDescription(self.flags))])
            }
        }
        case messageEditData(Cons_messageEditData)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .messageEditData(let _data):
                if boxed {
                    buffer.appendInt32(649453030)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .messageEditData(let _data):
                return ("messageEditData", [("flags", ConstructorParameterDescription(_data.flags))])
            }
        }

        public static func parse_messageEditData(_ reader: BufferReader) -> MessageEditData? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.messages.MessageEditData.messageEditData(Cons_messageEditData(flags: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum MessageReactionsList: TypeConstructorDescription {
        public class Cons_messageReactionsList: TypeConstructorDescription {
            public var flags: Int32
            public var count: Int32
            public var reactions: [Api.MessagePeerReaction]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public var nextOffset: String?
            public init(flags: Int32, count: Int32, reactions: [Api.MessagePeerReaction], chats: [Api.Chat], users: [Api.User], nextOffset: String?) {
                self.flags = flags
                self.count = count
                self.reactions = reactions
                self.chats = chats
                self.users = users
                self.nextOffset = nextOffset
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("messageReactionsList", [("flags", ConstructorParameterDescription(self.flags)), ("count", ConstructorParameterDescription(self.count)), ("reactions", ConstructorParameterDescription(self.reactions)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users)), ("nextOffset", ConstructorParameterDescription(self.nextOffset))])
            }
        }
        case messageReactionsList(Cons_messageReactionsList)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .messageReactionsList(let _data):
                if boxed {
                    buffer.appendInt32(834488621)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.reactions.count))
                for item in _data.reactions {
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
            case .messageReactionsList(let _data):
                return ("messageReactionsList", [("flags", ConstructorParameterDescription(_data.flags)), ("count", ConstructorParameterDescription(_data.count)), ("reactions", ConstructorParameterDescription(_data.reactions)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users)), ("nextOffset", ConstructorParameterDescription(_data.nextOffset))])
            }
        }

        public static func parse_messageReactionsList(_ reader: BufferReader) -> MessageReactionsList? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: [Api.MessagePeerReaction]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.MessagePeerReaction.self)
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
                return Api.messages.MessageReactionsList.messageReactionsList(Cons_messageReactionsList(flags: _1!, count: _2!, reactions: _3!, chats: _4!, users: _5!, nextOffset: _6))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum MessageViews: TypeConstructorDescription {
        public class Cons_messageViews: TypeConstructorDescription {
            public var views: [Api.MessageViews]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(views: [Api.MessageViews], chats: [Api.Chat], users: [Api.User]) {
                self.views = views
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("messageViews", [("views", ConstructorParameterDescription(self.views)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case messageViews(Cons_messageViews)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .messageViews(let _data):
                if boxed {
                    buffer.appendInt32(-1228606141)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.views.count))
                for item in _data.views {
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
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .messageViews(let _data):
                return ("messageViews", [("views", ConstructorParameterDescription(_data.views)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_messageViews(_ reader: BufferReader) -> MessageViews? {
            var _1: [Api.MessageViews]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.MessageViews.self)
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
                return Api.messages.MessageViews.messageViews(Cons_messageViews(views: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum Messages: TypeConstructorDescription {
        public class Cons_channelMessages: TypeConstructorDescription {
            public var flags: Int32
            public var pts: Int32
            public var count: Int32
            public var offsetIdOffset: Int32?
            public var messages: [Api.Message]
            public var topics: [Api.ForumTopic]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(flags: Int32, pts: Int32, count: Int32, offsetIdOffset: Int32?, messages: [Api.Message], topics: [Api.ForumTopic], chats: [Api.Chat], users: [Api.User]) {
                self.flags = flags
                self.pts = pts
                self.count = count
                self.offsetIdOffset = offsetIdOffset
                self.messages = messages
                self.topics = topics
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("channelMessages", [("flags", ConstructorParameterDescription(self.flags)), ("pts", ConstructorParameterDescription(self.pts)), ("count", ConstructorParameterDescription(self.count)), ("offsetIdOffset", ConstructorParameterDescription(self.offsetIdOffset)), ("messages", ConstructorParameterDescription(self.messages)), ("topics", ConstructorParameterDescription(self.topics)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        public class Cons_messages: TypeConstructorDescription {
            public var messages: [Api.Message]
            public var topics: [Api.ForumTopic]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(messages: [Api.Message], topics: [Api.ForumTopic], chats: [Api.Chat], users: [Api.User]) {
                self.messages = messages
                self.topics = topics
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("messages", [("messages", ConstructorParameterDescription(self.messages)), ("topics", ConstructorParameterDescription(self.topics)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        public class Cons_messagesNotModified: TypeConstructorDescription {
            public var count: Int32
            public init(count: Int32) {
                self.count = count
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("messagesNotModified", [("count", ConstructorParameterDescription(self.count))])
            }
        }
        public class Cons_messagesSlice: TypeConstructorDescription {
            public var flags: Int32
            public var count: Int32
            public var nextRate: Int32?
            public var offsetIdOffset: Int32?
            public var searchFlood: Api.SearchPostsFlood?
            public var messages: [Api.Message]
            public var topics: [Api.ForumTopic]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(flags: Int32, count: Int32, nextRate: Int32?, offsetIdOffset: Int32?, searchFlood: Api.SearchPostsFlood?, messages: [Api.Message], topics: [Api.ForumTopic], chats: [Api.Chat], users: [Api.User]) {
                self.flags = flags
                self.count = count
                self.nextRate = nextRate
                self.offsetIdOffset = offsetIdOffset
                self.searchFlood = searchFlood
                self.messages = messages
                self.topics = topics
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("messagesSlice", [("flags", ConstructorParameterDescription(self.flags)), ("count", ConstructorParameterDescription(self.count)), ("nextRate", ConstructorParameterDescription(self.nextRate)), ("offsetIdOffset", ConstructorParameterDescription(self.offsetIdOffset)), ("searchFlood", ConstructorParameterDescription(self.searchFlood)), ("messages", ConstructorParameterDescription(self.messages)), ("topics", ConstructorParameterDescription(self.topics)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case channelMessages(Cons_channelMessages)
        case messages(Cons_messages)
        case messagesNotModified(Cons_messagesNotModified)
        case messagesSlice(Cons_messagesSlice)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .channelMessages(let _data):
                if boxed {
                    buffer.appendInt32(-948520370)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.pts, buffer: buffer, boxed: false)
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeInt32(_data.offsetIdOffset!, buffer: buffer, boxed: false)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.messages.count))
                for item in _data.messages {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.topics.count))
                for item in _data.topics {
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
            case .messages(let _data):
                if boxed {
                    buffer.appendInt32(494135274)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.messages.count))
                for item in _data.messages {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.topics.count))
                for item in _data.topics {
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
            case .messagesNotModified(let _data):
                if boxed {
                    buffer.appendInt32(1951620897)
                }
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                break
            case .messagesSlice(let _data):
                if boxed {
                    buffer.appendInt32(1595959062)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeInt32(_data.nextRate!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeInt32(_data.offsetIdOffset!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 3) != 0 {
                    _data.searchFlood!.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.messages.count))
                for item in _data.messages {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.topics.count))
                for item in _data.topics {
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
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .channelMessages(let _data):
                return ("channelMessages", [("flags", ConstructorParameterDescription(_data.flags)), ("pts", ConstructorParameterDescription(_data.pts)), ("count", ConstructorParameterDescription(_data.count)), ("offsetIdOffset", ConstructorParameterDescription(_data.offsetIdOffset)), ("messages", ConstructorParameterDescription(_data.messages)), ("topics", ConstructorParameterDescription(_data.topics)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            case .messages(let _data):
                return ("messages", [("messages", ConstructorParameterDescription(_data.messages)), ("topics", ConstructorParameterDescription(_data.topics)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            case .messagesNotModified(let _data):
                return ("messagesNotModified", [("count", ConstructorParameterDescription(_data.count))])
            case .messagesSlice(let _data):
                return ("messagesSlice", [("flags", ConstructorParameterDescription(_data.flags)), ("count", ConstructorParameterDescription(_data.count)), ("nextRate", ConstructorParameterDescription(_data.nextRate)), ("offsetIdOffset", ConstructorParameterDescription(_data.offsetIdOffset)), ("searchFlood", ConstructorParameterDescription(_data.searchFlood)), ("messages", ConstructorParameterDescription(_data.messages)), ("topics", ConstructorParameterDescription(_data.topics)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_channelMessages(_ reader: BufferReader) -> Messages? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            _3 = reader.readInt32()
            var _4: Int32?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _4 = reader.readInt32()
            }
            var _5: [Api.Message]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _6: [Api.ForumTopic]?
            if let _ = reader.readInt32() {
                _6 = Api.parseVector(reader, elementSignature: 0, elementType: Api.ForumTopic.self)
            }
            var _7: [Api.Chat]?
            if let _ = reader.readInt32() {
                _7 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _8: [Api.User]?
            if let _ = reader.readInt32() {
                _8 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            let _c7 = _7 != nil
            let _c8 = _8 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 {
                return Api.messages.Messages.channelMessages(Cons_channelMessages(flags: _1!, pts: _2!, count: _3!, offsetIdOffset: _4, messages: _5!, topics: _6!, chats: _7!, users: _8!))
            }
            else {
                return nil
            }
        }
        public static func parse_messages(_ reader: BufferReader) -> Messages? {
            var _1: [Api.Message]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _2: [Api.ForumTopic]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.ForumTopic.self)
            }
            var _3: [Api.Chat]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _4: [Api.User]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.messages.Messages.messages(Cons_messages(messages: _1!, topics: _2!, chats: _3!, users: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_messagesNotModified(_ reader: BufferReader) -> Messages? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.messages.Messages.messagesNotModified(Cons_messagesNotModified(count: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_messagesSlice(_ reader: BufferReader) -> Messages? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _3 = reader.readInt32()
            }
            var _4: Int32?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _4 = reader.readInt32()
            }
            var _5: Api.SearchPostsFlood?
            if Int(_1 ?? 0) & Int(1 << 3) != 0 {
                if let signature = reader.readInt32() {
                    _5 = Api.parse(reader, signature: signature) as? Api.SearchPostsFlood
                }
            }
            var _6: [Api.Message]?
            if let _ = reader.readInt32() {
                _6 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _7: [Api.ForumTopic]?
            if let _ = reader.readInt32() {
                _7 = Api.parseVector(reader, elementSignature: 0, elementType: Api.ForumTopic.self)
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
            let _c2 = _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 3) == 0) || _5 != nil
            let _c6 = _6 != nil
            let _c7 = _7 != nil
            let _c8 = _8 != nil
            let _c9 = _9 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 && _c9 {
                return Api.messages.Messages.messagesSlice(Cons_messagesSlice(flags: _1!, count: _2!, nextRate: _3, offsetIdOffset: _4, searchFlood: _5, messages: _6!, topics: _7!, chats: _8!, users: _9!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum MyStickers: TypeConstructorDescription {
        public class Cons_myStickers: TypeConstructorDescription {
            public var count: Int32
            public var sets: [Api.StickerSetCovered]
            public init(count: Int32, sets: [Api.StickerSetCovered]) {
                self.count = count
                self.sets = sets
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("myStickers", [("count", ConstructorParameterDescription(self.count)), ("sets", ConstructorParameterDescription(self.sets))])
            }
        }
        case myStickers(Cons_myStickers)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .myStickers(let _data):
                if boxed {
                    buffer.appendInt32(-83926371)
                }
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.sets.count))
                for item in _data.sets {
                    item.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .myStickers(let _data):
                return ("myStickers", [("count", ConstructorParameterDescription(_data.count)), ("sets", ConstructorParameterDescription(_data.sets))])
            }
        }

        public static func parse_myStickers(_ reader: BufferReader) -> MyStickers? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.StickerSetCovered]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerSetCovered.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.MyStickers.myStickers(Cons_myStickers(count: _1!, sets: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum PeerDialogs: TypeConstructorDescription {
        public class Cons_peerDialogs: TypeConstructorDescription {
            public var dialogs: [Api.Dialog]
            public var messages: [Api.Message]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public var state: Api.updates.State
            public init(dialogs: [Api.Dialog], messages: [Api.Message], chats: [Api.Chat], users: [Api.User], state: Api.updates.State) {
                self.dialogs = dialogs
                self.messages = messages
                self.chats = chats
                self.users = users
                self.state = state
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("peerDialogs", [("dialogs", ConstructorParameterDescription(self.dialogs)), ("messages", ConstructorParameterDescription(self.messages)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users)), ("state", ConstructorParameterDescription(self.state))])
            }
        }
        case peerDialogs(Cons_peerDialogs)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .peerDialogs(let _data):
                if boxed {
                    buffer.appendInt32(863093588)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.dialogs.count))
                for item in _data.dialogs {
                    item.serialize(buffer, true)
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
                _data.state.serialize(buffer, true)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .peerDialogs(let _data):
                return ("peerDialogs", [("dialogs", ConstructorParameterDescription(_data.dialogs)), ("messages", ConstructorParameterDescription(_data.messages)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users)), ("state", ConstructorParameterDescription(_data.state))])
            }
        }

        public static func parse_peerDialogs(_ reader: BufferReader) -> PeerDialogs? {
            var _1: [Api.Dialog]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Dialog.self)
            }
            var _2: [Api.Message]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _3: [Api.Chat]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _4: [Api.User]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            var _5: Api.updates.State?
            if let signature = reader.readInt32() {
                _5 = Api.parse(reader, signature: signature) as? Api.updates.State
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.messages.PeerDialogs.peerDialogs(Cons_peerDialogs(dialogs: _1!, messages: _2!, chats: _3!, users: _4!, state: _5!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum PeerSettings: TypeConstructorDescription {
        public class Cons_peerSettings: TypeConstructorDescription {
            public var settings: Api.PeerSettings
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(settings: Api.PeerSettings, chats: [Api.Chat], users: [Api.User]) {
                self.settings = settings
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("peerSettings", [("settings", ConstructorParameterDescription(self.settings)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case peerSettings(Cons_peerSettings)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .peerSettings(let _data):
                if boxed {
                    buffer.appendInt32(1753266509)
                }
                _data.settings.serialize(buffer, true)
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
            case .peerSettings(let _data):
                return ("peerSettings", [("settings", ConstructorParameterDescription(_data.settings)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_peerSettings(_ reader: BufferReader) -> PeerSettings? {
            var _1: Api.PeerSettings?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.PeerSettings
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
                return Api.messages.PeerSettings.peerSettings(Cons_peerSettings(settings: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum PreparedInlineMessage: TypeConstructorDescription {
        public class Cons_preparedInlineMessage: TypeConstructorDescription {
            public var queryId: Int64
            public var result: Api.BotInlineResult
            public var peerTypes: [Api.InlineQueryPeerType]
            public var cacheTime: Int32
            public var users: [Api.User]
            public init(queryId: Int64, result: Api.BotInlineResult, peerTypes: [Api.InlineQueryPeerType], cacheTime: Int32, users: [Api.User]) {
                self.queryId = queryId
                self.result = result
                self.peerTypes = peerTypes
                self.cacheTime = cacheTime
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("preparedInlineMessage", [("queryId", ConstructorParameterDescription(self.queryId)), ("result", ConstructorParameterDescription(self.result)), ("peerTypes", ConstructorParameterDescription(self.peerTypes)), ("cacheTime", ConstructorParameterDescription(self.cacheTime)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case preparedInlineMessage(Cons_preparedInlineMessage)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .preparedInlineMessage(let _data):
                if boxed {
                    buffer.appendInt32(-11046771)
                }
                serializeInt64(_data.queryId, buffer: buffer, boxed: false)
                _data.result.serialize(buffer, true)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.peerTypes.count))
                for item in _data.peerTypes {
                    item.serialize(buffer, true)
                }
                serializeInt32(_data.cacheTime, buffer: buffer, boxed: false)
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
            case .preparedInlineMessage(let _data):
                return ("preparedInlineMessage", [("queryId", ConstructorParameterDescription(_data.queryId)), ("result", ConstructorParameterDescription(_data.result)), ("peerTypes", ConstructorParameterDescription(_data.peerTypes)), ("cacheTime", ConstructorParameterDescription(_data.cacheTime)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_preparedInlineMessage(_ reader: BufferReader) -> PreparedInlineMessage? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: Api.BotInlineResult?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.BotInlineResult
            }
            var _3: [Api.InlineQueryPeerType]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.InlineQueryPeerType.self)
            }
            var _4: Int32?
            _4 = reader.readInt32()
            var _5: [Api.User]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.messages.PreparedInlineMessage.preparedInlineMessage(Cons_preparedInlineMessage(queryId: _1!, result: _2!, peerTypes: _3!, cacheTime: _4!, users: _5!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum QuickReplies: TypeConstructorDescription {
        public class Cons_quickReplies: TypeConstructorDescription {
            public var quickReplies: [Api.QuickReply]
            public var messages: [Api.Message]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(quickReplies: [Api.QuickReply], messages: [Api.Message], chats: [Api.Chat], users: [Api.User]) {
                self.quickReplies = quickReplies
                self.messages = messages
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("quickReplies", [("quickReplies", ConstructorParameterDescription(self.quickReplies)), ("messages", ConstructorParameterDescription(self.messages)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case quickReplies(Cons_quickReplies)
        case quickRepliesNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .quickReplies(let _data):
                if boxed {
                    buffer.appendInt32(-963811691)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.quickReplies.count))
                for item in _data.quickReplies {
                    item.serialize(buffer, true)
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
            case .quickRepliesNotModified:
                if boxed {
                    buffer.appendInt32(1603398491)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .quickReplies(let _data):
                return ("quickReplies", [("quickReplies", ConstructorParameterDescription(_data.quickReplies)), ("messages", ConstructorParameterDescription(_data.messages)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            case .quickRepliesNotModified:
                return ("quickRepliesNotModified", [])
            }
        }

        public static func parse_quickReplies(_ reader: BufferReader) -> QuickReplies? {
            var _1: [Api.QuickReply]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.QuickReply.self)
            }
            var _2: [Api.Message]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _3: [Api.Chat]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _4: [Api.User]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.messages.QuickReplies.quickReplies(Cons_quickReplies(quickReplies: _1!, messages: _2!, chats: _3!, users: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_quickRepliesNotModified(_ reader: BufferReader) -> QuickReplies? {
            return Api.messages.QuickReplies.quickRepliesNotModified
        }
    }
}
public extension Api.messages {
    enum Reactions: TypeConstructorDescription {
        public class Cons_reactions: TypeConstructorDescription {
            public var hash: Int64
            public var reactions: [Api.Reaction]
            public init(hash: Int64, reactions: [Api.Reaction]) {
                self.hash = hash
                self.reactions = reactions
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("reactions", [("hash", ConstructorParameterDescription(self.hash)), ("reactions", ConstructorParameterDescription(self.reactions))])
            }
        }
        case reactions(Cons_reactions)
        case reactionsNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .reactions(let _data):
                if boxed {
                    buffer.appendInt32(-352454890)
                }
                serializeInt64(_data.hash, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.reactions.count))
                for item in _data.reactions {
                    item.serialize(buffer, true)
                }
                break
            case .reactionsNotModified:
                if boxed {
                    buffer.appendInt32(-1334846497)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .reactions(let _data):
                return ("reactions", [("hash", ConstructorParameterDescription(_data.hash)), ("reactions", ConstructorParameterDescription(_data.reactions))])
            case .reactionsNotModified:
                return ("reactionsNotModified", [])
            }
        }

        public static func parse_reactions(_ reader: BufferReader) -> Reactions? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: [Api.Reaction]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Reaction.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.Reactions.reactions(Cons_reactions(hash: _1!, reactions: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_reactionsNotModified(_ reader: BufferReader) -> Reactions? {
            return Api.messages.Reactions.reactionsNotModified
        }
    }
}
public extension Api.messages {
    enum RecentStickers: TypeConstructorDescription {
        public class Cons_recentStickers: TypeConstructorDescription {
            public var hash: Int64
            public var packs: [Api.StickerPack]
            public var stickers: [Api.Document]
            public var dates: [Int32]
            public init(hash: Int64, packs: [Api.StickerPack], stickers: [Api.Document], dates: [Int32]) {
                self.hash = hash
                self.packs = packs
                self.stickers = stickers
                self.dates = dates
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("recentStickers", [("hash", ConstructorParameterDescription(self.hash)), ("packs", ConstructorParameterDescription(self.packs)), ("stickers", ConstructorParameterDescription(self.stickers)), ("dates", ConstructorParameterDescription(self.dates))])
            }
        }
        case recentStickers(Cons_recentStickers)
        case recentStickersNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .recentStickers(let _data):
                if boxed {
                    buffer.appendInt32(-1999405994)
                }
                serializeInt64(_data.hash, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.packs.count))
                for item in _data.packs {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.stickers.count))
                for item in _data.stickers {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.dates.count))
                for item in _data.dates {
                    serializeInt32(item, buffer: buffer, boxed: false)
                }
                break
            case .recentStickersNotModified:
                if boxed {
                    buffer.appendInt32(186120336)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .recentStickers(let _data):
                return ("recentStickers", [("hash", ConstructorParameterDescription(_data.hash)), ("packs", ConstructorParameterDescription(_data.packs)), ("stickers", ConstructorParameterDescription(_data.stickers)), ("dates", ConstructorParameterDescription(_data.dates))])
            case .recentStickersNotModified:
                return ("recentStickersNotModified", [])
            }
        }

        public static func parse_recentStickers(_ reader: BufferReader) -> RecentStickers? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: [Api.StickerPack]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerPack.self)
            }
            var _3: [Api.Document]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Document.self)
            }
            var _4: [Int32]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: -1471112230, elementType: Int32.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.messages.RecentStickers.recentStickers(Cons_recentStickers(hash: _1!, packs: _2!, stickers: _3!, dates: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_recentStickersNotModified(_ reader: BufferReader) -> RecentStickers? {
            return Api.messages.RecentStickers.recentStickersNotModified
        }
    }
}
public extension Api.messages {
    enum SavedDialogs: TypeConstructorDescription {
        public class Cons_savedDialogs: TypeConstructorDescription {
            public var dialogs: [Api.SavedDialog]
            public var messages: [Api.Message]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(dialogs: [Api.SavedDialog], messages: [Api.Message], chats: [Api.Chat], users: [Api.User]) {
                self.dialogs = dialogs
                self.messages = messages
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("savedDialogs", [("dialogs", ConstructorParameterDescription(self.dialogs)), ("messages", ConstructorParameterDescription(self.messages)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        public class Cons_savedDialogsNotModified: TypeConstructorDescription {
            public var count: Int32
            public init(count: Int32) {
                self.count = count
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("savedDialogsNotModified", [("count", ConstructorParameterDescription(self.count))])
            }
        }
        public class Cons_savedDialogsSlice: TypeConstructorDescription {
            public var count: Int32
            public var dialogs: [Api.SavedDialog]
            public var messages: [Api.Message]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(count: Int32, dialogs: [Api.SavedDialog], messages: [Api.Message], chats: [Api.Chat], users: [Api.User]) {
                self.count = count
                self.dialogs = dialogs
                self.messages = messages
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("savedDialogsSlice", [("count", ConstructorParameterDescription(self.count)), ("dialogs", ConstructorParameterDescription(self.dialogs)), ("messages", ConstructorParameterDescription(self.messages)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case savedDialogs(Cons_savedDialogs)
        case savedDialogsNotModified(Cons_savedDialogsNotModified)
        case savedDialogsSlice(Cons_savedDialogsSlice)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .savedDialogs(let _data):
                if boxed {
                    buffer.appendInt32(-130358751)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.dialogs.count))
                for item in _data.dialogs {
                    item.serialize(buffer, true)
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
            case .savedDialogsNotModified(let _data):
                if boxed {
                    buffer.appendInt32(-1071681560)
                }
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                break
            case .savedDialogsSlice(let _data):
                if boxed {
                    buffer.appendInt32(1153080793)
                }
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.dialogs.count))
                for item in _data.dialogs {
                    item.serialize(buffer, true)
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
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .savedDialogs(let _data):
                return ("savedDialogs", [("dialogs", ConstructorParameterDescription(_data.dialogs)), ("messages", ConstructorParameterDescription(_data.messages)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            case .savedDialogsNotModified(let _data):
                return ("savedDialogsNotModified", [("count", ConstructorParameterDescription(_data.count))])
            case .savedDialogsSlice(let _data):
                return ("savedDialogsSlice", [("count", ConstructorParameterDescription(_data.count)), ("dialogs", ConstructorParameterDescription(_data.dialogs)), ("messages", ConstructorParameterDescription(_data.messages)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_savedDialogs(_ reader: BufferReader) -> SavedDialogs? {
            var _1: [Api.SavedDialog]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.SavedDialog.self)
            }
            var _2: [Api.Message]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _3: [Api.Chat]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _4: [Api.User]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.messages.SavedDialogs.savedDialogs(Cons_savedDialogs(dialogs: _1!, messages: _2!, chats: _3!, users: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_savedDialogsNotModified(_ reader: BufferReader) -> SavedDialogs? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.messages.SavedDialogs.savedDialogsNotModified(Cons_savedDialogsNotModified(count: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_savedDialogsSlice(_ reader: BufferReader) -> SavedDialogs? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.SavedDialog]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.SavedDialog.self)
            }
            var _3: [Api.Message]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _4: [Api.Chat]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _5: [Api.User]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.messages.SavedDialogs.savedDialogsSlice(Cons_savedDialogsSlice(count: _1!, dialogs: _2!, messages: _3!, chats: _4!, users: _5!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum SavedGifs: TypeConstructorDescription {
        public class Cons_savedGifs: TypeConstructorDescription {
            public var hash: Int64
            public var gifs: [Api.Document]
            public init(hash: Int64, gifs: [Api.Document]) {
                self.hash = hash
                self.gifs = gifs
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("savedGifs", [("hash", ConstructorParameterDescription(self.hash)), ("gifs", ConstructorParameterDescription(self.gifs))])
            }
        }
        case savedGifs(Cons_savedGifs)
        case savedGifsNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .savedGifs(let _data):
                if boxed {
                    buffer.appendInt32(-2069878259)
                }
                serializeInt64(_data.hash, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.gifs.count))
                for item in _data.gifs {
                    item.serialize(buffer, true)
                }
                break
            case .savedGifsNotModified:
                if boxed {
                    buffer.appendInt32(-402498398)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .savedGifs(let _data):
                return ("savedGifs", [("hash", ConstructorParameterDescription(_data.hash)), ("gifs", ConstructorParameterDescription(_data.gifs))])
            case .savedGifsNotModified:
                return ("savedGifsNotModified", [])
            }
        }

        public static func parse_savedGifs(_ reader: BufferReader) -> SavedGifs? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: [Api.Document]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Document.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.SavedGifs.savedGifs(Cons_savedGifs(hash: _1!, gifs: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_savedGifsNotModified(_ reader: BufferReader) -> SavedGifs? {
            return Api.messages.SavedGifs.savedGifsNotModified
        }
    }
}
public extension Api.messages {
    enum SavedReactionTags: TypeConstructorDescription {
        public class Cons_savedReactionTags: TypeConstructorDescription {
            public var tags: [Api.SavedReactionTag]
            public var hash: Int64
            public init(tags: [Api.SavedReactionTag], hash: Int64) {
                self.tags = tags
                self.hash = hash
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("savedReactionTags", [("tags", ConstructorParameterDescription(self.tags)), ("hash", ConstructorParameterDescription(self.hash))])
            }
        }
        case savedReactionTags(Cons_savedReactionTags)
        case savedReactionTagsNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .savedReactionTags(let _data):
                if boxed {
                    buffer.appendInt32(844731658)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.tags.count))
                for item in _data.tags {
                    item.serialize(buffer, true)
                }
                serializeInt64(_data.hash, buffer: buffer, boxed: false)
                break
            case .savedReactionTagsNotModified:
                if boxed {
                    buffer.appendInt32(-2003084817)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .savedReactionTags(let _data):
                return ("savedReactionTags", [("tags", ConstructorParameterDescription(_data.tags)), ("hash", ConstructorParameterDescription(_data.hash))])
            case .savedReactionTagsNotModified:
                return ("savedReactionTagsNotModified", [])
            }
        }

        public static func parse_savedReactionTags(_ reader: BufferReader) -> SavedReactionTags? {
            var _1: [Api.SavedReactionTag]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.SavedReactionTag.self)
            }
            var _2: Int64?
            _2 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.SavedReactionTags.savedReactionTags(Cons_savedReactionTags(tags: _1!, hash: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_savedReactionTagsNotModified(_ reader: BufferReader) -> SavedReactionTags? {
            return Api.messages.SavedReactionTags.savedReactionTagsNotModified
        }
    }
}
public extension Api.messages {
    enum SearchCounter: TypeConstructorDescription {
        public class Cons_searchCounter: TypeConstructorDescription {
            public var flags: Int32
            public var filter: Api.MessagesFilter
            public var count: Int32
            public init(flags: Int32, filter: Api.MessagesFilter, count: Int32) {
                self.flags = flags
                self.filter = filter
                self.count = count
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("searchCounter", [("flags", ConstructorParameterDescription(self.flags)), ("filter", ConstructorParameterDescription(self.filter)), ("count", ConstructorParameterDescription(self.count))])
            }
        }
        case searchCounter(Cons_searchCounter)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .searchCounter(let _data):
                if boxed {
                    buffer.appendInt32(-398136321)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                _data.filter.serialize(buffer, true)
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .searchCounter(let _data):
                return ("searchCounter", [("flags", ConstructorParameterDescription(_data.flags)), ("filter", ConstructorParameterDescription(_data.filter)), ("count", ConstructorParameterDescription(_data.count))])
            }
        }

        public static func parse_searchCounter(_ reader: BufferReader) -> SearchCounter? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.MessagesFilter?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.MessagesFilter
            }
            var _3: Int32?
            _3 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.messages.SearchCounter.searchCounter(Cons_searchCounter(flags: _1!, filter: _2!, count: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum SearchResultsCalendar: TypeConstructorDescription {
        public class Cons_searchResultsCalendar: TypeConstructorDescription {
            public var flags: Int32
            public var count: Int32
            public var minDate: Int32
            public var minMsgId: Int32
            public var offsetIdOffset: Int32?
            public var periods: [Api.SearchResultsCalendarPeriod]
            public var messages: [Api.Message]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(flags: Int32, count: Int32, minDate: Int32, minMsgId: Int32, offsetIdOffset: Int32?, periods: [Api.SearchResultsCalendarPeriod], messages: [Api.Message], chats: [Api.Chat], users: [Api.User]) {
                self.flags = flags
                self.count = count
                self.minDate = minDate
                self.minMsgId = minMsgId
                self.offsetIdOffset = offsetIdOffset
                self.periods = periods
                self.messages = messages
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("searchResultsCalendar", [("flags", ConstructorParameterDescription(self.flags)), ("count", ConstructorParameterDescription(self.count)), ("minDate", ConstructorParameterDescription(self.minDate)), ("minMsgId", ConstructorParameterDescription(self.minMsgId)), ("offsetIdOffset", ConstructorParameterDescription(self.offsetIdOffset)), ("periods", ConstructorParameterDescription(self.periods)), ("messages", ConstructorParameterDescription(self.messages)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case searchResultsCalendar(Cons_searchResultsCalendar)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .searchResultsCalendar(let _data):
                if boxed {
                    buffer.appendInt32(343859772)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                serializeInt32(_data.minDate, buffer: buffer, boxed: false)
                serializeInt32(_data.minMsgId, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeInt32(_data.offsetIdOffset!, buffer: buffer, boxed: false)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.periods.count))
                for item in _data.periods {
                    item.serialize(buffer, true)
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
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .searchResultsCalendar(let _data):
                return ("searchResultsCalendar", [("flags", ConstructorParameterDescription(_data.flags)), ("count", ConstructorParameterDescription(_data.count)), ("minDate", ConstructorParameterDescription(_data.minDate)), ("minMsgId", ConstructorParameterDescription(_data.minMsgId)), ("offsetIdOffset", ConstructorParameterDescription(_data.offsetIdOffset)), ("periods", ConstructorParameterDescription(_data.periods)), ("messages", ConstructorParameterDescription(_data.messages)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_searchResultsCalendar(_ reader: BufferReader) -> SearchResultsCalendar? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            _3 = reader.readInt32()
            var _4: Int32?
            _4 = reader.readInt32()
            var _5: Int32?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _5 = reader.readInt32()
            }
            var _6: [Api.SearchResultsCalendarPeriod]?
            if let _ = reader.readInt32() {
                _6 = Api.parseVector(reader, elementSignature: 0, elementType: Api.SearchResultsCalendarPeriod.self)
            }
            var _7: [Api.Message]?
            if let _ = reader.readInt32() {
                _7 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
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
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _5 != nil
            let _c6 = _6 != nil
            let _c7 = _7 != nil
            let _c8 = _8 != nil
            let _c9 = _9 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 && _c9 {
                return Api.messages.SearchResultsCalendar.searchResultsCalendar(Cons_searchResultsCalendar(flags: _1!, count: _2!, minDate: _3!, minMsgId: _4!, offsetIdOffset: _5, periods: _6!, messages: _7!, chats: _8!, users: _9!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum SearchResultsPositions: TypeConstructorDescription {
        public class Cons_searchResultsPositions: TypeConstructorDescription {
            public var count: Int32
            public var positions: [Api.SearchResultsPosition]
            public init(count: Int32, positions: [Api.SearchResultsPosition]) {
                self.count = count
                self.positions = positions
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("searchResultsPositions", [("count", ConstructorParameterDescription(self.count)), ("positions", ConstructorParameterDescription(self.positions))])
            }
        }
        case searchResultsPositions(Cons_searchResultsPositions)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .searchResultsPositions(let _data):
                if boxed {
                    buffer.appendInt32(1404185519)
                }
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.positions.count))
                for item in _data.positions {
                    item.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .searchResultsPositions(let _data):
                return ("searchResultsPositions", [("count", ConstructorParameterDescription(_data.count)), ("positions", ConstructorParameterDescription(_data.positions))])
            }
        }

        public static func parse_searchResultsPositions(_ reader: BufferReader) -> SearchResultsPositions? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.SearchResultsPosition]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.SearchResultsPosition.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.SearchResultsPositions.searchResultsPositions(Cons_searchResultsPositions(count: _1!, positions: _2!))
            }
            else {
                return nil
            }
        }
    }
}
