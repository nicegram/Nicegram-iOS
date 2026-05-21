import Foundation
import Swift2D

/// A modification that should be applied to an element and its children.
///
/// If a list of transforms is provided, then the net effect is as if each transform had been specified separately in
/// the order provided.
///
/// For example,
/// ```
/// <g transform="translate(-10,-20) scale(2) rotate(45) translate(5,10)">
///   <!-- graphics elements go here -->
/// </g>
/// ```
/// is functionally equivalent to:
/// ```
/// <g transform="translate(-10,-20)">
///   <g transform="scale(2)">
///     <g transform="rotate(45)">
///       <g transform="translate(5,10)">
///         <!-- graphics elements go here -->
///       </g>
///     </g>
///   </g>
/// </g>
/// ```
///
/// The ‘transform’ attribute is applied to an element before processing any other coordinate or length values supplied
/// for that element.
///
/// ## Documentation
/// [Mozilla Developer Network](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/transform)
/// | [W3](https://www.w3.org/TR/SVG11/coords.html#TransformAttribute)
public enum Transformation {
    /// Moves an object by x & y. (Y is assumed to be '0' if not provided)
    case translate(x: Double, y: Double)
    /// Specifies a transformation in the form of a transformation matrix of six values.
    case matrix(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)

    public enum Prefix: String, CaseIterable {
        case translate
        case matrix
    }

    /// Initializes a new `Transformation` with a raw SVG transformation string.
    public init?(_ string: String) {
        guard let prefix = Prefix.allCases.first(where: { string.lowercased().hasPrefix($0.rawValue) }) else {
            return nil
        }

        switch prefix {
        case .translate:
            guard let start = string.firstIndex(of: "(") else {
                return nil
            }

            guard let stop = string.lastIndex(of: ")") else {
                return nil
            }

            var substring = String(string[start ... stop])
            substring = substring.replacingOccurrences(of: "(", with: "")
            substring = substring.replacingOccurrences(of: ")", with: "")

            var components = substring.split(separator: " ", omittingEmptySubsequences: true).map { String($0) }
            components = components.flatMap { $0.components(separatedBy: ",") }

            let values = components.compactMap { Double($0) }.map { Double($0) }
            guard values.count > 0 else {
                return nil
            }

            if values.count > 1 {
                self = .translate(x: values[0], y: values[1])
            } else {
                self = .translate(x: values[0], y: 0.0)
            }
        case .matrix:
            guard let start = string.firstIndex(of: "(") else {
                return nil
            }

            guard let stop = string.lastIndex(of: ")") else {
                return nil
            }

            var substring = String(string[start ... stop])
            substring = substring.replacingOccurrences(of: "(", with: "")
            substring = substring.replacingOccurrences(of: ")", with: "")

            var components = substring.split(separator: " ", omittingEmptySubsequences: true).map { String($0) }
            components = components.flatMap { $0.components(separatedBy: ",") }

            let values = components.compactMap { Double($0) }.map { Double($0) }
            guard values.count > 5 else {
                return nil
            }

            self = .matrix(a: values[0], b: values[1], c: values[2], d: values[3], e: values[4], f: values[5])
        }
    }
}

extension Transformation: CustomStringConvertible {
    public var description: String {
        switch self {
        case .translate(let x, let y):
            "translate(\(x), \(y))"
        case .matrix(let a, let b, let c, let d, let e, let f):
            "matrix(\(a), \(b), \(c), \(d), \(e), \(f))"
        }
    }
}
