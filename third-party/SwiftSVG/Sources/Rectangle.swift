import Swift2D
import XMLCoder

/// Basic SVG shape that draws rectangles, defined by their position, width, and height.
///
/// The values used for the x- and y-axis rounded corner radii are determined implicitly
/// if the ‘rx’ or ‘ry’ attributes (or both) are not specified, or are specified but with invalid values.
///
/// ## Documentation
/// [Mozilla Developer Network](https://developer.mozilla.org/en-US/docs/Web/SVG/Element/rect)
/// | [W3](https://www.w3.org/TR/SVG11/shapes.html#RectElement)
public struct Rectangle: Element {

    /// The x-axis coordinate of the side of the rectangle which
    /// has the smaller x-axis coordinate value.
    public var x: Double = 0.0
    /// The y-axis coordinate of the side of the rectangle which
    /// has the smaller y-axis coordinate value
    public var y: Double = 0.0
    /// The width of the rectangle.
    public var width: Double = 0.0
    /// The height of the rectangle.
    public var height: Double = 0.0
    /// For rounded rectangles, the x-axis radius of the ellipse used
    /// to round off the corners of the rectangle.
    public var rx: Double?
    /// For rounded rectangles, the y-axis radius of the ellipse used
    /// to round off the corners of the rectangle.
    public var ry: Double?

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
        case x
        case y
        case width
        case height
        case rx
        case ry
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

    public init(x: Double, y: Double, width: Double, height: Double, rx: Double? = nil, ry: Double? = nil) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rx = rx
        self.ry = ry
    }
}

extension Rectangle: CustomStringConvertible {
    public var description: String {
        var desc = "<rect x=\"\(x)\" y=\"\(y)\" width=\"\(width)\" height=\"\(height)\""
        if let rx {
            desc.append(" rx=\"\(rx)\"")
        }
        if let ry {
            desc.append(" ry=\"\(ry)\"")
        }

        return desc + " \(attributeDescription) />"
    }
}

extension Rectangle: DirectionalCommandRepresentable {
    public func commands(clockwise: Bool) throws -> [Path.Command] {
        RectangleProcessor(rectangle: self).commands(clockwise: clockwise)
    }
}

extension Rectangle: DynamicNodeDecoding {
    public static func nodeDecoding(for key: any CodingKey) -> XMLDecoder.NodeDecoding {
        .attribute
    }
}

extension Rectangle: DynamicNodeEncoding {
    public static func nodeEncoding(for key: any CodingKey) -> XMLEncoder.NodeEncoding {
        .attribute
    }
}
