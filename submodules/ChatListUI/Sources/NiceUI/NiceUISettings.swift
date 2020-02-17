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
import TelegramCore
import AccountContext
import SyncCore

public struct NiceSettings: PreferencesEntry, Equatable {
    public var foo: Bool
    
    public var pinnedMessagesNotification: Bool
    public var showContactsTab: Bool
    public var chatFilters: [NiceChatListNodePeersFilter]
    public var maxFilters: Int32
    public var currentFilter: Int32
    public var fixNotifications: Bool
    
    public static var defaultSettings: NiceSettings {
        return NiceSettings(foo: false, pinnedMessagesNotification: true, showContactsTab: true, chatFilters: NiceChatListNodePeersFilter.all.reversed(), maxFilters: 2, currentFilter: 0, fixNotifications: false)
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
        
        self.fixNotifications = decoder.decodeBoolForKey("nice:fixNotifications", orElse: false)
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
public func setDefaults() {
    let UD = UserDefaults(suiteName: "SimplyNiceSettings")
    UD?.register(defaults: ["maxFilters": 2])
    UD?.register(defaults: ["chatFilters": [1 << 6, 1 << 5]])
    UD?.register(defaults: ["showTabNames": true])
    UD?.register(defaults: ["hideNumber": false])
    UD?.register(defaults: ["useBrowser": false])
    UD?.register(defaults: ["browser": "safari"])
}

let supportedFilters: [Int32] = [1, 2, 8, 16, 32, 64, 256, 1 << 9] //, 1 << 10] // pow 2

public class SimplyNiceSettings {
    let UD = UserDefaults(suiteName: "SimplyNiceSettings")
    let cloud = NSUbiquitousKeyValueStore.default
    var changed = false
    
    public init() {
        setDefaults()
    }
    
    deinit {
        if changed {
            print("Syncing Settings!")
            // // cloud.synchronize()
        }
    }
    
    public var hideNumber: Bool {
        get {
            if useIcloud() {
                return cloud.object(forKey: "hideNumber") as? Bool ?? false
            }
            return UD?.bool(forKey: "hideNumber") ?? false
        }
        set {
            // cloud.set(newValue, forKey: "hideNumber")
            // cloud.synchronize()
            changed = true
            UD?.set(newValue, forKey: "hideNumber")
        }
    }
    
    public var maxFilters: Int32 {
        // let k = "maxFilters"
        get {
            if useIcloud() {
                return cloud.object(forKey: "maxFilters") as? Int32 ?? 2
            }
            return Int32(UD?.integer(forKey: "maxFilters") ?? 2)
        }
        set {
            // cloud.set(newValue, forKey: "maxFilters")
            // cloud.synchronize()
            changed = true
            UD?.set(newValue, forKey: "maxFilters")
        }
    }
    
    public var chatFilters: [NiceChatListNodePeersFilter] {
        get {
            let array: [Int32]
            if useIcloud() {
                array = cloud.object(forKey: "chatFilters") as? [Int32] ?? [1 << 6, 1 << 5]
            } else {
                array = UD?.array(forKey: "chatFilters") as? [Int32] ?? [1 << 6, 1 << 5]
            }
            var res: [NiceChatListNodePeersFilter] = []
            for item in array {
                if supportedFilters.contains(item) && getAvailableFilters().contains(NiceChatListNodePeersFilter(rawValue: item)) {
                    res.append(NiceChatListNodePeersFilter(rawValue: item))
                } else {
                    res.append(NiceChatListNodePeersFilter(rawValue: 1 << 5))
                }
            }
            return res
        }
        set {
            var resSet: [Int32] = []
            for item in newValue {
                resSet.append(item.rawValue)
            }
            // cloud.set(resSet, forKey: "chatFilters")
            // cloud.synchronize()
            UD?.set(resSet, forKey: "chatFilters")
            changed = true
        }
        
    }
    
    public var showTabNames: Bool {
        get {
            if useIcloud() {
                return cloud.object(forKey: "showTabNames") as? Bool ?? true
            } else {
                return UD?.bool(forKey: "showTabNames") ?? true
            }
             
        }
        set {
            // cloud.set(newValue, forKey: "showTabNames")
            // cloud.synchronize()
            UD?.set(newValue, forKey: "showTabNames")
            changed = true
        }
    }
    
    public var useBrowser: Bool {
        get {
            return /*cloud.object(forKey: "useBrowser") as? Bool ??*/ UD?.bool(forKey: "useBrowser") ?? false
        }
        set {
            UD?.set(newValue, forKey: "useBrowser")
            //// cloud.set(newValue, forKey: "useBrowser")
            changed = true
        }
    }
    
    public var browser: String {
        get {
            return /*cloud.object(forKey: "browser") as? String ??*/ UD?.string(forKey: "browser") ?? "safari"
        }
        set {
            UD?.set(newValue, forKey: "browser")
            //// cloud.set(newValue, forKey: "browser")
            changed = true
        }
    }
    
    public var filtersBadge: Bool {
        get {
            if useIcloud() {
                return cloud.object(forKey: "filtersBadge") as? Bool ?? true
            } else {
                return UD?.bool(forKey: "filtersBadge") ?? true
            }
        }
        set {
            // cloud.set(newValue, forKey: "filtersBadge")
            // cloud.synchronize()
            UD?.set(newValue, forKey: "filtersBadge")
            changed = true
        }
    }
}

public var MessagesToCopy: [EnqueueMessage] = []
public var MessagesToCopyDict: [MessageId:EnqueueMessage] = [:]
// public var SelectedMessagesToCopy: [Message] = []

public func convertMessagesForEnqueue(_ messages: [Message]) -> [EnqueueMessage] {
    var messagesToC: [EnqueueMessage] = []
    for m in messages {
        var media: AnyMediaReference?
        if !m.media.isEmpty {
            media = .standalone(media: m.media[0])
        }
        let enqMsg: EnqueueMessage = .message(text: m.text, attributes: m.attributes, mediaReference: media, replyToMessageId: nil, localGroupingKey: m.groupingKey)
        messagesToC.append(enqMsg)
    }
    return messagesToC
}

public func convertMessagesForEnqueueDict(_ messages: [Message]) -> [MessageId:EnqueueMessage] {
    var messagesToC: [MessageId:EnqueueMessage] = [:]
    for m in messages {
        var media: AnyMediaReference?
        if !m.media.isEmpty {
            media = .standalone(media: m.media[0])
        }
        let enqMsg: EnqueueMessage = .message(text: m.text, attributes: m.attributes, mediaReference: media, replyToMessageId: nil, localGroupingKey: m.groupingKey)
        messagesToC[m.id] = enqMsg
    }
    return messagesToC
}



public func getAvailableFilters() -> [NiceChatListNodePeersFilter] {
    if isPremium() {
        return NiceChatListNodePeersFilter.all
    } else {
        let filters = [
            NiceChatListNodePeersFilter.onlyAdmin, NiceChatListNodePeersFilter.onlyBots, NiceChatListNodePeersFilter.onlyChannels, NiceChatListNodePeersFilter.onlyGroups, NiceChatListNodePeersFilter.onlyPrivateChats, NiceChatListNodePeersFilter.onlyUnread, NiceChatListNodePeersFilter.onlyNonMuted,
        ]
        return filters
    }
}


public func getEnabledFilters() -> [NiceChatListNodePeersFilter] {
    let available = getAvailableFilters()
    if isPremium() {
        var res: [NiceChatListNodePeersFilter] = []
        for filter in available {
            if isEnabledFilter(filter.rawValue) {
                res.append(filter)
            }
        }
        return res
    } else {
        return available
    }
}


public func setSystemNGDefaults() {
    let UD = UserDefaults.standard
    UD.register(defaults: ["ng_db_reset": false])
    UD.register(defaults: ["ng_db_export": false])
}

public class SystemNGSettings {
    let UD = UserDefaults.standard
    
    public init() {
        // setSystemNGDefaults()
    }
    
    public var dbReset: Bool {
        get {
            return UD.bool(forKey: "ng_db_reset")
        }
        set {
            UD.set(newValue, forKey: "ng_db_reset")
        }
    }
    
    public var dbExport: Bool {
        get {
            return UD.bool(forKey: "ng_db_export")
        }
        set {
            UD.set(newValue, forKey: "ng_db_export")
        }
    }
    
}

public let SETTINGS_VERSION = 4
public let BACKUP_NAME = "backup.ng-settings"
public func getSettingsFilePath() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
}

public class NicegramSettings {
    let UD = UserDefaults(suiteName: "NicegramSettings")
    let shared = UserDefaults(suiteName: "group.\(Bundle.main.bundleIdentifier!)")
    let exSimplyNiceSettings = SimplyNiceSettings()
    let exSimplyNiceFolders = SimplyNiceFolders()
    let exSimplyNiceFilters = SimplyNiceFilters()
    let exPremiumSettings = PremiumSettings()
    
