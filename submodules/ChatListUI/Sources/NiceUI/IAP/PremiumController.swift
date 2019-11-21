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
import NicegramLib

private struct SelectionState: Equatable {
}

private final class PremiumControllerArguments {
    let toggleSetting: (Bool, String) -> Void
    let openSetMissedInterval: () -> Void
    let testAction: () -> Void
    let openManageFilters: () -> Void
    
    init(toggleSetting:@escaping (Bool, String) -> Void, openSetMissedInterval:@escaping () -> Void, testAction:@escaping () -> Void, openManageFilters:@escaping () -> Void) {
        self.toggleSetting = toggleSetting
        self.openSetMissedInterval = openSetMissedInterval
        self.testAction = testAction
        self.openManageFilters = openManageFilters
    }
}


private enum premiumControllerSection: Int32 {
    case mainHeader
    case syncPins
    case notifyMissed
    case manageFilters
    case test
}

private enum PremiumControllerEntityId: Equatable, Hashable {
    case index(Int)
}

private enum PremiumControllerEntry: ItemListNodeEntry {
    case header(PresentationTheme, String)
    
    case syncPinsHeader(PresentationTheme, String)
    case syncPinsToggle(PresentationTheme, String, Bool)
    case syncPinsNotice(PresentationTheme, String)
    
    case notifyMissed(PresentationTheme, String, String)
    case notifyMissedNotice(PresentationTheme, String)
    
    case manageFiltersHeader(PresentationTheme, String)
    case manageFilters(PresentationTheme, String)
    
    case testButton(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
        case .header:
            return premiumControllerSection.mainHeader.rawValue
        case .syncPinsHeader, .syncPinsToggle, .syncPinsNotice:
            return premiumControllerSection.syncPins.rawValue
        case .notifyMissed, .notifyMissedNotice:
            return premiumControllerSection.notifyMissed.rawValue
        case .manageFiltersHeader, .manageFilters:
           return premiumControllerSection.manageFilters.rawValue
        case .testButton:
            return premiumControllerSection.test.rawValue
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
        case .notifyMissed:
            return 2100
        case .notifyMissedNotice:
            return 2200
        case .manageFiltersHeader:
            return 3000
        case .manageFilters:
            return 3100
        case .testButton:
            return 999999
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
            
        case let .notifyMissed(lhsTheme, lhsText, lhsValue):
            if case let .notifyMissed(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            
        case let .notifyMissedNotice(lhsTheme, lhsText):
            if case let .notifyMissedNotice(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }

        case let .manageFiltersHeader(lhsTheme, lhsText):
            if case let .manageFiltersHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
            
        case let .manageFilters(lhsTheme, lhsText):
            if case let .manageFilters(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
            
        case let .testButton(lhsTheme, lhsText):
            if case let .testButton(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
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
            
        case let .notifyMissed(theme, title, value):
            return ItemListDisclosureItem(theme: theme, title: title, label: value, sectionId: self.section, style: .blocks, action: {
                arguments.openSetMissedInterval()
            })
        case let .notifyMissedNotice(theme, text):
            return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
        case let .manageFiltersHeader(theme, text):
            return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
        case let .manageFilters(theme, text):
            return ItemListDisclosureItem(theme: theme, icon: nil, title: text, label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openManageFilters()
            })
        case let .testButton(theme, text):
            return ItemListActionItem(theme: theme, title: "Test Button", kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.testAction()
            })
        }
    }
    
}


