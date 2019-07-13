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
    public var foo: Bool
    
    public var pinnedMessagesNotification: Bool
    public var showContactsTab: Bool
    public var chatFilters: [NiceChatListNodePeersFilter]
    public var maxFilters: Int32
    public var currentFilter: Int32
    public var fixNotifications: Bool
    
    public static var defaultSettings: NiceSettings {
        return NiceSettings(foo: false, pinnedMessagesNotification: true, showContactsTab: true, chatFilters: NiceChatListNodePeersFilter.all.reversed(), maxFilters: 2, currentFilter: 0, fixNotifications: true)
    }
    
    init(foo: Bool, pinnedMessagesNotification: Bool, showContactsTab: Bool, chatFilters: [NiceChatListNodePeersFilter], maxFilters: Int32, currentFilter: Int32, fixNotifications: Bool) {
        self.foo = foo
        self.pinnedMessagesNotification = pinnedMessagesNotification
        self.showContactsTab = showContactsTab
        self.chatFilters = chatFilters
        self.maxFilters = maxFilters
        self.currentFilter = currentFilter
        self.fixNotifications = fixNotifications
    }
    
    public init(decoder: PostboxDecoder) {
        self.foo = decoder.decodeBoolForKey("nice:foo", orElse: false)
        self.pinnedMessagesNotification = decoder.decodeBoolForKey("nice:pinnedMessagesNotification", orElse: true)
        self.showContactsTab = decoder.decodeBoolForKey("nice:showContactsTab", orElse: true)
        
        let filterList = decoder.decodeInt32ArrayForKey("nice:chatFilters")
        
        if filterList.isEmpty {
            self.chatFilters = NiceChatListNodePeersFilter.all.reversed()
        } else {
            self.chatFilters = []
            for filter in filterList {
                chatFilters.append(NiceChatListNodePeersFilter(rawValue: filter))
            }
        }
        
        self.maxFilters = decoder.decodeInt32ForKey("nice:maxFilters", orElse: 2)
        self.currentFilter = decoder.decodeInt32ForKey("nice:currentFilterIndex", orElse: 0)
        
        self.fixNotifications = decoder.decodeBoolForKey("nice:fixNotifications", orElse: true)
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeBool(self.foo, forKey: "nice:foo")
        encoder.encodeBool(self.pinnedMessagesNotification, forKey: "nice:pinnedMessagesNotification")
        encoder.encodeBool(self.showContactsTab, forKey: "nice:showContactsTab")
        
        var filterList: [Int32] = []
        for filter in self.chatFilters {
            filterList.append(filter.rawValue)
        }
        encoder.encodeInt32Array(filterList, forKey: "nice:chatFilters")
        encoder.encodeInt32(self.maxFilters, forKey: "nice:maxFilters")
        encoder.encodeInt32(self.currentFilter, forKey: "nice:currentFilterIndex")
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
    
    /* public func withUpdatedCurrentFilter(_ currentFilter: NiceChatListNodePeersFilter) -> NiceSettings {
        return NiceSettings(pinnedMessagesNotification: self.pinnedMessagesNotification, showContactsTab: self.showContactsTab, chatFilters: self. currentFilter: currentFilter, fixNotifications: fixNotifications)
    } */
    
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


public func getNiceSettings(accountManager: AccountManager) -> NiceSettings {
    var niceSettings: NiceSettings? = nil
    let semaphore = DispatchSemaphore(value: 0)
    _ = (accountManager.transaction { transaction in
        niceSettings = transaction.getSharedData(ApplicationSpecificSharedDataKeys.niceSettings) as? NiceSettings
        semaphore.signal()
    }).start()
    semaphore.wait()
    
    if (niceSettings == nil) {
        niceSettings = NiceSettings.defaultSettings
    }
    
    return niceSettings!
}


public func setNiceSettings(accountManager: AccountManager, newNiceSettings: NiceSettings) -> Void {
    let semaphore = DispatchSemaphore(value: 0)
    _ = (accountManager.transaction { transaction in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.niceSettings, { entry in
            return newNiceSettings
        })
        semaphore.signal()
    }).start()
    semaphore.wait()
}

// I'm fucking tired of these "Disposables", "transactions" and other shit, really. I'm not an iOS dev at all. Just want to make things nice...


public class SimplyNiceSettings {
    let UD = UserDefaults(suiteName: "SimplyNiceSettings")
    var maxFilters: Int32 {
        // let k = "maxFilters"
        get {
            return Int32(UD?.integer(forKey: "maxFilters") ?? 2)
        }
        set {
            UD?.set(newValue, forKey: "maxFilters")
        }
    }
    
    var chatFilters: [NiceChatListNodePeersFilter] {
        get {
            let array = UD?.array(forKey: "chatFilters") as? [Int32] ?? [1 << 6, 1 << 5]
            var res: [NiceChatListNodePeersFilter] = []
            for item in array {
                res.append(NiceChatListNodePeersFilter(rawValue: item))
            }
            return res
        }
        set {
            var resSet: [Int32] = []
            for item in newValue {
                resSet.append(item.rawValue)
            }
            UD?.set(resSet, forKey: "chatFilters")
        }
        
    }
}
