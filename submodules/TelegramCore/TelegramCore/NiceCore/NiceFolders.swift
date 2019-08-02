//
//  NiceFolders.swift
//  TelegramCore
//
//  Created by Sergey Ak on 01/08/2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import Postbox

public func generateFolderGroupId() -> Int32 {
    
    var folderGroupIds: [Int32] = []
    let folders = getNiceFolders()
    for folder in folders {
        folderGroupIds.append(folder.groupId)
    }
    let maxId = folderGroupIds.max()
    var id: Int32 = maxId ?? 1
    while true {
        id = id + 1
        if isNiceFolderCheck(id) && getFolder(id) == nil {
            return id
        }
    }
}

public class NiceFolder: NSObject, NSCoding {
    public var groupId: Int32 {
        didSet {
            self.save()
        }
    }
    public var name: String {
        didSet {
            self.save()
        }
    }
    public var items: [Int64] {
        didSet {
            self.save()
        }
    }
    
    
    public init(groupId: Int32, name: String, items: [Int64]) {
        self.groupId = groupId
        self.name = name
        self.items = items
        
    }
    
    required convenience public init(coder aDecoder: NSCoder) {
        let groupId = aDecoder.decodeInt32(forKey: "groupId")
        let name = aDecoder.decodeObject(forKey: "name") as! String
        let items = aDecoder.decodeObject(forKey: "items") as! [Int64]
        self.init(groupId: groupId, name: name, items: items)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(groupId, forKey: "groupId")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(items, forKey: "items")
    }
    
    override public var description: String {
        return "NiceFolder(\(groupId), \(name), \(items.count), \(items))"
    }
    
    public func save() {
        let currentFolderIndex = searchFolderIndex(groupId)
        if currentFolderIndex != nil {
            setNiceFolderAt(currentFolderIndex!, self)
        } else {
            let newFolder = createFolder(name, items)
            self.groupId = newFolder.groupId
        }
    }
}


public func setFoldersDefaults() {
    let UD = UserDefaults(suiteName: "SimplyNiceFolders")
    UD?.register(defaults: ["folders": NSKeyedArchiver.archivedData(withRootObject: [])])
}

public func resetFolders() {
    let UD = UserDefaults(suiteName: "SimplyNiceFolders")
    UD?.removePersistentDomain(forName: "SimplyNiceFolders")
}

public class SimplyNiceFolders {
    let UD = UserDefaults(suiteName: "SimplyNiceFolders")
    
    init() {
        setFoldersDefaults()
    }
    
    
    var folders: [NiceFolder] {
        get {
            return NSKeyedUnarchiver.unarchiveObject(with: (UD?.data(forKey: "folders"))!) as! [NiceFolder]
        }
        set {
            UD?.set(NSKeyedArchiver.archivedData(withRootObject: newValue), forKey: "folders")
        }
    }
    
}

public func isNiceFolderCheck(_ groupId: Int32) -> Bool {
    let tgGroups: [Int32] = [0, 1]
    var isNFolder = false
    
    if !tgGroups.contains(groupId) {
        isNFolder = true
    }
    
    return isNFolder
}

public func getNiceFolders() ->  [NiceFolder] {
    return SimplyNiceFolders().folders
}

public func setNiceFolders(_ folders: [NiceFolder]) -> Void {
    SimplyNiceFolders().folders = folders
}

public func setNiceFolderAt(_ index: Int, _ folder: NiceFolder) -> Void {
    SimplyNiceFolders().folders[index] = folder
}

public func getFolder(_ groupId: Int32) -> NiceFolder? {
    for folder in SimplyNiceFolders().folders {
        if folder.groupId == groupId {
            return folder
        }
    }
    return nil
}

public func searchFolderIndex(_ groupId: Int32) -> Int? {
    for (index, folder) in SimplyNiceFolders().folders.enumerated() {
        if folder.groupId == groupId {
            return index
        }
    }
    return nil
}


public func createFolder(_ name: String, _ items: [Int64]) -> NiceFolder {
    let groupId = generateFolderGroupId()
    let folder = NiceFolder(groupId: groupId, name: name, items: items)
    SimplyNiceFolders().folders.append(folder)
    return folder
}


public func deleteFolder(_ groupId: Int32) -> Void {
    let folderIndex = searchFolderIndex(groupId)
    if folderIndex != nil {
        SimplyNiceFolders().folders.remove(at: folderIndex!)
    }
}

public func getPeerFolder(_ peerId: Int64) -> NiceFolder? {
    for folder in getNiceFolders() {
        for item in folder.items {
            if item == peerId {
                return folder
            }
        }
    }
    return nil
}

public func peersToInt64(_ peers: [PeerId]) -> [Int64] {
    var res: [Int64] = []
    
    for peer in peers {
        res.append(peer.toInt64())
    }
    return res
}

public func removeNiceFolderItems(_ folder: NiceFolder, _ peerIds: [Int64]) {
    var peersToRemove: [Int64] = []
    for peerId in peerIds {
        peersToRemove.append(peerId)
    }
    Logger.shared.log("NiceFolders", "Removed items from folder")
    let newFolderItems = Array(Set(folder.items).subtracting(peersToRemove))
    if newFolderItems.isEmpty {
        Logger.shared.log("NiceFolders", "Automatically deleting folder \(folder)")
        deleteFolder(folder.groupId)
        return
    }
    folder.items = newFolderItems
}
