import Foundation
import UIKit
import Display
import ComponentFlow
import MultilineTextComponent
import TelegramPresentationData
import GlassBackgroundComponent

extension CameraMode {
    func title(strings: PresentationStrings) -> String {
        switch self {
        case .photo:
            return strings.Story_Camera_Photo
        case .video:
            return strings.Story_Camera_Video
        case .live:
            return strings.Story_Camera_Live
        }
    }
}

private let buttonSize = CGSize(width: 55.0, height: 48.0)
private let tabletButtonSize = CGSize(width: 55.0, height: 44.0)

final class ModeComponent: Component {
    let isTablet: Bool
    let strings: PresentationStrings
    let tintColor: UIColor
    let availableModes: [CameraMode]
    let currentMode: CameraMode
    let updatedMode: (CameraMode) -> Void
    let tag: AnyObject?
    
    init(
        isTablet: Bool,
        strings: PresentationStrings,
        tintColor: UIColor,
        availableModes: [CameraMode],
        currentMode: CameraMode,
        updatedMode: @escaping (CameraMode) -> Void,
        tag: AnyObject?
    ) {
        self.isTablet = isTablet
        self.strings = strings
        self.tintColor = tintColor
        self.availableModes = availableModes
        self.currentMode = currentMode
        self.updatedMode = updatedMode
        self.tag = tag
    }
    
    static func ==(lhs: ModeComponent, rhs: ModeComponent) -> Bool {
        if lhs.isTablet != rhs.isTablet {
            return false
        }
        if lhs.strings !== rhs.strings {
            return false
        }
        if lhs.tintColor != rhs.tintColor {
            return false
        }
        if lhs.availableModes != rhs.availableModes {
            return false
        }
        if lhs.currentMode != rhs.currentMode {
            return false
        }
        return true
    }
    
    final class View: UIView, ComponentTaggedView {
        private var component: ModeComponent?
        
        final class ItemView: HighlightTrackingButton {
            var pressed: () -> Void = {
                
            }
            
            init() {
                super.init(frame: .zero)
                
                self.isExclusiveTouch = true
                
                self.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
            }
            
            required init(coder: NSCoder) {
                preconditionFailure()
            }
            
            @objc func buttonPressed() {
                self.pressed()
            }
            
            func update(isTablet: Bool, value: String, selected: Bool, tintColor: UIColor) -> CGSize {
                let accentColor: UIColor
                let normalColor: UIColor
                if tintColor.rgb == 0xffffff {
                    accentColor = UIColor(rgb: 0xffd300)
                    normalColor = .white
                } else {
                    accentColor = tintColor
                    normalColor = tintColor.withAlphaComponent(0.5)
                }
                
                let title = NSMutableAttributedString(string: value.uppercased(), font: Font.with(size: 14.0, design: .regular, weight: .medium), textColor: selected ? accentColor : normalColor, paragraphAlignment: .center)
                title.addAttribute(.kern, value: -0.5 as NSNumber, range: NSMakeRange(0, title.length))
                self.setAttributedTitle(title, for: .normal)
                self.sizeToFit()
                
                return CGSize(width: self.titleLabel?.bounds.size.width ?? 0.0, height: isTablet ? tabletButtonSize.height : buttonSize.height)
            }
        }
        
        private var backgroundView = UIView()
        private var glassContainerView = GlassBackgroundContainerView()
        private var selectionView = GlassBackgroundView()
        private var itemViews: [Int32: ItemView] = [:]
        
        public func matches(tag: Any) -> Bool {
            if let component = self.component, let componentTag = component.tag {
                let tag = tag as AnyObject
                if componentTag === tag {
                    return true
                }
            }
            return false
        }
        
