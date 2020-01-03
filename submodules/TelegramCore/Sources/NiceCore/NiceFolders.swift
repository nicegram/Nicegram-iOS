//
//  NiceFolders.swift
//  TelegramCore
//
//  Created by Sergey Ak on 01/08/2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import Postbox

enum FLogManagedFileMode {
    case read
    case readwrite
    case append
}

private func wrappedWrite(_ fd: Int32, _ data: UnsafeRawPointer, _ count: Int) -> Int {
    return write(fd, data, count)
}

private func wrappedRead(_ fd: Int32, _ data: UnsafeMutableRawPointer, _ count: Int) -> Int {
    return read(fd, data, count)
}

final class FLogManagedFile {
    private let fd: Int32
    private let mode: FLogManagedFileMode
    
    init?(path: String, mode: FLogManagedFileMode) {
        self.mode = mode
        let fileMode: Int32
        let accessMode: UInt16
        switch mode {
        case .read:
            fileMode = O_RDONLY
            accessMode = S_IRUSR
        case .readwrite:
            fileMode = O_RDWR | O_CREAT
            accessMode = S_IRUSR | S_IWUSR
        case .append:
            fileMode = O_WRONLY | O_CREAT | O_APPEND
            accessMode = S_IRUSR | S_IWUSR
        }
        let fd = open(path, fileMode, accessMode)
        if fd >= 0 {
            self.fd = fd
        } else {
            return nil
        }
    }
    
    deinit {
        close(self.fd)
    }
    
    func write(_ data: UnsafeRawPointer, count: Int) -> Int {
        return wrappedWrite(self.fd, data, count)
    }
    
    func read(_ data: UnsafeMutableRawPointer, _ count: Int) -> Int {
        return wrappedRead(self.fd, data, count)
    }
    
    func readData(count: Int) -> Data {
        var result = Data(count: count)
        result.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<Int8>) -> Void in
            let readCount = self.read(bytes, count)
            assert(readCount == count)
        }
        return result
    }
    
    func seek(position: Int64) {
        lseek(self.fd, position, SEEK_SET)
    }
    
    func truncate(count: Int64) {
        ftruncate(self.fd, count)
    }
    
    func getSize() -> Int? {
        var value = stat()
        if fstat(self.fd, &value) == 0 {
            return Int(value.st_size)
        } else {
            return nil
        }
    }
    
    func sync() {
        fsync(self.fd)
    }
}


public var folderLogger: FolderLogger?

public final class FolderLogger {
    private let maxLength: Int = 2 * 1024 * 1024
    private let maxFiles: Int = 20
    
    private let basePath: String
    private var file: (FLogManagedFile, Int)?
    
    var logToFile: Bool = true
    var logToConsole: Bool = true
    
    public static func setSharedLogger(_ logger: FolderLogger) {
        folderLogger = logger
    }
    
    public static var shared: FolderLogger {
        if let folderLogger = folderLogger {
            return folderLogger
        } else {
            assertionFailure()
            let tempLogger = FolderLogger(basePath: "")
            tempLogger.logToFile = false
            tempLogger.logToConsole = false
            return tempLogger
        }
    }
    
    public init(basePath: String) {
        self.basePath = basePath
        //self.logToConsole = false
    }
    
    public func log(_ tag: String, _ what: @autoclosure () -> String) {
        if !self.logToFile && !self.logToConsole {
            return
        }
        
        let string = what()
        
        var rawTime = time_t()
        time(&rawTime)
        var timeinfo = tm()
        localtime_r(&rawTime, &timeinfo)
        
        var curTime = timeval()
        gettimeofday(&curTime, nil)
        let milliseconds = curTime.tv_usec / 1000
        
        var consoleContent: String?
        if self.logToConsole {
            let content = String(format: "[%@] %d-%d-%d %02d:%02d:%02d.%03d %@", arguments: [tag, Int(timeinfo.tm_year) + 1900, Int(timeinfo.tm_mon + 1), Int(timeinfo.tm_mday), Int(timeinfo.tm_hour), Int(timeinfo.tm_min), Int(timeinfo.tm_sec), Int(milliseconds), string])
            consoleContent = content
            print(content)
        }
        
        if self.logToFile {
            let content: String
            if let consoleContent = consoleContent {
                content = consoleContent
            } else {
                content = String(format: "[%@] %d-%d-%d %02d:%02d:%02d.%03d %@", arguments: [tag, Int(timeinfo.tm_year) + 1900, Int(timeinfo.tm_mon + 1), Int(timeinfo.tm_mday), Int(timeinfo.tm_hour), Int(timeinfo.tm_min), Int(timeinfo.tm_sec), Int(milliseconds), string])
            }
            
            var currentFile: FLogManagedFile?
            var openNew = false
            if let (file, length) = self.file {
                if length >= self.maxLength {
                    self.file = nil
                    openNew = true
                } else {
                    currentFile = file
                }
            } else {
                openNew = true
            }
            if openNew {
                let _ = try? FileManager.default.createDirectory(atPath: self.basePath, withIntermediateDirectories: true, attributes: nil)
                
                var createNew = false
                if let files = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: self.basePath), includingPropertiesForKeys: [URLResourceKey.creationDateKey], options: []) {
                    var minCreationDate: (Date, URL)?
                    var maxCreationDate: (Date, URL)?
                    var count = 0
                    for url in files {
                        if url.lastPathComponent.hasPrefix("log-") {
                            if let values = try? url.resourceValues(forKeys: Set([URLResourceKey.creationDateKey])), let creationDate = values.creationDate {
                                count += 1
                                if minCreationDate == nil || minCreationDate!.0 > creationDate {
                                    minCreationDate = (creationDate, url)
                                }
                                if maxCreationDate == nil || maxCreationDate!.0 < creationDate {
                                    maxCreationDate = (creationDate, url)
                                }
                            }
                        }
                    }
                    if let (_, url) = minCreationDate, count >= self.maxFiles {
                        let _ = try? FileManager.default.removeItem(at: url)
                    }
                    if let (_, url) = maxCreationDate {
                        var value = stat()
                        if stat(url.path, &value) == 0 && Int(value.st_size) < self.maxLength {
                            if let file = FLogManagedFile(path: url.path, mode: .append) {
                                self.file = (file, Int(value.st_size))
                                currentFile = file
                            }
                        } else {
                            createNew = true
                        }
                    } else {
                        createNew = true
                    }
                }
                
                if createNew {
                    let fileName = String(format: "log-%d-%d-%d_%02d-%02d-%02d.%03d.txt", arguments: [Int(timeinfo.tm_year) + 1900, Int(timeinfo.tm_mon + 1), Int(timeinfo.tm_mday), Int(timeinfo.tm_hour), Int(timeinfo.tm_min), Int(timeinfo.tm_sec), Int(milliseconds)])
                    
                    let path = self.basePath + "/" + fileName
                    
                    if let file = FLogManagedFile(path: path, mode: .append) {
                        self.file = (file, 0)
                        currentFile = file
                    }
                }
            }
            
