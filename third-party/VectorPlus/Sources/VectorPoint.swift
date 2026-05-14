import Swift2D

/// A cartesian-based struct that describes the relationship of any particular `Point` to the _origin_ of a `Rect`.
public struct VectorPoint {
    public enum Sign: String {
        case plus = "+"
        case minus = "-"
    }

    public typealias Offset = (sign: Sign, multiplier: Double)

    public var x: Offset
    public var y: Offset

    public init(x: Offset, y: Offset) {
        self.x = x
        self.y = y
    }

    /// Initializes a `VectorPoint` for a given `Point` container in the provided `Rect`.
    public init(point: Point, in rect: Rect) {
        let radius = rect.size.maxRadius
        let cartesianPoint = Self.cartesianPoint(for: point, in: rect)

        if cartesianPoint.x < 0 {
            x = (.minus, abs(cartesianPoint.x) / radius)
        } else {
            x = (.plus, cartesianPoint.x / radius)
        }

        if cartesianPoint.y < 0 {
            y = (.plus, abs(cartesianPoint.y) / radius)
        } else {
            y = (.minus, cartesianPoint.y / radius)
        }
    }
}

// MARK: - CustomStringConvertible

extension VectorPoint: CustomStringConvertible {
    public var description: String {
        "VectorPoint(x: (\(x.sign.rawValue), \(x.multiplier)), y: (\(y.sign.rawValue), \(y.multiplier)))"
    }
}

// MARK: - Equatable

extension VectorPoint: Equatable {
    public static func == (lhs: VectorPoint, rhs: VectorPoint) -> Bool {
        guard lhs.x.sign == rhs.x.sign else {
            return false
        }
        guard lhs.x.multiplier == rhs.x.multiplier else {
            return false
        }
        guard lhs.y.sign == rhs.y.sign else {
            return false
        }
        guard lhs.y.multiplier == rhs.y.multiplier else {
            return false
        }

        return true
    }
}

// MARK: -

public extension VectorPoint {
    /// Translates the provided point within the `Rect` from using the top-left
    /// as the _origin_, to using the center as the _origin_.
    ///
    /// For example: Given `Rect(x: 0, y: 0, width: 100, height: 100)`, the point
    /// `Point(x: 25, y: 25)` would translate to `Point(x: -25, y: 25)`.
    static func cartesianPoint(for point: Point, in rect: Rect) -> Point {
        let origin = Point(x: rect.size.width / 2.0, y: rect.size.height / 2.0)
        var cartesianPoint: Point = .zero

        if point.x < origin.x {
            cartesianPoint = cartesianPoint.x(-(origin.x - point.x))
        } else if point.x > origin.x {
            cartesianPoint = cartesianPoint.x(point.x - origin.x)
        }

        if point.y > origin.y {
            cartesianPoint = cartesianPoint.y(-(point.y - origin.y))
        } else if point.y < origin.y {
            cartesianPoint = cartesianPoint.y(origin.y - point.y)
        }

        return cartesianPoint
    }
}

// MARK: - Instance Functionality

public extension VectorPoint {
    /// Calculates the `Point` for this instance in the specified `Rect`.
    func translate(to rect: Rect) -> Point {
        translate(to: rect.size)
    }

    /// Calculates the `Point` in the desired output size
    func translate(to outputSize: Size) -> Point {
        let center = outputSize.center
        let radius = outputSize.minRadius

        switch (x.sign, y.sign) {
        case (.plus, .plus):
            return Point(x: center.x + (radius * x.multiplier), y: center.y + (radius * y.multiplier))
        case (.plus, .minus):
            return Point(x: center.x + (radius * x.multiplier), y: center.y - (radius * y.multiplier))
        case (.minus, .plus):
            return Point(x: center.x - (radius * x.multiplier), y: center.y + (radius * y.multiplier))
        case (.minus, .minus):
            return Point(x: center.x - (radius * x.multiplier), y: center.y - (radius * y.multiplier))
        }
    }
}

public extension VectorPoint {
    var coreGraphicsDescription: String {
        "CGPoint(x: center.x \(x.sign.rawValue) (radius * \(x.multiplier)), y: center.y \(y.sign.rawValue) (radius * \(y.multiplier)))"
    }
}
