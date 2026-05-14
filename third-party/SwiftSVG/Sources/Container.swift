public protocol Container {
    var circles: [Circle]? { get set }
    var ellipses: [Ellipse]? { get set }
    var groups: [Group]? { get set }
    var lines: [Line]? { get set }
    var paths: [Path]? { get set }
    var polygons: [Polygon]? { get set }
    var polylines: [Polyline]? { get set }
    var rectangles: [Rectangle]? { get set }
    var texts: [Text]? { get set }
}

enum ContainerKeys: String, CodingKey {
    case circles = "circle"
    case ellipses = "ellipse"
    case groups = "g"
    case lines = "line"
    case paths = "path"
    case polylines = "polyline"
    case polygons = "polygon"
    case rectangles = "rect"
    case texts = "text"
}

public extension Container {
    var containerDescription: String {
        var contents: String = ""

        let circles = circles?.compactMap(\.description) ?? []
        circles.forEach { contents.append("\n\($0)") }

        let ellipses = ellipses?.compactMap(\.description) ?? []
        ellipses.forEach { contents.append("\n\($0)") }

        let groups = groups?.compactMap(\.description) ?? []
        groups.forEach { contents.append("\n\($0)") }

        let lines = lines?.compactMap(\.description) ?? []
        lines.forEach { contents.append("\n\($0)") }

        let paths = paths?.compactMap(\.description) ?? []
        paths.forEach { contents.append("\n\($0)") }

        let polylines = polylines?.compactMap(\.description) ?? []
        polylines.forEach { contents.append("\n\($0)") }

        let polygons = polygons?.compactMap(\.description) ?? []
        polygons.forEach { contents.append("\n\($0)") }

        let rectangles = rectangles?.compactMap(\.description) ?? []
        rectangles.forEach { contents.append("\n\($0)") }

        let texts = texts?.compactMap(\.description) ?? []
        texts.forEach { contents.append("\n\($0)") }

        return contents
    }
}
