import Foundation

public extension Pigment {
    /// Initializes a `Pigment` with an `Int` in the expected format of **0x000**.
    ///
    /// Used as a short-hand. If the hex 0x123 is provided, it is interpreted as 0x112233.
    init(
        hex3 hex: Int,
        @Clamping(0 ... 1) alpha: Double = 1.0
    ) {
        let values = Self.hex3(hex: hex, alpha: alpha)
        red = values.red
        green = values.green
        blue = values.blue
        self.alpha = values.alpha
    }

    /// Shorthand **0x0000** initializer similar to `init(hex3:alpha:)` where
    /// the last digit represent the alpha component.
    init(
        hex4 hex: Int
    ) {
        let values = Self.hex4(hex: hex)
        red = values.red
        green = values.green
        blue = values.blue
        alpha = values.alpha
    }

    /// Initializes with a standard format hex representation of color in the form of **0x1E2C3D**.
    init(
        hex6 hex: Int,
        @Clamping(0 ... 1) alpha: Double = 1.0
    ) {
        let values = Self.hex6(hex: hex, alpha: alpha)
        red = values.red
        green = values.green
        blue = values.blue
        self.alpha = values.alpha
    }

    #if !os(watchOS)
    /// Extended form of `init(hex6:alpha:)` expecting **0x112233FF**, that uses the last
    /// bits for the alpha component.
    init(
        hex8 hex: Int
    ) {
        let values = Self.hex8(hex: hex)
        red = values.red
        green = values.green
        blue = values.blue
        alpha = values.alpha
    }
    #endif

    /// Initializes a `Pigment` with an `Int` representation of an RGB(a) Hex Value
    ///
    /// This initializer will do its best to interpret the intentions of what is provided.
    /// **YOUR RESULTS WILL VARY**, and it's best to use one of the `init(hex?:)` initializers.
    ///
    /// - Parameter hex: Hex value
    /// - Parameter alpha: The opacity value of the color object
    init(
        _ hex: Int,
        alpha: Double? = nil
    ) {
        #if !os(watchOS)
        if hex > 0xFFFFFF {
            let values = Self.hex8(hex: hex)
            red = values.red
            green = values.green
            blue = values.blue
            self.alpha = values.alpha
            return
        }
        #endif
        if hex > 0xFFFF {
            let values = Self.hex6(hex: hex, alpha: alpha ?? 1.0)
            red = values.red
            green = values.green
            blue = values.blue
            self.alpha = values.alpha
        } else if hex > 0xFFF {
            let values = Self.hex4(hex: hex)
            red = values.red
            green = values.green
            blue = values.blue
            self.alpha = values.alpha
        } else {
            let values = Self.hex3(hex: hex, alpha: alpha ?? 1.0)
            red = values.red
            green = values.green
            blue = values.blue
            self.alpha = values.alpha
        }
    }
}

extension Pigment {
    static func hex3(
        hex: Int,
        @Clamping(0 ... 1) alpha: Double = 1.0
    ) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        let red = Double(duplicateBits((hex & 0xF00) >> 8)) / 255.0
        let green = Double(duplicateBits((hex & 0x0F0) >> 4)) / 255.0
        let blue = Double(duplicateBits((hex & 0x00F) >> 0)) / 255.0
        return (red, green, blue, alpha)
    }

    static func hex4(
        hex: Int
    ) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        let red = Double(duplicateBits((hex & 0xF000) >> 12)) / 255.0
        let green = Double(duplicateBits((hex & 0x0F00) >> 8)) / 255.0
        let blue = Double(duplicateBits((hex & 0x00F0) >> 4)) / 255.0
        let alpha = Double(duplicateBits((hex & 0x000F) >> 0)) / 255.0
        return (red, green, blue, alpha)
    }

    static func hex6(
        hex: Int,
        @Clamping(0 ... 1) alpha: Double = 1.0
    ) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0x00FF00) >> 8) / 255.0
        let blue = Double((hex & 0x0000FF) >> 0) / 255.0
        return (red, green, blue, alpha)
    }

    #if !os(watchOS)
    static func hex8(
        hex: Int
    ) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        let red = Double((hex & 0xFF00_0000) >> 24) / 255.0
        let green = Double((hex & 0x00FF_0000) >> 16) / 255.0
        let blue = Double((hex & 0x0000_FF00) >> 8) / 255.0
        let alpha = Double((hex & 0x0000_00FF) >> 0) / 255.0
        return (red, green, blue, alpha)
    }
    #endif

    static func duplicateBits(_ value: Int) -> Int {
        (value << 4) + value
    }
}
