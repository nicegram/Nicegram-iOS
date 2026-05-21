public extension Api.auth {
    enum SentCodeType: TypeConstructorDescription {
        public class Cons_sentCodeTypeApp: TypeConstructorDescription {
            public var length: Int32
            public init(length: Int32) {
                self.length = length
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCodeTypeApp", [("length", ConstructorParameterDescription(self.length))])
            }
        }
        public class Cons_sentCodeTypeCall: TypeConstructorDescription {
            public var length: Int32
            public init(length: Int32) {
                self.length = length
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCodeTypeCall", [("length", ConstructorParameterDescription(self.length))])
            }
        }
        public class Cons_sentCodeTypeEmailCode: TypeConstructorDescription {
            public var flags: Int32
            public var emailPattern: String
            public var length: Int32
            public var resetAvailablePeriod: Int32?
            public var resetPendingDate: Int32?
            public init(flags: Int32, emailPattern: String, length: Int32, resetAvailablePeriod: Int32?, resetPendingDate: Int32?) {
                self.flags = flags
                self.emailPattern = emailPattern
                self.length = length
                self.resetAvailablePeriod = resetAvailablePeriod
                self.resetPendingDate = resetPendingDate
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCodeTypeEmailCode", [("flags", ConstructorParameterDescription(self.flags)), ("emailPattern", ConstructorParameterDescription(self.emailPattern)), ("length", ConstructorParameterDescription(self.length)), ("resetAvailablePeriod", ConstructorParameterDescription(self.resetAvailablePeriod)), ("resetPendingDate", ConstructorParameterDescription(self.resetPendingDate))])
            }
        }
        public class Cons_sentCodeTypeFirebaseSms: TypeConstructorDescription {
            public var flags: Int32
            public var nonce: Buffer?
            public var playIntegrityProjectId: Int64?
            public var playIntegrityNonce: Buffer?
            public var receipt: String?
            public var pushTimeout: Int32?
            public var length: Int32
            public init(flags: Int32, nonce: Buffer?, playIntegrityProjectId: Int64?, playIntegrityNonce: Buffer?, receipt: String?, pushTimeout: Int32?, length: Int32) {
                self.flags = flags
                self.nonce = nonce
                self.playIntegrityProjectId = playIntegrityProjectId
                self.playIntegrityNonce = playIntegrityNonce
                self.receipt = receipt
                self.pushTimeout = pushTimeout
                self.length = length
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCodeTypeFirebaseSms", [("flags", ConstructorParameterDescription(self.flags)), ("nonce", ConstructorParameterDescription(self.nonce)), ("playIntegrityProjectId", ConstructorParameterDescription(self.playIntegrityProjectId)), ("playIntegrityNonce", ConstructorParameterDescription(self.playIntegrityNonce)), ("receipt", ConstructorParameterDescription(self.receipt)), ("pushTimeout", ConstructorParameterDescription(self.pushTimeout)), ("length", ConstructorParameterDescription(self.length))])
            }
        }
        public class Cons_sentCodeTypeFlashCall: TypeConstructorDescription {
            public var pattern: String
            public init(pattern: String) {
                self.pattern = pattern
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCodeTypeFlashCall", [("pattern", ConstructorParameterDescription(self.pattern))])
            }
        }
        public class Cons_sentCodeTypeFragmentSms: TypeConstructorDescription {
            public var url: String
            public var length: Int32
            public init(url: String, length: Int32) {
                self.url = url
                self.length = length
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCodeTypeFragmentSms", [("url", ConstructorParameterDescription(self.url)), ("length", ConstructorParameterDescription(self.length))])
            }
        }
        public class Cons_sentCodeTypeMissedCall: TypeConstructorDescription {
            public var prefix: String
            public var length: Int32
            public init(prefix: String, length: Int32) {
                self.prefix = prefix
                self.length = length
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCodeTypeMissedCall", [("prefix", ConstructorParameterDescription(self.prefix)), ("length", ConstructorParameterDescription(self.length))])
            }
        }
        public class Cons_sentCodeTypeSetUpEmailRequired: TypeConstructorDescription {
            public var flags: Int32
            public init(flags: Int32) {
                self.flags = flags
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCodeTypeSetUpEmailRequired", [("flags", ConstructorParameterDescription(self.flags))])
            }
        }
        public class Cons_sentCodeTypeSms: TypeConstructorDescription {
            public var length: Int32
            public init(length: Int32) {
                self.length = length
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCodeTypeSms", [("length", ConstructorParameterDescription(self.length))])
            }
        }
        public class Cons_sentCodeTypeSmsPhrase: TypeConstructorDescription {
            public var flags: Int32
            public var beginning: String?
            public init(flags: Int32, beginning: String?) {
                self.flags = flags
                self.beginning = beginning
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCodeTypeSmsPhrase", [("flags", ConstructorParameterDescription(self.flags)), ("beginning", ConstructorParameterDescription(self.beginning))])
            }
        }
        public class Cons_sentCodeTypeSmsWord: TypeConstructorDescription {
            public var flags: Int32
            public var beginning: String?
            public init(flags: Int32, beginning: String?) {
                self.flags = flags
                self.beginning = beginning
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sentCodeTypeSmsWord", [("flags", ConstructorParameterDescription(self.flags)), ("beginning", ConstructorParameterDescription(self.beginning))])
            }
        }
        case sentCodeTypeApp(Cons_sentCodeTypeApp)
        case sentCodeTypeCall(Cons_sentCodeTypeCall)
        case sentCodeTypeEmailCode(Cons_sentCodeTypeEmailCode)
        case sentCodeTypeFirebaseSms(Cons_sentCodeTypeFirebaseSms)
        case sentCodeTypeFlashCall(Cons_sentCodeTypeFlashCall)
        case sentCodeTypeFragmentSms(Cons_sentCodeTypeFragmentSms)
        case sentCodeTypeMissedCall(Cons_sentCodeTypeMissedCall)
        case sentCodeTypeSetUpEmailRequired(Cons_sentCodeTypeSetUpEmailRequired)
        case sentCodeTypeSms(Cons_sentCodeTypeSms)
        case sentCodeTypeSmsPhrase(Cons_sentCodeTypeSmsPhrase)
        case sentCodeTypeSmsWord(Cons_sentCodeTypeSmsWord)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .sentCodeTypeApp(let _data):
                if boxed {
                    buffer.appendInt32(1035688326)
                }
                serializeInt32(_data.length, buffer: buffer, boxed: false)
                break
            case .sentCodeTypeCall(let _data):
                if boxed {
                    buffer.appendInt32(1398007207)
                }
                serializeInt32(_data.length, buffer: buffer, boxed: false)
                break
            case .sentCodeTypeEmailCode(let _data):
                if boxed {
                    buffer.appendInt32(-196020837)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeString(_data.emailPattern, buffer: buffer, boxed: false)
                serializeInt32(_data.length, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 3) != 0 {
                    serializeInt32(_data.resetAvailablePeriod!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 4) != 0 {
                    serializeInt32(_data.resetPendingDate!, buffer: buffer, boxed: false)
                }
                break
            case .sentCodeTypeFirebaseSms(let _data):
                if boxed {
                    buffer.appendInt32(10475318)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeBytes(_data.nonce!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeInt64(_data.playIntegrityProjectId!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeBytes(_data.playIntegrityNonce!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeString(_data.receipt!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeInt32(_data.pushTimeout!, buffer: buffer, boxed: false)
                }
                serializeInt32(_data.length, buffer: buffer, boxed: false)
                break
            case .sentCodeTypeFlashCall(let _data):
                if boxed {
                    buffer.appendInt32(-1425815847)
                }
                serializeString(_data.pattern, buffer: buffer, boxed: false)
                break
            case .sentCodeTypeFragmentSms(let _data):
                if boxed {
                    buffer.appendInt32(-648651719)
                }
                serializeString(_data.url, buffer: buffer, boxed: false)
                serializeInt32(_data.length, buffer: buffer, boxed: false)
                break
            case .sentCodeTypeMissedCall(let _data):
                if boxed {
                    buffer.appendInt32(-2113903484)
                }
                serializeString(_data.prefix, buffer: buffer, boxed: false)
                serializeInt32(_data.length, buffer: buffer, boxed: false)
                break
            case .sentCodeTypeSetUpEmailRequired(let _data):
                if boxed {
                    buffer.appendInt32(-1521934870)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                break
            case .sentCodeTypeSms(let _data):
                if boxed {
                    buffer.appendInt32(-1073693790)
                }
                serializeInt32(_data.length, buffer: buffer, boxed: false)
                break
            case .sentCodeTypeSmsPhrase(let _data):
                if boxed {
                    buffer.appendInt32(-1284008785)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeString(_data.beginning!, buffer: buffer, boxed: false)
                }
                break
            case .sentCodeTypeSmsWord(let _data):
                if boxed {
                    buffer.appendInt32(-1542017919)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeString(_data.beginning!, buffer: buffer, boxed: false)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .sentCodeTypeApp(let _data):
                return ("sentCodeTypeApp", [("length", ConstructorParameterDescription(_data.length))])
            case .sentCodeTypeCall(let _data):
                return ("sentCodeTypeCall", [("length", ConstructorParameterDescription(_data.length))])
            case .sentCodeTypeEmailCode(let _data):
                return ("sentCodeTypeEmailCode", [("flags", ConstructorParameterDescription(_data.flags)), ("emailPattern", ConstructorParameterDescription(_data.emailPattern)), ("length", ConstructorParameterDescription(_data.length)), ("resetAvailablePeriod", ConstructorParameterDescription(_data.resetAvailablePeriod)), ("resetPendingDate", ConstructorParameterDescription(_data.resetPendingDate))])
            case .sentCodeTypeFirebaseSms(let _data):
                return ("sentCodeTypeFirebaseSms", [("flags", ConstructorParameterDescription(_data.flags)), ("nonce", ConstructorParameterDescription(_data.nonce)), ("playIntegrityProjectId", ConstructorParameterDescription(_data.playIntegrityProjectId)), ("playIntegrityNonce", ConstructorParameterDescription(_data.playIntegrityNonce)), ("receipt", ConstructorParameterDescription(_data.receipt)), ("pushTimeout", ConstructorParameterDescription(_data.pushTimeout)), ("length", ConstructorParameterDescription(_data.length))])
            case .sentCodeTypeFlashCall(let _data):
                return ("sentCodeTypeFlashCall", [("pattern", ConstructorParameterDescription(_data.pattern))])
            case .sentCodeTypeFragmentSms(let _data):
                return ("sentCodeTypeFragmentSms", [("url", ConstructorParameterDescription(_data.url)), ("length", ConstructorParameterDescription(_data.length))])
            case .sentCodeTypeMissedCall(let _data):
                return ("sentCodeTypeMissedCall", [("prefix", ConstructorParameterDescription(_data.prefix)), ("length", ConstructorParameterDescription(_data.length))])
            case .sentCodeTypeSetUpEmailRequired(let _data):
                return ("sentCodeTypeSetUpEmailRequired", [("flags", ConstructorParameterDescription(_data.flags))])
            case .sentCodeTypeSms(let _data):
                return ("sentCodeTypeSms", [("length", ConstructorParameterDescription(_data.length))])
            case .sentCodeTypeSmsPhrase(let _data):
                return ("sentCodeTypeSmsPhrase", [("flags", ConstructorParameterDescription(_data.flags)), ("beginning", ConstructorParameterDescription(_data.beginning))])
            case .sentCodeTypeSmsWord(let _data):
                return ("sentCodeTypeSmsWord", [("flags", ConstructorParameterDescription(_data.flags)), ("beginning", ConstructorParameterDescription(_data.beginning))])
            }
        }

        public static func parse_sentCodeTypeApp(_ reader: BufferReader) -> SentCodeType? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.auth.SentCodeType.sentCodeTypeApp(Cons_sentCodeTypeApp(length: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_sentCodeTypeCall(_ reader: BufferReader) -> SentCodeType? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.auth.SentCodeType.sentCodeTypeCall(Cons_sentCodeTypeCall(length: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_sentCodeTypeEmailCode(_ reader: BufferReader) -> SentCodeType? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: Int32?
            _3 = reader.readInt32()
            var _4: Int32?
            if Int(_1 ?? 0) & Int(1 << 3) != 0 {
                _4 = reader.readInt32()
            }
            var _5: Int32?
            if Int(_1 ?? 0) & Int(1 << 4) != 0 {
                _5 = reader.readInt32()
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 3) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 4) == 0) || _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.auth.SentCodeType.sentCodeTypeEmailCode(Cons_sentCodeTypeEmailCode(flags: _1!, emailPattern: _2!, length: _3!, resetAvailablePeriod: _4, resetPendingDate: _5))
            }
            else {
                return nil
            }
        }
        public static func parse_sentCodeTypeFirebaseSms(_ reader: BufferReader) -> SentCodeType? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Buffer?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _2 = parseBytes(reader)
            }
            var _3: Int64?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _3 = reader.readInt64()
            }
            var _4: Buffer?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _4 = parseBytes(reader)
            }
            var _5: String?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _5 = parseString(reader)
            }
            var _6: Int32?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _6 = reader.readInt32()
            }
            var _7: Int32?
            _7 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _5 != nil
            let _c6 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _6 != nil
            let _c7 = _7 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 {
                return Api.auth.SentCodeType.sentCodeTypeFirebaseSms(Cons_sentCodeTypeFirebaseSms(flags: _1!, nonce: _2, playIntegrityProjectId: _3, playIntegrityNonce: _4, receipt: _5, pushTimeout: _6, length: _7!))
            }
            else {
                return nil
            }
        }
        public static func parse_sentCodeTypeFlashCall(_ reader: BufferReader) -> SentCodeType? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.auth.SentCodeType.sentCodeTypeFlashCall(Cons_sentCodeTypeFlashCall(pattern: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_sentCodeTypeFragmentSms(_ reader: BufferReader) -> SentCodeType? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int32?
            _2 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.auth.SentCodeType.sentCodeTypeFragmentSms(Cons_sentCodeTypeFragmentSms(url: _1!, length: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_sentCodeTypeMissedCall(_ reader: BufferReader) -> SentCodeType? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int32?
            _2 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.auth.SentCodeType.sentCodeTypeMissedCall(Cons_sentCodeTypeMissedCall(prefix: _1!, length: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_sentCodeTypeSetUpEmailRequired(_ reader: BufferReader) -> SentCodeType? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.auth.SentCodeType.sentCodeTypeSetUpEmailRequired(Cons_sentCodeTypeSetUpEmailRequired(flags: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_sentCodeTypeSms(_ reader: BufferReader) -> SentCodeType? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.auth.SentCodeType.sentCodeTypeSms(Cons_sentCodeTypeSms(length: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_sentCodeTypeSmsPhrase(_ reader: BufferReader) -> SentCodeType? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _2 = parseString(reader)
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _2 != nil
            if _c1 && _c2 {
                return Api.auth.SentCodeType.sentCodeTypeSmsPhrase(Cons_sentCodeTypeSmsPhrase(flags: _1!, beginning: _2))
            }
            else {
                return nil
            }
        }
        public static func parse_sentCodeTypeSmsWord(_ reader: BufferReader) -> SentCodeType? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _2 = parseString(reader)
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _2 != nil
            if _c1 && _c2 {
                return Api.auth.SentCodeType.sentCodeTypeSmsWord(Cons_sentCodeTypeSmsWord(flags: _1!, beginning: _2))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.bots {
    enum AccessSettings: TypeConstructorDescription {
        public class Cons_accessSettings: TypeConstructorDescription {
            public var flags: Int32
            public var addUsers: [Api.User]?
            public init(flags: Int32, addUsers: [Api.User]?) {
                self.flags = flags
                self.addUsers = addUsers
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("accessSettings", [("flags", ConstructorParameterDescription(self.flags)), ("addUsers", ConstructorParameterDescription(self.addUsers))])
            }
        }
        case accessSettings(Cons_accessSettings)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .accessSettings(let _data):
                if boxed {
                    buffer.appendInt32(-585121901)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.addUsers!.count))
                    for item in _data.addUsers! {
                        item.serialize(buffer, true)
                    }
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .accessSettings(let _data):
                return ("accessSettings", [("flags", ConstructorParameterDescription(_data.flags)), ("addUsers", ConstructorParameterDescription(_data.addUsers))])
            }
        }

        public static func parse_accessSettings(_ reader: BufferReader) -> AccessSettings? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.User]?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let _ = reader.readInt32() {
                    _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
                }
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _2 != nil
            if _c1 && _c2 {
                return Api.bots.AccessSettings.accessSettings(Cons_accessSettings(flags: _1!, addUsers: _2))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.bots {
    enum BotInfo: TypeConstructorDescription {
        public class Cons_botInfo: TypeConstructorDescription {
            public var name: String
            public var about: String
            public var description: String
            public init(name: String, about: String, description: String) {
                self.name = name
                self.about = about
                self.description = description
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("botInfo", [("name", ConstructorParameterDescription(self.name)), ("about", ConstructorParameterDescription(self.about)), ("description", ConstructorParameterDescription(self.description))])
            }
        }
        case botInfo(Cons_botInfo)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .botInfo(let _data):
                if boxed {
                    buffer.appendInt32(-391678544)
                }
                serializeString(_data.name, buffer: buffer, boxed: false)
                serializeString(_data.about, buffer: buffer, boxed: false)
                serializeString(_data.description, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .botInfo(let _data):
                return ("botInfo", [("name", ConstructorParameterDescription(_data.name)), ("about", ConstructorParameterDescription(_data.about)), ("description", ConstructorParameterDescription(_data.description))])
            }
        }

        public static func parse_botInfo(_ reader: BufferReader) -> BotInfo? {
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
                return Api.bots.BotInfo.botInfo(Cons_botInfo(name: _1!, about: _2!, description: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.bots {
    enum ExportedBotToken: TypeConstructorDescription {
        public class Cons_exportedBotToken: TypeConstructorDescription {
            public var token: String
            public init(token: String) {
                self.token = token
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("exportedBotToken", [("token", ConstructorParameterDescription(self.token))])
            }
        }
        case exportedBotToken(Cons_exportedBotToken)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .exportedBotToken(let _data):
                if boxed {
                    buffer.appendInt32(1012971041)
                }
                serializeString(_data.token, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .exportedBotToken(let _data):
                return ("exportedBotToken", [("token", ConstructorParameterDescription(_data.token))])
            }
        }

        public static func parse_exportedBotToken(_ reader: BufferReader) -> ExportedBotToken? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.bots.ExportedBotToken.exportedBotToken(Cons_exportedBotToken(token: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.bots {
    enum PopularAppBots: TypeConstructorDescription {
        public class Cons_popularAppBots: TypeConstructorDescription {
            public var flags: Int32
            public var nextOffset: String?
            public var users: [Api.User]
            public init(flags: Int32, nextOffset: String?, users: [Api.User]) {
                self.flags = flags
                self.nextOffset = nextOffset
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("popularAppBots", [("flags", ConstructorParameterDescription(self.flags)), ("nextOffset", ConstructorParameterDescription(self.nextOffset)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case popularAppBots(Cons_popularAppBots)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .popularAppBots(let _data):
                if boxed {
                    buffer.appendInt32(428978491)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeString(_data.nextOffset!, buffer: buffer, boxed: false)
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
            case .popularAppBots(let _data):
                return ("popularAppBots", [("flags", ConstructorParameterDescription(_data.flags)), ("nextOffset", ConstructorParameterDescription(_data.nextOffset)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_popularAppBots(_ reader: BufferReader) -> PopularAppBots? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _2 = parseString(reader)
            }
            var _3: [Api.User]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.bots.PopularAppBots.popularAppBots(Cons_popularAppBots(flags: _1!, nextOffset: _2, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.bots {
    enum PreviewInfo: TypeConstructorDescription {
        public class Cons_previewInfo: TypeConstructorDescription {
            public var media: [Api.BotPreviewMedia]
            public var langCodes: [String]
            public init(media: [Api.BotPreviewMedia], langCodes: [String]) {
                self.media = media
                self.langCodes = langCodes
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("previewInfo", [("media", ConstructorParameterDescription(self.media)), ("langCodes", ConstructorParameterDescription(self.langCodes))])
            }
        }
        case previewInfo(Cons_previewInfo)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .previewInfo(let _data):
                if boxed {
                    buffer.appendInt32(212278628)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.media.count))
                for item in _data.media {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.langCodes.count))
                for item in _data.langCodes {
                    serializeString(item, buffer: buffer, boxed: false)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .previewInfo(let _data):
                return ("previewInfo", [("media", ConstructorParameterDescription(_data.media)), ("langCodes", ConstructorParameterDescription(_data.langCodes))])
            }
        }

        public static func parse_previewInfo(_ reader: BufferReader) -> PreviewInfo? {
            var _1: [Api.BotPreviewMedia]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.BotPreviewMedia.self)
            }
            var _2: [String]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: -1255641564, elementType: String.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.bots.PreviewInfo.previewInfo(Cons_previewInfo(media: _1!, langCodes: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.bots {
    enum RequestedButton: TypeConstructorDescription {
        public class Cons_requestedButton: TypeConstructorDescription {
            public var webappReqId: String
            public init(webappReqId: String) {
                self.webappReqId = webappReqId
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("requestedButton", [("webappReqId", ConstructorParameterDescription(self.webappReqId))])
            }
        }
        case requestedButton(Cons_requestedButton)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .requestedButton(let _data):
                if boxed {
                    buffer.appendInt32(-247743273)
                }
                serializeString(_data.webappReqId, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .requestedButton(let _data):
                return ("requestedButton", [("webappReqId", ConstructorParameterDescription(_data.webappReqId))])
            }
        }

        public static func parse_requestedButton(_ reader: BufferReader) -> RequestedButton? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.bots.RequestedButton.requestedButton(Cons_requestedButton(webappReqId: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.channels {
    enum AdminLogResults: TypeConstructorDescription {
        public class Cons_adminLogResults: TypeConstructorDescription {
            public var events: [Api.ChannelAdminLogEvent]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(events: [Api.ChannelAdminLogEvent], chats: [Api.Chat], users: [Api.User]) {
                self.events = events
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("adminLogResults", [("events", ConstructorParameterDescription(self.events)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case adminLogResults(Cons_adminLogResults)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .adminLogResults(let _data):
                if boxed {
                    buffer.appendInt32(-309659827)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.events.count))
                for item in _data.events {
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
            case .adminLogResults(let _data):
                return ("adminLogResults", [("events", ConstructorParameterDescription(_data.events)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_adminLogResults(_ reader: BufferReader) -> AdminLogResults? {
            var _1: [Api.ChannelAdminLogEvent]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.ChannelAdminLogEvent.self)
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
                return Api.channels.AdminLogResults.adminLogResults(Cons_adminLogResults(events: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.channels {
    enum ChannelParticipant: TypeConstructorDescription {
        public class Cons_channelParticipant: TypeConstructorDescription {
            public var participant: Api.ChannelParticipant
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(participant: Api.ChannelParticipant, chats: [Api.Chat], users: [Api.User]) {
                self.participant = participant
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("channelParticipant", [("participant", ConstructorParameterDescription(self.participant)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case channelParticipant(Cons_channelParticipant)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .channelParticipant(let _data):
                if boxed {
                    buffer.appendInt32(-541588713)
                }
                _data.participant.serialize(buffer, true)
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
            case .channelParticipant(let _data):
                return ("channelParticipant", [("participant", ConstructorParameterDescription(_data.participant)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_channelParticipant(_ reader: BufferReader) -> ChannelParticipant? {
            var _1: Api.ChannelParticipant?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.ChannelParticipant
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
                return Api.channels.ChannelParticipant.channelParticipant(Cons_channelParticipant(participant: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.channels {
    enum ChannelParticipants: TypeConstructorDescription {
        public class Cons_channelParticipants: TypeConstructorDescription {
            public var count: Int32
            public var participants: [Api.ChannelParticipant]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(count: Int32, participants: [Api.ChannelParticipant], chats: [Api.Chat], users: [Api.User]) {
                self.count = count
                self.participants = participants
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("channelParticipants", [("count", ConstructorParameterDescription(self.count)), ("participants", ConstructorParameterDescription(self.participants)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case channelParticipants(Cons_channelParticipants)
        case channelParticipantsNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .channelParticipants(let _data):
                if boxed {
                    buffer.appendInt32(-1699676497)
                }
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.participants.count))
                for item in _data.participants {
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
            case .channelParticipantsNotModified:
                if boxed {
                    buffer.appendInt32(-266911767)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .channelParticipants(let _data):
                return ("channelParticipants", [("count", ConstructorParameterDescription(_data.count)), ("participants", ConstructorParameterDescription(_data.participants)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            case .channelParticipantsNotModified:
                return ("channelParticipantsNotModified", [])
            }
        }

        public static func parse_channelParticipants(_ reader: BufferReader) -> ChannelParticipants? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.ChannelParticipant]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.ChannelParticipant.self)
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
                return Api.channels.ChannelParticipants.channelParticipants(Cons_channelParticipants(count: _1!, participants: _2!, chats: _3!, users: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_channelParticipantsNotModified(_ reader: BufferReader) -> ChannelParticipants? {
            return Api.channels.ChannelParticipants.channelParticipantsNotModified
        }
    }
}
public extension Api.channels {
    enum SendAsPeers: TypeConstructorDescription {
        public class Cons_sendAsPeers: TypeConstructorDescription {
            public var peers: [Api.SendAsPeer]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(peers: [Api.SendAsPeer], chats: [Api.Chat], users: [Api.User]) {
                self.peers = peers
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sendAsPeers", [("peers", ConstructorParameterDescription(self.peers)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case sendAsPeers(Cons_sendAsPeers)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .sendAsPeers(let _data):
                if boxed {
                    buffer.appendInt32(-191450938)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.peers.count))
                for item in _data.peers {
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
            case .sendAsPeers(let _data):
                return ("sendAsPeers", [("peers", ConstructorParameterDescription(_data.peers)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_sendAsPeers(_ reader: BufferReader) -> SendAsPeers? {
            var _1: [Api.SendAsPeer]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.SendAsPeer.self)
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
                return Api.channels.SendAsPeers.sendAsPeers(Cons_sendAsPeers(peers: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.channels {
    enum SponsoredMessageReportResult: TypeConstructorDescription {
        public class Cons_sponsoredMessageReportResultChooseOption: TypeConstructorDescription {
            public var title: String
            public var options: [Api.SponsoredMessageReportOption]
            public init(title: String, options: [Api.SponsoredMessageReportOption]) {
                self.title = title
                self.options = options
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sponsoredMessageReportResultChooseOption", [("title", ConstructorParameterDescription(self.title)), ("options", ConstructorParameterDescription(self.options))])
            }
        }
        case sponsoredMessageReportResultAdsHidden
        case sponsoredMessageReportResultChooseOption(Cons_sponsoredMessageReportResultChooseOption)
        case sponsoredMessageReportResultReported

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .sponsoredMessageReportResultAdsHidden:
                if boxed {
                    buffer.appendInt32(1044107055)
                }
                break
            case .sponsoredMessageReportResultChooseOption(let _data):
                if boxed {
                    buffer.appendInt32(-2073059774)
                }
                serializeString(_data.title, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.options.count))
                for item in _data.options {
                    item.serialize(buffer, true)
                }
                break
            case .sponsoredMessageReportResultReported:
                if boxed {
                    buffer.appendInt32(-1384544183)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .sponsoredMessageReportResultAdsHidden:
                return ("sponsoredMessageReportResultAdsHidden", [])
            case .sponsoredMessageReportResultChooseOption(let _data):
                return ("sponsoredMessageReportResultChooseOption", [("title", ConstructorParameterDescription(_data.title)), ("options", ConstructorParameterDescription(_data.options))])
            case .sponsoredMessageReportResultReported:
                return ("sponsoredMessageReportResultReported", [])
            }
        }

        public static func parse_sponsoredMessageReportResultAdsHidden(_ reader: BufferReader) -> SponsoredMessageReportResult? {
            return Api.channels.SponsoredMessageReportResult.sponsoredMessageReportResultAdsHidden
        }
        public static func parse_sponsoredMessageReportResultChooseOption(_ reader: BufferReader) -> SponsoredMessageReportResult? {
            var _1: String?
            _1 = parseString(reader)
            var _2: [Api.SponsoredMessageReportOption]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.SponsoredMessageReportOption.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.channels.SponsoredMessageReportResult.sponsoredMessageReportResultChooseOption(Cons_sponsoredMessageReportResultChooseOption(title: _1!, options: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_sponsoredMessageReportResultReported(_ reader: BufferReader) -> SponsoredMessageReportResult? {
            return Api.channels.SponsoredMessageReportResult.sponsoredMessageReportResultReported
        }
    }
}
public extension Api.chatlists {
    enum ChatlistInvite: TypeConstructorDescription {
        public class Cons_chatlistInvite: TypeConstructorDescription {
            public var flags: Int32
            public var title: Api.TextWithEntities
            public var emoticon: String?
            public var peers: [Api.Peer]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(flags: Int32, title: Api.TextWithEntities, emoticon: String?, peers: [Api.Peer], chats: [Api.Chat], users: [Api.User]) {
                self.flags = flags
                self.title = title
                self.emoticon = emoticon
                self.peers = peers
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("chatlistInvite", [("flags", ConstructorParameterDescription(self.flags)), ("title", ConstructorParameterDescription(self.title)), ("emoticon", ConstructorParameterDescription(self.emoticon)), ("peers", ConstructorParameterDescription(self.peers)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        public class Cons_chatlistInviteAlready: TypeConstructorDescription {
            public var filterId: Int32
            public var missingPeers: [Api.Peer]
            public var alreadyPeers: [Api.Peer]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(filterId: Int32, missingPeers: [Api.Peer], alreadyPeers: [Api.Peer], chats: [Api.Chat], users: [Api.User]) {
                self.filterId = filterId
                self.missingPeers = missingPeers
                self.alreadyPeers = alreadyPeers
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("chatlistInviteAlready", [("filterId", ConstructorParameterDescription(self.filterId)), ("missingPeers", ConstructorParameterDescription(self.missingPeers)), ("alreadyPeers", ConstructorParameterDescription(self.alreadyPeers)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case chatlistInvite(Cons_chatlistInvite)
        case chatlistInviteAlready(Cons_chatlistInviteAlready)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .chatlistInvite(let _data):
                if boxed {
                    buffer.appendInt32(-250687953)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                _data.title.serialize(buffer, true)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeString(_data.emoticon!, buffer: buffer, boxed: false)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.peers.count))
                for item in _data.peers {
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
            case .chatlistInviteAlready(let _data):
                if boxed {
                    buffer.appendInt32(-91752871)
                }
                serializeInt32(_data.filterId, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.missingPeers.count))
                for item in _data.missingPeers {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.alreadyPeers.count))
                for item in _data.alreadyPeers {
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
            case .chatlistInvite(let _data):
                return ("chatlistInvite", [("flags", ConstructorParameterDescription(_data.flags)), ("title", ConstructorParameterDescription(_data.title)), ("emoticon", ConstructorParameterDescription(_data.emoticon)), ("peers", ConstructorParameterDescription(_data.peers)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            case .chatlistInviteAlready(let _data):
                return ("chatlistInviteAlready", [("filterId", ConstructorParameterDescription(_data.filterId)), ("missingPeers", ConstructorParameterDescription(_data.missingPeers)), ("alreadyPeers", ConstructorParameterDescription(_data.alreadyPeers)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_chatlistInvite(_ reader: BufferReader) -> ChatlistInvite? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.TextWithEntities?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.TextWithEntities
            }
            var _3: String?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _3 = parseString(reader)
            }
            var _4: [Api.Peer]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Peer.self)
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
            let _c3 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.chatlists.ChatlistInvite.chatlistInvite(Cons_chatlistInvite(flags: _1!, title: _2!, emoticon: _3, peers: _4!, chats: _5!, users: _6!))
            }
            else {
                return nil
            }
        }
        public static func parse_chatlistInviteAlready(_ reader: BufferReader) -> ChatlistInvite? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.Peer]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Peer.self)
            }
            var _3: [Api.Peer]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Peer.self)
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
                return Api.chatlists.ChatlistInvite.chatlistInviteAlready(Cons_chatlistInviteAlready(filterId: _1!, missingPeers: _2!, alreadyPeers: _3!, chats: _4!, users: _5!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.chatlists {
    enum ChatlistUpdates: TypeConstructorDescription {
        public class Cons_chatlistUpdates: TypeConstructorDescription {
            public var missingPeers: [Api.Peer]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(missingPeers: [Api.Peer], chats: [Api.Chat], users: [Api.User]) {
                self.missingPeers = missingPeers
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("chatlistUpdates", [("missingPeers", ConstructorParameterDescription(self.missingPeers)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case chatlistUpdates(Cons_chatlistUpdates)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .chatlistUpdates(let _data):
                if boxed {
                    buffer.appendInt32(-1816295539)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.missingPeers.count))
                for item in _data.missingPeers {
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
            case .chatlistUpdates(let _data):
                return ("chatlistUpdates", [("missingPeers", ConstructorParameterDescription(_data.missingPeers)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_chatlistUpdates(_ reader: BufferReader) -> ChatlistUpdates? {
            var _1: [Api.Peer]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Peer.self)
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
                return Api.chatlists.ChatlistUpdates.chatlistUpdates(Cons_chatlistUpdates(missingPeers: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.chatlists {
    enum ExportedChatlistInvite: TypeConstructorDescription {
        public class Cons_exportedChatlistInvite: TypeConstructorDescription {
            public var filter: Api.DialogFilter
            public var invite: Api.ExportedChatlistInvite
            public init(filter: Api.DialogFilter, invite: Api.ExportedChatlistInvite) {
                self.filter = filter
                self.invite = invite
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("exportedChatlistInvite", [("filter", ConstructorParameterDescription(self.filter)), ("invite", ConstructorParameterDescription(self.invite))])
            }
        }
        case exportedChatlistInvite(Cons_exportedChatlistInvite)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .exportedChatlistInvite(let _data):
                if boxed {
                    buffer.appendInt32(283567014)
                }
                _data.filter.serialize(buffer, true)
                _data.invite.serialize(buffer, true)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .exportedChatlistInvite(let _data):
                return ("exportedChatlistInvite", [("filter", ConstructorParameterDescription(_data.filter)), ("invite", ConstructorParameterDescription(_data.invite))])
            }
        }

        public static func parse_exportedChatlistInvite(_ reader: BufferReader) -> ExportedChatlistInvite? {
            var _1: Api.DialogFilter?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.DialogFilter
            }
            var _2: Api.ExportedChatlistInvite?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.ExportedChatlistInvite
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.chatlists.ExportedChatlistInvite.exportedChatlistInvite(Cons_exportedChatlistInvite(filter: _1!, invite: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.chatlists {
    enum ExportedInvites: TypeConstructorDescription {
        public class Cons_exportedInvites: TypeConstructorDescription {
            public var invites: [Api.ExportedChatlistInvite]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(invites: [Api.ExportedChatlistInvite], chats: [Api.Chat], users: [Api.User]) {
                self.invites = invites
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("exportedInvites", [("invites", ConstructorParameterDescription(self.invites)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case exportedInvites(Cons_exportedInvites)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .exportedInvites(let _data):
                if boxed {
                    buffer.appendInt32(279670215)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.invites.count))
                for item in _data.invites {
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
            case .exportedInvites(let _data):
                return ("exportedInvites", [("invites", ConstructorParameterDescription(_data.invites)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_exportedInvites(_ reader: BufferReader) -> ExportedInvites? {
            var _1: [Api.ExportedChatlistInvite]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.ExportedChatlistInvite.self)
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
                return Api.chatlists.ExportedInvites.exportedInvites(Cons_exportedInvites(invites: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.contacts {
    enum Blocked: TypeConstructorDescription {
        public class Cons_blocked: TypeConstructorDescription {
            public var blocked: [Api.PeerBlocked]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(blocked: [Api.PeerBlocked], chats: [Api.Chat], users: [Api.User]) {
                self.blocked = blocked
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("blocked", [("blocked", ConstructorParameterDescription(self.blocked)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        public class Cons_blockedSlice: TypeConstructorDescription {
            public var count: Int32
            public var blocked: [Api.PeerBlocked]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(count: Int32, blocked: [Api.PeerBlocked], chats: [Api.Chat], users: [Api.User]) {
                self.count = count
                self.blocked = blocked
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("blockedSlice", [("count", ConstructorParameterDescription(self.count)), ("blocked", ConstructorParameterDescription(self.blocked)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case blocked(Cons_blocked)
        case blockedSlice(Cons_blockedSlice)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .blocked(let _data):
                if boxed {
                    buffer.appendInt32(182326673)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.blocked.count))
                for item in _data.blocked {
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
            case .blockedSlice(let _data):
                if boxed {
                    buffer.appendInt32(-513392236)
                }
                serializeInt32(_data.count, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.blocked.count))
                for item in _data.blocked {
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
            case .blocked(let _data):
                return ("blocked", [("blocked", ConstructorParameterDescription(_data.blocked)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            case .blockedSlice(let _data):
                return ("blockedSlice", [("count", ConstructorParameterDescription(_data.count)), ("blocked", ConstructorParameterDescription(_data.blocked)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_blocked(_ reader: BufferReader) -> Blocked? {
            var _1: [Api.PeerBlocked]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.PeerBlocked.self)
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
                return Api.contacts.Blocked.blocked(Cons_blocked(blocked: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_blockedSlice(_ reader: BufferReader) -> Blocked? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.PeerBlocked]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.PeerBlocked.self)
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
                return Api.contacts.Blocked.blockedSlice(Cons_blockedSlice(count: _1!, blocked: _2!, chats: _3!, users: _4!))
            }
            else {
                return nil
            }
        }
    }
}
