import AccountContext
import AsyncDisplayKit
import Display
import FeatCalls
import MemberwiseInit
import NGUtils
import Postbox
import TelegramPresentationData

@available(iOS 16.0, *)
@MemberwiseInit
final class PeerInfoScreenNicegramCallsItem: PeerInfoScreenItem {
    let peer: Peer
    
    var id: AnyHashable { ID() }
    struct ID: Hashable {}
    
    func node() -> PeerInfoScreenItemNode {
        return PeerInfoScreenNicegramCallsItemNode()
    }
}

@available(iOS 16.0, *)
private final class PeerInfoScreenNicegramCallsItemNode: PeerInfoScreenItemNode {
    private let viewModel: TgProfileWidgetViewModel
    private let itemNode: ASDisplayNode
    
    override init() {
        let viewModel = TgProfileWidgetViewModel()
        let itemView = makeTgProfileWidgetView(viewModel)
        self.viewModel = viewModel
        self.itemNode = ASDisplayNode { itemView }
        
        super.init()
        
        self.addSubnode(self.itemNode)
    }
    
    override func update(context: AccountContext, width: CGFloat, safeInsets: UIEdgeInsets, presentationData: PresentationData, item: PeerInfoScreenItem, topItem: PeerInfoScreenItem?, bottomItem: PeerInfoScreenItem?, hasCorners: Bool, transition: ContainedViewLayoutTransition) -> CGFloat {
        let height = TgProfileWidgetView.Constants.height
        
        guard let item = item as? PeerInfoScreenNicegramCallsItem else {
            return height
        }
        
        if let user = try? CallParticipant.make(peer: item.peer) {
            viewModel.set(user: user)
        }
        
        transition.updateFrame(node: self.itemNode, frame: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        
        return height
    }
}
