public extension Api.updates {
    indirect enum ChannelDifference: TypeConstructorDescription {
        public class Cons_channelDifference: TypeConstructorDescription {
            public var flags: Int32
            public var pts: Int32
            public var timeout: Int32?
            public var newMessages: [Api.Message]
            public var otherUpdates: [Api.Update]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(flags: Int32, pts: Int32, timeout: Int32?, newMessages: [Api.Message], otherUpdates: [Api.Update], chats: [Api.Chat], users: [Api.User]) {
                self.flags = flags
                self.pts = pts
                self.timeout = timeout
                self.newMessages = newMessages
                self.otherUpdates = otherUpdates
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("channelDifference", [("flags", ConstructorParameterDescription(self.flags)), ("pts", ConstructorParameterDescription(self.pts)), ("timeout", ConstructorParameterDescription(self.timeout)), ("newMessages", ConstructorParameterDescription(self.newMessages)), ("otherUpdates", ConstructorParameterDescription(self.otherUpdates)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        public class Cons_channelDifferenceEmpty: TypeConstructorDescription {
            public var flags: Int32
            public var pts: Int32
            public var timeout: Int32?
            public init(flags: Int32, pts: Int32, timeout: Int32?) {
                self.flags = flags
                self.pts = pts
                self.timeout = timeout
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("channelDifferenceEmpty", [("flags", ConstructorParameterDescription(self.flags)), ("pts", ConstructorParameterDescription(self.pts)), ("timeout", ConstructorParameterDescription(self.timeout))])
            }
        }
        public class Cons_channelDifferenceTooLong: TypeConstructorDescription {
            public var flags: Int32
            public var timeout: Int32?
            public var dialog: Api.Dialog
            public var messages: [Api.Message]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(flags: Int32, timeout: Int32?, dialog: Api.Dialog, messages: [Api.Message], chats: [Api.Chat], users: [Api.User]) {
                self.flags = flags
                self.timeout = timeout
                self.dialog = dialog
                self.messages = messages
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("channelDifferenceTooLong", [("flags", ConstructorParameterDescription(self.flags)), ("timeout", ConstructorParameterDescription(self.timeout)), ("dialog", ConstructorParameterDescription(self.dialog)), ("messages", ConstructorParameterDescription(self.messages)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case channelDifference(Cons_channelDifference)
        case channelDifferenceEmpty(Cons_channelDifferenceEmpty)
        case channelDifferenceTooLong(Cons_channelDifferenceTooLong)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .channelDifference(let _data):
                if boxed {
                    buffer.appendInt32(543450958)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.pts, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeInt32(_data.timeout!, buffer: buffer, boxed: false)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.newMessages.count))
                for item in _data.newMessages {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.otherUpdates.count))
                for item in _data.otherUpdates {
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
            case .channelDifferenceEmpty(let _data):
                if boxed {
                    buffer.appendInt32(1041346555)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.pts, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeInt32(_data.timeout!, buffer: buffer, boxed: false)
                }
                break
            case .channelDifferenceTooLong(let _data):
                if boxed {
                    buffer.appendInt32(-1531132162)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeInt32(_data.timeout!, buffer: buffer, boxed: false)
                }
                _data.dialog.serialize(buffer, true)
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
            case .channelDifference(let _data):
                return ("channelDifference", [("flags", ConstructorParameterDescription(_data.flags)), ("pts", ConstructorParameterDescription(_data.pts)), ("timeout", ConstructorParameterDescription(_data.timeout)), ("newMessages", ConstructorParameterDescription(_data.newMessages)), ("otherUpdates", ConstructorParameterDescription(_data.otherUpdates)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            case .channelDifferenceEmpty(let _data):
                return ("channelDifferenceEmpty", [("flags", ConstructorParameterDescription(_data.flags)), ("pts", ConstructorParameterDescription(_data.pts)), ("timeout", ConstructorParameterDescription(_data.timeout))])
            case .channelDifferenceTooLong(let _data):
                return ("channelDifferenceTooLong", [("flags", ConstructorParameterDescription(_data.flags)), ("timeout", ConstructorParameterDescription(_data.timeout)), ("dialog", ConstructorParameterDescription(_data.dialog)), ("messages", ConstructorParameterDescription(_data.messages)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_channelDifference(_ reader: BufferReader) -> ChannelDifference? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _3 = reader.readInt32()
            }
            var _4: [Api.Message]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _5: [Api.Update]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Update.self)
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
            let _c2 = _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            let _c7 = _7 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 {
                return Api.updates.ChannelDifference.channelDifference(Cons_channelDifference(flags: _1!, pts: _2!, timeout: _3, newMessages: _4!, otherUpdates: _5!, chats: _6!, users: _7!))
            }
            else {
                return nil
            }
        }
        public static func parse_channelDifferenceEmpty(_ reader: BufferReader) -> ChannelDifference? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _3 = reader.readInt32()
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.updates.ChannelDifference.channelDifferenceEmpty(Cons_channelDifferenceEmpty(flags: _1!, pts: _2!, timeout: _3))
            }
            else {
                return nil
            }
        }
        public static func parse_channelDifferenceTooLong(_ reader: BufferReader) -> ChannelDifference? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _2 = reader.readInt32()
            }
            var _3: Api.Dialog?
            if let signature = reader.readInt32() {
                _3 = Api.parse(reader, signature: signature) as? Api.Dialog
            }
            var _4: [Api.Message]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
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
            let _c2 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.updates.ChannelDifference.channelDifferenceTooLong(Cons_channelDifferenceTooLong(flags: _1!, timeout: _2, dialog: _3!, messages: _4!, chats: _5!, users: _6!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.updates {
    enum Difference: TypeConstructorDescription {
        public class Cons_difference: TypeConstructorDescription {
            public var newMessages: [Api.Message]
            public var newEncryptedMessages: [Api.EncryptedMessage]
            public var otherUpdates: [Api.Update]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public var state: Api.updates.State
            public init(newMessages: [Api.Message], newEncryptedMessages: [Api.EncryptedMessage], otherUpdates: [Api.Update], chats: [Api.Chat], users: [Api.User], state: Api.updates.State) {
                self.newMessages = newMessages
                self.newEncryptedMessages = newEncryptedMessages
                self.otherUpdates = otherUpdates
                self.chats = chats
                self.users = users
                self.state = state
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("difference", [("newMessages", ConstructorParameterDescription(self.newMessages)), ("newEncryptedMessages", ConstructorParameterDescription(self.newEncryptedMessages)), ("otherUpdates", ConstructorParameterDescription(self.otherUpdates)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users)), ("state", ConstructorParameterDescription(self.state))])
            }
        }
        public class Cons_differenceEmpty: TypeConstructorDescription {
            public var date: Int32
            public var seq: Int32
            public init(date: Int32, seq: Int32) {
                self.date = date
                self.seq = seq
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("differenceEmpty", [("date", ConstructorParameterDescription(self.date)), ("seq", ConstructorParameterDescription(self.seq))])
            }
        }
        public class Cons_differenceSlice: TypeConstructorDescription {
            public var newMessages: [Api.Message]
            public var newEncryptedMessages: [Api.EncryptedMessage]
            public var otherUpdates: [Api.Update]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public var intermediateState: Api.updates.State
            public init(newMessages: [Api.Message], newEncryptedMessages: [Api.EncryptedMessage], otherUpdates: [Api.Update], chats: [Api.Chat], users: [Api.User], intermediateState: Api.updates.State) {
                self.newMessages = newMessages
                self.newEncryptedMessages = newEncryptedMessages
                self.otherUpdates = otherUpdates
                self.chats = chats
                self.users = users
                self.intermediateState = intermediateState
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("differenceSlice", [("newMessages", ConstructorParameterDescription(self.newMessages)), ("newEncryptedMessages", ConstructorParameterDescription(self.newEncryptedMessages)), ("otherUpdates", ConstructorParameterDescription(self.otherUpdates)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users)), ("intermediateState", ConstructorParameterDescription(self.intermediateState))])
            }
        }
        public class Cons_differenceTooLong: TypeConstructorDescription {
            public var pts: Int32
            public init(pts: Int32) {
                self.pts = pts
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("differenceTooLong", [("pts", ConstructorParameterDescription(self.pts))])
            }
        }
        case difference(Cons_difference)
        case differenceEmpty(Cons_differenceEmpty)
        case differenceSlice(Cons_differenceSlice)
        case differenceTooLong(Cons_differenceTooLong)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .difference(let _data):
                if boxed {
                    buffer.appendInt32(16030880)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.newMessages.count))
                for item in _data.newMessages {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.newEncryptedMessages.count))
                for item in _data.newEncryptedMessages {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.otherUpdates.count))
                for item in _data.otherUpdates {
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
            case .differenceEmpty(let _data):
                if boxed {
                    buffer.appendInt32(1567990072)
                }
                serializeInt32(_data.date, buffer: buffer, boxed: false)
                serializeInt32(_data.seq, buffer: buffer, boxed: false)
                break
            case .differenceSlice(let _data):
                if boxed {
                    buffer.appendInt32(-1459938943)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.newMessages.count))
                for item in _data.newMessages {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.newEncryptedMessages.count))
                for item in _data.newEncryptedMessages {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.otherUpdates.count))
                for item in _data.otherUpdates {
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
                _data.intermediateState.serialize(buffer, true)
                break
            case .differenceTooLong(let _data):
                if boxed {
                    buffer.appendInt32(1258196845)
                }
                serializeInt32(_data.pts, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .difference(let _data):
                return ("difference", [("newMessages", ConstructorParameterDescription(_data.newMessages)), ("newEncryptedMessages", ConstructorParameterDescription(_data.newEncryptedMessages)), ("otherUpdates", ConstructorParameterDescription(_data.otherUpdates)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users)), ("state", ConstructorParameterDescription(_data.state))])
            case .differenceEmpty(let _data):
                return ("differenceEmpty", [("date", ConstructorParameterDescription(_data.date)), ("seq", ConstructorParameterDescription(_data.seq))])
            case .differenceSlice(let _data):
                return ("differenceSlice", [("newMessages", ConstructorParameterDescription(_data.newMessages)), ("newEncryptedMessages", ConstructorParameterDescription(_data.newEncryptedMessages)), ("otherUpdates", ConstructorParameterDescription(_data.otherUpdates)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users)), ("intermediateState", ConstructorParameterDescription(_data.intermediateState))])
            case .differenceTooLong(let _data):
                return ("differenceTooLong", [("pts", ConstructorParameterDescription(_data.pts))])
            }
        }

        public static func parse_difference(_ reader: BufferReader) -> Difference? {
            var _1: [Api.Message]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _2: [Api.EncryptedMessage]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.EncryptedMessage.self)
            }
            var _3: [Api.Update]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Update.self)
            }
            var _4: [Api.Chat]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _5: [Api.User]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            var _6: Api.updates.State?
            if let signature = reader.readInt32() {
                _6 = Api.parse(reader, signature: signature) as? Api.updates.State
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.updates.Difference.difference(Cons_difference(newMessages: _1!, newEncryptedMessages: _2!, otherUpdates: _3!, chats: _4!, users: _5!, state: _6!))
            }
            else {
                return nil
            }
        }
        public static func parse_differenceEmpty(_ reader: BufferReader) -> Difference? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.updates.Difference.differenceEmpty(Cons_differenceEmpty(date: _1!, seq: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_differenceSlice(_ reader: BufferReader) -> Difference? {
            var _1: [Api.Message]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Message.self)
            }
            var _2: [Api.EncryptedMessage]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.EncryptedMessage.self)
            }
            var _3: [Api.Update]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Update.self)
            }
            var _4: [Api.Chat]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _5: [Api.User]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            var _6: Api.updates.State?
            if let signature = reader.readInt32() {
                _6 = Api.parse(reader, signature: signature) as? Api.updates.State
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.updates.Difference.differenceSlice(Cons_differenceSlice(newMessages: _1!, newEncryptedMessages: _2!, otherUpdates: _3!, chats: _4!, users: _5!, intermediateState: _6!))
            }
            else {
                return nil
            }
        }
        public static func parse_differenceTooLong(_ reader: BufferReader) -> Difference? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.updates.Difference.differenceTooLong(Cons_differenceTooLong(pts: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.updates {
    enum State: TypeConstructorDescription {
        public class Cons_state: TypeConstructorDescription {
            public var pts: Int32
            public var qts: Int32
            public var date: Int32
            public var seq: Int32
            public var unreadCount: Int32
            public init(pts: Int32, qts: Int32, date: Int32, seq: Int32, unreadCount: Int32) {
                self.pts = pts
                self.qts = qts
                self.date = date
                self.seq = seq
                self.unreadCount = unreadCount
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("state", [("pts", ConstructorParameterDescription(self.pts)), ("qts", ConstructorParameterDescription(self.qts)), ("date", ConstructorParameterDescription(self.date)), ("seq", ConstructorParameterDescription(self.seq)), ("unreadCount", ConstructorParameterDescription(self.unreadCount))])
            }
        }
        case state(Cons_state)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .state(let _data):
                if boxed {
                    buffer.appendInt32(-1519637954)
                }
                serializeInt32(_data.pts, buffer: buffer, boxed: false)
                serializeInt32(_data.qts, buffer: buffer, boxed: false)
                serializeInt32(_data.date, buffer: buffer, boxed: false)
                serializeInt32(_data.seq, buffer: buffer, boxed: false)
                serializeInt32(_data.unreadCount, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .state(let _data):
                return ("state", [("pts", ConstructorParameterDescription(_data.pts)), ("qts", ConstructorParameterDescription(_data.qts)), ("date", ConstructorParameterDescription(_data.date)), ("seq", ConstructorParameterDescription(_data.seq)), ("unreadCount", ConstructorParameterDescription(_data.unreadCount))])
            }
        }

        public static func parse_state(_ reader: BufferReader) -> State? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            _3 = reader.readInt32()
            var _4: Int32?
            _4 = reader.readInt32()
            var _5: Int32?
            _5 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.updates.State.state(Cons_state(pts: _1!, qts: _2!, date: _3!, seq: _4!, unreadCount: _5!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.upload {
    enum CdnFile: TypeConstructorDescription {
        public class Cons_cdnFile: TypeConstructorDescription {
            public var bytes: Buffer
            public init(bytes: Buffer) {
                self.bytes = bytes
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("cdnFile", [("bytes", ConstructorParameterDescription(self.bytes))])
            }
        }
        public class Cons_cdnFileReuploadNeeded: TypeConstructorDescription {
            public var requestToken: Buffer
            public init(requestToken: Buffer) {
                self.requestToken = requestToken
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("cdnFileReuploadNeeded", [("requestToken", ConstructorParameterDescription(self.requestToken))])
            }
        }
        case cdnFile(Cons_cdnFile)
        case cdnFileReuploadNeeded(Cons_cdnFileReuploadNeeded)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .cdnFile(let _data):
                if boxed {
                    buffer.appendInt32(-1449145777)
                }
                serializeBytes(_data.bytes, buffer: buffer, boxed: false)
                break
            case .cdnFileReuploadNeeded(let _data):
                if boxed {
                    buffer.appendInt32(-290921362)
                }
                serializeBytes(_data.requestToken, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .cdnFile(let _data):
                return ("cdnFile", [("bytes", ConstructorParameterDescription(_data.bytes))])
            case .cdnFileReuploadNeeded(let _data):
                return ("cdnFileReuploadNeeded", [("requestToken", ConstructorParameterDescription(_data.requestToken))])
            }
        }

        public static func parse_cdnFile(_ reader: BufferReader) -> CdnFile? {
            var _1: Buffer?
            _1 = parseBytes(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.upload.CdnFile.cdnFile(Cons_cdnFile(bytes: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_cdnFileReuploadNeeded(_ reader: BufferReader) -> CdnFile? {
            var _1: Buffer?
            _1 = parseBytes(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.upload.CdnFile.cdnFileReuploadNeeded(Cons_cdnFileReuploadNeeded(requestToken: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.upload {
    enum File: TypeConstructorDescription {
        public class Cons_file: TypeConstructorDescription {
            public var type: Api.storage.FileType
            public var mtime: Int32
            public var bytes: Buffer
            public init(type: Api.storage.FileType, mtime: Int32, bytes: Buffer) {
                self.type = type
                self.mtime = mtime
                self.bytes = bytes
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("file", [("type", ConstructorParameterDescription(self.type)), ("mtime", ConstructorParameterDescription(self.mtime)), ("bytes", ConstructorParameterDescription(self.bytes))])
            }
        }
        public class Cons_fileCdnRedirect: TypeConstructorDescription {
            public var dcId: Int32
            public var fileToken: Buffer
            public var encryptionKey: Buffer
            public var encryptionIv: Buffer
            public var fileHashes: [Api.FileHash]
            public init(dcId: Int32, fileToken: Buffer, encryptionKey: Buffer, encryptionIv: Buffer, fileHashes: [Api.FileHash]) {
                self.dcId = dcId
                self.fileToken = fileToken
                self.encryptionKey = encryptionKey
                self.encryptionIv = encryptionIv
                self.fileHashes = fileHashes
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("fileCdnRedirect", [("dcId", ConstructorParameterDescription(self.dcId)), ("fileToken", ConstructorParameterDescription(self.fileToken)), ("encryptionKey", ConstructorParameterDescription(self.encryptionKey)), ("encryptionIv", ConstructorParameterDescription(self.encryptionIv)), ("fileHashes", ConstructorParameterDescription(self.fileHashes))])
            }
        }
        case file(Cons_file)
        case fileCdnRedirect(Cons_fileCdnRedirect)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .file(let _data):
                if boxed {
                    buffer.appendInt32(157948117)
                }
                _data.type.serialize(buffer, true)
                serializeInt32(_data.mtime, buffer: buffer, boxed: false)
                serializeBytes(_data.bytes, buffer: buffer, boxed: false)
                break
            case .fileCdnRedirect(let _data):
                if boxed {
                    buffer.appendInt32(-242427324)
                }
                serializeInt32(_data.dcId, buffer: buffer, boxed: false)
                serializeBytes(_data.fileToken, buffer: buffer, boxed: false)
                serializeBytes(_data.encryptionKey, buffer: buffer, boxed: false)
                serializeBytes(_data.encryptionIv, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.fileHashes.count))
                for item in _data.fileHashes {
                    item.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .file(let _data):
                return ("file", [("type", ConstructorParameterDescription(_data.type)), ("mtime", ConstructorParameterDescription(_data.mtime)), ("bytes", ConstructorParameterDescription(_data.bytes))])
            case .fileCdnRedirect(let _data):
                return ("fileCdnRedirect", [("dcId", ConstructorParameterDescription(_data.dcId)), ("fileToken", ConstructorParameterDescription(_data.fileToken)), ("encryptionKey", ConstructorParameterDescription(_data.encryptionKey)), ("encryptionIv", ConstructorParameterDescription(_data.encryptionIv)), ("fileHashes", ConstructorParameterDescription(_data.fileHashes))])
            }
        }

        public static func parse_file(_ reader: BufferReader) -> File? {
            var _1: Api.storage.FileType?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.storage.FileType
            }
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Buffer?
            _3 = parseBytes(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.upload.File.file(Cons_file(type: _1!, mtime: _2!, bytes: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_fileCdnRedirect(_ reader: BufferReader) -> File? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Buffer?
            _2 = parseBytes(reader)
            var _3: Buffer?
            _3 = parseBytes(reader)
            var _4: Buffer?
            _4 = parseBytes(reader)
            var _5: [Api.FileHash]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.FileHash.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.upload.File.fileCdnRedirect(Cons_fileCdnRedirect(dcId: _1!, fileToken: _2!, encryptionKey: _3!, encryptionIv: _4!, fileHashes: _5!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.upload {
    enum WebFile: TypeConstructorDescription {
        public class Cons_webFile: TypeConstructorDescription {
            public var size: Int32
            public var mimeType: String
            public var fileType: Api.storage.FileType
            public var mtime: Int32
            public var bytes: Buffer
            public init(size: Int32, mimeType: String, fileType: Api.storage.FileType, mtime: Int32, bytes: Buffer) {
                self.size = size
                self.mimeType = mimeType
                self.fileType = fileType
                self.mtime = mtime
                self.bytes = bytes
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("webFile", [("size", ConstructorParameterDescription(self.size)), ("mimeType", ConstructorParameterDescription(self.mimeType)), ("fileType", ConstructorParameterDescription(self.fileType)), ("mtime", ConstructorParameterDescription(self.mtime)), ("bytes", ConstructorParameterDescription(self.bytes))])
            }
        }
        case webFile(Cons_webFile)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .webFile(let _data):
                if boxed {
                    buffer.appendInt32(568808380)
                }
                serializeInt32(_data.size, buffer: buffer, boxed: false)
                serializeString(_data.mimeType, buffer: buffer, boxed: false)
                _data.fileType.serialize(buffer, true)
                serializeInt32(_data.mtime, buffer: buffer, boxed: false)
                serializeBytes(_data.bytes, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .webFile(let _data):
                return ("webFile", [("size", ConstructorParameterDescription(_data.size)), ("mimeType", ConstructorParameterDescription(_data.mimeType)), ("fileType", ConstructorParameterDescription(_data.fileType)), ("mtime", ConstructorParameterDescription(_data.mtime)), ("bytes", ConstructorParameterDescription(_data.bytes))])
            }
        }

        public static func parse_webFile(_ reader: BufferReader) -> WebFile? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: Api.storage.FileType?
            if let signature = reader.readInt32() {
                _3 = Api.parse(reader, signature: signature) as? Api.storage.FileType
            }
            var _4: Int32?
            _4 = reader.readInt32()
            var _5: Buffer?
            _5 = parseBytes(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.upload.WebFile.webFile(Cons_webFile(size: _1!, mimeType: _2!, fileType: _3!, mtime: _4!, bytes: _5!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.users {
    enum SavedMusic: TypeConstructorDescription {
        public class Cons_savedMusic: TypeConstructorDescription {
            public var count: Int32
            public var documents: [Api.Document]
            public init(count: Int32, documents: [Api.Document]) {
                self.count = count
                self.documents = documents
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("savedMusic", [("count", ConstructorParameterDescription(self.count)), ("documents", ConstructorParameterDescription(self.documents))])
            }
        }
        public class Cons_savedMusicNotModified: TypeConstructorDescription {
            public var count: Int32
            public init(count: Int32) {
                self.count = count
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("savedMusicNotModified", [("count", ConstructorParameterDescription(self.count))])
            }
        }
        case savedMusic(Cons_savedMusic)
        case savedMusicNotModified(Cons_savedMusicNotModified)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .savedMusic(let _data):
                if boxed {
                    buffer.appendInt32(883094167)
                }
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.documents.count))
                for item in _data.documents {
                    item.serialize(buffer, true)
                }
                break
            case .savedMusicNotModified(let _data):
                if boxed {
                    buffer.appendInt32(-477656412)
                }
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .savedMusic(let _data):
                return ("savedMusic", [("count", ConstructorParameterDescription(_data.count)), ("documents", ConstructorParameterDescription(_data.documents))])
            case .savedMusicNotModified(let _data):
                return ("savedMusicNotModified", [("count", ConstructorParameterDescription(_data.count))])
            }
        }

        public static func parse_savedMusic(_ reader: BufferReader) -> SavedMusic? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.Document]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Document.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.users.SavedMusic.savedMusic(Cons_savedMusic(count: _1!, documents: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_savedMusicNotModified(_ reader: BufferReader) -> SavedMusic? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.users.SavedMusic.savedMusicNotModified(Cons_savedMusicNotModified(count: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.users {
    enum UserFull: TypeConstructorDescription {
        public class Cons_userFull: TypeConstructorDescription {
            public var fullUser: Api.UserFull
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(fullUser: Api.UserFull, chats: [Api.Chat], users: [Api.User]) {
                self.fullUser = fullUser
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("userFull", [("fullUser", ConstructorParameterDescription(self.fullUser)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case userFull(Cons_userFull)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .userFull(let _data):
                if boxed {
                    buffer.appendInt32(997004590)
                }
                _data.fullUser.serialize(buffer, true)
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
            case .userFull(let _data):
                return ("userFull", [("fullUser", ConstructorParameterDescription(_data.fullUser)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_userFull(_ reader: BufferReader) -> UserFull? {
            var _1: Api.UserFull?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.UserFull
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
                return Api.users.UserFull.userFull(Cons_userFull(fullUser: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.users {
    enum Users: TypeConstructorDescription {
        public class Cons_users: TypeConstructorDescription {
            public var users: [Api.User]
            public init(users: [Api.User]) {
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("users", [("users", ConstructorParameterDescription(self.users))])
            }
        }
        public class Cons_usersSlice: TypeConstructorDescription {
            public var count: Int32
            public var users: [Api.User]
            public init(count: Int32, users: [Api.User]) {
                self.count = count
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("usersSlice", [("count", ConstructorParameterDescription(self.count)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case users(Cons_users)
        case usersSlice(Cons_usersSlice)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .users(let _data):
                if boxed {
                    buffer.appendInt32(1658259128)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.users.count))
                for item in _data.users {
                    item.serialize(buffer, true)
                }
                break
            case .usersSlice(let _data):
                if boxed {
                    buffer.appendInt32(828000628)
                }
                serializeInt32(_data.count, buffer: buffer, boxed: false)
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
            case .users(let _data):
                return ("users", [("users", ConstructorParameterDescription(_data.users))])
            case .usersSlice(let _data):
                return ("usersSlice", [("count", ConstructorParameterDescription(_data.count)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_users(_ reader: BufferReader) -> Users? {
            var _1: [Api.User]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.users.Users.users(Cons_users(users: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_usersSlice(_ reader: BufferReader) -> Users? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.User]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.users.Users.usersSlice(Cons_usersSlice(count: _1!, users: _2!))
            }
            else {
                return nil
            }
        }
    }
}
