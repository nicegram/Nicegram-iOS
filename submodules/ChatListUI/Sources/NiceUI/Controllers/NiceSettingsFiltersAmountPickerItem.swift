import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramUIPreferences
import TelegramPresentationData
import LegacyComponents
import ItemListUI

//enum AutomaticDownloadDataUsage: Int {
//    case low
//    case medium
//    case high
//    case custom
//    
//    init(preset: MediaAutoDownloadPreset) {
//        switch preset {
//        case .low:
//            self = .low
//        case .medium:
//            self = .medium
//        case .high:
//            self = .high
//        case .custom:
//            self = .custom
//        }
//    }
//}

class NiceSettingsFiltersAmountPickerItem: ListViewItem, ItemListItem {
    let theme: PresentationTheme
    let lang: String
    let value: Int32
    let customPosition: Int?
    let enabled: Bool
    let sectionId: ItemListSectionId
    let updated: (Int32) -> Void
    
    init(theme: PresentationTheme, lang: String, value: Int32, customPosition: Int?, enabled: Bool, sectionId: ItemListSectionId, updated: @escaping (Int32) -> Void) {
        self.theme = theme
        self.lang = lang
        self.value = value
        self.customPosition = customPosition
        self.enabled = enabled
        self.sectionId = sectionId
        self.updated = updated
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = NiceSettingsFiltersAmountPickerItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
            
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply() })
                })
            }
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? NiceSettingsFiltersAmountPickerItemNode {
                let makeLayout = nodeValue.asyncLayout()
                
                async {
                    let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                    Queue.mainQueue().async {
                        completion(layout, { _ in
                            apply()
                        })
                    }
                }
            }
        }
    }
}

private func generateKnobImage() -> UIImage? {
    return generateImage(CGSize(width: 40.0, height: 40.0), rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.setShadow(offset: CGSize(width: 0.0, height: -2.0), blur: 3.5, color: UIColor(white: 0.0, alpha: 0.35).cgColor)
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(x: 6.0, y: 6.0), size: CGSize(width: 28.0, height: 28.0)))
    })
}

class NiceSettingsFiltersAmountPickerItemNode: ListViewItemNode {
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    
    private let TextNode0: TextNode
    private let TextNode1: TextNode
    private let TextNode2: TextNode
    private let TextNode3: TextNode
    private let TextNode4: TextNode
    private let TextNode5: TextNode
    private var sliderView: TGPhotoEditorSliderView?
    
    private var item: NiceSettingsFiltersAmountPickerItem?
    private var layoutParams: ListViewItemLayoutParams?
    
    init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true
        
        self.TextNode0 = TextNode()
        self.TextNode0.isUserInteractionEnabled = false
        self.TextNode0.displaysAsynchronously = false
        
        self.TextNode1 = TextNode()
        self.TextNode1.isUserInteractionEnabled = false
        self.TextNode1.displaysAsynchronously = false
        
        self.TextNode2 = TextNode()
        self.TextNode2.isUserInteractionEnabled = false
        self.TextNode2.displaysAsynchronously = false
        
        self.TextNode3 = TextNode()
        self.TextNode3.isUserInteractionEnabled = false
        self.TextNode3.displaysAsynchronously = false
        
        self.TextNode4 = TextNode()
        self.TextNode4.isUserInteractionEnabled = false
        self.TextNode4.displaysAsynchronously = false
        
        self.TextNode5 = TextNode()
        self.TextNode5.isUserInteractionEnabled = false
        self.TextNode5.displaysAsynchronously = false
        
        super.init(layerBacked: false, dynamicBounce: false)
        
