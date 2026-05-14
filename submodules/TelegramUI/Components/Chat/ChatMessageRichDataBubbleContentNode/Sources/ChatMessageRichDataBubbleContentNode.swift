import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramCore
import Postbox
import SwiftSignalKit
import AccountContext
import ChatMessageBubbleContentNode
import ChatMessageItemCommon
import InstantPageUI
import TelegramUIPreferences

public class ChatMessageRichDataBubbleContentNode: ChatMessageBubbleContentNode {
    public final class ContainerNode: ASDisplayNode {
    }
    
    private let containerNode: ContainerNode
    private var currentLayoutTiles: [InstantPageTile] = []
    private var visibleTiles: [Int: InstantPageTileNode] = [:]
    private var visibleItemsWithNodes: [Int: InstantPageNode] = [:]
    private var currentPageLayout: (boundingWidth: CGFloat, layout: InstantPageLayout)?
    private var distanceThresholdGroupCount: [Int: Int] = [:]
    private var currentLayoutItemsWithNodes: [InstantPageItem] = []
    private var currentExpandedDetails: [Int : Bool]?
    
    override public var visibility: ListViewItemNodeVisibility {
        didSet {
            if oldValue != self.visibility {
                self.updateVisibility()
            }
        }
    }
    
    required public init() {
        self.containerNode = ContainerNode()
        self.containerNode.clipsToBounds = true
        
        super.init()
        
        self.addSubnode(self.containerNode)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
    }
    
    override public func asyncLayoutContent() -> (_ item: ChatMessageBubbleContentItem, _ layoutConstants: ChatMessageItemLayoutConstants, _ preparePosition: ChatMessageBubblePreparePosition, _ messageSelection: Bool?, _ constrainedSize: CGSize, _ avatarInset: CGFloat) -> (ChatMessageBubbleContentProperties, CGSize?, CGFloat, (CGSize, ChatMessageBubbleContentPosition) -> (CGFloat, (CGFloat) -> (CGSize, (ListViewItemUpdateAnimation, Bool, ListViewItemApply?) -> Void))) {
        let currentPageLayout = self.currentPageLayout
        let previousCurrentLayoutTiles = self.currentLayoutTiles
        
        return { [weak self] item, layoutConstants, _, _, _, _ in
            let contentProperties = ChatMessageBubbleContentProperties(hidesSimpleAuthorHeader: false, headerSpacing: 0.0, hidesBackground: .never, forceFullCorners: false, forceAlignment: .none)
            
            return (contentProperties, nil, CGFloat.greatestFiniteMagnitude, { constrainedSize, position in
                let suggestedBoundingWidth: CGFloat = constrainedSize.width
                
                return (suggestedBoundingWidth, { boundingWidth in
                    var boundingSize = CGSize(width: boundingWidth, height: 0.0)
                    
                    var pageLayout: InstantPageLayout?
                    var currentLayoutTiles: [InstantPageTile] = []
                    
                    if let webpage = item.message.media.first(where: { $0 is TelegramMediaWebpage }) as? TelegramMediaWebpage, case let .Loaded(content) = webpage.content, let instantPage = content.instantPage {
                        if let current = currentPageLayout, current.boundingWidth == boundingSize.width {
                            pageLayout = current.layout
                            currentLayoutTiles = previousCurrentLayoutTiles
                        } else {
                            let pageTheme = instantPageThemeForType(item.presentationData.theme.theme.overallDarkAppearance ? .dark : .light, settings: InstantPagePresentationSettings(
                                themeType: item.presentationData.theme.theme.overallDarkAppearance ? .dark : .light,
                                fontSize: .standard,
                                forceSerif: false,
                                autoNightMode: false,
                                ignoreAutoNightModeUntil: 0
                            ))
                            pageLayout = instantPageLayoutForWebPage(webpage, instantPage: instantPage._parse(), userLocation: .other, boundingWidth: boundingWidth - 2.0, safeInset: 0.0, strings: item.presentationData.strings, theme: pageTheme, dateTimeFormat: item.presentationData.dateTimeFormat, webEmbedHeights: [:], addFeedback: false)
                            if let pageLayout {
                                currentLayoutTiles = instantPageTilesFromLayout(pageLayout, boundingWidth: boundingWidth)
                            }
                        }
                    }
                    
                    if let pageLayout {
                        boundingSize.height = pageLayout.contentSize.height + 2.0
                    }
                    
                    return (boundingSize, { animation, synchronousLoads, itemApply in
                        guard let self else {
                            return
                        }
                        self.item = item
                        
                        self.containerNode.frame = CGRect(origin: CGPoint(x: 1.0, y: 1.0), size: CGSize(width: boundingSize.width - 2.0, height: boundingSize.height - 2.0))
                        
                        if let pageLayout {
                            self.currentPageLayout = (boundingSize.width, pageLayout)
                            self.currentLayoutTiles = currentLayoutTiles
                            
                            var distanceThresholdGroupCount: [Int : Int] = [:]
                            
                            for item in pageLayout.items {
                                if item.wantsNode {
                                    self.currentLayoutItemsWithNodes.append(item)
                                    
                                    if let group = item.distanceThresholdGroup() {
                                        let count: Int
                                        if let currentCount = distanceThresholdGroupCount[Int(group)] {
                                            count = currentCount
                                        } else {
                                            count = 0
                                        }
                                        distanceThresholdGroupCount[Int(group)] = count + 1
                                    }
                                }
                            }
                            
                            self.distanceThresholdGroupCount = distanceThresholdGroupCount
                        } else {
                            self.currentPageLayout = nil
                            self.currentLayoutTiles = []
                            self.distanceThresholdGroupCount = [:]
                        }
                        
                        self.updateVisibility()
                    })
                })
            })
        }
    }
    
