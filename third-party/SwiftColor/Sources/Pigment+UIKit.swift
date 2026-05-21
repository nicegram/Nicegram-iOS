import Foundation
#if canImport(UIKit)
import UIKit

public extension Pigment {
    init(_ color: UIColor) {
        var redComponent: CGFloat = 1.0
        var greenComponent: CGFloat = 1.0
        var blueComponent: CGFloat = 1.0
        var alphaComponent: CGFloat = 1.0

        guard color.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha: &alphaComponent) else {
            // TODO: Fail Initializer? Default Colors?
            red = redComponent
            green = greenComponent
            blue = blueComponent
            alpha = alphaComponent
            return
        }

        red = redComponent
        green = greenComponent
        blue = blueComponent
        alpha = alphaComponent
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

public extension UIColor {
    var pigment: Pigment {
        Pigment(self)
    }
}
#endif
