//
//  NiceFeaturesController.swift
//  TelegramUI
//
//  Created by Sergey on 10/07/2019.
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

private final class NiceFeaturesControllerArguments {
    let togglePinnedMessage: (Bool) -> Void
    let toggleShowContactsTab: (Bool) -> Void
    let toggleFixNotifications: (Bool) -> Void
    let updateShowCallsTab: (Bool) -> Void
    let changeFiltersAmount: (Int32) -> Void
    let toggleShowTabNames: (Bool, String) -> Void
    let toggleHidePhone: (Bool, String) -> Void
    
    init(togglePinnedMessage:@escaping (Bool) -> Void, toggleShowContactsTab:@escaping (Bool) -> Void, toggleFixNotifications:@escaping (Bool) -> Void, updateShowCallsTab:@escaping (Bool) -> Void, changeFiltersAmount:@escaping (Int32) -> Void, toggleShowTabNames:@escaping (Bool, String) -> Void, toggleHidePhone:@escaping (Bool, String) -> Void) {
        self.togglePinnedMessage = togglePinnedMessage
        self.toggleShowContactsTab = toggleShowContactsTab
        self.toggleFixNotifications = toggleFixNotifications
        self.updateShowCallsTab = updateShowCallsTab
        self.changeFiltersAmount = changeFiltersAmount
        self.toggleShowTabNames = toggleShowTabNames
        self.toggleHidePhone = toggleHidePhone
    }
}


private enum niceFeaturesControllerSection: Int32 {
    case messageNotifications
    case chatsList
    case tabs
    case filters
    case chatScreen
    case other
}

private enum NiceFeaturesControllerEntityId: Equatable, Hashable {
    case index(Int)
}

private enum NiceFeaturesControllerEntry: ItemListNodeEntry {
    case messageNotificationsHeader(PresentationTheme, String)
    case pinnedMessageNotification(PresentationTheme, String, Bool)
    
    case fixNotifications(PresentationTheme, String, Bool)
    case fixNotificationsNotice(PresentationTheme, String)
    
    case chatsListHeader(PresentationTheme, String)
    
    case tabsHeader(PresentationTheme, String)
    case showContactsTab(PresentationTheme, String, Bool)
    case duplicateShowCalls(PresentationTheme, String, Bool)
    case showTabNames(PresentationTheme, String, Bool, String)
    
    case filtersHeader(PresentationTheme, String)
    case filtersAmount(PresentationTheme, String, Int32)
    case filtersNotice(PresentationTheme, String)
    
    case chatScreenHeader(PresentationTheme, String)
    
    case otherHeader(PresentationTheme, String)
    case hideNumber(PresentationTheme, String, Bool, String)
    
    var section: ItemListSectionId {
        switch self {
        case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice:
            return niceFeaturesControllerSection.messageNotifications.rawValue
        case .chatsListHeader:
            return niceFeaturesControllerSection.chatsList.rawValue
        case .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames:
            return niceFeaturesControllerSection.tabs.rawValue
        case .filtersHeader, .filtersAmount, .filtersNotice:
            return niceFeaturesControllerSection.filters.rawValue
        case .chatScreenHeader:
            return niceFeaturesControllerSection.chatScreen.rawValue
        case .otherHeader, .hideNumber:
            return niceFeaturesControllerSection.other.rawValue
        }
        
    }
    
    var stableId: NiceFeaturesControllerEntityId {
        switch self {
        case .messageNotificationsHeader:
            return .index(0)
        case .pinnedMessageNotification:
            return .index(1)
        case .fixNotifications:
            return .index(2)
        case .fixNotificationsNotice:
            return .index(3)
        case .chatsListHeader:
            return .index(4)
        case .tabsHeader:
            return .index(5)
        case .showContactsTab:
            return .index(6)
        case .duplicateShowCalls:
            return .index(7)
        case .showTabNames:
            return .index(8)
        case .filtersHeader:
            return .index(9)
        case .filtersAmount:
            return .index(10)
        case .filtersNotice:
            return .index(11)
        case .chatScreenHeader:
            return .index(20)
        case .otherHeader:
            return .index(21)
        case .hideNumber:
            return .index(22)
        }
    }
    
