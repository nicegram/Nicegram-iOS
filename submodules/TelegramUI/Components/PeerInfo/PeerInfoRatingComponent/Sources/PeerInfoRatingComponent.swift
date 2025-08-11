import Foundation
import UIKit
import Display
import ComponentFlow
import MultilineTextComponent
import Svg

public final class PeerInfoRatingComponent: Component {
    let backgroundColor: UIColor
    let borderColor: UIColor
    let foregroundColor: UIColor
    let level: Int
    let action: () -> Void
    
    public init(
        backgroundColor: UIColor,
        borderColor: UIColor,
        foregroundColor: UIColor,
        level: Int,
        action: @escaping () -> Void
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.foregroundColor = foregroundColor
        self.level = level
        self.action = action
    }
    
    public static func ==(lhs: PeerInfoRatingComponent, rhs: PeerInfoRatingComponent) -> Bool {
        if lhs.backgroundColor != rhs.backgroundColor {
            return false
        }
        if lhs.borderColor != rhs.borderColor {
            return false
        }
        if lhs.foregroundColor != rhs.foregroundColor {
            return false
        }
        if lhs.level != rhs.level {
            return false
        }
        return true
    }
    
    private struct TextLayout {
        var size: CGSize
        var opticalBounds: CGRect
        
        init(size: CGSize, opticalBounds: CGRect) {
            self.size = size
            self.opticalBounds = opticalBounds
        }
    }
    
    public final class View: UIView {
        private let borderLayer: SimpleLayer
        private let backgroundLayer: SimpleLayer
        
        //private var tempLevel: Int = 1
        
        private var component: PeerInfoRatingComponent?
        private weak var state: EmptyComponentState?
        
