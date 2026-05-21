public protocol CoreAttributes {
    var id: String? { get set }
}

enum CoreAttributesKeys: String, CodingKey {
    case id
}

public extension CoreAttributes {
    var coreDescription: String {
        if let id {
            "\(CoreAttributesKeys.id.rawValue)=\"\(id)\""
        } else {
            ""
        }
    }
}