    static func ==(lhs: NiceFeaturesControllerEntry, rhs: NiceFeaturesControllerEntry) -> Bool {
        switch lhs {
        case let .messageNotificationsHeader(lhsTheme, lhsText):
            if case let .messageNotificationsHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
            
        case let .pinnedMessageNotification(lhsTheme, lhsText, lhsValue):
            if case let .pinnedMessageNotification(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            
        case let .fixNotifications(lhsTheme, lhsText, lhsValue):
            if case let .fixNotifications(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            
        case let .fixNotificationsNotice(lhsTheme, lhsText):
            if case let .fixNotificationsNotice(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
            
        case let .chatsListHeader(lhsTheme, lhsText):
            if case let .chatsListHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
            
        case let .tabsHeader(lhsTheme, lhsText):
            if case let .tabsHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
            
        case let .showContactsTab(lhsTheme, lhsText, lhsValue):
            if case let .showContactsTab(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            
        case let .duplicateShowCalls(lhsTheme, lhsText, lhsValue):
            if case let .duplicateShowCalls(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            
        case let .showTabNames(lhsTheme, lhsText, lhsValue, lhsLanguage):
            if case let .showTabNames(rhsTheme, rhsText, rhsValue, rhsLanguage) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue, lhsLanguage == rhsLanguage {
                return true
            } else {
                return false
            }
            
        case let .filtersHeader(lhsTheme, lhsText):
            if case let .filtersHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
            
        case let .filtersAmount(lhsTheme, lhsText, lhsAmount):
            if case let .filtersAmount(rhsTheme, rhsText, rhsAmount) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsAmount == rhsAmount {
                return true
            } else {
                return false
            }
            
        case let .filtersNotice(lhsTheme, lhsText):
            if case let .filtersNotice(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
            
        case let .chatScreenHeader(lhsTheme, lhsText):
            if case let .chatScreenHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .otherHeader(lhsTheme, lhsText):
            if case let .otherHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .hideNumber(lhsTheme, lhsText, lhsValue, lhsLanguage):
            if case let .hideNumber(rhsTheme, rhsText, rhsValue, rhsLanguage) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue, lhsLanguage == rhsLanguage {
                return true
            } else {
                return false
            }
       }
    }
    
    static func <(lhs: NiceFeaturesControllerEntry, rhs: NiceFeaturesControllerEntry) -> Bool {
        switch lhs {
        case .messageNotificationsHeader:
            switch rhs {
            case .messageNotificationsHeader:
                return false
            default:
                return true
            }
        case .pinnedMessageNotification:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification:
                return false
            default:
                return true
            }
        case .fixNotifications:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications:
                return false
            default:
                return true
            }
        case .fixNotificationsNotice:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice:
                return false
            default:
                return true
            }
        case .chatsListHeader:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader:
                return false
            default:
                return true
            }
        case .tabsHeader:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader:
                return false
            default:
                return true
            }
        case .showContactsTab:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab:
                return false
            default:
                return true
            }
        case .duplicateShowCalls:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls:
                return false
            default:
                return true
            }
        case .showTabNames:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames:
                return false
            default:
                return true
            }
        case .filtersHeader:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader:
                return false
            default:
                return true
            }
        case .filtersAmount:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount:
                return false
            default:
                return true
            }
        case .filtersNotice:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice:
                return false
            default:
                return true
            }
        case .chatScreenHeader:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .chatScreenHeader:
                return false
            default:
                return true
            }
        case .otherHeader:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .chatScreenHeader, .otherHeader:
                return false
            default:
                return true
            }
        case .hideNumber:
            return false
        }
    }
    
    func item(_ arguments: NiceFeaturesControllerArguments) -> ListViewItem {
        switch self {
        case let .messageNotificationsHeader(theme, text):
            return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
        case let .pinnedMessageNotification(theme, text, value):
            return ItemListSwitchItem(theme: theme, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.togglePinnedMessage(value)
            })
        case let .fixNotifications(theme, text, value):
            return ItemListSwitchItem(theme: theme, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleFixNotifications(value)
            })
        case let .fixNotificationsNotice(theme, text):
            return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
        case let .chatsListHeader(theme, text):
            return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
        case let .tabsHeader(theme, text):
            return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
        case let .showContactsTab(theme, text, value):
            return ItemListSwitchItem(theme: theme, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleShowContactsTab(value)
            })
        case let .duplicateShowCalls(theme, text, value):
            return ItemListSwitchItem(theme: theme, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateShowCallsTab(value)
            })
        case let .showTabNames(theme, text, value, locale):
            return ItemListSwitchItem(theme: theme, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleShowTabNames(value, locale)
            })
        case let .filtersHeader(theme, text):
            return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
        case let .filtersAmount(theme, lang, value):
            return NiceSettingsFiltersAmountPickerItem(theme: theme, lang: lang, value: value, customPosition: nil, enabled: true, sectionId: self.section, updated: { preset in
                arguments.changeFiltersAmount(preset)
            })
        case let .filtersNotice(theme, text):
            return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
        case let .chatScreenHeader(theme, text):
            return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
        case let .otherHeader(theme, text):
            return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
        case let .hideNumber(theme, text, value, locale):
            return ItemListSwitchItem(theme: theme, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleHidePhone(value, locale)
            })
        }
    }
    
}


