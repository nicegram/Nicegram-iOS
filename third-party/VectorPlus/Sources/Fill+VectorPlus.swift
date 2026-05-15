import SwiftColor
import SwiftSVG

public extension Fill {
    @available(*, deprecated, renamed: "pigment")
    var swiftColor: Pigment? { pigment }

    var pigment: Pigment? {
        guard let color, !color.isEmpty else {
            return nil
        }

        let _color = Pigment(color)
        guard _color.alpha != 0.0 else {
            return nil
        }

        return _color
    }
}

public extension Fill.Rule {
    var coreGraphicsDescription: String {
        switch self {
        case .evenOdd: ".evenOdd"
        case .nonZero: ".winding"
        }
    }
}
