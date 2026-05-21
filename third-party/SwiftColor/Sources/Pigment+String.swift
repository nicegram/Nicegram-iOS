import Foundation

public extension Pigment {
    init(_ value: String, alpha: Double = 1.0) {
        if let keyword = Name.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(value) == .orderedSame }) {
            red = keyword.pigment.red
            green = keyword.pigment.green
            blue = keyword.pigment.blue
            self.alpha = alpha
            return
        }

        if ExtendedKeyword.allCases.contains(where: { $0.rawValue.caseInsensitiveCompare(value) == .orderedSame }) {
            red = 1.0
            green = 1.0
            blue = 1.0
            self.alpha = alpha
            return
        }

        var hex = value
        if hex.hasPrefix("#") {
            hex = String(hex.dropFirst())
        }

        guard let hexValue = Int(hex, radix: 16) else {
            red = 1.0
            green = 1.0
            blue = 1.0
            self.alpha = alpha
            return
        }

        switch hex.count {
        case 3:
            let values = Self.hex3(hex: hexValue)
            red = values.red
            green = values.green
            blue = values.blue
            self.alpha = values.alpha
        case 4:
            let values = Self.hex4(hex: hexValue)
            red = values.red
            green = values.green
            blue = values.blue
            self.alpha = values.alpha
        case 6:
            let values = Self.hex6(hex: hexValue, alpha: alpha)
            red = values.red
            green = values.green
            blue = values.blue
            self.alpha = values.alpha
        #if !os(watchOS)
        case 8:
            let values = Self.hex8(hex: hexValue)
            red = values.red
            green = values.green
            blue = values.blue
            self.alpha = values.alpha
        #endif
        default:
            red = 1.0
            green = 1.0
            blue = 1.0
            self.alpha = alpha
        }
    }
}

private extension Pigment {
    enum ExtendedKeyword: String, CaseIterable {
        case none
        case clear
        case transparent
    }
}
