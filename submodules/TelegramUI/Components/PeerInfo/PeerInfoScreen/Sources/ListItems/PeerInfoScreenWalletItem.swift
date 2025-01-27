import AccountContext
import AsyncDisplayKit
import Display
import MemberwiseInit
import NGUtils
import NicegramWallet
import Postbox
import TelegramPresentationData

@available(iOS 16.0, *)
@MemberwiseInit
final class PeerInfoScreenWalletItem: PeerInfoScreenItem {
    let peer: Peer?
    
    var id: AnyHashable { ID() }
    struct ID: Hashable {}
    
    func node() -> PeerInfoScreenItemNode {
        return PeerInfoScreenWalletItemNode()
    }
}

@available(iOS 16.0, *)
private final class PeerInfoScreenWalletItemNode: PeerInfoScreenItemNode {
    private let viewModel: TgProfileWalletViewModel
    
    private let itemNode: ASDisplayNode
    private let maskNode: ASImageNode
    
    override init() {
        let viewModel = TgProfileWalletViewModel()
        let itemView = makeTgProfileWalletView(viewModel)
        self.viewModel = viewModel
        self.itemNode = ASDisplayNode { itemView }
        
        self.maskNode = ASImageNode()
        self.maskNode.isUserInteractionEnabled = false
        
        super.init()
        
        self.addSubnode(self.itemNode)
        self.addSubnode(self.maskNode)
    }
    
    override func update(context: AccountContext, width: CGFloat, safeInsets: UIEdgeInsets, presentationData: PresentationData, item: PeerInfoScreenItem, topItem: PeerInfoScreenItem?, bottomItem: PeerInfoScreenItem?, hasCorners: Bool, transition: ContainedViewLayoutTransition) -> CGFloat {
        let height: CGFloat = 72
        
        guard let item = item as? PeerInfoScreenWalletItem else {
            return height
        }
        
        if let peer = item.peer {
            viewModel.set(contact: .init(peer))
        }
        viewModel.set(theme: .init(presentationData))
        
        let hasCorners = hasCorners && (topItem == nil || bottomItem == nil)
        let hasTopCorners = hasCorners && topItem == nil
        let hasBottomCorners = hasCorners && bottomItem == nil
        self.maskNode.image = hasCorners ? PresentationResourcesItemList.cornersImage(presentationData.theme, top: hasTopCorners, bottom: hasBottomCorners) : nil
        self.maskNode.frame = CGRect(origin: CGPoint(x: safeInsets.left, y: 0.0), size: CGSize(width: width - safeInsets.left - safeInsets.right, height: height))
        
        transition.updateFrame(node: self.itemNode, frame: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        
        return height
    }
}
