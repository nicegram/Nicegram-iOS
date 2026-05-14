public protocol Element: CoreAttributes, PresentationAttributes, StylingAttributes {}

public extension Element {
    var attributeDescription: String {
        var components: [String] = []

        if !coreDescription.isEmpty {
            components.append(coreDescription)
        }
        if !presentationDescription.isEmpty {
            components.append(presentationDescription)
        }
        if !stylingDescription.isEmpty {
            components.append(stylingDescription)
        }

        return components.joined(separator: " ")
    }
}

public extension CommandRepresentable where Self: Element {
    /// When a `Path` is accessed on an element, the path that is returned should have the supplied transformations
    /// applied.
    ///
    /// For instance, if
    /// * a `Path.data` contains relative elements,
    /// * and `transformations` contains a `.translate`
    ///
    /// Than the path created will not only use 'absolute' instructions, but those instructions will be modified to
    /// include the required transformation.
    func path(applying transformations: [Transformation] = []) throws -> Path {
        var _transformations = transformations
        _transformations.append(contentsOf: self.transformations)

        let commands = try commands().map { $0.applying(transformations: _transformations) }

        var path = Path(commands: commands)
        path.fillColor = fillColor
        path.fillOpacity = fillOpacity
        path.strokeColor = strokeColor
        path.strokeOpacity = strokeOpacity
        path.strokeWidth = strokeWidth

        return path
    }
}
