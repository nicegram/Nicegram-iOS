public protocol StylingAttributes {
    var style: String? { get set }
}

enum StylingAttributesKeys: String, CodingKey {
    case style
}

public extension StylingAttributes {
    var stylingDescription: String {
        if let style {
            "\(StylingAttributesKeys.style.rawValue)=\"\(style)\""
        } else {
            ""
        }
    }
}
