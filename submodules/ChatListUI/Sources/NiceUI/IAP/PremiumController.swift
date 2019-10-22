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
    let toggleSetting: (Bool, String) -> Void
    
    init(toggleSetting:@escaping (Bool, String) -> Void) {
        self.toggleSetting = toggleSetting
    }
}


private enum premiumControllerSection: Int32 {
    case mainHeader
    case syncPins
}

private enum PremiumControllerEntityId: Equatable, Hashable {
    case index(Int)
}

private enum PremiumControllerEntry: ItemListNodeEntry {
    case header(PresentationTheme, String)
    
    case syncPinsHeader(PresentationTheme, String)
    case syncPinsToggle(PresentationTheme, String, Bool)
    case syncPinsNotice(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
            case .header:
                return premiumControllerSection.mainHeader.rawValue
            case .syncPinsHeader, .syncPinsToggle, .syncPinsNotice:
                return premiumControllerSection.syncPins.rawValue
        }
        
    }
    
    var stableId: Int32 {
        switch self {
            case .header:
                return 0
            case .syncPinsHeader:
                return 1000
            case .syncPinsToggle:
                return 1100
            case .syncPinsNotice:
                return 1200
        }
    }
    
    static func ==(lhs: PremiumControllerEntry, rhs: PremiumControllerEntry) -> Bool {
        switch lhs {
        case let .header(lhsTheme, lhsText):
            if case let .header(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .syncPinsHeader(lhsTheme, lhsText):
            if case let .syncPinsHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .syncPinsToggle(lhsTheme, lhsText, lhsValue):
            if case let .syncPinsToggle(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .syncPinsNotice(lhsTheme, lhsText):
            if case let .syncPinsNotice(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        }

    }
    
    static func <(lhs: PremiumControllerEntry, rhs: PremiumControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(_ arguments: PremiumControllerArguments) -> ListViewItem {
        switch self {
        case let .header(theme, text):
            return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
        case let .syncPinsHeader(theme, text):
            return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
        case let .syncPinsToggle(theme, text, value):
            return ItemListSwitchItem(theme: theme, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleSetting(value, "syncPins")
            })
        case let .syncPinsNotice(theme, text):
            return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
        }
    }
    
}


private func premiumControllerEntries(presentationData: PresentationData, premiumSettings: PremiumSettings) -> [PremiumControllerEntry] {
    var entries: [PremiumControllerEntry] = []
    
    let theme = presentationData.theme
    let locale = presentationData.strings.baseLanguageCode
    
    
    // entries.append(.header(theme, l("")))
    entries.append(.syncPinsHeader(theme, l("Premium.UnlimitedPins.Header", locale)))
    entries.append(.syncPinsToggle(theme, l("Premium.SyncPins", locale), premiumSettings.syncPins))
    
    
    var changeNoticeString = "Premium.SyncPins.Notice.ON"
    if !premiumSettings.syncPins {
        changeNoticeString = "Premium.SyncPins.Notice.OFF"
    }
    entries.append(.syncPinsNotice(theme, l(changeNoticeString, locale)))
    
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
    let statePromise = ValuePromise(SelectionState(), ignoreRepeated: false)
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
    
    let arguments = PremiumControllerArguments(toggleSetting: { value, setting in
            switch (setting) {
                case "syncPins":
                    PremiumSettings().syncPins = value
                    break
                default:
                    break
            }
            updateState { state in
                return SelectionState()
            }
        }
    )
    
    
    
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

