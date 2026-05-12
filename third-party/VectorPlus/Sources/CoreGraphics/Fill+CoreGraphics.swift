import Foundation
import SwiftSVG
#if canImport(CoreGraphics)
import CoreGraphics

public extension Fill.Rule {
    var cgFillRule: CGPathFillRule {
        switch self {
        case .evenOdd: .evenOdd
        case .nonZero: .winding
        }
    }
}
#endif
