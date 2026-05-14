import Swift2D

public extension Path {
    /// Utility used to construct a collection of `Path.Command` from a collection of `Path.Component`.
    class ComponentParser {
        /// The command currently being built
        private var command: Path.Command?
        /// Coordinate system being used
        private var coordinates: Path.Command.Coordinates = .absolute
        /// The argument position of the _command_ to be processed.
        private var position: Int = 0
        /// Indicates that only a single value will be processed on the next component pass.
        private var singleValue: Bool = false
        /// The originating coordinates of the path.
        private var pathOrigin: Point = .nan
        /// The last point as processed by the parser.
        private var currentPoint: Point = .zero

        public init() {}

        public func parse(_ components: [Path.Component]) throws -> [Path.Command] {
            var commands: [Path.Command] = []

            try components.forEach { component in
                if let command = try parse(component, lastCommand: commands.last) {
                    commands.append(command)
                }
            }

            return commands
        }

        private func parse(_ component: Path.Component, lastCommand: Path.Command?) throws -> Path.Command? {
            switch component {
            case .prefix(let prefix):
                setup(prefix: prefix, lastCommand: lastCommand)
            case .value(let value):
                try process(value: value, lastCommand: lastCommand)
            }
        }

        private func setup(prefix: Path.Command.Prefix, lastCommand: Path.Command?) -> Path.Command? {
            position = 0
            singleValue = false

            switch prefix {
            case .move:
                command = .moveTo(point: .nan)
                coordinates = .absolute
            case .relativeMove:
                command = .moveTo(point: currentPoint)
                coordinates = .relative
            case .line:
                command = .lineTo(point: .nan)
                coordinates = .absolute
            case .relativeLine:
                command = .lineTo(point: currentPoint)
                coordinates = .relative
            case .horizontalLine:
                command = .lineTo(point: currentPoint.with(x: .nan))
                coordinates = .absolute
            case .relativeHorizontalLine:
                command = .lineTo(point: currentPoint)
                coordinates = .relative
                singleValue = true
            case .verticalLine:
                command = .lineTo(point: currentPoint.with(y: .nan))
                coordinates = .absolute
                position = 1
            case .relativeVerticalLine:
                command = .lineTo(point: currentPoint)
                coordinates = .relative
                position = 1
                singleValue = true
            case .cubicBezierCurve:
                command = .cubicBezierCurve(cp1: .nan, cp2: .nan, point: .nan)
                coordinates = .absolute
            case .relativeCubicBezierCurve:
                command = .cubicBezierCurve(cp1: currentPoint, cp2: currentPoint, point: currentPoint)
                coordinates = .relative
            case .smoothCubicBezierCurve:
                if case .cubicBezierCurve(_, let cp, _) = lastCommand {
                    command = .cubicBezierCurve(cp1: cp.reflecting(around: currentPoint), cp2: .nan, point: .nan)
                } else {
                    command = .cubicBezierCurve(cp1: currentPoint, cp2: .nan, point: .nan)
                }
                coordinates = .absolute
                position = 2
            case .relativeSmoothCubicBezierCurve:
                if case .cubicBezierCurve(_, let cp, _) = lastCommand {
                    command = .cubicBezierCurve(cp1: cp.reflecting(around: cp.reflecting(around: currentPoint)), cp2: currentPoint, point: currentPoint)
                } else {
                    command = .cubicBezierCurve(cp1: currentPoint, cp2: currentPoint, point: currentPoint)
                }
                coordinates = .relative
                position = 2
            case .quadraticBezierCurve:
                command = .quadraticBezierCurve(cp: .nan, point: .nan)
                coordinates = .absolute
            case .relativeQuadraticBezierCurve:
                command = .quadraticBezierCurve(cp: currentPoint, point: currentPoint)
                coordinates = .relative
            case .smoothQuadraticBezierCurve:
                if case .quadraticBezierCurve(let cp, _) = lastCommand {
                    command = .quadraticBezierCurve(cp: cp.reflecting(around: currentPoint), point: .nan)
                } else {
                    command = .quadraticBezierCurve(cp: currentPoint, point: .nan)
                }
                coordinates = .absolute
                position = 2
            case .relativeSmoothQuadraticBezierCurve:
                if case .quadraticBezierCurve(let cp, _) = lastCommand {
                    command = .quadraticBezierCurve(cp: cp.reflecting(around: currentPoint), point: currentPoint)
                } else {
                    command = .quadraticBezierCurve(cp: currentPoint, point: currentPoint)
                }
                coordinates = .relative
                position = 2
            case .ellipticalArcCurve:
                command = .ellipticalArcCurve(rx: .nan, ry: .nan, angle: .nan, largeArc: false, clockwise: false, point: .nan)
                coordinates = .absolute
            case .relativeEllipticalArcCurve:
                command = .ellipticalArcCurve(rx: .nan, ry: .nan, angle: .nan, largeArc: false, clockwise: false, point: currentPoint)
                coordinates = .relative
            case .close, .relativeClose:
                currentPoint = pathOrigin
                reset()
                return .closePath
            }

            return nil
        }

