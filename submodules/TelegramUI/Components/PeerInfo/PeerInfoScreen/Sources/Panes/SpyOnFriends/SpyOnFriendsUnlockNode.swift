import AsyncDisplayKit
import Display
import TelegramCore
import SwiftSignalKit
import Postbox
import TelegramPresentationData
import ItemListUI
import FeatSpyOnFriends
import AccountContext

@available(iOS 15.0, *)
public final class SpyOnFriendsUnlockItem: ListViewItem, ItemListItem {
    public let sectionId: ItemListSectionId
    public let theme: PresentationTheme
    public let locale: Locale
    public let context: SpyOnFriendsContext
    public let accountContext: AccountContext
    public let peerId: PeerId
    public let share: () -> Void
    
    public init(
        sectionId: ItemListSectionId,
        theme: PresentationTheme,
        locale: Locale,
        context: SpyOnFriendsContext,
        accountContext: AccountContext,
        peerId: PeerId,
        share: @escaping () -> Void
    ) {
        self.sectionId = sectionId
        self.theme = theme
        self.locale = locale
        self.context = context
        self.accountContext = accountContext
        self.peerId = peerId
        self.share = share
    }

    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        let configure = { () -> Void in
            let node = SpyOnFriendsUnlockNode(peerId: self.peerId.id._internalGetInt64Value())
            node.setupItem(self)

            let (layout, apply) = node.asyncLayout()(self, params, false, false, false)
            
            node.contentSize = layout.contentSize
            node.insets = layout.insets

            completion(node, {
                return (nil, { _ in apply(.None) })
            })
        }
        if Thread.isMainThread {
            configure()
        } else {
            Queue.mainQueue().async(configure)
        }
    }
    
    public func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? SpyOnFriendsUnlockNode {
                let nodeLayout = nodeValue.asyncLayout()
                
                let (layout, apply) = nodeLayout(self, params, false, false, false)
                
                completion(layout, { _ in
                    apply(animation)
                })
            } else {
                assertionFailure()
            }
        }
    }
}

@available(iOS 15.0, *)
class SpyOnFriendsUnlockNode: ListViewItemNode {
    var item: SpyOnFriendsUnlockItem?

    private let unlockView: SpyOnFriendsUnlockView
    private let unlockNode: ASDisplayNode
    
    required init(peerId: Int64) {
        let unlockView = SpyOnFriendsUnlockView(peerId: peerId)
        self.unlockView = unlockView
        self.unlockNode = ASDisplayNode {
            unlockView
        }

        super.init(layerBacked: false, dynamicBounce: false, rotated: false)
        
        self.addSubnode(unlockNode)
    }

    func setupItem(_ item: SpyOnFriendsUnlockItem) {
        self.item = item

        unlockView.setup(
            with: item.theme.list.itemAccentColor,
            backgroundColor: item.theme.list.itemBlocksBackgroundColor,
            textColor: item.theme.list.blocksBackgroundColor,
            locale: item.locale
        ) {
            item.context.load()
        } share: {
            item.share()
        }
        unlockView.rotate()
    }

    func asyncLayout() -> (_ item: SpyOnFriendsUnlockItem, _ params: ListViewItemLayoutParams, _ mergedTop: Bool, _ mergedBottom: Bool, _ dateAtBottom: Bool) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
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
            
            unlockView.setup(
                with: item.theme.list.itemAccentColor,
                backgroundColor: item.theme.list.itemBlocksBackgroundColor,
                textColor: item.theme.list.blocksBackgroundColor,
                locale: item.locale
            ) {
                item.context.load()
            } share: {
                item.share()
            }
            unlockView.rotate()
            unlockView.updateConstraintsIfNeeded()
            
            let unlockInsets: UIEdgeInsets = isPortrait ? .top(20).bottom(64).horizontal(16) : .top(20).bottom(32).horizontal(59)
            let unlockSize = unlockView.systemLayoutSizeFitting(
                UIView.layoutFittingExpandedSize
            )
            
            let size = CGSize(
                width: params.width - (unlockInsets.left + unlockInsets.right),
                height: unlockSize.height + unlockInsets.bottom
            )
            
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: unlockInsets
            )
            
            let apply: (ListViewItemUpdateAnimation) -> Void = { [weak self] _ in
                guard let self else { return }
                unlockNode.frame = CGRect(origin: .init(x: unlockInsets.left, y: 0), size: size)
            }
            
            return (layout, apply)
        }
    }
}
