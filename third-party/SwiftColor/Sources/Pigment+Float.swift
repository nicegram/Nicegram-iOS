import Foundation

public extension Pigment {
    /// Initialize a `Pigment` using `Float` values leaning towards the 'Red' spectrum.
    ///
    /// - parameters
    ///   - red: A value in the range of 0.0 to 1.0 representing the **red** percent.
    ///   - green: A value in the range of 0.0 to 1.0 representing the **green** percent.
    ///   - blue: A value in the range of 0.0 to 1.0 representing the **blue** percent.
    ///   - alpha: A value in the range of 0.0 to 1.0 representing the **alpha/opacity/transparency** percent.
    init(
        red: Float,
        green: Float = 0.0,
        blue: Float = 0.0,
        alpha: Float = 1.0
    ) {
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.alpha = Double(alpha)
    }

    /// Initialize a `Pigment` using `Float` values leaning towards the 'Green' spectrum.
    ///
    /// - parameters:
    ///   - green: A value in the range of 0.0 to 1.0 representing the **green** percent.
    ///   - blue: A value in the range of 0.0 to 1.0 representing the **blue** percent.
    ///   - red: A value in the range of 0.0 to 1.0 representing the **red** percent.
    ///   - alpha: A value in the range of 0.0 to 1.0 representing the **alpha/opacity/transparency** percent.
    init(
        green: Float,
        blue: Float = 0.0,
        red: Float = 0.0,
        alpha: Float = 1.0
    ) {
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.alpha = Double(alpha)
    }

    /// Initialize a `Pigment` using `Float` values leaning towards the 'Blue' spectrum.
    ///
    /// - parameter:
    ///   - blue: A value in the range of 0.0 to 1.0 representing the **blue** percent.
    ///   - red: A value in the range of 0.0 to 1.0 representing the **red** percent.
    ///   - green: A value in the range of 0.0 to 1.0 representing the **green** percent.
    ///   - alpha: A value in the range of 0.0 to 1.0 representing the **alpha/opacity/transparency** percent.
    init(
        blue: Float,
        red: Float = 0.0,
        green: Float = 0.0,
        alpha: Float = 1.0
    ) {
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.alpha = Double(alpha)
    }

    /// Initialize a `Pigment` using variadic `Float` values.
    ///
    /// All _values_ should be expressed in the range of 0.0 to 1.0.
    ///
    /// - parameters:
    ///   - values: A number of `Float` which are mapped to **red**, **green**, **blue** in that order.
    ///   - alpha: Amount of _opacity/transparency_ to apply.
    init(
        _ values: Float...,
        alpha: Float
    ) {
        if values.count > 0 {
            red = Double(values[0].clamped(to: 0 ... 1))
        } else {
            red = 0.0
        }
        if values.count > 1 {
            green = Double(values[1].clamped(to: 0 ... 1))
        } else {
            green = 0.0
        }
        if values.count > 2 {
            blue = Double(values[2].clamped(to: 0 ... 1))
        } else {
            blue = 0.0
        }
        self.alpha = Double(alpha.clamped(to: 0 ... 1))
    }
}

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(range.lowerBound, self), range.upperBound)
    }
}
