import Foundation
import UIKit
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import UrlEscaping
import ComponentFlow
import StarsWithdrawalScreen

private final class GiftAuctionCustomBidAlertContentNode: AlertContentNode {
    private let theme: PresentationTheme
    private let strings: PresentationStrings
    private let dateTimeFormat: PresentationDateTimeFormat
    private let title: String
    private let text: String
    private let placeholder: String
    private let minValue: Int64
    fileprivate var value: Int64
    
    private let titleNode: ASTextNode
    private let textNode: ASTextNode
    private let backgroundView = UIImageView()
    let amountField = ComponentView<Empty>()
    
    private let actionNodesSeparator: ASDisplayNode
    private let actionNodes: [TextAlertContentActionNode]
    private let actionVerticalSeparators: [ASDisplayNode]
    
    private let disposable = MetaDisposable()
    
    private var validLayout: CGSize?
    
    private let hapticFeedback = HapticFeedback()
    
    var complete: (() -> Void)? {
        didSet {
            //self.inputFieldNode.complete = self.complete
        }
    }
    
    override var dismissOnOutsideTap: Bool {
        return self.isUserInteractionEnabled
    }
    
    init(theme: AlertControllerTheme, ptheme: PresentationTheme, strings: PresentationStrings, dateTimeFormat: PresentationDateTimeFormat, actions: [TextAlertAction], title: String, text: String, placeholder: String, minValue: Int64, value: Int64) {
        self.theme = ptheme
        self.strings = strings
        self.dateTimeFormat = dateTimeFormat
        self.title = title
        self.text = text
        self.placeholder = placeholder
        self.minValue = minValue
        self.value = value
        
        self.titleNode = ASTextNode()
        self.titleNode.maximumNumberOfLines = 2
        self.textNode = ASTextNode()
        self.textNode.maximumNumberOfLines = 8
                
//        self.inputFieldNode = GiftAuctionCustomBidInputFieldNode(theme: ptheme, placeholder: placeholder)
//        self.inputFieldNode.text = "\(value)"
        
        self.actionNodesSeparator = ASDisplayNode()
        self.actionNodesSeparator.isLayerBacked = true
        
        self.actionNodes = actions.map { action -> TextAlertContentActionNode in
            return TextAlertContentActionNode(theme: theme, action: action)
        }
        
        var actionVerticalSeparators: [ASDisplayNode] = []
        if actions.count > 1 {
            for _ in 0 ..< actions.count - 1 {
                let separatorNode = ASDisplayNode()
                separatorNode.isLayerBacked = true
                actionVerticalSeparators.append(separatorNode)
            }
        }
        self.actionVerticalSeparators = actionVerticalSeparators
        
        super.init()
        
        self.addSubnode(self.titleNode)
        self.addSubnode(self.textNode)
        
//        self.addSubnode(self.inputFieldNode)

        self.addSubnode(self.actionNodesSeparator)
        
        for actionNode in self.actionNodes {
            self.addSubnode(actionNode)
        }
        
        for separatorNode in self.actionVerticalSeparators {
            self.addSubnode(separatorNode)
        }
        
        self.updateTheme(theme)
    }
    
    deinit {
        self.disposable.dispose()
    }
    
    override func updateTheme(_ theme: AlertControllerTheme) {
        self.titleNode.attributedText = NSAttributedString(string: self.title, font: Font.bold(17.0), textColor: theme.primaryColor, paragraphAlignment: .center)
        self.textNode.attributedText = NSAttributedString(string: self.text, font: Font.regular(13.0), textColor: theme.primaryColor, paragraphAlignment: .center)

        self.actionNodesSeparator.backgroundColor = theme.separatorColor
        for actionNode in self.actionNodes {
            actionNode.updateTheme(theme)
        }
        for separatorNode in self.actionVerticalSeparators {
            separatorNode.backgroundColor = theme.separatorColor
        }
        
        if let size = self.validLayout {
            _ = self.updateLayout(size: size, transition: .immediate)
        }
    }
    
