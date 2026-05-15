#if canImport(SwiftUI)
import SwiftUI

public extension Pigment {
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
#endif