private func premiumControllerEntries(presentationData: PresentationData, premiumSettings: PremiumSettings) -> [PremiumControllerEntry] {
    var entries: [PremiumControllerEntry] = []
    
    let theme = presentationData.theme
    let strings = presentationData.strings
    let locale = presentationData.strings.baseLanguageCode
    
    
    // entries.append(.header(theme, l("")))
    entries.append(.syncPinsHeader(theme, l("Premium.UnlimitedPins.Header", locale)))
    entries.append(.syncPinsToggle(theme, l("Premium.SyncPins", locale), premiumSettings.syncPins))
    
    
    var changeNoticeString = "Premium.SyncPins.Notice.ON"
    if !premiumSettings.syncPins {
        changeNoticeString = "Premium.SyncPins.Notice.OFF"
    }
    entries.append(.syncPinsNotice(theme, l(changeNoticeString, locale)))
    
    var notifyTimeout = Int32.max
    if PremiumSettings().notifyMissed {
        notifyTimeout = Int32(PremiumSettings().notifyMissedEach)
    } else {
        notifyTimeout = Int32.max
    }
    let timeoutString = stringForShowMissedTimeout(strings, notifyTimeout)
    
    entries.append(.notifyMissed(theme, l("Premium.Missed", locale), timeoutString))
    entries.append(.notifyMissedNotice(theme, l("Premium.Missed.Notice", locale)))
    
    entries.append(.manageFiltersHeader(theme, l("NiceFeatures.Filters.Header", locale)))
    entries.append(.manageFilters(theme, l("ManageFilters.Title", locale)))
    
    #if DEBUG
    entries.append(.testButton(theme, "TEST"))
    #endif
    
    return entries
}


private struct PremiumSelectionState: Equatable {
    var updatingFiltersAmountValue: Int32? = nil
}

private func stringForShowMissedTimeout(_ strings: PresentationStrings, _ timeout: Int32?) -> String {
    if let timeout = timeout {
        if timeout > 1 * 31 * 24 * 60 * 60 {
            return strings.PrivacySettings_PasscodeOff
        } else {
            return timeIntervalString(strings: strings, value: timeout)
        }
    } else {
        return strings.PrivacySettings_PasscodeOff
    }
}

public func premiumController(context: AccountContext) -> ViewController {
    // let statePromise = ValuePromise(PremiumSelectionState(), ignoreRepeated: true)
    var dismissImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    var pushControllerImpl: ((ViewController) -> Void)?
    
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
    }, openSetMissedInterval: {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let actionSheet = ActionSheetController(presentationTheme: presentationData.theme)
        var items: [ActionSheetItem] = []
        let setAction: (Int32?) -> Void = { value in
            if let value = value {
                if value == Int32.max {
                    PremiumSettings().notifyMissed = false
                } else if value > 0 {
                    PremiumSettings().notifyMissed = true
                    PremiumSettings().notifyMissedEach = Int(value)
                } else {
                    PremiumSettings().notifyMissed = false
                }
            } else {
                PremiumSettings().notifyMissed = false
            }
            updateState { state in
                return SelectionState()
            }
        }
        var values: [Int32] = [
            1 * 60,
            5 * 60,
            15 * 60,
            30 * 60,
            1 * 60 * 60,
            3 * 60 * 60,
            5 * 60 * 60,
            8 * 60 * 60,
            Int32.max]
        
        #if DEBUG
        values.append(10)
        values.sort()
        #endif
        
        for value in values {
            var t: Int32?
            if value != 0 {
                t = value
            }
            items.append(ActionSheetButtonItem(title: stringForShowMissedTimeout(presentationData.strings, t), color: .accent, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
                
                setAction(t)
            }))
        }
        
        actionSheet.setItemGroups([ActionSheetItemGroup(items: items), ActionSheetItemGroup(items: [
            ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
            })
            ])])
        presentControllerImpl?(actionSheet, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
    }, testAction: {
        let msg = "- 儒家 \n\n> - Dota"
        let _ = (gtranslate(msg, presentationData.strings.baseLanguageCode)  |> deliverOnMainQueue).start(next: { translated in
            print("Translated", translated)
        },
        error: {_ in print("error translating")})
        print("TESTED!")
    }, openManageFilters: {
        pushControllerImpl?(manageFilters(context: context))
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
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    return controller
}