/*
 public func niceFeaturesController(context: AccountContext) -> ViewController {
 let presentationData = context.sharedContext.currentPresentationData.with { $0 }
 return niceFeaturesController(accountManager: context.sharedContext.accountManager, postbox: context.account.postbox, theme: presentationData.theme, strings: presentationData.strings, updatedPresentationData: context.sharedContext.presentationData |> map { ($0.theme, $0.strings) })
 }
 */

private func niceFeaturesControllerEntries(niceSettings: NiceSettings, showCalls: Bool, presentationData: PresentationData) -> [NiceFeaturesControllerEntry] {
    var entries: [NiceFeaturesControllerEntry] = []
    
    let locale = presentationData.strings.baseLanguageCode
    let simplyNiceSettings = SimplyNiceSettings()
    entries.append(.messageNotificationsHeader(presentationData.theme, presentationData.strings.Notifications_Title.uppercased()))
    //entries.append(.pinnedMessageNotification(presentationData.theme, "Pinned Messages", niceSettings.pinnedMessagesNotification))  //presentationData.strings.Nicegram_Settings_Features_PinnedMessages
    entries.append(.fixNotifications(presentationData.theme, l("NiceFeatures.Notifications.Fix", locale), niceSettings.fixNotifications))
    entries.append(.fixNotificationsNotice(presentationData.theme, l("NiceFeatures.Notifications.FixNotice", locale)))
    
    
    entries.append(.tabsHeader(presentationData.theme, l("NiceFeatures.Tabs.Header", locale)))
    entries.append(.showContactsTab(presentationData.theme, l("NiceFeatures.Tabs.ShowContacts", locale), niceSettings.showContactsTab))
    entries.append(.duplicateShowCalls(presentationData.theme, presentationData.strings.CallSettings_TabIcon, showCalls))
    
    entries.append(.showTabNames(presentationData.theme, l("NiceFeatures.Tabs.ShowNames", locale), SimplyNiceSettings().showTabNames, locale))
    
    entries.append(.filtersHeader(presentationData.theme, l("NiceFeatures.Filters.Header", locale)))
    entries.append(.filtersAmount(presentationData.theme, locale, simplyNiceSettings.maxFilters))
    entries.append(.filtersNotice(presentationData.theme, l("NiceFeatures.Filters.Notice", locale)))
    //entries.append(.chatScreenHeader(presentationData.theme, l(key: "NiceFeatures.ChatScreen.Header", locale: locale)))
    //entries.append(.animatedStickers(presentationData.theme, l(key:  "NiceFeatures.ChatScreen.AnimatedStickers", locale: locale), GlobalExperimentalSettings.animatedStickers))
    
    entries.append(.otherHeader(presentationData.theme, presentationData.strings.ChatSettings_Other))
    entries.append(.hideNumber(presentationData.theme, l("NiceFeatures.HideNumber", locale), simplyNiceSettings.hideNumber, locale))
    
    return entries
}


private struct NiceFeaturesSelectionState: Equatable {
    var updatingFiltersAmountValue: Int32? = nil
}


public func dummyCompleteDisposable() -> Signal<Void, NoError> {
    return .complete()
}

