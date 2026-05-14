let imageViewSubclassTemplate: String = """
#if canImport(UIKit)
import UIKit

@IBDesignable
public class {{name}}: UIImageView {
    
    public static let width: CGFloat = {{width}}
    public static let height: CGFloat = {{height}}
    public let width: CGFloat = {{width}}
    public let height: CGFloat = {{height}}
    
    public var widthToHeightAspectRatio: CGFloat {
        guard width != .nan, width > 0.0 else {
            return 0.0
        }
        
        guard height != .nan, height > 0.0 else {
            return 0.0
        }
        
        return width / height
    }
    
    public var heightToWidthAspectRatio: CGFloat {
        guard height != .nan, height > 0.0 else {
            return 0.0
        }
        
        guard width != .nan, width > 0.0 else {
            return 0.0
        }
        
        return height / width
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        updateSubviews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        updateSubviews()
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: width, height: height)
    }
    
    public override var bounds: CGRect {
        didSet {
            updateSubviews()
        }
    }
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        updateSubviews()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateSubviews()
    }
    
    public func updateSubviews() {
        image = Self.image(size: bounds.size)
    }
    
    public static func path(size: CGSize) -> CGPath {
        guard size.height > 0.0 && size.width > 0.0 else {
            return CGMutablePath()
        }
        
        let radius = max(size.width / 2.0, size.height / 2.0)
        let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        
        let path = CGMutablePath()
        {{instructions}}
        return path
    }
    
    public static func image(size: CGSize) -> UIImage? {
        guard size.height > 0.0 && size.width > 0.0 else {
            return nil
        }
        
        let radius = max(size.width / 2.0, size.height / 2.0)
        let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        
        defer {
            UIGraphicsEndImageContext()
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        {{render}}
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private static func radians(_ degree: Float) -> CGFloat {
        return CGFloat(degree) * (.pi / CGFloat(180))
    }
}

private extension CGContext {
    func rendering(_ block: (CGContext) -> Void) {
        block(self)
    }
}

#endif

"""

let contextTemplate: String = """
        context.rendering { (ctx) in
            ctx.saveGState()
            
            let path = CGMutablePath()
            {{instructions}}
            
            let defaultColor: CGColor = CGColor(srgbRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            let pathFillColor: CGColor? = {{fillColor}}
            let pathFillOpacity: CGFloat? = {{fillOpacity}}
            let pathFillRule: CGPathFillRule = {{fillRule}}
            let pathStrokeColor: CGColor? = {{strokeColor}}
            let pathStrokeOpacity: CGFloat? = {{strokeOpacity}}
            let pathStrokeWidth: CGFloat? = {{strokeWidth}}
            let pathStrokeLineCap: CGLineCap? = {{strokeLineCap}}
            let pathStrokeLineJoin: CGLineJoin? = {{strokeLineJoin}}
            let pathStrokeMiterLimit: CGFloat? = {{strokeMiterLimit}}

            if pathFillColor != nil && pathFillOpacity != nil {
                let opacity = pathFillOpacity ?? 1.0
                let color = (pathFillColor ?? defaultColor).copy(alpha: opacity) ?? defaultColor
                
                ctx.setFillColor(color)
                ctx.addPath(path)
                ctx.fillPath(using: pathFillRule)
            }
            
            if pathStrokeColor != nil && pathStrokeOpacity != nil {
                let opacity = pathStrokeOpacity ?? 1.0
                let color = (pathStrokeColor ?? defaultColor).copy(alpha: opacity) ?? defaultColor
                let lineWidth = pathStrokeWidth ?? 1.0
                
                ctx.setLineWidth(lineWidth)
                ctx.setStrokeColor(color)
                if let lineCap = pathStrokeLineCap {
                    ctx.setLineCap(lineCap)
                }
                if let lineJoin = pathStrokeLineJoin {
                    ctx.setLineJoin(lineJoin)
                    if let miterLimit = pathStrokeMiterLimit, lineJoin == .miter {
                        ctx.setMiterLimit(miterLimit)
                    }
                }
                ctx.addPath(path)
                ctx.strokePath()
            }
            
            if (pathFillColor == nil && pathFillOpacity == nil) && (pathStrokeColor == nil && pathStrokeOpacity == nil) {
                ctx.setFillColor(defaultColor)
                ctx.addPath(path)
                ctx.fillPath(using: pathFillRule)
            }
            
            ctx.restoreGState()
        }
"""
