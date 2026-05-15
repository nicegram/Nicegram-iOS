import Swift2D

public extension Rect {
    var coreGraphicsDescription: String {
        "CGRect(origin: \(origin.coreGraphicsDescription), size: \(size.coreGraphicsDescription))"
    }
}
