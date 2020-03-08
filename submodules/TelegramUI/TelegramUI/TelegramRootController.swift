import Foundation
import UIKit
import Display
import Postbox
import TelegramCore
import SyncCore
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import ContactListUI
import CallListUI
import ChatListUI
import SettingsUI
import NicegramLib
import AlertUI
import AvatarNode
import AppBundle
import TelegramUIPreferences
import NicegramUI

public final class TelegramRootController: NavigationController {
    private let context: AccountContext
    
    public var rootTabController: TabBarController?
    
    public var contactsController: ContactsController?
    public var callListController: CallListController?
    public var chatListController: ChatListController?
    public var accountSettingsController: ViewController?
    
    public var filterControllers: [ChatListController]?
    public var topChatsController: ViewController?
    
    private var permissionsDisposable: Disposable?
    private var presentationDataDisposable: Disposable?
    private var presentationData: PresentationData
    
    public init(context: AccountContext) {
        self.context = context
        
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        let navigationDetailsBackgroundMode: NavigationEmptyDetailsBackgoundMode?
        switch presentationData.chatWallpaper {
        case .color:
            let image = generateTintedImage(image: UIImage(bundleImageName: "Chat List/EmptyMasterDetailIcon"), color: presentationData.theme.chatList.messageTextColor.withAlphaComponent(0.2))
            navigationDetailsBackgroundMode = image != nil ? .image(image!) : nil
        default:
            let image = chatControllerBackgroundImage(theme: presentationData.theme, wallpaper: presentationData.chatWallpaper, mediaBox: context.account.postbox.mediaBox, knockoutMode: context.sharedContext.immediateExperimentalUISettings.knockoutWallpaper)
            navigationDetailsBackgroundMode = image != nil ? .wallpaper(image!) : nil
        }
        
        super.init(mode: .automaticMasterDetail, theme: NavigationControllerTheme(presentationTheme: self.presentationData.theme), backgroundDetailsMode: navigationDetailsBackgroundMode)
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
            |> deliverOnMainQueue).start(next: { [weak self] presentationData in
                if let strongSelf = self {
                    if presentationData.chatWallpaper != strongSelf.presentationData.chatWallpaper {
                        let navigationDetailsBackgroundMode: NavigationEmptyDetailsBackgoundMode?
                        switch presentationData.chatWallpaper {
                        case .color:
                            let image = generateTintedImage(image: UIImage(bundleImageName: "Chat List/EmptyMasterDetailIcon"), color: presentationData.theme.chatList.messageTextColor.withAlphaComponent(0.2))
                            navigationDetailsBackgroundMode = image != nil ? .image(image!) : nil
                        default:
                            navigationDetailsBackgroundMode = chatControllerBackgroundImage(theme: presentationData.theme, wallpaper: presentationData.chatWallpaper, mediaBox: strongSelf.context.sharedContext.accountManager.mediaBox, knockoutMode: strongSelf.context.sharedContext.immediateExperimentalUISettings.knockoutWallpaper).flatMap(NavigationEmptyDetailsBackgoundMode.wallpaper)
                        }
                        strongSelf.updateBackgroundDetailsMode(navigationDetailsBackgroundMode, transition: .immediate)
                    }
                    strongSelf.updateBackgroundDetailsMode(navigationDetailsBackgroundMode, transition: .immediate)
                    let previousTheme = strongSelf.presentationData.theme
                    strongSelf.presentationData = presentationData
                    if previousTheme !== presentationData.theme {
                        strongSelf.rootTabController?.updateTheme(navigationBarPresentationData: NavigationBarPresentationData(presentationData: presentationData), theme: TabBarControllerTheme(rootControllerTheme: presentationData.theme))
                        strongSelf.rootTabController?.statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style
                    }
                }
            })
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.permissionsDisposable?.dispose()
        self.presentationDataDisposable?.dispose()
    }
    
    public func addRootControllers(showCallsTab: Bool, niceSettings: NiceSettings) {
        let tabBarController = TabBarController(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData), theme: TabBarControllerTheme(rootControllerTheme: self.presentationData.theme), showTabNames: VarSimplyNiceSettings.showTabNames)
        tabBarController.navigationPresentation = .master
        let chatListController = self.context.sharedContext.makeChatListController(context: self.context, groupId: .root, filter: nil, controlsHistoryPreload: true, hideNetworkActivityStatus: false, ngfilter: nil, filterIndex: nil, isMissed: false, previewing: false, enableDebugActions: !GlobalExperimentalSettings.isAppStoreBuild)
        if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
            chatListController.tabBarItem.badgeValue = sharedContext.switchingData.chatListBadge
        }
        let callListController = CallListController(context: self.context, mode: .tab)
        
        var controllers: [ViewController] = []
        
        let contactsController = ContactsController(context: self.context)
        contactsController.switchToChatsController = {  [weak self] in
            self?.openChatsController(activateSearch: false)
        }
        // let niceSettings = getNiceSettings(accountManager: self.context.sharedContext.accountManager)
        if niceSettings.showContactsTab {
            controllers.append(contactsController)
        }
        if showCallsTab {
            controllers.append(callListController)
        }
        if VarSimplyNiceSettings.maxFilters > 0 {
            var filControllers: [ChatListController] = []
            for (index, filter) in VarSimplyNiceSettings.chatFilters.enumerated() {
                // Break if max filters
                if index + 1 > VarSimplyNiceSettings.maxFilters {
                    break
                }
                filControllers.append(self.context.sharedContext.makeChatListController(context: self.context, groupId: .root, filter: nil, controlsHistoryPreload: true, hideNetworkActivityStatus: false, ngfilter: filter, filterIndex: Int32(index), isMissed: false, previewing: false, enableDebugActions: !GlobalExperimentalSettings.isAppStoreBuild))
            }
            
            if !filControllers.isEmpty {
                for controller in filControllers {
                    if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
                        controller.tabBarItem.badgeValue = sharedContext.switchingData.chatListBadge
                    }
                    controllers.append(controller)
                }
                self.filterControllers = filControllers
            } else {
                self.filterControllers = nil
            }
        }

        controllers.append(chatListController)
        
        var restoreSettignsController: (ViewController & SettingsController)?
        if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
            restoreSettignsController = sharedContext.switchingData.settingsController
        }
        restoreSettignsController?.updateContext(context: self.context)
        if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
            sharedContext.switchingData = (nil, nil, nil)
        }
        
        let accountSettingsController = restoreSettignsController ?? settingsController(context: self.context, accountManager: context.sharedContext.accountManager, enableDebugActions: !GlobalExperimentalSettings.isAppStoreBuild)
        controllers.append(accountSettingsController)
        
        
