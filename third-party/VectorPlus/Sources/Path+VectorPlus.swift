import Swift2D
import SwiftSVG

public extension Path {
    func asCoreGraphicsDescription(variable: String = "path", originalSize: Size) throws -> String {
        var outputs: [String] = []
        let commands = (try? commands()) ?? []
        for (idx, command) in commands.enumerated() {
            let previous: Point? = if idx > 0 {
                commands[idx - 1].previousPoint
            } else {
                nil
            }

            let method = command.coreGraphicsDescription(originalSize: originalSize, previousPoint: previous)
            let code = "\(variable)\(method)"
            outputs.append(code)
        }
        return outputs.joined(separator: "\n        ")
    }
}

public extension Path.Command {
    var previousPoint: Point {
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
