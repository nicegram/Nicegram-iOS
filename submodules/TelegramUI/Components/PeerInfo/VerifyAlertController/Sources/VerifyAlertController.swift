import Foundation
import UIKit
import SwiftSignalKit
import AsyncDisplayKit
import Display
import Postbox
import TelegramCore
import TelegramPresentationData
import AccountContext
import ComponentFlow
import MultilineTextComponent
import BalancedTextComponent
import TextFieldComponent
import ComponentDisplayAdapters
import TextFormat
import PremiumPeerShortcutComponent

private final class VerifyAlertContentNode: AlertContentNode {
    private let context: AccountContext
    private var theme: AlertControllerTheme
    private var presentationTheme: PresentationTheme
    private let strings: PresentationStrings
    private let title: String
    private let text: String
    private let peer: EnginePeer
    private let verifierSettings: BotVerifierSettings
    private let verifierIcon: TelegramMediaFile?
    private let hasInput: Bool
    
    private let titleView = ComponentView<Empty>()
    private let textView = ComponentView<Empty>()
    private let shortcut = ComponentView<Empty>()
    
    private let state = ComponentState()
    
    private let inputBackgroundNode = ASImageNode()
    private let inputField = ComponentView<Empty>()
    private let inputFieldExternalState = TextFieldComponent.ExternalState()
    private let inputPlaceholderView = ComponentView<Empty>()
    
    private let actionNodesSeparator: ASDisplayNode
    private let actionNodes: [TextAlertContentActionNode]
    private let actionVerticalSeparators: [ASDisplayNode]
    
    private let disposable = MetaDisposable()
    
    private var validLayout: CGSize?
    
    private let hapticFeedback = HapticFeedback()
    
    var present: (ViewController) -> () = { _ in }
    
    var complete: (() -> Void)? {
        didSet {
//            self.inputFieldNode.complete = self.complete
        }
    }
    
    override var dismissOnOutsideTap: Bool {
        return self.isUserInteractionEnabled
    }
    
    init(context: AccountContext, theme: AlertControllerTheme, presentationTheme: PresentationTheme, strings: PresentationStrings, actions: [TextAlertAction], title: String, text: String, peer: EnginePeer, verifierSettings: BotVerifierSettings, verifierIcon: TelegramMediaFile?, hasInput: Bool) {
        self.context = context
        self.theme = theme
        self.presentationTheme = presentationTheme
        self.strings = strings
        self.title = title
        self.text = text
        self.peer = peer
        self.verifierSettings = verifierSettings
        self.verifierIcon = verifierIcon
        self.hasInput = hasInput
        
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
        
        self.inputBackgroundNode.displaysAsynchronously = false
        self.inputBackgroundNode.image = generateStretchableFilledCircleImage(diameter: 16.0, color: presentationTheme.actionSheet.inputHollowBackgroundColor, strokeColor: presentationTheme.actionSheet.inputBorderColor, strokeWidth: UIScreenPixel)
        
        self.addSubnode(self.actionNodesSeparator)
        
        if self.hasInput {
            self.addSubnode(self.inputBackgroundNode)
        }
        
        for actionNode in self.actionNodes {
            self.addSubnode(actionNode)
        }
        
        for separatorNode in self.actionVerticalSeparators {
            self.addSubnode(separatorNode)
        }
                
        self.updateTheme(theme)
        
        self.state._updated = { [weak self] transition, _ in
            guard let self, let _ = self.validLayout else {
                return
            }
            self.requestLayout?(transition.containedViewLayoutTransition)
        }
    }
    
    deinit {
        self.disposable.dispose()
    }
    
    var textAndEntities: (String, [MessageTextEntity]) {
        let text = self.inputFieldExternalState.text.string
        let entities = generateChatInputTextEntities(self.inputFieldExternalState.text)
        return (text, entities)
    }

