import Swift2D

public struct Stroke {

    public var color: String?
    public var width: Double?
    public var opacity: Double?
    public var lineCap: LineCap = .butt
    public var lineJoin: LineJoin = .miter
    public var miterLimit: Double?

    public init() {}

    /// Presentation attribute defining the shape to be used at the end of open subpaths when they are stroked.
    ///
    /// The default `LineCap` is `.butt`
    public enum LineCap: String, Sendable, Codable, CaseIterable {
        /// The stroke for each subpath does not extend beyond its two endpoints.
        case butt
        /// The end of each subpath the stroke will be extended by a half circle with a diameter equal to the stroke
        /// width.
        case round
        /// The end of each subpath the stroke will be extended by a rectangle with a width equal to half the width of
        /// the stroke and a height equal to the width of the stroke.
        case square
    }

    /// Presentation attribute defining the shape to be used at the corners of paths when they are stroked.
    ///
    /// The default `LineJoin` is `.miter`
    public enum LineJoin: String, Sendable, Codable, CaseIterable {
        /// An arcs corner is to be used to join path segments.
        ///
        /// The arcs shape is formed by extending the outer edges of the stroke at the join point with arcs that have
        /// the same curvature as the outer edges at the join point.
        case arcs
        /// The bevel value indicates that a bevelled corner is to be used to join path segments.
        case bevel
        /// Indicates that a sharp corner is to be used to join path segments.
        ///
        /// The corner is formed by extending the outer edges of the stroke at the tangents of the path segments until
        /// they intersect.
        case miter
        /// A sharp corner is to be used to join path segments.
        ///
        /// The corner is formed by extending the outer edges of the stroke at the tangents of the path segments until
        /// they intersect.
        case miterClip = "miter-clip"
        /// The round value indicates that a round corner is to be used to join path segments.
        case round
    }
}

extension Stroke.LineCap: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

extension Stroke.LineJoin: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
