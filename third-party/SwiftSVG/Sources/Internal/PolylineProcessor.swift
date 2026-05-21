import Foundation
import Swift2D

struct PolylineProcessor {

    let points: String

    func commands() throws -> [Path.Command] {
        let pairs = points.components(separatedBy: " ")
        let components = pairs.flatMap { $0.components(separatedBy: ",") }
        let values = components.compactMap { Double($0) }.map { Double($0) }

        guard values.count > 2 else {
            // More than just a starting point is required.
            return []
        }

        guard values.count % 2 == 0 else {
            // An odd number of components means that parsing probably failed
            return []
        }

        var commands: [Path.Command] = []

        let move = values.prefix(upTo: 2)
        let segments = values.suffix(from: 2)

        commands.append(.moveTo(point: Point(x: move[0], y: move[1])))

        var _value: Double = .nan
        for value in segments {
            if _value.isNaN {
                _value = value
            } else {
                commands.append(.lineTo(point: Point(x: _value, y: value)))
                _value = .nan
            }
        }

        let reversedSegments = segments.dropLast(2).reversed()
        for value in reversedSegments {
            if _value.isNaN {
                _value = value
            } else {
                commands.append(.lineTo(point: Point(x: _value, y: value)))
                _value = .nan
            }
        }

        commands.append(.closePath)

        return commands
    }
}