    override func updateTheme(_ theme: AlertControllerTheme) {
        self.theme = theme
        
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
        
        var origin: CGPoint = CGPoint(x: 0.0, y: 16.0)
        let spacing: CGFloat = 5.0
        
        
        let titleSize = self.titleView.update(
            transition: .immediate,
            component: AnyComponent(MultilineTextComponent(
                text: .plain(NSAttributedString(string: self.title, font: Font.semibold(17.0), textColor: self.theme.primaryColor)),
                horizontalAlignment: .center,
                maximumNumberOfLines: 0
            )),
            environment: {},
            containerSize: CGSize(width: measureSize.width, height: 1000.0)
        )
        let titleFrame = CGRect(origin: CGPoint(x: floor((size.width - titleSize.width) * 0.5), y: origin.y), size: titleSize)
        if let titleComponentView = self.titleView.view {
            if titleComponentView.superview == nil {
                self.view.addSubview(titleComponentView)
            }
            titleComponentView.frame = titleFrame
        }
        origin.y += titleSize.height + 5.0
        
        let textSize = self.textView.update(
            transition: .immediate,
            component: AnyComponent(MultilineTextComponent(
                text: .plain(NSAttributedString(string: self.text, font: Font.regular(13.0), textColor: self.theme.primaryColor)),
                horizontalAlignment: .center,
                maximumNumberOfLines: 0
            )),
            environment: {},
            containerSize: CGSize(width: measureSize.width, height: 1000.0)
        )
        let textFrame = CGRect(origin: CGPoint(x: floor((size.width - textSize.width) * 0.5), y: origin.y), size: textSize)
        if let textComponentView = self.textView.view {
            if textComponentView.superview == nil {
                self.view.addSubview(textComponentView)
            }
            textComponentView.frame = textFrame
        }
        origin.y += textSize.height + 17.0
        
        let shortcutSize = self.shortcut.update(
            transition: .immediate,
            component: AnyComponent(PremiumPeerShortcutComponent(
                context: self.context,
                theme: self.presentationTheme,
                peer: self.peer,
                icon: self.verifierIcon,
                iconPosition: .left
            )),
            environment: {},
            containerSize: CGSize(width: measureSize.width, height: 1000.0)
        )
        let shortcutFrame = CGRect(origin: CGPoint(x: floor((size.width - shortcutSize.width) * 0.5), y: origin.y), size: shortcutSize)
        if let shortcutComponentView = self.shortcut.view {
            if shortcutComponentView.superview == nil {
                self.view.addSubview(shortcutComponentView)
            }
            shortcutComponentView.frame = shortcutFrame
        }
        origin.y += shortcutSize.height + 17.0
        
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
        var resultInputHeight: CGFloat = 0.0
        
        if self.hasInput {
            let inputInset: CGFloat = 16.0
            let inputWidth = resultWidth - inputInset * 2.0
            
            var characterLimit: Int = 70
            if let data = self.context.currentAppConfiguration.with({ $0 }).data, let value = data["bot_verification_description_length_limit"] as? Double {
                characterLimit = Int(value)
            }
            
            let inputFieldSize = self.inputField.update(
                transition: .immediate,
                component: AnyComponent(TextFieldComponent(
                    context: self.context,
                    theme: self.presentationTheme,
                    strings: self.strings,
                    externalState: self.inputFieldExternalState,
                    fontSize: 14.0,
                    textColor: self.presentationTheme.actionSheet.inputTextColor,
                    accentColor: self.presentationTheme.actionSheet.controlAccentColor,
                    insets: UIEdgeInsets(top: 8.0, left: 2.0, bottom: 8.0, right: 2.0),
                    hideKeyboard: false,
                    customInputView: nil,
                    resetText: nil,
                    isOneLineWhenUnfocused: false,
                    characterLimit: characterLimit,
                    emptyLineHandling: .oneConsecutive,
                    formatMenuAvailability: .none,
                    returnKeyType: .default,
                    lockedFormatAction: {
                    },
                    present: { [weak self] c in
                        self?.present(c)
                    },
                    paste: { _ in
                    },
                    returnKeyAction: nil,
                    backspaceKeyAction: nil
                )),
                environment: {},
                containerSize: CGSize(width: inputWidth, height: 270.0)
            )
            self.inputField.parentState = self.state
            let inputFieldFrame = CGRect(origin: CGPoint(x: inputInset, y: origin.y), size: inputFieldSize)
            if let inputFieldView = self.inputField.view as? TextFieldComponent.View {
                if inputFieldView.superview == nil {
                    self.view.addSubview(inputFieldView)
                }
                transition.updateFrame(view: inputFieldView, frame: inputFieldFrame)
                transition.updateFrame(node: self.inputBackgroundNode, frame: inputFieldFrame)
                
                if !hadValidLayout {
                    inputFieldView.activateInput()
                }
            }
            
            let placeholderText = self.verifierSettings.customDescription ?? self.strings.BotVerification_Verify_Placeholder(self.verifierSettings.companyName).string
            
            let inputPlaceholderSize = self.inputPlaceholderView.update(
                transition: .immediate,
                component: AnyComponent(
                    MultilineTextComponent(text: .plain(NSAttributedString(
                        string: placeholderText,
                        font: Font.regular(14.0),
                        textColor: self.presentationTheme.actionSheet.inputPlaceholderColor
                    )))
                ),
                environment: {},
                containerSize: CGSize(width: inputWidth - 32.0, height: 240.0)
            )
            let inputPlaceholderFrame = CGRect(origin: CGPoint(x: inputInset + 10.0, y: floorToScreenPixels(inputFieldFrame.midY - inputPlaceholderSize.height / 2.0)), size: inputPlaceholderSize)
            if let inputPlaceholderView = self.inputPlaceholderView.view {
                if inputPlaceholderView.superview == nil {
                    inputPlaceholderView.isUserInteractionEnabled = false
                    self.view.addSubview(inputPlaceholderView)
                }
                inputPlaceholderView.frame = inputPlaceholderFrame
                inputPlaceholderView.isHidden = self.inputFieldExternalState.hasText
            }
            resultInputHeight = inputFieldSize.height + 17.0
        }
                        
        let resultSize = CGSize(width: resultWidth, height: titleSize.height + textSize.height + shortcutSize.height + spacing + resultInputHeight + 22.0 + actionsHeight + insets.top + insets.bottom)
        
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
        
        return resultSize
    }
    