        override public init(frame: CGRect) {
            self.borderLayer = SimpleLayer()
            self.backgroundLayer = SimpleLayer()
            
            super.init(frame: frame)
            
            self.layer.addSublayer(self.borderLayer)
            self.layer.addSublayer(self.backgroundLayer)
            
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onTapGesture(_:))))
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func onTapGesture(_ recognizer: UITapGestureRecognizer) {
            if case .ended = recognizer.state {
                self.component?.action()
                
                /*if self.tempLevel < 10 {
                    self.tempLevel += 1
                } else {
                    self.tempLevel += 10
                }
                if self.tempLevel >= 110 {
                    self.tempLevel = 1
                }
                self.state?.updated(transition: .immediate)*/
            }
        }
        
        func update(component: PeerInfoRatingComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
            let size = CGSize(width: 30.0, height: 30.0)
            
            let alphaTransition: ComponentTransition = transition.animation.isImmediate ? .immediate : .easeInOut(duration: 0.2)
            
            let previousComponent = self.component
            self.component = component
            self.state = state
            
            let level = component.level
            //let level = self.tempLevel
            
            let iconSize = CGSize(width: 26.0, height: 26.0)
            
            if previousComponent?.level != level || previousComponent?.borderColor != component.borderColor || previousComponent?.foregroundColor != component.foregroundColor || previousComponent?.backgroundColor != component.backgroundColor || "".isEmpty {
                let attributedText = NSAttributedString(string: "\(level)", attributes: [
                    NSAttributedString.Key.font: Font.semibold(10.0),
                    NSAttributedString.Key.foregroundColor: component.foregroundColor
                ])
                
                var boundingRect = attributedText.boundingRect(with: CGSize(width: 100.0, height: 100.0), options: .usesLineFragmentOrigin, context: nil)
                boundingRect.size.width = ceil(boundingRect.size.width)
                boundingRect.size.height = ceil(boundingRect.size.height)
                
                var textLayout: TextLayout?
                if let context = DrawingContext(size: boundingRect.size, scale: 0.0, opaque: false, clear: true) {
                    context.withContext { c in
                        UIGraphicsPushContext(c)
                        defer {
                            UIGraphicsPopContext()
                        }
                        
                        attributedText.draw(at: CGPoint())
                    }
                    var minFilledLineY = Int(context.scaledSize.height) - 1
                    var maxFilledLineY = 0
                    var minFilledLineX = Int(context.scaledSize.width) - 1
                    var maxFilledLineX = 0
                    for y in 0 ..< Int(context.scaledSize.height) {
                        let linePtr = context.bytes.advanced(by: max(0, y) * context.bytesPerRow).assumingMemoryBound(to: UInt32.self)
                        
                        for x in 0 ..< Int(context.scaledSize.width) {
                            let pixelPtr = linePtr.advanced(by: x)
                            if pixelPtr.pointee != 0 {
                                minFilledLineY = min(y, minFilledLineY)
                                maxFilledLineY = max(y, maxFilledLineY)
                                minFilledLineX = min(x, minFilledLineX)
                                maxFilledLineX = max(x, maxFilledLineX)
                            }
                        }
                    }
                    
                    var opticalBounds = CGRect()
                    if minFilledLineX <= maxFilledLineX && minFilledLineY <= maxFilledLineY {
                        opticalBounds.origin.x = CGFloat(minFilledLineX) / context.scale
                        opticalBounds.origin.y = CGFloat(minFilledLineY) / context.scale
                        opticalBounds.size.width = CGFloat(maxFilledLineX - minFilledLineX) / context.scale
                        opticalBounds.size.height = CGFloat(maxFilledLineY - minFilledLineY) / context.scale
                    }
                    
                    textLayout = TextLayout(size: boundingRect.size, opticalBounds: opticalBounds)
                }
                
                let levelIndex: Int
                if level <= 10 {
                    levelIndex = max(0, component.level)
                } else if level <= 90 {
                    levelIndex = (level / 10) * 10
                } else {
                    levelIndex = 90
                }
                let borderImage = generateImage(iconSize, rotatedContext: { size, context in
                    UIGraphicsPushContext(context)
                    defer {
                        UIGraphicsPopContext()
                    }
                    
                    context.clear(CGRect(origin: CGPoint(), size: size))
                    
                    if let url = Bundle.main.url(forResource: "profile_level\(levelIndex)_outer", withExtension: "svg"), let data = try? Data(contentsOf: url) {
                        if let image = generateTintedImage(image: drawSvgImage(data, size, nil, nil, 0.0, false), color: component.borderColor) {
                            image.draw(in: CGRect(origin: CGPoint(), size: size), blendMode: .normal, alpha: 1.0)
                        }
                    }
                })
                
                if let previousContents = self.borderLayer.contents, CFGetTypeID(previousContents as CFTypeRef) == CGImage.typeID {
                    self.borderLayer.contents = borderImage!.cgImage
                    alphaTransition.animateContentsImage(layer: self.borderLayer, from: previousContents as! CGImage, to: borderImage!.cgImage!, duration: 0.2, curve: .easeInOut)
                } else {
                    self.borderLayer.contents = borderImage!.cgImage
                }
                
                let backgroundImage = generateImage(iconSize, rotatedContext: { size, context in
                    UIGraphicsPushContext(context)
                    defer {
                        UIGraphicsPopContext()
                    }
                    
                    context.clear(CGRect(origin: CGPoint(), size: size))
                    
                    if let url = Bundle.main.url(forResource: "profile_level\(levelIndex)_inner", withExtension: "svg"), let data = try? Data(contentsOf: url) {
                        if let image = generateTintedImage(image: drawSvgImage(data, size, nil, nil, 0.0, false), color: component.backgroundColor) {
                            image.draw(in: CGRect(origin: CGPoint(), size: size), blendMode: .normal, alpha: 1.0)
                        }
                    }
                    
                    if component.foregroundColor.alpha < 1.0 {
                        context.setBlendMode(.copy)
                    } else {
                        context.setBlendMode(.normal)
                    }
                    
                    if let textLayout {
                        let titleScale: CGFloat
                        if level < 10 {
                            titleScale = 1.0
                        } else if level < 100 {
                            titleScale = 0.8
                        } else {
                            titleScale = 0.6
                        }
                        
                        var textFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - textLayout.size.width) * 0.5), y: floorToScreenPixels((size.height - textLayout.size.height) * 0.5)), size: textLayout.size)
                        if level == 1 {
                            textFrame.origin.x += UIScreenPixel
                        } else {
                            textFrame.origin.x += 0.0
                        }
                        
                        context.saveGState()
                        context.translateBy(x: textFrame.midX, y: textFrame.midY)
                        context.scaleBy(x: titleScale, y: titleScale)
                        context.translateBy(x: -textFrame.midX, y: -textFrame.midY)
                        
                        attributedText.draw(at: textFrame.origin)
                        
                        context.restoreGState()
                    }
                })
                if let previousContents = self.backgroundLayer.contents, CFGetTypeID(previousContents as CFTypeRef) == CGImage.typeID {
                    self.backgroundLayer.contents = backgroundImage!.cgImage
                    alphaTransition.animateContentsImage(layer: self.backgroundLayer, from: previousContents as! CGImage, to: backgroundImage!.cgImage!, duration: 0.2, curve: .easeInOut)
                } else {
                    self.backgroundLayer.contents = backgroundImage!.cgImage
                }
            }
            
            let backgroundFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - iconSize.width) * 0.5), y: floorToScreenPixels((size.height - iconSize.height) * 0.5)), size: iconSize)
            transition.setFrame(layer: self.backgroundLayer, frame: backgroundFrame)
            transition.setFrame(layer: self.borderLayer, frame: backgroundFrame)
            
            return size
        }
    }
    
    public func makeView() -> View {
        return View(frame: CGRect())
    }
    
    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}