    override func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) -> CGSize {
        var size = size
        size.width = min(size.width, 270.0)
        let measureSize = CGSize(width: size.width - 16.0 * 2.0, height: CGFloat.greatestFiniteMagnitude)
        
        let hadValidLayout = self.validLayout != nil
        
        self.validLayout = size
        
        var origin: CGPoint = CGPoint(x: 0.0, y: 20.0)
        let spacing: CGFloat = 5.0
        
        let titleSize = self.titleNode.measure(measureSize)
        transition.updateFrame(node: self.titleNode, frame: CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - titleSize.width) / 2.0), y: origin.y), size: titleSize))
        origin.y += titleSize.height + 4.0
        
        let textSize = self.textNode.measure(measureSize)
        transition.updateFrame(node: self.textNode, frame: CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - textSize.width) / 2.0), y: origin.y), size: textSize))
        origin.y += textSize.height + 6.0 + spacing
        
        let actionButtonHeight: CGFloat = 44.0
        var minActionsWidth: CGFloat = 0.0
        let maxActionWidth: CGFloat = floor(size.width / CGFloat(self.actionNodes.count))
        let actionTitleInsets: CGFloat = 8.0
        
        var effectiveActionLayout = TextAlertContentActionLayout.horizontal
        for actionNode in self.actionNodes {
            let actionTitleSize = actionNode.titleNode.updateLayout(CGSize(width: maxActionWidth, height: actionButtonHeight))
            if case .horizontal = effectiveActionLayout, actionTitleSize.height > actionButtonHeight * 0.6667 {
                effectiveActionLayout = .vertical
            }
            switch effectiveActionLayout {
                case .horizontal:
                    minActionsWidth += actionTitleSize.width + actionTitleInsets
                case .vertical:
                    minActionsWidth = max(minActionsWidth, actionTitleSize.width + actionTitleInsets)
            }
        }
        
        let insets = UIEdgeInsets(top: 18.0, left: 18.0, bottom: 9.0, right: 18.0)
        
        var contentWidth = max(titleSize.width, minActionsWidth)
        contentWidth = max(contentWidth, 234.0)
        
        var actionsHeight: CGFloat = 0.0
        switch effectiveActionLayout {
            case .horizontal:
                actionsHeight = actionButtonHeight
            case .vertical:
                actionsHeight = actionButtonHeight * CGFloat(self.actionNodes.count)
        }
        
        let resultWidth = contentWidth + insets.left + insets.right
        
        let fieldWidth = resultWidth - 18.0
        let amountFieldSize = self.amountField.update(
            transition: .immediate,
            component: AnyComponent(
                AmountFieldComponent(
                    textColor: self.theme.list.itemPrimaryTextColor,
                    secondaryColor: self.theme.list.itemSecondaryTextColor,
                    placeholderColor: self.theme.list.itemPlaceholderTextColor,
                    accentColor: self.theme.list.itemAccentColor,
                    value: self.value,
                    minValue: self.minValue,
                    forceMinValue: false,
                    allowZero: false,
                    maxValue: nil,
                    placeholderText: self.placeholder,
                    textFieldOffset: CGPoint(x: -4.0, y: -1.0),
                    labelText: nil,
                    currency: .stars,
                    dateTimeFormat: self.dateTimeFormat,
                    amountUpdated: { [weak self] value in
                        guard let self else {
                            return
                        }
                        if let value {
                            self.value = value
                        }
                    },
                    tag: nil
                )
            ),
            environment: {},
            containerSize: CGSize(width: fieldWidth, height: 44.0)
        )
        var amountFieldFrame = CGRect(origin: CGPoint(x: floor((resultWidth - fieldWidth) / 2.0), y: origin.y - 2.0), size: amountFieldSize)
        if let amountFieldView = self.amountField.view {
            if amountFieldView.superview == nil {
                amountFieldView.clipsToBounds = true
                self.backgroundView.image = generateStretchableFilledCircleImage(diameter: 12.0, color: self.theme.actionSheet.inputHollowBackgroundColor, strokeColor: self.theme.actionSheet.inputBorderColor, strokeWidth: 1.0)
                
                self.view.addSubview(self.backgroundView)
                self.view.addSubview(amountFieldView)
            }
            self.backgroundView.frame = amountFieldFrame.insetBy(dx: 7.0, dy: 9.0)
            amountFieldFrame.size.width -= 14.0
            amountFieldView.frame = amountFieldFrame
        }
        
        let resultSize = CGSize(width: resultWidth, height: titleSize.height + textSize.height + spacing + amountFieldSize.height + actionsHeight + insets.top + insets.bottom + 3.0)
        
        transition.updateFrame(node: self.actionNodesSeparator, frame: CGRect(origin: CGPoint(x: 0.0, y: resultSize.height - actionsHeight - UIScreenPixel), size: CGSize(width: resultSize.width, height: UIScreenPixel)))
        
        var actionOffset: CGFloat = 0.0
        let actionWidth: CGFloat = floor(resultSize.width / CGFloat(self.actionNodes.count))
        var separatorIndex = -1
        var nodeIndex = 0
        for actionNode in self.actionNodes {
            if separatorIndex >= 0 {
                let separatorNode = self.actionVerticalSeparators[separatorIndex]
                switch effectiveActionLayout {
                    case .horizontal:
                        transition.updateFrame(node: separatorNode, frame: CGRect(origin: CGPoint(x: actionOffset - UIScreenPixel, y: resultSize.height - actionsHeight), size: CGSize(width: UIScreenPixel, height: actionsHeight - UIScreenPixel)))
                    case .vertical:
                        transition.updateFrame(node: separatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: resultSize.height - actionsHeight + actionOffset - UIScreenPixel), size: CGSize(width: resultSize.width, height: UIScreenPixel)))
                }
            }
            separatorIndex += 1
            
            let currentActionWidth: CGFloat
            switch effectiveActionLayout {
                case .horizontal:
                    if nodeIndex == self.actionNodes.count - 1 {
                        currentActionWidth = resultSize.width - actionOffset
                    } else {
                        currentActionWidth = actionWidth
                    }
                case .vertical:
                    currentActionWidth = resultSize.width
            }
            
            let actionNodeFrame: CGRect
            switch effectiveActionLayout {
                case .horizontal:
                    actionNodeFrame = CGRect(origin: CGPoint(x: actionOffset, y: resultSize.height - actionsHeight), size: CGSize(width: currentActionWidth, height: actionButtonHeight))
                    actionOffset += currentActionWidth
                case .vertical:
                    actionNodeFrame = CGRect(origin: CGPoint(x: 0.0, y: resultSize.height - actionsHeight + actionOffset), size: CGSize(width: currentActionWidth, height: actionButtonHeight))
                    actionOffset += actionButtonHeight
            }
            
            transition.updateFrame(node: actionNode, frame: actionNodeFrame)
            
            nodeIndex += 1
        }
        
        if !hadValidLayout {
            if let amountFieldView = self.amountField.view as? AmountFieldComponent.View {
                amountFieldView.activateInput()
                Queue.mainQueue().justDispatch {
                    amountFieldView.selectAll()
                }
            }
        }
        
        return resultSize
    }
    
    func animateError() {
        if let amountFieldView = self.amountField.view as? AmountFieldComponent.View {
            self.value = self.minValue
            if let size = self.validLayout {
                _ = self.updateLayout(size: size, transition: .immediate)
            }
            amountFieldView.resetValue()
            
            amountFieldView.animateError()
            amountFieldView.selectAll()
        }
    }
    
    func deactivateInput() {
        if let amountFieldView = self.amountField.view as? AmountFieldComponent.View {
            amountFieldView.deactivateInput()
        }
    }
}

