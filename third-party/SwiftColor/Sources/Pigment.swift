/// A platform agnostic representation of Color
///
/// The components - red, green, blue, & alpha - are maintained as a floating-point representation.
/// Each value can range from 0.0 to 1.0 (e.g. 0 to 100 percent).
///
/// 'Pure White' is represented by values all equal to **1.0**.
public struct Pigment: Sendable {

    public let colorSpace: ColorSpace = .rgba
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(
        @Clamping(0 ... 1) red: Double = 1.0,
        @Clamping(0 ... 1) green: Double = 1.0,
        @Clamping(0 ... 1) blue: Double = 1.0,
        @Clamping(0 ... 1) alpha: Double = 1.0
    ) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

extension Pigment: CustomStringConvertible {
    public var description: String {
        String(format: "Pigment(red: %.4f, green: %.4f, blue: %.4f, alpha: %.2f)", red, green, blue, alpha)
    }
}

extension Pigment: Equatable {
    public static func == (lhs: Pigment, rhs: Pigment) -> Bool {
        guard lhs.red == rhs.red else {
            return false
        }
        guard lhs.green == rhs.green else {
            return false
        }
        guard lhs.blue == rhs.blue else {
            return false
        }
        guard lhs.alpha == rhs.alpha else {
            return false
        }
        guard lhs.colorSpace == rhs.colorSpace else {
            return false
        }
        return true
    }
}
