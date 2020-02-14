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
import SyncCore
import NicegramLib


private struct BrowserSelectionState: Equatable {
    let selectedBrowser: Browser

    static func ==(lhs: BrowserSelectionState, rhs: BrowserSelectionState) -> Bool {
        return lhs.selectedBrowser == rhs.selectedBrowser
    }
}

private final class NiceFeaturesControllerArguments {
    let togglePinnedMessage: (Bool) -> Void
    let toggleMuteSilent: (Bool) -> Void
    let toggleHideNotifyAccount: (Bool) -> Void
    
    let toggleShowContactsTab: (Bool) -> Void
    let toggleFixNotifications: (Bool) -> Void
    let updateShowCallsTab: (Bool) -> Void
    let changeFiltersAmount: (Int32) -> Void
    let toggleShowTabNames: (Bool, String) -> Void
    let toggleHidePhone: (Bool, String) -> Void
    
    let toggleFiltersBadge: (Bool) -> Void
    
    let toggleUseBrowser: (Bool) -> Void
    let customizeBrowser: (Browser) -> Void
    
    let openBrowserSelection: () -> Void

    let backupSettings: () -> Void
    
    let toggleBackupIcloud: (Bool) -> Void
    
    let togglebackCam: (Bool) -> Void
    let toggletgFilters: (Bool) -> Void

    init(togglePinnedMessage: @escaping (Bool) -> Void, toggleMuteSilent: @escaping (Bool) -> Void, toggleHideNotifyAccount: @escaping (Bool) -> Void, toggleShowContactsTab: @escaping (Bool) -> Void, toggleFixNotifications: @escaping (Bool) -> Void, updateShowCallsTab: @escaping (Bool) -> Void, changeFiltersAmount: @escaping (Int32) -> Void, toggleShowTabNames: @escaping (Bool, String) -> Void, toggleHidePhone: @escaping (Bool, String) -> Void, toggleUseBrowser: @escaping (Bool) -> Void, customizeBrowser: @escaping (Browser) -> Void, openBrowserSelection: @escaping () -> Void, backupSettings: @escaping () -> Void, toggleFiltersBadge: @escaping (Bool) -> Void, toggleBackupIcloud: @escaping (Bool) -> Void, togglebackCam: @escaping (Bool) -> Void, toggletgFilters: @escaping (Bool) -> Void) {
        self.togglePinnedMessage = togglePinnedMessage
        self.toggleMuteSilent = toggleMuteSilent
        self.toggleHideNotifyAccount = toggleHideNotifyAccount
        self.toggleShowContactsTab = toggleShowContactsTab
        self.toggleFixNotifications = toggleFixNotifications
        self.updateShowCallsTab = updateShowCallsTab
        self.changeFiltersAmount = changeFiltersAmount
        self.toggleShowTabNames = toggleShowTabNames
        self.toggleHidePhone = toggleHidePhone
        self.toggleUseBrowser = toggleUseBrowser
        self.customizeBrowser = customizeBrowser
        self.openBrowserSelection = openBrowserSelection
        self.backupSettings = backupSettings
        self.toggleFiltersBadge = toggleFiltersBadge
        self.toggleBackupIcloud = toggleBackupIcloud
        self.togglebackCam = togglebackCam
        self.toggletgFilters = toggletgFilters
    }
}


private enum niceFeaturesControllerSection: Int32 {
    case messageNotifications
    case chatsList
    case tabs
    case filters
    case chatScreen
    case browsers
    case other
}

private enum NiceFeaturesControllerEntityId: Equatable, Hashable {
    case index(Int)
}

private enum NiceFeaturesControllerEntry: ItemListNodeEntry {
    case messageNotificationsHeader(PresentationTheme, String)
    case pinnedMessageNotification(PresentationTheme, String, Bool)
    case muteSilentNotifications(PresentationTheme, String, Bool)
    case muteSilentNotificationsNotice(PresentationTheme, String)
    case hideNotifyAccount(PresentationTheme, String, Bool)
    case hideNotifyAccountNotice(PresentationTheme, String)

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
    case filtersBadge(PresentationTheme, String, Bool)