    public init() {
        UD?.register(defaults: ["useBackCam": false])
        UD?.register(defaults: ["useTgFilters": false])
        shared?.register(defaults: ["muteSoundSilent": true])
        shared?.register(defaults: ["hideNotifyAccountName": false])
        UD?.register(defaults: ["useClassicInfoUi": false])
        
        #if CN
        UD?.register(defaults: ["sendWithKb": true])
        UD?.register(defaults: ["gmod": false])
        #endif
    }
    
    // SimplyNiceSettings
    public var hideNumber: Bool {
        get {
            return exSimplyNiceSettings.hideNumber
        }
        set {
            exSimplyNiceSettings.hideNumber = newValue
        }
    }
    
    
    public var maxFilters: Int32 {
        get {
            return exSimplyNiceSettings.maxFilters
        }
        set {
            exSimplyNiceSettings.maxFilters = newValue
        }
    }
    
    public var chatFilters: [NiceChatListNodePeersFilter] {
        get {
            return exSimplyNiceSettings.chatFilters
        }
        set {
            exSimplyNiceSettings.chatFilters = newValue
        }
    }
    
    public var showTabNames: Bool {
        get {
            return exSimplyNiceSettings.showTabNames
        }
        set {
            exSimplyNiceSettings.showTabNames = newValue
        }
    }
    
