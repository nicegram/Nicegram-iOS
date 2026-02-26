import AsyncDisplayKit
import ChatMessageItemView
import Display
import FeatAdsgram
import SwiftUI
import UIKit

@available(iOS 16.0, *)
class ChatMessageNicegramAdNode: ListViewItemNode {
    private var item: ChatMessageNicegramAdItem?
    
    private let bannerView: ChatMessageAdView
    private let bannerNode: ASDisplayNode

    override var visibility: ListViewItemNodeVisibility {
        didSet {
            let visibleFraction: Double
            switch visibility {
            case .none:
                visibleFraction = 0.0
            case let .visible(part, _):
                visibleFraction = part
            }
            
            item?.viewModel.updateVisibility {
                $0.visibleFraction = visibleFraction
            }
        }
    }
    
    required init(rotated: Bool) {
        let bannerView = ChatMessageAdView()
        self.bannerView = bannerView
        self.bannerNode = ASDisplayNode { bannerView }
        
        super.init(layerBacked: false, rotated: rotated)
        
        if rotated {
            self.transform = CATransform3DMakeRotation(CGFloat.pi, 0.0, 0.0, 1.0)
        }
        
        self.addSubnode(bannerNode)
    }
    
    func setupItem(_ item: ChatMessageNicegramAdItem) {
        self.item = item
    }
    
    func asyncLayout() -> (_ item: ChatMessageNicegramAdItem, _ params: ListViewItemLayoutParams, _ mergedTop: Bool, _ mergedBottom: Bool, _ dateAtBottom: Bool) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
        return { [weak self] item, params, mergedTop, mergedBottom, dateHeaderAtBottom -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) in
            guard let self else {
                return (ListViewItemNodeLayout(contentSize: .zero, insets: .zero), { _ in })
            }
            
            let bubbleParams = ChatMessageBubbleNicegramParams(
                params: params,
                presentationData: item.presentationData
            )
            
            let size = bannerView.update(
                props: .init(
                    layout: .init(
                        availableWidth: params.width,
                        insets: .init(bubbleParams.insets)
                    ),
                    viewState: item.viewState
                ),
                viewModel: item.viewModel
            )
            
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: .zero
            )
            
            let apply: (ListViewItemUpdateAnimation) -> Void = { [weak self] _ in
                self?.bannerNode.frame = CGRect(origin: .zero, size: size)
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