//        var hasUnreads = false
//
//        let semaphore = DispatchSemaphore(value: 0)
//        let signal = renderedTotalUnreadCount(accountManager: self.context.sharedContext.accountManager, postbox: self.context.account.postbox)
//        signal.start(next: { count in
//            if count.0 != 0 {
//                hasUnreads = true
//            }
//            print("unread count \(count.0)")
//            semaphore.signal()
//        })
//
//        semaphore.wait()
        
        if showMissed() /*&& hasUnreads*/ {
            var missedControllerIndex: Int? = nil
            for (index, testController) in controllers.enumerated() {
                if let strongController = testController as? ChatListController {
                    if strongController.ngfilter == .onlyMissed {
                        missedControllerIndex = index
                    }
                }
            }
            if let hasMissedControllerIndex = missedControllerIndex {
                // Use existing tab
            } else {
                let missedController = self.context.sharedContext.makeChatListController(context: self.context, groupId: .root, filter: nil, controlsHistoryPreload: true, hideNetworkActivityStatus: false, ngfilter: .onlyMissed, filterIndex: nil, isMissed: true, previewing: false, enableDebugActions: !GlobalExperimentalSettings.isAppStoreBuild)
                
                if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
                    missedController.tabBarItem.badgeValue = sharedContext.switchingData.chatListBadge
                }
                
                controllers.insert(missedController, at: 0)
            }
        }
        
        #if CN
        let topChatsController = TopChatsViewController(context: self.context)
        
        
        controllers.insert(topChatsController, at: 0)
        self.topChatsController = topChatsController
        #endif
        
        tabBarController.setControllers(controllers, selectedIndex: restoreSettignsController != nil ? (controllers.count - 1) : (controllers.count - 2))
        
        self.contactsController = contactsController
        self.callListController = callListController
        self.chatListController = chatListController
        self.accountSettingsController = accountSettingsController
        self.rootTabController = tabBarController
        self.pushViewController(tabBarController, animated: false)
        
