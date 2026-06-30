import AsyncDisplayKit
import Display
import FeatSpyOnFriends
import ItemListUI
import MemberwiseInit
import SwiftSignalKit
import TelegramCore

@available(iOS 16.0, *)
@MemberwiseInit(.public)
public final class SpyOnFriendsUnlockItem: ListViewItem, ItemListItem {
    public let context: SpyOnFriendsContext
    public let peerId: EnginePeer.Id
    public let peerName: String
    public let sectionId: ItemListSectionId

    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        let configure = { () -> Void in
            let node = SpyOnFriendsUnlockNode()
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

@available(iOS 16.0, *)
class SpyOnFriendsUnlockNode: ListViewItemNode {
    var item: SpyOnFriendsUnlockItem?

    private let unlockView: SpyOnFriendsUnlockView
    private let unlockNode: ASDisplayNode
    
    required init() {
        let unlockView = SpyOnFriendsUnlockView()
        self.unlockView = unlockView
        self.unlockNode = ASDisplayNode {
            unlockView
        }

        super.init(layerBacked: false, rotated: false)
        
        self.addSubnode(unlockNode)
    }

    func setupItem(_ item: SpyOnFriendsUnlockItem) {
        self.item = item
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

            let size = unlockView.update(
                props: .init(
                    layout: .init(
                        availableWidth: params.width
                    ),
                    peerId: item.peerId.id._internalGetInt64Value(),
                    peerName: item.peerName
                ),
                refresh: {
                    item.context.load()
                }
            )
            
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: .zero
            )
            
            let apply: (ListViewItemUpdateAnimation) -> Void = { [weak self] _ in
                self?.unlockNode.frame = CGRect(origin: .zero, size: size)
            }
            
            return (layout, apply)
        }
    }
}
