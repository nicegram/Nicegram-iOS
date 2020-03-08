//
//  NicegramPremium.swift
//  NiceCore
//
//  Created by Sergey Akentev on 23.10.2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import NicegramLib

public func setPremiumDefaults() {
    let UD = UserDefaults(suiteName: "PremiumSettings")
    UD?.register(defaults: ["syncPins": true,
    "p": false,
    "isPremium": false,
    "isBetaPremium": false,
    "lastOpenedApp": utcnow(),
    "notifyMissed": false,
    "notifyMissedEach": 5 * 60 *  60,
    "oneTapTr": true,
    "ignoreTranslate": []
    ])
}

public var VarPremiumSettings = PremiumSettings()

public class PremiumSettings {
    let UD = UserDefaults(suiteName: "PremiumSettings")
    let cloud = NSUbiquitousKeyValueStore.default
    var changed = false
    
    public init() {
        setPremiumDefaults()
    }
    
    deinit {
        if changed {
            print("Syncing Premium Settings!")
            // // cloud.synchronize()
        }
    }
    
    public var syncPins: Bool {
        get {
            if useIcloud() {
                return cloud.object(forKey: "syncPins") as? Bool ?? true
            } else {
                return UD?.bool(forKey: "syncPins") ?? true
            }
        }
        set {
            // cloud.set(newValue, forKey: "syncPins")
            // cloud.synchronize()
            UD?.set(newValue, forKey: "syncPins")
            changed = true
        }
    }
    
    public var isPremium: Bool {
        get {
            return UD?.bool(forKey: "isPremium") ?? false
        }
        set {
            UD?.set(newValue, forKey: "isPremium")
        }
    }
    
    public var isBetaPremium: Bool {
        get {
            return UD?.bool(forKey: "isBetaPremium") ?? false
        }
        set {
            UD?.set(newValue, forKey: "isBetaPremium")
        }
    }
    
    public var p: Bool {
        get {
            return UD?.bool(forKey: "p") ?? false
        }
        set {
            UD?.set(newValue, forKey: "p")
        }
    }
    
    public var lastOpened: Int {
        get {
            return UD?.integer(forKey: "lastOpened") ?? utcnow()
        }
        set {
            UD?.set(newValue, forKey: "lastOpened")
        }
    }
    
    public var notifyMissed: Bool {
        get {
            if useIcloud() {
                return cloud.object(forKey: "notifyMissed") as? Bool ?? false
            } else {
                return UD?.bool(forKey: "notifyMissed") ?? false
            }
        }
        set {
            // cloud.set(newValue, forKey: "notifyMissed")
            // cloud.synchronize()
            UD?.set(newValue, forKey: "notifyMissed")
            changed = true
        }
    }
    
    public var notifyMissedEach: Int {
        get {
            if useIcloud() {
                return cloud.object(forKey: "notifyMissedEach") as? Int ?? 5 * 60 * 60 // 5 hours
            } else {
                return UD?.integer(forKey: "notifyMissedEach") ?? 5 * 60 * 60 // 5 hours
            }
        }
        set {
            // cloud.set(newValue, forKey: "notifyMissedEach")
            // cloud.synchronize()
            UD?.set(newValue, forKey: "notifyMissedEach")
            changed = true
        }
    }
    
    public var oneTapTr: Bool {
        get {
            if useIcloud() {
                return cloud.object(forKey: "oneTapTr") as? Bool ?? true
            } else {
                return UD?.bool(forKey: "oneTapTr") ?? true
            }
            
        }
        set {
            // cloud.set(newValue, forKey: "oneTapTr")
            // cloud.synchronize()
            UD?.set(newValue, forKey: "oneTapTr")
            changed = true
        }
    }
    
    public var ignoreTranslate: [String] {
        get {
            return UD?.array(forKey: "ignoreTranslate") as? [String] ?? []
        }
        set {
            UD?.set(newValue, forKey: "ignoreTranslate")
            changed = true
        }
    }
}

