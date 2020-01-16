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

    init(togglePinnedMessage: @escaping (Bool) -> Void, toggleShowContactsTab: @escaping (Bool) -> Void, toggleFixNotifications: @escaping (Bool) -> Void, updateShowCallsTab: @escaping (Bool) -> Void, changeFiltersAmount: @escaping (Int32) -> Void, toggleShowTabNames: @escaping (Bool, String) -> Void, toggleHidePhone: @escaping (Bool, String) -> Void, toggleUseBrowser: @escaping (Bool) -> Void, customizeBrowser: @escaping (Browser) -> Void, openBrowserSelection: @escaping () -> Void, backupSettings: @escaping () -> Void, toggleFiltersBadge: @escaping (Bool) -> Void) {
        self.togglePinnedMessage = togglePinnedMessage
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
    case useBrowser(PresentationTheme, String, Bool)
    case useBrowserNotice(PresentationTheme, String)

    // case browsers(PresentationTheme, String, Bool, Bool)
    case browserSafari(PresentationTheme, String, Bool, Bool)
    case browserChrome(PresentationTheme, String, Bool, Bool)
    case browserYandex(PresentationTheme, String, Bool, Bool)
    case browserDuckDuckGo(PresentationTheme, String, Bool, Bool)
    case browserOpenerOptions(PresentationTheme, String, Bool, Bool)
    case browserOpenerAuto(PresentationTheme, String, Bool, Bool)
    case browserBrave(PresentationTheme, String, Bool, Bool)
    case browserAlook(PresentationTheme, String, Bool, Bool)
    case browserFirefox(PresentationTheme, String, Bool, Bool)
    case browserFirefoxFocus(PresentationTheme, String, Bool, Bool)
    case browserOperaTouch(PresentationTheme, String, Bool, Bool)
    case browserOperaMini(PresentationTheme, String, Bool, Bool)
    case browserEdge(PresentationTheme, String, Bool, Bool)

    
    case telegramBrowsers(PresentationTheme, String, String)
    
    case otherHeader(PresentationTheme, String)
    case hideNumber(PresentationTheme, String, Bool, String)

    case backupSettings(PresentationTheme, String)
    case backupNotice(PresentationTheme, String)

    var section: ItemListSectionId {
        switch self {
        case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice:
            return niceFeaturesControllerSection.messageNotifications.rawValue
        case .chatsListHeader:
            return niceFeaturesControllerSection.chatsList.rawValue
        case .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames:
            return niceFeaturesControllerSection.tabs.rawValue
        case .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge:
            return niceFeaturesControllerSection.filters.rawValue
        case .chatScreenHeader:
            return niceFeaturesControllerSection.chatScreen.rawValue
        case .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions, .browserOpenerAuto, .browserBrave, .browserAlook, .browserFirefox, .browserFirefoxFocus, .browserOperaTouch, .browserOperaMini, .browserEdge, .telegramBrowsers:
            return niceFeaturesControllerSection.browsers.rawValue
        case .otherHeader, .hideNumber, .backupNotice, .backupSettings:
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
        case .filtersBadge:
            return .index(12)
        case .chatScreenHeader:
            return .index(20)
        case .browsersHeader:
            return .index(21)
        case .useBrowser:
            return .index(22)
        case .useBrowserNotice:
            return .index(23)
        case .browserSafari:
            return .index(24)
        case .browserChrome:
            return .index(25)
        case .browserYandex:
            return .index(26)
        case .browserDuckDuckGo:
            return .index(27)
        case .browserOpenerOptions:
            return .index(28)
        case .browserOpenerAuto:
            return .index(29)
        case .browserBrave:
            return .index(30)
        case .browserAlook:
            return .index(31)
        case .browserFirefox:
            return .index(32)
        case .browserFirefoxFocus:
            return .index(33)
        case .browserOperaTouch:
            return .index(34)
        case .browserOperaMini:
            return .index(35)
        case .browserEdge:
            return .index(36)
        case .telegramBrowsers:
            return .index(37)
        case .otherHeader:
            return .index(38)
        case .hideNumber:
            return .index(39)
        case .backupSettings:
            return .index(40)
        case .backupNotice:
            return .index(41)
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

        case let .useBrowser(lhsTheme, lhsText, lhsAmount):
            if case let .useBrowser(rhsTheme, rhsText, rhsAmount) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsAmount == rhsAmount {
                return true
            } else {
                return false
            }

        case let .useBrowserNotice(lhsTheme, lhsText):
            if case let .useBrowserNotice(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                return true
            } else {
                return false
            }

        case let .browserChrome(lhsTheme, lhsText, lhsTick, lhsEnabled):
            if case let .browserChrome(rhsTheme, rhsText, rhsTick, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsTick == rhsTick, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
        case let .browserYandex(lhsTheme, lhsText, lhsTick, lhsEnabled):
            if case let .browserYandex(rhsTheme, rhsText, rhsTick, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsTick == rhsTick, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
        case let .browserDuckDuckGo(lhsTheme, lhsText, lhsTick, lhsEnabled):
            if case let .browserDuckDuckGo(rhsTheme, rhsText, rhsTick, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsTick == rhsTick, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
        case let .browserOpenerAuto(lhsTheme, lhsText, lhsTick, lhsEnabled):
            if case let .browserOpenerAuto(rhsTheme, rhsText, rhsTick, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsTick == rhsTick, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
        case let .browserOpenerOptions(lhsTheme, lhsText, lhsTick, lhsEnabled):
            if case let .browserOpenerOptions(rhsTheme, rhsText, rhsTick, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsTick == rhsTick, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
        case let .browserBrave(lhsTheme, lhsText, lhsTick, lhsEnabled):
            if case let .browserBrave(rhsTheme, rhsText, rhsTick, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsTick == rhsTick, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
        case let .browserAlook(lhsTheme, lhsText, lhsTick, lhsEnabled):
            if case let .browserAlook(rhsTheme, rhsText, rhsTick, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsTick == rhsTick, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
        case let .browserOperaTouch(lhsTheme, lhsText, lhsTick, lhsEnabled):
            if case let .browserOperaTouch(rhsTheme, rhsText, rhsTick, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsTick == rhsTick, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
        case let .browserOperaMini(lhsTheme, lhsText, lhsTick, lhsEnabled):
            if case let .browserOperaMini(rhsTheme, rhsText, rhsTick, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsTick == rhsTick, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
        case let .browserFirefox(lhsTheme, lhsText, lhsTick, lhsEnabled):
            if case let .browserFirefox(rhsTheme, rhsText, rhsTick, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsTick == rhsTick, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
        case let .browserFirefoxFocus(lhsTheme, lhsText, lhsTick, lhsEnabled):
            if case let .browserFirefoxFocus(rhsTheme, rhsText, rhsTick, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsTick == rhsTick, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
        case let .browserEdge(lhsTheme, lhsText, lhsTick, lhsEnabled):
            if case let .browserEdge(rhsTheme, rhsText, rhsTick, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsTick == rhsTick, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
        case let .browserSafari(lhsTheme, lhsText, lhsTick, lhsEnabled):
            if case let .browserSafari(rhsTheme, rhsText, rhsTick, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsTick == rhsTick, lhsEnabled == rhsEnabled {
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
        case .filtersBadge:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge:
                return false
            default:
                return true
            }
        case .chatScreenHeader:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader:
                return false
            default:
                return true
            }
        case .browsersHeader:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader:
                return false
            default:
                return true
            }
        case .useBrowser:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser:
                return false
            default:
                return true
            }
        case .useBrowserNotice:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice:
                return false
            default:
                return true
            }
        case .browserSafari:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari:
                return false
            default:
                return true
            }
        case .browserChrome:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome:
                return false
            default:
                return true
            }
        case .browserYandex:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex:
                return false
            default:
                return true
            }
        case .browserDuckDuckGo:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo:
                return false
            default:
                return true
            }
        case .browserOpenerOptions:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions:
                return false
            default:
                return true
            }
        case .browserOpenerAuto:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions, .browserOpenerAuto:
                return false
            default:
                return true
            }
        case .browserBrave:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions, .browserOpenerAuto, .browserBrave:
                return false
            default:
                return true
            }
        case .browserAlook:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions, .browserOpenerAuto, .browserBrave, .browserAlook:
                return false
            default:
                return true
            }
        case .browserFirefox:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions, .browserOpenerAuto, .browserBrave, .browserAlook, .browserFirefox:
                return false
            default:
                return true
            }
        case .browserFirefoxFocus:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions, .browserOpenerAuto, .browserBrave, .browserAlook, .browserFirefox, .browserFirefoxFocus:
                return false
            default:
                return true
            }
        case .browserOperaTouch:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions, .browserOpenerAuto, .browserBrave, .browserAlook, .browserFirefox, .browserFirefoxFocus, .browserOperaTouch:
                return false
            default:
                return true
            }
        case .browserOperaMini:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions, .browserOpenerAuto, .browserBrave, .browserAlook, .browserFirefox, .browserFirefoxFocus, .browserOperaTouch, .browserOperaMini:
                return false
            default:
                return true
            }
        case .browserEdge:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions, .browserOpenerAuto, .browserBrave, .browserAlook, .browserFirefox, .browserFirefoxFocus, .browserOperaTouch, .browserOperaMini, .browserEdge, .telegramBrowsers:
                return false
            default:
                return true
            }
        case .telegramBrowsers:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions, .browserOpenerAuto, .browserBrave, .browserAlook, .browserFirefox, .browserFirefoxFocus, .browserOperaTouch, .browserOperaMini, .browserEdge, .telegramBrowsers:
                return false
            default:
                return true
            }
        case .otherHeader:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions, .browserOpenerAuto, .browserBrave, .browserAlook, .browserFirefox, .browserFirefoxFocus, .browserOperaTouch, .browserOperaMini, .browserEdge, .telegramBrowsers, .otherHeader:
                return false
            default:
                return true
            }
        case .hideNumber:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions, .browserOpenerAuto, .browserBrave, .browserAlook, .browserFirefox, .browserFirefoxFocus, .browserOperaTouch, .browserOperaMini, .browserEdge, .telegramBrowsers, .otherHeader, .hideNumber:
                return false
            default:
                return true
            }
        case .backupSettings:
            switch rhs {
            case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice, .chatsListHeader, .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames, .filtersHeader, .filtersAmount, .filtersNotice, .filtersBadge, .chatScreenHeader, .browsersHeader, .useBrowser, .useBrowserNotice, .browserSafari, .browserChrome, .browserYandex, .browserDuckDuckGo, .browserOpenerOptions, .browserOpenerAuto, .browserBrave, .browserAlook, .browserFirefox, .browserFirefoxFocus, .browserOperaTouch, .browserOperaMini, .browserEdge, .telegramBrowsers, .otherHeader, .hideNumber, .backupSettings:
                return false
            default:
                return true
            }
        case .backupNotice:
            return false
        }
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
        case let .useBrowser(theme, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleUseBrowser(value)
            })
        case let .browserSafari(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.Safari)
            })
        case let .browserChrome(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.Chrome)
            })
        case let .browserYandex(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.Yandex)
            })
        case let .browserDuckDuckGo(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.DuckDuckGo)
            })
        case let .browserAlook(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.Alook)
            })
        case let .browserOpenerAuto(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.OpenerAuto)
            })
        case let .browserOpenerOptions(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.OpenerOptions)
            })
        case let .browserBrave(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.Brave)
            })
        case let .browserAlook(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.Alook)
            })
        case let .browserFirefox(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.Firefox)
            })
        case let .browserFirefoxFocus(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.FirefoxFocus)
            })
        case let .browserOperaTouch(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.OperaTouch)
            })
        case let .browserOperaMini(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.OperaMini)
            })
        case let .browserEdge(theme, text, value, _):
            return ItemListCheckboxItem(presentationData: presentationData, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.customizeBrowser(.Edge)
            })
        case let .useBrowserNotice(theme, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
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
        }
    }

}


