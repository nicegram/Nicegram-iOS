import FeatAttentionEconomy

import AsyncDisplayKit
import ChatMessageItemCommon
import ChatMessageItemView
import Display
import ShareController

@available(iOS 15.0, *)
class ChatMessageNicegramAdNode: ListViewItemNode {
    private let layoutConstants = (ChatMessageItemLayoutConstants.compact, ChatMessageItemLayoutConstants.regular)
    
    var item: ChatMessageNicegramAdItem?
    
    private let bannerView: AttChatBanner
    private let bannerNode: ASDisplayNode
    
    override var visibility: ListViewItemNodeVisibility {
        didSet {
            let visiblePart: Double
            switch visibility {
            case .none:
                visiblePart = 0.0
            case let .visible(part, _):
                visiblePart = part
            }
            
            bannerView.set(visiblePart: visiblePart)
        }
    }
    
    required init(rotated: Bool) {
        let bannerView = AttChatBanner()
        self.bannerView = bannerView
        self.bannerNode = ASDisplayNode {
            bannerView
        }
        
        super.init(layerBacked: false, dynamicBounce: true, rotated: rotated)
        
        if rotated {
            self.transform = CATransform3DMakeRotation(CGFloat.pi, 0.0, 0.0, 1.0)
        }
        
        self.addSubnode(bannerNode)
        
        bannerView.share = { [weak self] image, text in
            guard let item = self?.item else { return }
            Task { @MainActor in
                let shareController = await shareController(
                    image: image,
                    text: text,
                    context: item.context
                )
                item.controllerInteraction.presentController(shareController, nil)
            }
        }
    }
    
    func setupItem(_ item: ChatMessageNicegramAdItem) {
        self.item = item
    }
    
    override func layoutForParams(_ params: ListViewItemLayoutParams, item: ListViewItem, previousItem: ListViewItem?, nextItem: ListViewItem?) {
        
    }
    
    func asyncLayout() -> (_ item: ChatMessageNicegramAdItem, _ params: ListViewItemLayoutParams, _ mergedTop: Bool, _ mergedBottom: Bool, _ dateAtBottom: Bool) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
        return { [weak self] item, params, mergedTop, mergedBottom, dateHeaderAtBottom -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) in
            guard let self else {
                return (
                    ListViewItemNodeLayout(
                        contentSize: .zero,
                        insets: .zero
                    ),
                    { _ in }
                )
            }
            
            let presentationData = item.presentationData
            let messagePresentationData = item.presentationData.theme.theme.chat.message
            let incomingBubble = if presentationData.theme.wallpaper.hasWallpaper {
                messagePresentationData.incoming.bubble.withWallpaper
            } else {
                messagePresentationData.incoming.bubble.withoutWallpaper
            }
            let bannerPresentationData = AttChatBannerPresentationData(
                incomingBubble: .init(
                    backgroundColor: incomingBubble.fill.first ?? .black,
                    primaryTextColor: messagePresentationData.incoming.primaryTextColor
                ),
                messageFont: presentationData.messageFont,
                messageBoldFont: presentationData.messageBoldFont
            )
            
            let layoutConstants = chatMessageItemLayoutConstants(layoutConstants, params: params, presentationData: presentationData)
            let maximumWidthFill = layoutConstants.bubble.maximumWidthFill.widthFor(params.width)
            let layoutParams = AttChatBannerLayoutParams(
                insets: layoutConstants.bubble.contentInsets
                    .sum(.vertical(layoutConstants.bubble.defaultSpacing))
                    .sum(.horizontal(layoutConstants.bubble.edgeInset))
                    .sum(.left(params.leftInset).right(params.rightInset)),
                maximumWidthFill: maximumWidthFill
            )
            
            bannerView.set(
                ad: item.ad,
                layoutParams: layoutParams,
                presentationData: bannerPresentationData
            )
            bannerView.layoutIfNeeded()
            let bannerSize = bannerView.systemLayoutSizeFitting(
                UIView.layoutFittingExpandedSize
            )
            let size = CGSize(
                width: params.width,
                height: bannerSize.height
            )
            
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: .zero
            )
            
            let apply: (ListViewItemUpdateAnimation) -> Void = { [weak self] _ in
                guard let self else { return }
                bannerNode.frame = CGRect(origin: .zero, size: size)
            }
            
            return (layout, apply)
        }
    }
    
    override public func animateInsertion(_ currentTimestamp: Double, duration: Double, options: ListViewItemAnimationOptions) {
        super.animateInsertion(currentTimestamp, duration: duration, options: options)
        
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override public func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        super.animateRemoved(currentTimestamp, duration: duration)
        
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
    }
    
    override public func animateAdded(_ currentTimestamp: Double, duration: Double) {
        super.animateAdded(currentTimestamp, duration: duration)
        
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
}

private extension UIEdgeInsets {
    func sum(_ other: UIEdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(
            top: self.top + other.top,
            left: self.left + other.left,
            bottom: self.bottom + other.bottom,
            right: self.right + other.right
        )
    }
}
