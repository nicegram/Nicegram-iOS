import Foundation
import Swift2D

struct PolygonProcessor {

    let points: String

    func commands() throws -> [Path.Command] {
        let pairs = points.components(separatedBy: " ")
        let components = pairs.flatMap { $0.components(separatedBy: ",") }
        guard components.count > 0 else {
            return []
        }

        guard components.count % 2 == 0 else {
            // An odd number of components means that parsing probably failed
            return []
        }

        var commands: [Path.Command] = []

        var firstValue: Bool = true
        for (idx, component) in components.enumerated() {
            guard let _value = Double(component) else {
                return commands
            }

            let value = Double(_value)

            if firstValue {
                if idx == 0 {
                    commands.append(.moveTo(point: Point(x: value, y: .nan)))
                } else {
                    commands.append(.lineTo(point: Point(x: value, y: .nan)))
                }
                firstValue = false
            } else {
                let count = commands.count
                guard let modified = try? commands.last?.adjustingArgument(at: 1, by: value) else {
                    return commands
                }

                commands[count - 1] = modified
                firstValue = true
            }
        }

        commands.append(.closePath)

        return commands
    }
}
