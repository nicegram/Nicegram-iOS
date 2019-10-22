//
//  PremiumController.swift
//  NicegramPremium
//
//  Created by Sergey Akentev on 22.10.2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AccountContext
import TelegramNotices


private struct SelectionState: Equatable {
}

private final class PremiumControllerArguments {
    let togglePinnedMessage: (Bool) -> Void
    
    init(togglePinnedMessage:@escaping (Bool) -> Void) {
        self.togglePinnedMessage = togglePinnedMessage
    }
}


private enum premiumControllerSection: Int32 {
    case messageNotifications
}

private enum PremiumControllerEntityId: Equatable, Hashable {
    case index(Int)
}

private enum PremiumControllerEntry: ItemListNodeEntry {
    
    var section: ItemListSectionId {
        switch self {
            
        }
        
    }
    
    var stableId: Int32 {
        switch self {
            
        }
    }
    
    static func ==(lhs: PremiumControllerEntry, rhs: PremiumControllerEntry) -> Bool {
        switch lhs {
            
        }
    }
    
    static func <(lhs: PremiumControllerEntry, rhs: PremiumControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(_ arguments: PremiumControllerArguments) -> ListViewItem {
        switch self {
            
        }
    }
    
}


private func premiumControllerEntries(presentationData: PresentationData, premiumSettings: PremiumSettings) -> [PremiumControllerEntry] {
    var entries: [PremiumControllerEntry] = []
    
    let locale = presentationData.strings.baseLanguageCode
    
    return entries
}


private struct PremiumSelectionState: Equatable {
    var updatingFiltersAmountValue: Int32? = nil
}


public func premiumController(context: AccountContext) -> ViewController {
    // let statePromise = ValuePromise(PremiumSelectionState(), ignoreRepeated: true)
    var dismissImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    
    var currentBrowser = Browser(rawValue: SimplyNiceSettings().browser) ?? Browser.Safari
    let statePromise = ValuePromise(SelectionState(), ignoreRepeated: true)
    let stateValue = Atomic(value: SelectionState())
    let updateState: ((SelectionState) -> SelectionState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    
    
    func updateTabs() {
        let _ = updateNiceSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
            var settings = settings
            settings.showContactsTab = !settings.showContactsTab
            return settings
        }).start(completed: {
            let _ = updateNiceSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                var settings = settings
                settings.showContactsTab = !settings.showContactsTab
                return settings
            }).start(completed: {
                print("TABS REFRESHED")
            })
        })
    }
    
    let arguments = PremiumControllerArguments(togglePinnedMessage: { value in
        let _ = updateNiceSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
            var settings = settings
            settings.pinnedMessagesNotification = value
            return settings
        }).start()
    }
    )
    
    let showCallsTab = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.callListSettings])
        |> map { sharedData -> Bool in
            var value = true
            if let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.callListSettings] as? CallListSettings {
                value = settings.showTab
            }
            return value
    }
    
    
    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
        |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState<PremiumControllerEntry>, PremiumControllerEntry.ItemGenerationArguments)) in
            
            let entries = premiumControllerEntries(presentationData: presentationData, premiumSettings: PremiumSettings())
            
            var index = 0
            var scrollToItem: ListViewScrollToItem?
            // workaround
            //            let focusOnItemTag: FakeEntryTag? = nil
            //            if let focusOnItemTag = focusOnItemTag {
            //                for entry in entries {
            //                    if entry.tag?.isEqual(to: focusOnItemTag) ?? false {
            //                        scrollToItem = ListViewScrollToItem(index: index, position: .top(0.0), animated: false, curve: .Default(duration: 0.0), directionHint: .Up)
            //                    }
            //                    index += 1
            //                }
            //            }
            
            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text(l("Premium.Title", presentationData.strings.baseLanguageCode)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
            let listState = ItemListNodeState(entries: entries, style: .blocks, ensureVisibleItemTag: nil, initialScrollToItem: scrollToItem)
            
            return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    dismissImpl = { [weak controller] in
        controller?.dismiss()
    }
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    return controller
}

