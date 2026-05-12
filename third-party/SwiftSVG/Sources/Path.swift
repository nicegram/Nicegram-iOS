import XMLCoder

/// Generic element to define a shape.
///
/// A path is defined by including a ‘path’ element in a SVG document which contains a **d="(path data)"**
/// attribute, where the **‘d’** attribute contains the moveto, line, curve (both Cubic and Quadratic Bézier),
/// arc and closepath instructions.
///
/// ## Documentation
/// [Mozilla Developer Network](https://developer.mozilla.org/en-US/docs/Web/SVG/Element/path)
/// | [W3](https://www.w3.org/TR/SVG11/paths.html)
public struct Path: Element {

    /// The definition of the outline of a shape.
    public var data: String = ""

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
        case data = "d"
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

    public init(data: String) {
        self.init()
        self.data = data
    }

    public init(commands: [Path.Command]) {
        self.init()
        data = commands.map(\.description).joined()
    }
}

extension Path: CommandRepresentable {
    public func commands() throws -> [Command] {
        try PathProcessor(data: data).commands()
    }
}

extension Path: CustomStringConvertible {
    public var description: String {
        "<path d=\"\(data)\" \(attributeDescription) />"
    }
}

extension Path: DynamicNodeDecoding {
    public static func nodeDecoding(for key: any CodingKey) -> XMLDecoder.NodeDecoding {
        .attribute
    }
}

extension Path: DynamicNodeEncoding {
    public static func nodeEncoding(for key: any CodingKey) -> XMLEncoder.NodeEncoding {
        .attribute
    }
}

extension Path: Equatable {
    public static func == (lhs: Path, rhs: Path) -> Bool {
        do {
            let lhsCommands = try lhs.commands()
            let rhsCommands = try rhs.commands()
            return lhsCommands == rhsCommands
        } catch {
            return false
        }
    }
}