public func useIcloud() -> Bool {
    return false
    return UserDefaults.standard.bool(forKey: "useIcloud")
}

public func setUseIcloud(_ value: Bool) {
    return UserDefaults.standard.set(value, forKey: "useIcloud")
}

public func isPremium() -> Bool {
    #if DEBUG
        return VarPremiumSettings.p
    #endif
    
    if (NicegramProducts.Premium.isEmpty) {
        return false
    }
    
    let bb = (Bundle.main.infoDictionary?[kCFBundleVersionKey as String] ?? "") as! String
    if bb.last != "1" {
        return false
    }
    
    return VarPremiumSettings.p //|| SecureNiceSettings().isPremium || SecureNiceSettings().isBetaPremium
}

public func usetrButton() -> [(Bool, [String])] {
    if isPremium() {
        let ps = VarPremiumSettings
        return [(ps.oneTapTr, ps.ignoreTranslate)]
    }
    return [(false, [])]
}

public func showMissed() -> Bool {
    // premiumlog("MISSSED DIFF")
    if isPremium() && VarPremiumSettings.notifyMissed {
        let launchDiff = utcnow() - VarPremiumSettings.lastOpened
        let isShowMissed: Bool = launchDiff > VarPremiumSettings.notifyMissedEach
        
        premiumLog("SHOWING  MISSED: \(isShowMissed) CAUSE LAUNCH DIFF IS \(launchDiff)")
        return isShowMissed
    } else {
        return false
    }
}

public func canUnlimFolders() -> Bool {
    return isPremium()
}


public func utcnow() -> Int {
    // using current date and time as an example
    let someDate = Date()
    
    // convert Date to TimeInterval (typealias for Double)
    let timeInterval = someDate.timeIntervalSince1970
    
    // convert to Integer
    return Int(timeInterval)
}



// Logging


enum PREMIUMManagedFileMode {
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

final class PREMIUMManagedFile {
    private let fd: Int32
    private let mode: PREMIUMManagedFileMode
    
    init?(path: String, mode: PREMIUMManagedFileMode) {
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


public var premiumLogger: PREMIUMLogger?

public final class PREMIUMLogger {
    private let maxLength: Int = 2 * 1024 * 1024
    private let maxFiles: Int = 20
    
    private let basePath: String
    private var file: (PREMIUMManagedFile, Int)?
    
    var logToFile: Bool = true
    var logToConsole: Bool = true
    
    public static func setSharedLogger(_ logger: PREMIUMLogger) {
        premiumLogger = logger
    }
    
    public static var shared: PREMIUMLogger {
        if let premiumLogger = premiumLogger {
            return premiumLogger
        } else {
            assertionFailure()
            let tempLogger = PREMIUMLogger(basePath: "")
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
            
            var currentFile: PREMIUMManagedFile?
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
                            if let file = PREMIUMManagedFile(path: url.path, mode: .append) {
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
                    
                    if let file = PREMIUMManagedFile(path: path, mode: .append) {
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


public func premiumLog(_ text: String, _ tag: String = "PREMIUM") {
    let baseAppBundleId = Bundle.main.bundleIdentifier!
    let appGroupName = "group.\(baseAppBundleId)"
    let maybeAppGroupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName)
    
    if let appGroupUrl = maybeAppGroupUrl {
        let rootPath = appGroupUrl.path + "/telegram-data"
        
        if premiumLogger == nil {
            let logsPath = rootPath + "/premiumLogs"
            PREMIUMLogger.setSharedLogger(PREMIUMLogger(basePath: logsPath))
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
            
            if premiumLogger == nil {
                let logsPath = rootPath + "/premiumLogs"
                PREMIUMLogger.setSharedLogger(PREMIUMLogger(basePath: logsPath))
            }
        } else {
            Logger.shared.log(tag + " (Main Logger)", text)
        }
    }
    
    
    PREMIUMLogger.shared.log(tag, text)
}
