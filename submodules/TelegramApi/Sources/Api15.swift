public extension Api {
    indirect enum KeyboardButton: TypeConstructorDescription {
        public class Cons_inputKeyboardButtonRequestPeer: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public var buttonId: Int32
            public var peerType: Api.RequestPeerType
            public var maxQuantity: Int32
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String, buttonId: Int32, peerType: Api.RequestPeerType, maxQuantity: Int32) {
                self.flags = flags
                self.style = style
                self.text = text
                self.buttonId = buttonId
                self.peerType = peerType
                self.maxQuantity = maxQuantity
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputKeyboardButtonRequestPeer", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text)), ("buttonId", ConstructorParameterDescription(self.buttonId)), ("peerType", ConstructorParameterDescription(self.peerType)), ("maxQuantity", ConstructorParameterDescription(self.maxQuantity))])
            }
        }
        public class Cons_inputKeyboardButtonUrlAuth: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public var fwdText: String?
            public var url: String
            public var bot: Api.InputUser
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String, fwdText: String?, url: String, bot: Api.InputUser) {
                self.flags = flags
                self.style = style
                self.text = text
                self.fwdText = fwdText
                self.url = url
                self.bot = bot
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputKeyboardButtonUrlAuth", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text)), ("fwdText", ConstructorParameterDescription(self.fwdText)), ("url", ConstructorParameterDescription(self.url)), ("bot", ConstructorParameterDescription(self.bot))])
            }
        }
        public class Cons_inputKeyboardButtonUserProfile: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public var userId: Api.InputUser
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String, userId: Api.InputUser) {
                self.flags = flags
                self.style = style
                self.text = text
                self.userId = userId
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputKeyboardButtonUserProfile", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text)), ("userId", ConstructorParameterDescription(self.userId))])
            }
        }
        public class Cons_keyboardButton: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String) {
                self.flags = flags
                self.style = style
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButton", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_keyboardButtonBuy: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String) {
                self.flags = flags
                self.style = style
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonBuy", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_keyboardButtonCallback: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public var data: Buffer
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String, data: Buffer) {
                self.flags = flags
                self.style = style
                self.text = text
                self.data = data
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonCallback", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text)), ("data", ConstructorParameterDescription(self.data))])
            }
        }
        public class Cons_keyboardButtonCopy: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public var copyText: String
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String, copyText: String) {
                self.flags = flags
                self.style = style
                self.text = text
                self.copyText = copyText
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonCopy", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text)), ("copyText", ConstructorParameterDescription(self.copyText))])
            }
        }
        public class Cons_keyboardButtonGame: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String) {
                self.flags = flags
                self.style = style
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonGame", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_keyboardButtonRequestGeoLocation: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String) {
                self.flags = flags
                self.style = style
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonRequestGeoLocation", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_keyboardButtonRequestPeer: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public var buttonId: Int32
            public var peerType: Api.RequestPeerType
            public var maxQuantity: Int32
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String, buttonId: Int32, peerType: Api.RequestPeerType, maxQuantity: Int32) {
                self.flags = flags
                self.style = style
                self.text = text
                self.buttonId = buttonId
                self.peerType = peerType
                self.maxQuantity = maxQuantity
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonRequestPeer", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text)), ("buttonId", ConstructorParameterDescription(self.buttonId)), ("peerType", ConstructorParameterDescription(self.peerType)), ("maxQuantity", ConstructorParameterDescription(self.maxQuantity))])
            }
        }
        public class Cons_keyboardButtonRequestPhone: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String) {
                self.flags = flags
                self.style = style
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonRequestPhone", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_keyboardButtonRequestPoll: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var quiz: Api.Bool?
            public var text: String
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, quiz: Api.Bool?, text: String) {
                self.flags = flags
                self.style = style
                self.quiz = quiz
                self.text = text
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonRequestPoll", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("quiz", ConstructorParameterDescription(self.quiz)), ("text", ConstructorParameterDescription(self.text))])
            }
        }
        public class Cons_keyboardButtonSimpleWebView: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public var url: String
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String, url: String) {
                self.flags = flags
                self.style = style
                self.text = text
                self.url = url
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonSimpleWebView", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text)), ("url", ConstructorParameterDescription(self.url))])
            }
        }
        public class Cons_keyboardButtonSwitchInline: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public var query: String
            public var peerTypes: [Api.InlineQueryPeerType]?
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String, query: String, peerTypes: [Api.InlineQueryPeerType]?) {
                self.flags = flags
                self.style = style
                self.text = text
                self.query = query
                self.peerTypes = peerTypes
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonSwitchInline", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text)), ("query", ConstructorParameterDescription(self.query)), ("peerTypes", ConstructorParameterDescription(self.peerTypes))])
            }
        }
        public class Cons_keyboardButtonUrl: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public var url: String
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String, url: String) {
                self.flags = flags
                self.style = style
                self.text = text
                self.url = url
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonUrl", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text)), ("url", ConstructorParameterDescription(self.url))])
            }
        }
        public class Cons_keyboardButtonUrlAuth: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public var fwdText: String?
            public var url: String
            public var buttonId: Int32
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String, fwdText: String?, url: String, buttonId: Int32) {
                self.flags = flags
                self.style = style
                self.text = text
                self.fwdText = fwdText
                self.url = url
                self.buttonId = buttonId
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonUrlAuth", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text)), ("fwdText", ConstructorParameterDescription(self.fwdText)), ("url", ConstructorParameterDescription(self.url)), ("buttonId", ConstructorParameterDescription(self.buttonId))])
            }
        }
        public class Cons_keyboardButtonUserProfile: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public var userId: Int64
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String, userId: Int64) {
                self.flags = flags
                self.style = style
                self.text = text
                self.userId = userId
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonUserProfile", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text)), ("userId", ConstructorParameterDescription(self.userId))])
            }
        }
        public class Cons_keyboardButtonWebView: TypeConstructorDescription {
            public var flags: Int32
            public var style: Api.KeyboardButtonStyle?
            public var text: String
            public var url: String
            public init(flags: Int32, style: Api.KeyboardButtonStyle?, text: String, url: String) {
                self.flags = flags
                self.style = style
                self.text = text
                self.url = url
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonWebView", [("flags", ConstructorParameterDescription(self.flags)), ("style", ConstructorParameterDescription(self.style)), ("text", ConstructorParameterDescription(self.text)), ("url", ConstructorParameterDescription(self.url))])
            }
        }
        case inputKeyboardButtonRequestPeer(Cons_inputKeyboardButtonRequestPeer)
        case inputKeyboardButtonUrlAuth(Cons_inputKeyboardButtonUrlAuth)
        case inputKeyboardButtonUserProfile(Cons_inputKeyboardButtonUserProfile)
        case keyboardButton(Cons_keyboardButton)
        case keyboardButtonBuy(Cons_keyboardButtonBuy)
        case keyboardButtonCallback(Cons_keyboardButtonCallback)
        case keyboardButtonCopy(Cons_keyboardButtonCopy)
        case keyboardButtonGame(Cons_keyboardButtonGame)
        case keyboardButtonRequestGeoLocation(Cons_keyboardButtonRequestGeoLocation)
        case keyboardButtonRequestPeer(Cons_keyboardButtonRequestPeer)
        case keyboardButtonRequestPhone(Cons_keyboardButtonRequestPhone)
        case keyboardButtonRequestPoll(Cons_keyboardButtonRequestPoll)
        case keyboardButtonSimpleWebView(Cons_keyboardButtonSimpleWebView)
        case keyboardButtonSwitchInline(Cons_keyboardButtonSwitchInline)
        case keyboardButtonUrl(Cons_keyboardButtonUrl)
        case keyboardButtonUrlAuth(Cons_keyboardButtonUrlAuth)
        case keyboardButtonUserProfile(Cons_keyboardButtonUserProfile)
        case keyboardButtonWebView(Cons_keyboardButtonWebView)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .inputKeyboardButtonRequestPeer(let _data):
                if boxed {
                    buffer.appendInt32(45580630)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                serializeInt32(_data.buttonId, buffer: buffer, boxed: false)
                _data.peerType.serialize(buffer, true)
                serializeInt32(_data.maxQuantity, buffer: buffer, boxed: false)
                break
            case .inputKeyboardButtonUrlAuth(let _data):
                if boxed {
                    buffer.appendInt32(1744911986)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeString(_data.fwdText!, buffer: buffer, boxed: false)
                }
                serializeString(_data.url, buffer: buffer, boxed: false)
                _data.bot.serialize(buffer, true)
                break
            case .inputKeyboardButtonUserProfile(let _data):
                if boxed {
                    buffer.appendInt32(2103314375)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                _data.userId.serialize(buffer, true)
                break
            case .keyboardButton(let _data):
                if boxed {
                    buffer.appendInt32(2098662655)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                break
            case .keyboardButtonBuy(let _data):
                if boxed {
                    buffer.appendInt32(1067792645)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                break
            case .keyboardButtonCallback(let _data):
                if boxed {
                    buffer.appendInt32(-433338016)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                serializeBytes(_data.data, buffer: buffer, boxed: false)
                break
            case .keyboardButtonCopy(let _data):
                if boxed {
                    buffer.appendInt32(-1127960816)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                serializeString(_data.copyText, buffer: buffer, boxed: false)
                break
            case .keyboardButtonGame(let _data):
                if boxed {
                    buffer.appendInt32(-1983540999)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                break
            case .keyboardButtonRequestGeoLocation(let _data):
                if boxed {
                    buffer.appendInt32(-1438582451)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                break
            case .keyboardButtonRequestPeer(let _data):
                if boxed {
                    buffer.appendInt32(1527715317)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                serializeInt32(_data.buttonId, buffer: buffer, boxed: false)
                _data.peerType.serialize(buffer, true)
                serializeInt32(_data.maxQuantity, buffer: buffer, boxed: false)
                break
            case .keyboardButtonRequestPhone(let _data):
                if boxed {
                    buffer.appendInt32(1098841487)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                break
            case .keyboardButtonRequestPoll(let _data):
                if boxed {
                    buffer.appendInt32(2047989634)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    _data.quiz!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                break
            case .keyboardButtonSimpleWebView(let _data):
                if boxed {
                    buffer.appendInt32(-514047120)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                serializeString(_data.url, buffer: buffer, boxed: false)
                break
            case .keyboardButtonSwitchInline(let _data):
                if boxed {
                    buffer.appendInt32(-1726768644)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                serializeString(_data.query, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.peerTypes!.count))
                    for item in _data.peerTypes! {
                        item.serialize(buffer, true)
                    }
                }
                break
            case .keyboardButtonUrl(let _data):
                if boxed {
                    buffer.appendInt32(-670292500)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                serializeString(_data.url, buffer: buffer, boxed: false)
                break
            case .keyboardButtonUrlAuth(let _data):
                if boxed {
                    buffer.appendInt32(-183499015)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeString(_data.fwdText!, buffer: buffer, boxed: false)
                }
                serializeString(_data.url, buffer: buffer, boxed: false)
                serializeInt32(_data.buttonId, buffer: buffer, boxed: false)
                break
            case .keyboardButtonUserProfile(let _data):
                if boxed {
                    buffer.appendInt32(-1057137399)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                serializeInt64(_data.userId, buffer: buffer, boxed: false)
                break
            case .keyboardButtonWebView(let _data):
                if boxed {
                    buffer.appendInt32(-398020192)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    _data.style!.serialize(buffer, true)
                }
                serializeString(_data.text, buffer: buffer, boxed: false)
                serializeString(_data.url, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .inputKeyboardButtonRequestPeer(let _data):
                return ("inputKeyboardButtonRequestPeer", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text)), ("buttonId", ConstructorParameterDescription(_data.buttonId)), ("peerType", ConstructorParameterDescription(_data.peerType)), ("maxQuantity", ConstructorParameterDescription(_data.maxQuantity))])
            case .inputKeyboardButtonUrlAuth(let _data):
                return ("inputKeyboardButtonUrlAuth", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text)), ("fwdText", ConstructorParameterDescription(_data.fwdText)), ("url", ConstructorParameterDescription(_data.url)), ("bot", ConstructorParameterDescription(_data.bot))])
            case .inputKeyboardButtonUserProfile(let _data):
                return ("inputKeyboardButtonUserProfile", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text)), ("userId", ConstructorParameterDescription(_data.userId))])
            case .keyboardButton(let _data):
                return ("keyboardButton", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text))])
            case .keyboardButtonBuy(let _data):
                return ("keyboardButtonBuy", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text))])
            case .keyboardButtonCallback(let _data):
                return ("keyboardButtonCallback", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text)), ("data", ConstructorParameterDescription(_data.data))])
            case .keyboardButtonCopy(let _data):
                return ("keyboardButtonCopy", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text)), ("copyText", ConstructorParameterDescription(_data.copyText))])
            case .keyboardButtonGame(let _data):
                return ("keyboardButtonGame", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text))])
            case .keyboardButtonRequestGeoLocation(let _data):
                return ("keyboardButtonRequestGeoLocation", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text))])
            case .keyboardButtonRequestPeer(let _data):
                return ("keyboardButtonRequestPeer", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text)), ("buttonId", ConstructorParameterDescription(_data.buttonId)), ("peerType", ConstructorParameterDescription(_data.peerType)), ("maxQuantity", ConstructorParameterDescription(_data.maxQuantity))])
            case .keyboardButtonRequestPhone(let _data):
                return ("keyboardButtonRequestPhone", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text))])
            case .keyboardButtonRequestPoll(let _data):
                return ("keyboardButtonRequestPoll", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("quiz", ConstructorParameterDescription(_data.quiz)), ("text", ConstructorParameterDescription(_data.text))])
            case .keyboardButtonSimpleWebView(let _data):
                return ("keyboardButtonSimpleWebView", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text)), ("url", ConstructorParameterDescription(_data.url))])
            case .keyboardButtonSwitchInline(let _data):
                return ("keyboardButtonSwitchInline", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text)), ("query", ConstructorParameterDescription(_data.query)), ("peerTypes", ConstructorParameterDescription(_data.peerTypes))])
            case .keyboardButtonUrl(let _data):
                return ("keyboardButtonUrl", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text)), ("url", ConstructorParameterDescription(_data.url))])
            case .keyboardButtonUrlAuth(let _data):
                return ("keyboardButtonUrlAuth", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text)), ("fwdText", ConstructorParameterDescription(_data.fwdText)), ("url", ConstructorParameterDescription(_data.url)), ("buttonId", ConstructorParameterDescription(_data.buttonId))])
            case .keyboardButtonUserProfile(let _data):
                return ("keyboardButtonUserProfile", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text)), ("userId", ConstructorParameterDescription(_data.userId))])
            case .keyboardButtonWebView(let _data):
                return ("keyboardButtonWebView", [("flags", ConstructorParameterDescription(_data.flags)), ("style", ConstructorParameterDescription(_data.style)), ("text", ConstructorParameterDescription(_data.text)), ("url", ConstructorParameterDescription(_data.url))])
            }
        }

        public static func parse_inputKeyboardButtonRequestPeer(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: Int32?
            _4 = reader.readInt32()
            var _5: Api.RequestPeerType?
            if let signature = reader.readInt32() {
                _5 = Api.parse(reader, signature: signature) as? Api.RequestPeerType
            }
            var _6: Int32?
            _6 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.KeyboardButton.inputKeyboardButtonRequestPeer(Cons_inputKeyboardButtonRequestPeer(flags: _1!, style: _2, text: _3!, buttonId: _4!, peerType: _5!, maxQuantity: _6!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputKeyboardButtonUrlAuth(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _4 = parseString(reader)
            }
            var _5: String?
            _5 = parseString(reader)
            var _6: Api.InputUser?
            if let signature = reader.readInt32() {
                _6 = Api.parse(reader, signature: signature) as? Api.InputUser
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.KeyboardButton.inputKeyboardButtonUrlAuth(Cons_inputKeyboardButtonUrlAuth(flags: _1!, style: _2, text: _3!, fwdText: _4, url: _5!, bot: _6!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputKeyboardButtonUserProfile(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: Api.InputUser?
            if let signature = reader.readInt32() {
                _4 = Api.parse(reader, signature: signature) as? Api.InputUser
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.KeyboardButton.inputKeyboardButtonUserProfile(Cons_inputKeyboardButtonUserProfile(flags: _1!, style: _2, text: _3!, userId: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButton(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.KeyboardButton.keyboardButton(Cons_keyboardButton(flags: _1!, style: _2, text: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonBuy(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.KeyboardButton.keyboardButtonBuy(Cons_keyboardButtonBuy(flags: _1!, style: _2, text: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonCallback(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: Buffer?
            _4 = parseBytes(reader)
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.KeyboardButton.keyboardButtonCallback(Cons_keyboardButtonCallback(flags: _1!, style: _2, text: _3!, data: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonCopy(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            _4 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.KeyboardButton.keyboardButtonCopy(Cons_keyboardButtonCopy(flags: _1!, style: _2, text: _3!, copyText: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonGame(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.KeyboardButton.keyboardButtonGame(Cons_keyboardButtonGame(flags: _1!, style: _2, text: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonRequestGeoLocation(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.KeyboardButton.keyboardButtonRequestGeoLocation(Cons_keyboardButtonRequestGeoLocation(flags: _1!, style: _2, text: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonRequestPeer(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: Int32?
            _4 = reader.readInt32()
            var _5: Api.RequestPeerType?
            if let signature = reader.readInt32() {
                _5 = Api.parse(reader, signature: signature) as? Api.RequestPeerType
            }
            var _6: Int32?
            _6 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.KeyboardButton.keyboardButtonRequestPeer(Cons_keyboardButtonRequestPeer(flags: _1!, style: _2, text: _3!, buttonId: _4!, peerType: _5!, maxQuantity: _6!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonRequestPhone(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.KeyboardButton.keyboardButtonRequestPhone(Cons_keyboardButtonRequestPhone(flags: _1!, style: _2, text: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonRequestPoll(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: Api.Bool?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                if let signature = reader.readInt32() {
                    _3 = Api.parse(reader, signature: signature) as? Api.Bool
                }
            }
            var _4: String?
            _4 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.KeyboardButton.keyboardButtonRequestPoll(Cons_keyboardButtonRequestPoll(flags: _1!, style: _2, quiz: _3, text: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonSimpleWebView(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            _4 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.KeyboardButton.keyboardButtonSimpleWebView(Cons_keyboardButtonSimpleWebView(flags: _1!, style: _2, text: _3!, url: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonSwitchInline(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            _4 = parseString(reader)
            var _5: [Api.InlineQueryPeerType]?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let _ = reader.readInt32() {
                    _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.InlineQueryPeerType.self)
                }
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.KeyboardButton.keyboardButtonSwitchInline(Cons_keyboardButtonSwitchInline(flags: _1!, style: _2, text: _3!, query: _4!, peerTypes: _5))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonUrl(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            _4 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.KeyboardButton.keyboardButtonUrl(Cons_keyboardButtonUrl(flags: _1!, style: _2, text: _3!, url: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonUrlAuth(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _4 = parseString(reader)
            }
            var _5: String?
            _5 = parseString(reader)
            var _6: Int32?
            _6 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.KeyboardButton.keyboardButtonUrlAuth(Cons_keyboardButtonUrlAuth(flags: _1!, style: _2, text: _3!, fwdText: _4, url: _5!, buttonId: _6!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonUserProfile(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: Int64?
            _4 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.KeyboardButton.keyboardButtonUserProfile(Cons_keyboardButtonUserProfile(flags: _1!, style: _2, text: _3!, userId: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonWebView(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.KeyboardButtonStyle?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.KeyboardButtonStyle
                }
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            _4 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.KeyboardButton.keyboardButtonWebView(Cons_keyboardButtonWebView(flags: _1!, style: _2, text: _3!, url: _4!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum KeyboardButtonRow: TypeConstructorDescription {
        public class Cons_keyboardButtonRow: TypeConstructorDescription {
            public var buttons: [Api.KeyboardButton]
            public init(buttons: [Api.KeyboardButton]) {
                self.buttons = buttons
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonRow", [("buttons", ConstructorParameterDescription(self.buttons))])
            }
        }
        case keyboardButtonRow(Cons_keyboardButtonRow)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .keyboardButtonRow(let _data):
                if boxed {
                    buffer.appendInt32(2002815875)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.buttons.count))
                for item in _data.buttons {
                    item.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .keyboardButtonRow(let _data):
                return ("keyboardButtonRow", [("buttons", ConstructorParameterDescription(_data.buttons))])
            }
        }

        public static func parse_keyboardButtonRow(_ reader: BufferReader) -> KeyboardButtonRow? {
            var _1: [Api.KeyboardButton]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.KeyboardButton.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.KeyboardButtonRow.keyboardButtonRow(Cons_keyboardButtonRow(buttons: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum KeyboardButtonStyle: TypeConstructorDescription {
        public class Cons_keyboardButtonStyle: TypeConstructorDescription {
            public var flags: Int32
            public var icon: Int64?
            public init(flags: Int32, icon: Int64?) {
                self.flags = flags
                self.icon = icon
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("keyboardButtonStyle", [("flags", ConstructorParameterDescription(self.flags)), ("icon", ConstructorParameterDescription(self.icon))])
            }
        }
        case keyboardButtonStyle(Cons_keyboardButtonStyle)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .keyboardButtonStyle(let _data):
                if boxed {
                    buffer.appendInt32(1339896880)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 3) != 0 {
                    serializeInt64(_data.icon!, buffer: buffer, boxed: false)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .keyboardButtonStyle(let _data):
                return ("keyboardButtonStyle", [("flags", ConstructorParameterDescription(_data.flags)), ("icon", ConstructorParameterDescription(_data.icon))])
            }
        }

        public static func parse_keyboardButtonStyle(_ reader: BufferReader) -> KeyboardButtonStyle? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int64?
            if Int(_1 ?? 0) & Int(1 << 3) != 0 {
                _2 = reader.readInt64()
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 3) == 0) || _2 != nil
            if _c1 && _c2 {
                return Api.KeyboardButtonStyle.keyboardButtonStyle(Cons_keyboardButtonStyle(flags: _1!, icon: _2))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum LabeledPrice: TypeConstructorDescription {
        public class Cons_labeledPrice: TypeConstructorDescription {
            public var label: String
            public var amount: Int64
            public init(label: String, amount: Int64) {
                self.label = label
                self.amount = amount
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("labeledPrice", [("label", ConstructorParameterDescription(self.label)), ("amount", ConstructorParameterDescription(self.amount))])
            }
        }
        case labeledPrice(Cons_labeledPrice)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .labeledPrice(let _data):
                if boxed {
                    buffer.appendInt32(-886477832)
                }
                serializeString(_data.label, buffer: buffer, boxed: false)
                serializeInt64(_data.amount, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .labeledPrice(let _data):
                return ("labeledPrice", [("label", ConstructorParameterDescription(_data.label)), ("amount", ConstructorParameterDescription(_data.amount))])
            }
        }

        public static func parse_labeledPrice(_ reader: BufferReader) -> LabeledPrice? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int64?
            _2 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.LabeledPrice.labeledPrice(Cons_labeledPrice(label: _1!, amount: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum LangPackDifference: TypeConstructorDescription {
        public class Cons_langPackDifference: TypeConstructorDescription {
            public var langCode: String
            public var fromVersion: Int32
            public var version: Int32
            public var strings: [Api.LangPackString]
            public init(langCode: String, fromVersion: Int32, version: Int32, strings: [Api.LangPackString]) {
                self.langCode = langCode
                self.fromVersion = fromVersion
                self.version = version
                self.strings = strings
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("langPackDifference", [("langCode", ConstructorParameterDescription(self.langCode)), ("fromVersion", ConstructorParameterDescription(self.fromVersion)), ("version", ConstructorParameterDescription(self.version)), ("strings", ConstructorParameterDescription(self.strings))])
            }
        }
        case langPackDifference(Cons_langPackDifference)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .langPackDifference(let _data):
                if boxed {
                    buffer.appendInt32(-209337866)
                }
                serializeString(_data.langCode, buffer: buffer, boxed: false)
                serializeInt32(_data.fromVersion, buffer: buffer, boxed: false)
                serializeInt32(_data.version, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.strings.count))
                for item in _data.strings {
                    item.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .langPackDifference(let _data):
                return ("langPackDifference", [("langCode", ConstructorParameterDescription(_data.langCode)), ("fromVersion", ConstructorParameterDescription(_data.fromVersion)), ("version", ConstructorParameterDescription(_data.version)), ("strings", ConstructorParameterDescription(_data.strings))])
            }
        }

        public static func parse_langPackDifference(_ reader: BufferReader) -> LangPackDifference? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            _3 = reader.readInt32()
            var _4: [Api.LangPackString]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.LangPackString.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.LangPackDifference.langPackDifference(Cons_langPackDifference(langCode: _1!, fromVersion: _2!, version: _3!, strings: _4!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum LangPackLanguage: TypeConstructorDescription {
        public class Cons_langPackLanguage: TypeConstructorDescription {
            public var flags: Int32
            public var name: String
            public var nativeName: String
            public var langCode: String
            public var baseLangCode: String?
            public var pluralCode: String
            public var stringsCount: Int32
            public var translatedCount: Int32
            public var translationsUrl: String
            public init(flags: Int32, name: String, nativeName: String, langCode: String, baseLangCode: String?, pluralCode: String, stringsCount: Int32, translatedCount: Int32, translationsUrl: String) {
                self.flags = flags
                self.name = name
                self.nativeName = nativeName
                self.langCode = langCode
                self.baseLangCode = baseLangCode
                self.pluralCode = pluralCode
                self.stringsCount = stringsCount
                self.translatedCount = translatedCount
                self.translationsUrl = translationsUrl
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("langPackLanguage", [("flags", ConstructorParameterDescription(self.flags)), ("name", ConstructorParameterDescription(self.name)), ("nativeName", ConstructorParameterDescription(self.nativeName)), ("langCode", ConstructorParameterDescription(self.langCode)), ("baseLangCode", ConstructorParameterDescription(self.baseLangCode)), ("pluralCode", ConstructorParameterDescription(self.pluralCode)), ("stringsCount", ConstructorParameterDescription(self.stringsCount)), ("translatedCount", ConstructorParameterDescription(self.translatedCount)), ("translationsUrl", ConstructorParameterDescription(self.translationsUrl))])
            }
        }
        case langPackLanguage(Cons_langPackLanguage)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .langPackLanguage(let _data):
                if boxed {
                    buffer.appendInt32(-288727837)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeString(_data.name, buffer: buffer, boxed: false)
                serializeString(_data.nativeName, buffer: buffer, boxed: false)
                serializeString(_data.langCode, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeString(_data.baseLangCode!, buffer: buffer, boxed: false)
                }
                serializeString(_data.pluralCode, buffer: buffer, boxed: false)
                serializeInt32(_data.stringsCount, buffer: buffer, boxed: false)
                serializeInt32(_data.translatedCount, buffer: buffer, boxed: false)
                serializeString(_data.translationsUrl, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .langPackLanguage(let _data):
                return ("langPackLanguage", [("flags", ConstructorParameterDescription(_data.flags)), ("name", ConstructorParameterDescription(_data.name)), ("nativeName", ConstructorParameterDescription(_data.nativeName)), ("langCode", ConstructorParameterDescription(_data.langCode)), ("baseLangCode", ConstructorParameterDescription(_data.baseLangCode)), ("pluralCode", ConstructorParameterDescription(_data.pluralCode)), ("stringsCount", ConstructorParameterDescription(_data.stringsCount)), ("translatedCount", ConstructorParameterDescription(_data.translatedCount)), ("translationsUrl", ConstructorParameterDescription(_data.translationsUrl))])
            }
        }

        public static func parse_langPackLanguage(_ reader: BufferReader) -> LangPackLanguage? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            _4 = parseString(reader)
            var _5: String?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _5 = parseString(reader)
            }
            var _6: String?
            _6 = parseString(reader)
            var _7: Int32?
            _7 = reader.readInt32()
            var _8: Int32?
            _8 = reader.readInt32()
            var _9: String?
            _9 = parseString(reader)
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
                return Api.LangPackLanguage.langPackLanguage(Cons_langPackLanguage(flags: _1!, name: _2!, nativeName: _3!, langCode: _4!, baseLangCode: _5, pluralCode: _6!, stringsCount: _7!, translatedCount: _8!, translationsUrl: _9!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum LangPackString: TypeConstructorDescription {
        public class Cons_langPackString: TypeConstructorDescription {
            public var key: String
            public var value: String
            public init(key: String, value: String) {
                self.key = key
                self.value = value
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("langPackString", [("key", ConstructorParameterDescription(self.key)), ("value", ConstructorParameterDescription(self.value))])
            }
        }
        public class Cons_langPackStringDeleted: TypeConstructorDescription {
            public var key: String
            public init(key: String) {
                self.key = key
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("langPackStringDeleted", [("key", ConstructorParameterDescription(self.key))])
            }
        }
        public class Cons_langPackStringPluralized: TypeConstructorDescription {
            public var flags: Int32
            public var key: String
            public var zeroValue: String?
            public var oneValue: String?
            public var twoValue: String?
            public var fewValue: String?
            public var manyValue: String?
            public var otherValue: String
            public init(flags: Int32, key: String, zeroValue: String?, oneValue: String?, twoValue: String?, fewValue: String?, manyValue: String?, otherValue: String) {
                self.flags = flags
                self.key = key
                self.zeroValue = zeroValue
                self.oneValue = oneValue
                self.twoValue = twoValue
                self.fewValue = fewValue
                self.manyValue = manyValue
                self.otherValue = otherValue
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("langPackStringPluralized", [("flags", ConstructorParameterDescription(self.flags)), ("key", ConstructorParameterDescription(self.key)), ("zeroValue", ConstructorParameterDescription(self.zeroValue)), ("oneValue", ConstructorParameterDescription(self.oneValue)), ("twoValue", ConstructorParameterDescription(self.twoValue)), ("fewValue", ConstructorParameterDescription(self.fewValue)), ("manyValue", ConstructorParameterDescription(self.manyValue)), ("otherValue", ConstructorParameterDescription(self.otherValue))])
            }
        }
        case langPackString(Cons_langPackString)
        case langPackStringDeleted(Cons_langPackStringDeleted)
        case langPackStringPluralized(Cons_langPackStringPluralized)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .langPackString(let _data):
                if boxed {
                    buffer.appendInt32(-892239370)
                }
                serializeString(_data.key, buffer: buffer, boxed: false)
                serializeString(_data.value, buffer: buffer, boxed: false)
                break
            case .langPackStringDeleted(let _data):
                if boxed {
                    buffer.appendInt32(695856818)
                }
                serializeString(_data.key, buffer: buffer, boxed: false)
                break
            case .langPackStringPluralized(let _data):
                if boxed {
                    buffer.appendInt32(1816636575)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeString(_data.key, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeString(_data.zeroValue!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeString(_data.oneValue!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeString(_data.twoValue!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 3) != 0 {
                    serializeString(_data.fewValue!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 4) != 0 {
                    serializeString(_data.manyValue!, buffer: buffer, boxed: false)
                }
                serializeString(_data.otherValue, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .langPackString(let _data):
                return ("langPackString", [("key", ConstructorParameterDescription(_data.key)), ("value", ConstructorParameterDescription(_data.value))])
            case .langPackStringDeleted(let _data):
                return ("langPackStringDeleted", [("key", ConstructorParameterDescription(_data.key))])
            case .langPackStringPluralized(let _data):
                return ("langPackStringPluralized", [("flags", ConstructorParameterDescription(_data.flags)), ("key", ConstructorParameterDescription(_data.key)), ("zeroValue", ConstructorParameterDescription(_data.zeroValue)), ("oneValue", ConstructorParameterDescription(_data.oneValue)), ("twoValue", ConstructorParameterDescription(_data.twoValue)), ("fewValue", ConstructorParameterDescription(_data.fewValue)), ("manyValue", ConstructorParameterDescription(_data.manyValue)), ("otherValue", ConstructorParameterDescription(_data.otherValue))])
            }
        }

        public static func parse_langPackString(_ reader: BufferReader) -> LangPackString? {
            var _1: String?
            _1 = parseString(reader)
            var _2: String?
            _2 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.LangPackString.langPackString(Cons_langPackString(key: _1!, value: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_langPackStringDeleted(_ reader: BufferReader) -> LangPackString? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.LangPackString.langPackStringDeleted(Cons_langPackStringDeleted(key: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_langPackStringPluralized(_ reader: BufferReader) -> LangPackString? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: String?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _3 = parseString(reader)
            }
            var _4: String?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _4 = parseString(reader)
            }
            var _5: String?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _5 = parseString(reader)
            }
            var _6: String?
            if Int(_1 ?? 0) & Int(1 << 3) != 0 {
                _6 = parseString(reader)
            }
            var _7: String?
            if Int(_1 ?? 0) & Int(1 << 4) != 0 {
                _7 = parseString(reader)
            }
            var _8: String?
            _8 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _5 != nil
            let _c6 = (Int(_1 ?? 0) & Int(1 << 3) == 0) || _6 != nil
            let _c7 = (Int(_1 ?? 0) & Int(1 << 4) == 0) || _7 != nil
            let _c8 = _8 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 {
                return Api.LangPackString.langPackStringPluralized(Cons_langPackStringPluralized(flags: _1!, key: _2!, zeroValue: _3, oneValue: _4, twoValue: _5, fewValue: _6, manyValue: _7, otherValue: _8!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum MaskCoords: TypeConstructorDescription {
        public class Cons_maskCoords: TypeConstructorDescription {
            public var n: Int32
            public var x: Double
            public var y: Double
            public var zoom: Double
            public init(n: Int32, x: Double, y: Double, zoom: Double) {
                self.n = n
                self.x = x
                self.y = y
                self.zoom = zoom
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("maskCoords", [("n", ConstructorParameterDescription(self.n)), ("x", ConstructorParameterDescription(self.x)), ("y", ConstructorParameterDescription(self.y)), ("zoom", ConstructorParameterDescription(self.zoom))])
            }
        }
        case maskCoords(Cons_maskCoords)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .maskCoords(let _data):
                if boxed {
                    buffer.appendInt32(-1361650766)
                }
                serializeInt32(_data.n, buffer: buffer, boxed: false)
                serializeDouble(_data.x, buffer: buffer, boxed: false)
                serializeDouble(_data.y, buffer: buffer, boxed: false)
                serializeDouble(_data.zoom, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .maskCoords(let _data):
                return ("maskCoords", [("n", ConstructorParameterDescription(_data.n)), ("x", ConstructorParameterDescription(_data.x)), ("y", ConstructorParameterDescription(_data.y)), ("zoom", ConstructorParameterDescription(_data.zoom))])
            }
        }

        public static func parse_maskCoords(_ reader: BufferReader) -> MaskCoords? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Double?
            _2 = reader.readDouble()
            var _3: Double?
            _3 = reader.readDouble()
            var _4: Double?
            _4 = reader.readDouble()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.MaskCoords.maskCoords(Cons_maskCoords(n: _1!, x: _2!, y: _3!, zoom: _4!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    indirect enum MediaArea: TypeConstructorDescription {
        public class Cons_inputMediaAreaChannelPost: TypeConstructorDescription {
            public var coordinates: Api.MediaAreaCoordinates
            public var channel: Api.InputChannel
            public var msgId: Int32
            public init(coordinates: Api.MediaAreaCoordinates, channel: Api.InputChannel, msgId: Int32) {
                self.coordinates = coordinates
                self.channel = channel
                self.msgId = msgId
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputMediaAreaChannelPost", [("coordinates", ConstructorParameterDescription(self.coordinates)), ("channel", ConstructorParameterDescription(self.channel)), ("msgId", ConstructorParameterDescription(self.msgId))])
            }
        }
        public class Cons_inputMediaAreaVenue: TypeConstructorDescription {
            public var coordinates: Api.MediaAreaCoordinates
            public var queryId: Int64
            public var resultId: String
            public init(coordinates: Api.MediaAreaCoordinates, queryId: Int64, resultId: String) {
                self.coordinates = coordinates
                self.queryId = queryId
                self.resultId = resultId
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputMediaAreaVenue", [("coordinates", ConstructorParameterDescription(self.coordinates)), ("queryId", ConstructorParameterDescription(self.queryId)), ("resultId", ConstructorParameterDescription(self.resultId))])
            }
        }
        public class Cons_mediaAreaChannelPost: TypeConstructorDescription {
            public var coordinates: Api.MediaAreaCoordinates
            public var channelId: Int64
            public var msgId: Int32
            public init(coordinates: Api.MediaAreaCoordinates, channelId: Int64, msgId: Int32) {
                self.coordinates = coordinates
                self.channelId = channelId
                self.msgId = msgId
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("mediaAreaChannelPost", [("coordinates", ConstructorParameterDescription(self.coordinates)), ("channelId", ConstructorParameterDescription(self.channelId)), ("msgId", ConstructorParameterDescription(self.msgId))])
            }
        }
        public class Cons_mediaAreaGeoPoint: TypeConstructorDescription {
            public var flags: Int32
            public var coordinates: Api.MediaAreaCoordinates
            public var geo: Api.GeoPoint
            public var address: Api.GeoPointAddress?
            public init(flags: Int32, coordinates: Api.MediaAreaCoordinates, geo: Api.GeoPoint, address: Api.GeoPointAddress?) {
                self.flags = flags
                self.coordinates = coordinates
                self.geo = geo
                self.address = address
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("mediaAreaGeoPoint", [("flags", ConstructorParameterDescription(self.flags)), ("coordinates", ConstructorParameterDescription(self.coordinates)), ("geo", ConstructorParameterDescription(self.geo)), ("address", ConstructorParameterDescription(self.address))])
            }
        }
        public class Cons_mediaAreaStarGift: TypeConstructorDescription {
            public var coordinates: Api.MediaAreaCoordinates
            public var slug: String
            public init(coordinates: Api.MediaAreaCoordinates, slug: String) {
                self.coordinates = coordinates
                self.slug = slug
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("mediaAreaStarGift", [("coordinates", ConstructorParameterDescription(self.coordinates)), ("slug", ConstructorParameterDescription(self.slug))])
            }
        }
        public class Cons_mediaAreaSuggestedReaction: TypeConstructorDescription {
            public var flags: Int32
            public var coordinates: Api.MediaAreaCoordinates
            public var reaction: Api.Reaction
            public init(flags: Int32, coordinates: Api.MediaAreaCoordinates, reaction: Api.Reaction) {
                self.flags = flags
                self.coordinates = coordinates
                self.reaction = reaction
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("mediaAreaSuggestedReaction", [("flags", ConstructorParameterDescription(self.flags)), ("coordinates", ConstructorParameterDescription(self.coordinates)), ("reaction", ConstructorParameterDescription(self.reaction))])
            }
        }
        public class Cons_mediaAreaUrl: TypeConstructorDescription {
            public var coordinates: Api.MediaAreaCoordinates
            public var url: String
            public init(coordinates: Api.MediaAreaCoordinates, url: String) {
                self.coordinates = coordinates
                self.url = url
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("mediaAreaUrl", [("coordinates", ConstructorParameterDescription(self.coordinates)), ("url", ConstructorParameterDescription(self.url))])
            }
        }
        public class Cons_mediaAreaVenue: TypeConstructorDescription {
            public var coordinates: Api.MediaAreaCoordinates
            public var geo: Api.GeoPoint
            public var title: String
            public var address: String
            public var provider: String
            public var venueId: String
            public var venueType: String
            public init(coordinates: Api.MediaAreaCoordinates, geo: Api.GeoPoint, title: String, address: String, provider: String, venueId: String, venueType: String) {
                self.coordinates = coordinates
                self.geo = geo
                self.title = title
                self.address = address
                self.provider = provider
                self.venueId = venueId
                self.venueType = venueType
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("mediaAreaVenue", [("coordinates", ConstructorParameterDescription(self.coordinates)), ("geo", ConstructorParameterDescription(self.geo)), ("title", ConstructorParameterDescription(self.title)), ("address", ConstructorParameterDescription(self.address)), ("provider", ConstructorParameterDescription(self.provider)), ("venueId", ConstructorParameterDescription(self.venueId)), ("venueType", ConstructorParameterDescription(self.venueType))])
            }
        }
        public class Cons_mediaAreaWeather: TypeConstructorDescription {
            public var coordinates: Api.MediaAreaCoordinates
            public var emoji: String
            public var temperatureC: Double
            public var color: Int32
            public init(coordinates: Api.MediaAreaCoordinates, emoji: String, temperatureC: Double, color: Int32) {
                self.coordinates = coordinates
                self.emoji = emoji
                self.temperatureC = temperatureC
                self.color = color
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("mediaAreaWeather", [("coordinates", ConstructorParameterDescription(self.coordinates)), ("emoji", ConstructorParameterDescription(self.emoji)), ("temperatureC", ConstructorParameterDescription(self.temperatureC)), ("color", ConstructorParameterDescription(self.color))])
            }
        }
        case inputMediaAreaChannelPost(Cons_inputMediaAreaChannelPost)
        case inputMediaAreaVenue(Cons_inputMediaAreaVenue)
        case mediaAreaChannelPost(Cons_mediaAreaChannelPost)
        case mediaAreaGeoPoint(Cons_mediaAreaGeoPoint)
        case mediaAreaStarGift(Cons_mediaAreaStarGift)
        case mediaAreaSuggestedReaction(Cons_mediaAreaSuggestedReaction)
        case mediaAreaUrl(Cons_mediaAreaUrl)
        case mediaAreaVenue(Cons_mediaAreaVenue)
        case mediaAreaWeather(Cons_mediaAreaWeather)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .inputMediaAreaChannelPost(let _data):
                if boxed {
                    buffer.appendInt32(577893055)
                }
                _data.coordinates.serialize(buffer, true)
                _data.channel.serialize(buffer, true)
                serializeInt32(_data.msgId, buffer: buffer, boxed: false)
                break
            case .inputMediaAreaVenue(let _data):
                if boxed {
                    buffer.appendInt32(-1300094593)
                }
                _data.coordinates.serialize(buffer, true)
                serializeInt64(_data.queryId, buffer: buffer, boxed: false)
                serializeString(_data.resultId, buffer: buffer, boxed: false)
                break
            case .mediaAreaChannelPost(let _data):
                if boxed {
                    buffer.appendInt32(1996756655)
                }
                _data.coordinates.serialize(buffer, true)
                serializeInt64(_data.channelId, buffer: buffer, boxed: false)
                serializeInt32(_data.msgId, buffer: buffer, boxed: false)
                break
            case .mediaAreaGeoPoint(let _data):
                if boxed {
                    buffer.appendInt32(-891992787)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                _data.coordinates.serialize(buffer, true)
                _data.geo.serialize(buffer, true)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    _data.address!.serialize(buffer, true)
                }
                break
            case .mediaAreaStarGift(let _data):
                if boxed {
                    buffer.appendInt32(1468491885)
                }
                _data.coordinates.serialize(buffer, true)
                serializeString(_data.slug, buffer: buffer, boxed: false)
                break
            case .mediaAreaSuggestedReaction(let _data):
                if boxed {
                    buffer.appendInt32(340088945)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                _data.coordinates.serialize(buffer, true)
                _data.reaction.serialize(buffer, true)
                break
            case .mediaAreaUrl(let _data):
                if boxed {
                    buffer.appendInt32(926421125)
                }
                _data.coordinates.serialize(buffer, true)
                serializeString(_data.url, buffer: buffer, boxed: false)
                break
            case .mediaAreaVenue(let _data):
                if boxed {
                    buffer.appendInt32(-1098720356)
                }
                _data.coordinates.serialize(buffer, true)
                _data.geo.serialize(buffer, true)
                serializeString(_data.title, buffer: buffer, boxed: false)
                serializeString(_data.address, buffer: buffer, boxed: false)
                serializeString(_data.provider, buffer: buffer, boxed: false)
                serializeString(_data.venueId, buffer: buffer, boxed: false)
                serializeString(_data.venueType, buffer: buffer, boxed: false)
                break
            case .mediaAreaWeather(let _data):
                if boxed {
                    buffer.appendInt32(1235637404)
                }
                _data.coordinates.serialize(buffer, true)
                serializeString(_data.emoji, buffer: buffer, boxed: false)
                serializeDouble(_data.temperatureC, buffer: buffer, boxed: false)
                serializeInt32(_data.color, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .inputMediaAreaChannelPost(let _data):
                return ("inputMediaAreaChannelPost", [("coordinates", ConstructorParameterDescription(_data.coordinates)), ("channel", ConstructorParameterDescription(_data.channel)), ("msgId", ConstructorParameterDescription(_data.msgId))])
            case .inputMediaAreaVenue(let _data):
                return ("inputMediaAreaVenue", [("coordinates", ConstructorParameterDescription(_data.coordinates)), ("queryId", ConstructorParameterDescription(_data.queryId)), ("resultId", ConstructorParameterDescription(_data.resultId))])
            case .mediaAreaChannelPost(let _data):
                return ("mediaAreaChannelPost", [("coordinates", ConstructorParameterDescription(_data.coordinates)), ("channelId", ConstructorParameterDescription(_data.channelId)), ("msgId", ConstructorParameterDescription(_data.msgId))])
            case .mediaAreaGeoPoint(let _data):
                return ("mediaAreaGeoPoint", [("flags", ConstructorParameterDescription(_data.flags)), ("coordinates", ConstructorParameterDescription(_data.coordinates)), ("geo", ConstructorParameterDescription(_data.geo)), ("address", ConstructorParameterDescription(_data.address))])
            case .mediaAreaStarGift(let _data):
                return ("mediaAreaStarGift", [("coordinates", ConstructorParameterDescription(_data.coordinates)), ("slug", ConstructorParameterDescription(_data.slug))])
            case .mediaAreaSuggestedReaction(let _data):
                return ("mediaAreaSuggestedReaction", [("flags", ConstructorParameterDescription(_data.flags)), ("coordinates", ConstructorParameterDescription(_data.coordinates)), ("reaction", ConstructorParameterDescription(_data.reaction))])
            case .mediaAreaUrl(let _data):
                return ("mediaAreaUrl", [("coordinates", ConstructorParameterDescription(_data.coordinates)), ("url", ConstructorParameterDescription(_data.url))])
            case .mediaAreaVenue(let _data):
                return ("mediaAreaVenue", [("coordinates", ConstructorParameterDescription(_data.coordinates)), ("geo", ConstructorParameterDescription(_data.geo)), ("title", ConstructorParameterDescription(_data.title)), ("address", ConstructorParameterDescription(_data.address)), ("provider", ConstructorParameterDescription(_data.provider)), ("venueId", ConstructorParameterDescription(_data.venueId)), ("venueType", ConstructorParameterDescription(_data.venueType))])
            case .mediaAreaWeather(let _data):
                return ("mediaAreaWeather", [("coordinates", ConstructorParameterDescription(_data.coordinates)), ("emoji", ConstructorParameterDescription(_data.emoji)), ("temperatureC", ConstructorParameterDescription(_data.temperatureC)), ("color", ConstructorParameterDescription(_data.color))])
            }
        }

        public static func parse_inputMediaAreaChannelPost(_ reader: BufferReader) -> MediaArea? {
            var _1: Api.MediaAreaCoordinates?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.MediaAreaCoordinates
            }
            var _2: Api.InputChannel?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.InputChannel
            }
            var _3: Int32?
            _3 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.MediaArea.inputMediaAreaChannelPost(Cons_inputMediaAreaChannelPost(coordinates: _1!, channel: _2!, msgId: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputMediaAreaVenue(_ reader: BufferReader) -> MediaArea? {
            var _1: Api.MediaAreaCoordinates?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.MediaAreaCoordinates
            }
            var _2: Int64?
            _2 = reader.readInt64()
            var _3: String?
            _3 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.MediaArea.inputMediaAreaVenue(Cons_inputMediaAreaVenue(coordinates: _1!, queryId: _2!, resultId: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_mediaAreaChannelPost(_ reader: BufferReader) -> MediaArea? {
            var _1: Api.MediaAreaCoordinates?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.MediaAreaCoordinates
            }
            var _2: Int64?
            _2 = reader.readInt64()
            var _3: Int32?
            _3 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.MediaArea.mediaAreaChannelPost(Cons_mediaAreaChannelPost(coordinates: _1!, channelId: _2!, msgId: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_mediaAreaGeoPoint(_ reader: BufferReader) -> MediaArea? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.MediaAreaCoordinates?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.MediaAreaCoordinates
            }
            var _3: Api.GeoPoint?
            if let signature = reader.readInt32() {
                _3 = Api.parse(reader, signature: signature) as? Api.GeoPoint
            }
            var _4: Api.GeoPointAddress?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                if let signature = reader.readInt32() {
                    _4 = Api.parse(reader, signature: signature) as? Api.GeoPointAddress
                }
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.MediaArea.mediaAreaGeoPoint(Cons_mediaAreaGeoPoint(flags: _1!, coordinates: _2!, geo: _3!, address: _4))
            }
            else {
                return nil
            }
        }
        public static func parse_mediaAreaStarGift(_ reader: BufferReader) -> MediaArea? {
            var _1: Api.MediaAreaCoordinates?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.MediaAreaCoordinates
            }
            var _2: String?
            _2 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.MediaArea.mediaAreaStarGift(Cons_mediaAreaStarGift(coordinates: _1!, slug: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_mediaAreaSuggestedReaction(_ reader: BufferReader) -> MediaArea? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.MediaAreaCoordinates?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.MediaAreaCoordinates
            }
            var _3: Api.Reaction?
            if let signature = reader.readInt32() {
                _3 = Api.parse(reader, signature: signature) as? Api.Reaction
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.MediaArea.mediaAreaSuggestedReaction(Cons_mediaAreaSuggestedReaction(flags: _1!, coordinates: _2!, reaction: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_mediaAreaUrl(_ reader: BufferReader) -> MediaArea? {
            var _1: Api.MediaAreaCoordinates?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.MediaAreaCoordinates
            }
            var _2: String?
            _2 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.MediaArea.mediaAreaUrl(Cons_mediaAreaUrl(coordinates: _1!, url: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_mediaAreaVenue(_ reader: BufferReader) -> MediaArea? {
            var _1: Api.MediaAreaCoordinates?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.MediaAreaCoordinates
            }
            var _2: Api.GeoPoint?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.GeoPoint
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            _4 = parseString(reader)
            var _5: String?
            _5 = parseString(reader)
            var _6: String?
            _6 = parseString(reader)
            var _7: String?
            _7 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            let _c7 = _7 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 {
                return Api.MediaArea.mediaAreaVenue(Cons_mediaAreaVenue(coordinates: _1!, geo: _2!, title: _3!, address: _4!, provider: _5!, venueId: _6!, venueType: _7!))
            }
            else {
                return nil
            }
        }
        public static func parse_mediaAreaWeather(_ reader: BufferReader) -> MediaArea? {
            var _1: Api.MediaAreaCoordinates?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.MediaAreaCoordinates
            }
            var _2: String?
            _2 = parseString(reader)
            var _3: Double?
            _3 = reader.readDouble()
            var _4: Int32?
            _4 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.MediaArea.mediaAreaWeather(Cons_mediaAreaWeather(coordinates: _1!, emoji: _2!, temperatureC: _3!, color: _4!))
            }
            else {
                return nil
            }
        }
    }
}
