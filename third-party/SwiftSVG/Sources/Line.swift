import Swift2D
import XMLCoder

/// SVG basic shape used to create a line connecting two points.
///
/// ## Documentation
/// [Mozilla Developer Network](https://developer.mozilla.org/en-US/docs/Web/SVG/Element/line)
/// | [W3](https://developer.mozilla.org/en-US/docs/Web/SVG/Element/line)
public struct Line: Element {

    /// Defines the x-axis coordinate of the line starting point.
    public var x1: Double = 0.0
    /// Defines the x-axis coordinate of the line ending point.
    public var y1: Double = 0.0
    /// Defines the y-axis coordinate of the line starting point.
    public var x2: Double = 0.0
    /// Defines the y-axis coordinate of the line ending point.
    public var y2: Double = 0.0

    // MARK: CoreAttributes

    public var id: String?

    // MARK: PresentationAttributes

    public var fillColor: String?
    public var fillOpacity: Double?
    public var fillRule: Fill.Rule?
    public var strokeColor: String?
    public var strokeWidth: Double?
    public var strokeOpacity: Double?
    public var strokeLineCap: Stroke.LineCap?
    public var strokeLineJoin: Stroke.LineJoin?
    public var strokeMiterLimit: Double?
    public var transform: String?

    // MARK: StylingAttributes

    public var style: String?

    enum CodingKeys: String, CodingKey {
        case x1
        case y1
        case x2
        case y2
        case id
        case fillColor = "fill"
        case fillOpacity = "fill-opacity"
        case fillRule = "fill-rule"
        case strokeColor = "stroke"
        case strokeWidth = "stroke-width"
        case strokeOpacity = "stroke-opacity"
        case strokeLineCap = "stroke-linecap"
        case strokeLineJoin = "stroke-linejoin"
        case strokeMiterLimit = "stroke-miterlimit"
        case transform
        case style
    }

    public init() {}

    public init(x1: Double, y1: Double, x2: Double, y2: Double) {
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
    }
}

extension Line: CommandRepresentable {
    public func commands() throws -> [Path.Command] {
        [
            .moveTo(point: Point(x: x1, y: y1)),
            .lineTo(point: Point(x: x2, y: y2)),
            .lineTo(point: Point(x: x1, y: y1)),
            .closePath,
        ]
    }
}

extension Line: CustomStringConvertible {
    public var description: String {
        let desc = "<line x1=\"\(x1)\" y1=\"\(y1)\" x2=\"\(x2)\" y2=\"\(y2)\""
        return desc + " \(attributeDescription) />"
    }
}

extension Line: DynamicNodeDecoding {
    public static func nodeDecoding(for key: any CodingKey) -> XMLDecoder.NodeDecoding {
        .attribute
    }
}

extension Line: DynamicNodeEncoding {
    public static func nodeEncoding(for key: any CodingKey) -> XMLEncoder.NodeEncoding {
        .attribute
    }
}