    public var filtersBadge: Bool {
        get {
            return exSimplyNiceSettings.filtersBadge
        }
        set {
            exSimplyNiceSettings.filtersBadge = newValue
        }
    }
    //
    
    // SimplyNiceFolders
    public var folders: [NiceFolder] {
        get {
            return exSimplyNiceFolders.folders
        }
        set {
            exSimplyNiceFolders.folders = newValue
        }
    }
    
    
    // SimplyNiceFilters
    public var disabledFilters: [Int32] {
        get {
            return exSimplyNiceFilters.disabledFilters
        }
        set {
            exSimplyNiceFilters.disabledFilters = newValue
        }
    }
    
    public var filters: [CustomFilter] {
        get {
            return exSimplyNiceFilters.filters
        }
        set {
            exSimplyNiceFilters.filters = newValue
        }
    }
    //
    
    // PremiumSettings
    public var syncPins: Bool {
        get {
            return exPremiumSettings.syncPins
        }
        set {
            exPremiumSettings.syncPins = newValue
        }
    }
    
    public var lastOpened: Int {
        get {
            return exPremiumSettings.lastOpened
        }
        set {
            exPremiumSettings.lastOpened = newValue
        }
    }
    
    public var notifyMissed: Bool {
        get {
            return exPremiumSettings.notifyMissed
        }
        set {
            exPremiumSettings.notifyMissed = newValue
        }
    }
    
    public var notifyMissedEach: Int {
        get {
            return exPremiumSettings.notifyMissedEach
        }
        set {
            exPremiumSettings.notifyMissedEach = newValue
        }
    }
    
    public var oneTapTr: Bool {
        get {
            return exPremiumSettings.oneTapTr
        }
        set {
            exPremiumSettings.oneTapTr = newValue
        }
    }
    
    public var ignoreTranslate: [String] {
        get {
            return exPremiumSettings.ignoreTranslate
        }
        set {
            exPremiumSettings.ignoreTranslate = newValue
        }
    }
    //
    
    public var useBackCam: Bool {
        get {
            return UD?.bool(forKey: "useBackCam") ?? false
        }
        set {
            UD?.set(newValue, forKey: "useBackCam")
        }
    }
    
    public var useTgFilters: Bool {
        get {
            return UD?.bool(forKey: "useTgFilters") ?? true
            }
        set {
            UD?.set(newValue, forKey: "useTgFilters")
        }
    }
    
    public var muteSoundSilent: Bool {
        get {
            return shared?.bool(forKey: "muteSoundSilent") ?? false
        }
        set {
            shared?.set(newValue, forKey: "muteSoundSilent")
        }
    }
    
    public var hideNotifyAccountName: Bool {
        get {
            return shared?.bool(forKey: "hideNotifyAccountName") ?? false
        }
        set {
            shared?.set(newValue, forKey: "hideNotifyAccountName")
        }
    }
    
    public var useClassicInfoUi: Bool {
        get {
            return UD?.bool(forKey: "useClassicInfoUi") ?? false
        }
        set {
            UD?.set(newValue, forKey: "useClassicInfoUi")
        }
    }
    