func giftAuctionCustomBidController(context: AccountContext, title: String, text: String, placeholder: String, action: String, minValue: Int64, value: Int64, apply: @escaping (Int64) -> Void, cancel: @escaping () -> Void) -> AlertController {
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    
    var dismissImpl: ((Bool) -> Void)?
    var applyImpl: (() -> Void)?
    
    let actions: [TextAlertAction] = [TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {
        dismissImpl?(true)
        cancel()
    }), TextAlertAction(type: .defaultAction, title: action, action: {
        applyImpl?()
    })]
    
    let contentNode = GiftAuctionCustomBidAlertContentNode(theme: AlertControllerTheme(presentationData: presentationData), ptheme: presentationData.theme, strings: presentationData.strings, dateTimeFormat: presentationData.dateTimeFormat, actions: actions, title: title, text: text, placeholder: placeholder, minValue: minValue, value: value)
    contentNode.complete = {
        applyImpl?()
    }
    applyImpl = { [weak contentNode] in
        guard let contentNode = contentNode else {
            return
        }
        let value = contentNode.value
        if value < minValue {
            contentNode.animateError()
        } else {
            dismissImpl?(true)
            apply(contentNode.value)
        }
    }
    
    let controller = AlertController(theme: AlertControllerTheme(presentationData: presentationData), contentNode: contentNode)
    let presentationDataDisposable = context.sharedContext.presentationData.start(next: { [weak controller] presentationData in
        controller?.theme = AlertControllerTheme(presentationData: presentationData)
    })
    controller.dismissed = { byTapOutside in
        presentationDataDisposable.dispose()
        if byTapOutside {
            cancel()
        }
    }
    dismissImpl = { [weak controller, weak contentNode] animated in
        contentNode?.deactivateInput()
        let _ = contentNode
        if animated {
            controller?.dismissAnimated()
        } else {
            controller?.dismiss()
        }
    }
    return controller
}