    case chatScreenHeader(PresentationTheme, String)

    case browsersHeader(PresentationTheme, String)
    case telegramBrowsers(PresentationTheme, String, String)
    
    case otherHeader(PresentationTheme, String)
    case hideNumber(PresentationTheme, String, Bool, String)

    case backupSettings(PresentationTheme, String)
    case backupNotice(PresentationTheme, String)
    
    case backupIcloud(PresentationTheme, String, Bool)
    case backCam(PresentationTheme, String, Bool)
    case tgFilters(PresentationTheme, String, Bool)

    var section: ItemListSectionId {
        switch self {
        case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .muteSilentNotifications, .muteSilentNotificationsNotice, .hideNotifyAccount, .hideNotifyAccountNotice:
            return niceFeaturesControllerSection.messageNotifications.rawValue
        case .chatsListHeader:
            return niceFeaturesControllerSection.chatsList.rawValue
        case .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames:
            return niceFeaturesControllerSection.tabs.rawValue
        case .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge:
            return niceFeaturesControllerSection.filters.rawValue
        case .chatScreenHeader:
            return niceFeaturesControllerSection.chatScreen.rawValue
        case .browsersHeader, .telegramBrowsers:
            return niceFeaturesControllerSection.browsers.rawValue
        case .otherHeader, .hideNumber, .backupNotice, .backupSettings, .backupIcloud, .backCam, .tgFilters:
            return niceFeaturesControllerSection.other.rawValue
        }

    }

