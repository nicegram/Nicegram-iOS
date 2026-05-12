import Swift2D
import SwiftColor
import SwiftSVG
#if canImport(CoreGraphics)
import CoreGraphics

public extension CGContext {
    func render(path: Path, from: Rect, to: Rect) throws {
        saveGState()

        let cgPath = CGMutablePath()

        let commands = (try? path.commands()) ?? []
        for (idx, command) in commands.enumerated() {
            let previous: Point? = if idx > 0 {
                commands[idx - 1].previousPoint
            } else {
                nil
            }

            cgPath.addCommand(command, from: from, to: to, previousPoint: previous)
        }

        if let fill = path.fill {
            let _color = Pigment(fill.color ?? "black")
            if _color.alpha != 0.0 {
                let cgColor = CGColor.make(_color)
                let color = cgColor.copy(alpha: CGFloat(fill.opacity ?? 1.0)) ?? cgColor
                let rule = fill.rule.cgFillRule

                setFillColor(color)
                addPath(cgPath)
                fillPath(using: rule)
            }
        }

        if let stroke = path.stroke {
            let _color = Pigment(stroke.color ?? "black")
            if _color.alpha != 0.0 {
                let cgColor = CGColor.make(_color)
                let color = cgColor.copy(alpha: CGFloat(stroke.opacity ?? 1.0)) ?? cgColor
                let width = stroke.width ?? 1.0
                let lineWidth = width * (to.size.width / from.size.width)

                setLineWidth(CGFloat(lineWidth))
                setStrokeColor(color)
                setLineCap(stroke.lineCap.cgLineCap)
                setLineJoin(stroke.lineJoin.cgLineJoin)
                if let miterLimit = stroke.miterLimit, stroke.lineJoin == .miter {
                    setMiterLimit(CGFloat(miterLimit))
                }
                addPath(cgPath)
                strokePath()
            }
        }

        if path.fill == nil, path.stroke == nil {
            let color = CGColor(srgbRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            setFillColor(color)
            addPath(cgPath)
            fillPath(using: path.fill?.rule.cgFillRule ?? .winding)
        }

        restoreGState()
    }

    func render(path: Path, in rect: Rect) throws {
        try render(path: path, from: rect, to: rect)
    }
}

#endif