//        let _ = (archivedStickerPacks(account: self.context.account, namespace: .stickers)
//        |> deliverOnMainQueue).start(next: { [weak self] stickerPacks in
//            var packs: [(StickerPackCollectionInfo, StickerPackItem?)] = []
//            for pack in stickerPacks {
//                packs.append((pack.info, pack.topItems.first))
//            }
//
//            if let strongSelf = self {
//                let controller = archivedStickersNoticeController(context: strongSelf.context, archivedStickerPacks: packs)
//                strongSelf.chatListController?.present(controller, in: .window(.root))
//            }
//        })
    }
    
    public func updateRootControllers(showCallsTab: Bool, niceSettings: NiceSettings) {
        guard let rootTabController = self.rootTabController else {
            return
        }
        var controllers: [ViewController] = []
        // let niceSettings = getNiceSettings(accountManager: self.context.sharedContext.accountManager)
        if niceSettings.showContactsTab {
            controllers.append(self.contactsController!)
        }
        
        if showCallsTab {
            controllers.append(self.callListController!)
        }
        
        var selectedIndex: Int? = nil
        
        if VarSimplyNiceSettings.maxFilters > 0 {
            var filControllers: [ChatListController] = []
            for (index, filter) in VarSimplyNiceSettings.chatFilters.enumerated() {
                // Break if max filters
                if index + 1 > VarSimplyNiceSettings.maxFilters {
                    break
                }
                filControllers.append(self.context.sharedContext.makeChatListController(context: self.context, groupId: .root, filter: nil, controlsHistoryPreload: true, hideNetworkActivityStatus: false, ngfilter: filter, filterIndex: Int32(index), isMissed: false, previewing: false, enableDebugActions: !GlobalExperimentalSettings.isAppStoreBuild))
            }
            
            if !filControllers.isEmpty {
                for controller in filControllers {
                    if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
                        controller.tabBarItem.badgeValue = sharedContext.switchingData.chatListBadge
                    }
                    controllers.append(controller)
                }
                self.filterControllers = filControllers
            } else {
                self.filterControllers = nil
            }
        }
        
        
        controllers.append(self.chatListController!)
        controllers.append(self.accountSettingsController!)
        
//        var hasUnreads = false
//
//        let semaphore = DispatchSemaphore(value: 0)
//        let signal = renderedTotalUnreadCount(accountManager: self.context.sharedContext.accountManager, postbox: self.context.account.postbox)
//        signal.start(next: { count in
//            if count.0 != 0 {
//                hasUnreads = true
//            }
//            print("unread count \(count.0)")
//            semaphore.signal()
//        })
//
//        semaphore.wait()
        
        if showMissed() /*&& hasUnreads*/ {
            for (index, testController) in controllers.enumerated() {
                if let strongController = testController as? ChatListController {
                    if strongController.ngfilter == .onlyMissed {
                        selectedIndex = index
                        break
                    }
                }
            }
            if let hasMissedControllerIndex = selectedIndex {
                // Use existing tab
            } else {
                selectedIndex = 0
                let missedController = self.context.sharedContext.makeChatListController(context: self.context, groupId: .root, filter: nil, controlsHistoryPreload: true, hideNetworkActivityStatus: false, ngfilter: .onlyMissed, filterIndex: nil, isMissed: true, previewing: false, enableDebugActions: !GlobalExperimentalSettings.isAppStoreBuild)
                
                if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
                    missedController.tabBarItem.badgeValue = sharedContext.switchingData.chatListBadge
                }
                
                controllers.insert(missedController, at: 0)
            }
        }
        
        // Updating start data
        let oldOpened = VarPremiumSettings.lastOpened
        VarPremiumSettings.lastOpened = utcnow()
        premiumLog("LAST OPENED \(VarPremiumSettings.lastOpened) | DIFF \(VarPremiumSettings.lastOpened - oldOpened) s")
        
        #if CN
        controllers.insert(self.topChatsController!, at: 0)
        #endif
        rootTabController.setControllers(controllers, selectedIndex: selectedIndex)
        
//        let observer = NotificationCenter.default.addObserver(forName: .IAPHelperPurchaseNotification, object: nil, queue: .main, using: { notification in
//            let productID = notification.object as? String
//            if productID == NicegramProducts.Premium {
//                VarPremiumSettings.p = true
//                validatePremium(isPremium())
//                print("TRIGGERED MAIN OBSERVERS")
//                if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
//                    let presentationData = sharedContext.currentPresentationData.with { $0 }
//                    if (isPremium()) {
//                        let c = getPremiumActivatedAlert(context: self.context, "IAP.Common.Congrats", "IAP.Premium.Activated", presentationData, action: {
//                        })
//                        rootTabController.present(c, in: .window(.root))
//                    } else {
//                        let alertController = textAlertController(context: self.context, title: nil, text: l("IAP.Common.ValidateError", presentationData.strings.baseLanguageCode), actions: [
//                            TextAlertAction(type: .genericAction, title: presentationData.strings.Common_OK, action: {
//                            })])
//                        rootTabController.present(alertController, in: .window(.root))
//                    }
//
//                }
//
//            }
//        })
    }
    
    public func openChatsController(activateSearch: Bool) {
        guard let rootTabController = self.rootTabController else {
            return
        }
        
        if activateSearch {
            self.popToRoot(animated: false)
        }
        
        if let index = rootTabController.controllers.firstIndex(where: { $0 is ChatListController}) {
            rootTabController.selectedIndex = index
        }
        
        if activateSearch {
            self.chatListController?.activateSearch()
        }
    }
    
    public func openRootCompose() {
        self.chatListController?.activateCompose()
    }
    
    public func openRootCamera() {
        guard let controller = self.viewControllers.last as? ViewController else {
            return
        }
        controller.view.endEditing(true)
        presentedLegacyShortcutCamera(context: self.context, saveCapturedMedia: false, saveEditedPhotos: false, mediaGrouping: true, parentController: controller)
    }
}
