//
//  NiceManageFilters.swift
//  TelegramCore
//
//  Created by Sergey on 11.11.2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import Postbox


func setFiltersDefault() {
    let UD = UserDefaults(suiteName: "SimplyNiceFilters")
    UD?.register(defaults: ["disabledFilters": []])
    UD?.register(defaults: ["customFilters":[]])
}



public func getCustomFilter(_ id: Int32) -> CustomFilter? {
    let filters = VarSimplyNiceFilters.filters
    for filter in filters {
        if filter.id == id {
            return filter
        }
    }
    return nil
}


public func generateFilterId() -> Int32 {
    
    var filterIds: [Int32] = []
    let filter = VarSimplyNiceFilters.filters
    for filter in filter {
        filterIds.append(filter.id)
    }
    let maxId = filterIds.max()
    var id: Int32 = maxId ?? 1
    while true {
        id = id + 1
        if getCustomFilter(id) == nil {
            return id
        }
    }
}


public func createOrGetCustomFilter(id: Int32? = nil, _ name: String = "Custom", _ includeItems: [String] = [], _ unIncludeItems: [String] = []) -> CustomFilter {
    if let id = id {
        if let customFilter = getCustomFilter(id) {
            if let exisitngIndex = VarSimplyNiceFilters.filters.firstIndex(of: customFilter) {
                VarSimplyNiceFilters.filters[exisitngIndex] = customFilter
                return customFilter
            }
        }
    }
    
    let id = generateFilterId()
    let filter = CustomFilter(id: id, name: name, includeItems: includeItems, unIncludeItems: unIncludeItems)
    VarSimplyNiceFilters.filters.append(filter)
    return filter
}



public func getCustomFilterSetting(customFilter: CustomFilter, setting: String) -> Bool {
    let parsedSetting = setting.components(separatedBy: ["."])
    // (includeType, type)
    
    let includeType = parsedSetting[0]
    let type = parsedSetting[1]
    
    var searchDict = customFilter.includeItems
    
    if includeType == "include" {
    } else { // uninclude
        searchDict = customFilter.unIncludeItems
    }
    
    for item in searchDict {
        if item == type {
            return true
        }
    }
    
    return false
}



public func isEnabledCustomFilterSetting(id: Int32, setting: String) -> Bool {
    let customFilter = createOrGetCustomFilter(id: id)
    
    let parsedSetting = setting.components(separatedBy: ["."])
    // (includeType, type)
    
    let includeType = parsedSetting[0]
    let type = parsedSetting[1]
    let sound = parsedSetting[2]
    
    var searchDict = customFilter.includeItems
    
    if includeType == "include" {
    } else { // uninclude
        searchDict = customFilter.unIncludeItems
    }
    
    for item in searchDict {
        if item.starts(with: type) {
            return true
        }
    }
    
    return false
}

public class CustomFilter: NSObject, NSCoding {
    public var id: Int32 {
        didSet {
            self.save()
        }
    }
    public var name: String {
        didSet {
            self.save()
        }
    }
    public var includeItems: [String] {
        didSet {
            self.save()
        }
    }
    public var unIncludeItems: [String] {
        didSet {
            self.save()
        }
    }
    
    
    public init(id: Int32, name: String, includeItems: [String], unIncludeItems: [String]) {
        self.id = id
        self.name = name
        self.includeItems = includeItems
        self.unIncludeItems = unIncludeItems
    }
    
    required convenience public init(coder aDecoder: NSCoder) {
        let id = aDecoder.decodeInt32(forKey: "id")
        let name = aDecoder.decodeObject(forKey: "name") as! String
        let incldudeItems = aDecoder.decodeObject(forKey: "includeItems") as! [String]
        let unIncldudeItems = aDecoder.decodeObject(forKey: "unIncludeItems") as! [String]
        self.init(id: id, name: name, includeItems: incldudeItems, unIncludeItems: unIncldudeItems)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(includeItems, forKey: "includeItems")
        aCoder.encode(unIncludeItems, forKey: "unIncludeItems")
    }
    