        self.addSubnode(self.TextNode0)
        self.addSubnode(self.TextNode1)
        self.addSubnode(self.TextNode2)
        self.addSubnode(self.TextNode3)
        self.addSubnode(self.TextNode4)
        self.addSubnode(self.TextNode5)
    }
    
    func updateSliderView() {
        if let sliderView = self.sliderView, let item = self.item {
            sliderView.maximumValue = 5.0
            sliderView.positionsCount = 6
            var value = item.value
            
            sliderView.value = CGFloat(value)
            
            sliderView.isUserInteractionEnabled = item.enabled
            sliderView.alpha = item.enabled ? 1.0 : 0.4
            sliderView.layer.allowsGroupOpacity = !item.enabled
        }
    }
    
    override func didLoad() {
        super.didLoad()
        
        let sliderView = TGPhotoEditorSliderView()
        sliderView.enablePanHandling = true
        sliderView.trackCornerRadius = 1.0
        sliderView.lineSize = 2.0
        sliderView.dotSize = 5.0
        sliderView.minimumValue = 0.0
        sliderView.maximumValue = 5.0
        sliderView.startValue = 0.0
        sliderView.disablesInteractiveTransitionGestureRecognizer = true
        sliderView.positionsCount = 6
        sliderView.useLinesForPositions = true
        if let item = self.item, let params = self.layoutParams {
            var value = item.value
            
            sliderView.value = CGFloat(value)
            sliderView.backgroundColor = item.theme.list.itemBlocksBackgroundColor
            sliderView.backColor = item.theme.list.disclosureArrowColor
            sliderView.startColor = item.theme.list.disclosureArrowColor
            sliderView.trackColor = item.theme.list.itemAccentColor
            sliderView.knobImage = generateKnobImage()
            
            sliderView.frame = CGRect(origin: CGPoint(x: params.leftInset + 15.0, y: 37.0), size: CGSize(width: params.width - params.leftInset - params.rightInset - 15.0 * 2.0, height: 44.0))
            sliderView.hitTestEdgeInsets = UIEdgeInsets(top: -sliderView.frame.minX, left: 0.0, bottom: 0.0, right: -sliderView.frame.minX)
        }
        self.view.addSubview(sliderView)
        sliderView.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
        self.sliderView = sliderView
        
        self.updateSliderView()
    }
    
    func asyncLayout() -> (_ item: NiceSettingsFiltersAmountPickerItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let currentItem = self.item
        
        let makeTextLayout0 = TextNode.asyncLayout(self.TextNode0)
        let makeTextLayout1 = TextNode.asyncLayout(self.TextNode1)
        let makeTextLayout2 = TextNode.asyncLayout(self.TextNode2)
        let makeTextLayout3 = TextNode.asyncLayout(self.TextNode3)
        let makeTextLayout4 = TextNode.asyncLayout(self.TextNode4)
        let makeTextLayout5 = TextNode.asyncLayout(self.TextNode5)
        
        return { item, params, neighbors in
            var themeUpdated = false
            if currentItem?.theme !== item.theme {
                themeUpdated = true
            }
            
            let contentSize: CGSize
            let insets: UIEdgeInsets
            let separatorHeight = UIScreenPixel
            
            let (TextLayout0, TextApply0) = makeTextLayout0(TextNodeLayoutArguments(attributedString: NSAttributedString(string: "0", font: Font.regular(13.0), textColor: item.theme.list.itemSecondaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: params.width, height: CGFloat.greatestFiniteMagnitude), alignment: .center, lineSpacing: 0.0, cutout: nil, insets: UIEdgeInsets()))
            
            let (TextLayout1, TextApply1) = makeTextLayout1(TextNodeLayoutArguments(attributedString: NSAttributedString(string: "1", font: Font.regular(13.0), textColor: item.theme.list.itemSecondaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: params.width, height: CGFloat.greatestFiniteMagnitude), alignment: .center, lineSpacing: 0.0, cutout: nil, insets: UIEdgeInsets()))
            
            let (TextLayout2, TextApply2) = makeTextLayout2(TextNodeLayoutArguments(attributedString: NSAttributedString(string: "2", font: Font.regular(13.0), textColor: item.theme.list.itemSecondaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: params.width, height: CGFloat.greatestFiniteMagnitude), alignment: .center, lineSpacing: 0.0, cutout: nil, insets: UIEdgeInsets()))
            
            let (TextLayout3, TextApply3) = makeTextLayout3(TextNodeLayoutArguments(attributedString: NSAttributedString(string: "3", font: Font.regular(13.0), textColor: item.theme.list.itemSecondaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: params.width, height: CGFloat.greatestFiniteMagnitude), alignment: .center, lineSpacing: 0.0, cutout: nil, insets: UIEdgeInsets()))
            
            let (TextLayout4, TextApply4) = makeTextLayout4(TextNodeLayoutArguments(attributedString: NSAttributedString(string: "4", font: Font.regular(13.0), textColor: item.theme.list.itemSecondaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: params.width, height: CGFloat.greatestFiniteMagnitude), alignment: .center, lineSpacing: 0.0, cutout: nil, insets: UIEdgeInsets()))
            
            let (TextLayout5, TextApply5) = makeTextLayout5(TextNodeLayoutArguments(attributedString: NSAttributedString(string: "5", font: Font.regular(13.0), textColor: item.theme.list.itemSecondaryTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: params.width, height: CGFloat.greatestFiniteMagnitude), alignment: .center, lineSpacing: 0.0, cutout: nil, insets: UIEdgeInsets()))
            
            contentSize = CGSize(width: params.width, height: 88.0)
            insets = itemListNeighborsGroupedInsets(neighbors)
            
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size
            
            return (layout, { [weak self] in
                if let strongSelf = self {
                    strongSelf.item = item
                    strongSelf.layoutParams = params
                    
                    strongSelf.backgroundNode.backgroundColor = item.theme.list.itemBlocksBackgroundColor
                    strongSelf.topStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                    strongSelf.bottomStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                    
                    if strongSelf.backgroundNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.backgroundNode, at: 0)
                    }
                    if strongSelf.topStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.topStripeNode, at: 1)
                    }
                    if strongSelf.bottomStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.bottomStripeNode, at: 2)
                    }
                    switch neighbors.top {
                    case .sameSection(false):
                        strongSelf.topStripeNode.isHidden = true
                    default:
                        strongSelf.topStripeNode.isHidden = false
                    }
                    let bottomStripeInset: CGFloat
                    let bottomStripeOffset: CGFloat
                    switch neighbors.bottom {
                    case .sameSection(false):
                        bottomStripeInset = 0.0 //params.leftInset + 16.0
                        bottomStripeOffset = -separatorHeight
                    default:
                        bottomStripeInset = 0.0
                        bottomStripeOffset = 0.0
                    }
                    strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: params.width, height: contentSize.height + min(insets.top, separatorHeight) + min(insets.bottom, separatorHeight)))
                    strongSelf.topStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: layoutSize.width, height: separatorHeight))
                    strongSelf.bottomStripeNode.frame = CGRect(origin: CGPoint(x: bottomStripeInset, y: contentSize.height + bottomStripeOffset), size: CGSize(width: layoutSize.width - bottomStripeInset, height: separatorHeight))
                    
                    let _ = TextApply0()
                    let _ = TextApply1()
                    let _ = TextApply2()
                    let _ = TextApply3()
                    let _ = TextApply4()
                    let _ = TextApply5()
                    
                    var textNodes: [(TextNode, CGSize)] = [(strongSelf.TextNode0, TextLayout0.size),
                                                           (strongSelf.TextNode1, TextLayout1.size),
                                                           (strongSelf.TextNode2, TextLayout2.size),
                    (strongSelf.TextNode3, TextLayout3.size),
                    (strongSelf.TextNode4, TextLayout4.size),
                    (strongSelf.TextNode5, TextLayout5.size)]

                    
                    let delta = (params.width - params.leftInset - params.rightInset - 18.0 * 2.0) / CGFloat(textNodes.count - 1)
                    for i in 0 ..< textNodes.count {
                        let (textNode, textSize) = textNodes[i]
                        
                        var position = params.leftInset + 18.0 + delta * CGFloat(i)
                        if i == textNodes.count - 1 {
                            position -= textSize.width
                        } else if i > 0 {
                            position -= textSize.width / 2.0
                        }
                        
                        textNode.frame = CGRect(origin: CGPoint(x: position, y: 15.0), size: textSize)
                    }
                    
                    if let sliderView = strongSelf.sliderView {
                        if themeUpdated {
                            sliderView.backgroundColor = item.theme.list.itemBlocksBackgroundColor
                            sliderView.backColor = item.theme.list.disclosureArrowColor
                            sliderView.trackColor = item.theme.list.itemAccentColor
                            sliderView.knobImage = generateKnobImage()
                        }
                        
                        sliderView.frame = CGRect(origin: CGPoint(x: params.leftInset + 15.0, y: 37.0), size: CGSize(width: params.width - params.leftInset - params.rightInset - 15.0 * 2.0, height: 44.0))
                        sliderView.hitTestEdgeInsets = UIEdgeInsets(top: -sliderView.frame.minX, left: 0.0, bottom: 0.0, right: -sliderView.frame.minX)
                        
                        strongSelf.updateSliderView()
                    }
                }
            })
        }
    }
    
    override func animateInsertion(_ currentTimestamp: Double, duration: Double, short: Bool) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
    
    @objc func sliderValueChanged() {
        guard let sliderView = self.sliderView else {
            return
        }
        
        let position = Int(sliderView.value)
        var value: Int32?
        
    
        value = Int32(position)
        
        
        if let value = value {
            self.item?.updated(value)
        }
    }
}