public enum FakeEntryTag: ItemListItemTag {
    public func isEqual(to other: ItemListItemTag) -> Bool {
        return true
    }
    
}

public func niceFeaturesController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(NiceFeaturesSelectionState(), ignoreRepeated: true)
    var dismissImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    
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
    
    let arguments = NiceFeaturesControllerArguments(togglePinnedMessage: { value in
        let _ = updateNiceSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
            var settings = settings
            settings.pinnedMessagesNotification = value
            return settings
        }).start()
    }, toggleShowContactsTab: { value in
        let _ = updateNiceSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
            var settings = settings
            settings.showContactsTab = value
            return settings
        }).start()
    }, toggleFixNotifications: { value in
        let _ = updateNiceSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
            var settings = settings
            settings.fixNotifications = value
            return settings
        }).start()
        context.sharedContext.updateNotificationTokensRegistration()
    }, updateShowCallsTab: { value in
        let _ = updateCallListSettingsInteractively(accountManager: context.sharedContext.accountManager, {
            $0.withUpdatedShowTab(value)
        }).start()
        
        if value {
            let _ = ApplicationSpecificNotice.incrementCallsTabTips(accountManager: context.sharedContext.accountManager, count: 4).start()
        }
    }, changeFiltersAmount: { value in
        SimplyNiceSettings().maxFilters = Int32(value)
        if SimplyNiceSettings().maxFilters > SimplyNiceSettings().chatFilters.count {
            let delta = Int(SimplyNiceSettings().maxFilters) - SimplyNiceSettings().chatFilters.count
            
            for _ in 0...delta {
                SimplyNiceSettings().chatFilters.append(.onlyNonMuted)
            }
        }
        let _ = updateNiceSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
            var settings = settings
            settings.foo = !settings.foo
            return settings
        }).start()
        
        updateTabs()
        
    }, toggleShowTabNames: { value, locale in
        SimplyNiceSettings().showTabNames = value
        updateTabs()
        
        let controller = textAlertController(theme: AlertControllerTheme(presentationTheme: presentationData.theme), title: nil, text: NSAttributedString(string: l("Common.RestartRequired", locale)), actions: [TextAlertAction(type: .destructiveAction, title: l("Common.ExitNow", locale), action: {preconditionFailure()}),TextAlertAction(type: .genericAction, title: l("Common.Later", locale), action: {})])
        
        presentControllerImpl?(controller, nil)
    }, toggleHidePhone: { value, locale in
        SimplyNiceSettings().hideNumber = value
        
        let controller = textAlertController(theme: AlertControllerTheme(presentationTheme: presentationData.theme), title: nil, text: NSAttributedString(string: l("Common.RestartRequired", locale)), actions: [TextAlertAction(type: .destructiveAction, title: l("Common.ExitNow", locale), action: {preconditionFailure()}),TextAlertAction(type: .genericAction, title: l("Common.Later", locale), action: {})])
        
        presentControllerImpl?(controller, nil)
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
    
    let niceSettings = getNiceSettings(accountManager: context.sharedContext.accountManager)
    
    let signal = combineLatest(context.sharedContext.presentationData, context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.niceSettings]), showCallsTab, statePromise.get())
        |> map { presentationData, sharedData, showCalls, state -> (ItemListControllerState, (ItemListNodeState<NiceFeaturesControllerEntry>, NiceFeaturesControllerEntry.ItemGenerationArguments)) in
            
            let entries = niceFeaturesControllerEntries(niceSettings: niceSettings, showCalls: showCalls, presentationData: presentationData)
            
            var index = 0
            var scrollToItem: ListViewScrollToItem?
            // workaround
            let focusOnItemTag: FakeEntryTag? = nil
            if let focusOnItemTag = focusOnItemTag {
                for entry in entries {
                    if entry.tag?.isEqual(to: focusOnItemTag) ?? false {
                        scrollToItem = ListViewScrollToItem(index: index, position: .top(0.0), animated: false, curve: .Default(duration: 0.0), directionHint: .Up)
                    }
                    index += 1
                }
            }
            
            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text(l("NiceFeatures.Title", presentationData.strings.baseLanguageCode)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
            let listState = ItemListNodeState(entries: entries, style: .blocks, ensureVisibleItemTag: focusOnItemTag, initialScrollToItem: scrollToItem)
            
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
