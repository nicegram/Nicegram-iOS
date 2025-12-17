import AsyncDisplayKit
import Display
import FeatChatListWidget
import Foundation
import SwiftSignalKit
import TelegramPresentationData
import UIKit

@available(iOS 16.0, *)
class ChatListNicegramWidget: ListViewItem {
    let height: Double
    let theme: PresentationTheme
    
    init(height: Double, theme: PresentationTheme) {
        self.height = height
        self.theme = theme
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        MainActor.runSyncOrAsync {
            let node = ChatListNicegramWidgetNode()
            
            let (nodeLayout, apply) = node.asyncLayout()(self, params, false)
            
            node.contentSize = nodeLayout.contentSize
            node.insets = nodeLayout.insets
            
            completion(node, {
                return (nil, { _ in apply() })
            })
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        MainActor.runSyncOrAsync {
            if let nodeValue = node() as? ChatListNicegramWidgetNode {
                let nodeLayout = nodeValue.asyncLayout()
                
                let (layout, apply) = nodeLayout(self, params, nextItem == nil)
                
                completion(layout, { _ in
                    apply()
                })
            } else {
                assertionFailure()
            }
        }
    }
}

final class ChatListNicegramWidgetView: UIView {}

@available(iOS 16.0, *)
final class ChatListNicegramWidgetNode: ListViewItemNode {
    private let widgetNode: ASDisplayNode
    
    @MainActor
    init() {
        let widgetView = makeChatListWidgetView()
        
        let widgetContainer = ChatListNicegramWidgetView()
        widgetContainer.addSubview(widgetView)
        widgetView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.widgetNode = ASDisplayNode { widgetContainer }
        
        super.init(layerBacked: false, dynamicBounce: false, rotated: false, seeThrough: false)
        
        self.addSubnode(widgetNode)
    }
    
    override func layoutForParams(_ params: ListViewItemLayoutParams, item: ListViewItem, previousItem: ListViewItem?, nextItem: ListViewItem?) {
        let layout = self.asyncLayout()
        let (_, apply) = layout(item as! ChatListNicegramWidget, params, nextItem == nil)
        apply()
    }
    
    func asyncLayout() -> (_ item: ChatListNicegramWidget, _ params: ListViewItemLayoutParams, _ isLast: Bool) -> (ListViewItemNodeLayout, () -> Void) {
        return { [weak self] item, params, last in
            let size = CGSize(
                width: params.width,
                height: item.height
            )
            
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: .zero
            )
            
            let apply: () -> Void = {
                MainActor.runSyncOrAsync {
                    guard let self else { return }
                    
                    self.widgetNode.backgroundColor = item.theme.chatList.itemBackgroundColor
                    self.widgetNode.frame = CGRect(origin: .zero, size: size)
                }
            }
            
            return (layout, apply)
        }
    }
}

private extension MainActor {
    /// Executes MainActor-isolated code from a synchronous context.
    /// - If already on the main thread, executes immediately.
    /// - Otherwise, schedules execution asynchronously on MainActor.
    static func runSyncOrAsync(
        _ body: @escaping @MainActor () -> Void
    ) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(body)
        } else {
            Task { @MainActor in
                body()
            }
        }
    }
}
