import Foundation
import Swift2D
import SwiftSVG

public extension Path.Command {
    /// Uses the _Power of Math_ to translate a commands controls/points from one `Rect` to another `Rect`.
    func translate(from: Rect, to: Rect) -> Path.Command {
        switch self {
        case .moveTo(let point):
            let _point = VectorPoint(point: point, in: from).translate(to: to)
            return .moveTo(point: _point)
        case .lineTo(let point):
            let _point = VectorPoint(point: point, in: from).translate(to: to)
            return .lineTo(point: _point)
        case .cubicBezierCurve(let cp1, let cp2, let point):
            let _cp1 = VectorPoint(point: cp1, in: from).translate(to: to)
            let _cp2 = VectorPoint(point: cp2, in: from).translate(to: to)
            let _point = VectorPoint(point: point, in: from).translate(to: to)
            return .cubicBezierCurve(cp1: _cp1, cp2: _cp2, point: _point)
        case .quadraticBezierCurve(let cp, let point):
            let _cp = VectorPoint(point: cp, in: from).translate(to: to)
            let _point = VectorPoint(point: point, in: from).translate(to: to)
            return .quadraticBezierCurve(cp: _cp, point: _point)
        case .ellipticalArcCurve(let rx, let ry, let angle, let largeArc, let clockwise, let point):
            let _rx = rx * (from.size.maxRadius / to.size.minRadius)
            let _ry = ry * (from.size.maxRadius / to.size.minRadius)
            let _point = VectorPoint(point: point, in: from).translate(to: to)
            return .ellipticalArcCurve(rx: _rx, ry: _ry, angle: angle, largeArc: largeArc, clockwise: clockwise, point: _point)
        case .closePath:
            return self
        }
    }
}

public extension Path.Command {
    func coreGraphicsDescription(originalSize: Size, previousPoint: Point? = nil) -> String {
        let rect = Rect(origin: .zero, size: originalSize)

        switch self {
        case .moveTo(let point):
            let _point = VectorPoint(point: point, in: rect)
            return ".move(to: \(_point.coreGraphicsDescription))"
        case .lineTo(let point):
            let _point = VectorPoint(point: point, in: rect)
            return ".addLine(to: \(_point.coreGraphicsDescription))"
        case .cubicBezierCurve(let cp1, let cp2, let point):
            let _cp1 = VectorPoint(point: cp1, in: rect)
            let _cp2 = VectorPoint(point: cp2, in: rect)
            let _point = VectorPoint(point: point, in: rect)
            return ".addCurve(to: \(_point.coreGraphicsDescription), control1: \(_cp1.coreGraphicsDescription), control2: \(_cp2.coreGraphicsDescription))"
        case .quadraticBezierCurve(let cp, let point):
            let _cp = VectorPoint(point: cp, in: rect)
            let _point = VectorPoint(point: point, in: rect)
            return ".addQuadCurve(to: \(_point.coreGraphicsDescription), control: \(_cp.coreGraphicsDescription))"
        case .ellipticalArcCurve(_, _, _, _, _, let point):
            guard let previousPoint else {
                return Path.Command.lineTo(point: point).coreGraphicsDescription(originalSize: originalSize)
            }

            do {
                let curves = try convertToCubicBezierCurves(with: previousPoint)
                return curves.map { $0.coreGraphicsDescription(originalSize: originalSize) }.joined(separator: "\n")
            } catch {
                print(error)
                return Path.Command.lineTo(point: point).coreGraphicsDescription(originalSize: originalSize)
            }
        case .closePath:
            return ".closeSubpath()"
        }
    }
}

