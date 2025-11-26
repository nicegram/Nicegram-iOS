import AsyncDisplayKit
import Display
import FeatNftSticker
import PeerInfoPaneNode
import Postbox
import SwiftSignalKit
import TelegramPresentationData
import UIKit

@available(iOS 16.0, *)
final class PeerInfoNftsPaneNode: ASDisplayNode, PeerInfoPaneNode {
    private let contentNode: ASDisplayNode
    
    weak var parentController: ViewController?
    
    var isReady: Signal<Bool, NoError> { .single(true) }
    
    var status: Signal<PeerInfoStatusData?, NoError> { .single(nil) }
    
    var tabBarOffsetUpdated: ((ContainedViewLayoutTransition) -> Void)?
    var tabBarOffset: CGFloat { 0 }
    
    init(viewModel: UserNftsViewModel) {
        self.contentNode = ASDisplayNode {
            makeUserNftsView(viewModel: viewModel)
        }
        
        super.init()
        
        addSubnode(contentNode)
    }
    
    func update(size: CGSize, topInset: CGFloat, sideInset: CGFloat, bottomInset: CGFloat, deviceMetrics: DeviceMetrics, visibleHeight: CGFloat, isScrollingLockedAtTop: Bool, expandProgress: CGFloat, navigationHeight: CGFloat, presentationData: PresentationData, synchronous: Bool, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: contentNode, frame: CGRect(origin: CGPoint(x: 0, y: topInset), size: CGSize(width: size.width, height: size.height - topInset)))
    }
    
    func scrollToTop() -> Bool { false }
    func transferVelocity(_ velocity: CGFloat) {}
    func cancelPreviewGestures() {}
    func findLoadedMessage(id: MessageId) -> Message? { nil }
    func transitionNodeForGallery(messageId: MessageId, media: Media) -> (ASDisplayNode, CGRect, () -> (UIView?, UIView?))? { nil }
    func addToTransitionSurface(view: UIView) {}
    func updateHiddenMedia() {}
    func updateSelectedMessages(animated: Bool) {}
    func ensureMessageIsVisible(id: MessageId) {}
}
