import Foundation

public extension Path {
    /// A unit of a SVG path data string.
    enum Component {
        case prefix(Command.Prefix)
        case value(Double)

        /// Interprets a `Path` `data` attribute into individual `Component`s for command processing.
        public static func components(from data: String) throws -> [Component] {
            var blocks: [String] = []
            var block: String = ""

            for scalar in data.unicodeScalars {
                if scalar == "e" {
                    // Account for exponential value notation.
                    block.append(String(scalar))
                    continue
                }

                if CharacterSet.letters.contains(scalar) {
                    if !block.isEmpty {
                        blocks.append(block)
                        block = ""
                    }

                    blocks.append(String(scalar))
                    continue
                }

                if CharacterSet.whitespaces.contains(scalar) {
                    if !block.isEmpty {
                        blocks.append(block)
                        block = ""
                    }

                    continue
                }

                if CharacterSet(charactersIn: ",").contains(scalar) {
                    if !block.isEmpty {
                        blocks.append(block)
                        block = ""
                    }

                    continue
                }

                if CharacterSet(charactersIn: "-").contains(scalar) {
                    if !block.isEmpty, block.last != "e" {
                        // Again, account for exponential values.
                        blocks.append(block)
                        block = ""
                    }

                    block.append(String(scalar))
                    continue
                }

                if CharacterSet(charactersIn: ".").contains(scalar) {
                    if block.contains(".") {
                        // Already decimal value, this is a new value
                        blocks.append(block)
                        block = ""
                    }

                    block.append(String(scalar))
                    continue
                }

                if CharacterSet.decimalDigits.contains(scalar) {
                    block.append(String(scalar))
                    continue
                }

                print("Unhandled Character: \(scalar)")
            }

            if !block.isEmpty {
                blocks.append(block)
                block = ""
            }

            return blocks
                .filter { !$0.isEmpty }
                .compactMap {
                    if let prefix = Path.Command.Prefix(rawValue: $0.first!) {
                        .prefix(prefix)
                    } else if let value = Double($0) {
                        .value(value)
                    } else {
                        // throw in the future?
                        nil
                    }
                }
        }
    }
}
