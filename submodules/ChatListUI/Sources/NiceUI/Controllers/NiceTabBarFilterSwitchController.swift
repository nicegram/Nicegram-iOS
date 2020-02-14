//
//  NiceTabFilterSwitchController.swift
//  TelegramUI
//
//  Created by Sergey Ak on 5/16/19.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import ItemListUI

public final class TabBarFilterSwitchController: ViewController {
    private var controllerNode: TabBarFilterSwitchControllerNode {
        return self.displayNode as! TabBarFilterSwitchControllerNode
    }
    
    private let _ready = Promise<Bool>(true)
    override public var ready: Promise<Bool> {
        return self._ready
    }
    
    private let sharedContext: SharedAccountContext
    private let switchToNGFilter: (NiceChatListNodePeersFilter) -> Void
    private let sourceNodes: [ASDisplayNode]
    
    private var presentationData: PresentationData
    private var animatedAppearance = false
    private var changedFilter = false
    
    private let hapticFeedback = HapticFeedback()
    
    private let current: NiceChatListNodePeersFilter?
    private let available: [NiceChatListNodePeersFilter]
    
    public init(sharedContext: SharedAccountContext, current: NiceChatListNodePeersFilter?, available: [NiceChatListNodePeersFilter], switchToNGFilter: @escaping (NiceChatListNodePeersFilter) -> Void, sourceNodes: [ASDisplayNode]) {
        self.sharedContext = sharedContext
        self.switchToNGFilter = switchToNGFilter
        self.sourceNodes = sourceNodes
        
        self.current = current
        self.available = available
        
        self.presentationData = sharedContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: nil)
        
        self.statusBar.statusBarStyle = .Hide
        self.statusBar.ignoreInCall = true
        
        self.lockOrientation = true
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
    }
    
    override public func loadDisplayNode() {
        self.displayNode = TabBarFilterSwitchControllerNode(sharedContext: self.sharedContext, presentationData: self.presentationData, current: current, available: available, switchToNGFilter: { [weak self] f in
            guard let strongSelf = self, !strongSelf.changedFilter else {
                return
            }
            strongSelf.changedFilter = true
            strongSelf.switchToNGFilter(f)
            }, cancel: { [weak self] in
                self?.dismiss()
            }, sourceNodes: self.sourceNodes)
        self.displayNodeDidLoad()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.animatedAppearance {
            self.animatedAppearance = true
            
            self.hapticFeedback.impact()
            self.controllerNode.animateIn()
        }
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, transition: transition)
    }
    
    override public func dismiss(completion: (() -> Void)? = nil) {
        self.changedFilter = false
        self.dismiss(sourceNodes: [])
    }
    
    public func dismiss(sourceNodes: [ASDisplayNode]) {
        self.controllerNode.animateOut(sourceNodes: sourceNodes, changedFilter: self.changedFilter, completion: { [weak self] in
            self?.animatedAppearance = false
            self?.presentingViewController?.dismiss(animated: false, completion: nil)
        })
    }
}