    private func effectiveFrameForTile(_ tile: InstantPageTile) -> CGRect {
        let layoutOrigin = tile.frame.origin
        let origin = layoutOrigin
        return CGRect(origin: origin, size: tile.frame.size)
    }
    
    private func updateVisibility() {
        switch self.visibility {
        case .none:
            self.updateVisibleItems(visibleBounds: CGRect(), animated: false)
        case let .visible(_, subRect):
            self.updateVisibleItems(visibleBounds: subRect, animated: false)
        }
    }
    
    private func updateVisibleItems(visibleBounds: CGRect, animated: Bool = false) {
        guard let messageItem = self.item else {
            return
        }
        let pageTheme = instantPageThemeForType(messageItem.presentationData.theme.theme.overallDarkAppearance ? .dark : .light, settings: InstantPagePresentationSettings(
            themeType: messageItem.presentationData.theme.theme.overallDarkAppearance ? .dark : .light,
            fontSize: .standard,
            forceSerif: false,
            autoNightMode: false,
            ignoreAutoNightModeUntil: 0
        ))
        let sourceLocation = InstantPageSourceLocation(userLocation: .other, peerType: .otherPrivate)
        
        var visibleTileIndices = Set<Int>()
        var visibleItemIndices = Set<Int>()
        
        var topNode: ASDisplayNode?
        let topTileNode = topNode
        if let containerSubnodes = self.containerNode.subnodes {
            for node in containerSubnodes.reversed() {
                if let node = node as? InstantPageTileNode {
                    topNode = node
                    break
                }
            }
        }
        
        var collapseOffset: CGFloat = 0.0
        collapseOffset = 0.0
        let transition: ContainedViewLayoutTransition
        if animated {
            transition = .animated(duration: 0.3, curve: .spring)
        } else {
            transition = .immediate
        }
        
        var itemIndex = -1
        var embedIndex = -1
        var detailsIndex = -1
        
        var previousDetailsNode: InstantPageDetailsNode?
        
        for item in self.currentLayoutItemsWithNodes {
            itemIndex += 1
            if item is InstantPageWebEmbedItem {
                embedIndex += 1
            }
            if let imageItem = item as? InstantPageImageItem, case .webpage = imageItem.media.media {
                embedIndex += 1
            }
            if item is InstantPageDetailsItem {
                detailsIndex += 1
            }
    
            var itemThreshold: CGFloat = 0.0
            if let group = item.distanceThresholdGroup() {
                var count: Int = 0
                if let currentCount = self.distanceThresholdGroupCount[group] {
                    count = currentCount
                }
                itemThreshold = item.distanceThresholdWithGroupCount(count)
            }
            
            let itemFrame = item.frame.offsetBy(dx: 0.0, dy: -collapseOffset)
            var thresholdedItemFrame = itemFrame
            thresholdedItemFrame.origin.y -= itemThreshold
            thresholdedItemFrame.size.height += itemThreshold * 2.0
            
            if visibleBounds.intersects(thresholdedItemFrame) {
                visibleItemIndices.insert(itemIndex)
                
                var itemNode = self.visibleItemsWithNodes[itemIndex]
                if let currentItemNode = itemNode {
                    if !item.matchesNode(currentItemNode) {
                        currentItemNode.removeFromSupernode()
                        self.visibleItemsWithNodes.removeValue(forKey: itemIndex)
                        itemNode = nil
                    }
                }
                
                if itemNode == nil {
                    let itemIndex = itemIndex
                    //let embedIndex = embedIndex
                    //let detailsIndex = detailsIndex
                    if let newNode = item.node(context: messageItem.context, strings: messageItem.presentationData.strings, nameDisplayOrder: messageItem.presentationData.nameDisplayOrder, theme: pageTheme, sourceLocation: sourceLocation, openMedia: { [weak self] media in
                        let _ = self
                        //self?.openMedia(media)
                    }, longPressMedia: { [weak self] media in
                        //self?.longPressMedia(media)
                        let _ = self
                    }, activatePinchPreview: { [weak self] sourceNode in
                        /*guard let strongSelf = self, let controller = strongSelf.controller else {
                            return
                        }
                        let pinchController = makePinchController(sourceNode: sourceNode, getContentAreaInScreenSpace: {
                            guard let strongSelf = self else {
                                return CGRect()
                            }

                            let localRect = CGRect(origin: CGPoint(x: 0.0, y: strongSelf.navigationBar.frame.maxY), size: CGSize(width: strongSelf.bounds.width, height: strongSelf.bounds.height - strongSelf.navigationBar.frame.maxY))
                            return strongSelf.view.convert(localRect, to: nil)
                        })
                        controller.window?.presentInGlobalOverlay(pinchController)*/
                        let _ = self
                    }, pinchPreviewFinished: { [weak self] itemNode in
                        /*guard let strongSelf = self else {
                            return
                        }
                        for (_, listItemNode) in strongSelf.visibleItemsWithNodes {
                            if let listItemNode = listItemNode as? InstantPagePeerReferenceNode {
                                if listItemNode.frame.intersects(itemNode.frame) && listItemNode.frame.maxY <= itemNode.frame.maxY + 2.0 {
                                    listItemNode.layer.animateAlpha(from: 0.0, to: listItemNode.alpha, duration: 0.25)
                                    break
                                }
                            }
                        }*/
                        let _ = self
                    }, openPeer: { [weak self] peerId in
                        let _ = self
                        //self?.openPeer(peerId)
                    }, openUrl: { [weak self] url in
                        let _ = self
                        //self?.openUrl(url)
                    }, updateWebEmbedHeight: { [weak self] height in
                        let _ = self
                        //self?.updateWebEmbedHeight(embedIndex, height)
                    }, updateDetailsExpanded: { [weak self] expanded in
                        let _ = self
                        //self?.updateDetailsExpanded(detailsIndex, expanded)
                    }, currentExpandedDetails: self.currentExpandedDetails, getPreloadedResource: { _ in return nil }) {
                        newNode.frame = itemFrame
                        newNode.updateLayout(size: itemFrame.size, transition: transition)
                        if let topNode = topNode {
                            self.containerNode.insertSubnode(newNode, aboveSubnode: topNode)
                        } else {
                            self.containerNode.insertSubnode(newNode, at: 0)
                        }
                        topNode = newNode
                        self.visibleItemsWithNodes[itemIndex] = newNode
                        itemNode = newNode
                        
                        if let itemNode = itemNode as? InstantPageDetailsNode {
                            itemNode.requestLayoutUpdate = { [weak self] animated in
                                let _ = self
                                /*if let strongSelf = self {
                                    strongSelf.updateVisibleItems(visibleBounds: strongSelf.scrollNode.view.bounds, animated: animated)
                                }*/
                            }
                            
                            if let previousDetailsNode = previousDetailsNode {
                                if itemNode.frame.minY - previousDetailsNode.frame.maxY < 1.0 {
                                    itemNode.previousNode = previousDetailsNode
                                }
                            }
                            previousDetailsNode = itemNode
                        }
                    }
                } else {
                    if let itemNode = itemNode, itemNode.frame != itemFrame {
                        transition.updateFrame(node: itemNode, frame: itemFrame)
                        itemNode.updateLayout(size: itemFrame.size, transition: transition)
                    }
                }
                
                if let itemNode = itemNode as? InstantPageDetailsNode {
                    itemNode.updateVisibleItems(visibleBounds: visibleBounds.offsetBy(dx: -itemNode.frame.minX, dy: -itemNode.frame.minY), animated: animated)
                }
            }
        }
        
        topNode = topTileNode
        
        var tileIndex = -1
        for tile in self.currentLayoutTiles {
            tileIndex += 1
            
            let tileFrame = effectiveFrameForTile(tile)
            var tileVisibleFrame = tileFrame
            tileVisibleFrame.origin.y -= 400.0
            tileVisibleFrame.size.height += 400.0 * 2.0
            if tileVisibleFrame.intersects(visibleBounds) {
                visibleTileIndices.insert(tileIndex)
                
                if self.visibleTiles[tileIndex] == nil {
                    let tileNode = InstantPageTileNode(tile: tile, backgroundColor: .clear)
                    tileNode.frame = tileFrame
                    if let topNode = topNode {
                        self.containerNode.insertSubnode(tileNode, aboveSubnode: topNode)
                    } else {
                        self.containerNode.insertSubnode(tileNode, at: 0)
                    }
                    topNode = tileNode
                    self.visibleTiles[tileIndex] = tileNode
                } else {
                    if let tileNode = self.visibleTiles[tileIndex] {
                        tileNode.update(tile: tile, backgroundColor: .clear)
                        if tileNode.frame != tileFrame {
                            transition.updateFrame(node: tileNode, frame: tileFrame)
                        }
                    }
                }
            }
        }
        
        var removeTileIndices: [Int] = []
        for (index, tileNode) in self.visibleTiles {
            if !visibleTileIndices.contains(index) {
                removeTileIndices.append(index)
                tileNode.removeFromSupernode()
            }
        }
        for index in removeTileIndices {
            self.visibleTiles.removeValue(forKey: index)
        }
        
        var removeItemIndices: [Int] = []
        for (index, itemNode) in self.visibleItemsWithNodes {
            if !visibleItemIndices.contains(index) {
                removeItemIndices.append(index)
                itemNode.removeFromSupernode()
            } else {
                var itemFrame = itemNode.frame
                let itemThreshold: CGFloat = 200.0
                itemFrame.origin.y -= itemThreshold
                itemFrame.size.height += itemThreshold * 2.0
                itemNode.updateIsVisible(visibleBounds.intersects(itemFrame))
            }
        }
        for index in removeItemIndices {
            self.visibleItemsWithNodes.removeValue(forKey: index)
        }
    }
    