    public var sendWithKb: Bool {
        get {
            return UD?.bool(forKey: "sendWithKb") ?? true
        }
        set {
            UD?.set(newValue, forKey: "sendWithKb")
        }
    }
    
    public var gmod: Bool {
        get {
            return UD?.bool(forKey: "gmod") ?? false
        }
        set {
            UD?.set(newValue, forKey: "gmod")
        }
    }
    
    public var json: [String: Any] {
        var cnExclusiveSettings: [String: Any] = [
            "sendWithKb": self.sendWithKb,
            "gmod": self.gmod
        ]
        var jsNiceSettings: [String: Any] = [
            "hideNumber": self.hideNumber,
            "maxFilters": self.maxFilters,
            "showTabNames": self.showTabNames,
            "filtersBadge": self.filtersBadge,
            "useBackCam": self.useBackCam,
            "hideNotifyAccountName": self.hideNotifyAccountName,
            "useClassicInfoUi": self.useClassicInfoUi,
        ]
        
        var intChatFilters: [Int32] = []
        for chatFilter in self.chatFilters {
            intChatFilters.append(chatFilter.rawValue)
        }
        
        jsNiceSettings["chatFilters"] = intChatFilters
        
        var jsNiceFolders: [String: Any] = [
            "folders": exSimplyNiceFolders.json
        ]
        
        var jsNiceFilters: [String: Any] = [
            "disabledFilters": self.disabledFilters,
            "filters": exSimplyNiceFilters.jsonFilters
        ]
        
        var jsPremiumSettings: [String: Any] = [
            "syncPins": self.syncPins,
            "notifyMissed": self.notifyMissed,
            "notifyMissedEach": self.notifyMissedEach,
            "oneTapTr": self.oneTapTr,
            "ignoreTranslate": self.ignoreTranslate
        ]
        
        let data: [String: Any] = [
            "version": SETTINGS_VERSION,
            "NiceSettings": jsNiceSettings,
            "NiceFolders": jsNiceFolders,
            "NiceFilters": jsNiceFilters,
            "PremiumSettings": jsPremiumSettings,
            "CNSettings": cnExclusiveSettings
        ]
        return data
    }
    
    public func exportSettings() -> String? {
        do {
            let data = try JSONSerialization.data(
                withJSONObject: self.json,
                options: []
            )
            var path = getSettingsFilePath()
            path.appendPathComponent(BACKUP_NAME)
            try FileManager.default.createFile(atPath: path.path, contents: data, attributes: nil)
            return path.path
        } catch {
            return nil
        }
    }
    
    
    