        init() {
            super.init(frame: CGRect())
            
            self.backgroundView.backgroundColor = UIColor(rgb: 0xffffff, alpha: 0.11)
            self.backgroundView.layer.cornerRadius = 24.0
            
            self.layer.allowsGroupOpacity = true
            
            self.addSubview(self.backgroundView)
            self.backgroundView.addSubview(self.glassContainerView)
            self.glassContainerView.contentView.addSubview(self.selectionView)
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }
        
        private var animatedOut = false
        func animateOutToEditor(transition: ComponentTransition) {
            self.animatedOut = true
            
            transition.setAlpha(view: self.backgroundView, alpha: 0.0)
            transition.setSublayerTransform(view: self, transform: CATransform3DMakeTranslation(0.0, -buttonSize.height, 0.0))
        }
        
        func animateInFromEditor(transition: ComponentTransition) {
            self.animatedOut = false
            
            transition.setAlpha(view: self.backgroundView, alpha: 1.0)
            transition.setSublayerTransform(view: self, transform: CATransform3DIdentity)
        }
        
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            return self.backgroundView.frame.contains(point)
        }
                
        func update(component: ModeComponent, availableSize: CGSize, transition: ComponentTransition) -> CGSize {
            self.component = component
        
            let isTablet = component.isTablet
            let updatedMode = component.updatedMode
            
            self.glassContainerView.isHidden = component.isTablet
            self.backgroundView.backgroundColor = component.isTablet ? .clear : UIColor(rgb: 0xffffff, alpha: 0.11)
        
            let inset: CGFloat = 23.0
            let spacing: CGFloat = isTablet ? 9.0 : 40.0
      
            var i = 0
            var itemFrame = CGRect(origin: isTablet ? .zero : CGPoint(x: inset, y: 0.0), size: buttonSize)
            var selectedCenter = itemFrame.minX
            var selectedFrame = itemFrame
            
            var validKeys: Set<Int32> = Set()
            for mode in component.availableModes.reversed() {
                let id = mode.rawValue
                validKeys.insert(id)
                
                let itemView: ItemView
                if let current = self.itemViews[id] {
                    itemView = current
                } else {
                    itemView = ItemView()
                    self.backgroundView.addSubview(itemView)
                    self.itemViews[id] = itemView
                }
                itemView.pressed = {
                    updatedMode(mode)
                }
               
                let itemSize = itemView.update(isTablet: component.isTablet, value: mode.title(strings: component.strings), selected: mode == component.currentMode, tintColor: component.tintColor)
                itemView.bounds = CGRect(origin: .zero, size: itemSize)
                itemFrame = CGRect(origin: itemFrame.origin, size: itemSize)
                
                if mode == component.currentMode {
                    selectedFrame = itemFrame
                }
                
                if isTablet {
                    itemView.center = CGPoint(x: availableSize.width / 2.0, y: itemFrame.midY)
                    if mode == component.currentMode {
                        selectedCenter = itemFrame.midY
                    }
                    itemFrame = itemFrame.offsetBy(dx: 0.0, dy: tabletButtonSize.height + spacing)
                } else {
                    itemView.center = CGPoint(x: itemFrame.midX, y: itemFrame.midY)
                    if mode == component.currentMode {
                        selectedCenter = itemFrame.midX
                    }
                    itemFrame = itemFrame.offsetBy(dx: itemFrame.width + spacing, dy: 0.0)
                }
                i += 1
            }
            
            var removeKeys: [Int32] = []
            for (id, itemView) in self.itemViews {
                if !validKeys.contains(id) {
                    removeKeys.append(id)
                    
                    transition.setAlpha(view: itemView, alpha: 0.0, completion: { _ in
                        itemView.removeFromSuperview()
                    })
                }
            }
            for id in removeKeys {
                self.itemViews.removeValue(forKey: id)
            }
            
            let totalSize: CGSize
            let size: CGSize
            if isTablet {
                totalSize = CGSize(width: availableSize.width, height: tabletButtonSize.height * CGFloat(component.availableModes.count) + spacing * CGFloat(component.availableModes.count - 1))
                size = CGSize(width: availableSize.width, height: availableSize.height)
                transition.setFrame(view: self.backgroundView, frame: CGRect(origin: CGPoint(x: 0.0, y: availableSize.height / 2.0 - selectedCenter), size: totalSize))
            } else {
                size = CGSize(width: availableSize.width, height: buttonSize.height)
                totalSize = CGSize(width: itemFrame.minX - spacing + inset, height: buttonSize.height)
                transition.setFrame(view: self.backgroundView, frame: CGRect(origin: CGPoint(x: floorToScreenPixels((availableSize.width - totalSize.width) / 2.0), y: 0.0), size: totalSize))
            }
            
            let containerFrame = CGRect(origin: .zero, size: self.backgroundView.frame.size)
            transition.setFrame(view: self.glassContainerView, frame: containerFrame)
            
            let selectionFrame = selectedFrame.insetBy(dx: -20.0, dy: 3.0)
            self.glassContainerView.update(size: containerFrame.size, isDark: true, transition: .immediate)
            self.selectionView.update(size: selectionFrame.size, cornerRadius: selectionFrame.height * 0.5, isDark: true, tintColor: .init(kind: .custom, color: UIColor(rgb: 0xffffff, alpha: 0.16)), transition: transition)
            transition.setFrame(view: self.selectionView, frame: selectionFrame)
            
            return size
        }
    }
    
    func makeView() -> View {
        return View()
    }

    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, transition: transition)
    }
}