    override public func animateInsertion(_ currentTimestamp: Double, duration: Double) {
        /*self.textNode.textNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        if let statusNode = self.statusNode, statusNode.alpha != 0.0 {
            statusNode.layer.animateAlpha(from: 0.0, to: statusNode.alpha, duration: 0.2)
        }*/
    }
    
    override public func animateAdded(_ currentTimestamp: Double, duration: Double) {
        /*self.textNode.textNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        if let statusNode = self.statusNode, statusNode.alpha != 0.0 {
            statusNode.layer.animateAlpha(from: 0.0, to: statusNode.alpha, duration: 0.2)
        }*/
    }
    
    override public func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        /*self.textNode.textNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
        if let statusNode = self.statusNode, statusNode.alpha != 0.0 {
            statusNode.layer.animateAlpha(from: statusNode.alpha, to: 0.0, duration: 0.2, removeOnCompletion: false)
        }*/
    }
    
    override public func tapActionAtPoint(_ point: CGPoint, gesture: TapLongTapOrDoubleTapGesture, isEstimating: Bool) -> ChatMessageBubbleContentTapAction {
        if case .tap = gesture {
        } else {
            if let item = self.item, let subject = item.associatedData.subject, case .messageOptions = subject {
                return ChatMessageBubbleContentTapAction(content: .none)
            }
        }
        
        /*func makeActivate(_ urlRange: NSRange?) -> (() -> Promise<Bool>?)? {
            return { [weak self] in
                guard let self else {
                    return nil
                }
                
                let promise = Promise<Bool>()
                
                self.linkProgressDisposable?.dispose()
                
                if self.linkProgressRange != nil {
                    self.linkProgressRange = nil
                    self.updateLinkProgressState()
                }
                
                self.linkProgressDisposable = (promise.get() |> deliverOnMainQueue).startStrict(next: { [weak self] value in
                    guard let self else {
                        return
                    }
                    let updatedRange: NSRange? = value ? urlRange : nil
                    if self.linkProgressRange != updatedRange {
                        self.linkProgressRange = updatedRange
                        self.updateLinkProgressState()
                    }
                })
                
                return promise
            }
        }*/
        
        return ChatMessageBubbleContentTapAction(content: .none)
    }
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return super.hitTest(point, with: event)
    }
    
    override public func updateTouchesAtPoint(_ point: CGPoint?) {
    }
    
    override public func updateSearchTextHighlightState(text: String?, messages: [MessageIndex]?) {
    }
    
    override public func willUpdateIsExtractedToContextPreview(_ value: Bool) {
    }
    
    override public func updateIsExtractedToContextPreview(_ value: Bool) {
    }
    
    override public func reactionTargetView(value: MessageReaction.Reaction) -> UIView? {
        /*if let statusNode = self.statusNode, !statusNode.isHidden {
            return statusNode.reactionView(value: value)
        }*/
        return nil
    }
    
    override public func messageEffectTargetView() -> UIView? {
        /*if let statusNode = self.statusNode, !statusNode.isHidden {
            return statusNode.messageEffectTargetView()
        }*/
        return nil
    }
    
    override public func getStatusNode() -> ASDisplayNode? {
        return nil
        //return self.statusNode
    }
}
