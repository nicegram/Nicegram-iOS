import Foundation
import Postbox

public final class AccountNicegramAttribute: Codable, Equatable {
    public var exported: Bool
    public var imported: Bool
    public var skipRemoteLogout: Bool
    
    public init(
        exported: Bool = false,
        imported: Bool = false,
        skipRemoteLogout: Bool = false
    ) {
        self.exported = exported
        self.imported = imported
        self.skipRemoteLogout = skipRemoteLogout
    }

    public static func ==(lhs: AccountNicegramAttribute, rhs: AccountNicegramAttribute) -> Bool {
        lhs.exported == rhs.exported &&
        lhs.imported == rhs.imported &&
        lhs.skipRemoteLogout == rhs.skipRemoteLogout
    }
}

public extension [TelegramAccountManagerTypes.Attribute] {
    func nicegramAttribute() -> AccountNicegramAttribute {
        for attribute in self {
            if case let .nicegram(nicegram) = attribute {
                return nicegram
            }
        }
        return AccountNicegramAttribute()
    }
    
    mutating func updateNicegramAttribute(
        modifier: (inout AccountNicegramAttribute) -> Void
    ) {
        func updater(_ attribute: AccountNicegramAttribute) -> AccountNicegramAttribute {
            var updatedAttribute = attribute
            modifier(&updatedAttribute)
            return updatedAttribute
        }
        
        var found = false
        for (index, attribute) in self.enumerated() {
            if case let .nicegram(nicegram) = attribute {
                self[index] = .nicegram(updater(nicegram))
                found = true
            }
        }
        
        if !found {
            let attribute = updater(AccountNicegramAttribute())
            self.append(.nicegram(attribute))
        }
    }
}

public extension [TelegramAccountManagerTypes.Attribute] {
    var sortOrder: Int32 {
        get {
            for attribute in self {
                if case let .sortOrder(sortOrder) = attribute {
                    return sortOrder.order
                }
            }
            return .min
        } set {
            let newAttr = TelegramAccountManagerTypes.Attribute.sortOrder(.init(order: newValue))
            
            var found = false
            for (index, attribute) in self.enumerated() {
                if case let .sortOrder(sortOrder) = attribute {
                    self[index] = newAttr
                    found = true
                }
            }
            
            if !found {
                self.append(newAttr)
            }
        }
    }
}

public extension AccountRecord {
    func with(attributes: [Attribute]) -> AccountRecord {
        AccountRecord(id: id, attributes: attributes, temporarySessionId: temporarySessionId)
    }
}
