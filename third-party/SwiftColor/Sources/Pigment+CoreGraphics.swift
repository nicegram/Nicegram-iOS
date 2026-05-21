import Foundation
#if canImport(CoreGraphics)
import CoreGraphics

public extension Pigment {
    /// Initialize a `Pigment` using an `CGColor`.
    init?(_ color: CGColor) {
        let components = color.components ?? []
        switch components.count {
        case 2:
            // Monochrome/Grayscale
            // TODO: Express this in 'Color'.
            red = 0.0
            green = 0.0
            blue = 0.0
            alpha = components[1]
        case 4:
            // RGB
            red = components[0]
            green = components[1]
            blue = components[2]
            alpha = components[3]
        default:
            return nil
        }
    }
}

public extension CGColor {
    static func make(_ color: Pigment) -> CGColor {
        if color.red == 0.0, color.green == 0.0, color.blue == 0.0, color.alpha == 0.0 {
            // Return the CG color equivalent of `UIColor.clear`.
            return CGColor(genericGrayGamma2_2Gray: 0.0, alpha: 0.0)
        }

        return CGColor(srgbRed: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
    }
}
#endif
