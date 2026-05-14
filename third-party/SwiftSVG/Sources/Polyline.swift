import XMLCoder

/// SVG basic shape that creates straight lines connecting several points.
///
/// Typically a polyline is used to create open shapes as the last point doesn't have to be connected to the first
/// point. For closed shapes see the `Polygon` element.
///
/// ## Documentation
/// [Mozilla Developer Network](https://developer.mozilla.org/en-US/docs/Web/SVG/Element/polyline)
/// | [W3](https://www.w3.org/TR/SVG11/shapes.html#PolylineElement)
public struct Polyline: Element {

    public var points: String = ""

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
        case points
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

    public init(points: String) {
        self.points = points
    }
}

extension Polyline: CommandRepresentable {
    public func commands() throws -> [Path.Command] {
        try PolylineProcessor(points: points).commands()
    }
}

extension Polyline: CustomStringConvertible {
    public var description: String {
        "<polyline points=\"\(points)\" \(attributeDescription) />"
    }
}

extension Polyline: DynamicNodeDecoding {
    public static func nodeDecoding(for key: any CodingKey) -> XMLDecoder.NodeDecoding {
        .attribute
    }
}

extension Polyline: DynamicNodeEncoding {
    public static func nodeEncoding(for key: any CodingKey) -> XMLEncoder.NodeEncoding {
        .attribute
    }
}
