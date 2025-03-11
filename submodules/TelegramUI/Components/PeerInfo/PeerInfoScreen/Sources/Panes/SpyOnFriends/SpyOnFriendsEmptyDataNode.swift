import AsyncDisplayKit
import Display
import TelegramCore
import SwiftSignalKit
import Postbox
import TelegramPresentationData
import ItemListUI
import FeatSpyOnFriends

@available(iOS 15.0, *)
public final class SpyOnFriendsEmptyDataItem: ListViewItem, ItemListItem {
    public let sectionId: ItemListSectionId
    public let theme: PresentationTheme
    
    public init(
        sectionId: ItemListSectionId,
        theme: PresentationTheme
    ) {
        self.sectionId = sectionId
        self.theme = theme
    }

    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        let configure = { () -> Void in
            let node = SpyOnFriendsEmptyDataNode()
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
            if let nodeValue = node() as? SpyOnFriendsEmptyDataNode {
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
class SpyOnFriendsEmptyDataNode: ListViewItemNode {
    var item: SpyOnFriendsEmptyDataItem?

    private let emptyDataView: SpyOnFriendsEmptyDataView
    private let emptyDataNode: ASDisplayNode
    
    required init() {
        let emptyDataView = SpyOnFriendsEmptyDataView()
        self.emptyDataView = emptyDataView
        self.emptyDataNode = ASDisplayNode {
            emptyDataView
        }

        super.init(layerBacked: false, dynamicBounce: false, rotated: false)
        
        self.addSubnode(emptyDataNode)
    }

    func setupItem(_ item: SpyOnFriendsEmptyDataItem) {
        self.item = item
    }

    func asyncLayout() -> (_ item: SpyOnFriendsEmptyDataItem, _ params: ListViewItemLayoutParams, _ mergedTop: Bool, _ mergedBottom: Bool, _ dateAtBottom: Bool) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
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

            emptyDataView.updateConstraintsIfNeeded()
            
            let emptyDataInsets: UIEdgeInsets = isPortrait ? .vertical(20).horizontal(16) : .vertical(20).horizontal(59)
            
            let size = CGSize(
                width: params.width - (emptyDataInsets.left + emptyDataInsets.right),
                height: 300
            )
            
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: emptyDataInsets
            )
            
            let apply: (ListViewItemUpdateAnimation) -> Void = { [weak self] _ in
                guard let self else { return }
                emptyDataNode.frame = CGRect(origin: .init(x: emptyDataInsets.left, y: 0), size: size)
            }
            
            return (layout, apply)
        }
    }
}