    public func importSettings(json: [String: Any]) -> [(String, String, Bool)] {
        var result: [(String, String, Bool)] = []
        if let version = json["version"] as? Int {
            result.append(("version", String(version), true))
        } else {
            return result
        }
        
        if let niceSettings = json["NiceSettings"] as? [String:Any] {
            result.append(("NiceSettings", "", true))
            if let hideNumber = niceSettings["hideNumber"] as? Bool {
                self.hideNumber = hideNumber
                result.append(("hideNumber", String(hideNumber), true))
            } else {
                result.append(("hideNumber", "", false))
            }
            
            if let maxFilters = niceSettings["maxFilters"] as? Int32 {
                self.maxFilters = maxFilters
                result.append(("maxFilters", String(maxFilters), true))
            } else {
                result.append(("maxFilters", "", false))
            }
            
            if let showTabNames = niceSettings["showTabNames"] as? Bool {
                self.showTabNames = showTabNames
                result.append(("showTabNames", String(maxFilters), true))
            } else {
                result.append(("showTabNames", "", false))
            }
            
            if let filtersBadge = niceSettings["filtersBadge"] as? Bool {
                self.filtersBadge = filtersBadge
                result.append(("filtersBadge", String(filtersBadge), true))
            } else {
                result.append(("filtersBadge", "", false))
            }
            
            if let chatFilters = niceSettings["chatFilters"] as? [Int32] {
                var converted: [NiceChatListNodePeersFilter] = []
                for chatFilter in chatFilters {
                    converted.append(NiceChatListNodePeersFilter(rawValue: chatFilter))
                }
                self.chatFilters = converted
                result.append(("chatFilters", String(converted.count), true))
            } else {
                result.append(("chatFilters", "", false))
            }
            
            if let useBackCam = niceSettings["useBackCam"] as? Bool {
                self.useBackCam = useBackCam
                result.append(("useBackCam", String(useBackCam), true))
            } else {
                result.append(("useBackCam", "", false))
            }
            
            if let hideNotifyAccountName = niceSettings["hideNotifyAccountName"] as? Bool {
                self.hideNotifyAccountName = hideNotifyAccountName
                result.append(("hideNotifyAccountName", String(hideNotifyAccountName), true))
            } else {
                result.append(("hideNotifyAccountName", "", false))
            }
            
            if let useClassicInfoUi = niceSettings["useClassicInfoUi"] as? Bool {
                self.useClassicInfoUi = useClassicInfoUi
                result.append(("useClassicInfoUi", String(useClassicInfoUi), true))
            } else {
                result.append(("useClassicInfoUi", "", false))
            }
        } else {
             result.append(("NiceSettings", "", false))
        }
        
        if let niceFolders = json["NiceFolders"] as? [String:Any] {
            result.append(("NiceFolders", "", true))
            if let folders = niceFolders["folders"] as? [[String:Any]] {
                var converted: [NiceFolder] = []
                for folder in folders {
                    if let groupId = folder["groupId"] as? Int32, let name = folder["name"] as? String, let items = folder["items"] as? [Int64] {
                        converted.append(NiceFolder(groupId: groupId, name: name, items: items))
                    }
                }
                self.folders = converted
                result.append(("folders", String(converted.count), true))
            } else {
                result.append(("folders", "", false))
            }
        } else {
            result.append(("NiceFolders", "", false))
        }
        
        if let premiumSettings = json["PremiumSettings"] as? [String:Any] {
            result.append(("PremiumSettings", "", true))
            if let syncPins = premiumSettings["syncPins"] as? Bool {
                self.syncPins = syncPins
                result.append(("syncPins", String(syncPins), true))
            } else {
                result.append(("syncPins", "", false))
            }
            
            if let notifyMissed = premiumSettings["notifyMissed"] as? Bool {
                self.notifyMissed = notifyMissed
                result.append(("notifyMissed", String(notifyMissed), true))
            } else {
                result.append(("notifyMissed", "", false))
            }
            
            if let notifyMissedEach = premiumSettings["notifyMissedEach"] as? Int {
                self.notifyMissedEach = notifyMissedEach
                result.append(("notifyMissedEach", String(notifyMissedEach), true))
            } else {
                result.append(("notifyMissedEach", "", false))
            }
            
            if let oneTapTr = premiumSettings["oneTapTr"] as? Bool {
                self.oneTapTr = oneTapTr
                result.append(("oneTapTr", String(oneTapTr), true))
            } else {
                result.append(("oneTapTr", "", false))
            }
            
            if let ignoreTranslate = premiumSettings["ignoreTranslate"] as? [String] {
                self.ignoreTranslate = ignoreTranslate
                result.append(("ignoreTranslate", String(ignoreTranslate.count), true))
            } else {
                result.append(("ignoreTranslate", "", false))
            }
        } else {
            result.append(("PremiumSettings", "", false))
        }
        
        if let niceFilters = json["NiceFilters"] as? [String:Any] {
            result.append(("NiceFilters", "", true))
            if let disabledFilters = niceFilters["disabledFilters"] as? [Int32] {
                self.disabledFilters = disabledFilters
                result.append(("disabledFilters", String(disabledFilters.count), true))
            } else {
                result.append(("disabledFilters", "", false))
            }
            
            if let filters = niceFilters["filters"] as? [[String: Any]] {
                var converted: [CustomFilter] = []
                for filter in filters {
                    if let id = filter["id"] as? Int32, let name = filter["name"] as? String, let includeItems = filter["includeItems"] as? [String], let unIncludeItems = filter["unIncludeItems"] as? [String] {
                        converted.append(CustomFilter(id: id, name: name, includeItems: includeItems, unIncludeItems: unIncludeItems))
                    }
                }
                self.filters = converted
                result.append(("filters", String(converted.count), true))
            } else {
                result.append(("filters", "", false))
            }
        } else {
            result.append(("NiceFilters", "", false))
        }
        
        if let CNSettings = json["CNSettings"] as? [String: Any] {
            result.append(("CNSettings", "", true))
            if let sendWithKb = CNSettings["sendWithKb"] as? Bool {
                self.sendWithKb = sendWithKb
                result.append(("sendWithKb", String(sendWithKb), true))
            } else {
                result.append(("sendWithKb", "", false))
            }
            
            if let gmod = CNSettings["gmod"] as? Bool {
                self.gmod = gmod
                result.append(("gmod", String(gmod), true))
            } else {
                result.append(("gmod", "", false))
            }
        } else {
            result.append(("CNSettings", "", false))
        }
        
        return result
    }
}
