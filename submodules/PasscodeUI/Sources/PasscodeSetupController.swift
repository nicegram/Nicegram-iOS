import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import AccountContext

public enum PasscodeSetupControllerMode {
    case setup(change: Bool, PasscodeEntryFieldType)
    case entry(PostboxAccessChallengeData)
}

public final class PasscodeSetupController: ViewController {
    private var controllerNode: PasscodeSetupControllerNode {
        return self.displayNode as! PasscodeSetupControllerNode
    }
    // Nicegram DB Changes
    private let context: SharedAccountContext
    private var mode: PasscodeSetupControllerMode
    
    public var complete: ((String, Bool) -> Void)?
    public var check: ((String) -> Bool)?
    // Nicegram DB Changes
    public var checkSetupPasscode: ((String) -> Bool)?
    
    private let hapticFeedback = HapticFeedback()
    
    private var presentationData: PresentationData
    // Nicegram DB Changes
    private let isChangeModeAllowed: Bool
    
    private var nextAction: UIBarButtonItem?
    
    // Nicegram DB Changes
    public init(context: SharedAccountContext, mode: PasscodeSetupControllerMode, isChangeModeAllowed: Bool = true, isOpaqueNavigationBar: Bool = false) {
        self.context = context
        self.mode = mode
        self.isChangeModeAllowed = isChangeModeAllowed
        self.presentationData = context.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData, hideBackground: isOpaqueNavigationBar, hideBadge: false))
        
        self.supportedOrientations = ViewControllerSupportedOrientations(regularSize: .all, compactSize: .portrait)
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        self.nextAction = UIBarButtonItem(title: self.presentationData.strings.Common_Next, style: .done, target: self, action: #selector(self.nextPressed))
        
        self.title = self.presentationData.strings.PasscodeSettings_Title
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadDisplayNode() {
        // Nicegram DB Changes
        self.displayNode = PasscodeSetupControllerNode(presentationData: self.presentationData, mode: self.mode, isChangeModeAllowed: isChangeModeAllowed)
        self.displayNodeDidLoad()
        
        self.navigationBar?.updateBackgroundAlpha(0.0, transition: .immediate)
        
        self.controllerNode.selectPasscodeMode = { [weak self] in
            guard let strongSelf = self, case let .setup(change, type) = strongSelf.mode else {
                return
            }
            
            let controller = ActionSheetController(presentationData: strongSelf.presentationData)
            let dismissAction: () -> Void = { [weak controller] in
                self?.controllerNode.activateInput()
                controller?.dismissAnimated()
            }
            
            var items: [ActionSheetButtonItem] = []
            if case .digits6 = type {
            } else {
                items.append(ActionSheetButtonItem(title: strongSelf.presentationData.strings.PasscodeSettings_6DigitCode, action: { [weak self] in
                    if let strongSelf = self {
                        strongSelf.mode = .setup(change: change, .digits6)
                        strongSelf.controllerNode.updateMode(strongSelf.mode)
                    }
                    dismissAction()
                }))
            }
            if case .digits4 = type {
            } else {
                items.append(ActionSheetButtonItem(title: strongSelf.presentationData.strings.PasscodeSettings_4DigitCode, action: {
                    if let strongSelf = self {
                        strongSelf.mode = .setup(change: change, .digits4)
                        strongSelf.controllerNode.updateMode(strongSelf.mode)
                    }
                    dismissAction()
                }))
            }
            if case .alphanumeric = type {
            } else {
                items.append(ActionSheetButtonItem(title: strongSelf.presentationData.strings.PasscodeSettings_AlphanumericCode, action: {
                    if let strongSelf = self {
                        strongSelf.mode = .setup(change: change, .alphanumeric)
                        strongSelf.controllerNode.updateMode(strongSelf.mode)
                    }
                    dismissAction()
                }))
            }
            controller.setItemGroups([
                ActionSheetItemGroup(items: items),
                ActionSheetItemGroup(items: [ActionSheetButtonItem(title: strongSelf.presentationData.strings.Common_Cancel, action: { dismissAction() })])
            ])
            controller.dismissed = { _ in
                self?.controllerNode.activateInput()
            }
            strongSelf.view.endEditing(true)
            strongSelf.present(controller, in: .window(.root))
        }
        self.controllerNode.updateNextAction = { [weak self] visible in
            guard let strongSelf = self else {
                return
            }
            
            if visible {
                strongSelf.navigationItem.rightBarButtonItem = strongSelf.nextAction
            } else {
                strongSelf.navigationItem.rightBarButtonItem = nil
            }
        }
        self.controllerNode.complete = { [weak self] passcode, numerical in
            if let strongSelf = self {
                strongSelf.complete?(passcode, numerical)
            }
        }
        self.controllerNode.checkPasscode = { [weak self] passcode in
            return self?.check?(passcode) ?? false
        }
        // Nicegram DB Changes
        self.controllerNode.checkSetupPasscode = { [weak self] passcode in
            return self?.checkSetupPasscode?(passcode) ?? true
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.controllerNode.activateInput()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.disablesInteractiveTransitionGestureRecognizer = true
        
        self.controllerNode.activateInput()
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationLayout(layout: layout).navigationFrame.maxY, transition: transition)
    }
    
    @objc private func nextPressed() {
       self.controllerNode.activateNext()
    }
}
