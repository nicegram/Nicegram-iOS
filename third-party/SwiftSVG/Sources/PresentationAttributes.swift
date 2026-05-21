import Foundation
import Swift2D

public protocol PresentationAttributes {
    var fillColor: String? { get set }
    var fillOpacity: Double? { get set }
    var fillRule: Fill.Rule? { get set }
    var strokeColor: String? { get set }
    var strokeWidth: Double? { get set }
    var strokeOpacity: Double? { get set }
    var strokeLineCap: Stroke.LineCap? { get set }
    var strokeLineJoin: Stroke.LineJoin? { get set }
    var strokeMiterLimit: Double? { get set }
    var transform: String? { get set }
}

enum PresentationAttributesKeys: String, CodingKey {
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
}

public extension PresentationAttributes {
    var presentationDescription: String {
        var attributes: [String] = []

        if let fillColor {
            attributes.append("\(PresentationAttributesKeys.fillColor.rawValue)=\"\(fillColor)\"")
        }
        if let fillOpacity {
            attributes.append("\(PresentationAttributesKeys.fillOpacity.rawValue)=\"\(fillOpacity)\"")
        }
        if let fillRule {
            attributes.append("\(PresentationAttributesKeys.fillRule.rawValue)=\"\(fillRule.description)\"")
        }
        if let strokeColor {
            attributes.append("\(PresentationAttributesKeys.strokeColor.rawValue)=\"\(strokeColor)\"")
        }
        if let strokeWidth {
            attributes.append("\(PresentationAttributesKeys.strokeWidth.rawValue)=\"\(strokeWidth)\"")
        }
        if let strokeOpacity {
            attributes.append("\(PresentationAttributesKeys.strokeOpacity.rawValue)=\"\(strokeOpacity)\"")
        }
        if let strokeLineCap {
            attributes.append("\(PresentationAttributesKeys.strokeLineCap.rawValue)=\"\(strokeLineCap.description)\"")
        }
        if let strokeLineJoin {
            attributes.append("\(PresentationAttributesKeys.strokeLineJoin.rawValue)=\"\(strokeLineJoin.description)\"")
        }
        if let strokeMiterLimit {
            attributes.append("\(PresentationAttributesKeys.strokeMiterLimit.rawValue)=\"\(strokeMiterLimit)\"")
        }
        if let transform {
            attributes.append("\(PresentationAttributesKeys.transform.rawValue)=\"\(transform)\"")
        }

        return attributes.joined(separator: " ")
    }

    var transformations: [Transformation] {
        let value = transform?.replacingOccurrences(of: " ", with: "") ?? ""
        guard !value.isEmpty else {
            return []
        }

        let values = value.split(separator: ")").map { $0.appending(")") }
        return values.compactMap { Transformation($0) }
    }

    var fill: Fill? {
        get {
            if fillColor == nil, fillOpacity == nil {
                return nil
            }

            var fill = Fill()
            fill.color = fillColor ?? "black"
            fill.opacity = fillOpacity ?? 1.0
            return fill
        }
        set {
            fillColor = newValue?.color
            fillOpacity = newValue?.opacity
            fillRule = newValue?.rule
        }
    }

    var stroke: Stroke? {
        get {
            if strokeColor == nil, strokeOpacity == nil {
                return nil
            }

            var stroke = Stroke()
            stroke.color = strokeColor ?? "black"
            stroke.opacity = strokeOpacity ?? 1.0
            stroke.width = strokeWidth ?? 1.0
            stroke.lineCap = strokeLineCap ?? .butt
            stroke.lineJoin = strokeLineJoin ?? .miter
            stroke.miterLimit = strokeMiterLimit
            return stroke
        }
        set {
            strokeColor = newValue?.color
            strokeOpacity = newValue?.opacity
            strokeWidth = newValue?.width
            strokeLineCap = newValue?.lineCap
            strokeLineJoin = newValue?.lineJoin
            strokeMiterLimit = newValue?.miterLimit
        }
    }
}
