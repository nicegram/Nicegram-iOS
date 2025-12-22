import Foundation
import UIKit
import SwiftSignalKit
import AsyncDisplayKit
import Display
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import AccountContext
import AppBundle
import AvatarNode
import Markdown

private final class GiftAuctionTransferAlertContentNode: AlertContentNode {
    private let strings: PresentationStrings
    private let title: String
    private let text: String
    
    private let titleNode: ASTextNode
    private let textNode: ASTextNode
    private let avatarNode: AvatarNode
    private let arrowNode: ASImageNode
    private let secondAvatarNode: AvatarNode
    
    private let actionNodesSeparator: ASDisplayNode
    private let actionNodes: [TextAlertContentActionNode]
    private let actionVerticalSeparators: [ASDisplayNode]
        
    private var validLayout: CGSize?
    
    override var dismissOnOutsideTap: Bool {
        return self.isUserInteractionEnabled
    }
    
    init(context: AccountContext, theme: AlertControllerTheme, ptheme: PresentationTheme, strings: PresentationStrings, fromPeer: EnginePeer, toPeer: EnginePeer, title: String, text: String, actions: [TextAlertAction]) {
        self.strings = strings
        self.title = title
        self.text = text
        
        self.titleNode = ASTextNode()
        self.titleNode.maximumNumberOfLines = 0
        
        self.textNode = ASTextNode()
        self.textNode.maximumNumberOfLines = 0
        
        self.avatarNode = AvatarNode(font: avatarPlaceholderFont(size: 26.0))
        
        self.arrowNode = ASImageNode()
        self.arrowNode.displaysAsynchronously = false
        self.arrowNode.displayWithoutProcessing = true
        
        self.secondAvatarNode = AvatarNode(font: avatarPlaceholderFont(size: 26.0))
                
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
        self.addSubnode(self.avatarNode)
        self.addSubnode(self.arrowNode)
        self.addSubnode(self.secondAvatarNode)
    
        self.addSubnode(self.actionNodesSeparator)
        
        for actionNode in self.actionNodes {
            self.addSubnode(actionNode)
        }
        
        for separatorNode in self.actionVerticalSeparators {
            self.addSubnode(separatorNode)
        }
        
        self.updateTheme(theme)
        
        self.avatarNode.setPeer(context: context, theme: ptheme, peer: fromPeer)
        self.secondAvatarNode.setPeer(context: context, theme: ptheme, peer: toPeer)
    }
    
    override func updateTheme(_ theme: AlertControllerTheme) {
        self.titleNode.attributedText = NSAttributedString(string: self.title, font: Font.bold(17.0), textColor: theme.primaryColor, paragraphAlignment: .center)
        self.textNode.attributedText = parseMarkdownIntoAttributedString(self.text, attributes: MarkdownAttributes(
            body: MarkdownAttributeSet(font: Font.regular(13.0), textColor: theme.primaryColor),
            bold: MarkdownAttributeSet(font: Font.semibold(13.0), textColor: theme.primaryColor),
            link: MarkdownAttributeSet(font: Font.regular(13.0), textColor: theme.primaryColor),
            linkAttribute: { url in
                return ("URL", url)
            }
        ), textAlignment: .center)
        self.arrowNode.image = generateTintedImage(image: UIImage(bundleImageName: "Peer Info/AlertArrow"), color: theme.secondaryColor)
        
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
        
        self.validLayout = size
        
        var origin: CGPoint = CGPoint(x: 0.0, y: 20.0)
        
        let avatarSize = CGSize(width: 60.0, height: 60.0)
        self.avatarNode.updateSize(size: avatarSize)
        
        let avatarFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - avatarSize.width) / 2.0) - 44.0, y: origin.y), size: avatarSize)
        transition.updateFrame(node: self.avatarNode, frame: avatarFrame)
        
        if let arrowImage = self.arrowNode.image {
            let arrowFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - arrowImage.size.width) / 2.0), y: origin.y + floorToScreenPixels((avatarSize.height - arrowImage.size.height) / 2.0)), size: arrowImage.size)
            transition.updateFrame(node: self.arrowNode, frame: arrowFrame)
        }
        
        let secondAvatarFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - avatarSize.width) / 2.0) + 44.0, y: origin.y), size: avatarSize)
        transition.updateFrame(node: self.secondAvatarNode, frame: secondAvatarFrame)
        
        origin.y += avatarSize.height + 10.0

        let titleSize = self.titleNode.measure(CGSize(width: size.width - 32.0, height: size.height))
        transition.updateFrame(node: self.titleNode, frame: CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - titleSize.width) / 2.0), y: origin.y), size: titleSize))
        origin.y += titleSize.height + 4.0

        let textSize = self.textNode.measure(CGSize(width: size.width - 32.0, height: size.height))
        transition.updateFrame(node: self.textNode, frame: CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - textSize.width) / 2.0), y: origin.y), size: textSize))
        origin.y += textSize.height + 10.0
        
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
        
        let insets = UIEdgeInsets(top: 18.0, left: 18.0, bottom: 18.0, right: 18.0)
        
        let contentWidth = max(size.width, minActionsWidth)
                
        var actionsHeight: CGFloat = 0.0
        switch effectiveActionLayout {
            case .horizontal:
                actionsHeight = actionButtonHeight
            case .vertical:
                actionsHeight = actionButtonHeight * CGFloat(self.actionNodes.count)
        }
        
        let resultSize = CGSize(width: contentWidth, height: avatarSize.height + titleSize.height + textSize.height + actionsHeight + 16.0 + insets.top + insets.bottom)
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
}

func giftAuctionTransferController(context: AccountContext, fromPeer: EnginePeer, toPeer: EnginePeer, commit: @escaping () -> Void) -> AlertController {
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let strings = presentationData.strings
    
    let text: String
    if fromPeer.id == context.account.peerId {
        text = strings.Gift_AuctionTransfer_TextFromYourself(toPeer.displayTitle(strings: strings, displayOrder: presentationData.nameDisplayOrder)).string
    } else if toPeer.id == context.account.peerId {
        text = strings.Gift_AuctionTransfer_TextToYourself(fromPeer.displayTitle(strings: strings, displayOrder: presentationData.nameDisplayOrder)).string
    } else {
        text = strings.Gift_AuctionTransfer_Text(fromPeer.displayTitle(strings: strings, displayOrder: presentationData.nameDisplayOrder), toPeer.displayTitle(strings: strings, displayOrder: presentationData.nameDisplayOrder)).string
    }
        
    var dismissImpl: ((Bool) -> Void)?
    var contentNode: GiftAuctionTransferAlertContentNode?
    let actions: [TextAlertAction] = [TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {
        dismissImpl?(true)
    }), TextAlertAction(type: .defaultAction, title: strings.Gift_AuctionTransfer_Change, action: {
        dismissImpl?(true)
        commit()
    })]
    
    contentNode = GiftAuctionTransferAlertContentNode(context: context, theme: AlertControllerTheme(presentationData: presentationData), ptheme: presentationData.theme, strings: strings, fromPeer: fromPeer, toPeer: toPeer, title: strings.Gift_AuctionTransfer_Title, text: text, actions: actions)
    
    let controller = AlertController(theme: AlertControllerTheme(presentationData: presentationData), contentNode: contentNode!)
    dismissImpl = { [weak controller] animated in
        if animated {
            controller?.dismissAnimated()
        } else {
            controller?.dismiss()
        }
    }
    return controller
}
