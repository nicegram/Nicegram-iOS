import Foundation
import UIKit
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit
import LegacyComponents
import TelegramPresentationData
import TelegramUIPreferences
import OverlayStatusController
import AccountContext
import ShareController
import SearchUI
import HexColor
import PresentationDataUtils
import MediaPickerUI
import WallpaperGalleryScreen
import Photos

public enum WallpaperSelectionResult {
    case remove
    case emoticon(String)
    case custom(wallpaperEntry: WallpaperGalleryEntry, options: WallpaperPresentationOptions, editedImage: UIImage?, cropRect: CGRect?, brightness: CGFloat?)
}

public final class ThemeGridController: ViewController {
    public enum Mode {
        case generic
        case peer(EnginePeer, [TelegramTheme], TelegramWallpaper?, Int?, Int?)
    }
    private var controllerNode: ThemeGridControllerNode {
        return self.displayNode as! ThemeGridControllerNode
    }
    
    private let _ready = Promise<Bool>()
    public override var ready: Promise<Bool> {
        return self._ready
    }
    
    private let context: AccountContext
    private let mode: Mode
    
    private var presentationData: PresentationData
    private let presentationDataPromise = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    
    private var searchContentNode: NavigationBarSearchContentNode?
    
    private var isEmpty: Bool?
    private var editingMode: Bool = false
    
    private var validLayout: ContainerViewLayout?
    
    public override var navigationBarRequiresEntireLayoutUpdate: Bool {
        return false
    }
    
    private var previousContentOffset: GridNodeVisibleContentOffset?
    
    public var completion: (WallpaperSelectionResult) -> Void = { _ in }
    
