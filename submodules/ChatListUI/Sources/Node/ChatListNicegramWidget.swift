import AsyncDisplayKit
import Display
import FeatChatListWidget
import Foundation
import SwiftSignalKit
import TelegramPresentationData
import UIKit

@available(iOS 15.0, *)
class ChatListNicegramWidget: ListViewItem {
    let chatListNodeInteraction: ChatListNodeInteraction
    let theme: PresentationTheme
    
    private var widgetView: ChatListNicegramWidgetView?
    
    init(chatListNodeInteraction: ChatListNodeInteraction, theme: PresentationTheme) {
        self.chatListNodeInteraction = chatListNodeInteraction
        self.theme = theme
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        let configure = { [self] () -> Void in
            let node = ChatListNicegramWidgetNode(widgetView: prepareWidgetView())
            
            let (nodeLayout, apply) = node.asyncLayout()(self, params, false)
            
            node.contentSize = nodeLayout.contentSize
            node.insets = nodeLayout.insets
            
            completion(node, {
                return (nil, { _ in apply() })
            })
        }
        if Thread.isMainThread {
            configure()
        } else {
            Queue.mainQueue().async(configure)
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
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
    
    private func prepareWidgetView() -> ChatListNicegramWidgetView {
        if let widgetView {
            widgetView.removeFromSuperview()
            return widgetView
        }
        
        let view = ChatListNicegramWidgetView()
        if let controller = chatListNodeInteraction.getController() {
            setupChatListWidget(view: view, controller: controller)
        }
        
        self.widgetView = view
        return view
    }
}

final class ChatListNicegramWidgetView: UIView {}

@available(iOS 15.0, *)
final class ChatListNicegramWidgetNode: ListViewItemNode {
    private var item: ChatListNicegramWidget?
    
    private let widgetNode: ASDisplayNode
    
    init(widgetView: ChatListNicegramWidgetView) {
        self.widgetNode = ASDisplayNode {
            widgetView
        }
        
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
                height: 110
            )
            
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: .zero
            )
            
            let apply: () -> Void = {
                guard let self else { return }
                
                self.widgetNode.backgroundColor = item.theme.chatList.itemBackgroundColor
                self.widgetNode.frame = CGRect(origin: .zero, size: size)
            }
            
            return (layout, apply)
        }
    }
}
