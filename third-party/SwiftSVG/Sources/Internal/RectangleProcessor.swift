import Swift2D

struct RectangleProcessor {

    let rectangle: Rectangle

    func commands(clockwise: Bool) -> [Path.Command] {
        var rx = rectangle.rx
        var ry = rectangle.ry

        if let _rx = rx, _rx > (rectangle.width / 2.0) {
            rx = rectangle.width / 2.0
        }

        if let _ry = ry, _ry > (rectangle.height / 2.0) {
            ry = rectangle.height / 2.0
        }

        var commands: [Path.Command] = []

        switch (rx, ry) {
        case (.some(let radiusX), .some(let radiusY)) where radiusX != radiusY:
            // Use Cubic Bezier Curve to form rounded corners
            // TODO: Verify that the control points are right

            var cp1: Point = .zero
            var cp2: Point = .zero
            var point: Point = Point(x: rectangle.x + radiusX, y: rectangle.y)

            commands.append(.moveTo(point: point))

            if clockwise {
                point = .init(x: rectangle.x + rectangle.width - radiusX, y: rectangle.y)
                commands.append(.lineTo(point: point))

                cp1 = .init(x: rectangle.x + rectangle.width, y: rectangle.y)
                cp2 = cp1
                point = .init(x: rectangle.x + rectangle.width, y: rectangle.y + radiusY)
                commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: point))

                point = .init(x: rectangle.x + rectangle.width, y: rectangle.y + rectangle.height - radiusY)
                commands.append(.lineTo(point: point))

                cp1 = .init(x: rectangle.x + rectangle.width, y: rectangle.y + rectangle.height)
                cp2 = cp1
                point = .init(x: rectangle.x + rectangle.width - radiusX, y: rectangle.y + rectangle.height)
                commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: point))

                point = .init(x: rectangle.x + radiusX, y: rectangle.y + rectangle.height)
                commands.append(.lineTo(point: point))

                cp1 = .init(x: rectangle.x, y: rectangle.y + rectangle.height)
                cp2 = cp1
                point = .init(x: rectangle.x, y: rectangle.y + rectangle.height - radiusY)
                commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: point))

                point = .init(x: rectangle.x, y: rectangle.y + radiusY)
                commands.append(.lineTo(point: point))

                cp1 = .init(x: rectangle.x, y: rectangle.y)
                cp2 = cp1
                point = .init(x: rectangle.x + radiusX, y: rectangle.y)
                commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: point))
            } else {
                cp1 = .init(x: rectangle.x, y: rectangle.y)
                cp2 = cp1
                point = .init(x: rectangle.x, y: rectangle.y + radiusY)
                commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: point))

                point = .init(x: rectangle.x, y: rectangle.y + rectangle.height - radiusY)
                commands.append(.lineTo(point: point))

                cp1 = .init(x: rectangle.x, y: rectangle.y + rectangle.height)
                cp2 = cp1
                point = .init(x: rectangle.x + radiusX, y: rectangle.y + rectangle.height)
                commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: point))

                point = .init(x: rectangle.x + rectangle.width - radiusX, y: rectangle.y + rectangle.height)
                commands.append(.lineTo(point: point))

                cp1 = .init(x: rectangle.x + rectangle.width, y: rectangle.y + rectangle.height)
                cp2 = cp1
                point = .init(x: rectangle.x + rectangle.width, y: rectangle.y + rectangle.height - radiusY)
                commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: point))

                point = .init(x: rectangle.x + rectangle.width, y: rectangle.y + radiusY)
                commands.append(.lineTo(point: point))

                cp1 = .init(x: rectangle.x + rectangle.width, y: rectangle.y)
                cp2 = cp1
                point = .init(x: rectangle.x + rectangle.width - radiusX, y: rectangle.y)
                commands.append(.cubicBezierCurve(cp1: cp1, cp2: cp2, point: point))
            }
        case (.some(let radius), .none), (.none, .some(let radius)), (.some(let radius), _):
            // use Quadratic Bezier Curve to form rounded corners

            var cp: Point = .zero
            var point: Point = Point(x: rectangle.x + radius, y: rectangle.y)

            commands.append(.moveTo(point: point))

            if clockwise {
                point = .init(x: (rectangle.x + rectangle.width) - radius, y: rectangle.y)
                commands.append(.lineTo(point: point))

                cp = .init(x: rectangle.x + rectangle.width, y: rectangle.y)
                point = .init(x: rectangle.x + rectangle.width, y: rectangle.y + radius)
                commands.append(.quadraticBezierCurve(cp: cp, point: point))

                point = .init(x: rectangle.x + rectangle.width, y: (rectangle.y + rectangle.height) - radius)
                commands.append(.lineTo(point: point))

                cp = .init(x: rectangle.x + rectangle.width, y: rectangle.y + rectangle.height)
                point = .init(x: rectangle.x + rectangle.width - radius, y: rectangle.y + rectangle.height)
                commands.append(.quadraticBezierCurve(cp: cp, point: point))

                point = .init(x: rectangle.x + radius, y: rectangle.y + rectangle.height)
                commands.append(.lineTo(point: point))

                cp = .init(x: rectangle.x, y: rectangle.y + rectangle.height)
                point = .init(x: rectangle.x, y: rectangle.y + rectangle.height - radius)
                commands.append(.quadraticBezierCurve(cp: cp, point: point))

                point = .init(x: rectangle.x, y: rectangle.y + radius)
                commands.append(.lineTo(point: point))

                cp = .init(x: rectangle.x, y: rectangle.y)
                point = .init(x: rectangle.x + radius, y: rectangle.y)
                commands.append(.quadraticBezierCurve(cp: cp, point: point))
            } else {
                cp = .init(x: rectangle.x, y: rectangle.y)
                point = .init(x: rectangle.x, y: rectangle.y + radius)
                commands.append(.quadraticBezierCurve(cp: cp, point: point))

                point = .init(x: rectangle.x, y: rectangle.y + rectangle.height - radius)
                commands.append(.lineTo(point: point))

                cp = .init(x: rectangle.x, y: rectangle.y + rectangle.height)
                point = .init(x: rectangle.x + radius, y: rectangle.y + rectangle.height)
                commands.append(.quadraticBezierCurve(cp: cp, point: point))

                point = .init(x: rectangle.x + rectangle.width - radius, y: rectangle.y + rectangle.height)
                commands.append(.lineTo(point: point))

                cp = .init(x: rectangle.x + rectangle.width, y: rectangle.y + rectangle.height)
                point = .init(x: rectangle.x + rectangle.width, y: rectangle.y + rectangle.height - radius)
                commands.append(.quadraticBezierCurve(cp: cp, point: point))

                point = .init(x: rectangle.x + rectangle.width, y: rectangle.y + radius)
                commands.append(.lineTo(point: point))

                cp = .init(x: rectangle.x + rectangle.width, y: rectangle.y)
                point = .init(x: rectangle.x + rectangle.width - radius, y: rectangle.y)
                commands.append(.quadraticBezierCurve(cp: cp, point: point))
            }
        case (.none, .none):
            // draw three line segments.
            commands.append(.moveTo(point: Point(x: rectangle.x, y: rectangle.y)))

            if clockwise {
                commands.append(.lineTo(point: Point(x: rectangle.x + rectangle.width, y: rectangle.y)))
                commands.append(.lineTo(point: Point(x: rectangle.x + rectangle.width, y: rectangle.y + rectangle.height)))
                commands.append(.lineTo(point: Point(x: rectangle.x, y: rectangle.y + rectangle.height)))
            } else {
                commands.append(.lineTo(point: Point(x: rectangle.x, y: rectangle.y + rectangle.height)))
                commands.append(.lineTo(point: Point(x: rectangle.x + rectangle.width, y: rectangle.y + rectangle.height)))
                commands.append(.lineTo(point: Point(x: rectangle.x + rectangle.width, y: rectangle.y)))
            }
        }

        commands.append(.closePath)

        return commands
    }
}