        private func process(value: Double, lastCommand: Path.Command?) throws -> Path.Command? {
            if let command {
                try continueCommand(command, with: value)
            } else {
                try nextCommand(with: value, lastCommand: lastCommand)
            }

            if let command, command.isComplete {
                switch coordinates {
                case .relative:
                    guard position == -1 else {
                        return nil
                    }

                    fallthrough
                case .absolute:
                    currentPoint = command.point
                    if case .moveTo = command {
                        pathOrigin = command.point
                    }
                    reset()
                    return command
                }
            } else {
                return nil
            }
        }

        private func continueCommand(_ command: Path.Command, with value: Double) throws {
            switch command {
            case .moveTo, .cubicBezierCurve, .quadraticBezierCurve, .ellipticalArcCurve:
                self.command = try command.adjustingArgument(at: position, by: value)
                switch coordinates {
                case .absolute:
                    position += 1
                case .relative:
                    switch position {
                    case 0 ... (command.arguments - 2):
                        position += 1
                    case command.arguments - 1:
                        position = -1
                    default:
                        break // throw?
                    }
                }
            case .lineTo:
                self.command = try command.adjustingArgument(at: position, by: value)
                switch coordinates {
                case .absolute:
                    position += 1
                case .relative:
                    switch position {
                    case 0:
                        if singleValue {
                            singleValue = false
                            position = -1
                        } else {
                            position += 1
                        }
                    case 1:
                        if singleValue {
                            singleValue = false
                        }
                        position = -1
                    default:
                        break // throw?
                    }
                }
            case .closePath:
                break
            }
        }

        private func nextCommand(with value: Double, lastCommand: Path.Command?) throws {
            guard let command = lastCommand else {
                throw Path.Command.Error.invalidRelativeCommand
            }

            switch command {
            case .moveTo:
                switch coordinates {
                case .absolute:
                    self.command = .lineTo(point: Point(x: value, y: .nan))
                    position = 1
                case .relative:
                    let c = Path.Command.lineTo(point: command.point)
                    self.command = try c.adjustingArgument(at: 0, by: value)
                    position = 1
                }
            case .lineTo:
                switch coordinates {
                case .absolute:
                    self.command = .lineTo(point: Point(x: value, y: .nan))
                    position = 1
                case .relative:
                    let c = Path.Command.lineTo(point: command.point)
                    self.command = try c.adjustingArgument(at: 0, by: value)
                    position = 1
                }
            case .cubicBezierCurve:
                switch coordinates {
                case .absolute:
                    self.command = .cubicBezierCurve(cp1: Point(x: value, y: .nan), cp2: .nan, point: .nan)
                    position = 1
                case .relative:
                    let c = Path.Command.cubicBezierCurve(cp1: command.point, cp2: command.point, point: command.point)
                    self.command = try c.adjustingArgument(at: 0, by: value)
                    position = 1
                }
            case .quadraticBezierCurve:
                switch coordinates {
                case .absolute:
                    self.command = .quadraticBezierCurve(cp: Point(x: value, y: .nan), point: .nan)
                    position = 1
                case .relative:
                    let c = Path.Command.quadraticBezierCurve(cp: command.point, point: command.point)
                    self.command = try c.adjustingArgument(at: 0, by: value)
                    position = 1
                }
            case .ellipticalArcCurve:
                switch coordinates {
                case .absolute:
                    self.command = .ellipticalArcCurve(rx: value, ry: .nan, angle: .nan, largeArc: false, clockwise: false, point: .nan)
                    position = 1
                case .relative:
                    let c = Path.Command.ellipticalArcCurve(rx: .nan, ry: .nan, angle: .nan, largeArc: false, clockwise: false, point: command.point)
                    self.command = try c.adjustingArgument(at: 0, by: value)
                    position = 1
                }
            case .closePath:
                break
            }
        }

        private func reset() {
            command = nil
            coordinates = .absolute
            position = 0
            singleValue = false
        }
    }
}
