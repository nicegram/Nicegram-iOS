import ChatControllerInteraction
import Display
import FeatAdsgram
import Foundation
import MemberwiseInit
import SwiftSignalKit
import TelegramPresentationData

@available(iOS 16.0, *)
@MemberwiseInit(.public)
public final class ChatMessageNicegramAdItem: ListViewItem {
    public let controllerInteraction: ChatControllerInteraction
    public let presentationData: ChatPresentationData
    public let viewModel: ChatMessageAdViewModel
    public let viewState: PlacementViewState
    
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