    public init(context: AccountContext, mode: Mode = .generic) {
        self.context = context
        self.mode = mode
        
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.presentationDataPromise.set(.single(self.presentationData))
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        switch mode {
        case .generic:
            self.title = self.presentationData.strings.Wallpaper_Title
        case .peer:
            self.title = self.presentationData.strings.Wallpaper_ChannelTitle
        }
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        self.scrollToTop = { [weak self] in
            if let strongSelf = self {
                if let searchContentNode = strongSelf.searchContentNode {
                    searchContentNode.updateExpansionProgress(1.0, animated: true)
                }
                strongSelf.controllerNode.scrollToTop()
            }
        }
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            if let strongSelf = self {
                let previousTheme = strongSelf.presentationData.theme
                let previousStrings = strongSelf.presentationData.strings
                
                strongSelf.presentationData = presentationData
                strongSelf.presentationDataPromise.set(.single(presentationData))
                
                if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                    strongSelf.updateThemeAndStrings()
                }
            }
        })
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    private func updateThemeAndStrings() {
        self.title = self.presentationData.strings.Wallpaper_Title
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        
        if case .generic = self.mode {
            if let isEmpty = self.isEmpty, isEmpty {
            } else {
                if self.editingMode {
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Done, style: .done, target: self, action: #selector(self.donePressed))
                } else {
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Edit, style: .plain, target: self, action: #selector(self.editPressed))
                }
            }
        }
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData))
        self.searchContentNode?.updateThemeAndPlaceholder(theme: self.presentationData.theme, placeholder: self.presentationData.strings.Wallpaper_Search)
        
        if self.isNodeLoaded {
            self.controllerNode.updatePresentationData(self.presentationData)
        }
    }
    
    public override func loadDisplayNode() {
        var mode: WallpaperGalleryController.Mode = .default
        var requiredLevel: Int?
        var requiredCustomLevel: Int?
        if case let .peer(peer, _, _, requiredLevelValue, requiredCustomLevelValue) = self.mode {
            mode = .peer(peer, false)
            requiredLevel = requiredLevelValue
            requiredCustomLevel = requiredCustomLevelValue
        }
        
        self.displayNode = ThemeGridControllerNode(context: self.context, mode: self.mode, presentationData: self.presentationData, presentPreviewController: { [weak self] source in
            if let strongSelf = self {
                let dismissControllers = { [weak self] in
                    if let self, let navigationController = self.navigationController as? NavigationController {
                        var controllers = navigationController.viewControllers.filter({ controller in
                            if controller is ThemeGridController {
                                return false
                            }
                            return true
                        })
                        navigationController.setViewControllers(controllers, animated: false)
                        
                        controllers = navigationController.viewControllers.filter({ controller in
                            if controller is WallpaperGalleryController {
                                return false
                            }
                            return true
                        })
                        navigationController.setViewControllers(controllers, animated: true)
                    }
                }
                
                let controller = WallpaperGalleryController(context: strongSelf.context, source: source, mode: mode)
                controller.requiredLevel = requiredLevel
                controller.apply = { [weak self, weak controller] wallpaper, options, editedImage, cropRect, brightness, _ in
                    if let strongSelf = self {
                        if case .peer = mode {
                            var emoticon = ""
                            if case let .wallpaper(wallpaper, _) = wallpaper {
                                emoticon = wallpaper.settings?.emoticon ?? ""
                            }
                            strongSelf.completion(.emoticon(emoticon))
                            dismissControllers()
                        } else {
                            uploadCustomWallpaper(context: strongSelf.context, wallpaper: wallpaper, mode: options, editedImage: editedImage, cropRect: cropRect, brightness: brightness, completion: { [weak self, weak controller] in
                                if let strongSelf = self {
                                    strongSelf.deactivateSearch(animated: false)
                                    strongSelf.controllerNode.scrollToTop(animated: false)
                                }
                                if let controller = controller {
                                    switch wallpaper {
                                    case .asset, .contextResult:
                                        controller.dismiss(animated: true)
                                    default:
                                        break
                                    }
                                }
                            })
                        }
                    }
                }
                self?.push(controller)
            }
        }, presentGallery: { [weak self] in
            if let strongSelf = self {
                let dismissControllers = { [weak self] in
                    if let self, let navigationController = self.navigationController as? NavigationController {
                        if case .peer = mode {
                            var controllers = navigationController.viewControllers.filter({ controller in
                                if controller is ThemeGridController || controller is MediaPickerScreen {
                                    return false
                                }
                                return true
                            })
                            navigationController.setViewControllers(controllers, animated: false)
                            
                            controllers = navigationController.viewControllers.filter({ controller in
                                if controller is WallpaperGalleryController {
                                    return false
                                }
                                return true
                            })
                            navigationController.setViewControllers(controllers, animated: true)
                        } else {
                            let controllers = navigationController.viewControllers.filter({ controller in
                                if controller is WallpaperGalleryController || controller is MediaPickerScreen {
                                    return false
                                }
                                
                                return true
                            })
                            navigationController.setViewControllers(controllers, animated: true)
                        }
                    }
                }
                
                let controller = MediaPickerScreenImpl(context: strongSelf.context, peer: nil, threadTitle: nil, chatLocation: nil, bannedSendPhotos: nil, bannedSendVideos: nil, subject: .assets(nil, .wallpaper))
                controller.customSelection = { [weak self] _, asset in
                    guard let strongSelf = self, let asset = asset as? PHAsset else {
                        return
                    }
                    let controller = WallpaperGalleryController(context: strongSelf.context, source: .asset(asset), mode: mode)
                    controller.requiredLevel = requiredCustomLevel
                    controller.apply = { [weak self] wallpaper, options, editedImage, cropRect, brightness, _ in
                        if let strongSelf = self {
                            if case .peer = mode {
                                strongSelf.completion(.custom(wallpaperEntry: wallpaper, options: options, editedImage: editedImage, cropRect: cropRect, brightness: brightness))
                                Queue.mainQueue().after(0.15) {
                                    dismissControllers()
                                }
                            } else {
                                uploadCustomWallpaper(context: strongSelf.context, wallpaper: wallpaper, mode: options, editedImage: editedImage, cropRect: cropRect, brightness: brightness, completion: {
                                    dismissControllers()
                                })
                            }
                        }
                    }
                    strongSelf.push(controller)
                }
                self?.push(controller)
            }
        }, presentColors: { [weak self] in
            if let strongSelf = self {
                let controller = ThemeColorsGridController(context: strongSelf.context)
                (strongSelf.navigationController as? NavigationController)?.pushViewController(controller)
            }
        }, emptyStateUpdated: { [weak self] empty in
            if let strongSelf = self {
                if empty != strongSelf.isEmpty {
                    strongSelf.isEmpty = empty
                    
                    if case .generic = strongSelf.mode {
                        if empty {
                            strongSelf.navigationItem.setRightBarButton(nil, animated: true)
                        } else {
                            if strongSelf.editingMode {
                                strongSelf.navigationItem.rightBarButtonItem = UIBarButtonItem(title: strongSelf.presentationData.strings.Common_Done, style: .done, target: strongSelf, action: #selector(strongSelf.donePressed))
                            } else {
                                strongSelf.navigationItem.rightBarButtonItem = UIBarButtonItem(title: strongSelf.presentationData.strings.Common_Edit, style: .plain, target: strongSelf, action: #selector(strongSelf.editPressed))
                            }
                        }
                    }
                }
            }
        }, deleteWallpapers: { [weak self] wallpapers, completed in
            if let strongSelf = self {
                let actionSheet = ActionSheetController(presentationData: strongSelf.presentationData)
                var items: [ActionSheetItem] = []
                items.append(ActionSheetButtonItem(title: strongSelf.presentationData.strings.Wallpaper_DeleteConfirmation(Int32(wallpapers.count)), color: .destructive, action: { [weak self, weak actionSheet] in
   
                    actionSheet?.dismissAnimated()
                    completed()
                    
                    guard let strongSelf = self else {
                        return
                    }
                    for wallpaper in wallpapers {
                        if wallpaper == strongSelf.presentationData.chatWallpaper {
                            let presentationData = strongSelf.presentationData
                            let _ = (updatePresentationThemeSettingsInteractively(accountManager: strongSelf.context.sharedContext.accountManager, { current in
                                var themeSpecificChatWallpapers = current.themeSpecificChatWallpapers
                                let themeReference: PresentationThemeReference
                                if presentationData.autoNightModeTriggered {
                                    themeReference = current.automaticThemeSwitchSetting.theme
                                } else {
                                    themeReference = current.theme
                                }
                                themeSpecificChatWallpapers[themeReference.index] = nil
                                themeSpecificChatWallpapers[coloredThemeIndex(reference: themeReference, accentColor: current.themeSpecificAccentColors[themeReference.index])] = nil
                                return current.withUpdatedThemeSpecificChatWallpapers(themeSpecificChatWallpapers)
                            })).start()
                            break
                        }
                    }
                    
                    var deleteWallpapers: [Signal<Void, NoError>] = []
                    for wallpaper in wallpapers {
                        deleteWallpapers.append(deleteWallpaper(account: strongSelf.context.account, wallpaper: wallpaper))
                    }
                    
                    let _ = (combineLatest(deleteWallpapers)
                    |> deliverOnMainQueue).start(completed: { [weak self] in
                        if let strongSelf = self {
                            strongSelf.controllerNode.updateWallpapers()
                        }
                    })
                    
                    strongSelf.donePressed()
                }))
                
                actionSheet.setItemGroups([
                    ActionSheetItemGroup(items: items),
                    ActionSheetItemGroup(items: [
                        ActionSheetButtonItem(title: strongSelf.presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                            actionSheet?.dismissAnimated()
                        })
                    ])
                ])
                strongSelf.present(actionSheet, in: .window(.root))
            }
        }, shareWallpapers: { [weak self] wallpapers in
            if let strongSelf = self {
                strongSelf.shareWallpapers(wallpapers)
            }
        }, resetWallpapers: { [weak self] in
            if let strongSelf = self {
                let actionSheet = ActionSheetController(presentationData: strongSelf.presentationData)
                let items: [ActionSheetItem] = [
                    ActionSheetButtonItem(title: strongSelf.presentationData.strings.Wallpaper_ResetWallpapersConfirmation, color: .destructive, action: { [weak self, weak actionSheet] in
                        actionSheet?.dismissAnimated()
                        
                        if let strongSelf = self {
                            strongSelf.scrollToTop?()
                            
                            let controller = OverlayStatusController(theme: strongSelf.presentationData.theme, type: .loading(cancelled: nil))
                            strongSelf.present(controller, in: .window(.root))
                            
                            let _ = resetWallpapers(account: strongSelf.context.account).start(completed: { [weak self, weak controller] in
                                let _ = updatePresentationThemeSettingsInteractively(accountManager: strongSelf.context.sharedContext.accountManager, { current in
                                    return current.withUpdatedThemeSpecificChatWallpapers([:])
                                }).start()

                                let _ = (strongSelf.context.sharedContext.accountManager.transaction { transaction in
                                    WallpapersState.update(transaction: transaction, { state in
                                        var state = state
                                        state.wallpapers.removeAll()
                                        return state
                                    })
                                }).start()
                                
                                let _ = (telegramWallpapers(postbox: strongSelf.context.account.postbox, network: strongSelf.context.account.network)
                                |> deliverOnMainQueue).start(completed: { [weak self, weak controller] in
                                    controller?.dismiss()
                                    if let strongSelf = self {
                                        strongSelf.controllerNode.updateWallpapers()
                                    }
                                })
                            })
                        }
                    })
                ]
                actionSheet.setItemGroups([ActionSheetItemGroup(items: items),
                    ActionSheetItemGroup(items: [
                        ActionSheetButtonItem(title: strongSelf.presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                            actionSheet?.dismissAnimated()
                        })
                    ])
                ])
                strongSelf.present(actionSheet, in: .window(.root))
            }
        }, popViewController: { [weak self] in
            if let strongSelf = self {
                let _ = (strongSelf.navigationController as? NavigationController)?.popViewController(animated: true)
            }
        })
        self.controllerNode.navigationBar = self.navigationBar
        self.controllerNode.requestDeactivateSearch = { [weak self] in
            self?.deactivateSearch(animated: true)
        }
        self.controllerNode.requestWallpaperRemoval = { [weak self] in
            if let self {
                self.completion(.remove)
                self.dismiss()
            }
        }
        self.controllerNode.gridNode.visibleContentOffsetChanged = { [weak self] offset in
            if let strongSelf = self {
                if let searchContentNode = strongSelf.searchContentNode {
                    searchContentNode.updateGridVisibleContentOffset(offset)
                }
                
                var previousContentOffsetValue: CGFloat?
                if let previousContentOffset = strongSelf.previousContentOffset, case let .known(value) = previousContentOffset {
                    previousContentOffsetValue = value
                }
                switch offset {
                    case let .known(value):
                        let transition: ContainedViewLayoutTransition
                        if let previousContentOffsetValue = previousContentOffsetValue, value <= 0.0, previousContentOffsetValue > 30.0 {
                            transition = .animated(duration: 0.2, curve: .easeInOut)
                        } else {
                            transition = .immediate
                        }
                        strongSelf.navigationBar?.updateBackgroundAlpha(min(30.0, max(0.0, value - 54.0)) / 30.0, transition: transition)
                    case .unknown, .none:
                        strongSelf.navigationBar?.updateBackgroundAlpha(1.0, transition: .immediate)
                }
                
                strongSelf.previousContentOffset = offset
            }
        }

        self.controllerNode.gridNode.scrollingCompleted = { [weak self] in
            if let strongSelf = self, let searchContentNode = strongSelf.searchContentNode {
                let _ = strongSelf.controllerNode.fixNavigationSearchableGridNodeScrolling(searchNode: searchContentNode)
            }
        }
        
        self._ready.set(self.controllerNode.ready.get())
        
        self.navigationBar?.updateBackgroundAlpha(0.0, transition: .immediate)
        
        self.displayNodeDidLoad()
    }
    
    private func shareWallpapers(_ wallpapers: [TelegramWallpaper]) {
        var string: String = ""
        for wallpaper in wallpapers {
            var item: String?
            switch wallpaper {
                case let .file(file):
                    var options: [String] = []
                    if file.isPattern {
                        if file.settings.colors.count >= 1 {
                            options.append("bg_color=\(UIColor(rgb: file.settings.colors[0]).hexString)")
                        }
                        if let intensity = file.settings.intensity {
                            options.append("intensity=\(intensity)")
                        }
                    }
                    
                    var optionsString = ""
                    if !options.isEmpty {
                        optionsString = "?\(options.joined(separator: "&"))"
                    }
                    item = file.slug + optionsString
                case let .color(color):
                    item = "\(UIColor(rgb: color).hexString)"
                default:
                    break
            }
            if let item = item {
                if !string.isEmpty {
                    string.append("\n")
                }
                string.append("https://t.me/bg/\(item)")
            }
        }
        let subject: ShareControllerSubject
        if wallpapers.count == 1 {
            subject = .url(string)
        } else {
            subject = .text(string)
        }
        let shareController = ShareController(context: context, subject: subject)
        self.present(shareController, in: .window(.root), blockInteraction: true)
        
        self.donePressed()
    }
    
    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.cleanNavigationHeight, transition: transition)
    }
    
    func activateSearch() {
        if self.displayNavigationBar {
            let _ = (self.controllerNode.ready.get()
            |> take(1)
            |> deliverOnMainQueue).start(completed: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                if let scrollToTop = strongSelf.scrollToTop {
                    scrollToTop()
                }
                if let searchContentNode = strongSelf.searchContentNode {
                    strongSelf.controllerNode.activateSearch(placeholderNode: searchContentNode.placeholderNode)
                }
                strongSelf.setDisplayNavigationBar(false, transition: .animated(duration: 0.5, curve: .spring))
            })
        }
    }
    
    func deactivateSearch(animated: Bool) {
        if !self.displayNavigationBar {
            self.setDisplayNavigationBar(true, transition: animated ? .animated(duration: 0.5, curve: .spring) : .immediate)
            if let searchContentNode = self.searchContentNode {
                self.controllerNode.deactivateSearch(placeholderNode: searchContentNode.placeholderNode, animated: animated)
            }
        }
    }
    
    @objc func editPressed() {
        self.editingMode = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Done, style: .done, target: self, action: #selector(self.donePressed))
        self.searchContentNode?.setIsEnabled(false, animated: true)
        self.controllerNode.updateState { state in
            var state = state
            state.editing = true
            return state
        }
    }
    
    @objc func donePressed() {
        self.editingMode = false
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Edit, style: .plain, target: self, action: #selector(self.editPressed))
        self.searchContentNode?.setIsEnabled(true, animated: true)
        self.controllerNode.updateState { state in
            var state = state
            state.editing = false
            return state
        }
    }
}
