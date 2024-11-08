import FeatAttentionEconomy

import AccountContext
import ChatControllerInteraction
import Display
import Foundation
import SwiftSignalKit
import TelegramPresentationData

@available(iOS 15.0, *)
public final class ChatMessageNicegramAdItem: ListViewItem {
    public let ad: AttAd
    public let chatLocation: ChatLocation
    public let context: AccountContext
    public let controllerInteraction: ChatControllerInteraction
    public let presentationData: ChatPresentationData
    
    public init(ad: AttAd, chatLocation: ChatLocation, context: AccountContext, controllerInteraction: ChatControllerInteraction, presentationData: ChatPresentationData) {
        self.ad = ad
        self.chatLocation = chatLocation
        self.context = context
        self.controllerInteraction = controllerInteraction
        self.presentationData = presentationData
    }
    
    public func nodeConfiguredForParams(
        async: @escaping (@escaping () -> Void) -> Void,
        params: ListViewItemLayoutParams,
        synchronousLoads: Bool,
        previousItem: ListViewItem?,
        nextItem: ListViewItem?,
        completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void
    ) {
        let configure = { () -> Void in
            let node = ChatMessageNicegramAdNode(rotated: self.controllerInteraction.chatIsRotated)
            node.setupItem(self)
            
            let nodeLayout = node.asyncLayout()
            let (layout, apply) = nodeLayout(self, params, false, false, false)
            
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
            if let nodeValue = node() as? ChatMessageNicegramAdNode {
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
