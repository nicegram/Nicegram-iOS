import Foundation
import Swift2D

struct EllipseProcessor {

    let x: Double
    let y: Double
    let rx: Double
    let ry: Double

    /// The _optimal_ offset for control points when representing a
    /// circle/ellipse as 4 bezier curves.
    ///
    /// [Stack Overflow](https://stackoverflow.com/questions/1734745/how-to-create-circle-with-bézier-curves)
    static func controlPointOffset(_ radius: Double) -> Double {
        (Double(4.0 / 3.0) * tan(Double.pi / 8.0)) * radius
    }

    init(ellipse: Ellipse) {
        x = ellipse.x
        y = ellipse.y
        rx = ellipse.rx
        ry = ellipse.ry
    }

    init(circle: Circle) {
        x = circle.x
        y = circle.y
        rx = circle.r
        ry = circle.r
    }

    func commands(clockwise: Bool) -> [Path.Command] {
        var commands: [Path.Command] = []

        let xOffset = Self.controlPointOffset(rx)
        let yOffset = Self.controlPointOffset(ry)

        let zero = Point(x: x + rx, y: y)
        let ninety = Point(x: x, y: y - ry)
        let oneEighty = Point(x: x - rx, y: y)
        let twoSeventy = Point(x: x, y: y + ry)

        var cp1: Point = .zero
        var cp2: Point = .zero

        // Starting at degree 0 (the right most point)
        commands.append(.moveTo(point: zero))

        if clockwise {
            cp1 = Point(x: zero.x, y: zero.y + yOffset)
            cp2 = Point(x: twoSeventy.x + xOffset, y: twoSeventy.y)
            commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: twoSeventy))

            cp1 = Point(x: twoSeventy.x - xOffset, y: twoSeventy.y)
            cp2 = Point(x: oneEighty.x, y: oneEighty.y + yOffset)
            commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: oneEighty))

            cp1 = Point(x: oneEighty.x, y: oneEighty.y - yOffset)
            cp2 = Point(x: ninety.x - xOffset, y: ninety.y)
            commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: ninety))

            cp1 = Point(x: ninety.x + xOffset, y: ninety.y)
            cp2 = Point(x: zero.x, y: zero.y - yOffset)
            commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: zero))
        } else {
            cp1 = Point(x: zero.x, y: zero.y - yOffset)
            cp2 = Point(x: ninety.x + xOffset, y: ninety.y)
            commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: ninety))

            cp1 = Point(x: ninety.x - xOffset, y: ninety.y)
            cp2 = Point(x: oneEighty.x, y: oneEighty.y - yOffset)
            commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: oneEighty))

            cp1 = Point(x: oneEighty.x, y: oneEighty.y + yOffset)
            cp2 = Point(x: twoSeventy.x - xOffset, y: twoSeventy.y)
            commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: twoSeventy))

            cp1 = Point(x: twoSeventy.x + xOffset, y: twoSeventy.y)
            cp2 = Point(x: zero.x, y: zero.y + yOffset)
            commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: zero))
        }

        commands.append(.closePath)

        return commands
    }
}
