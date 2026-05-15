import Foundation
import Swift2D

public extension Path {
    /// Path commands are instructions that define a path to be drawn.
    ///
    /// Each command is composed of a command letter and numbers that represent the command parameters.
    enum Command: Equatable, Sendable, CustomStringConvertible {
        /// Moves the current drawing point
        case moveTo(point: Point)
        /// Draw a straight line from the current point to the point provided
        case lineTo(point: Point)
        /// Draw a smooth curve using three points (+ origin)
        case cubicBezierCurve(cp1: Point, cp2: Point, point: Point)
        /// Draw a smooth curve using two points (+ origin)
        case quadraticBezierCurve(cp: Point, point: Point)
        /// Draw a curve defined as a portion of an ellipse
        case ellipticalArcCurve(rx: Double, ry: Double, angle: Double, largeArc: Bool, clockwise: Bool, point: Point)
        /// ClosePath instructions draw a straight line from the current position to the first point in the path.
        case closePath

        public enum Prefix: Character, CaseIterable {
            case move = "M"
            case relativeMove = "m"
            case line = "L"
            case relativeLine = "l"
            case horizontalLine = "H"
            case relativeHorizontalLine = "h"
            case verticalLine = "V"
            case relativeVerticalLine = "v"
            case cubicBezierCurve = "C"
            case relativeCubicBezierCurve = "c"
            case smoothCubicBezierCurve = "S"
            case relativeSmoothCubicBezierCurve = "s"
            case quadraticBezierCurve = "Q"
            case relativeQuadraticBezierCurve = "q"
            case smoothQuadraticBezierCurve = "T"
            case relativeSmoothQuadraticBezierCurve = "t"
            case ellipticalArcCurve = "A"
            case relativeEllipticalArcCurve = "a"
            case close = "Z"
            case relativeClose = "z"

            public static var characterSet: CharacterSet {
                CharacterSet(charactersIn: allCases.map { String($0.rawValue) }.joined())
            }
        }

        public enum Coordinates {
            case absolute
            case relative
        }

        public enum Error: Swift.Error {
            case message(String)
            case invalidAdjustment(Path.Command)
            case invalidArgumentPosition(Int, Path.Command)
            case invalidRelativeCommand
        }

        public var description: String {
            switch self {
            case .moveTo(let point):
                return "\(Prefix.move.rawValue)\(point.x),\(point.y)"
            case .lineTo(let point):
                return "\(Prefix.line.rawValue)\(point.x),\(point.y)"
            case .cubicBezierCurve(let cp1, let cp2, let point):
                return "\(Prefix.cubicBezierCurve.rawValue)\(cp1.x),\(cp1.y) \(cp2.x),\(cp2.y) \(point.x),\(point.y)"
            case .quadraticBezierCurve(let cp, let point):
                return "\(Prefix.quadraticBezierCurve.rawValue)\(cp.x),\(cp.y) \(point.x),\(point.y)"
            case .ellipticalArcCurve(let rx, let ry, let angle, let largeArc, let clockwise, let point):
                let la = largeArc ? 1 : 0
                let cw = clockwise ? 1 : 0
                return "\(Prefix.ellipticalArcCurve.rawValue)\(rx) \(ry) \(angle) \(la) \(cw) \(point.x) \(point.y)"
            case .closePath:
                return "\(Prefix.close.rawValue)"
            }
        }

        /// The primary point that dictates the commands action.
        public var point: Point {
            switch self {
            case .moveTo(let point): point
            case .lineTo(let point): point
            case .cubicBezierCurve(_, _, let point): point
            case .quadraticBezierCurve(_, let point): point
            case .ellipticalArcCurve(_, _, _, _, _, let point): point
            case .closePath: .zero
            }
        }
    }
}

public extension Path.Command {
    /// Applies the provided `Transformation` to the instances values.
    func applying(transformation: Transformation) -> Path.Command {
        switch transformation {
        case .translate(let x, let y):
            switch self {
            case .moveTo(let point):
                let _point = point.adjusting(x: x).adjusting(y: y)
                return .moveTo(point: _point)
            case .lineTo(let point):
                let _point = point.adjusting(x: x).adjusting(y: y)
                return .lineTo(point: _point)
            case .cubicBezierCurve(let cp1, let cp2, let point):
                let _cp1 = cp1.adjusting(x: x).adjusting(y: y)
                let _cp2 = cp2.adjusting(x: x).adjusting(y: y)
                let _point = point.adjusting(x: x).adjusting(y: y)
                return .cubicBezierCurve(cp1: _cp1, cp2: _cp2, point: _point)
            case .quadraticBezierCurve(let cp, let point):
                let _cp = cp.adjusting(x: x).adjusting(y: y)
                let _point = point.adjusting(x: x).adjusting(y: y)
                return .quadraticBezierCurve(cp: _cp, point: _point)
            case .ellipticalArcCurve(let rx, let ry, let angle, let largeArc, let clockwise, let point):
                let _point = point.adjusting(x: x).adjusting(y: y)
                return .ellipticalArcCurve(rx: rx, ry: ry, angle: angle, largeArc: largeArc, clockwise: clockwise, point: _point)
            case .closePath:
                return self
            }
        case .matrix:
            // TODO: What should occur here?
            return self
        }
    }

    /// Applies multiple transformations in the order they are specified.
    func applying(transformations: [Transformation]) -> Path.Command {
        var command = self

        for transformation in transformations {
            command = command.applying(transformation: transformation)
        }

        return command
    }
}