    override public var description: String {
        return "CustomFilter(id(\(id)), \(name), (\(includeItems)), \(unIncludeItems))"
    }
    
    public func save() {
        let savedFilter = createOrGetCustomFilter(id: self.id, self.name, self.includeItems, self.unIncludeItems)
        if savedFilter.id != self.id {
            self.id = savedFilter.id
        }
    }
}

public var VarSimplyNiceFilters = SimplyNiceFilters()

public class SimplyNiceFilters {
    let UD = UserDefaults(suiteName: "SimplyNiceFilters")
    let cloud = NSUbiquitousKeyValueStore.default
    var changed = false
    
    public init() {
        setFiltersDefault()
    }
    
    deinit {
        if changed {
            print("Syncing Filters!")
            // // cloud.synchronize()
        }
    }
    
    public var disabledFilters: [Int32] {
        get {
            if useIcloud() {
                if let arrayData = cloud.object(forKey: "disabledFilters") {
                    if let intArrayData = arrayData as? [Int32] {
                        return intArrayData
                    }
                }
                return []
            } else {
                return UD?.array(forKey: "disabledFilters") as? [Int32] ?? []
            }
        }
        set {
            var resSet: [Int32] = []
            for item in newValue {
                resSet.append(item)
            }
            // cloud.set(resSet, forKey: "disabledFilters")
            // cloud.synchronize()
            UD?.set(resSet, forKey: "disabledFilters")
            changed = true
        }
        
    }
    
    public var filters: [CustomFilter] {
        get {
            if useIcloud() {
                if let filtersData = cloud.data(forKey: "customFilters") {
                    if let strongCloudFilters = NSKeyedUnarchiver.unarchiveObject(with: filtersData) as? [CustomFilter] {
                        return strongCloudFilters
                    }
                }
                return []
            } else {
                if let localFiltersData = UD?.data(forKey: "customFilters") {
                    if let strongLocalFilters = NSKeyedUnarchiver.unarchiveObject(with: localFiltersData) as? [CustomFilter] {
                        return strongLocalFilters
                    }
                }
                return []
            }
        }
        set {
            // cloud.set(NSKeyedArchiver.archivedData(withRootObject: newValue), forKey: "customFilters")
            // cloud.synchronize()
            UD?.set(NSKeyedArchiver.archivedData(withRootObject: newValue), forKey: "customFilters")
            changed = true
        }
    }
    
    public var jsonFilters: [[String:Any]] {
           var result: [[String:Any]] = []
           for filter in self.filters {
               let filterData: [String: Any] = [
                   "id": filter.id,
                   "name": filter.name,
                   "includeItems": filter.includeItems,
                   "unIncludeItems": filter.unIncludeItems
               ]
               result.append(filterData)
           }
           return result
       }
    
}


public func enableFilter(_ filter: Int32) -> Void {
    guard let index = VarSimplyNiceFilters.disabledFilters.firstIndex(of: filter) else { return }
    VarSimplyNiceFilters.disabledFilters.remove(at: index)
}


public func disableFilter(_ filter: Int32) -> Void {
    guard let _ = VarSimplyNiceFilters.disabledFilters.firstIndex(of: filter) else {
        VarSimplyNiceFilters.disabledFilters.append(filter)
        return
    }
}

public func isEnabledFilter(_ filter: Int32) -> Bool {
    guard let _ = VarSimplyNiceFilters.disabledFilters.firstIndex(of: filter) else {
        return true
    }
    return false
}

public let SoundFilters: [String] = [
        "all",
        "muted",
        "unmuted",
        "soundAndTags"
]

public let IncludeFilters: [String] = [
        "users",
        "secret-chats",
        "bots",
        "groups",
        "supergroups",
        "channels",
        "admin",
        "owner",
        "tagged"
]