            if let currentFile = currentFile {
                if let data = content.data(using: .utf8) {
                    data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
                        let _ = currentFile.write(bytes, count: data.count)
                    }
                    var newline: UInt8 = 0x0a
                    let _ = currentFile.write(&newline, count: 1)
                    if let file = self.file {
                        self.file = (file.0, file.1 + data.count + 1)
                    } else {
                        assertionFailure()
                    }
                }
            }
        }
    }
}


public func fLog(_ text: String, _ tag: String = "Folders") {
    let baseAppBundleId = Bundle.main.bundleIdentifier!
    let appGroupName = "group.\(baseAppBundleId)"
    let maybeAppGroupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName)
    
    if let appGroupUrl = maybeAppGroupUrl {
        let rootPath = appGroupUrl.path + "/telegram-data"
        
        if folderLogger == nil {
            let logsPath = rootPath + "/niceFolderLogs"
            FolderLogger.setSharedLogger(FolderLogger(basePath: logsPath))
        }
    } else {
        let appBundleIdentifier = Bundle.main.bundleIdentifier!
        guard let lastDotRange = appBundleIdentifier.range(of: ".", options: [.backwards]) else {
            Logger.shared.log(tag + " (Main Logger)", text)
            return
        }
        
        let baseAppBundleId = String(appBundleIdentifier[..<lastDotRange.lowerBound])
        let appGroupName = "group.\(baseAppBundleId)"
        let maybeAppGroupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName)
        
        if let appGroupUrl = maybeAppGroupUrl {
            let rootPath = appGroupUrl.path + "/telegram-data"
            
            if folderLogger == nil {
                let logsPath = rootPath + "/niceFolderLogs"
                FolderLogger.setSharedLogger(FolderLogger(basePath: logsPath))
            }
        } else {
            Logger.shared.log(tag + " (Main Logger)", text)
        }
    }

    
    FolderLogger.shared.log(tag, text)
}

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
        return "NiceFolder(group(\(groupId)), \(name), (\(items.count)), \(items))"
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
    fLog("Folders RESET")
    let UD = UserDefaults(suiteName: "SimplyNiceFolders")
    UD?.removePersistentDomain(forName: "SimplyNiceFolders")
    
    let cloud = NSUbiquitousKeyValueStore.default
    cloud.removeObject(forKey: "folders")
}

public class SimplyNiceFolders {
    let UD = UserDefaults(suiteName: "SimplyNiceFolders")
    let cloud = NSUbiquitousKeyValueStore.default
    var changed = false
    
    public init() {
        setFoldersDefaults()
    }
    
    deinit {
        if changed {
            print("Syncing Folders!")
            cloud.synchronize()
        }
    }
    
    public var folders: [NiceFolder] {
        get {
            // return NSKeyedUnarchiver.unarchiveObject(with: (UD?.data(forKey: "folders"))!) as! [NiceFolder]
            if let foldersData = cloud.data(forKey: "folders") {
                return NSKeyedUnarchiver.unarchiveObject(with: foldersData) as! [NiceFolder]
            } else {
                return NSKeyedUnarchiver.unarchiveObject(with: (UD?.data(forKey: "folders"))!) as! [NiceFolder]
            }
        }
        set {
            // UD?.set(NSKeyedArchiver.archivedData(withRootObject: newValue), forKey: "folders")
            cloud.set(NSKeyedArchiver.archivedData(withRootObject: newValue), forKey: "folders")
            changed = true
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
    let newFolderItems = Array(Set(folder.items).subtracting(peersToRemove))
    fLog("Removed items \(peersToRemove) from folder \(folder)")
    if newFolderItems.isEmpty {
        fLog("Automatically deleting folder \(folder)")
        deleteFolder(folder.groupId)
        return
    }
    folder.items = newFolderItems
}

public func sureRemovePeerFromFolder(_ peerId: PeerId) {
    let folder = getPeerFolder(peerId.toInt64())
    if folder != nil {
        removeNiceFolderItems(folder!, peersToInt64([peerId]))
    }
}


public func syncFolders(_ postbox: Postbox) {
    fLog("Syncing folders")
    for folder in SimplyNiceFolders().folders {
        for peerId in folder.items {
            let _ = updatePeerGroupIdInteractively(postbox: postbox, peerId: PeerId(peerId), groupId: PeerGroupId(rawValue: folder.groupId)).start(completed: {
                fLog("Sync done for \(peerId) in \(folder)")
            })
        }
    }
}