    func deactivateInput() {
        if let inputFieldView = self.inputField.view as? TextFieldComponent.View {
            inputFieldView.deactivateInput()
        }
    }
    
    func animateError() {
        if let inputFieldView = self.inputField.view as? TextFieldComponent.View {
            inputFieldView.layer.addShakeAnimation()
        }

        self.hapticFeedback.error()
    }
}

public func verifyAlertController(context: AccountContext, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)? = nil, peer: EnginePeer, verifierSettings: BotVerifierSettings, verifierIcon: TelegramMediaFile?, apply: @escaping (String) -> Void) -> AlertController {
    let presentationData = updatedPresentationData?.initial ?? context.sharedContext.currentPresentationData.with { $0 }
    
    var dismissImpl: ((Bool) -> Void)?
    var applyImpl: (() -> Void)?
    
    let actions: [TextAlertAction] = [TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {
        dismissImpl?(true)
    }), TextAlertAction(type: .defaultAction, title: presentationData.strings.BotVerification_Verify_Verify, action: {
        dismissImpl?(true)
        applyImpl?()
    })]
    
    let title: String
    let text: String
    if case let .user(user) = peer {
        if let _ = user.botInfo {
            title = presentationData.strings.BotVerification_Verify_Bot_Title
            text = presentationData.strings.BotVerification_Verify_Bot_Text
        } else {
            title = presentationData.strings.BotVerification_Verify_User_Title
            text = presentationData.strings.BotVerification_Verify_User_Text
        }
    } else if case let .channel(channel) = peer, case .broadcast = channel.info {
        title = presentationData.strings.BotVerification_Verify_Channel_Title
        text = presentationData.strings.BotVerification_Verify_Channel_Text
    } else {
        title = presentationData.strings.BotVerification_Verify_Group_Title
        text = presentationData.strings.BotVerification_Verify_Group_Text
    }
    
    let contentNode = VerifyAlertContentNode(context: context, theme: AlertControllerTheme(presentationData: presentationData), presentationTheme: presentationData.theme, strings: presentationData.strings, actions: actions, title: title, text: text, peer: peer, verifierSettings: verifierSettings, verifierIcon: verifierIcon, hasInput: verifierSettings.canModifyDescription)
    contentNode.complete = {
        applyImpl?()
    }
    applyImpl = { [weak contentNode] in
        guard let contentNode = contentNode else {
            return
        }
        let (text, _) = contentNode.textAndEntities
        apply(text)
    }
    
    let controller = AlertController(theme: AlertControllerTheme(presentationData: presentationData), contentNode: contentNode)
    let presentationDataDisposable = (updatedPresentationData?.signal ?? context.sharedContext.presentationData).start(next: { [weak controller] presentationData in
        controller?.theme = AlertControllerTheme(presentationData: presentationData)
    })
    controller.dismissed = { _ in
        presentationDataDisposable.dispose()
    }
    dismissImpl = { [weak controller] animated in
        contentNode.deactivateInput()
        if animated {
            controller?.dismissAnimated()
        } else {
            controller?.dismiss()
        }
    }
    
    contentNode.present = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    
    return controller
}