final class HintLabelComponent: Component {
    let text: String
    let tintColor: UIColor
    
    init(
        text: String,
        tintColor: UIColor
    ) {
        self.text = text
        self.tintColor = tintColor
    }
    
    static func ==(lhs: HintLabelComponent, rhs: HintLabelComponent) -> Bool {
        if lhs.text != rhs.text {
            return false
        }
        if lhs.tintColor != rhs.tintColor {
            return false
        }
        return true
    }
    
    final class View: UIView {
        private var component: HintLabelComponent?
        private var componentView = ComponentView<Empty>()
        
        init() {
            super.init(frame: CGRect())
        }
        
        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }
            
        func update(component: HintLabelComponent, availableSize: CGSize, transition: ComponentTransition) -> CGSize {
            let previousComponent = self.component
            self.component = component
            
            if let previousText = previousComponent?.text, !previousText.isEmpty && previousText != component.text {
                if let componentView = self.componentView.view, let snapshotView = componentView.snapshotView(afterScreenUpdates: false) {
                    snapshotView.frame = componentView.frame
                    self.addSubview(snapshotView)
                    snapshotView.layer.animateScale(from: 1.0, to: 0.1, duration: 0.2, removeOnCompletion: false)
                    snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                        snapshotView?.removeFromSuperview()
                    })
                }
                
                self.componentView.view?.removeFromSuperview()
                self.componentView = ComponentView<Empty>()
            }
            
            let textSize = self.componentView.update(
                transition: .immediate,
                component: AnyComponent(
                    MultilineTextComponent(
                        text: .plain(NSAttributedString(string: component.text.uppercased(), font: Font.with(size: 14.0, design: .camera, weight: .semibold), textColor: component.tintColor)),
                        horizontalAlignment: .center
                    )
                ),
                environment: {},
                containerSize: availableSize
            )
            if let view = self.componentView.view {
                if view.superview == nil {
                    view.layer.animateScale(from: 0.1, to: 1.0, duration: 0.2)
                    view.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
                    self.addSubview(view)
                }
                
                view.frame = CGRect(origin: CGPoint(x: floorToScreenPixels((availableSize.width - textSize.width) / 2.0), y: 0.0), size: textSize)
            }
                        
            return CGSize(width: availableSize.width, height: textSize.height)
        }
    }
    
    func makeView() -> View {
        return View()
    }

    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, transition: transition)
    }
}
