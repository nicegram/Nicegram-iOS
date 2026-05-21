import Swift2D
import SwiftSVG
#if canImport(CoreGraphics)
import CoreGraphics

public extension CGMutablePath {
    /// Adds a `Path.Command` to a _CoreGraphics path_, using the provided rectangles to correctly scale the parameters.
    ///
    /// - parameter command: The `Path.Command` to append
    /// - parameter from: The `Rect` which originally had the instruction. This is typically the `Document.originalSize`.
    /// - parameter to: The `Rect` defining the new size.
    /// - parameter previousPoint: The last `Point`, used for Elliptical Arc calculations
    func addCommand(_ command: Path.Command, from: Rect, to: Rect, previousPoint: Point? = nil) {
        let translated = command.translate(from: from, to: to)
        switch translated {
        case .moveTo(let point):
            move(to: CGPoint(point))
        case .lineTo(let point):
            addLine(to: CGPoint(point))
        case .cubicBezierCurve(let cp1, let cp2, let point):
            addCurve(to: CGPoint(point), control1: CGPoint(cp1), control2: CGPoint(cp2))
        case .quadraticBezierCurve(let cp, let point):
            addQuadCurve(to: CGPoint(point), control: CGPoint(cp))
        case .ellipticalArcCurve(_, _, _, _, _, let point):
            guard let previousPoint else {
                addLine(to: CGPoint(point))
                return
            }

            do {
                let curves = try command.convertToCubicBezierCurves(with: previousPoint)
                for curve in curves {
                    addCommand(curve, from: from, to: to)
                }
            } catch {
                print(error)
                addLine(to: CGPoint(point))
            }
        case .closePath:
            closeSubpath()
        }
    }
}

#endif
