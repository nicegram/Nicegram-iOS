public extension Api.help {
    enum PeerColorOption: TypeConstructorDescription {
        public class Cons_peerColorOption: TypeConstructorDescription {
            public var flags: Int32
            public var colorId: Int32
            public var colors: Api.help.PeerColorSet?
            public var darkColors: Api.help.PeerColorSet?
            public var channelMinLevel: Int32?
            public var groupMinLevel: Int32?
            public init(flags: Int32, colorId: Int32, colors: Api.help.PeerColorSet?, darkColors: Api.help.PeerColorSet?, channelMinLevel: Int32?, groupMinLevel: Int32?) {
                self.flags = flags
                self.colorId = colorId
                self.colors = colors
                self.darkColors = darkColors
                self.channelMinLevel = channelMinLevel
                self.groupMinLevel = groupMinLevel
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("peerColorOption", [("flags", ConstructorParameterDescription(self.flags)), ("colorId", ConstructorParameterDescription(self.colorId)), ("colors", ConstructorParameterDescription(self.colors)), ("darkColors", ConstructorParameterDescription(self.darkColors)), ("channelMinLevel", ConstructorParameterDescription(self.channelMinLevel)), ("groupMinLevel", ConstructorParameterDescription(self.groupMinLevel))])
            }
        }
        case peerColorOption(Cons_peerColorOption)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .peerColorOption(let _data):
                if boxed {
                    buffer.appendInt32(-1377014082)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.colorId, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    _data.colors!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    _data.darkColors!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 3) != 0 {
                    serializeInt32(_data.channelMinLevel!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 4) != 0 {
                    serializeInt32(_data.groupMinLevel!, buffer: buffer, boxed: false)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .peerColorOption(let _data):
                return ("peerColorOption", [("flags", ConstructorParameterDescription(_data.flags)), ("colorId", ConstructorParameterDescription(_data.colorId)), ("colors", ConstructorParameterDescription(_data.colors)), ("darkColors", ConstructorParameterDescription(_data.darkColors)), ("channelMinLevel", ConstructorParameterDescription(_data.channelMinLevel)), ("groupMinLevel", ConstructorParameterDescription(_data.groupMinLevel))])
            }
        }

        public static func parse_peerColorOption(_ reader: BufferReader) -> PeerColorOption? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Api.help.PeerColorSet?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let signature = reader.readInt32() {
                    _3 = Api.parse(reader, signature: signature) as? Api.help.PeerColorSet
                }
            }
            var _4: Api.help.PeerColorSet?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                if let signature = reader.readInt32() {
                    _4 = Api.parse(reader, signature: signature) as? Api.help.PeerColorSet
                }
            }
            var _5: Int32?
            if Int(_1 ?? 0) & Int(1 << 3) != 0 {
                _5 = reader.readInt32()
            }
            var _6: Int32?
            if Int(_1 ?? 0) & Int(1 << 4) != 0 {
                _6 = reader.readInt32()
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 3) == 0) || _5 != nil
            let _c6 = (Int(_1 ?? 0) & Int(1 << 4) == 0) || _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.help.PeerColorOption.peerColorOption(Cons_peerColorOption(flags: _1!, colorId: _2!, colors: _3, darkColors: _4, channelMinLevel: _5, groupMinLevel: _6))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.help {
    enum PeerColorSet: TypeConstructorDescription {
        public class Cons_peerColorProfileSet: TypeConstructorDescription {
            public var paletteColors: [Int32]
            public var bgColors: [Int32]
            public var storyColors: [Int32]
            public init(paletteColors: [Int32], bgColors: [Int32], storyColors: [Int32]) {
                self.paletteColors = paletteColors
                self.bgColors = bgColors
                self.storyColors = storyColors
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("peerColorProfileSet", [("paletteColors", ConstructorParameterDescription(self.paletteColors)), ("bgColors", ConstructorParameterDescription(self.bgColors)), ("storyColors", ConstructorParameterDescription(self.storyColors))])
            }
        }
        public class Cons_peerColorSet: TypeConstructorDescription {
            public var colors: [Int32]
            public init(colors: [Int32]) {
                self.colors = colors
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("peerColorSet", [("colors", ConstructorParameterDescription(self.colors))])
            }
        }
        case peerColorProfileSet(Cons_peerColorProfileSet)
        case peerColorSet(Cons_peerColorSet)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .peerColorProfileSet(let _data):
                if boxed {
                    buffer.appendInt32(1987928555)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.paletteColors.count))
                for item in _data.paletteColors {
                    serializeInt32(item, buffer: buffer, boxed: false)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.bgColors.count))
                for item in _data.bgColors {
                    serializeInt32(item, buffer: buffer, boxed: false)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.storyColors.count))
                for item in _data.storyColors {
                    serializeInt32(item, buffer: buffer, boxed: false)
                }
                break
            case .peerColorSet(let _data):
                if boxed {
                    buffer.appendInt32(639736408)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.colors.count))
                for item in _data.colors {
                    serializeInt32(item, buffer: buffer, boxed: false)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .peerColorProfileSet(let _data):
                return ("peerColorProfileSet", [("paletteColors", ConstructorParameterDescription(_data.paletteColors)), ("bgColors", ConstructorParameterDescription(_data.bgColors)), ("storyColors", ConstructorParameterDescription(_data.storyColors))])
            case .peerColorSet(let _data):
                return ("peerColorSet", [("colors", ConstructorParameterDescription(_data.colors))])
            }
        }

        public static func parse_peerColorProfileSet(_ reader: BufferReader) -> PeerColorSet? {
            var _1: [Int32]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: -1471112230, elementType: Int32.self)
            }
            var _2: [Int32]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: -1471112230, elementType: Int32.self)
            }
            var _3: [Int32]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: -1471112230, elementType: Int32.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.help.PeerColorSet.peerColorProfileSet(Cons_peerColorProfileSet(paletteColors: _1!, bgColors: _2!, storyColors: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_peerColorSet(_ reader: BufferReader) -> PeerColorSet? {
            var _1: [Int32]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: -1471112230, elementType: Int32.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.help.PeerColorSet.peerColorSet(Cons_peerColorSet(colors: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.help {
    enum PeerColors: TypeConstructorDescription {
        public class Cons_peerColors: TypeConstructorDescription {
            public var hash: Int32
            public var colors: [Api.help.PeerColorOption]
            public init(hash: Int32, colors: [Api.help.PeerColorOption]) {
                self.hash = hash
                self.colors = colors
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("peerColors", [("hash", ConstructorParameterDescription(self.hash)), ("colors", ConstructorParameterDescription(self.colors))])
            }
        }
        case peerColors(Cons_peerColors)
        case peerColorsNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .peerColors(let _data):
                if boxed {
                    buffer.appendInt32(16313608)
                }
                serializeInt32(_data.hash, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.colors.count))
                for item in _data.colors {
                    item.serialize(buffer, true)
                }
                break
            case .peerColorsNotModified:
                if boxed {
                    buffer.appendInt32(732034510)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .peerColors(let _data):
                return ("peerColors", [("hash", ConstructorParameterDescription(_data.hash)), ("colors", ConstructorParameterDescription(_data.colors))])
            case .peerColorsNotModified:
                return ("peerColorsNotModified", [])
            }
        }

        public static func parse_peerColors(_ reader: BufferReader) -> PeerColors? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.help.PeerColorOption]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.help.PeerColorOption.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.help.PeerColors.peerColors(Cons_peerColors(hash: _1!, colors: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_peerColorsNotModified(_ reader: BufferReader) -> PeerColors? {
            return Api.help.PeerColors.peerColorsNotModified
        }
    }
}
public extension Api.help {
    enum PremiumPromo: TypeConstructorDescription {
        public class Cons_premiumPromo: TypeConstructorDescription {
            public var statusText: String
            public var statusEntities: [Api.MessageEntity]
            public var videoSections: [String]
            public var videos: [Api.Document]
            public var periodOptions: [Api.PremiumSubscriptionOption]
            public var users: [Api.User]
            public init(statusText: String, statusEntities: [Api.MessageEntity], videoSections: [String], videos: [Api.Document], periodOptions: [Api.PremiumSubscriptionOption], users: [Api.User]) {
                self.statusText = statusText
                self.statusEntities = statusEntities
                self.videoSections = videoSections
                self.videos = videos
                self.periodOptions = periodOptions
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("premiumPromo", [("statusText", ConstructorParameterDescription(self.statusText)), ("statusEntities", ConstructorParameterDescription(self.statusEntities)), ("videoSections", ConstructorParameterDescription(self.videoSections)), ("videos", ConstructorParameterDescription(self.videos)), ("periodOptions", ConstructorParameterDescription(self.periodOptions)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case premiumPromo(Cons_premiumPromo)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .premiumPromo(let _data):
                if boxed {
                    buffer.appendInt32(1395946908)
                }
                serializeString(_data.statusText, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.statusEntities.count))
                for item in _data.statusEntities {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.videoSections.count))
                for item in _data.videoSections {
                    serializeString(item, buffer: buffer, boxed: false)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.videos.count))
                for item in _data.videos {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.periodOptions.count))
                for item in _data.periodOptions {
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
            case .premiumPromo(let _data):
                return ("premiumPromo", [("statusText", ConstructorParameterDescription(_data.statusText)), ("statusEntities", ConstructorParameterDescription(_data.statusEntities)), ("videoSections", ConstructorParameterDescription(_data.videoSections)), ("videos", ConstructorParameterDescription(_data.videos)), ("periodOptions", ConstructorParameterDescription(_data.periodOptions)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_premiumPromo(_ reader: BufferReader) -> PremiumPromo? {
            var _1: String?
            _1 = parseString(reader)
            var _2: [Api.MessageEntity]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.MessageEntity.self)
            }
            var _3: [String]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: -1255641564, elementType: String.self)
            }
            var _4: [Api.Document]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Document.self)
            }
            var _5: [Api.PremiumSubscriptionOption]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.PremiumSubscriptionOption.self)
            }
            var _6: [Api.User]?
            if let _ = reader.readInt32() {
                _6 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.help.PremiumPromo.premiumPromo(Cons_premiumPromo(statusText: _1!, statusEntities: _2!, videoSections: _3!, videos: _4!, periodOptions: _5!, users: _6!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.help {
    enum PromoData: TypeConstructorDescription {
        public class Cons_promoData: TypeConstructorDescription {
            public var flags: Int32
            public var expires: Int32
            public var peer: Api.Peer?
            public var psaType: String?
            public var psaMessage: String?
            public var pendingSuggestions: [String]
            public var dismissedSuggestions: [String]
            public var customPendingSuggestion: Api.PendingSuggestion?
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(flags: Int32, expires: Int32, peer: Api.Peer?, psaType: String?, psaMessage: String?, pendingSuggestions: [String], dismissedSuggestions: [String], customPendingSuggestion: Api.PendingSuggestion?, chats: [Api.Chat], users: [Api.User]) {
                self.flags = flags
                self.expires = expires
                self.peer = peer
                self.psaType = psaType
                self.psaMessage = psaMessage
                self.pendingSuggestions = pendingSuggestions
                self.dismissedSuggestions = dismissedSuggestions
                self.customPendingSuggestion = customPendingSuggestion
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("promoData", [("flags", ConstructorParameterDescription(self.flags)), ("expires", ConstructorParameterDescription(self.expires)), ("peer", ConstructorParameterDescription(self.peer)), ("psaType", ConstructorParameterDescription(self.psaType)), ("psaMessage", ConstructorParameterDescription(self.psaMessage)), ("pendingSuggestions", ConstructorParameterDescription(self.pendingSuggestions)), ("dismissedSuggestions", ConstructorParameterDescription(self.dismissedSuggestions)), ("customPendingSuggestion", ConstructorParameterDescription(self.customPendingSuggestion)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        public class Cons_promoDataEmpty: TypeConstructorDescription {
            public var expires: Int32
            public init(expires: Int32) {
                self.expires = expires
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("promoDataEmpty", [("expires", ConstructorParameterDescription(self.expires))])
            }
        }
        case promoData(Cons_promoData)
        case promoDataEmpty(Cons_promoDataEmpty)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .promoData(let _data):
                if boxed {
                    buffer.appendInt32(145021050)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.expires, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 3) != 0 {
                    _data.peer!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeString(_data.psaType!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeString(_data.psaMessage!, buffer: buffer, boxed: false)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.pendingSuggestions.count))
                for item in _data.pendingSuggestions {
                    serializeString(item, buffer: buffer, boxed: false)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.dismissedSuggestions.count))
                for item in _data.dismissedSuggestions {
                    serializeString(item, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 4) != 0 {
                    _data.customPendingSuggestion!.serialize(buffer, true)
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
            case .promoDataEmpty(let _data):
                if boxed {
                    buffer.appendInt32(-1728664459)
                }
                serializeInt32(_data.expires, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .promoData(let _data):
                return ("promoData", [("flags", ConstructorParameterDescription(_data.flags)), ("expires", ConstructorParameterDescription(_data.expires)), ("peer", ConstructorParameterDescription(_data.peer)), ("psaType", ConstructorParameterDescription(_data.psaType)), ("psaMessage", ConstructorParameterDescription(_data.psaMessage)), ("pendingSuggestions", ConstructorParameterDescription(_data.pendingSuggestions)), ("dismissedSuggestions", ConstructorParameterDescription(_data.dismissedSuggestions)), ("customPendingSuggestion", ConstructorParameterDescription(_data.customPendingSuggestion)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            case .promoDataEmpty(let _data):
                return ("promoDataEmpty", [("expires", ConstructorParameterDescription(_data.expires))])
            }
        }

        public static func parse_promoData(_ reader: BufferReader) -> PromoData? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Api.Peer?
            if Int(_1 ?? 0) & Int(1 << 3) != 0 {
                if let signature = reader.readInt32() {
                    _3 = Api.parse(reader, signature: signature) as? Api.Peer
                }
            }
            var _4: String?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _4 = parseString(reader)
            }
            var _5: String?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _5 = parseString(reader)
            }
            var _6: [String]?
            if let _ = reader.readInt32() {
                _6 = Api.parseVector(reader, elementSignature: -1255641564, elementType: String.self)
            }
            var _7: [String]?
            if let _ = reader.readInt32() {
                _7 = Api.parseVector(reader, elementSignature: -1255641564, elementType: String.self)
            }
            var _8: Api.PendingSuggestion?
            if Int(_1 ?? 0) & Int(1 << 4) != 0 {
                if let signature = reader.readInt32() {
                    _8 = Api.parse(reader, signature: signature) as? Api.PendingSuggestion
                }
            }
            var _9: [Api.Chat]?
            if let _ = reader.readInt32() {
                _9 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Chat.self)
            }
            var _10: [Api.User]?
            if let _ = reader.readInt32() {
                _10 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 3) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _5 != nil
            let _c6 = _6 != nil
            let _c7 = _7 != nil
            let _c8 = (Int(_1 ?? 0) & Int(1 << 4) == 0) || _8 != nil
            let _c9 = _9 != nil
            let _c10 = _10 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 && _c9 && _c10 {
                return Api.help.PromoData.promoData(Cons_promoData(flags: _1!, expires: _2!, peer: _3, psaType: _4, psaMessage: _5, pendingSuggestions: _6!, dismissedSuggestions: _7!, customPendingSuggestion: _8, chats: _9!, users: _10!))
            }
            else {
                return nil
            }
        }
        public static func parse_promoDataEmpty(_ reader: BufferReader) -> PromoData? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.help.PromoData.promoDataEmpty(Cons_promoDataEmpty(expires: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.help {
    enum RecentMeUrls: TypeConstructorDescription {
        public class Cons_recentMeUrls: TypeConstructorDescription {
            public var urls: [Api.RecentMeUrl]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(urls: [Api.RecentMeUrl], chats: [Api.Chat], users: [Api.User]) {
                self.urls = urls
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("recentMeUrls", [("urls", ConstructorParameterDescription(self.urls)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case recentMeUrls(Cons_recentMeUrls)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .recentMeUrls(let _data):
                if boxed {
                    buffer.appendInt32(235081943)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.urls.count))
                for item in _data.urls {
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
            case .recentMeUrls(let _data):
                return ("recentMeUrls", [("urls", ConstructorParameterDescription(_data.urls)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_recentMeUrls(_ reader: BufferReader) -> RecentMeUrls? {
            var _1: [Api.RecentMeUrl]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.RecentMeUrl.self)
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
                return Api.help.RecentMeUrls.recentMeUrls(Cons_recentMeUrls(urls: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.help {
    enum Support: TypeConstructorDescription {
        public class Cons_support: TypeConstructorDescription {
            public var phoneNumber: String
            public var user: Api.User
            public init(phoneNumber: String, user: Api.User) {
                self.phoneNumber = phoneNumber
                self.user = user
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("support", [("phoneNumber", ConstructorParameterDescription(self.phoneNumber)), ("user", ConstructorParameterDescription(self.user))])
            }
        }
        case support(Cons_support)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .support(let _data):
                if boxed {
                    buffer.appendInt32(398898678)
                }
                serializeString(_data.phoneNumber, buffer: buffer, boxed: false)
                _data.user.serialize(buffer, true)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .support(let _data):
                return ("support", [("phoneNumber", ConstructorParameterDescription(_data.phoneNumber)), ("user", ConstructorParameterDescription(_data.user))])
            }
        }

        public static func parse_support(_ reader: BufferReader) -> Support? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Api.User?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.User
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.help.Support.support(Cons_support(phoneNumber: _1!, user: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.help {
    enum SupportName: TypeConstructorDescription {
        public class Cons_supportName: TypeConstructorDescription {
            public var name: String
            public init(name: String) {
                self.name = name
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("supportName", [("name", ConstructorParameterDescription(self.name))])
            }
        }
        case supportName(Cons_supportName)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .supportName(let _data):
                if boxed {
                    buffer.appendInt32(-1945767479)
                }
                serializeString(_data.name, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .supportName(let _data):
                return ("supportName", [("name", ConstructorParameterDescription(_data.name))])
            }
        }

        public static func parse_supportName(_ reader: BufferReader) -> SupportName? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.help.SupportName.supportName(Cons_supportName(name: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.help {
    enum TermsOfService: TypeConstructorDescription {
        public class Cons_termsOfService: TypeConstructorDescription {
            public var flags: Int32
            public var id: Api.DataJSON
            public var text: String
            public var entities: [Api.MessageEntity]
            public var minAgeConfirm: Int32?
            public init(flags: Int32, id: Api.DataJSON, text: String, entities: [Api.MessageEntity], minAgeConfirm: Int32?) {
                self.flags = flags
                self.id = id
                self.text = text
                self.entities = entities
                self.minAgeConfirm = minAgeConfirm
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("termsOfService", [("flags", ConstructorParameterDescription(self.flags)), ("id", ConstructorParameterDescription(self.id)), ("text", ConstructorParameterDescription(self.text)), ("entities", ConstructorParameterDescription(self.entities)), ("minAgeConfirm", ConstructorParameterDescription(self.minAgeConfirm))])
            }
        }
        case termsOfService(Cons_termsOfService)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .termsOfService(let _data):
                if boxed {
                    buffer.appendInt32(2013922064)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                _data.id.serialize(buffer, true)
                serializeString(_data.text, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.entities.count))
                for item in _data.entities {
                    item.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeInt32(_data.minAgeConfirm!, buffer: buffer, boxed: false)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .termsOfService(let _data):
                return ("termsOfService", [("flags", ConstructorParameterDescription(_data.flags)), ("id", ConstructorParameterDescription(_data.id)), ("text", ConstructorParameterDescription(_data.text)), ("entities", ConstructorParameterDescription(_data.entities)), ("minAgeConfirm", ConstructorParameterDescription(_data.minAgeConfirm))])
            }
        }

        public static func parse_termsOfService(_ reader: BufferReader) -> TermsOfService? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.DataJSON?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.DataJSON
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: [Api.MessageEntity]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.MessageEntity.self)
            }
            var _5: Int32?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _5 = reader.readInt32()
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.help.TermsOfService.termsOfService(Cons_termsOfService(flags: _1!, id: _2!, text: _3!, entities: _4!, minAgeConfirm: _5))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.help {
    enum TermsOfServiceUpdate: TypeConstructorDescription {
        public class Cons_termsOfServiceUpdate: TypeConstructorDescription {
            public var expires: Int32
            public var termsOfService: Api.help.TermsOfService
            public init(expires: Int32, termsOfService: Api.help.TermsOfService) {
                self.expires = expires
                self.termsOfService = termsOfService
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("termsOfServiceUpdate", [("expires", ConstructorParameterDescription(self.expires)), ("termsOfService", ConstructorParameterDescription(self.termsOfService))])
            }
        }
        public class Cons_termsOfServiceUpdateEmpty: TypeConstructorDescription {
            public var expires: Int32
            public init(expires: Int32) {
                self.expires = expires
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("termsOfServiceUpdateEmpty", [("expires", ConstructorParameterDescription(self.expires))])
            }
        }
        case termsOfServiceUpdate(Cons_termsOfServiceUpdate)
        case termsOfServiceUpdateEmpty(Cons_termsOfServiceUpdateEmpty)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .termsOfServiceUpdate(let _data):
                if boxed {
                    buffer.appendInt32(686618977)
                }
                serializeInt32(_data.expires, buffer: buffer, boxed: false)
                _data.termsOfService.serialize(buffer, true)
                break
            case .termsOfServiceUpdateEmpty(let _data):
                if boxed {
                    buffer.appendInt32(-483352705)
                }
                serializeInt32(_data.expires, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .termsOfServiceUpdate(let _data):
                return ("termsOfServiceUpdate", [("expires", ConstructorParameterDescription(_data.expires)), ("termsOfService", ConstructorParameterDescription(_data.termsOfService))])
            case .termsOfServiceUpdateEmpty(let _data):
                return ("termsOfServiceUpdateEmpty", [("expires", ConstructorParameterDescription(_data.expires))])
            }
        }

        public static func parse_termsOfServiceUpdate(_ reader: BufferReader) -> TermsOfServiceUpdate? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.help.TermsOfService?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.help.TermsOfService
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.help.TermsOfServiceUpdate.termsOfServiceUpdate(Cons_termsOfServiceUpdate(expires: _1!, termsOfService: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_termsOfServiceUpdateEmpty(_ reader: BufferReader) -> TermsOfServiceUpdate? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.help.TermsOfServiceUpdate.termsOfServiceUpdateEmpty(Cons_termsOfServiceUpdateEmpty(expires: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.help {
    enum TimezonesList: TypeConstructorDescription {
        public class Cons_timezonesList: TypeConstructorDescription {
            public var timezones: [Api.Timezone]
            public var hash: Int32
            public init(timezones: [Api.Timezone], hash: Int32) {
                self.timezones = timezones
                self.hash = hash
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("timezonesList", [("timezones", ConstructorParameterDescription(self.timezones)), ("hash", ConstructorParameterDescription(self.hash))])
            }
        }
        case timezonesList(Cons_timezonesList)
        case timezonesListNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .timezonesList(let _data):
                if boxed {
                    buffer.appendInt32(2071260529)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.timezones.count))
                for item in _data.timezones {
                    item.serialize(buffer, true)
                }
                serializeInt32(_data.hash, buffer: buffer, boxed: false)
                break
            case .timezonesListNotModified:
                if boxed {
                    buffer.appendInt32(-1761146676)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .timezonesList(let _data):
                return ("timezonesList", [("timezones", ConstructorParameterDescription(_data.timezones)), ("hash", ConstructorParameterDescription(_data.hash))])
            case .timezonesListNotModified:
                return ("timezonesListNotModified", [])
            }
        }

        public static func parse_timezonesList(_ reader: BufferReader) -> TimezonesList? {
            var _1: [Api.Timezone]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Timezone.self)
            }
            var _2: Int32?
            _2 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.help.TimezonesList.timezonesList(Cons_timezonesList(timezones: _1!, hash: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_timezonesListNotModified(_ reader: BufferReader) -> TimezonesList? {
            return Api.help.TimezonesList.timezonesListNotModified
        }
    }
}
public extension Api.help {
    enum UserInfo: TypeConstructorDescription {
        public class Cons_userInfo: TypeConstructorDescription {
            public var message: String
            public var entities: [Api.MessageEntity]
            public var author: String
            public var date: Int32
            public init(message: String, entities: [Api.MessageEntity], author: String, date: Int32) {
                self.message = message
                self.entities = entities
                self.author = author
                self.date = date
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("userInfo", [("message", ConstructorParameterDescription(self.message)), ("entities", ConstructorParameterDescription(self.entities)), ("author", ConstructorParameterDescription(self.author)), ("date", ConstructorParameterDescription(self.date))])
            }
        }
        case userInfo(Cons_userInfo)
        case userInfoEmpty

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .userInfo(let _data):
                if boxed {
                    buffer.appendInt32(32192344)
                }
                serializeString(_data.message, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.entities.count))
                for item in _data.entities {
                    item.serialize(buffer, true)
                }
                serializeString(_data.author, buffer: buffer, boxed: false)
                serializeInt32(_data.date, buffer: buffer, boxed: false)
                break
            case .userInfoEmpty:
                if boxed {
                    buffer.appendInt32(-206688531)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .userInfo(let _data):
                return ("userInfo", [("message", ConstructorParameterDescription(_data.message)), ("entities", ConstructorParameterDescription(_data.entities)), ("author", ConstructorParameterDescription(_data.author)), ("date", ConstructorParameterDescription(_data.date))])
            case .userInfoEmpty:
                return ("userInfoEmpty", [])
            }
        }

        public static func parse_userInfo(_ reader: BufferReader) -> UserInfo? {
            var _1: String?
            _1 = parseString(reader)
            var _2: [Api.MessageEntity]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.MessageEntity.self)
            }
            var _3: String?
            _3 = parseString(reader)
            var _4: Int32?
            _4 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.help.UserInfo.userInfo(Cons_userInfo(message: _1!, entities: _2!, author: _3!, date: _4!))
            }
            else {
                return nil
            }
        }
        public static func parse_userInfoEmpty(_ reader: BufferReader) -> UserInfo? {
            return Api.help.UserInfo.userInfoEmpty
        }
    }
}
public extension Api.messages {
    enum AffectedFoundMessages: TypeConstructorDescription {
        public class Cons_affectedFoundMessages: TypeConstructorDescription {
            public var pts: Int32
            public var ptsCount: Int32
            public var offset: Int32
            public var messages: [Int32]
            public init(pts: Int32, ptsCount: Int32, offset: Int32, messages: [Int32]) {
                self.pts = pts
                self.ptsCount = ptsCount
                self.offset = offset
                self.messages = messages
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("affectedFoundMessages", [("pts", ConstructorParameterDescription(self.pts)), ("ptsCount", ConstructorParameterDescription(self.ptsCount)), ("offset", ConstructorParameterDescription(self.offset)), ("messages", ConstructorParameterDescription(self.messages))])
            }
        }
        case affectedFoundMessages(Cons_affectedFoundMessages)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .affectedFoundMessages(let _data):
                if boxed {
                    buffer.appendInt32(-275956116)
                }
                serializeInt32(_data.pts, buffer: buffer, boxed: false)
                serializeInt32(_data.ptsCount, buffer: buffer, boxed: false)
                serializeInt32(_data.offset, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.messages.count))
                for item in _data.messages {
                    serializeInt32(item, buffer: buffer, boxed: false)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .affectedFoundMessages(let _data):
                return ("affectedFoundMessages", [("pts", ConstructorParameterDescription(_data.pts)), ("ptsCount", ConstructorParameterDescription(_data.ptsCount)), ("offset", ConstructorParameterDescription(_data.offset)), ("messages", ConstructorParameterDescription(_data.messages))])
            }
        }

        public static func parse_affectedFoundMessages(_ reader: BufferReader) -> AffectedFoundMessages? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            _3 = reader.readInt32()
            var _4: [Int32]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: -1471112230, elementType: Int32.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.messages.AffectedFoundMessages.affectedFoundMessages(Cons_affectedFoundMessages(pts: _1!, ptsCount: _2!, offset: _3!, messages: _4!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum AffectedHistory: TypeConstructorDescription {
        public class Cons_affectedHistory: TypeConstructorDescription {
            public var pts: Int32
            public var ptsCount: Int32
            public var offset: Int32
            public init(pts: Int32, ptsCount: Int32, offset: Int32) {
                self.pts = pts
                self.ptsCount = ptsCount
                self.offset = offset
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("affectedHistory", [("pts", ConstructorParameterDescription(self.pts)), ("ptsCount", ConstructorParameterDescription(self.ptsCount)), ("offset", ConstructorParameterDescription(self.offset))])
            }
        }
        case affectedHistory(Cons_affectedHistory)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .affectedHistory(let _data):
                if boxed {
                    buffer.appendInt32(-1269012015)
                }
                serializeInt32(_data.pts, buffer: buffer, boxed: false)
                serializeInt32(_data.ptsCount, buffer: buffer, boxed: false)
                serializeInt32(_data.offset, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .affectedHistory(let _data):
                return ("affectedHistory", [("pts", ConstructorParameterDescription(_data.pts)), ("ptsCount", ConstructorParameterDescription(_data.ptsCount)), ("offset", ConstructorParameterDescription(_data.offset))])
            }
        }

        public static func parse_affectedHistory(_ reader: BufferReader) -> AffectedHistory? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            _3 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.messages.AffectedHistory.affectedHistory(Cons_affectedHistory(pts: _1!, ptsCount: _2!, offset: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum AffectedMessages: TypeConstructorDescription {
        public class Cons_affectedMessages: TypeConstructorDescription {
            public var pts: Int32
            public var ptsCount: Int32
            public init(pts: Int32, ptsCount: Int32) {
                self.pts = pts
                self.ptsCount = ptsCount
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("affectedMessages", [("pts", ConstructorParameterDescription(self.pts)), ("ptsCount", ConstructorParameterDescription(self.ptsCount))])
            }
        }
        case affectedMessages(Cons_affectedMessages)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .affectedMessages(let _data):
                if boxed {
                    buffer.appendInt32(-2066640507)
                }
                serializeInt32(_data.pts, buffer: buffer, boxed: false)
                serializeInt32(_data.ptsCount, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .affectedMessages(let _data):
                return ("affectedMessages", [("pts", ConstructorParameterDescription(_data.pts)), ("ptsCount", ConstructorParameterDescription(_data.ptsCount))])
            }
        }

        public static func parse_affectedMessages(_ reader: BufferReader) -> AffectedMessages? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.AffectedMessages.affectedMessages(Cons_affectedMessages(pts: _1!, ptsCount: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum AllStickers: TypeConstructorDescription {
        public class Cons_allStickers: TypeConstructorDescription {
            public var hash: Int64
            public var sets: [Api.StickerSet]
            public init(hash: Int64, sets: [Api.StickerSet]) {
                self.hash = hash
                self.sets = sets
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("allStickers", [("hash", ConstructorParameterDescription(self.hash)), ("sets", ConstructorParameterDescription(self.sets))])
            }
        }
        case allStickers(Cons_allStickers)
        case allStickersNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .allStickers(let _data):
                if boxed {
                    buffer.appendInt32(-843329861)
                }
                serializeInt64(_data.hash, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.sets.count))
                for item in _data.sets {
                    item.serialize(buffer, true)
                }
                break
            case .allStickersNotModified:
                if boxed {
                    buffer.appendInt32(-395967805)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .allStickers(let _data):
                return ("allStickers", [("hash", ConstructorParameterDescription(_data.hash)), ("sets", ConstructorParameterDescription(_data.sets))])
            case .allStickersNotModified:
                return ("allStickersNotModified", [])
            }
        }

        public static func parse_allStickers(_ reader: BufferReader) -> AllStickers? {
            var _1: Int64?
            _1 = reader.readInt64()
            var _2: [Api.StickerSet]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerSet.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.AllStickers.allStickers(Cons_allStickers(hash: _1!, sets: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_allStickersNotModified(_ reader: BufferReader) -> AllStickers? {
            return Api.messages.AllStickers.allStickersNotModified
        }
    }
}
public extension Api.messages {
    enum ArchivedStickers: TypeConstructorDescription {
        public class Cons_archivedStickers: TypeConstructorDescription {
            public var count: Int32
            public var sets: [Api.StickerSetCovered]
            public init(count: Int32, sets: [Api.StickerSetCovered]) {
                self.count = count
                self.sets = sets
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("archivedStickers", [("count", ConstructorParameterDescription(self.count)), ("sets", ConstructorParameterDescription(self.sets))])
            }
        }
        case archivedStickers(Cons_archivedStickers)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .archivedStickers(let _data):
                if boxed {
                    buffer.appendInt32(1338747336)
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
            case .archivedStickers(let _data):
                return ("archivedStickers", [("count", ConstructorParameterDescription(_data.count)), ("sets", ConstructorParameterDescription(_data.sets))])
            }
        }

        public static func parse_archivedStickers(_ reader: BufferReader) -> ArchivedStickers? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.StickerSetCovered]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.StickerSetCovered.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.ArchivedStickers.archivedStickers(Cons_archivedStickers(count: _1!, sets: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum AvailableEffects: TypeConstructorDescription {
        public class Cons_availableEffects: TypeConstructorDescription {
            public var hash: Int32
            public var effects: [Api.AvailableEffect]
            public var documents: [Api.Document]
            public init(hash: Int32, effects: [Api.AvailableEffect], documents: [Api.Document]) {
                self.hash = hash
                self.effects = effects
                self.documents = documents
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("availableEffects", [("hash", ConstructorParameterDescription(self.hash)), ("effects", ConstructorParameterDescription(self.effects)), ("documents", ConstructorParameterDescription(self.documents))])
            }
        }
        case availableEffects(Cons_availableEffects)
        case availableEffectsNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .availableEffects(let _data):
                if boxed {
                    buffer.appendInt32(-1109696146)
                }
                serializeInt32(_data.hash, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.effects.count))
                for item in _data.effects {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.documents.count))
                for item in _data.documents {
                    item.serialize(buffer, true)
                }
                break
            case .availableEffectsNotModified:
                if boxed {
                    buffer.appendInt32(-772957605)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .availableEffects(let _data):
                return ("availableEffects", [("hash", ConstructorParameterDescription(_data.hash)), ("effects", ConstructorParameterDescription(_data.effects)), ("documents", ConstructorParameterDescription(_data.documents))])
            case .availableEffectsNotModified:
                return ("availableEffectsNotModified", [])
            }
        }

        public static func parse_availableEffects(_ reader: BufferReader) -> AvailableEffects? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.AvailableEffect]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.AvailableEffect.self)
            }
            var _3: [Api.Document]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Document.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.messages.AvailableEffects.availableEffects(Cons_availableEffects(hash: _1!, effects: _2!, documents: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_availableEffectsNotModified(_ reader: BufferReader) -> AvailableEffects? {
            return Api.messages.AvailableEffects.availableEffectsNotModified
        }
    }
}
public extension Api.messages {
    enum AvailableReactions: TypeConstructorDescription {
        public class Cons_availableReactions: TypeConstructorDescription {
            public var hash: Int32
            public var reactions: [Api.AvailableReaction]
            public init(hash: Int32, reactions: [Api.AvailableReaction]) {
                self.hash = hash
                self.reactions = reactions
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("availableReactions", [("hash", ConstructorParameterDescription(self.hash)), ("reactions", ConstructorParameterDescription(self.reactions))])
            }
        }
        case availableReactions(Cons_availableReactions)
        case availableReactionsNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .availableReactions(let _data):
                if boxed {
                    buffer.appendInt32(1989032621)
                }
                serializeInt32(_data.hash, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.reactions.count))
                for item in _data.reactions {
                    item.serialize(buffer, true)
                }
                break
            case .availableReactionsNotModified:
                if boxed {
                    buffer.appendInt32(-1626924713)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .availableReactions(let _data):
                return ("availableReactions", [("hash", ConstructorParameterDescription(_data.hash)), ("reactions", ConstructorParameterDescription(_data.reactions))])
            case .availableReactionsNotModified:
                return ("availableReactionsNotModified", [])
            }
        }

        public static func parse_availableReactions(_ reader: BufferReader) -> AvailableReactions? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: [Api.AvailableReaction]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.AvailableReaction.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.AvailableReactions.availableReactions(Cons_availableReactions(hash: _1!, reactions: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_availableReactionsNotModified(_ reader: BufferReader) -> AvailableReactions? {
            return Api.messages.AvailableReactions.availableReactionsNotModified
        }
    }
}
public extension Api.messages {
    enum BotApp: TypeConstructorDescription {
        public class Cons_botApp: TypeConstructorDescription {
            public var flags: Int32
            public var app: Api.BotApp
            public init(flags: Int32, app: Api.BotApp) {
                self.flags = flags
                self.app = app
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("botApp", [("flags", ConstructorParameterDescription(self.flags)), ("app", ConstructorParameterDescription(self.app))])
            }
        }
        case botApp(Cons_botApp)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .botApp(let _data):
                if boxed {
                    buffer.appendInt32(-347034123)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                _data.app.serialize(buffer, true)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .botApp(let _data):
                return ("botApp", [("flags", ConstructorParameterDescription(_data.flags)), ("app", ConstructorParameterDescription(_data.app))])
            }
        }

        public static func parse_botApp(_ reader: BufferReader) -> BotApp? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.BotApp?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.BotApp
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.BotApp.botApp(Cons_botApp(flags: _1!, app: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum BotCallbackAnswer: TypeConstructorDescription {
        public class Cons_botCallbackAnswer: TypeConstructorDescription {
            public var flags: Int32
            public var message: String?
            public var url: String?
            public var cacheTime: Int32
            public init(flags: Int32, message: String?, url: String?, cacheTime: Int32) {
                self.flags = flags
                self.message = message
                self.url = url
                self.cacheTime = cacheTime
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("botCallbackAnswer", [("flags", ConstructorParameterDescription(self.flags)), ("message", ConstructorParameterDescription(self.message)), ("url", ConstructorParameterDescription(self.url)), ("cacheTime", ConstructorParameterDescription(self.cacheTime))])
            }
        }
        case botCallbackAnswer(Cons_botCallbackAnswer)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .botCallbackAnswer(let _data):
                if boxed {
                    buffer.appendInt32(911761060)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    serializeString(_data.message!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeString(_data.url!, buffer: buffer, boxed: false)
                }
                serializeInt32(_data.cacheTime, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .botCallbackAnswer(let _data):
                return ("botCallbackAnswer", [("flags", ConstructorParameterDescription(_data.flags)), ("message", ConstructorParameterDescription(_data.message)), ("url", ConstructorParameterDescription(_data.url)), ("cacheTime", ConstructorParameterDescription(_data.cacheTime))])
            }
        }

        public static func parse_botCallbackAnswer(_ reader: BufferReader) -> BotCallbackAnswer? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                _2 = parseString(reader)
            }
            var _3: String?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _3 = parseString(reader)
            }
            var _4: Int32?
            _4 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.messages.BotCallbackAnswer.botCallbackAnswer(Cons_botCallbackAnswer(flags: _1!, message: _2, url: _3, cacheTime: _4!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum BotPreparedInlineMessage: TypeConstructorDescription {
        public class Cons_botPreparedInlineMessage: TypeConstructorDescription {
            public var id: String
            public var expireDate: Int32
            public init(id: String, expireDate: Int32) {
                self.id = id
                self.expireDate = expireDate
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("botPreparedInlineMessage", [("id", ConstructorParameterDescription(self.id)), ("expireDate", ConstructorParameterDescription(self.expireDate))])
            }
        }
        case botPreparedInlineMessage(Cons_botPreparedInlineMessage)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .botPreparedInlineMessage(let _data):
                if boxed {
                    buffer.appendInt32(-1899035375)
                }
                serializeString(_data.id, buffer: buffer, boxed: false)
                serializeInt32(_data.expireDate, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .botPreparedInlineMessage(let _data):
                return ("botPreparedInlineMessage", [("id", ConstructorParameterDescription(_data.id)), ("expireDate", ConstructorParameterDescription(_data.expireDate))])
            }
        }

        public static func parse_botPreparedInlineMessage(_ reader: BufferReader) -> BotPreparedInlineMessage? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int32?
            _2 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.messages.BotPreparedInlineMessage.botPreparedInlineMessage(Cons_botPreparedInlineMessage(id: _1!, expireDate: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.messages {
    enum BotResults: TypeConstructorDescription {
        public class Cons_botResults: TypeConstructorDescription {
            public var flags: Int32
            public var queryId: Int64
            public var nextOffset: String?
            public var switchPm: Api.InlineBotSwitchPM?
            public var switchWebview: Api.InlineBotWebView?
            public var results: [Api.BotInlineResult]
            public var cacheTime: Int32
            public var users: [Api.User]
            public init(flags: Int32, queryId: Int64, nextOffset: String?, switchPm: Api.InlineBotSwitchPM?, switchWebview: Api.InlineBotWebView?, results: [Api.BotInlineResult], cacheTime: Int32, users: [Api.User]) {
                self.flags = flags
                self.queryId = queryId
                self.nextOffset = nextOffset
                self.switchPm = switchPm
                self.switchWebview = switchWebview
                self.results = results
                self.cacheTime = cacheTime
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("botResults", [("flags", ConstructorParameterDescription(self.flags)), ("queryId", ConstructorParameterDescription(self.queryId)), ("nextOffset", ConstructorParameterDescription(self.nextOffset)), ("switchPm", ConstructorParameterDescription(self.switchPm)), ("switchWebview", ConstructorParameterDescription(self.switchWebview)), ("results", ConstructorParameterDescription(self.results)), ("cacheTime", ConstructorParameterDescription(self.cacheTime)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case botResults(Cons_botResults)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .botResults(let _data):
                if boxed {
                    buffer.appendInt32(-534646026)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt64(_data.queryId, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeString(_data.nextOffset!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    _data.switchPm!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 3) != 0 {
                    _data.switchWebview!.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.results.count))
                for item in _data.results {
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
            case .botResults(let _data):
                return ("botResults", [("flags", ConstructorParameterDescription(_data.flags)), ("queryId", ConstructorParameterDescription(_data.queryId)), ("nextOffset", ConstructorParameterDescription(_data.nextOffset)), ("switchPm", ConstructorParameterDescription(_data.switchPm)), ("switchWebview", ConstructorParameterDescription(_data.switchWebview)), ("results", ConstructorParameterDescription(_data.results)), ("cacheTime", ConstructorParameterDescription(_data.cacheTime)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_botResults(_ reader: BufferReader) -> BotResults? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int64?
            _2 = reader.readInt64()
            var _3: String?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _3 = parseString(reader)
            }
            var _4: Api.InlineBotSwitchPM?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                if let signature = reader.readInt32() {
                    _4 = Api.parse(reader, signature: signature) as? Api.InlineBotSwitchPM
                }
            }
            var _5: Api.InlineBotWebView?
            if Int(_1 ?? 0) & Int(1 << 3) != 0 {
                if let signature = reader.readInt32() {
                    _5 = Api.parse(reader, signature: signature) as? Api.InlineBotWebView
                }
            }
            var _6: [Api.BotInlineResult]?
            if let _ = reader.readInt32() {
                _6 = Api.parseVector(reader, elementSignature: 0, elementType: Api.BotInlineResult.self)
            }
            var _7: Int32?
            _7 = reader.readInt32()
            var _8: [Api.User]?
            if let _ = reader.readInt32() {
                _8 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _4 != nil
            let _c5 = (Int(_1 ?? 0) & Int(1 << 3) == 0) || _5 != nil
            let _c6 = _6 != nil
            let _c7 = _7 != nil
            let _c8 = _8 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 {
                return Api.messages.BotResults.botResults(Cons_botResults(flags: _1!, queryId: _2!, nextOffset: _3, switchPm: _4, switchWebview: _5, results: _6!, cacheTime: _7!, users: _8!))
            }
            else {
                return nil
            }
        }
    }
}
