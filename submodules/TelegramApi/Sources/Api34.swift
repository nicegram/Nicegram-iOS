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
public extension Api.contacts {
    enum ContactBirthdays: TypeConstructorDescription {
        public class Cons_contactBirthdays: TypeConstructorDescription {
            public var contacts: [Api.ContactBirthday]
            public var users: [Api.User]
            public init(contacts: [Api.ContactBirthday], users: [Api.User]) {
                self.contacts = contacts
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("contactBirthdays", [("contacts", ConstructorParameterDescription(self.contacts)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case contactBirthdays(Cons_contactBirthdays)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .contactBirthdays(let _data):
                if boxed {
                    buffer.appendInt32(290452237)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.contacts.count))
                for item in _data.contacts {
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
            case .contactBirthdays(let _data):
                return ("contactBirthdays", [("contacts", ConstructorParameterDescription(_data.contacts)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_contactBirthdays(_ reader: BufferReader) -> ContactBirthdays? {
            var _1: [Api.ContactBirthday]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.ContactBirthday.self)
            }
            var _2: [Api.User]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.contacts.ContactBirthdays.contactBirthdays(Cons_contactBirthdays(contacts: _1!, users: _2!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.contacts {
    enum Contacts: TypeConstructorDescription {
        public class Cons_contacts: TypeConstructorDescription {
            public var contacts: [Api.Contact]
            public var savedCount: Int32
            public var users: [Api.User]
            public init(contacts: [Api.Contact], savedCount: Int32, users: [Api.User]) {
                self.contacts = contacts
                self.savedCount = savedCount
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("contacts", [("contacts", ConstructorParameterDescription(self.contacts)), ("savedCount", ConstructorParameterDescription(self.savedCount)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case contacts(Cons_contacts)
        case contactsNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .contacts(let _data):
                if boxed {
                    buffer.appendInt32(-353862078)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.contacts.count))
                for item in _data.contacts {
                    item.serialize(buffer, true)
                }
                serializeInt32(_data.savedCount, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.users.count))
                for item in _data.users {
                    item.serialize(buffer, true)
                }
                break
            case .contactsNotModified:
                if boxed {
                    buffer.appendInt32(-1219778094)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .contacts(let _data):
                return ("contacts", [("contacts", ConstructorParameterDescription(_data.contacts)), ("savedCount", ConstructorParameterDescription(_data.savedCount)), ("users", ConstructorParameterDescription(_data.users))])
            case .contactsNotModified:
                return ("contactsNotModified", [])
            }
        }

        public static func parse_contacts(_ reader: BufferReader) -> Contacts? {
            var _1: [Api.Contact]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Contact.self)
            }
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: [Api.User]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.User.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.contacts.Contacts.contacts(Cons_contacts(contacts: _1!, savedCount: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_contactsNotModified(_ reader: BufferReader) -> Contacts? {
            return Api.contacts.Contacts.contactsNotModified
        }
    }
}
public extension Api.contacts {
    enum Found: TypeConstructorDescription {
        public class Cons_found: TypeConstructorDescription {
            public var myResults: [Api.Peer]
            public var results: [Api.Peer]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(myResults: [Api.Peer], results: [Api.Peer], chats: [Api.Chat], users: [Api.User]) {
                self.myResults = myResults
                self.results = results
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("found", [("myResults", ConstructorParameterDescription(self.myResults)), ("results", ConstructorParameterDescription(self.results)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case found(Cons_found)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .found(let _data):
                if boxed {
                    buffer.appendInt32(-1290580579)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.myResults.count))
                for item in _data.myResults {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.results.count))
                for item in _data.results {
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
            case .found(let _data):
                return ("found", [("myResults", ConstructorParameterDescription(_data.myResults)), ("results", ConstructorParameterDescription(_data.results)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_found(_ reader: BufferReader) -> Found? {
            var _1: [Api.Peer]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Peer.self)
            }
            var _2: [Api.Peer]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.Peer.self)
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
                return Api.contacts.Found.found(Cons_found(myResults: _1!, results: _2!, chats: _3!, users: _4!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.contacts {
    enum ImportedContacts: TypeConstructorDescription {
        public class Cons_importedContacts: TypeConstructorDescription {
            public var imported: [Api.ImportedContact]
            public var popularInvites: [Api.PopularContact]
            public var retryContacts: [Int64]
            public var users: [Api.User]
            public init(imported: [Api.ImportedContact], popularInvites: [Api.PopularContact], retryContacts: [Int64], users: [Api.User]) {
                self.imported = imported
                self.popularInvites = popularInvites
                self.retryContacts = retryContacts
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("importedContacts", [("imported", ConstructorParameterDescription(self.imported)), ("popularInvites", ConstructorParameterDescription(self.popularInvites)), ("retryContacts", ConstructorParameterDescription(self.retryContacts)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case importedContacts(Cons_importedContacts)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .importedContacts(let _data):
                if boxed {
                    buffer.appendInt32(2010127419)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.imported.count))
                for item in _data.imported {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.popularInvites.count))
                for item in _data.popularInvites {
                    item.serialize(buffer, true)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.retryContacts.count))
                for item in _data.retryContacts {
                    serializeInt64(item, buffer: buffer, boxed: false)
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
            case .importedContacts(let _data):
                return ("importedContacts", [("imported", ConstructorParameterDescription(_data.imported)), ("popularInvites", ConstructorParameterDescription(_data.popularInvites)), ("retryContacts", ConstructorParameterDescription(_data.retryContacts)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_importedContacts(_ reader: BufferReader) -> ImportedContacts? {
            var _1: [Api.ImportedContact]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.ImportedContact.self)
            }
            var _2: [Api.PopularContact]?
            if let _ = reader.readInt32() {
                _2 = Api.parseVector(reader, elementSignature: 0, elementType: Api.PopularContact.self)
            }
            var _3: [Int64]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 570911930, elementType: Int64.self)
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
                return Api.contacts.ImportedContacts.importedContacts(Cons_importedContacts(imported: _1!, popularInvites: _2!, retryContacts: _3!, users: _4!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.contacts {
    enum ResolvedPeer: TypeConstructorDescription {
        public class Cons_resolvedPeer: TypeConstructorDescription {
            public var peer: Api.Peer
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(peer: Api.Peer, chats: [Api.Chat], users: [Api.User]) {
                self.peer = peer
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("resolvedPeer", [("peer", ConstructorParameterDescription(self.peer)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case resolvedPeer(Cons_resolvedPeer)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .resolvedPeer(let _data):
                if boxed {
                    buffer.appendInt32(2131196633)
                }
                _data.peer.serialize(buffer, true)
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
            case .resolvedPeer(let _data):
                return ("resolvedPeer", [("peer", ConstructorParameterDescription(_data.peer)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            }
        }

        public static func parse_resolvedPeer(_ reader: BufferReader) -> ResolvedPeer? {
            var _1: Api.Peer?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.Peer
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
                return Api.contacts.ResolvedPeer.resolvedPeer(Cons_resolvedPeer(peer: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.contacts {
    enum SponsoredPeers: TypeConstructorDescription {
        public class Cons_sponsoredPeers: TypeConstructorDescription {
            public var peers: [Api.SponsoredPeer]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(peers: [Api.SponsoredPeer], chats: [Api.Chat], users: [Api.User]) {
                self.peers = peers
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("sponsoredPeers", [("peers", ConstructorParameterDescription(self.peers)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case sponsoredPeers(Cons_sponsoredPeers)
        case sponsoredPeersEmpty

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .sponsoredPeers(let _data):
                if boxed {
                    buffer.appendInt32(-352114556)
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
            case .sponsoredPeersEmpty:
                if boxed {
                    buffer.appendInt32(-365775695)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .sponsoredPeers(let _data):
                return ("sponsoredPeers", [("peers", ConstructorParameterDescription(_data.peers)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            case .sponsoredPeersEmpty:
                return ("sponsoredPeersEmpty", [])
            }
        }

        public static func parse_sponsoredPeers(_ reader: BufferReader) -> SponsoredPeers? {
            var _1: [Api.SponsoredPeer]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.SponsoredPeer.self)
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
                return Api.contacts.SponsoredPeers.sponsoredPeers(Cons_sponsoredPeers(peers: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_sponsoredPeersEmpty(_ reader: BufferReader) -> SponsoredPeers? {
            return Api.contacts.SponsoredPeers.sponsoredPeersEmpty
        }
    }
}
public extension Api.contacts {
    enum TopPeers: TypeConstructorDescription {
        public class Cons_topPeers: TypeConstructorDescription {
            public var categories: [Api.TopPeerCategoryPeers]
            public var chats: [Api.Chat]
            public var users: [Api.User]
            public init(categories: [Api.TopPeerCategoryPeers], chats: [Api.Chat], users: [Api.User]) {
                self.categories = categories
                self.chats = chats
                self.users = users
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("topPeers", [("categories", ConstructorParameterDescription(self.categories)), ("chats", ConstructorParameterDescription(self.chats)), ("users", ConstructorParameterDescription(self.users))])
            }
        }
        case topPeers(Cons_topPeers)
        case topPeersDisabled
        case topPeersNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .topPeers(let _data):
                if boxed {
                    buffer.appendInt32(1891070632)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.categories.count))
                for item in _data.categories {
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
            case .topPeersDisabled:
                if boxed {
                    buffer.appendInt32(-1255369827)
                }
                break
            case .topPeersNotModified:
                if boxed {
                    buffer.appendInt32(-567906571)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .topPeers(let _data):
                return ("topPeers", [("categories", ConstructorParameterDescription(_data.categories)), ("chats", ConstructorParameterDescription(_data.chats)), ("users", ConstructorParameterDescription(_data.users))])
            case .topPeersDisabled:
                return ("topPeersDisabled", [])
            case .topPeersNotModified:
                return ("topPeersNotModified", [])
            }
        }

        public static func parse_topPeers(_ reader: BufferReader) -> TopPeers? {
            var _1: [Api.TopPeerCategoryPeers]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.TopPeerCategoryPeers.self)
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
                return Api.contacts.TopPeers.topPeers(Cons_topPeers(categories: _1!, chats: _2!, users: _3!))
            }
            else {
                return nil
            }
        }
        public static func parse_topPeersDisabled(_ reader: BufferReader) -> TopPeers? {
            return Api.contacts.TopPeers.topPeersDisabled
        }
        public static func parse_topPeersNotModified(_ reader: BufferReader) -> TopPeers? {
            return Api.contacts.TopPeers.topPeersNotModified
        }
    }
}
public extension Api.fragment {
    enum CollectibleInfo: TypeConstructorDescription {
        public class Cons_collectibleInfo: TypeConstructorDescription {
            public var purchaseDate: Int32
            public var currency: String
            public var amount: Int64
            public var cryptoCurrency: String
            public var cryptoAmount: Int64
            public var url: String
            public init(purchaseDate: Int32, currency: String, amount: Int64, cryptoCurrency: String, cryptoAmount: Int64, url: String) {
                self.purchaseDate = purchaseDate
                self.currency = currency
                self.amount = amount
                self.cryptoCurrency = cryptoCurrency
                self.cryptoAmount = cryptoAmount
                self.url = url
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("collectibleInfo", [("purchaseDate", ConstructorParameterDescription(self.purchaseDate)), ("currency", ConstructorParameterDescription(self.currency)), ("amount", ConstructorParameterDescription(self.amount)), ("cryptoCurrency", ConstructorParameterDescription(self.cryptoCurrency)), ("cryptoAmount", ConstructorParameterDescription(self.cryptoAmount)), ("url", ConstructorParameterDescription(self.url))])
            }
        }
        case collectibleInfo(Cons_collectibleInfo)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .collectibleInfo(let _data):
                if boxed {
                    buffer.appendInt32(1857945489)
                }
                serializeInt32(_data.purchaseDate, buffer: buffer, boxed: false)
                serializeString(_data.currency, buffer: buffer, boxed: false)
                serializeInt64(_data.amount, buffer: buffer, boxed: false)
                serializeString(_data.cryptoCurrency, buffer: buffer, boxed: false)
                serializeInt64(_data.cryptoAmount, buffer: buffer, boxed: false)
                serializeString(_data.url, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .collectibleInfo(let _data):
                return ("collectibleInfo", [("purchaseDate", ConstructorParameterDescription(_data.purchaseDate)), ("currency", ConstructorParameterDescription(_data.currency)), ("amount", ConstructorParameterDescription(_data.amount)), ("cryptoCurrency", ConstructorParameterDescription(_data.cryptoCurrency)), ("cryptoAmount", ConstructorParameterDescription(_data.cryptoAmount)), ("url", ConstructorParameterDescription(_data.url))])
            }
        }

        public static func parse_collectibleInfo(_ reader: BufferReader) -> CollectibleInfo? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: Int64?
            _3 = reader.readInt64()
            var _4: String?
            _4 = parseString(reader)
            var _5: Int64?
            _5 = reader.readInt64()
            var _6: String?
            _6 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.fragment.CollectibleInfo.collectibleInfo(Cons_collectibleInfo(purchaseDate: _1!, currency: _2!, amount: _3!, cryptoCurrency: _4!, cryptoAmount: _5!, url: _6!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.help {
    enum AppConfig: TypeConstructorDescription {
        public class Cons_appConfig: TypeConstructorDescription {
            public var hash: Int32
            public var config: Api.JSONValue
            public init(hash: Int32, config: Api.JSONValue) {
                self.hash = hash
                self.config = config
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("appConfig", [("hash", ConstructorParameterDescription(self.hash)), ("config", ConstructorParameterDescription(self.config))])
            }
        }
        case appConfig(Cons_appConfig)
        case appConfigNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .appConfig(let _data):
                if boxed {
                    buffer.appendInt32(-585598930)
                }
                serializeInt32(_data.hash, buffer: buffer, boxed: false)
                _data.config.serialize(buffer, true)
                break
            case .appConfigNotModified:
                if boxed {
                    buffer.appendInt32(2094949405)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .appConfig(let _data):
                return ("appConfig", [("hash", ConstructorParameterDescription(_data.hash)), ("config", ConstructorParameterDescription(_data.config))])
            case .appConfigNotModified:
                return ("appConfigNotModified", [])
            }
        }

        public static func parse_appConfig(_ reader: BufferReader) -> AppConfig? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.JSONValue?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.JSONValue
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.help.AppConfig.appConfig(Cons_appConfig(hash: _1!, config: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_appConfigNotModified(_ reader: BufferReader) -> AppConfig? {
            return Api.help.AppConfig.appConfigNotModified
        }
    }
}
public extension Api.help {
    enum AppUpdate: TypeConstructorDescription {
        public class Cons_appUpdate: TypeConstructorDescription {
            public var flags: Int32
            public var id: Int32
            public var version: String
            public var text: String
            public var entities: [Api.MessageEntity]
            public var document: Api.Document?
            public var url: String?
            public var sticker: Api.Document?
            public init(flags: Int32, id: Int32, version: String, text: String, entities: [Api.MessageEntity], document: Api.Document?, url: String?, sticker: Api.Document?) {
                self.flags = flags
                self.id = id
                self.version = version
                self.text = text
                self.entities = entities
                self.document = document
                self.url = url
                self.sticker = sticker
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("appUpdate", [("flags", ConstructorParameterDescription(self.flags)), ("id", ConstructorParameterDescription(self.id)), ("version", ConstructorParameterDescription(self.version)), ("text", ConstructorParameterDescription(self.text)), ("entities", ConstructorParameterDescription(self.entities)), ("document", ConstructorParameterDescription(self.document)), ("url", ConstructorParameterDescription(self.url)), ("sticker", ConstructorParameterDescription(self.sticker))])
            }
        }
        case appUpdate(Cons_appUpdate)
        case noAppUpdate

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .appUpdate(let _data):
                if boxed {
                    buffer.appendInt32(-860107216)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeInt32(_data.id, buffer: buffer, boxed: false)
                serializeString(_data.version, buffer: buffer, boxed: false)
                serializeString(_data.text, buffer: buffer, boxed: false)
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.entities.count))
                for item in _data.entities {
                    item.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    _data.document!.serialize(buffer, true)
                }
                if Int(_data.flags) & Int(1 << 2) != 0 {
                    serializeString(_data.url!, buffer: buffer, boxed: false)
                }
                if Int(_data.flags) & Int(1 << 3) != 0 {
                    _data.sticker!.serialize(buffer, true)
                }
                break
            case .noAppUpdate:
                if boxed {
                    buffer.appendInt32(-1000708810)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .appUpdate(let _data):
                return ("appUpdate", [("flags", ConstructorParameterDescription(_data.flags)), ("id", ConstructorParameterDescription(_data.id)), ("version", ConstructorParameterDescription(_data.version)), ("text", ConstructorParameterDescription(_data.text)), ("entities", ConstructorParameterDescription(_data.entities)), ("document", ConstructorParameterDescription(_data.document)), ("url", ConstructorParameterDescription(_data.url)), ("sticker", ConstructorParameterDescription(_data.sticker))])
            case .noAppUpdate:
                return ("noAppUpdate", [])
            }
        }

        public static func parse_appUpdate(_ reader: BufferReader) -> AppUpdate? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            _4 = parseString(reader)
            var _5: [Api.MessageEntity]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.MessageEntity.self)
            }
            var _6: Api.Document?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let signature = reader.readInt32() {
                    _6 = Api.parse(reader, signature: signature) as? Api.Document
                }
            }
            var _7: String?
            if Int(_1 ?? 0) & Int(1 << 2) != 0 {
                _7 = parseString(reader)
            }
            var _8: Api.Document?
            if Int(_1 ?? 0) & Int(1 << 3) != 0 {
                if let signature = reader.readInt32() {
                    _8 = Api.parse(reader, signature: signature) as? Api.Document
                }
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _6 != nil
            let _c7 = (Int(_1 ?? 0) & Int(1 << 2) == 0) || _7 != nil
            let _c8 = (Int(_1 ?? 0) & Int(1 << 3) == 0) || _8 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 {
                return Api.help.AppUpdate.appUpdate(Cons_appUpdate(flags: _1!, id: _2!, version: _3!, text: _4!, entities: _5!, document: _6, url: _7, sticker: _8))
            }
            else {
                return nil
            }
        }
        public static func parse_noAppUpdate(_ reader: BufferReader) -> AppUpdate? {
            return Api.help.AppUpdate.noAppUpdate
        }
    }
}
public extension Api.help {
    enum CountriesList: TypeConstructorDescription {
        public class Cons_countriesList: TypeConstructorDescription {
            public var countries: [Api.help.Country]
            public var hash: Int32
            public init(countries: [Api.help.Country], hash: Int32) {
                self.countries = countries
                self.hash = hash
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("countriesList", [("countries", ConstructorParameterDescription(self.countries)), ("hash", ConstructorParameterDescription(self.hash))])
            }
        }
        case countriesList(Cons_countriesList)
        case countriesListNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .countriesList(let _data):
                if boxed {
                    buffer.appendInt32(-2016381538)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.countries.count))
                for item in _data.countries {
                    item.serialize(buffer, true)
                }
                serializeInt32(_data.hash, buffer: buffer, boxed: false)
                break
            case .countriesListNotModified:
                if boxed {
                    buffer.appendInt32(-1815339214)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .countriesList(let _data):
                return ("countriesList", [("countries", ConstructorParameterDescription(_data.countries)), ("hash", ConstructorParameterDescription(_data.hash))])
            case .countriesListNotModified:
                return ("countriesListNotModified", [])
            }
        }

        public static func parse_countriesList(_ reader: BufferReader) -> CountriesList? {
            var _1: [Api.help.Country]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.help.Country.self)
            }
            var _2: Int32?
            _2 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.help.CountriesList.countriesList(Cons_countriesList(countries: _1!, hash: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_countriesListNotModified(_ reader: BufferReader) -> CountriesList? {
            return Api.help.CountriesList.countriesListNotModified
        }
    }
}
public extension Api.help {
    enum Country: TypeConstructorDescription {
        public class Cons_country: TypeConstructorDescription {
            public var flags: Int32
            public var iso2: String
            public var defaultName: String
            public var name: String?
            public var countryCodes: [Api.help.CountryCode]
            public init(flags: Int32, iso2: String, defaultName: String, name: String?, countryCodes: [Api.help.CountryCode]) {
                self.flags = flags
                self.iso2 = iso2
                self.defaultName = defaultName
                self.name = name
                self.countryCodes = countryCodes
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("country", [("flags", ConstructorParameterDescription(self.flags)), ("iso2", ConstructorParameterDescription(self.iso2)), ("defaultName", ConstructorParameterDescription(self.defaultName)), ("name", ConstructorParameterDescription(self.name)), ("countryCodes", ConstructorParameterDescription(self.countryCodes))])
            }
        }
        case country(Cons_country)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .country(let _data):
                if boxed {
                    buffer.appendInt32(-1014526429)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeString(_data.iso2, buffer: buffer, boxed: false)
                serializeString(_data.defaultName, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    serializeString(_data.name!, buffer: buffer, boxed: false)
                }
                buffer.appendInt32(481674261)
                buffer.appendInt32(Int32(_data.countryCodes.count))
                for item in _data.countryCodes {
                    item.serialize(buffer, true)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .country(let _data):
                return ("country", [("flags", ConstructorParameterDescription(_data.flags)), ("iso2", ConstructorParameterDescription(_data.iso2)), ("defaultName", ConstructorParameterDescription(_data.defaultName)), ("name", ConstructorParameterDescription(_data.name)), ("countryCodes", ConstructorParameterDescription(_data.countryCodes))])
            }
        }

        public static func parse_country(_ reader: BufferReader) -> Country? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                _4 = parseString(reader)
            }
            var _5: [Api.help.CountryCode]?
            if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 0, elementType: Api.help.CountryCode.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.help.Country.country(Cons_country(flags: _1!, iso2: _2!, defaultName: _3!, name: _4, countryCodes: _5!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.help {
    enum CountryCode: TypeConstructorDescription {
        public class Cons_countryCode: TypeConstructorDescription {
            public var flags: Int32
            public var countryCode: String
            public var prefixes: [String]?
            public var patterns: [String]?
            public init(flags: Int32, countryCode: String, prefixes: [String]?, patterns: [String]?) {
                self.flags = flags
                self.countryCode = countryCode
                self.prefixes = prefixes
                self.patterns = patterns
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("countryCode", [("flags", ConstructorParameterDescription(self.flags)), ("countryCode", ConstructorParameterDescription(self.countryCode)), ("prefixes", ConstructorParameterDescription(self.prefixes)), ("patterns", ConstructorParameterDescription(self.patterns))])
            }
        }
        case countryCode(Cons_countryCode)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .countryCode(let _data):
                if boxed {
                    buffer.appendInt32(1107543535)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeString(_data.countryCode, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 0) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.prefixes!.count))
                    for item in _data.prefixes! {
                        serializeString(item, buffer: buffer, boxed: false)
                    }
                }
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.patterns!.count))
                    for item in _data.patterns! {
                        serializeString(item, buffer: buffer, boxed: false)
                    }
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .countryCode(let _data):
                return ("countryCode", [("flags", ConstructorParameterDescription(_data.flags)), ("countryCode", ConstructorParameterDescription(_data.countryCode)), ("prefixes", ConstructorParameterDescription(_data.prefixes)), ("patterns", ConstructorParameterDescription(_data.patterns))])
            }
        }

        public static func parse_countryCode(_ reader: BufferReader) -> CountryCode? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: [String]?
            if Int(_1 ?? 0) & Int(1 << 0) != 0 {
                if let _ = reader.readInt32() {
                    _3 = Api.parseVector(reader, elementSignature: -1255641564, elementType: String.self)
                }
            }
            var _4: [String]?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let _ = reader.readInt32() {
                    _4 = Api.parseVector(reader, elementSignature: -1255641564, elementType: String.self)
                }
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 0) == 0) || _3 != nil
            let _c4 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.help.CountryCode.countryCode(Cons_countryCode(flags: _1!, countryCode: _2!, prefixes: _3, patterns: _4))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.help {
    enum DeepLinkInfo: TypeConstructorDescription {
        public class Cons_deepLinkInfo: TypeConstructorDescription {
            public var flags: Int32
            public var message: String
            public var entities: [Api.MessageEntity]?
            public init(flags: Int32, message: String, entities: [Api.MessageEntity]?) {
                self.flags = flags
                self.message = message
                self.entities = entities
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("deepLinkInfo", [("flags", ConstructorParameterDescription(self.flags)), ("message", ConstructorParameterDescription(self.message)), ("entities", ConstructorParameterDescription(self.entities))])
            }
        }
        case deepLinkInfo(Cons_deepLinkInfo)
        case deepLinkInfoEmpty

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .deepLinkInfo(let _data):
                if boxed {
                    buffer.appendInt32(1783556146)
                }
                serializeInt32(_data.flags, buffer: buffer, boxed: false)
                serializeString(_data.message, buffer: buffer, boxed: false)
                if Int(_data.flags) & Int(1 << 1) != 0 {
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(_data.entities!.count))
                    for item in _data.entities! {
                        item.serialize(buffer, true)
                    }
                }
                break
            case .deepLinkInfoEmpty:
                if boxed {
                    buffer.appendInt32(1722786150)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .deepLinkInfo(let _data):
                return ("deepLinkInfo", [("flags", ConstructorParameterDescription(_data.flags)), ("message", ConstructorParameterDescription(_data.message)), ("entities", ConstructorParameterDescription(_data.entities))])
            case .deepLinkInfoEmpty:
                return ("deepLinkInfoEmpty", [])
            }
        }

        public static func parse_deepLinkInfo(_ reader: BufferReader) -> DeepLinkInfo? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: [Api.MessageEntity]?
            if Int(_1 ?? 0) & Int(1 << 1) != 0 {
                if let _ = reader.readInt32() {
                    _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.MessageEntity.self)
                }
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1 ?? 0) & Int(1 << 1) == 0) || _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.help.DeepLinkInfo.deepLinkInfo(Cons_deepLinkInfo(flags: _1!, message: _2!, entities: _3))
            }
            else {
                return nil
            }
        }
        public static func parse_deepLinkInfoEmpty(_ reader: BufferReader) -> DeepLinkInfo? {
            return Api.help.DeepLinkInfo.deepLinkInfoEmpty
        }
    }
}
public extension Api.help {
    enum InviteText: TypeConstructorDescription {
        public class Cons_inviteText: TypeConstructorDescription {
            public var message: String
            public init(message: String) {
                self.message = message
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("inviteText", [("message", ConstructorParameterDescription(self.message))])
            }
        }
        case inviteText(Cons_inviteText)

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .inviteText(let _data):
                if boxed {
                    buffer.appendInt32(415997816)
                }
                serializeString(_data.message, buffer: buffer, boxed: false)
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .inviteText(let _data):
                return ("inviteText", [("message", ConstructorParameterDescription(_data.message))])
            }
        }

        public static func parse_inviteText(_ reader: BufferReader) -> InviteText? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.help.InviteText.inviteText(Cons_inviteText(message: _1!))
            }
            else {
                return nil
            }
        }
    }
}
public extension Api.help {
    enum PassportConfig: TypeConstructorDescription {
        public class Cons_passportConfig: TypeConstructorDescription {
            public var hash: Int32
            public var countriesLangs: Api.DataJSON
            public init(hash: Int32, countriesLangs: Api.DataJSON) {
                self.hash = hash
                self.countriesLangs = countriesLangs
            }
            public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
                return ("passportConfig", [("hash", ConstructorParameterDescription(self.hash)), ("countriesLangs", ConstructorParameterDescription(self.countriesLangs))])
            }
        }
        case passportConfig(Cons_passportConfig)
        case passportConfigNotModified

        public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
            switch self {
            case .passportConfig(let _data):
                if boxed {
                    buffer.appendInt32(-1600596305)
                }
                serializeInt32(_data.hash, buffer: buffer, boxed: false)
                _data.countriesLangs.serialize(buffer, true)
                break
            case .passportConfigNotModified:
                if boxed {
                    buffer.appendInt32(-1078332329)
                }
                break
            }
        }

        public func descriptionFields() -> (String, [(String, ConstructorParameterDescription)]) {
            switch self {
            case .passportConfig(let _data):
                return ("passportConfig", [("hash", ConstructorParameterDescription(_data.hash)), ("countriesLangs", ConstructorParameterDescription(_data.countriesLangs))])
            case .passportConfigNotModified:
                return ("passportConfigNotModified", [])
            }
        }

        public static func parse_passportConfig(_ reader: BufferReader) -> PassportConfig? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.DataJSON?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.DataJSON
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.help.PassportConfig.passportConfig(Cons_passportConfig(hash: _1!, countriesLangs: _2!))
            }
            else {
                return nil
            }
        }
        public static func parse_passportConfigNotModified(_ reader: BufferReader) -> PassportConfig? {
            return Api.help.PassportConfig.passportConfigNotModified
        }
    }
}