/*
 public func niceFeaturesController(context: AccountContext) -> ViewController {
 let presentationData = context.sharedContext.currentPresentationData.with { $0 }
 return niceFeaturesController(accountManager: context.sharedContext.accountManager, postbox: context.account.postbox, theme: presentationData.theme, strings: presentationData.strings, updatedPresentationData: context.sharedContext.presentationData |> map { ($0.theme, $0.strings) })
 }
 */

private func niceFeaturesControllerEntries(niceSettings: NiceSettings, showCalls: Bool, presentationData: PresentationData, simplyNiceSettings: SimplyNiceSettings, defaultWebBrowser: String) -> [NiceFeaturesControllerEntry] {
    var entries: [NiceFeaturesControllerEntry] = []

    let locale = presentationData.strings.baseLanguageCode
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
    entries.append(.filtersBadge(presentationData.theme, l("NiceFeatures.Filters.ShowBadge", locale), simplyNiceSettings.filtersBadge))
    //entries.append(.chatScreenHeader(presentationData.theme, l(key: "NiceFeatures.ChatScreen.Header", locale: locale)))
    //entries.append(.animatedStickers(presentationData.theme, l(key:  "NiceFeatures.ChatScreen.AnimatedStickers", locale: locale), GlobalExperimentalSettings.animatedStickers))

    entries.append(.browsersHeader(presentationData.theme, l("NiceFeatures.Browser.Header", locale)))
    entries.append(.telegramBrowsers(presentationData.theme, presentationData.strings.ChatSettings_OpenLinksIn, defaultWebBrowser))
//    entries.append(.useBrowser(presentationData.theme, l("NiceFeatures.Browser.UseBrowser", locale), simplyNiceSettings.useBrowser))
//    entries.append(.useBrowserNotice(presentationData.theme, l("NiceFeatures.Browser.UseBrowserNotice", locale)))
//
//    entries.append(.browserSafari(presentationData.theme, "Safari", simplyNiceSettings.browser == Browser.Safari.rawValue, true))
//    entries.append(.browserChrome(presentationData.theme, "Chrome", simplyNiceSettings.browser == Browser.Chrome.rawValue, true))
//    entries.append(.browserYandex(presentationData.theme, "Yandex", simplyNiceSettings.browser == Browser.Yandex.rawValue, true))
//    entries.append(.browserDuckDuckGo(presentationData.theme, "DuckDuckGo", simplyNiceSettings.browser == Browser.DuckDuckGo.rawValue, true))
//    entries.append(.browserOpenerOptions(presentationData.theme, "Opener (Manual)", simplyNiceSettings.browser == Browser.OpenerOptions.rawValue, true))
//    entries.append(.browserOpenerAuto(presentationData.theme, "Opener (Auto)", simplyNiceSettings.browser == Browser.OpenerAuto.rawValue, true))
//    entries.append(.browserBrave(presentationData.theme, "Brave", simplyNiceSettings.browser == Browser.Brave.rawValue, true))
//    entries.append(.browserAlook(presentationData.theme, "Alook", simplyNiceSettings.browser == Browser.Alook.rawValue, true))
//    entries.append(.browserFirefox(presentationData.theme, "Firefox", simplyNiceSettings.browser == Browser.Firefox.rawValue, true))
//    entries.append(.browserFirefoxFocus(presentationData.theme, "Firefox Focus", simplyNiceSettings.browser == Browser.FirefoxFocus.rawValue, true))
//    entries.append(.browserOperaTouch(presentationData.theme, "Opera Touch", simplyNiceSettings.browser == Browser.OperaTouch.rawValue, true))
//    // entries.append(.browserOperaMini(presentationData.theme, "Opera Mini", simplyNiceSettings.browser == Browser.OperaMini.rawValue, true))
//    entries.append(.browserEdge(presentationData.theme, "Microsoft Edge", simplyNiceSettings.browser == Browser.Edge.rawValue, true))

    entries.append(.otherHeader(presentationData.theme, presentationData.strings.ChatSettings_Other))
    entries.append(.hideNumber(presentationData.theme, l("NiceFeatures.HideNumber", locale), simplyNiceSettings.hideNumber, locale))

//    entries.append(.backupSettings(presentationData.theme, l("NiceFeatures.BackupSettings", locale)))
//    entries.append(.backupNotice(presentationData.theme, l("NiceFeatures.BackupSettings.Notice", locale)))

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
        let library_path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]

        let path = library_path + "/Preferences/SimplyNiceSettings.plist"

        let id = arc4random64()
        let file = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: id), partialReference: nil, resource: LocalFileReferenceMediaResource(localFilePath: path, randomId: id), previewRepresentations: [], immediateThumbnailData: nil, mimeType: "application/xml", size: nil, attributes: [.FileName(fileName: "SimplyNiceSettings.plist")])
        let message = EnqueueMessage.message(text: "", attributes: [], mediaReference: .standalone(media: file), replyToMessageId: nil, localGroupingKey: nil)


        //SimplyNiceSettings().sync()

        let pathF = library_path + "/Preferences/SimplyNiceFolders.plist"

        let idF = arc4random64()
        let fileF = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: idF), partialReference: nil, resource: LocalFileReferenceMediaResource(localFilePath: pathF, randomId: idF), previewRepresentations: [], immediateThumbnailData: nil, mimeType: "application/xml", size: nil, attributes: [.FileName(fileName: "SimplyNiceFolders.plist")])
        let messageF = EnqueueMessage.message(text: "", attributes: [], mediaReference: .standalone(media: fileF), replyToMessageId: nil, localGroupingKey: nil)


        let _ = enqueueMessages(account: context.account, peerId: context.account.peerId, messages: [message, messageF]).start()

        //if let navigateToChat = navigateToChat {
        let locale = "en"
        let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("NiceFeatures.BackupSettings.Done", locale), actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {
        })])

        presentControllerImpl?(controller, nil)
        //}
    }, toggleFiltersBadge: { value in
        SimplyNiceSettings().filtersBadge = value
        updateTabs()
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
            
            let entries = niceFeaturesControllerEntries(niceSettings: niceSettings, showCalls: showCalls, presentationData: presentationData, simplyNiceSettings: SimplyNiceSettings(), defaultWebBrowser: "")

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
