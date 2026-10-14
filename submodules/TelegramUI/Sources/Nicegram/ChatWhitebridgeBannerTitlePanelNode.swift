import Foundation
import UIKit
import Display
import AsyncDisplayKit
import FeatWhitebridge
import ChatPresentationInterfaceState
import LegacyChatHeaderPanelComponent

@available(iOS 16.0, *)
final class ChatWhitebridgeBannerTitlePanelNode: ChatTitleAccessoryPanelNode {
    private let contentNode: ASDisplayNode
    private var cachedHeight: CGFloat = 56.0
    
    init(
        onClose: @escaping () -> Void,
        onGetReport: @escaping () -> Void
    ) {
        self.contentNode = ASDisplayNode {
            makeWhitebridgeChatBannerView(
                onClose: onClose,
                onGetReport: onGetReport
            )
        }
        
        super.init()
        
        self.addSubnode(self.contentNode)
    }
    
    override func updateLayout(width: CGFloat, leftInset: CGFloat, rightInset: CGFloat, transition: ContainedViewLayoutTransition, interfaceState: ChatPresentationInterfaceState) -> LayoutResult {
        let panelHeight: CGFloat
        if self.contentNode.isNodeLoaded {
            let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
            let fittingSize = self.contentNode.view.systemLayoutSizeFitting(
                targetSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            panelHeight = max(44.0, ceil(fittingSize.height))
            self.cachedHeight = panelHeight
        } else {
            panelHeight = self.cachedHeight
        }
        
        transition.updateFrame(node: self.contentNode, frame: CGRect(origin: .zero, size: CGSize(width: width, height: panelHeight)))
        
        return LayoutResult(backgroundHeight: panelHeight, insetHeight: panelHeight, hitTestSlop: 0.0)
    }
}
