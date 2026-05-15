import Foundation
import SwiftSVG
#if canImport(CoreGraphics)
import CoreGraphics

public extension Stroke.LineCap {
    var cgLineCap: CGLineCap {
        switch self {
        case .butt: .butt
        case .round: .round
        case .square: .square
        }
    }
}

public extension Stroke.LineJoin {
    var cgLineJoin: CGLineJoin {
        switch self {
        case .bevel: .bevel
        case .arcs, .miter, .miterClip: .miter
        case .round: .round
        }
    }
}
#endif
