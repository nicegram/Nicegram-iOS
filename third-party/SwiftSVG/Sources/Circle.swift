import Swift2D
import XMLCoder

/// Basic shape, used to draw circles based on a center point and a radius.
///
/// The arc of a ‘circle’ element begins at the "3 o'clock" point on the radius and progresses towards the
/// "9 o'clock" point. The starting point and direction of the arc are affected by the user space transform
/// in the same manner as the geometry of the element.
///
/// ## Documentation
/// [Mozilla Developer Network](https://developer.mozilla.org/en-US/docs/Web/SVG/Element/circle)
/// | [W3](https://www.w3.org/TR/SVG11/shapes.html#CircleElement)
public struct Circle: Element {

    /// The x-axis coordinate of the center of the circle.
    public var x: Double = 0.0
    /// The y-axis coordinate of the center of the circle.
    public var y: Double = 0.0
    /// The radius of the circle.
    public var r: Double = 0.0

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
        case x = "cx"
        case y = "cy"
        case r
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

    public init(x: Double, y: Double, r: Double) {
        self.x = x
        self.y = y
        self.r = r
    }
}

extension Circle: CustomStringConvertible {
    public var description: String {
        let desc = "<circle cx=\"\(x)\" cy=\"\(y)\" r=\"\(r)\""
        return desc + " \(attributeDescription) />"
    }
}

extension Circle: DirectionalCommandRepresentable {
    public func commands(clockwise: Bool) throws -> [Path.Command] {
        EllipseProcessor(circle: self).commands(clockwise: clockwise)
    }
}

extension Circle: DynamicNodeDecoding {
    public static func nodeDecoding(for key: any CodingKey) -> XMLDecoder.NodeDecoding {
        .attribute
    }
}

extension Circle: DynamicNodeEncoding {
    public static func nodeEncoding(for key: any CodingKey) -> XMLEncoder.NodeEncoding {
        .attribute
    }
}