extension Path.Command {
    /// Determines if all values are provided (i.e. !.isNaN)
    var isComplete: Bool {
        switch self {
        case .moveTo(let point), .lineTo(let point):
            !point.hasNaN
        case .cubicBezierCurve(let cp1, let cp2, let point):
            !cp1.hasNaN && !cp2.hasNaN && !point.hasNaN
        case .quadraticBezierCurve(let cp, let point):
            !cp.hasNaN && !point.hasNaN
        case .ellipticalArcCurve(let rx, let ry, let angle, _, _, let point):
            !rx.isNaN && !ry.isNaN && !angle.isNaN && !point.hasNaN
        case .closePath:
            true
        }
    }

    /// The last control point used in drawing the path.
    ///
    /// Only valid for curves.
    var lastControlPoint: Point? {
        switch self {
        case .cubicBezierCurve(_, let cp2, _):
            cp2
        case .quadraticBezierCurve(let cp, _):
            cp
        default:
            nil
        }
    }

    /// A mirror representation of `lastControlPoint`.
    var lastControlPointMirror: Point? {
        guard let cp = lastControlPoint else {
            return nil
        }

        return Point(x: point.x + (point.x - cp.x), y: point.y + (point.y - cp.y))
    }

    /// The total number of argument values the command requires.
    var arguments: Int {
        switch self {
        case .moveTo: 2
        case .lineTo: 2
        case .cubicBezierCurve: 6
        case .quadraticBezierCurve: 4
        case .ellipticalArcCurve: 7
        case .closePath: 0
        }
    }

    /// Adjusts a Command argument by a specified amount.
    ///
    /// A `Point` consumes two positions. So, in the example `.quadraticBezierCurve(cp: .zero, point: .zero)`:
    /// * position 0 = Control Point X
    /// * position 1 = Control Point Y
    /// * position 2 = Point X
    /// * position 3 = Point Y
    ///
    /// - parameter position: The index of the argument parameter to adjust.
    /// - parameter value: The value to add to the existing value. If the current value equal `.isNaN`, than the
    ///                    supplied value is used as-is.
    /// - throws: `Path.Command.Error`
    func adjustingArgument(at position: Int, by value: Double) throws -> Path.Command {
        switch self {
        case .moveTo(let point):
            switch position {
            case 0:
                return .moveTo(point: point.adjusting(x: value))
            case 1:
                return .moveTo(point: point.adjusting(y: value))
            default:
                throw Path.Command.Error.invalidArgumentPosition(position, self)
            }
        case .lineTo(let point):
            switch position {
            case 0:
                return .lineTo(point: point.adjusting(x: value))
            case 1:
                return .lineTo(point: point.adjusting(y: value))
            default:
                throw Path.Command.Error.invalidArgumentPosition(position, self)
            }
        case .cubicBezierCurve(let cp1, let cp2, let point):
            switch position {
            case 0:
                return .cubicBezierCurve(cp1: cp1.adjusting(x: value), cp2: cp2, point: point)
            case 1:
                return .cubicBezierCurve(cp1: cp1.adjusting(y: value), cp2: cp2, point: point)
            case 2:
                return .cubicBezierCurve(cp1: cp1, cp2: cp2.adjusting(x: value), point: point)
            case 3:
                return .cubicBezierCurve(cp1: cp1, cp2: cp2.adjusting(y: value), point: point)
            case 4:
                return .cubicBezierCurve(cp1: cp1, cp2: cp2, point: point.adjusting(x: value))
            case 5:
                return .cubicBezierCurve(cp1: cp1, cp2: cp2, point: point.adjusting(y: value))
            default:
                throw Path.Command.Error.invalidArgumentPosition(position, self)
            }
        case .quadraticBezierCurve(let cp, let point):
            switch position {
            case 0:
                return .quadraticBezierCurve(cp: cp.adjusting(x: value), point: point)
            case 1:
                return .quadraticBezierCurve(cp: cp.adjusting(y: value), point: point)
            case 2:
                return .quadraticBezierCurve(cp: cp, point: point.adjusting(x: value))
            case 3:
                return .quadraticBezierCurve(cp: cp, point: point.adjusting(y: value))
            default:
                throw Path.Command.Error.invalidArgumentPosition(position, self)
            }
        case .ellipticalArcCurve(let rx, let ry, let angle, let largeArc, let clockwise, let point):
            switch position {
            case 0:
                return .ellipticalArcCurve(rx: value, ry: ry, angle: angle, largeArc: largeArc, clockwise: clockwise, point: point)
            case 1:
                return .ellipticalArcCurve(rx: rx, ry: value, angle: angle, largeArc: largeArc, clockwise: clockwise, point: point)
            case 2:
                return .ellipticalArcCurve(rx: rx, ry: ry, angle: value, largeArc: largeArc, clockwise: clockwise, point: point)
            case 3:
                return .ellipticalArcCurve(rx: rx, ry: ry, angle: angle, largeArc: !value.isZero, clockwise: clockwise, point: point)
            case 4:
                return .ellipticalArcCurve(rx: rx, ry: ry, angle: angle, largeArc: largeArc, clockwise: !value.isZero, point: point)
            case 5:
                return .ellipticalArcCurve(rx: rx, ry: ry, angle: angle, largeArc: largeArc, clockwise: clockwise, point: point.adjusting(x: value))
            case 6:
                return .ellipticalArcCurve(rx: rx, ry: ry, angle: angle, largeArc: largeArc, clockwise: clockwise, point: point.adjusting(y: value))
            default:
                throw Path.Command.Error.invalidArgumentPosition(position, self)
            }
        case .closePath:
            throw Path.Command.Error.invalidAdjustment(self)
        }
    }
}