public func removeVerificationAlertController(context: AccountContext, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)? = nil, peer: EnginePeer, verifierSettings: BotVerifierSettings, verifierIcon: TelegramMediaFile?, completion: @escaping () -> Void) -> AlertController {
    let presentationData = updatedPresentationData?.initial ?? context.sharedContext.currentPresentationData.with { $0 }
    
    var dismissImpl: ((Bool) -> Void)?
    var applyImpl: (() -> Void)?
    
    let actions: [TextAlertAction] = [TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {
        dismissImpl?(true)
    }), TextAlertAction(type: .defaultDestructiveAction, title: presentationData.strings.BotVerification_Remove_Remove, action: {
        dismissImpl?(true)
        applyImpl?()
    })]
    
    let title = presentationData.strings.BotVerification_Remove_Title
    let text: String
    if case let .user(user) = peer {
        if let _ = user.botInfo {
            text = presentationData.strings.BotVerification_Remove_Bot_Text
        } else {
            text = presentationData.strings.BotVerification_Remove_User_Text
        }
    } else if case let .channel(channel) = peer, case .broadcast = channel.info {
        text = presentationData.strings.BotVerification_Remove_Channel_Text
    } else {
        text = presentationData.strings.BotVerification_Remove_Group_Text
    }
    
    let contentNode = VerifyAlertContentNode(context: context, theme: AlertControllerTheme(presentationData: presentationData), presentationTheme: presentationData.theme, strings: presentationData.strings, actions: actions, title: title, text: text, peer: peer, verifierSettings: verifierSettings, verifierIcon: verifierIcon, hasInput: false)
    applyImpl = {
        completion()
    }
    
    let controller = AlertController(theme: AlertControllerTheme(presentationData: presentationData), contentNode: contentNode)
    let presentationDataDisposable = (updatedPresentationData?.signal ?? context.sharedContext.presentationData).start(next: { [weak controller] presentationData in
        controller?.theme = AlertControllerTheme(presentationData: presentationData)
    })
    controller.dismissed = { _ in
        presentationDataDisposable.dispose()
    }
    dismissImpl = { [weak controller] animated in
        if animated {
            controller?.dismissAnimated()
        } else {
            controller?.dismiss()
        }
    }
    contentNode.present = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    return controller
}
