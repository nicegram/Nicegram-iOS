public extension Api {
    indirect enum InputStorePaymentPurpose: TypeConstructorDescription {
        public class Cons_inputStorePaymentAuthCode: TypeConstructorDescription {
            public var flags: Int32
            public var phoneNumber: String
            public var phoneCodeHash: String
            public var premiumDays: Int32
            public var currency: String
            public var amount: Int64
            public init(flags: Int32, phoneNumber: String, phoneCodeHash: String, premiumDays: Int32, currency: String, amount: Int64) {
                self.flags = flags
                self.phoneNumber = phoneNumber
                self.phoneCodeHash = phoneCodeHash
                self.premiumDays = premiumDays
                self.currency = currency
                self.amount = amount
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputStorePaymentAuthCode", [("flags", ConstructorParameterDescription(self.flags)), ("phoneNumber", ConstructorParameterDescription(self.phoneNumber)), ("phoneCodeHash", ConstructorParameterDescription(self.phoneCodeHash)), ("premiumDays", ConstructorParameterDescription(self.premiumDays)), ("currency", ConstructorParameterDescription(self.currency)), ("amount", ConstructorParameterDescription(self.amount))])
            }
        }
        public class Cons_inputStorePaymentGiftPremium: TypeConstructorDescription {
            public var userId: Api.InputUser
            public var currency: String
            public var amount: Int64
            public init(userId: Api.InputUser, currency: String, amount: Int64) {
                self.userId = userId
                self.currency = currency
                self.amount = amount
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputStorePaymentGiftPremium", [("userId", ConstructorParameterDescription(self.userId)), ("currency", ConstructorParameterDescription(self.currency)), ("amount", ConstructorParameterDescription(self.amount))])
            }
        }
        public class Cons_inputStorePaymentPremiumGiftCode: TypeConstructorDescription {
            public var flags: Int32
            public var users: [Api.InputUser]
            public var boostPeer: Api.InputPeer?
            public var currency: String
            public var amount: Int64
            public var message: Api.TextWithEntities?
            public init(flags: Int32, users: [Api.InputUser], boostPeer: Api.InputPeer?, currency: String, amount: Int64, message: Api.TextWithEntities?) {
                self.flags = flags
                self.users = users
                self.boostPeer = boostPeer
                self.currency = currency
                self.amount = amount
                self.message = message
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputStorePaymentPremiumGiftCode", [("flags", ConstructorParameterDescription(self.flags)), ("users", ConstructorParameterDescription(self.users)), ("boostPeer", ConstructorParameterDescription(self.boostPeer)), ("currency", ConstructorParameterDescription(self.currency)), ("amount", ConstructorParameterDescription(self.amount)), ("message", ConstructorParameterDescription(self.message))])
            }
        }
        public class Cons_inputStorePaymentPremiumGiveaway: TypeConstructorDescription {
            public var flags: Int32
            public var boostPeer: Api.InputPeer
            public var additionalPeers: [Api.InputPeer]?
            public var countriesIso2: [String]?
            public var prizeDescription: String?
            public var randomId: Int64
            public var untilDate: Int32
            public var currency: String
            public var amount: Int64
            public init(flags: Int32, boostPeer: Api.InputPeer, additionalPeers: [Api.InputPeer]?, countriesIso2: [String]?, prizeDescription: String?, randomId: Int64, untilDate: Int32, currency: String, amount: Int64) {
                self.flags = flags
                self.boostPeer = boostPeer
                self.additionalPeers = additionalPeers
                self.countriesIso2 = countriesIso2
                self.prizeDescription = prizeDescription
                self.randomId = randomId
                self.untilDate = untilDate
                self.currency = currency
                self.amount = amount
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputStorePaymentPremiumGiveaway", [("flags", ConstructorParameterDescription(self.flags)), ("boostPeer", ConstructorParameterDescription(self.boostPeer)), ("additionalPeers", ConstructorParameterDescription(self.additionalPeers)), ("countriesIso2", ConstructorParameterDescription(self.countriesIso2)), ("prizeDescription", ConstructorParameterDescription(self.prizeDescription)), ("randomId", ConstructorParameterDescription(self.randomId)), ("untilDate", ConstructorParameterDescription(self.untilDate)), ("currency", ConstructorParameterDescription(self.currency)), ("amount", ConstructorParameterDescription(self.amount))])
            }
        }
        public class Cons_inputStorePaymentPremiumSubscription: TypeConstructorDescription {
            public var flags: Int32
            public init(flags: Int32) {
                self.flags = flags
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputStorePaymentPremiumSubscription", [("flags", ConstructorParameterDescription(self.flags))])
            }
        }
        public class Cons_inputStorePaymentStarsGift: TypeConstructorDescription {
            public var userId: Api.InputUser
            public var stars: Int64
            public var currency: String
            public var amount: Int64
            public init(userId: Api.InputUser, stars: Int64, currency: String, amount: Int64) {
                self.userId = userId
                self.stars = stars
                self.currency = currency
                self.amount = amount
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputStorePaymentStarsGift", [("userId", ConstructorParameterDescription(self.userId)), ("stars", ConstructorParameterDescription(self.stars)), ("currency", ConstructorParameterDescription(self.currency)), ("amount", ConstructorParameterDescription(self.amount))])
            }
        }
        public class Cons_inputStorePaymentStarsGiveaway: TypeConstructorDescription {
            public var flags: Int32
            public var stars: Int64
            public var boostPeer: Api.InputPeer
            public var additionalPeers: [Api.InputPeer]?
            public var countriesIso2: [String]?
            public var prizeDescription: String?
            public var randomId: Int64
            public var untilDate: Int32
            public var currency: String
            public var amount: Int64
            public var users: Int32
            public init(flags: Int32, stars: Int64, boostPeer: Api.InputPeer, additionalPeers: [Api.InputPeer]?, countriesIso2: [String]?, prizeDescription: String?, randomId: Int64, untilDate: Int32, currency: String, amount: Int64, users: Int32) {
                self.flags = flags
                self.stars = stars
                self.boostPeer = boostPeer
                self.additionalPeers = additionalPeers
                self.countriesIso2 = countriesIso2
                self.prizeDescription = prizeDescription
                self.randomId = randomId
                self.untilDate = untilDate
                self.currency = currency
                self.amount = amount
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputStorePaymentStarsGiveaway", [("flags", ConstructorParameterDescription(self.flags)), ("stars", ConstructorParameterDescription(self.stars)), ("boostPeer", ConstructorParameterDescription(self.boostPeer)), ("additionalPeers", ConstructorParameterDescription(self.additionalPeers)), ("countriesIso2", ConstructorParameterDescription(self.countriesIso2)), ("prizeDescription", ConstructorParameterDescription(self.prizeDescription)), ("randomId", ConstructorParameterDescription(self.randomId)), ("untilDate", ConstructorParameterDescription(self.untilDate)), ("currency", ConstructorParameterDescription(self.currency)), ("amount", ConstructorParameterDescription(self.amount)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        public class Cons_inputStorePaymentStarsTopup: TypeConstructorDescription {
            public var flags: Int32
            public var stars: Int64
            public var currency: String
            public var amount: Int64
            public var spendPurposePeer: Api.InputPeer?
            public init(flags: Int32, stars: Int64, currency: String, amount: Int64, spendPurposePeer: Api.InputPeer?) {
                self.flags = flags
                self.stars = stars
                self.currency = currency
                self.amount = amount
                self.spendPurposePeer = spendPurposePeer
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputStorePaymentStarsTopup", [("flags", ConstructorParameterDescription(self.flags)), ("stars", ConstructorParameterDescription(self.stars)), ("currency", ConstructorParameterDescription(self.currency)), ("amount", ConstructorParameterDescription(self.amount)), ("spendPurposePeer", ConstructorParameterDescription(self.spendPurposePeer))])
            }
        }
        case inputStorePaymentAuthCode(Cons_inputStorePaymentAuthCode)
        case inputStorePaymentGiftPremium(Cons_inputStorePaymentGiftPremium)
        case inputStorePaymentPremiumGiftCode(Cons_inputStorePaymentPremiumGiftCode)
        case inputStorePaymentPremiumGiveaway(Cons_inputStorePaymentPremiumGiveaway)
        case inputStorePaymentPremiumSubscription(Cons_inputStorePaymentPremiumSubscription)
        case inputStorePaymentStarsGift(Cons_inputStorePaymentStarsGift)
        case inputStorePaymentStarsGiveaway(Cons_inputStorePaymentStarsGiveaway)
        case inputStorePaymentStarsTopup(Cons_inputStorePaymentStarsTopup)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .inputStorePaymentAuthCode(let _data):
                if boxed {
                    buffer.appendInt32(1069645911)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeString(_data.phoneNumber, buffer: buffer, boxed: false)
                serializeString(_data.phoneCodeHash, buffer: buffer, boxed: false)
                serializeInt32(_data.premiumDays, buffer: buffer, boxed: false)
                serializeString(_data.currency, buffer: buffer, boxed: false)
                serializeInt64(_data.amount, buffer: buffer, boxed: false)
                break
            case .inputStorePaymentGiftPremium(let _data):
                if boxed {
                    buffer.appendInt32(1634697192)
                }
                _data.userId.serialize(buffer, true)
                serializeString(_data.currency, buffer: buffer, boxed: false)
                serializeInt64(_data.amount, buffer: buffer, boxed: false)
                break
            case .inputStorePaymentPremiumGiftCode(let _data):
                if boxed {
                    buffer.appendInt32(-75955309)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.users.count))
                for item in _data.users {
                    item.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    _data.boostPeer!.serialize(buffer, true)
                }
                serializeString(_data.currency, buffer: buffer, boxed: false)
                serializeInt64(_data.amount, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    _data.message!.serialize(buffer, true)
                }
                break
            case .inputStorePaymentPremiumGiveaway(let _data):
                if boxed {
                    buffer.appendInt32(369444042)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                _data.boostPeer.serialize(buffer, true)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.additionalPeers!.count))
                    for item in _data.additionalPeers! {
                        item.serialize(buffer, true)
                    }
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.countriesIso2!.count))
                    for item in _data.countriesIso2! {
                        serializeString(item, buffer: buffer, boxed: false)
                    }
                }
                if Int(_data.flags) & Int(1 << 4) != 0 {
                    serializeString(_data.prizeDescription!, buffer: buffer, boxed: false)
                }
                serializeInt64(_data.randomId, buffer: buffer, boxed: false)
                serializeInt32(_data.untilDate, buffer: buffer, boxed: false)
                serializeString(_data.currency, buffer: buffer, boxed: false)
                serializeInt64(_data.amount, buffer: buffer, boxed: false)
                break
            case .inputStorePaymentPremiumSubscription(let _data):
                if boxed {
                    buffer.appendInt32(-1502273946)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                break
            case .inputStorePaymentStarsGift(let _data):
                if boxed {
                    buffer.appendInt32(494149367)
                }
                _data.userId.serialize(buffer, true)
                serializeInt64(_data.stars, buffer: buffer, boxed: false)
                serializeString(_data.currency, buffer: buffer, boxed: false)
                serializeInt64(_data.amount, buffer: buffer, boxed: false)
                break
            case .inputStorePaymentStarsGiveaway(let _data):
                if boxed {
                    buffer.appendInt32(1964968186)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt64(_data.stars, buffer: buffer, boxed: false)
                _data.boostPeer.serialize(buffer, true)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.additionalPeers!.count))
                    for item in _data.additionalPeers! {
                        item.serialize(buffer, true)
                    }
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.countriesIso2!.count))
                    for item in _data.countriesIso2! {
                        serializeString(item, buffer: buffer, boxed: false)
                    }
                }
                if Int(_data.flags) & Int(1 << 4) != 0 {
                    serializeString(_data.prizeDescription!, buffer: buffer, boxed: false)
                }
                serializeInt64(_data.randomId, buffer: buffer, boxed: false)
                serializeInt32(_data.untilDate, buffer: buffer, boxed: false)
                serializeString(_data.currency, buffer: buffer, boxed: false)
                serializeInt64(_data.amount, buffer: buffer, boxed: false)
                serializeInt32(_data.users, buffer: buffer, boxed: false)
                break
            case .inputStorePaymentStarsTopup(let _data):
                if boxed {
                    buffer.appendInt32(-106780981)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt64(_data.stars, buffer: buffer, boxed: false)
                serializeString(_data.currency, buffer: buffer, boxed: false)
                serializeInt64(_data.amount, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    _data.spendPurposePeer!.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .inputStorePaymentAuthCode(let _data):
                return ("inputStorePaymentAuthCode", [("flags", ConstructorParameterDescription(_data.flags)), ("phoneNumber", ConstructorParameterDescription(_data.phoneNumber)), ("phoneCodeHash", ConstructorParameterDescription(_data.phoneCodeHash)), ("premiumDays", ConstructorParameterDescription(_data.premiumDays)), ("currency", ConstructorParameterDescription(_data.currency)), ("amount", ConstructorParameterDescription(_data.amount))])
            case .inputStorePaymentGiftPremium(let _data):
                return ("inputStorePaymentGiftPremium", [("userId", ConstructorParameterDescription(_data.userId)), ("currency", ConstructorParameterDescription(_data.currency)), ("amount", ConstructorParameterDescription(_data.amount))])
            case .inputStorePaymentPremiumGiftCode(let _data):
                return ("inputStorePaymentPremiumGiftCode", [("flags", ConstructorParameterDescription(_data.flags)), ("users", ConstructorParameterDescription(_data.users)), ("boostPeer", ConstructorParameterDescription(_data.boostPeer)), ("currency", ConstructorParameterDescription(_data.currency)), ("amount", ConstructorParameterDescription(_data.amount)), ("message", ConstructorParameterDescription(_data.message))])
            case .inputStorePaymentPremiumGiveaway(let _data):
                return ("inputStorePaymentPremiumGiveaway", [("flags", ConstructorParameterDescription(_data.flags)), ("boostPeer", ConstructorParameterDescription(_data.boostPeer)), ("additionalPeers", ConstructorParameterDescription(_data.additionalPeers)), ("countriesIso2", ConstructorParameterDescription(_data.countriesIso2)), ("prizeDescription", ConstructorParameterDescription(_data.prizeDescription)), ("randomId", ConstructorParameterDescription(_data.randomId)), ("untilDate", ConstructorParameterDescription(_data.untilDate)), ("currency", ConstructorParameterDescription(_data.currency)), ("amount", ConstructorParameterDescription(_data.amount))])
            case .inputStorePaymentPremiumSubscription(let _data):
                return ("inputStorePaymentPremiumSubscription", [("flags", ConstructorParameterDescription(_data.flags))])
            case .inputStorePaymentStarsGift(let _data):
                return ("inputStorePaymentStarsGift", [("userId", ConstructorParameterDescription(_data.userId)), ("stars", ConstructorParameterDescription(_data.stars)), ("currency", ConstructorParameterDescription(_data.currency)), ("amount", ConstructorParameterDescription(_data.amount))])
            case .inputStorePaymentStarsGiveaway(let _data):
                return ("inputStorePaymentStarsGiveaway", [("flags", ConstructorParameterDescription(_data.flags)), ("stars", ConstructorParameterDescription(_data.stars)), ("boostPeer", ConstructorParameterDescription(_data.boostPeer)), ("additionalPeers", ConstructorParameterDescription(_data.additionalPeers)), ("countriesIso2", ConstructorParameterDescription(_data.countriesIso2)), ("prizeDescription", ConstructorParameterDescription(_data.prizeDescription)), ("randomId", ConstructorParameterDescription(_data.randomId)), ("untilDate", ConstructorParameterDescription(_data.untilDate)), ("currency", ConstructorParameterDescription(_data.currency)), ("amount", ConstructorParameterDescription(_data.amount)), ("users", ConstructorParameterDescription(_data.users))])
            case .inputStorePaymentStarsTopup(let _data):
                return ("inputStorePaymentStarsTopup", [("flags", ConstructorParameterDescription(_data.flags)), ("stars", ConstructorParameterDescription(_data.stars)), ("currency", ConstructorParameterDescription(_data.currency)), ("amount", ConstructorParameterDescription(_data.amount)), ("spendPurposePeer", ConstructorParameterDescription(_data.spendPurposePeer))])
            }
        }

        public static func parse_inputStorePaymentAuthCode(_ reader: BufferReader) -> InputStorePaymentPurpose? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: String?
            _3 = parseString(reader)
            var _4: Int32?
            _4 = reader.readInt32()
            var _5: String?
            _5 = parseString(reader)
            var _6: Int64?
            _6 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.InputStorePaymentPurpose.inputStorePaymentAuthCode(Cons_inputStorePaymentAuthCode(flags: _1!, phoneNumber: _2!, phoneCodeHash: _3!, premiumDays: _4!, currency: _5!, amount: _6!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputStorePaymentGiftPremium(_ reader: BufferReader) -> InputStorePaymentPurpose? {
            var _1: Api.InputUser?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.InputUser
            }
            var _2: String?
            _2 = parseString(reader)
            var _3: Int64?
            _3 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.InputStorePaymentPurpose.inputStorePaymentGiftPremium(Cons_inputStorePaymentGiftPremium(userId: _1!, currency: _2!, amount: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputStorePaymentPremiumGiftCode(_ reader: BufferReader) -> InputStorePaymentPurpose? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.InputUser]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.InputUser.self)
            }
            var _3: Api.InputPeer?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                if let signature = reader.readInt32() {
                    _3 = Api.parse(reader, signature: signature) as? Api.InputPeer
                }
            }
            var _4: String?
            _4 = parseString(reader)
            var _5: Int64?
            _5 = reader.readInt64()
            var _6: Api.TextWithEntities?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let signature = reader.readInt32() {
                    _6 = Api.parse(reader, signature: signature) as? Api.TextWithEntities
                }
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.InputStorePaymentPurpose.inputStorePaymentPremiumGiftCode(Cons_inputStorePaymentPremiumGiftCode(flags: _1!, users: _2!, boostPeer: _3, currency: _4!, amount: _5!, message: _6))
            }
            else {
                return nil
            }
        }
        public static func parse_inputStorePaymentPremiumGiveaway(_ reader: BufferReader) -> InputStorePaymentPurpose? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.InputPeer?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.InputPeer
            }
            var _3: [Api.InputPeer]?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let _ = reader.readInt32() {
                    _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.InputPeer.self)
                }
            }
            var _4: [String]?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                if let _ = reader.readInt32() {
                    _4 = Api.parseVector(reader, elementSignature: -1255641564, elementType: String.self)
                }
            }
            var _5: String?
            if Int(_1 ?? 0) & Int(1 << 4) != 0 {
                _5 = parseString(reader)
            }
            var _6: Int64?
            _6 = reader.readInt64()
            var _7: Int32?
            _7 = reader.readInt32()
            var _8: String?
            _8 = parseString(reader)
            var _9: Int64?
            _9 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 4) == 0) || _5 != nil
            let _c6 = _6 != nil
            let _c7 = _7 != nil
            let _c8 = _8 != nil
            let _c9 = _9 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 && _c9 {
                return Api.InputStorePaymentPurpose.inputStorePaymentPremiumGiveaway(Cons_inputStorePaymentPremiumGiveaway(flags: _1!, boostPeer: _2!, additionalPeers: _3, countriesIso2: _4, prizeDescription: _5, randomId: _6!, untilDate: _7!, currency: _8!, amount: _9!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputStorePaymentPremiumSubscription(_ reader: BufferReader) -> InputStorePaymentPurpose? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.InputStorePaymentPurpose.inputStorePaymentPremiumSubscription(Cons_inputStorePaymentPremiumSubscription(flags: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputStorePaymentStarsGift(_ reader: BufferReader) -> InputStorePaymentPurpose? {
            var _1: Api.InputUser?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.InputUser
            }
            var _2: Int64?
            _2 = reader.readInt64()
            var _3: String?
            _3 = parseString(reader)
            var _4: Int64?
            _4 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.InputStorePaymentPurpose.inputStorePaymentStarsGift(Cons_inputStorePaymentStarsGift(userId: _1!, stars: _2!, currency: _3!, amount: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputStorePaymentStarsGiveaway(_ reader: BufferReader) -> InputStorePaymentPurpose? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int64?
            _2 = reader.readInt64()
            var _3: Api.InputPeer?
            if let signature = reader.readInt32() {
                _3 = Api.parse(reader, signature: signature) as? Api.InputPeer
            }
            var _4: [Api.InputPeer]?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let _ = reader.readInt32() {
                    _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.InputPeer.self)
                }
            }
            var _5: [String]?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                if let _ = reader.readInt32() {
                    _5 = Api.parseVector(reader, elementSignature: -1255641564, elementType: String.self)
                }
            }
            var _6: String?
            if Int(_1 ?? 0) & Int(1 << 4) != 0 {
                _6 = parseString(reader)
            }
            var _7: Int64?
            _7 = reader.readInt64()
            var _8: Int32?
            _8 = reader.readInt32()
            var _9: String?
            _9 = parseString(reader)
            var _10: Int64?
            _10 = reader.readInt64()
            var _11: Int32?
            _11 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _5 != nil
            let _c6 = (Int(_1 ?? 0) & Int(1 << 4) == 0) || _6 != nil
            let _c7 = _7 != nil
            let _c8 = _8 != nil
            let _c9 = _9 != nil
            let _c10 = _10 != nil
            let _c11 = _11 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 && _c9 && _c10 && _c11 {
                return Api.InputStorePaymentPurpose.inputStorePaymentStarsGiveaway(Cons_inputStorePaymentStarsGiveaway(flags: _1!, stars: _2!, boostPeer: _3!, additionalPeers: _4, countriesIso2: _5, prizeDescription: _6, randomId: _7!, untilDate: _8!, currency: _9!, amount: _10!, users: _11!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputStorePaymentStarsTopup(_ reader: BufferReader) -> InputStorePaymentPurpose? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int64?
            _2 = reader.readInt64()
            var _3: String?
            _3 = parseString(reader)
            var _4: Int64?
            _4 = reader.readInt64()
            var _5: Api.InputPeer?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                if let signature = reader.readInt32() {
                    _5 = Api.parse(reader, signature: signature) as? Api.InputPeer
                }
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.InputStorePaymentPurpose.inputStorePaymentStarsTopup(Cons_inputStorePaymentStarsTopup(flags: _1!, stars: _2!, currency: _3!, amount: _4!, spendPurposePeer: _5))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum InputTheme: TypeConstructorDescription {
        public class Cons_inputTheme: TypeConstructorDescription {
            public var id: Int64
            public var accessHash: Int64
            public init(id: Int64, accessHash: Int64) {
                self.id = id
                self.accessHash = accessHash
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputTheme", [("id", ConstructorParameterDescription(self.id)), ("accessHash", ConstructorParameterDescription(self.accessHash))])
            }
        }
        public class Cons_inputThemeSlug: TypeConstructorDescription {
            public var slug: String
            public init(slug: String) {
                self.slug = slug
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputThemeSlug", [("slug", ConstructorParameterDescription(self.slug))])
            }
        }
        case inputTheme(Cons_inputTheme)
        case inputThemeSlug(Cons_inputThemeSlug)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .inputTheme(let _data):
                if boxed {
                    buffer.appendInt32(1012306921)
                }
                serializeInt64(_data.id, buffer: buffer, boxed: false)
                serializeInt64(_data.accessHash, buffer: buffer, boxed: false)
                break
            case .inputThemeSlug(let _data):
                if boxed {
                    buffer.appendInt32(-175567375)
                }
                serializeString(_data.slug, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .inputTheme(let _data):
                return ("inputTheme", [("id", ConstructorParameterDescription(_data.id)), ("accessHash", ConstructorParameterDescription(_data.accessHash))])
            case .inputThemeSlug(let _data):
                return ("inputThemeSlug", [("slug", ConstructorParameterDescription(_data.slug))])
            }
        }

        public static func parse_inputTheme(_ reader: BufferReader) -> InputTheme? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: Int64?
            _2 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.InputTheme.inputTheme(Cons_inputTheme(id: _1!, accessHash: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputThemeSlug(_ reader: BufferReader) -> InputTheme? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.InputTheme.inputThemeSlug(Cons_inputThemeSlug(slug: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum InputThemeSettings: TypeConstructorDescription {
        public class Cons_inputThemeSettings: TypeConstructorDescription {
            public var flags: Int32
            public var baseTheme: Api.BaseTheme
            public var accentColor: Int32
            public var outboxAccentColor: Int32?
            public var messageColors: [Int32]?
            public var wallpaper: Api.InputWallPaper?
            public var wallpaperSettings: Api.WallPaperSettings?
            public init(flags: Int32, baseTheme: Api.BaseTheme, accentColor: Int32, outboxAccentColor: Int32?, messageColors: [Int32]?, wallpaper: Api.InputWallPaper?, wallpaperSettings: Api.WallPaperSettings?) {
                self.flags = flags
                self.baseTheme = baseTheme
                self.accentColor = accentColor
                self.outboxAccentColor = outboxAccentColor
                self.messageColors = messageColors
                self.wallpaper = wallpaper
                self.wallpaperSettings = wallpaperSettings
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputThemeSettings", [("flags", ConstructorParameterDescription(self.flags)), ("baseTheme", ConstructorParameterDescription(self.baseTheme)), ("accentColor", ConstructorParameterDescription(self.accentColor)), ("outboxAccentColor", ConstructorParameterDescription(self.outboxAccentColor)), ("messageColors", ConstructorParameterDescription(self.messageColors)), ("wallpaper", ConstructorParameterDescription(self.wallpaper)), ("wallpaperSettings", ConstructorParameterDescription(self.wallpaperSettings))])
            }
        }
        case inputThemeSettings(Cons_inputThemeSettings)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .inputThemeSettings(let _data):
                if boxed {
                    buffer.appendInt32(-1881255857)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                _data.baseTheme.serialize(buffer, true)
                serializeInt32(_data.accentColor, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 3) != 0 {
                    serializeInt32(_data.outboxAccentColor!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.messageColors!.count))
                    for item in _data.messageColors! {
                        serializeInt32(item, buffer: buffer, boxed: false)
                    }
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    _data.wallpaper!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    _data.wallpaperSettings!.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .inputThemeSettings(let _data):
                return ("inputThemeSettings", [("flags", ConstructorParameterDescription(_data.flags)), ("baseTheme", ConstructorParameterDescription(_data.baseTheme)), ("accentColor", ConstructorParameterDescription(_data.accentColor)), ("outboxAccentColor", ConstructorParameterDescription(_data.outboxAccentColor)), ("messageColors", ConstructorParameterDescription(_data.messageColors)), ("wallpaper", ConstructorParameterDescription(_data.wallpaper)), ("wallpaperSettings", ConstructorParameterDescription(_data.wallpaperSettings))])
            }
        }

        public static func parse_inputThemeSettings(_ reader: BufferReader) -> InputThemeSettings? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.BaseTheme?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.BaseTheme
            }
            var _3: Int32?
            _3 = reader.readInt32()
            var _4: Int32?
            if Int(_1 ?? 0) & Int(1 << 3) != 0 {
                _4 = reader.readInt32()
            }
            var _5: [Int32]?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                if let _ = reader.readInt32() {
                    _5 = Api.parseVector(reader, elementSignature: -1471112230, elementType: Int32.self)
                }
            }
            var _6: Api.InputWallPaper?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let signature = reader.readInt32() {
                    _6 = Api.parse(reader, signature: signature) as? Api.InputWallPaper
                }
            }
            var _7: Api.WallPaperSettings?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let signature = reader.readInt32() {
                    _7 = Api.parse(reader, signature: signature) as? Api.WallPaperSettings
                }
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 3) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _5 != nil
            let _c6 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _6 != nil
            let _c7 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _7 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 {
                return Api.InputThemeSettings.inputThemeSettings(Cons_inputThemeSettings(flags: _1!, baseTheme: _2!, accentColor: _3!, outboxAccentColor: _4, messageColors: _5, wallpaper: _6, wallpaperSettings: _7))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    indirect enum InputUser: TypeConstructorDescription {
        public class Cons_inputUser: TypeConstructorDescription {
            public var userId: Int64
            public var accessHash: Int64
            public init(userId: Int64, accessHash: Int64) {
                self.userId = userId
                self.accessHash = accessHash
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputUser", [("userId", ConstructorParameterDescription(self.userId)), ("accessHash", ConstructorParameterDescription(self.accessHash))])
            }
        }
        public class Cons_inputUserFromMessage: TypeConstructorDescription {
            public var peer: Api.InputPeer
            public var msgId: Int32
            public var userId: Int64
            public init(peer: Api.InputPeer, msgId: Int32, userId: Int64) {
                self.peer = peer
                self.msgId = msgId
                self.userId = userId
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputUserFromMessage", [("peer", ConstructorParameterDescription(self.peer)), ("msgId", ConstructorParameterDescription(self.msgId)), ("userId", ConstructorParameterDescription(self.userId))])
            }
        }
        case inputUser(Cons_inputUser)
        case inputUserEmpty
        case inputUserFromMessage(Cons_inputUserFromMessage)
        case inputUserSelf

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .inputUser(let _data):
                if boxed {
                    buffer.appendInt32(-233744186)
                }
                serializeInt64(_data.userId, buffer: buffer, boxed: false)
                serializeInt64(_data.accessHash, buffer: buffer, boxed: false)
                break
            case .inputUserEmpty:
                if boxed {
                    buffer.appendInt32(-1182234929)
                }
                break
            case .inputUserFromMessage(let _data):
                if boxed {
                    buffer.appendInt32(497305826)
                }
                _data.peer.serialize(buffer, true)
                serializeInt32(_data.msgId, buffer: buffer, boxed: false)
                serializeInt64(_data.userId, buffer: buffer, boxed: false)
                break
            case .inputUserSelf:
                if boxed {
                    buffer.appendInt32(-138301121)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .inputUser(let _data):
                return ("inputUser", [("userId", ConstructorParameterDescription(_data.userId)), ("accessHash", ConstructorParameterDescription(_data.accessHash))])
            case .inputUserEmpty:
                return ("inputUserEmpty", [])
            case .inputUserFromMessage(let _data):
                return ("inputUserFromMessage", [("peer", ConstructorParameterDescription(_data.peer)), ("msgId", ConstructorParameterDescription(_data.msgId)), ("userId", ConstructorParameterDescription(_data.userId))])
            case .inputUserSelf:
                return ("inputUserSelf", [])
            }
        }

        public static func parse_inputUser(_ reader: BufferReader) -> InputUser? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: Int64?
            _2 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.InputUser.inputUser(Cons_inputUser(userId: _1!, accessHash: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputUserEmpty(_ reader: BufferReader) -> InputUser? {
            return Api.InputUser.inputUserEmpty
        }
        public static func parse_inputUserFromMessage(_ reader: BufferReader) -> InputUser? {
            var _1: Api.InputPeer?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.InputPeer
            }
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int64?
            _3 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.InputUser.inputUserFromMessage(Cons_inputUserFromMessage(peer: _1!, msgId: _2!, userId: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputUserSelf(_ reader: BufferReader) -> InputUser? {
            return Api.InputUser.inputUserSelf
        }
    }
}
public extension Api {
    enum InputWallPaper: TypeConstructorDescription {
        public class Cons_inputWallPaper: TypeConstructorDescription {
            public var id: Int64
            public var accessHash: Int64
            public init(id: Int64, accessHash: Int64) {
                self.id = id
                self.accessHash = accessHash
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputWallPaper", [("id", ConstructorParameterDescription(self.id)), ("accessHash", ConstructorParameterDescription(self.accessHash))])
            }
        }
        public class Cons_inputWallPaperNoFile: TypeConstructorDescription {
            public var id: Int64
            public init(id: Int64) {
                self.id = id
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputWallPaperNoFile", [("id", ConstructorParameterDescription(self.id))])
            }
        }
        public class Cons_inputWallPaperSlug: TypeConstructorDescription {
            public var slug: String
            public init(slug: String) {
                self.slug = slug
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputWallPaperSlug", [("slug", ConstructorParameterDescription(self.slug))])
            }
        }
        case inputWallPaper(Cons_inputWallPaper)
        case inputWallPaperNoFile(Cons_inputWallPaperNoFile)
        case inputWallPaperSlug(Cons_inputWallPaperSlug)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .inputWallPaper(let _data):
                if boxed {
                    buffer.appendInt32(-433014407)
                }
                serializeInt64(_data.id, buffer: buffer, boxed: false)
                serializeInt64(_data.accessHash, buffer: buffer, boxed: false)
                break
            case .inputWallPaperNoFile(let _data):
                if boxed {
                    buffer.appendInt32(-1770371538)
                }
                serializeInt64(_data.id, buffer: buffer, boxed: false)
                break
            case .inputWallPaperSlug(let _data):
                if boxed {
                    buffer.appendInt32(1913199744)
                }
                serializeString(_data.slug, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .inputWallPaper(let _data):
                return ("inputWallPaper", [("id", ConstructorParameterDescription(_data.id)), ("accessHash", ConstructorParameterDescription(_data.accessHash))])
            case .inputWallPaperNoFile(let _data):
                return ("inputWallPaperNoFile", [("id", ConstructorParameterDescription(_data.id))])
            case .inputWallPaperSlug(let _data):
                return ("inputWallPaperSlug", [("slug", ConstructorParameterDescription(_data.slug))])
            }
        }

        public static func parse_inputWallPaper(_ reader: BufferReader) -> InputWallPaper? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: Int64?
            _2 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.InputWallPaper.inputWallPaper(Cons_inputWallPaper(id: _1!, accessHash: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputWallPaperNoFile(_ reader: BufferReader) -> InputWallPaper? {
            var _1: Int64?
            _1 = reader.readInt64()
            let _c1 = _1 != nil
            if _c1 {
                return Api.InputWallPaper.inputWallPaperNoFile(Cons_inputWallPaperNoFile(id: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputWallPaperSlug(_ reader: BufferReader) -> InputWallPaper? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.InputWallPaper.inputWallPaperSlug(Cons_inputWallPaperSlug(slug: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum InputWebDocument: TypeConstructorDescription {
        public class Cons_inputWebDocument: TypeConstructorDescription {
            public var url: String
            public var size: Int32
            public var mimeType: String
            public var attributes: [Api.DocumentAttribute]
            public init(url: String, size: Int32, mimeType: String, attributes: [Api.DocumentAttribute]) {
                self.url = url
                self.size = size
                self.mimeType = mimeType
                self.attributes = attributes
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputWebDocument", [("url", ConstructorParameterDescription(self.url)), ("size", ConstructorParameterDescription(self.size)), ("mimeType", ConstructorParameterDescription(self.mimeType)), ("attributes", ConstructorParameterDescription(self.attributes))])
            }
        }
        case inputWebDocument(Cons_inputWebDocument)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .inputWebDocument(let _data):
                if boxed {
                    buffer.appendInt32(-1678949555)
                }
                serializeString(_data.url, buffer: buffer, boxed: false)
                serializeInt32(_data.size, buffer: buffer, boxed: false)
                serializeString(_data.mimeType, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.attributes.count))
                for item in _data.attributes {
                    item.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .inputWebDocument(let _data):
                return ("inputWebDocument", [("url", ConstructorParameterDescription(_data.url)), ("size", ConstructorParameterDescription(_data.size)), ("mimeType", ConstructorParameterDescription(_data.mimeType)), ("attributes", ConstructorParameterDescription(_data.attributes))])
            }
        }

        public static func parse_inputWebDocument(_ reader: BufferReader) -> InputWebDocument? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: String?
            _3 = parseString(reader)
            var _4: [Api.DocumentAttribute]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.DocumentAttribute.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.InputWebDocument.inputWebDocument(Cons_inputWebDocument(url: _1!, size: _2!, mimeType: _3!, attributes: _4!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum InputWebFileLocation: TypeConstructorDescription {
        public class Cons_inputWebFileAudioAlbumThumbLocation: TypeConstructorDescription {
            public var flags: Int32
            public var document: Api.InputDocument?
            public var title: String?
            public var performer: String?
            public init(flags: Int32, document: Api.InputDocument?, title: String?, performer: String?) {
                self.flags = flags
                self.document = document
                self.title = title
                self.performer = performer
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputWebFileAudioAlbumThumbLocation", [("flags", ConstructorParameterDescription(self.flags)), ("document", ConstructorParameterDescription(self.document)), ("title", ConstructorParameterDescription(self.title)), ("performer", ConstructorParameterDescription(self.performer))])
            }
        }
        public class Cons_inputWebFileGeoPointLocation: TypeConstructorDescription {
            public var geoPoint: Api.InputGeoPoint
            public var accessHash: Int64
            public var w: Int32
            public var h: Int32
            public var zoom: Int32
            public var scale: Int32
            public init(geoPoint: Api.InputGeoPoint, accessHash: Int64, w: Int32, h: Int32, zoom: Int32, scale: Int32) {
                self.geoPoint = geoPoint
                self.accessHash = accessHash
                self.w = w
                self.h = h
                self.zoom = zoom
                self.scale = scale
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputWebFileGeoPointLocation", [("geoPoint", ConstructorParameterDescription(self.geoPoint)), ("accessHash", ConstructorParameterDescription(self.accessHash)), ("w", ConstructorParameterDescription(self.w)), ("h", ConstructorParameterDescription(self.h)), ("zoom", ConstructorParameterDescription(self.zoom)), ("scale", ConstructorParameterDescription(self.scale))])
            }
        }
        public class Cons_inputWebFileLocation: TypeConstructorDescription {
            public var url: String
            public var accessHash: Int64
            public init(url: String, accessHash: Int64) {
                self.url = url
                self.accessHash = accessHash
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inputWebFileLocation", [("url", ConstructorParameterDescription(self.url)), ("accessHash", ConstructorParameterDescription(self.accessHash))])
            }
        }
        case inputWebFileAudioAlbumThumbLocation(Cons_inputWebFileAudioAlbumThumbLocation)
        case inputWebFileGeoPointLocation(Cons_inputWebFileGeoPointLocation)
        case inputWebFileLocation(Cons_inputWebFileLocation)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .inputWebFileAudioAlbumThumbLocation(let _data):
                if boxed {
                    buffer.appendInt32(-193992412)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    _data.document!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeString(_data.title!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeString(_data.performer!, buffer: buffer, boxed: false)
                }
                break
            case .inputWebFileGeoPointLocation(let _data):
                if boxed {
                    buffer.appendInt32(-1625153079)
                }
                _data.geoPoint.serialize(buffer, true)
                serializeInt64(_data.accessHash, buffer: buffer, boxed: false)
                serializeInt32(_data.w, buffer: buffer, boxed: false)
                serializeInt32(_data.h, buffer: buffer, boxed: false)
                serializeInt32(_data.zoom, buffer: buffer, boxed: false)
                serializeInt32(_data.scale, buffer: buffer, boxed: false)
                break
            case .inputWebFileLocation(let _data):
                if boxed {
                    buffer.appendInt32(-1036396922)
                }
                serializeString(_data.url, buffer: buffer, boxed: false)
                serializeInt64(_data.accessHash, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .inputWebFileAudioAlbumThumbLocation(let _data):
                return ("inputWebFileAudioAlbumThumbLocation", [("flags", ConstructorParameterDescription(_data.flags)), ("document", ConstructorParameterDescription(_data.document)), ("title", ConstructorParameterDescription(_data.title)), ("performer", ConstructorParameterDescription(_data.performer))])
            case .inputWebFileGeoPointLocation(let _data):
                return ("inputWebFileGeoPointLocation", [("geoPoint", ConstructorParameterDescription(_data.geoPoint)), ("accessHash", ConstructorParameterDescription(_data.accessHash)), ("w", ConstructorParameterDescription(_data.w)), ("h", ConstructorParameterDescription(_data.h)), ("zoom", ConstructorParameterDescription(_data.zoom)), ("scale", ConstructorParameterDescription(_data.scale))])
            case .inputWebFileLocation(let _data):
                return ("inputWebFileLocation", [("url", ConstructorParameterDescription(_data.url)), ("accessHash", ConstructorParameterDescription(_data.accessHash))])
            }
        }

        public static func parse_inputWebFileAudioAlbumThumbLocation(_ reader: BufferReader) -> InputWebFileLocation? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.InputDocument?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                if let signature = reader.readInt32() {
                    _2 = Api.parse(reader, signature: signature) as? Api.InputDocument
                }
            }
            var _3: String?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _3 = parseString(reader)
            }
            var _4: String?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _4 = parseString(reader)
            }
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.InputWebFileLocation.inputWebFileAudioAlbumThumbLocation(Cons_inputWebFileAudioAlbumThumbLocation(flags: _1!, document: _2, title: _3, performer: _4))
            }
            else {
                return nil
            }
        }
        public static func parse_inputWebFileGeoPointLocation(_ reader: BufferReader) -> InputWebFileLocation? {
            var _1: Api.InputGeoPoint?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.InputGeoPoint
            }
            var _2: Int64?
            _2 = reader.readInt64()
            var _3: Int32?
            _3 = reader.readInt32()
            var _4: Int32?
            _4 = reader.readInt32()
            var _5: Int32?
            _5 = reader.readInt32()
            var _6: Int32?
            _6 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.InputWebFileLocation.inputWebFileGeoPointLocation(Cons_inputWebFileGeoPointLocation(geoPoint: _1!, accessHash: _2!, w: _3!, h: _4!, zoom: _5!, scale: _6!))
            }
            else {
                return nil
            }
        }
        public static func parse_inputWebFileLocation(_ reader: BufferReader) -> InputWebFileLocation? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int64?
            _2 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.InputWebFileLocation.inputWebFileLocation(Cons_inputWebFileLocation(url: _1!, accessHash: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum Invoice: TypeConstructorDescription {
        public class Cons_invoice: TypeConstructorDescription {
            public var flags: Int32
            public var currency: String
            public var prices: [Api.LabeledPrice]
            public var maxTipAmount: Int64?
            public var suggestedTipAmounts: [Int64]?
            public var termsUrl: String?
            public var subscriptionPeriod: Int32?
            public init(flags: Int32, currency: String, prices: [Api.LabeledPrice], maxTipAmount: Int64?, suggestedTipAmounts: [Int64]?, termsUrl: String?, subscriptionPeriod: Int32?) {
                self.flags = flags
                self.currency = currency
                self.prices = prices
                self.maxTipAmount = maxTipAmount
                self.suggestedTipAmounts = suggestedTipAmounts
                self.termsUrl = termsUrl
                self.subscriptionPeriod = subscriptionPeriod
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("invoice", [("flags", ConstructorParameterDescription(self.flags)), ("currency", ConstructorParameterDescription(self.currency)), ("prices", ConstructorParameterDescription(self.prices)), ("maxTipAmount", ConstructorParameterDescription(self.maxTipAmount)), ("suggestedTipAmounts", ConstructorParameterDescription(self.suggestedTipAmounts)), ("termsUrl", ConstructorParameterDescription(self.termsUrl)), ("subscriptionPeriod", ConstructorParameterDescription(self.subscriptionPeriod))])
            }
        }
        case invoice(Cons_invoice)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .invoice(let _data):
                if boxed {
                    buffer.appendInt32(77522308)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeString(_data.currency, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.prices.count))
                for item in _data.prices {
                    item.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 8) != 0 {
                    serializeInt64(_data.maxTipAmount!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 8) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.suggestedTipAmounts!.count))
                    for item in _data.suggestedTipAmounts! {
                        serializeInt64(item, buffer: buffer, boxed: false)
                    }
                }
                if Int(_data.flags) & Int(1 << 10) != 0 {
                    serializeString(_data.termsUrl!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 11) != 0 {
                    serializeInt32(_data.subscriptionPeriod!, buffer: buffer, boxed: false)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .invoice(let _data):
                return ("invoice", [("flags", ConstructorParameterDescription(_data.flags)), ("currency", ConstructorParameterDescription(_data.currency)), ("prices", ConstructorParameterDescription(_data.prices)), ("maxTipAmount", ConstructorParameterDescription(_data.maxTipAmount)), ("suggestedTipAmounts", ConstructorParameterDescription(_data.suggestedTipAmounts)), ("termsUrl", ConstructorParameterDescription(_data.termsUrl)), ("subscriptionPeriod", ConstructorParameterDescription(_data.subscriptionPeriod))])
            }
        }

        public static func parse_invoice(_ reader: BufferReader) -> Invoice? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: [Api.LabeledPrice]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.LabeledPrice.self)
            }
            var _4: Int64?
            if Int(_1 ?? 0) & Int(1 << 8) != 0 {
                _4 = reader.readInt64()
            }
            var _5: [Int64]?
            if Int(_1 ?? 0) & Int(1 << 8) != 0 {
                if let _ = reader.readInt32() {
                    _5 = Api.parseVector(reader, elementSignature: 570911930, elementType: Int64.self)
                }
            }
            var _6: String?
            if Int(_1 ?? 0) & Int(1 << 10) != 0 {
                _6 = parseString(reader)
            }
            var _7: Int32?
            if Int(_1 ?? 0) & Int(1 << 11) != 0 {
                _7 = reader.readInt32()
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 8) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 8) == 0) || _5 != nil
            let _c6 = (Int(_1 ?? 0) & Int(1 << 10) == 0) || _6 != nil
            let _c7 = (Int(_1 ?? 0) & Int(1 << 11) == 0) || _7 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 {
                return Api.Invoice.invoice(Cons_invoice(flags: _1!, currency: _2!, prices: _3!, maxTipAmount: _4, suggestedTipAmounts: _5, termsUrl: _6, subscriptionPeriod: _7))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum JSONObjectValue: TypeConstructorDescription {
        public class Cons_jsonObjectValue: TypeConstructorDescription {
            public var key: String
            public var value: Api.JSONValue
            public init(key: String, value: Api.JSONValue) {
                self.key = key
                self.value = value
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("jsonObjectValue", [("key", ConstructorParameterDescription(self.key)), ("value", ConstructorParameterDescription(self.value))])
            }
        }
        case jsonObjectValue(Cons_jsonObjectValue)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .jsonObjectValue(let _data):
                if boxed {
                    buffer.appendInt32(-1059185703)
                }
                serializeString(_data.key, buffer: buffer, boxed: false)
                _data.value.serialize(buffer, true)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .jsonObjectValue(let _data):
                return ("jsonObjectValue", [("key", ConstructorParameterDescription(_data.key)), ("value", ConstructorParameterDescription(_data.value))])
            }
        }

        public static func parse_jsonObjectValue(_ reader: BufferReader) -> JSONObjectValue? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Api.JSONValue?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.JSONValue
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.JSONObjectValue.jsonObjectValue(Cons_jsonObjectValue(key: _1!, value: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum JSONValue: TypeConstructorDescription {
        public class Cons_jsonArray: TypeConstructorDescription {
            public var value: [Api.JSONValue]
            public init(value: [Api.JSONValue]) {
                self.value = value
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("jsonArray", [("value", ConstructorParameterDescription(self.value))])
            }
        }
        public class Cons_jsonBool: TypeConstructorDescription {
            public var value: Api.Bool
            public init(value: Api.Bool) {
                self.value = value
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("jsonBool", [("value", ConstructorParameterDescription(self.value))])
            }
        }
        public class Cons_jsonNumber: TypeConstructorDescription {
            public var value: Double
            public init(value: Double) {
                self.value = value
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("jsonNumber", [("value", ConstructorParameterDescription(self.value))])
            }
        }
        public class Cons_jsonObject: TypeConstructorDescription {
            public var value: [Api.JSONObjectValue]
            public init(value: [Api.JSONObjectValue]) {
                self.value = value
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("jsonObject", [("value", ConstructorParameterDescription(self.value))])
            }
        }
        public class Cons_jsonString: TypeConstructorDescription {
            public var value: String
            public init(value: String) {
                self.value = value
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("jsonString", [("value", ConstructorParameterDescription(self.value))])
            }
        }
        case jsonArray(Cons_jsonArray)
        case jsonBool(Cons_jsonBool)
        case jsonNull
        case jsonNumber(Cons_jsonNumber)
        case jsonObject(Cons_jsonObject)
        case jsonString(Cons_jsonString)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .jsonArray(let _data):
                if boxed {
                    buffer.appendInt32(-146520221)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.value.count))
                for item in _data.value {
                    item.serialize(buffer, true)
                }
                break
            case .jsonBool(let _data):
                if boxed {
                    buffer.appendInt32(-952869270)
                }
                _data.value.serialize(buffer, true)
                break
            case .jsonNull:
                if boxed {
                    buffer.appendInt32(1064139624)
                }
                break
            case .jsonNumber(let _data):
                if boxed {
                    buffer.appendInt32(736157604)
                }
                serializeDouble(_data.value, buffer: buffer, boxed: false)
                break
            case .jsonObject(let _data):
                if boxed {
                    buffer.appendInt32(-1715350371)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.value.count))
                for item in _data.value {
                    item.serialize(buffer, true)
                }
                break
            case .jsonString(let _data):
                if boxed {
                    buffer.appendInt32(-1222740358)
                }
                serializeString(_data.value, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .jsonArray(let _data):
                return ("jsonArray", [("value", ConstructorParameterDescription(_data.value))])
            case .jsonBool(let _data):
                return ("jsonBool", [("value", ConstructorParameterDescription(_data.value))])
            case .jsonNull:
                return ("jsonNull", [])
            case .jsonNumber(let _data):
                return ("jsonNumber", [("value", ConstructorParameterDescription(_data.value))])
            case .jsonObject(let _data):
                return ("jsonObject", [("value", ConstructorParameterDescription(_data.value))])
            case .jsonString(let _data):
                return ("jsonString", [("value", ConstructorParameterDescription(_data.value))])
            }
        }

        public static func parse_jsonArray(_ reader: BufferReader) -> JSONValue? {
            var _1: [Api.JSONValue]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.JSONValue.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.JSONValue.jsonArray(Cons_jsonArray(value: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_jsonBool(_ reader: BufferReader) -> JSONValue? {
            var _1: Api.Bool?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.Bool
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.JSONValue.jsonBool(Cons_jsonBool(value: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_jsonNull(_ reader: BufferReader) -> JSONValue? {
            return Api.JSONValue.jsonNull
        }
        public static func parse_jsonNumber(_ reader: BufferReader) -> JSONValue? {
            var _1: Double?
            _1 = reader.readDouble()
            let _c1 = _1 != nil
            if _c1 {
                return Api.JSONValue.jsonNumber(Cons_jsonNumber(value: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_jsonObject(_ reader: BufferReader) -> JSONValue? {
            var _1: [Api.JSONObjectValue]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.JSONObjectValue.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.JSONValue.jsonObject(Cons_jsonObject(value: _1!))
            }
            else {
                return nil
            }
        }
        public static func parse_jsonString(_ reader: BufferReader) -> JSONValue? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.JSONValue.jsonString(Cons_jsonString(value: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api {
    enum JoinChatBotResult: TypeConstructorDescription {
        public class Cons_joinChatBotResultWebView: TypeConstructorDescription {
            public var url: String
            public init(url: String) {
                self.url = url
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("joinChatBotResultWebView", [("url", ConstructorParameterDescription(self.url))])
            }
        }
        case joinChatBotResultApproved
        case joinChatBotResultDeclined
        case joinChatBotResultQueued
        case joinChatBotResultWebView(Cons_joinChatBotResultWebView)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .joinChatBotResultApproved:
                if boxed {
                    buffer.appendInt32(-1374344599)
                }
                break
            case .joinChatBotResultDeclined:
                if boxed {
                    buffer.appendInt32(251265428)
                }
                break
            case .joinChatBotResultQueued:
                if boxed {
                    buffer.appendInt32(-1734105024)
                }
                break
            case .joinChatBotResultWebView(let _data):
                if boxed {
                    buffer.appendInt32(-689719277)
                }
                serializeString(_data.url, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .joinChatBotResultApproved:
                return ("joinChatBotResultApproved", [])
            case .joinChatBotResultDeclined:
                return ("joinChatBotResultDeclined", [])
            case .joinChatBotResultQueued:
                return ("joinChatBotResultQueued", [])
            case .joinChatBotResultWebView(let _data):
                return ("joinChatBotResultWebView", [("url", ConstructorParameterDescription(_data.url))])
            }
        }

        public static func parse_joinChatBotResultApproved(_ reader: BufferReader) -> JoinChatBotResult? {
            return Api.JoinChatBotResult.joinChatBotResultApproved
        }
        public static func parse_joinChatBotResultDeclined(_ reader: BufferReader) -> JoinChatBotResult? {
            return Api.JoinChatBotResult.joinChatBotResultDeclined
        }
        public static func parse_joinChatBotResultQueued(_ reader: BufferReader) -> JoinChatBotResult? {
            return Api.JoinChatBotResult.joinChatBotResultQueued
        }
        public static func parse_joinChatBotResultWebView(_ reader: BufferReader) -> JoinChatBotResult? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.JoinChatBotResult.joinChatBotResultWebView(Cons_joinChatBotResultWebView(url: _1!))
            }
            else {
                return nil
            }
        }
    }
}