    var stableId: Int32 {
        switch self {
        case .messageNotificationsHeader:
            return 0
        case .pinnedMessageNotification:
            return 1
        case .muteSilentNotifications:
            return 2
        case .muteSilentNotificationsNotice:
            return 3
        case .hideNotifyAccount:
            return 4
        case .hideNotifyAccountNotice:
            return 5
        case .fixNotifications:
            return 6
        case .fixNotificationsNotice:
            return 7
        case .chatsListHeader:
            return 8
        case .tabsHeader:
            return 9
        case .showContactsTab:
            return 10
        case .duplicateShowCalls:
            return 11
        case .showTabNames:
            return 12
        case .filtersHeader:
            return 13
        case .filtersAmount:
            return 14
        case .filtersNotice:
            return 15
        case .filtersBadge:
            return 16
        case .chatScreenHeader:
            return 20
        case .browsersHeader:
            return 21
        case .telegramBrowsers:
            return 37
        case .otherHeader:
            return 38
        case .hideNumber:
            return 39
        case .backCam:
            return 41
        case .tgFilters:
            return 42
        case .backupIcloud:
            return 100000 - 1
        case .backupSettings:
            return 100000
        case .backupNotice:
            return 100001
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

        case let .browsersHeader(lhsTheme, lhsText):
            if case let .browsersHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .telegramBrowsers(lhsTheme, lhsText, lhsValue):
            if case let .telegramBrowsers(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
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
        case let .backupSettings(lhsTheme, lhsText):
            if case let .backupSettings(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .backupNotice(lhsTheme, lhsText):
            if case let .backupNotice(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .filtersBadge(lhsTheme, lhsText, lhsValue):
            if case let .filtersBadge(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .backupIcloud(lhsTheme, lhsText, lhsValue):
            if case let .backupIcloud(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .backCam(lhsTheme, lhsText, lhsValue):
            if case let .backCam(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .tgFilters(lhsTheme, lhsText, lhsValue):
            if case let .tgFilters(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .muteSilentNotifications(lhsTheme, lhsText, lhsValue):
            if case let .muteSilentNotifications(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .muteSilentNotificationsNotice(lhsTheme, lhsText):
            if case let .muteSilentNotificationsNotice(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .hideNotifyAccount(lhsTheme, lhsText, lhsValue):
            if case let .hideNotifyAccount(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .hideNotifyAccountNotice(lhsTheme, lhsText):
            if case let .hideNotifyAccountNotice(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }
        }
    }

    static func <(lhs: NiceFeaturesControllerEntry, rhs: NiceFeaturesControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! NiceFeaturesControllerArguments
        switch self {
        case let .messageNotificationsHeader(theme, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .pinnedMessageNotification(theme, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.togglePinnedMessage(value)
            })
        case let .muteSilentNotifications(theme, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleMuteSilent(value)
            })
        case let .muteSilentNotificationsNotice(theme, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .hideNotifyAccount(theme, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleHideNotifyAccount(value)
            })
        case let .hideNotifyAccountNotice(theme, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .fixNotifications(theme, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleFixNotifications(value)
            })
        case let .fixNotificationsNotice(theme, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .chatsListHeader(theme, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .tabsHeader(theme, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .showContactsTab(theme, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleShowContactsTab(value)
            })
        case let .duplicateShowCalls(theme, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateShowCallsTab(value)
            })
        case let .showTabNames(theme, text, value, locale):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleShowTabNames(value, locale)
            })
        case let .filtersHeader(theme, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .filtersAmount(theme, lang, value):
            return NiceSettingsFiltersAmountPickerItem(theme: theme, lang: lang, value: value, customPosition: nil, enabled: true, sectionId: self.section, updated: { preset in
                arguments.changeFiltersAmount(preset)
            })
        case let .filtersNotice(theme, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .filtersBadge(theme, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleFiltersBadge(value)
            })
        case let .chatScreenHeader(theme, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .browsersHeader(theme, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .telegramBrowsers(theme, text, value):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: value, sectionId: self.section, style: .blocks, action: {
                arguments.openBrowserSelection()
            })
        case let .otherHeader(theme, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .hideNumber(theme, text, value, locale):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleHidePhone(value, locale)
            })
//        case let .backupSettings(theme, text):
//            return ItemList
        case let .backupSettings(theme, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.backupSettings()
            })
        case let .backupNotice(theme, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .backupIcloud(theme, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleBackupIcloud(value)
            })
        case let .backCam(theme, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.togglebackCam(value)
            })
        case let .tgFilters(theme, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggletgFilters(value)
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

private func niceFeaturesControllerEntries(niceSettings: NiceSettings, showCalls: Bool, presentationData: PresentationData, simplyNiceSettings: SimplyNiceSettings, nicegramSettings: NicegramSettings, defaultWebBrowser: String) -> [NiceFeaturesControllerEntry] {
    var entries: [NiceFeaturesControllerEntry] = []

    let locale = presentationData.strings.baseLanguageCode
    entries.append(.messageNotificationsHeader(presentationData.theme, presentationData.strings.Notifications_Title.uppercased()))
    //entries.append(.pinnedMessageNotification(presentationData.theme, "Pinned Messages", niceSettings.pinnedMessagesNotification))  //presentationData.strings.Nicegram_Settings_Features_PinnedMessages
    
//    entries.append(.muteSilentNotifications(presentationData.theme, l("NiceFeatures.Notifications.MuteSilent", locale), nicegramSettings.muteSoundSilent))
//    entries.append(.muteSilentNotificationsNotice(presentationData.theme, l("NiceFeatures.Notifications.MuteSilentNotice", locale)))
    
    entries.append(.hideNotifyAccount(presentationData.theme, l("NiceFeatures.Notifications.HideNotifyAccount", locale), nicegramSettings.hideNotifyAccountName))
    entries.append(.hideNotifyAccountNotice(presentationData.theme, l("NiceFeatures.Notifications.HideNotifyAccountNotice", locale)))
    
    entries.append(.fixNotifications(presentationData.theme, l("NiceFeatures.Notifications.Fix", locale), niceSettings.fixNotifications))
    entries.append(.fixNotificationsNotice(presentationData.theme, l("NiceFeatures.Notifications.FixNotice", locale)))


    entries.append(.tabsHeader(presentationData.theme, l("NiceFeatures.Tabs.Header", locale)))
    entries.append(.showContactsTab(presentationData.theme, l("NiceFeatures.Tabs.ShowContacts", locale), niceSettings.showContactsTab))
    entries.append(.duplicateShowCalls(presentationData.theme, presentationData.strings.CallSettings_TabIcon, showCalls))

    entries.append(.showTabNames(presentationData.theme, l("NiceFeatures.Tabs.ShowNames", locale), SimplyNiceSettings().showTabNames, locale))

    entries.append(.filtersHeader(presentationData.theme, l("NiceFeatures.Filters.Header", locale)))
    entries.append(.filtersAmount(presentationData.theme, locale, simplyNiceSettings.maxFilters))
    entries.append(.filtersNotice(presentationData.theme, l("NiceFeatures.Filters.Notice", locale)))
    entries.append(.filtersBadge(presentationData.theme, l("NiceFeatures.Filters.ShowBadge", locale), simplyNiceSettings.filtersBadge))
    //entries.append(.chatScreenHeader(presentationData.theme, l(key: "NiceFeatures.ChatScreen.Header", locale: locale)))
    //entries.append(.animatedStickers(presentationData.theme, l(key:  "NiceFeatures.ChatScreen.AnimatedStickers", locale: locale), GlobalExperimentalSettings.animatedStickers))

    entries.append(.browsersHeader(presentationData.theme, l("NiceFeatures.Browser.Header", locale)))
    entries.append(.telegramBrowsers(presentationData.theme, presentationData.strings.ChatSettings_OpenLinksIn, defaultWebBrowser))

    entries.append(.otherHeader(presentationData.theme, presentationData.strings.ChatSettings_Other))
    entries.append(.hideNumber(presentationData.theme, l("NiceFeatures.HideNumber", locale), simplyNiceSettings.hideNumber, locale))
    // entries.append(.backupIcloud(presentationData.theme, l("NiceFeatures.BackupIcloud", locale), useIcloud()))
    entries.append(.backCam(presentationData.theme, l("NiceFeatures.useBackCam", locale), nicegramSettings.useBackCam))
    
    //entries.append(.tgFilters(presentationData.theme, "Use Telegram Filters", nicegramSettings.useTgFilters))

    entries.append(.backupSettings(presentationData.theme, l("NiceFeatures.BackupSettings", locale)))
    entries.append(.backupNotice(presentationData.theme, l("NiceFeatures.BackupSettings.Notice", locale)))
    
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
    // let statePromise = ValuePromise(NiceFeaturesSelectionState(), ignoreRepeated: true)
    var dismissImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    let presentationData = context.sharedContext.currentPresentationData.with {
        $0
    }

    var currentBrowser = Browser(rawValue: SimplyNiceSettings().browser) ?? Browser.Safari
    let statePromise = ValuePromise(BrowserSelectionState(selectedBrowser: currentBrowser), ignoreRepeated: true)
    let stateValue = Atomic(value: BrowserSelectionState(selectedBrowser: currentBrowser))
    let updateState: ((BrowserSelectionState) -> BrowserSelectionState) -> Void = { f in
        statePromise.set(stateValue.modify {
            f($0)
        })
    }
    var lastTabsCounter: Int32? = nil


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
    }, toggleMuteSilent: { value in
        NicegramSettings().muteSoundSilent = value
    }, toggleHideNotifyAccount: { value in
        NicegramSettings().hideNotifyAccountName = value
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
        if lastTabsCounter != nil {
            if Int32(value) == SimplyNiceSettings().maxFilters {
                //print("Same value, returning")
                return
            } else {
                lastTabsCounter = Int32(value)
            }
        }
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

        lastTabsCounter = Int32(value)
        updateTabs()

    }, toggleShowTabNames: { value, locale in
        SimplyNiceSettings().showTabNames = value
        updateTabs()
        // NSUbiquitousKeyValueStore.default.synchronize()
        
        let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("Common.RestartRequired", locale), actions: [/* TextAlertAction(type: .destructiveAction, title: l("Common.ExitNow", locale), action: { preconditionFailure() }),*/ TextAlertAction(type: .genericAction, title: presentationData.strings.Common_OK, action: {})])

        presentControllerImpl?(controller, nil)
    }, toggleHidePhone: { value, locale in
        SimplyNiceSettings().hideNumber = value
        // NSUbiquitousKeyValueStore.default.synchronize()
        
        let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("Common.RestartRequired", locale), actions: [/*TextAlertAction(type: .destructiveAction, title: l("Common.ExitNow", locale), action: { preconditionFailure() }),*/ TextAlertAction(type: .genericAction, title: presentationData.strings.Common_OK, action: {})])

        presentControllerImpl?(controller, nil)
    }, toggleUseBrowser: { value in
        SimplyNiceSettings().useBrowser = value
    }, customizeBrowser: { value in
        SimplyNiceSettings().browser = value.rawValue
        updateState { state in
            return BrowserSelectionState(selectedBrowser: value)
        }
        print("CUSTOMIZE BROWSER")
    }, openBrowserSelection: {
        let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("NiceFeatures.Use.DataStorage", presentationData.strings.baseLanguageCode).replacingOccurrences(of: "%1", with: presentationData.strings.Settings_ChatSettings, range: nil), actions: [TextAlertAction(type: .genericAction, title: presentationData.strings.Common_OK, action: {})])
         presentControllerImpl?(controller, nil)
//        let controller = webBrowserSettingsController(context: context)
//        presentControllerImpl?(controller, nil)
    }, backupSettings: {
        if let exportPath = NicegramSettings().exportSettings() {
            var messages: [EnqueueMessage] = []
            let id = arc4random64()
            let file = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: id), partialReference: nil, resource: LocalFileReferenceMediaResource(localFilePath: exportPath, randomId: id), previewRepresentations: [], immediateThumbnailData: nil, mimeType: "application/json", size: nil, attributes: [.FileName(fileName: BACKUP_NAME)])
            messages.append(.message(text: "", attributes: [], mediaReference: .standalone(media: file), replyToMessageId: nil, localGroupingKey: nil))
            let _ = enqueueMessages(account: context.account, peerId: context.account.peerId, messages: messages).start()
            let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("NiceFeatures.BackupSettings.Done", presentationData.strings.baseLanguageCode), actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {
            })])
            presentControllerImpl?(controller, nil)
        } else {
            let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("NiceFeatures.BackupSettings.Error", presentationData.strings.baseLanguageCode), actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {
            })])
            presentControllerImpl?(controller, nil)
        }
    }, toggleFiltersBadge: { value in
        SimplyNiceSettings().filtersBadge = value
        updateTabs()
    }, toggleBackupIcloud: { value in
        setUseIcloud(value)
        let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("Common.RestartRequired", presentationData.strings.baseLanguageCode), actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {
        })])
        presentControllerImpl?(controller, nil)
    }, togglebackCam: { value in
        NicegramSettings().useBackCam = value
    }, toggletgFilters: { value in
        NicegramSettings().useTgFilters = value
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
        |> map { presentationData, sharedData, showCalls, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
            
            let entries = niceFeaturesControllerEntries(niceSettings: niceSettings, showCalls: showCalls, presentationData: presentationData, simplyNiceSettings: SimplyNiceSettings(), nicegramSettings: NicegramSettings(), defaultWebBrowser: "")

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

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(l("NiceFeatures.Title", presentationData.strings.baseLanguageCode)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
            let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, ensureVisibleItemTag: focusOnItemTag, initialScrollToItem: scrollToItem)

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
