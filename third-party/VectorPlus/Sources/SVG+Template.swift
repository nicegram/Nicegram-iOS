import Foundation
import Swift2D
import SwiftSVG

public extension SVG {
    func asImageViewSubclass() throws -> String {
        let instructions = try asCoreGraphicsDescription()
        let renders = try asCGContextDescription()

        return imageViewSubclassTemplate
            .replacingOccurrences(of: "{{name}}", with: name)
            .replacingOccurrences(of: "{{width}}", with: String(format: "%.1f", originalSize.width))
            .replacingOccurrences(of: "{{height}}", with: String(format: "%.1f", originalSize.height))
            .replacingOccurrences(of: "{{instructions}}", with: instructions)
            .replacingOccurrences(of: "{{render}}", with: renders)
    }
}

private extension SVG {
    func asCoreGraphicsDescription(variable: String = "path") throws -> String {
        try subpaths().map { try $0.asCoreGraphicsDescription(variable: variable, originalSize: originalSize) }.joined(separator: "\n        ")
    }

    func asCGContextDescription() throws -> String {
        var outputs: [String] = []

        let paths = try subpaths()
        try paths.forEach { path in
            let instructions = try path.asCoreGraphicsDescription(variable: "path", originalSize: originalSize)
            let fillColor = path.fill?.pigment?.coreGraphicsDescription ?? "nil"
            let fillOpacity = (path.fillOpacity != nil) ? "\(path.fillOpacity!)" : "nil"
            let fillRule = (path.fillRule ?? .nonZero).coreGraphicsDescription
            let strokeColor = path.stroke?.pigment?.coreGraphicsDescription ?? "nil"
            let strokeOpacity = (path.strokeOpacity != nil) ? "\(path.strokeOpacity!)" : "nil"
            let strokeWidth = (path.strokeWidth != nil) ? "\(path.strokeWidth!) * (size.width / width)" : "nil"
            let strokeLineCap = (path.strokeLineCap != nil) ? "\(path.strokeLineCap!.coreGraphicsDescription)" : "nil"
            let strokeLineJoin = (path.strokeLineJoin != nil) ? "\(path.strokeLineJoin!.coreGraphicsDescription)" : "nil"
            let strokeMiterLimit = (path.strokeMiterLimit != nil) ? "\(path.strokeMiterLimit!)" : "nil"

            outputs.append(contextTemplate
                .replacingOccurrences(of: "{{instructions}}", with: instructions)
                .replacingOccurrences(of: "{{fillColor}}", with: fillColor)
                .replacingOccurrences(of: "{{fillOpacity}}", with: fillOpacity)
                .replacingOccurrences(of: "{{fillRule}}", with: fillRule)
                .replacingOccurrences(of: "{{strokeColor}}", with: strokeColor)
                .replacingOccurrences(of: "{{strokeOpacity}}", with: strokeOpacity)
                .replacingOccurrences(of: "{{strokeWidth}}", with: strokeWidth)
                .replacingOccurrences(of: "{{strokeLineCap}}", with: strokeLineCap)
                .replacingOccurrences(of: "{{strokeLineJoin}}", with: strokeLineJoin)
                .replacingOccurrences(of: "{{strokeMiterLimit}}", with: strokeMiterLimit)
            )
        }

        return outputs.joined(separator: "\n        ")
    }
}
