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

private final class NiceFeaturesControllerArguments {
    let togglePinnedMessage: (Bool) -> Void
    let toggleShowContactsTab: (Bool) -> Void
    let toggleFixNotifications: (Bool) -> Void
    
    
    init(togglePinnedMessage:@escaping (Bool) -> Void, toggleShowContactsTab:@escaping (Bool) -> Void, toggleFixNotifications:@escaping (Bool) -> Void) {
        self.togglePinnedMessage = togglePinnedMessage
        self.toggleShowContactsTab = toggleShowContactsTab
        self.toggleFixNotifications = toggleFixNotifications
    }
}


private enum niceFeaturesControllerSection: Int32 {
    case messageNotifications
    case chatsList
    case tabs
    case chatScreen
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
    
    case chatScreenHeader(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
        case .messageNotificationsHeader, .pinnedMessageNotification, .fixNotifications, .fixNotificationsNotice:
            return niceFeaturesControllerSection.messageNotifications.rawValue
        case .chatsListHeader:
            return niceFeaturesControllerSection.chatsList.rawValue
        case .tabsHeader, .showContactsTab:
            return niceFeaturesControllerSection.tabs.rawValue
        case .chatScreenHeader:
            return niceFeaturesControllerSection.chatScreen.rawValue
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
        case .chatScreenHeader:
            return .index(7)
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
            
        case let .chatScreenHeader(lhsTheme, lhsText):
            if case let .chatScreenHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
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
        case .chatScreenHeader:
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
        case let .chatScreenHeader(theme, text):
            return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
        }
    }
    
}


/*
 public func niceFeaturesController(context: AccountContext) -> ViewController {
 let presentationData = context.sharedContext.currentPresentationData.with { $0 }
 return niceFeaturesController(accountManager: context.sharedContext.accountManager, postbox: context.account.postbox, theme: presentationData.theme, strings: presentationData.strings, updatedPresentationData: context.sharedContext.presentationData |> map { ($0.theme, $0.strings) })
 }
 */

private func niceFeaturesControllerEntries(niceSettings: NiceSettings, presentationData: PresentationData) -> [NiceFeaturesControllerEntry] {
    var entries: [NiceFeaturesControllerEntry] = []
    
    entries.append(.messageNotificationsHeader(presentationData.theme, presentationData.strings.Notifications_Title.uppercased()))
    //entries.append(.pinnedMessageNotification(presentationData.theme, "Pinned Messages", niceSettings.pinnedMessagesNotification))  //presentationData.strings.Nicegram_Settings_Features_PinnedMessages
    entries.append(.fixNotifications(presentationData.theme, l("NiceFeatures.Notifications.Fix", presentationData.strings.baseLanguageCode), niceSettings.fixNotifications))
    entries.append(.fixNotificationsNotice(presentationData.theme, l("NiceFeatures.Notifications.FixNotice", presentationData.strings.baseLanguageCode)))
    
    
    entries.append(.tabsHeader(presentationData.theme, l("NiceFeatures.Tabs.Header", presentationData.strings.baseLanguageCode)))
    entries.append(.showContactsTab(presentationData.theme, l("NiceFeatures.Tabs.ShowContacts", presentationData.strings.baseLanguageCode), niceSettings.showContactsTab))
    
    //entries.append(.chatScreenHeader(presentationData.theme, l(key: "NiceFeatures.ChatScreen.Header", locale: presentationData.strings.baseLanguageCode)))
    //entries.append(.animatedStickers(presentationData.theme, l(key:  "NiceFeatures.ChatScreen.AnimatedStickers", locale: presentationData.strings.baseLanguageCode), GlobalExperimentalSettings.animatedStickers))
    
    
    return entries
}


private struct NiceFeaturesSelectionState: Equatable {
    
}

public func niceFeaturesController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(NiceFeaturesSelectionState(), ignoreRepeated: true)
    var dismissImpl: (() -> Void)?
    
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
    }
    )
    
    
    let signal = combineLatest(context.sharedContext.presentationData, context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.niceSettings]), statePromise.get())
        |> map { presentationData, sharedData, state -> (ItemListControllerState, (ItemListNodeState<NiceFeaturesControllerEntry>, NiceFeaturesControllerEntry.ItemGenerationArguments)) in
            
            let niceSettings: NiceSettings
            
            if let value = sharedData.entries[ApplicationSpecificSharedDataKeys.niceSettings] as? NiceSettings {
                niceSettings = value
            } else {
                niceSettings = NiceSettings.defaultSettings
            }
            
            let entries = niceFeaturesControllerEntries(niceSettings: niceSettings, presentationData: presentationData)
            
            var index = 0
            var scrollToItem: ListViewScrollToItem?
            // workaround
            let focusOnItemTag: NotificationsAndSoundsEntryTag? = nil
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
    return controller
}
