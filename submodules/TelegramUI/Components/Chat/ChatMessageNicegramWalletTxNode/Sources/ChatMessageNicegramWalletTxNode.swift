import NicegramWallet

import AsyncDisplayKit
import ChatMessageItemCommon
import ChatMessageItemView
import Display

@available(iOS 16.0, *)
class ChatMessageNicegramWalletTxNode: ListViewItemNode {
    private let itemView: ChatMessageTxView
    private let itemNode: ASDisplayNode
    
    required init(rotated: Bool) {
        let itemView = ChatMessageTxView()
        let itemNode = ASDisplayNode { itemView }
        
        self.itemView = itemView
        self.itemNode = itemNode
        
        super.init(layerBacked: false, dynamicBounce: true, rotated: rotated)
        
        if rotated {
            self.transform = CATransform3DMakeRotation(CGFloat.pi, 0.0, 0.0, 1.0)
        }
        
        self.addSubnode(itemNode)
    }
    
    func setupItem(_ item: ChatMessageNicegramWalletTxItem) {
        
    }
    
    override func layoutForParams(_ params: ListViewItemLayoutParams, item: ListViewItem, previousItem: ListViewItem?, nextItem: ListViewItem?) {
        
    }
    
    func asyncLayout() -> (_ item: ChatMessageNicegramWalletTxItem, _ params: ListViewItemLayoutParams, _ mergedTop: Bool, _ mergedBottom: Bool, _ dateAtBottom: Bool) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
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
            
            let bubbleParams = ChatMessageBubbleNicegramParams(
                params: params,
                presentationData: item.presentationData
            )
            let insets = bubbleParams.insets
            
            itemView.set(
                incoming: item.incoming,
                insets: insets,
                tx: item.tx
            )
            
            itemView.layoutIfNeeded()
            let itemSize = itemView.systemLayoutSizeFitting(
                UIView.layoutFittingExpandedSize
            )
            let size = CGSize(
                width: params.width,
                height: itemSize.height
            )
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: .zero
            )
            
            let apply: (ListViewItemUpdateAnimation) -> Void = { [weak self] _ in
                guard let self else { return }
                itemNode.frame = CGRect(origin: .zero, size: size)
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
