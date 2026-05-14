import SwiftColor
import SwiftSVG

public extension Stroke {
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

public extension Stroke.LineCap {
    var coreGraphicsDescription: String {
        switch self {
        case .butt: ".butt"
        case .round: ".round"
        case .square: ".square"
        }
    }
}

public extension Stroke.LineJoin {
    var coreGraphicsDescription: String {
        switch self {
        case .bevel: ".bevel"
        case .arcs, .miter, .miterClip: ".miter"
        case .round: ".round"
        }
    }
}
