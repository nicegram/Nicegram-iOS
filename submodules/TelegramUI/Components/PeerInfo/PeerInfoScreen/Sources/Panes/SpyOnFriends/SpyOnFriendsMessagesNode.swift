import AsyncDisplayKit
import Display
import TelegramCore
import SwiftSignalKit
import Postbox
import TelegramPresentationData
import ItemListUI
import FeatSpyOnFriends
import AccountContext
import AvatarNode

@available(iOS 15.0, *)
public final class SpyOnFriendsMessagesItem: ListViewItem, ItemListItem {
    public let sectionId: ItemListSectionId
    public let context: AccountContext
    public let theme: PresentationTheme
    public let locale: Locale
    public let group: (Date, [SpyOnFriendsGroup])
    public let openMessage: (Int32) -> Void
    
    public init(
        sectionId: ItemListSectionId,
        context: AccountContext,
        theme: PresentationTheme,
        locale: Locale,
        group: (Date, [SpyOnFriendsGroup]),
        openMessage: @escaping (Int32) -> Void
    ) {
        self.sectionId = sectionId
        self.context = context
        self.theme = theme
        self.locale = locale
        self.group = group
        self.openMessage = openMessage
    }

    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        let configure = { () -> Void in
            let node = SpyOnFriendsMessagesNode()
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
            if let nodeValue = node() as? SpyOnFriendsMessagesNode {
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
class SpyOnFriendsMessagesNode: ListViewItemNode {
    var item: SpyOnFriendsMessagesItem?

    private let messagesView: SpyOnFriendsMessagesView
    private let messagesNode: ASDisplayNode

    required init() {
        let messagesView = SpyOnFriendsMessagesView()
        self.messagesView = messagesView
        self.messagesNode = ASDisplayNode {
            messagesView
        }

        super.init(layerBacked: false, dynamicBounce: false, rotated: false)
        
        self.addSubnode(messagesNode)
    }
    
    func setupItem(_ item: SpyOnFriendsMessagesItem) {
        self.item = item
        
        messagesView.setup(
            with: item.group,
            backgroundColor: item.theme.list.itemBlocksBackgroundColor,
            locale: item.locale,
            tapOnMessage: { id in
                item.openMessage(id)
            },
            logoLoader: { [weak self] peerId in
                guard let self else { return nil }
                
                return try await self.peerAvatar(with: item.context, peerId: PeerId(peerId)).awaitForFirstValue()
            }
        )
    }

    func asyncLayout() -> (_ item: SpyOnFriendsMessagesItem, _ params: ListViewItemLayoutParams, _ mergedTop: Bool, _ mergedBottom: Bool, _ dateAtBottom: Bool) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
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
            
            messagesView.setup(
                with: item.group,
                backgroundColor: item.theme.list.itemBlocksBackgroundColor,
                locale: item.locale,
                tapOnMessage: { id in
                    item.openMessage(id)
                },
                logoLoader: { [weak self] peerId in
                    guard let self else { return nil }
                    
                    return try await self.peerAvatar(with: item.context, peerId: PeerId(peerId)).awaitForFirstValue()
                }
            )
            messagesView.updateConstraintsIfNeeded()

            let messagesInsets: UIEdgeInsets = isPortrait ? .bottom(32).horizontal(16) : .bottom(32).horizontal(59)
            let messagesSize = messagesView.systemLayoutSizeFitting(
                UIView.layoutFittingExpandedSize
            )
            let size = CGSize(
                width: params.width - (messagesInsets.left + messagesInsets.right),
                height: messagesSize.height
            )
            
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: messagesInsets
            )
            
            let apply: (ListViewItemUpdateAnimation) -> Void = { [weak self] _ in
                guard let self else { return }
                messagesNode.frame = CGRect(origin: .init(x: messagesInsets.left, y: 0), size: size)
            }
            
            return (layout, apply)
        }
    }
    
    private func peerAvatar(with context: AccountContext, peerId: PeerId) -> Signal<UIImage?, NoError> {
        return context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
        |> mapToSignal { peer -> Signal<UIImage?, NoError> in
            guard let peer else { return .single(nil) }

            return peerAvatarCompleteImage(
                account: context.account,
                peer: peer,
                forceProvidedRepresentation: false,
                representation: nil,
                size: CGSize(width: 50, height: 50)
            )
        }
    }
}
