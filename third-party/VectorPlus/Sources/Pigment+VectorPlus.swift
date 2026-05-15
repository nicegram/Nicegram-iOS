import SwiftColor

public extension Pigment {
    var coreGraphicsDescription: String {
        "CGColor(srgbRed: \(red), green: \(green), blue: \(blue), alpha: \(alpha))"
    }
}
