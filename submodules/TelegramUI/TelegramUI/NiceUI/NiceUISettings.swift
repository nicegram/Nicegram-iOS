//
//  NiceUISettings.swift
//  TelegramUI
//
//  Created by Sergey on 10/07/2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import Postbox
import SwiftSignalKit
import TelegramUIPreferences

public struct NiceSettings: PreferencesEntry, Equatable {
    public var pinnedMessagesNotification: Bool
    public var showContactsTab: Bool
    public var currentFilter: NiceChatListNodePeersFilter
    public var fixNotifications: Bool
    
    public static var defaultSettings: NiceSettings {
        return NiceSettings(pinnedMessagesNotification: true, showContactsTab: true, currentFilter: .onlyNonMuted, fixNotifications: true)
    }
    
    init(pinnedMessagesNotification: Bool, showContactsTab: Bool, currentFilter: NiceChatListNodePeersFilter, fixNotifications: Bool) {
        self.pinnedMessagesNotification = pinnedMessagesNotification
        self.showContactsTab = showContactsTab
        self.currentFilter = currentFilter
        self.fixNotifications = fixNotifications
    }
    
    public init(decoder: PostboxDecoder) {
        self.pinnedMessagesNotification = decoder.decodeBoolForKey("nice:pinnedMessagesNotification", orElse: true)
        self.showContactsTab = decoder.decodeBoolForKey("nice:showContactsTab", orElse: true)
        self.currentFilter = NiceChatListNodePeersFilter(rawValue: decoder.decodeInt32ForKey("nice:currentFilter", orElse: 1 << 5))
        self.fixNotifications = decoder.decodeBoolForKey("nice:fixNotifications", orElse: true)
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeBool(self.pinnedMessagesNotification, forKey: "nice:pinnedMessagesNotification")
        encoder.encodeBool(self.showContactsTab, forKey: "nice:showContactsTab")
        encoder.encodeInt32(self.currentFilter.rawValue, forKey: "nice:currentFilter")
        encoder.encodeBool(self.fixNotifications, forKey: "nice:fixNotifications")
    }
    
    public func isEqual(to: PreferencesEntry) -> Bool {
        if let to = to as? NiceSettings {
            return self == to
        } else {
            return false
        }
    }
    
    public static func ==(lhs: NiceSettings, rhs: NiceSettings) -> Bool {
        return lhs.pinnedMessagesNotification == rhs.pinnedMessagesNotification && lhs.showContactsTab == rhs.showContactsTab && lhs.currentFilter == rhs.currentFilter && lhs.fixNotifications == rhs.fixNotifications
    }
    
    public func withUpdatedCurrentFilter(_ currentFilter: NiceChatListNodePeersFilter) -> NiceSettings {
        return NiceSettings(pinnedMessagesNotification: self.pinnedMessagesNotification, showContactsTab: self.showContactsTab, currentFilter: currentFilter, fixNotifications: fixNotifications)
    }
    
    /*
     public func withUpdatedpinnedMessagesNotification(_ pinnedMessagesNotification: Bool) -> NiceSettings {
     return NiceSettings(pinnedMessagesNotification: pinnedMessagesNotification, workmode: self.workmode, showContactsTab: self.showContactsTab)
     }
     
     public func withUpdatedworkmode(_ workmode: Bool) -> NiceSettings {
     return NiceSettings(pinnedMessagesNotification: self.pinnedMessagesNotification, workmode: workmode, showContactsTab: self.showContactsTab)
     }
     
     public func withUpdatedshowContactsTab(_ showContactsTab: Bool) -> NiceSettings {
     return NiceSettings(pinnedMessagesNotification: self.pinnedMessagesNotification, workmode: self.workmode, showContactsTab: showContactsTab)
     }
     */
}

public func updateNiceSettingsInteractively(accountManager: AccountManager, _ f: @escaping (NiceSettings) -> NiceSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.niceSettings, { entry in
            let currentSettings: NiceSettings
            if let entry = entry as? NiceSettings {
                currentSettings = entry
            } else {
                currentSettings = NiceSettings.defaultSettings
            }
            return f(currentSettings)
        })
    }
}
