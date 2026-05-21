import AsyncDisplayKit
import Display
import TelegramCore
import SwiftSignalKit
import Postbox
import TelegramPresentationData
import ItemListUI
import FeatSpyOnFriends

@available(iOS 15.0, *)
public final class SpyOnFriendsHeaderItem: ListViewItem, ItemListItem {
    public let sectionId: ItemListSectionId
    public let context: SpyOnFriendsContext
    public let theme: PresentationTheme
    public let locale: Locale
    public let peerId: Int64
    public let isRefreshing: Bool
    
    public init(
        sectionId: ItemListSectionId,
        context: SpyOnFriendsContext,
        theme: PresentationTheme,
        locale: Locale,
        peerId: Int64,
        isRefreshing: Bool
    ) {
        self.sectionId = sectionId
        self.context = context
        self.theme = theme
        self.locale = locale
        self.peerId = peerId
        self.isRefreshing = isRefreshing
    }

    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        let configure = { () -> Void in
            let node = SpyOnFriendsHeaderNode(peerId: self.peerId)
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
            if let nodeValue = node() as? SpyOnFriendsHeaderNode {
                nodeValue.setupItem(self)
                
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
class SpyOnFriendsHeaderNode: ListViewItemNode {
    var item: SpyOnFriendsHeaderItem?

    private let headerView: SpyOnFriendsHeaderView
    private let headerNode: ASDisplayNode
    
    required init(peerId: Int64) {
        let headerView = SpyOnFriendsHeaderView(peerId: peerId)
        self.headerView = headerView
        self.headerNode = ASDisplayNode {
            headerView
        }

        super.init(layerBacked: false, dynamicBounce: false, rotated: false)

        self.addSubnode(headerNode)
    }
    
    func setupItem(_ item: SpyOnFriendsHeaderItem) {
        self.item = item
        
        headerView.setup(
            with: item.theme.list.itemAccentColor,
            backgroundColor: item.theme.list.itemBlocksBackgroundColor,
            locale: item.locale,
            isRefreshing: item.isRefreshing
        ) {
            item.context.load()
        }
    }

    func asyncLayout() -> (_ item: SpyOnFriendsHeaderItem, _ params: ListViewItemLayoutParams, _ mergedTop: Bool, _ mergedBottom: Bool, _ dateAtBottom: Bool) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
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

            headerView.setup(
                with: item.theme.list.itemAccentColor,
                backgroundColor: item.theme.list.itemBlocksBackgroundColor,
                locale: item.locale,
                isRefreshing: item.isRefreshing
            ) {
                item.context.load()
            }
            headerView.updateConstraintsIfNeeded()

            let headerInsets: UIEdgeInsets = isPortrait ? .vertical(12).horizontal(16) : .vertical(12).horizontal(59)
            let headerSize = headerView.systemLayoutSizeFitting(
                UIView.layoutFittingExpandedSize
            )
            let size = CGSize(
                width: params.width - (headerInsets.left + headerInsets.right),
                height: headerSize.height
            )
            
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: headerInsets
            )
            
            let apply: (ListViewItemUpdateAnimation) -> Void = { [weak self] _ in
                guard let self else { return }
                headerNode.frame = CGRect(origin: .init(x: headerInsets.left, y: 0), size: size)
            }
            
            return (layout, apply)
        }
    }
}