extension Path.Command {
    /// Converts an `.ellipticalArcCurve` into one or more `.cubicBezierCurve`s.
    /// https://github.com/colinmeinke/svg-arc-to-cubic-bezier/blob/master/src/index.js
    func convertToCubicBezierCurves(with previousPoint: Point) throws -> [Path.Command] {
        guard case let .ellipticalArcCurve(rx, ry, angle, largeArg, clockwise, point) = self else {
            throw Path.Command.Error.message("\(#function); Only .ellipticalArcCurve is allowed.")
        }

        var curves: [Path.Command] = []

        guard rx > 0.0, ry > 0.0 else {
            throw Path.Command.Error.message("\(#function); rx/ry must be greater than 0.0 (zero).")
        }

        let sinφ = sin(angle * (.pi * 2.0) / 360.0)
        let cosφ = cos(angle * (.pi * 2.0) / 360.0)

        let pxp = cosφ * (previousPoint.x - point.x) / 2 + sinφ * (previousPoint.y - point.y) / 2.0
        let pyp = -sinφ * (previousPoint.x - point.x) / 2 + cosφ * (previousPoint.y - point.y) / 2.0

        guard pxp != 0.0, pyp != 0.0 else {
            throw Path.Command.Error.message("\(#function); math")
        }

        var _rx = abs(rx)
        var _ry = abs(ry)

        let λ = pow(pxp, 2.0) / pow(_rx, 2.0) + pow(pyp, 2.0) / pow(_ry, 2.0)

        if λ > 1.0 {
            _rx *= sqrt(λ)
            _ry *= sqrt(λ)
        }

        let _arcCenter = arcCenter(previousPoint: previousPoint, point: point, rx: _rx, ry: _ry, largeArc: largeArg, clockwise: clockwise, sinφ: sinφ, cosφ: cosφ, pxp: pxp, pyp: pyp)
        let center = _arcCenter.center
        var angle1 = _arcCenter.angle1
        var angle2 = _arcCenter.angle2

        var ratio = abs(angle2) / ((.pi * 2.0) / 4.0)
        if abs(1.0 - ratio) < 0.0000001 {
            ratio = 1.0
        }

        let segments = max(ceil(ratio), 1)

        angle2 /= segments

        var rawCurves: [(Point, Point, Point)] = []
        for _ in 0 ... Int(segments) {
            rawCurves.append(approximateUnitArc(angle1: angle1, angle2: angle2))
            angle1 += angle2
        }

        for rawCurf in rawCurves {
            let _cp1 = mapToEllipse(point: rawCurf.0, rx: _rx, ry: _ry, sinφ: sinφ, cosφ: cosφ, center: center)
            let _cp2 = mapToEllipse(point: rawCurf.1, rx: _rx, ry: _ry, sinφ: sinφ, cosφ: cosφ, center: center)
            let _point = mapToEllipse(point: rawCurf.2, rx: _rx, ry: _ry, sinφ: sinφ, cosφ: cosφ, center: center)
            curves.append(.cubicBezierCurve(cp1: _cp1, cp2: _cp2, point: _point))
        }

        return curves
    }
}

private func arcCenter(previousPoint: Point, point: Point, rx: Double, ry: Double, largeArc: Bool, clockwise: Bool, sinφ: Double, cosφ: Double, pxp: Double, pyp: Double) ->
    (center: Point, angle1: Double, angle2: Double)
{

    let rxsq = pow(rx, 2.0)
    let rysq = pow(ry, 2.0)
    let pxpsq = pow(pxp, 2.0)
    let pypsq = pow(pyp, 2.0)

    var radicant = (rxsq * rysq) - (rxsq * pypsq) - (rysq * pxpsq)
    if radicant < 0.0 {
        radicant = 0.0
    }

    radicant /= (rxsq * pypsq) + (rysq * pxpsq)
    radicant = sqrt(radicant) * (largeArc == clockwise ? -1.0 : 1.0)

    let centerxp = radicant * rx / ry * pyp
    let centeryp = radicant * -ry / rx * pxp

    let centerx = cosφ * centerxp - sinφ * centeryp + (previousPoint.x + point.x) / 2.0
    let centery = sinφ * centerxp + cosφ * centeryp + (previousPoint.x + point.x) / 2.0

    let vx1 = (pxp - centerxp) / rx
    let vy1 = (pyp - centeryp) / ry
    let vx2 = (-pxp - centerxp) / rx
    let vy2 = (-pyp - centeryp) / ry

    let angle1 = vectorAngle(u: Point(x: 1, y: 0), v: Point(x: vx1, y: vy1))
    var angle2 = vectorAngle(u: Point(x: vx1, y: vy1), v: Point(x: vx2, y: vy2))

    if clockwise == false, angle2 > 0.0 {
        angle2 -= (.pi * 2.0)
    } else if clockwise == true, angle2 < 0.0 {
        angle2 += (.pi * 2.0)
    }

    return (Point(x: centerx, y: centery), angle1, angle2)
}

private func vectorAngle(u: Point, v: Point) -> Double {
    let sign: Double = ((u.x * v.y - u.y * v.x) < 0.0) ? -1.0 : 1.0
    var dot = u.x * v.x + u.y * v.y
    if dot > 1.0 {
        dot = 1.0
    } else if dot < -1.0 {
        dot = -1.0
    }

    return sign * acos(dot)
}

private func approximateUnitArc(angle1: Double, angle2: Double) -> (Point, Point, Point) {
    // If 90 degree circular arc, use a constant
    // as derived from http://spencermortensen.com/articles/bezier-circle
    let a: Double = switch angle2 {
    case 1.5707963267948966:
        0.551915024494
    case -1.5707963267948966:
        -0.551915024494
    default:
        4.0 / 3.0 * tan(angle2 / 4.0)
    }

    let x1 = cos(angle1)
    let y1 = sin(angle1)
    let x2 = cos(angle1 + angle2)
    let y2 = sin(angle1 + angle2)

    return (Point(x: x1 - y1 * a, y: y1 + x1 * a), Point(x: x2 + y2 * a, y: y2 - x2 * 1), Point(x: x2, y: y2))
}

private func mapToEllipse(point: Point, rx: Double, ry: Double, sinφ: Double, cosφ: Double, center: Point) -> Point {
    let x = point.x * rx
    let y = point.y * ry
    let xp = cosφ * x - sinφ * y
    let yp = sinφ * x + cosφ * y
    return Point(x: xp + center.x, y: yp + center.y)
}
