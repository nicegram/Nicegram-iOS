import Foundation
import SwiftSignalKit
import ManagedFile
import RangeSet

private final class ResourceStatusContext {
    var status: MediaResourceStatus?
    let subscribers = Bag<(MediaResourceStatus) -> Void>()
    let disposable: Disposable
    
    init(disposable: Disposable) {
        self.disposable = disposable
    }
}

private final class ResourceDataContext {
    var data: MediaResourceData
    var processedFetch: Bool = false
    let progresiveDataSubscribers = Bag<(waitUntilFetchStatus: Bool, sink: (MediaResourceData) -> Void)>()
    let completeDataSubscribers = Bag<(waitUntilFetchStatus: Bool, sink: (MediaResourceData) -> Void)>()
    
    var fetchDisposable: Disposable?
    let fetchSubscribers = Bag<Void>()
    
    init(data: MediaResourceData) {
        self.data = data
    }
}

public enum ResourceDataRangeMode {
    case complete
    case incremental
    case partial
}

public enum FetchResourceSourceType {
    case local
    case remote
}

public enum FetchResourceError {
    case generic
}

public struct ResourceStorePaths {
    public let partial: String
    public let complete: String
}

public struct MediaResourceData: Equatable {
    public let path: String
    public let offset: Int64
    public let size: Int64
    public let complete: Bool
    
    public init(path: String, offset: Int64, size: Int64, complete: Bool) {
        self.path = path
        self.offset = offset
        self.size = size
        self.complete = complete
    }
}

public protocol MediaResourceDataFetchCopyLocalItem {
    func copyTo(url: URL) -> Bool
}

public enum MediaBoxFetchPriority: Int32 {
    case `default` = 0
    case elevated = 1
    case maximum = 2
}

public enum MediaResourceDataFetchResult {
    case dataPart(resourceOffset: Int64, data: Data, range: Range<Int64>, complete: Bool)
    case resourceSizeUpdated(Int64)
    case progressUpdated(Float)
    case replaceHeader(data: Data, range: Range<Int64>)
    case moveLocalFile(path: String)
    case moveTempFile(file: TempBoxFile)
    case copyLocalItem(MediaResourceDataFetchCopyLocalItem)
    case reset
}

public enum MediaResourceDataFetchError {
    case generic
}

public enum CachedMediaResourceRepresentationResult {
    case reset
    case data(Data)
    case done
    case temporaryPath(String)
    case tempFile(TempBoxFile)
}

public enum CachedMediaRepresentationKeepDuration {
    case general
    case shortLived
}

private struct CachedMediaResourceRepresentationKey: Hashable {
    let resourceId: String?
    let representation: String
}

private final class CachedMediaResourceRepresentationSubscriber {
    let update: (MediaResourceData) -> Void
    let onlyComplete: Bool
    
    init(update: @escaping (MediaResourceData) -> Void, onlyComplete: Bool) {
        self.update = update
        self.onlyComplete = onlyComplete
    }
}

private final class CachedMediaResourceRepresentationContext {
    var currentData: MediaResourceData?
    let dataSubscribers = Bag<CachedMediaResourceRepresentationSubscriber>()
    let disposable = MetaDisposable()
    var initialized = false
}

public enum ResourceDataRequestOption {
    case complete(waitUntilFetchStatus: Bool)
    case incremental(waitUntilFetchStatus: Bool)
}

private final class MediaBoxKeepResourceContext {
    let subscribers = Bag<Void>()
    
    var isEmpty: Bool {
        return self.subscribers.isEmpty
    }
}

public final class MediaBox {
    public let basePath: String
    public let isMainProcess: Bool
    
    private let statusQueue = Queue()
    private let concurrentQueue = Queue.concurrentDefaultQueue()
    public let dataQueue = Queue(name: "MediaBox-Data")
    public let dataFileManager: MediaBoxFileManager
    private let cacheQueue = Queue()
    private let timeBasedCleanup: TimeBasedCleanup
    
    public let storageBox: StorageBox
    public let cacheStorageBox: StorageBox
    
    private let didRemoveResourcesPipe = ValuePipe<Void>()
    public var didRemoveResources: Signal<Void, NoError> {
        return .single(Void()) |> then(self.didRemoveResourcesPipe.signal())
    }
    
    private var statusContexts: [MediaResourceId: ResourceStatusContext] = [:]
    private var cachedRepresentationContexts: [CachedMediaResourceRepresentationKey: CachedMediaResourceRepresentationContext] = [:]
    
    private var fileContexts: [MediaResourceId: MediaBoxFileContext] = [:]
    private var keepResourceContexts: [MediaResourceId: MediaBoxKeepResourceContext] = [:]
    
    private var wrappedFetchResource = Promise<(MediaResource, Signal<[(Range<Int64>, MediaBoxFetchPriority)], NoError>, MediaResourceFetchParameters?) -> Signal<MediaResourceDataFetchResult, MediaResourceDataFetchError>>()

    public var fetchResource: ((MediaResource, Signal<[(Range<Int64>, MediaBoxFetchPriority)], NoError>, MediaResourceFetchParameters?) -> Signal<MediaResourceDataFetchResult, MediaResourceDataFetchError>)? {
        didSet {
            if let fetchResource = self.fetchResource {
                wrappedFetchResource.set(.single(fetchResource))
            } else {
                wrappedFetchResource.set(.never())
            }
        }
    }
    
    public var wrappedFetchCachedResourceRepresentation = Promise<(MediaResource, CachedMediaResourceRepresentation) -> Signal<CachedMediaResourceRepresentationResult, NoError>>()
    public var fetchCachedResourceRepresentation: ((MediaResource, CachedMediaResourceRepresentation) -> Signal<CachedMediaResourceRepresentationResult, NoError>)? {
        didSet {
            if let fetchCachedResourceRepresentation = self.fetchCachedResourceRepresentation {
                wrappedFetchCachedResourceRepresentation.set(.single(fetchCachedResourceRepresentation))
            } else {
                wrappedFetchCachedResourceRepresentation.set(.never())
            }
        }
    }
    
    lazy var ensureDirectoryCreated: Void = {
        let _ = try? FileManager.default.createDirectory(atPath: self.basePath, withIntermediateDirectories: true, attributes: nil)
        let _ = try? FileManager.default.createDirectory(atPath: self.basePath + "/cache", withIntermediateDirectories: true, attributes: nil)
        let _ = try? FileManager.default.createDirectory(atPath: self.basePath + "/short-cache", withIntermediateDirectories: true, attributes: nil)
    }()
    
    public init(basePath: String, isMainProcess: Bool) {
        self.basePath = basePath
        self.isMainProcess = isMainProcess
        
        self.storageBox = StorageBox(logger: StorageBox.Logger(impl: { string in
            postboxLog(string)
        }), basePath: basePath + "/storage", isMainProcess: isMainProcess)
        self.cacheStorageBox = StorageBox(logger: StorageBox.Logger(impl: { string in
            postboxLog(string)
        }), basePath: basePath + "/cache-storage", isMainProcess: isMainProcess)
        
        self.timeBasedCleanup = TimeBasedCleanup(storageBox: self.storageBox, generalPaths: [
            self.basePath + "/cache",
            self.basePath + "/animation-cache"
        ], totalSizeBasedPath: self.basePath, shortLivedPaths: [
            self.basePath + "/short-cache"
        ])
        
        self.dataFileManager = MediaBoxFileManager(queue: self.dataQueue)
        
        let _ = self.ensureDirectoryCreated
    }
    
    public func setMaxStoreTimes(general: Int32, shortLived: Int32, gigabytesLimit: Int32) {
        self.timeBasedCleanup.setMaxStoreTimes(general: general, shortLived: shortLived, gigabytesLimit: gigabytesLimit)
    }
    
    public static func idForFileName(name: String) -> String {
        if name.hasSuffix("_partial.meta") {
            return String(name[name.startIndex ..< name.index(name.endIndex, offsetBy: -13)])
        } else if name.hasSuffix("_partial") {
            return String(name[name.startIndex ..< name.index(name.endIndex, offsetBy: -8)])
        } else {
            return name
        }
    }
    
    private func fileNameForId(_ id: MediaResourceId) -> String {
        return "\(id.stringRepresentation)"
    }
    
    private func fileNameForId(_ id: String) -> String {
        return "\(id)"
    }
    
    private func pathForId(_ id: MediaResourceId) -> String {
        return "\(self.basePath)/\(fileNameForId(id))"
    }
    
    public func storePathsForId(_ id: MediaResourceId) -> ResourceStorePaths {
        return ResourceStorePaths(partial: "\(self.basePath)/\(fileNameForId(id))_partial", complete: "\(self.basePath)/\(fileNameForId(id))")
    }
    
    public func fileSizeForId(_ id: MediaResourceId) -> Int64 {
        let paths = self.storePathsForId(id)
        if let size = fileSize(paths.complete, useTotalFileAllocatedSize: false) {
            return size
        } else if let size = fileSize(paths.partial, useTotalFileAllocatedSize: true) {
            return size
        } else {
            return 0
        }
    }
    
    private func fileNamesForId(_ id: MediaResourceId) -> ResourceStorePaths {
        return ResourceStorePaths(partial: "\(fileNameForId(id))_partial", complete: "\(fileNameForId(id))")
    }
    
    private func cachedRepresentationPathsForId(_ id: String, representationId: String, keepDuration: CachedMediaRepresentationKeepDuration) -> ResourceStorePaths {
        let cacheString: String
        switch keepDuration {
            case .general:
                cacheString = "cache"
            case .shortLived:
                cacheString = "short-cache"
        }
        return ResourceStorePaths(partial:  "\(self.basePath)/\(cacheString)/\(fileNameForId(id))_partial:\(representationId)", complete: "\(self.basePath)/\(cacheString)/\(fileNameForId(id)):\(representationId)")
    }
    
    public func cachedRepresentationPathForId(_ id: String, representationId: String, keepDuration: CachedMediaRepresentationKeepDuration) -> String {
        let cacheString: String
        switch keepDuration {
            case .general:
                cacheString = "cache"
            case .shortLived:
                cacheString = "short-cache"
        }
        return "\(self.basePath)/\(cacheString)/\(fileNameForId(id)):\(representationId)"
    }
    
    public func cachedRepresentationCompletePath(_ id: MediaResourceId, representation: CachedMediaResourceRepresentation) -> String {
        let cacheString: String
        switch representation.keepDuration {
        case .general:
            cacheString = "cache"
        case .shortLived:
            cacheString = "short-cache"
        }
        return "\(self.basePath)/\(cacheString)/\(fileNameForId(id)):\(representation.uniqueId)"
    }
    
    public func cachedRepresentationCompletePath(_ id: MediaResourceId, keepDuration: CachedMediaRepresentationKeepDuration, representationId: String) -> String {
        let cacheString: String
        switch keepDuration {
        case .general:
            cacheString = "cache"
        case .shortLived:
            cacheString = "short-cache"
        }
        return "\(self.basePath)/\(cacheString)/\(fileNameForId(id)):\(representationId)"
    }
    
    public func shortLivedResourceCachePathPrefix(_ id: MediaResourceId) -> String {
        let cacheString = "short-cache"
        return "\(self.basePath)/\(cacheString)/\(fileNameForId(id))"
    }
    
    public func storeResourceData(_ id: MediaResourceId, data: Data, synchronous: Bool = false) {
        let begin = {
            let paths = self.storePathsForId(id)
            let _ = try? data.write(to: URL(fileURLWithPath: paths.complete), options: [.atomic])
        }
        if synchronous {
            begin()
        } else {
            self.dataQueue.async(begin)
        }
    }
    
    public func storeResourceData(_ id: MediaResourceId, range: Range<Int64>, data: Data) {
        self.dataQueue.async {
            if let (fileContext, dispose) = self.fileContext(for: id) {
                fileContext.internalStore(data: data, range: range)
                dispose()
            }
        }
    }
    
    public func moveResourceData(_ id: MediaResourceId, fromTempPath: String) {
        self.dataQueue.async {
            let paths = self.storePathsForId(id)
            let _ = try? FileManager.default.moveItem(at: URL(fileURLWithPath: fromTempPath), to: URL(fileURLWithPath: paths.complete))
        }
    }
    
    public func moveResourceData(_ id: MediaResourceId, toTempPath: String) {
        self.dataQueue.async {
            let paths = self.storePathsForId(id)
            let _ = try? FileManager.default.moveItem(at: URL(fileURLWithPath: paths.complete), to: URL(fileURLWithPath: toTempPath))
        }
    }
    
    public func copyResourceData(_ id: MediaResourceId, fromTempPath: String) {
        self.dataQueue.async {
            let paths = self.storePathsForId(id)
            let _ = try? FileManager.default.copyItem(at: URL(fileURLWithPath: fromTempPath), to: URL(fileURLWithPath: paths.complete))
        }
    }
    
    public func moveResourceData(from: MediaResourceId, to: MediaResourceId, synchronous: Bool = false) {
        if from == to {
            return
        }
        let begin = {
            let pathsFrom = self.storePathsForId(from)
            let pathsTo = self.storePathsForId(to)
            link(pathsFrom.partial, pathsTo.partial)
            link(pathsFrom.complete, pathsTo.complete)
            unlink(pathsFrom.partial)
            unlink(pathsFrom.complete)
        }
        if synchronous {
            begin()
        } else {
            self.dataQueue.async(begin)
        }
    }
    
    public func copyResourceData(from: MediaResourceId, to: MediaResourceId, synchronous: Bool = false) {
        if from == to {
            return
        }
        let begin = {
            let pathsFrom = self.storePathsForId(from)
            let pathsTo = self.storePathsForId(to)
            let _ = try? FileManager.default.copyItem(atPath: pathsFrom.partial, toPath: pathsTo.partial)
            let _ = try? FileManager.default.copyItem(atPath: pathsFrom.complete, toPath: pathsTo.complete)
        }
        if synchronous {
            begin()
        } else {
            self.dataQueue.async(begin)
        }
    }
    
    public func resourceStatus(_ resource: MediaResource, approximateSynchronousValue: Bool = false) -> Signal<MediaResourceStatus, NoError> {
        return self.resourceStatus(resource.id, resourceSize: resource.size, approximateSynchronousValue: approximateSynchronousValue)
    }
    
    public func resourceStatus(_ resourceId: MediaResourceId, resourceSize: Int64?, approximateSynchronousValue: Bool = false) -> Signal<MediaResourceStatus, NoError> {
        let signal = Signal<MediaResourceStatus, NoError> { subscriber in
            let disposable = MetaDisposable()
            
            self.concurrentQueue.async {
                let paths = self.storePathsForId(resourceId)
                
                if let _ = fileSize(paths.complete) {
                    self.timeBasedCleanup.touch(paths: [
                        paths.complete
                    ])
                    subscriber.putNext(.Local)
                    subscriber.putCompletion()
                } else {
                    self.statusQueue.async {
                        let statusContext: ResourceStatusContext
                        var statusUpdateDisposable: MetaDisposable?
                        if let current = self.statusContexts[resourceId] {
                            statusContext = current
                        } else {
                            let statusUpdateDisposableValue = MetaDisposable()
                            statusContext = ResourceStatusContext(disposable: statusUpdateDisposableValue)
                            self.statusContexts[resourceId] = statusContext
                            statusUpdateDisposable = statusUpdateDisposableValue
                        }
                        
                        let index = statusContext.subscribers.add({ status in
                            subscriber.putNext(status)
                        })
                        
                        if let status = statusContext.status {
                            subscriber.putNext(status)
                        }
                        
                        if let statusUpdateDisposable = statusUpdateDisposable {
                            let statusQueue = self.statusQueue
                            self.dataQueue.async {
                                if let (fileContext, releaseContext) = self.fileContext(for: resourceId) {
                                    let statusDisposable = fileContext.status(next: { [weak statusContext] value in
                                        statusQueue.async {
                                            if let current = self.statusContexts[resourceId], current === statusContext, current.status != value {
                                                current.status = value
                                                for subscriber in current.subscribers.copyItems() {
                                                    subscriber(value)
                                                }
                                            }
                                        }
                                    }, completed: { [weak statusContext] in
                                        statusQueue.async {
                                            if let current = self.statusContexts[resourceId], current ===  statusContext {
                                                current.subscribers.remove(index)
                                                if current.subscribers.isEmpty {
                                                    self.statusContexts.removeValue(forKey: resourceId)
                                                    current.disposable.dispose()
                                                }
                                            }
                                        }
                                    }, size: resourceSize)
                                    statusUpdateDisposable.set(ActionDisposable {
                                        statusDisposable.dispose()
                                        releaseContext()
                                    })
                                }
                            }
                        }
                        
                        disposable.set(ActionDisposable { [weak statusContext] in
                            self.statusQueue.async {
                                if let current = self.statusContexts[resourceId], current ===  statusContext {
                                    current.subscribers.remove(index)
                                    if current.subscribers.isEmpty {
                                        self.statusContexts.removeValue(forKey: resourceId)
                                        current.disposable.dispose()
                                    }
                                }
                            }
                        })
                    }
                }
            }
            
            return disposable
        }
        if approximateSynchronousValue {
            return Signal<Signal<MediaResourceStatus, NoError>, NoError> { subscriber in
                let paths = self.storePathsForId(resourceId)
                if let _ = fileSize(paths.complete) {
                    subscriber.putNext(.single(.Local))
                } else if let size = fileSize(paths.partial), size == resourceSize {
                    subscriber.putNext(.single(.Local))
                } else {
                    subscriber.putNext(.single(.Remote(progress: 0.0)) |> then(signal))
                }
                subscriber.putCompletion()
                return EmptyDisposable
            } |> switchToLatest
        } else {
            return signal
        }
    }
    
    public func resourcePath(_ resource: MediaResource) -> String {
        let paths = self.storePathsForId(resource.id)
        return paths.complete
    }
    
    public func completedResourcePath(_ resource: MediaResource, pathExtension: String? = nil) -> String? {
        return self.completedResourcePath(id: resource.id, pathExtension: pathExtension)
    }
    
    public func completedResourcePath(id: MediaResourceId, pathExtension: String? = nil) -> String? {
        let paths = self.storePathsForId(id)
        if let _ = fileSize(paths.complete) {
            self.timeBasedCleanup.touch(paths: [
                paths.complete
            ])
            if let pathExtension = pathExtension {
                let symlinkPath = paths.complete + ".\(pathExtension)"
                if fileSize(symlinkPath) == nil {
                    let _ = try? FileManager.default.linkItem(atPath: paths.complete, toPath: symlinkPath)
                }
                return symlinkPath
            } else {
                return paths.complete
            }
        } else {
            return nil
        }
    }

    public func resourceData(_ resource: MediaResource, pathExtension: String? = nil, option: ResourceDataRequestOption = .complete(waitUntilFetchStatus: false), attemptSynchronously: Bool = false) -> Signal<MediaResourceData, NoError> {
        return self.resourceData(id: resource.id, pathExtension: pathExtension, option: option, attemptSynchronously: attemptSynchronously)
    }
    
    public func resourceData(id: MediaResourceId, pathExtension: String? = nil, option: ResourceDataRequestOption = .complete(waitUntilFetchStatus: false), attemptSynchronously: Bool = false) -> Signal<MediaResourceData, NoError> {
        return Signal { subscriber in
            let disposable = MetaDisposable()
            
            let begin: () -> Void = {
                let paths = self.storePathsForId(id)
                
                if let completeSize = fileSize(paths.complete) {
                    self.timeBasedCleanup.touch(paths: [
                        paths.complete
                    ])
                    if let pathExtension = pathExtension {
                        let symlinkPath = paths.complete + ".\(pathExtension)"
                        if fileSize(symlinkPath) == nil {
                            let _ = try? FileManager.default.linkItem(atPath: paths.complete, toPath: symlinkPath)
                        }
                        subscriber.putNext(MediaResourceData(path: symlinkPath, offset: 0, size: completeSize, complete: true))
                        subscriber.putCompletion()
                    } else {
                        subscriber.putNext(MediaResourceData(path: paths.complete, offset: 0, size: completeSize, complete: true))
                        subscriber.putCompletion()
                    }
                } else {
                    if attemptSynchronously, case .complete(false) = option {
                        subscriber.putNext(MediaResourceData(path: paths.partial, offset: 0, size: fileSize(paths.partial) ?? 0, complete: false))
                    }
                    self.dataQueue.async {
                        if let (fileContext, releaseContext) = self.fileContext(for: id) {
                            let waitUntilAfterInitialFetch: Bool
                            switch option {
                                case let .complete(waitUntilFetchStatus):
                                    waitUntilAfterInitialFetch = waitUntilFetchStatus
                                case let .incremental(waitUntilFetchStatus):
                                    waitUntilAfterInitialFetch = waitUntilFetchStatus
                            }
                            let dataDisposable = fileContext.data(range: 0 ..< Int64.max, waitUntilAfterInitialFetch: waitUntilAfterInitialFetch, next: { value in
                                self.dataQueue.async {
                                    if value.complete {
                                        if let pathExtension = pathExtension {
                                            let symlinkPath = paths.complete + ".\(pathExtension)"
                                            if fileSize(symlinkPath) == nil {
                                                let _ = try? FileManager.default.linkItem(atPath: paths.complete, toPath: symlinkPath)
                                            }
                                            subscriber.putNext(MediaResourceData(path: symlinkPath, offset: 0, size: value.size, complete: true))
                                        } else {
                                            subscriber.putNext(value)
                                        }
                                        subscriber.putCompletion()
                                    } else {
                                        subscriber.putNext(value)
                                    }
                                }
                            })
                            disposable.set(ActionDisposable {
                                dataDisposable.dispose()
                                releaseContext()
                            })
                        }
                    }
                }
            }
            if attemptSynchronously {
                begin()
            } else {
                self.concurrentQueue.async(begin)
            }
            
            return disposable
        }
    }
    
    private func fileContext(for id: MediaResourceId) -> (MediaBoxFileContext, () -> Void)? {
        assert(self.dataQueue.isCurrent())
        
        let resourceId = id
        
        var context: MediaBoxFileContext?
        if let current = self.fileContexts[resourceId] {
            context = current
        } else {
            let paths = self.storePathsForId(id)
            self.timeBasedCleanup.touch(paths: [
                paths.complete,
                paths.partial,
                paths.partial + ".meta"
            ])
            
            if let fileContext = MediaBoxFileContextV2Impl(queue: self.dataQueue, manager: self.dataFileManager, storageBox: self.storageBox, resourceId: id.stringRepresentation.data(using: .utf8)!, path: paths.complete, partialPath: paths.partial, metaPath: paths.partial + ".meta") {
                context = fileContext
                self.fileContexts[resourceId] = fileContext
            } else {
                return nil
            }
        }
        if let context = context {
            let index = context.addReference()
            let queue = self.dataQueue
            return (context, { [weak self, weak context] in
                queue.async {
                    guard let strongSelf = self, let previousContext = context, let context = strongSelf.fileContexts[resourceId], context === previousContext else {
                        return
                    }
                    context.removeReference(index)
                    if context.isEmpty {
                        strongSelf.fileContexts.removeValue(forKey: resourceId)
                    }
                }
            })
        } else {
            return nil
        }
    }
    
    public func fetchedResourceData(_ resource: MediaResource, in range: Range<Int64>, priority: MediaBoxFetchPriority = .default, parameters: MediaResourceFetchParameters?) -> Signal<Void, FetchResourceError> {
        return Signal { subscriber in
            let disposable = MetaDisposable()
            
            self.dataQueue.async {
                let paths = self.storePathsForId(resource.id)
                if let _ = fileSize(paths.complete) {
                    subscriber.putCompletion()
                    return
                }
                
                if let parameters = parameters, let location = parameters.location {
                    var messageNamespace: Int32 = 0
                    var messageIdValue: Int32 = 0
                    if let messageId = location.messageId {
                        messageNamespace = messageId.namespace
                        messageIdValue = messageId.id
                    }
                    
                    self.storageBox.add(reference: StorageBox.Reference(peerId: location.peerId.toInt64(), messageNamespace: UInt8(clamping: messageNamespace), messageId: messageIdValue), to: resource.id.stringRepresentation.data(using: .utf8)!, contentType: parameters.contentType)
                } else {
                    self.storageBox.add(reference: StorageBox.Reference(peerId: 0, messageNamespace: 0, messageId: 0), to: resource.id.stringRepresentation.data(using: .utf8)!, contentType: parameters?.contentType ?? 0)
                }
                
                guard let (fileContext, releaseContext) = self.fileContext(for: resource.id) else {
                    subscriber.putCompletion()
                    return
                }
                
                var range = range
                if let parameters = parameters, !parameters.isRandomAccessAllowed {
                    range = 0 ..< range.upperBound
                }
                
                let fetchResource = self.wrappedFetchResource.get()
                let fetchedDisposable = fileContext.fetched(range: range.lowerBound ..< range.upperBound, priority: priority, fetch: { intervals in
                    return fetchResource
                    |> castError(MediaResourceDataFetchError.self)
                    |> mapToSignal { fetch in
                        return fetch(resource, intervals, parameters)
                    }
                }, error: { _ in
                    subscriber.putCompletion()
                }, completed: {
                    subscriber.putCompletion()
                })
                
                disposable.set(ActionDisposable {
                    fetchedDisposable.dispose()
                    releaseContext()
                })
            }
            
            return disposable
        }
    }

    public func resourceData(_ resource: MediaResource, size: Int64, in range: Range<Int64>, mode: ResourceDataRangeMode = .complete, notifyAboutIncomplete: Bool = false, attemptSynchronously: Bool = false) -> Signal<(Data, Bool), NoError> {
        return self.resourceData(id: resource.id, size: size, in: range, mode: mode, notifyAboutIncomplete: notifyAboutIncomplete, attemptSynchronously: attemptSynchronously)
    }
    
    public func internal_resourceData(id: MediaResourceId, size: Int64, in range: Range<Int64>) -> (file: ManagedFile, length: Int)? {
        let paths = self.storePathsForId(id)
        
        self.timeBasedCleanup.touch(paths: [
            paths.complete
        ])
        
        if let file = ManagedFile(queue: nil, path: paths.complete, mode: .read), let completeSize = file.getSize() {
            let clippedLowerBound = min(completeSize, max(0, range.lowerBound))
            let clippedUpperBound = min(completeSize, max(0, range.upperBound))
            if clippedLowerBound < clippedUpperBound && (clippedUpperBound - clippedLowerBound) <= 64 * 1024 * 1024 {
                let _ = file.seek(position: clippedLowerBound)
                return (file, Int(clippedUpperBound - clippedLowerBound))
            } else {
                return nil
            }
        } else {
            let tempManager = MediaBoxFileManager(queue: nil)
            return MediaBoxPartialFile.internal_extractPartialData(manager: tempManager, path: paths.partial, metaPath: paths.partial + ".meta", range: range)
        }
    }
    
    public func internal_resourceDataIsCached(id: MediaResourceId, size: Int64, in range: Range<Int64>) -> Bool {
        let paths = self.storePathsForId(id)
        
        if let _ = fileSize(paths.complete) {
            return true
        } else {
            let tempManager = MediaBoxFileManager(queue: nil)
            return MediaBoxPartialFile.internal_isPartialDataCached(manager: tempManager, path: paths.partial, metaPath: paths.partial + ".meta", range: range)
        }
    }
    
    public func resourceData(id: MediaResourceId, size: Int64, in range: Range<Int64>, mode: ResourceDataRangeMode = .complete, notifyAboutIncomplete: Bool = false, attemptSynchronously: Bool = false) -> Signal<(Data, Bool), NoError> {
        return Signal { subscriber in
            let disposable = MetaDisposable()
            
            if attemptSynchronously {
                let paths = self.storePathsForId(id)
                
                if let completeSize = fileSize(paths.complete) {
                    self.timeBasedCleanup.touch(paths: [
                        paths.complete
                    ])
                    
                    if let file = ManagedFile(queue: nil, path: paths.complete, mode: .read) {
                        let clippedLowerBound = min(completeSize, max(0, range.lowerBound))
                        let clippedUpperBound = min(completeSize, max(0, range.upperBound))
                        if clippedLowerBound < clippedUpperBound && (clippedUpperBound - clippedLowerBound) <= 64 * 1024 * 1024 {
                            let _ = file.seek(position: clippedLowerBound)
                            let data = file.readData(count: Int(clippedUpperBound - clippedLowerBound))
                            subscriber.putNext((data, true))
                        } else {
                            subscriber.putNext((Data(), isComplete: true))
                        }
                        subscriber.putCompletion()
                        return EmptyDisposable
                    } else {
                        let tempManager = MediaBoxFileManager(queue: nil)
                        let data = withExtendedLifetime(tempManager, {
                            return MediaBoxPartialFile.extractPartialData(manager: tempManager, path: paths.partial, metaPath: paths.partial + ".meta", range: range)
                        })
                        if let data = data {
                            subscriber.putNext((data, true))
                            subscriber.putCompletion()
                            return EmptyDisposable
                        }
                    }
                }
            }
            
            self.dataQueue.async {
                guard let (fileContext, releaseContext) = self.fileContext(for: id) else {
                    subscriber.putCompletion()
                    return
                }
                
                let dataDisposable = fileContext.data(range: range, waitUntilAfterInitialFetch: false, next: { result in
                    if let file = ManagedFile(queue: self.dataQueue, path: result.path, mode: .read), let fileSize = file.getSize() {
                        if result.complete {
                            let clippedLowerBound = min(result.offset, fileSize)
                            let clippedUpperBound = min(result.offset + result.size, fileSize)
                            if clippedUpperBound == clippedLowerBound {
                                subscriber.putNext((Data(), true))
                                subscriber.putCompletion()
                            } else if clippedUpperBound <= fileSize && (clippedUpperBound - clippedLowerBound) <= 64 * 1024 * 1024 {
                                let _ = file.seek(position: Int64(clippedLowerBound))
                                let resultData = file.readData(count: Int(clippedUpperBound - clippedLowerBound))
                                subscriber.putNext((resultData, true))
                                subscriber.putCompletion()
                            } else {
                                assertionFailure()
                            }
                        } else {
                            switch mode {
                                case .complete, .incremental:
                                    if notifyAboutIncomplete {
                                        subscriber.putNext((Data(), false))
                                    }
                                case .partial:
                                    subscriber.putNext((Data(), false))
                            }
                        }
                    } else {
                        switch mode {
                            case .complete, .incremental:
                                if notifyAboutIncomplete {
                                    subscriber.putNext((Data(), false))
                                }
                            case .partial:
                                subscriber.putNext((Data(), false))
                        }
                    }
                })
                
                disposable.set(ActionDisposable {
                    dataDisposable.dispose()
                    releaseContext()
                })
            }
            
            return disposable
        }
    }
    
    public func resourceRangesStatus(_ resource: MediaResource) -> Signal<RangeSet<Int64>, NoError> {
        return Signal { subscriber in
            let disposable = MetaDisposable()
            
            self.dataQueue.async {
                guard let (fileContext, releaseContext) = self.fileContext(for: resource.id) else {
                    subscriber.putCompletion()
                    return
                }
                
                let statusDisposable = fileContext.rangeStatus(next: { result in
                    subscriber.putNext(result)
                }, completed: {
                    subscriber.putCompletion()
                })
                
                disposable.set(ActionDisposable {
                    statusDisposable.dispose()
                    releaseContext()
                })
            }
            
            return disposable
        }
    }
    
    // MARK: Nicegram downloading feature
    public func fetchedResource(_ resource: MediaResource, parameters: MediaResourceFetchParameters?, implNext: Bool = false, shouldSave: Bool = false) -> Signal<FetchResourceSourceType, FetchResourceError> {
        return Signal { subscriber in
            let disposable = MetaDisposable()
            
            self.dataQueue.async {
                let paths = self.storePathsForId(resource.id)
                
                if let parameters = parameters, let location = parameters.location {
                    var messageNamespace: Int32 = 0
                    var messageIdValue: Int32 = 0
                    if let messageId = location.messageId {
                        messageNamespace = messageId.namespace
                        messageIdValue = messageId.id
                    }
                    
                    self.storageBox.add(reference: StorageBox.Reference(peerId: location.peerId.toInt64(), messageNamespace: UInt8(clamping: messageNamespace), messageId: messageIdValue), to: resource.id.stringRepresentation.data(using: .utf8)!, contentType: parameters.contentType)
                } else {
                    self.storageBox.add(reference: StorageBox.Reference(peerId: 0, messageNamespace: 0, messageId: 0), to: resource.id.stringRepresentation.data(using: .utf8)!, contentType: parameters?.contentType ?? 0)
                }
                
                if let _ = fileSize(paths.complete) {
                    if implNext {
                        subscriber.putNext(.local)
                    }
                    subscriber.putCompletion()
                } else {
                    if let (fileContext, releaseContext) = self.fileContext(for: resource.id) {
                        let fetchResource = self.wrappedFetchResource.get()
                        let fetchedDisposable = fileContext.fetchedFullRange(fetch: { ranges in
                            return fetchResource
                            |> castError(MediaResourceDataFetchError.self)
                            |> mapToSignal { fetch in
                                return fetch(resource, ranges, parameters)
                            }
                        }, error: { _ in
                            subscriber.putError(.generic)
                        }, completed: {
                            if implNext {
                                subscriber.putNext(.remote)
                            }
                            subscriber.putCompletion()
                        })
                        disposable.set(ActionDisposable {
                            fetchedDisposable.dispose()
                            releaseContext()
                        })
                    }
                }
            }
            
            return disposable
        }
    }
    
    public func keepResource(id: MediaResourceId) -> Signal<Never, NoError> {
        return Signal { subscriber in
            let disposable = MetaDisposable()
            
            let dataQueue = self.dataQueue
            self.dataQueue.async {
                let context: MediaBoxKeepResourceContext
                if let current = self.keepResourceContexts[id] {
                    context = current
                } else {
                    context = MediaBoxKeepResourceContext()
                    self.keepResourceContexts[id] = context
                }
                let index = context.subscribers.add(Void())
                
                disposable.set(ActionDisposable { [weak self, weak context] in
                    dataQueue.async {
                        guard let strongSelf = self, let context = context, let currentContext = strongSelf.keepResourceContexts[id], currentContext === context else {
                            return
                        }
                        currentContext.subscribers.remove(index)
                        if currentContext.isEmpty {
                            strongSelf.keepResourceContexts.removeValue(forKey: id)
                        }
                    }
                })
            }
            
            return disposable
        }
    }
    
    public func cancelInteractiveResourceFetch(_ resource: MediaResource) {
        self.cancelInteractiveResourceFetch(resourceId: resource.id)
    }
    
    public func cancelInteractiveResourceFetch(resourceId: MediaResourceId) {
        self.dataQueue.async {
            if let (fileContext, releaseContext) = self.fileContext(for: resourceId) {
                fileContext.cancelFullRangeFetches()
                releaseContext()
            }
        }
    }
    
    public func storeCachedResourceRepresentation(_ resource: MediaResource, representation: CachedMediaResourceRepresentation, data: Data) {
        self.dataQueue.async {
            let path = self.cachedRepresentationPathsForId(resource.id.stringRepresentation, representationId: representation.uniqueId, keepDuration: representation.keepDuration).complete
            if let pathData = path.data(using: .utf8) {
                self.cacheStorageBox.update(id: pathData, size: Int64(data.count))
            }
            let _ = try? data.write(to: URL(fileURLWithPath: path))
        }
    }

    public func storeCachedResourceRepresentation(_ resource: MediaResource, representationId: String, keepDuration: CachedMediaRepresentationKeepDuration, data: Data, completion: @escaping (String) -> Void = { _ in }) {
        self.dataQueue.async {
            let path = self.cachedRepresentationPathsForId(resource.id.stringRepresentation, representationId: representationId, keepDuration: keepDuration).complete
            if let pathData = path.data(using: .utf8) {
                self.cacheStorageBox.update(id: pathData, size: Int64(data.count))
            }
            let _ = try? data.write(to: URL(fileURLWithPath: path))
            completion(path)
        }
    }
    
    public func storeCachedResourceRepresentation(_ resourceId: String, representationId: String, keepDuration: CachedMediaRepresentationKeepDuration, data: Data, completion: @escaping (String) -> Void = { _ in }) {
        self.dataQueue.async {
            let path = self.cachedRepresentationPathsForId(resourceId, representationId: representationId, keepDuration: keepDuration).complete
            let _ = try? data.write(to: URL(fileURLWithPath: path))
            if let pathData = path.data(using: .utf8) {
                self.cacheStorageBox.update(id: pathData, size: Int64(data.count))
            }
            completion(path)
        }
    }
    
    public func storeCachedResourceRepresentation(_ resourceId: String, representationId: String, keepDuration: CachedMediaRepresentationKeepDuration, tempFile: TempBoxFile, completion: @escaping (String) -> Void = { _ in }) {
        self.dataQueue.async {
            let path = self.cachedRepresentationPathsForId(resourceId, representationId: representationId, keepDuration: keepDuration).complete
            let _ = try? FileManager.default.moveItem(atPath: tempFile.path, toPath: path)
            if let fileSize = fileSize(path), fileSize != 0, let pathData = path.data(using: .utf8) {
                self.cacheStorageBox.update(id: pathData, size: fileSize)
            }
            completion(path)
        }
    }
    
    public func cachedResourceRepresentation(_ resource: MediaResource, representation: CachedMediaResourceRepresentation, pathExtension: String? = nil, complete: Bool, fetch: Bool = true, attemptSynchronously: Bool = false) -> Signal<MediaResourceData, NoError> {
        return Signal { subscriber in
            let disposable = MetaDisposable()
            
            let begin: () -> Void = {
                let paths = self.cachedRepresentationPathsForId(resource.id.stringRepresentation, representationId: representation.uniqueId, keepDuration: representation.keepDuration)
                if let size = fileSize(paths.complete) {
                    self.timeBasedCleanup.touch(paths: [
                        paths.complete
                    ])
                    
                    if let pathExtension = pathExtension {
                        let symlinkPath = paths.complete + ".\(pathExtension)"
                        if fileSize(symlinkPath) == nil {
                            let _ = try? FileManager.default.linkItem(atPath: paths.complete, toPath: symlinkPath)
                        }
                        subscriber.putNext(MediaResourceData(path: symlinkPath, offset: 0, size: size, complete: true))
                        subscriber.putCompletion()
                    } else {
                        subscriber.putNext(MediaResourceData(path: paths.complete, offset: 0, size: size, complete: true))
                        subscriber.putCompletion()
                    }
                } else if fetch {
                    if attemptSynchronously && complete {
                        subscriber.putNext(MediaResourceData(path: paths.partial, offset: 0, size: 0, complete: false))
                    }
                    self.dataQueue.async {
                        let key = CachedMediaResourceRepresentationKey(resourceId: resource.id.stringRepresentation, representation: representation.uniqueId)
                        let context: CachedMediaResourceRepresentationContext
                        if let currentContext = self.cachedRepresentationContexts[key] {
                            context = currentContext
                        } else {
                            context = CachedMediaResourceRepresentationContext()
                            self.cachedRepresentationContexts[key] = context
                        }
                        
                        let index = context.dataSubscribers.add(CachedMediaResourceRepresentationSubscriber(update: { data in
                            if !complete || data.complete {
                                if let pathExtension = pathExtension, data.complete {
                                    let symlinkPath = data.path + ".\(pathExtension)"
                                    if fileSize(symlinkPath) == nil {
                                        let _ = try? FileManager.default.linkItem(atPath: data.path, toPath: symlinkPath)
                                    }
                                    subscriber.putNext(MediaResourceData(path: symlinkPath, offset: data.offset, size: data.size, complete: data.complete))
                                } else {
                                    subscriber.putNext(data)
                                }
                            }
                            if data.complete {
                                subscriber.putCompletion()
                            }
                        }, onlyComplete: complete))
                        if let currentData = context.currentData {
                            if !complete || currentData.complete {
                                subscriber.putNext(currentData)
                            }
                            if currentData.complete {
                                subscriber.putCompletion()
                            }
                        } else if !complete {
                            subscriber.putNext(MediaResourceData(path: paths.partial, offset: 0, size: 0, complete: false))
                        }
                        
                        disposable.set(ActionDisposable { [weak context] in
                            self.dataQueue.async {
                                if let currentContext = self.cachedRepresentationContexts[key], currentContext === context {
                                    currentContext.dataSubscribers.remove(index)
                                    if currentContext.dataSubscribers.isEmpty {
                                        currentContext.disposable.dispose()
                                        self.cachedRepresentationContexts.removeValue(forKey: key)
                                    }
                                }
                            }
                        })
                        
                        if !context.initialized {
                            context.initialized = true
                            let cacheStorageBox = self.cacheStorageBox
                            let signal = self.wrappedFetchCachedResourceRepresentation.get()
                            |> take(1)
                            |> mapToSignal { fetch in
                                return fetch(resource, representation)
                                |> map(Optional.init)
                            }
                            |> deliverOn(self.dataQueue)
                            context.disposable.set(signal.startStrict(next: { [weak self, weak context] next in
                                guard let strongSelf = self else {
                                    return
                                }
                                if let next = next {
                                    var isDone = false
                                    switch next {
                                    case let .temporaryPath(temporaryPath):
                                        rename(temporaryPath, paths.complete)
                                        if let size = fileSize(paths.complete), let pathData = paths.complete.data(using: .utf8) {
                                            cacheStorageBox.update(id: pathData, size: size)
                                        }
                                        isDone = true
                                    case let .tempFile(tempFile):
                                        rename(tempFile.path, paths.complete)
                                        TempBox.shared.dispose(tempFile)
                                        if let size = fileSize(paths.complete), let pathData = paths.complete.data(using: .utf8) {
                                            cacheStorageBox.update(id: pathData, size: size)
                                        }
                                        isDone = true
                                    case .reset:
                                        let file = ManagedFile(queue: strongSelf.dataQueue, path: paths.partial, mode: .readwrite)
                                        file?.truncate(count: 0)
                                        unlink(paths.complete)
                                        if let pathData = paths.complete.data(using: .utf8) {
                                            cacheStorageBox.update(id: pathData, size: 0)
                                        }
                                    case let .data(dataPart):
                                        let file = ManagedFile(queue: strongSelf.dataQueue, path: paths.partial, mode: .append)
                                        let dataCount = dataPart.count
                                        dataPart.withUnsafeBytes { rawBytes -> Void in
                                            let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
                                            let _ = file?.write(bytes, count: dataCount)
                                        }
                                        if let file = file, let size = file.getSize(), let pathData = paths.complete.data(using: .utf8) {
                                            cacheStorageBox.update(id: pathData, size: size)
                                        }
                                    case .done:
                                        link(paths.partial, paths.complete)
                                        if let size = fileSize(paths.complete), let pathData = paths.complete.data(using: .utf8) {
                                            cacheStorageBox.update(id: pathData, size: size)
                                        }
                                        isDone = true
                                    }
                                    
                                    if let strongSelf = self, let currentContext = strongSelf.cachedRepresentationContexts[key], currentContext === context {
                                        if isDone {
                                            currentContext.disposable.dispose()
                                            strongSelf.cachedRepresentationContexts.removeValue(forKey: key)
                                        }
                                        if let size = fileSize(paths.complete) {
                                            let data = MediaResourceData(path: paths.complete, offset: 0, size: size, complete: isDone)
                                            currentContext.currentData = data
                                            for subscriber in currentContext.dataSubscribers.copyItems() {
                                                if !subscriber.onlyComplete || isDone {
                                                    subscriber.update(data)
                                                }
                                            }
                                        } else if let size = fileSize(paths.partial) {
                                            let data = MediaResourceData(path: paths.partial, offset: 0, size: size, complete: isDone)
                                            currentContext.currentData = data
                                            for subscriber in currentContext.dataSubscribers.copyItems() {
                                                if !subscriber.onlyComplete || isDone {
                                                    subscriber.update(data)
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    if let strongSelf = self, let context = strongSelf.cachedRepresentationContexts[key] {
                                        let data = MediaResourceData(path: paths.partial, offset: 0, size: 0, complete: false)
                                        context.currentData = data
                                        for subscriber in context.dataSubscribers.copyItems() {
                                            if !subscriber.onlyComplete {
                                                subscriber.update(data)
                                            }
                                        }
                                    }
                                }
                            }))
                        }
                    }
                } else {
                    subscriber.putNext(MediaResourceData(path: paths.partial, offset: 0, size: 0, complete: false))
                    subscriber.putCompletion()
                }
            }
            if attemptSynchronously {
                begin()
            } else {
                self.concurrentQueue.async(begin)
            }
            return ActionDisposable {
                disposable.dispose()
            }
        }
    }

    public func customResourceData(id: String, baseResourceId: String?, pathExtension: String?, complete: Bool, fetch: (() -> Signal<CachedMediaResourceRepresentationResult, NoError>)?, keepDuration: CachedMediaRepresentationKeepDuration, attemptSynchronously: Bool) -> Signal<MediaResourceData, NoError> {
        return Signal { subscriber in
            let disposable = MetaDisposable()

            let begin: () -> Void = {
                let paths: ResourceStorePaths
                if let baseResourceId = baseResourceId {
                    paths = self.cachedRepresentationPathsForId(MediaResourceId(baseResourceId).stringRepresentation, representationId: id, keepDuration: keepDuration)
                } else {
                    paths = self.storePathsForId(MediaResourceId(id))
                }
                if let size = fileSize(paths.complete) {
                    self.timeBasedCleanup.touch(paths: [
                        paths.complete
                    ])

                    if let pathExtension = pathExtension {
                        let symlinkPath = paths.complete + ".\(pathExtension)"
                        if fileSize(symlinkPath) == nil {
                            let _ = try? FileManager.default.linkItem(atPath: paths.complete, toPath: symlinkPath)
                        }
                        subscriber.putNext(MediaResourceData(path: symlinkPath, offset: 0, size: size, complete: true))
                        subscriber.putCompletion()
                    } else {
                        subscriber.putNext(MediaResourceData(path: paths.complete, offset: 0, size: size, complete: true))
                        subscriber.putCompletion()
                    }
                } else if let fetch = fetch {
                    if attemptSynchronously && complete {
                        subscriber.putNext(MediaResourceData(path: paths.partial, offset: 0, size: 0, complete: false))
                    }
                    self.dataQueue.async {
                        let key = CachedMediaResourceRepresentationKey(resourceId: baseResourceId, representation: id)
                        let context: CachedMediaResourceRepresentationContext
                        if let currentContext = self.cachedRepresentationContexts[key] {
                            context = currentContext
                        } else {
                            context = CachedMediaResourceRepresentationContext()
                            self.cachedRepresentationContexts[key] = context
                        }

                        let index = context.dataSubscribers.add(CachedMediaResourceRepresentationSubscriber(update: { data in
                            if !complete || data.complete {
                                if let pathExtension = pathExtension, data.complete {
                                    let symlinkPath = data.path + ".\(pathExtension)"
                                    if fileSize(symlinkPath) == nil {
                                        let _ = try? FileManager.default.linkItem(atPath: data.path, toPath: symlinkPath)
                                    }
                                    subscriber.putNext(MediaResourceData(path: symlinkPath, offset: data.offset, size: data.size, complete: data.complete))
                                } else {
                                    subscriber.putNext(data)
                                }
                            }
                            if data.complete {
                                subscriber.putCompletion()
                            }
                        }, onlyComplete: complete))
                        if let currentData = context.currentData {
                            if !complete || currentData.complete {
                                subscriber.putNext(currentData)
                            }
                            if currentData.complete {
                                subscriber.putCompletion()
                            }
                        } else if !complete {
                            subscriber.putNext(MediaResourceData(path: paths.partial, offset: 0, size: 0, complete: false))
                        }

                        disposable.set(ActionDisposable { [weak context] in
                            self.dataQueue.async {
                                if let currentContext = self.cachedRepresentationContexts[key], currentContext === context {
                                    currentContext.dataSubscribers.remove(index)
                                    if currentContext.dataSubscribers.isEmpty {
                                        currentContext.disposable.dispose()
                                        self.cachedRepresentationContexts.removeValue(forKey: key)
                                    }
                                }
                            }
                        })

                        if !context.initialized {
                            context.initialized = true
                            let cacheStorageBox = self.cacheStorageBox
                            let signal = fetch()
                            |> deliverOn(self.dataQueue)
                            context.disposable.set(signal.startStrict(next: { [weak self, weak context] next in
                                guard let strongSelf = self else {
                                    return
                                }
                                var isDone = false
                                switch next {
                                case let .temporaryPath(temporaryPath):
                                    rename(temporaryPath, paths.complete)
                                    if let size = fileSize(paths.complete), let pathData = paths.complete.data(using: .utf8) {
                                        cacheStorageBox.update(id: pathData, size: size)
                                    }
                                    isDone = true
                                case let .tempFile(tempFile):
                                    rename(tempFile.path, paths.complete)
                                    TempBox.shared.dispose(tempFile)
                                    if let size = fileSize(paths.complete), let pathData = paths.complete.data(using: .utf8) {
                                        cacheStorageBox.update(id: pathData, size: size)
                                    }
                                    isDone = true
                                case .reset:
                                    let file = ManagedFile(queue: strongSelf.dataQueue, path: paths.partial, mode: .readwrite)
                                    file?.truncate(count: 0)
                                    unlink(paths.complete)
                                    if let pathData = paths.complete.data(using: .utf8) {
                                        cacheStorageBox.update(id: pathData, size: 0)
                                    }
                                case let .data(dataPart):
                                    let file = ManagedFile(queue: strongSelf.dataQueue, path: paths.partial, mode: .append)
                                    let dataCount = dataPart.count
                                    dataPart.withUnsafeBytes { rawBytes -> Void in
                                        let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
                                        let _ = file?.write(bytes, count: dataCount)
                                    }
                                    if let file = file, let size = file.getSize(), let pathData = paths.complete.data(using: .utf8) {
                                        cacheStorageBox.update(id: pathData, size: size)
                                    }
                                case .done:
                                    link(paths.partial, paths.complete)
                                    isDone = true
                                    if let size = fileSize(paths.complete), let pathData = paths.complete.data(using: .utf8) {
                                        cacheStorageBox.update(id: pathData, size: size)
                                    }
                                }

                                if let strongSelf = self, let currentContext = strongSelf.cachedRepresentationContexts[key], currentContext === context {
                                    if isDone {
                                        currentContext.disposable.dispose()
                                        strongSelf.cachedRepresentationContexts.removeValue(forKey: key)
                                    }
                                    if let size = fileSize(paths.complete) {
                                        let data = MediaResourceData(path: paths.complete, offset: 0, size: size, complete: isDone)
                                        currentContext.currentData = data
                                        for subscriber in currentContext.dataSubscribers.copyItems() {
                                            if !subscriber.onlyComplete || isDone {
                                                subscriber.update(data)
                                            }
                                        }
                                    } else if let size = fileSize(paths.partial) {
                                        let data = MediaResourceData(path: paths.partial, offset: 0, size: size, complete: isDone)
                                        currentContext.currentData = data
                                        for subscriber in currentContext.dataSubscribers.copyItems() {
                                            if !subscriber.onlyComplete || isDone {
                                                subscriber.update(data)
                                            }
                                        }
                                    }
                                }
                            }))
                        }
                    }
                } else {
                    subscriber.putNext(MediaResourceData(path: paths.partial, offset: 0, size: 0, complete: false))
                    subscriber.putCompletion()
                }
            }
            if attemptSynchronously {
                begin()
            } else {
                self.concurrentQueue.async(begin)
            }
            return ActionDisposable {
                disposable.dispose()
            }
        }
    }
    
    public func resourceUsage(id: MediaResourceId) -> Int64 {
        let paths = self.storePathsForId(id)
        if let size = fileSize(paths.complete) {
            return Int64(size)
        } else if let size = fileSize(paths.partial, useTotalFileAllocatedSize: true) {
            return Int64(size)
        } else {
            return 0
        }
    }
    
    public func resourceUsageWithInfo(id: MediaResourceId) -> Int32 {
        let paths = self.storePathsForId(id)
        
        var value = stat()
        
        if stat(paths.complete, &value) == 0 {
            return Int32(value.st_mtimespec.tv_sec)
        }
        
        value = stat()
        
        if stat(paths.partial, &value) == 0 {
            return Int32(value.st_mtimespec.tv_sec)
        }
        
        return 0
    }
    
    public func collectResourceCacheUsage(_ ids: [MediaResourceId]) -> Signal<[MediaResourceId: Int64], NoError> {
        return Signal { subscriber in
            self.dataQueue.async {
                var result: [MediaResourceId: Int64] = [:]
                for id in ids {
                    let wrappedId = id
                    let paths = self.storePathsForId(id)
                    if let size = fileSize(paths.complete) {
                        result[wrappedId] = Int64(size)
                    } else if let size = fileSize(paths.partial, useTotalFileAllocatedSize: true) {
                        result[wrappedId] = Int64(size)
                    }
                }
                subscriber.putNext(result)
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
    
    private func updateGeneralResourceIndex(otherResourceContentType: UInt8, lowImpact: Bool, completion: @escaping () -> Void) -> Disposable {
        let basePath = self.basePath
        let storageBox = self.storageBox
        
        var isCancelled: Bool = false
        
        let processQueue = Queue(name: "UpdateResourceIndex", qos: .background)
        processQueue.async {
            if isCancelled {
                return
            }
            
            let scanContext = ScanFilesContext(path: basePath)
            
            func processStale(nextId: Data?) {
                let _ = (storageBox.enumerateItems(startingWith: nextId, limit: 1000)
                |> deliverOn(processQueue)).startStandalone(next: { ids, realNextId in
                    var staleIds: [Data] = []
                    
                    for id in ids {
                        if let name = String(data: id, encoding: .utf8) {
                            if self.resourceUsage(id: MediaResourceId(name)) == 0 {
                                staleIds.append(id)
                            }
                        } else {
                            staleIds.append(id)
                        }
                    }
                    
                    if !staleIds.isEmpty {
                        storageBox.remove(ids: staleIds)
                    }
                    
                    if realNextId == nil {
                        completion()
                    } else {
                        if lowImpact {
                            processQueue.after(0.4, {
                                processStale(nextId: realNextId)
                            })
                        } else {
                            processStale(nextId: realNextId)
                        }
                    }
                })
            }
            
            func processNext() {
                processQueue.async {
                    if isCancelled {
                        return
                    }
                    
                    let results = scanContext.nextBatch(count: 32000)
                    if results.isEmpty {
                        processStale(nextId: nil)
                        return
                    }
                    
                    storageBox.addEmptyReferencesIfNotReferenced(ids: results.map { name -> (id: Data, size: Int64) in
                        let resourceId = MediaBox.idForFileName(name: name)
                        let paths = self.storePathsForId(MediaResourceId(resourceId))
                        var size: Int64 = 0
                        if let value = fileSize(paths.complete) {
                            size = value
                        } else if let value = fileSize(paths.partial) {
                            size = value
                        }
                        return (resourceId.data(using: .utf8)!, size)
                    }, contentType: otherResourceContentType, completion: { addedCount in
                        if addedCount != 0 {
                            postboxLog("UpdateResourceIndex: added \(addedCount) unreferenced ids")
                        }
                        
                        if lowImpact {
                            processQueue.after(0.4, {
                                processNext()
                            })
                        } else {
                            processNext()
                        }
                    })
                }
            }
            
            processNext()
        }
        
        return ActionDisposable {
            isCancelled = true
        }
    }
    
    /*private func updateCacheResourceIndex(pathPrefix: String, lowImpact: Bool, completion: @escaping () -> Void) -> Disposable {
        let cacheStorageBox = self.cacheStorageBox
        
        var isCancelled: Bool = false
        
        let processQueue = Queue(name: "UpdateResourceIndex", qos: .background)
        processQueue.async {
            if isCancelled {
                return
            }
            
            let scanContext = ScanFilesContext(path: pathPrefix)
            
            func processStale(nextId: Data?) {
                let _ = (storageBox.enumerateItems(startingWith: nextId, limit: 1000)
                |> deliverOn(processQueue)).startStandalone(next: { ids, realNextId in
                    var staleIds: [Data] = []
                    
                    for id in ids {
                        if let name = String(data: id, encoding: .utf8) {
                            if self.resourceUsage(id: MediaResourceId(name)) == 0 {
                                staleIds.append(id)
                            }
                        } else {
                            staleIds.append(id)
                        }
                    }
                    
                    if !staleIds.isEmpty {
                        storageBox.remove(ids: staleIds)
                    }
                    
                    if realNextId == nil {
                        completion()
                    } else {
                        if lowImpact {
                            processQueue.after(0.4, {
                                processStale(nextId: realNextId)
                            })
                        } else {
                            processStale(nextId: realNextId)
                        }
                    }
                })
            }
            
            func processNext() {
                processQueue.async {
                    if isCancelled {
                        return
                    }
                    
                    let results = scanContext.nextBatch(count: 32000)
                    if results.isEmpty {
                        processStale(nextId: nil)
                        return
                    }
                    
                    storageBox.addEmptyReferencesIfNotReferenced(ids: results.map { name -> (id: Data, size: Int64) in
                        let resourceId = MediaBox.idForFileName(name: name)
                        let paths = self.storePathsForId(MediaResourceId(resourceId))
                        var size: Int64 = 0
                        if let value = fileSize(paths.complete) {
                            size = value
                        } else if let value = fileSize(paths.partial) {
                            size = value
                        }
                        return (resourceId.data(using: .utf8)!, size)
                    }, contentType: MediaResourceUserContentType.other.rawValue, completion: { addedCount in
                        if addedCount != 0 {
                            postboxLog("UpdateResourceIndex: added \(addedCount) unreferenced ids")
                        }
                        
                        if lowImpact {
                            processQueue.after(0.4, {
                                processNext()
                            })
                        } else {
                            processNext()
                        }
                    })
                }
            }
            
            processNext()
        }
        
        return ActionDisposable {
            isCancelled = true
        }
    }*/
    
    public func updateResourceIndex(otherResourceContentType: UInt8, lowImpact: Bool, completion: @escaping () -> Void) -> Disposable {
        return self.updateGeneralResourceIndex(otherResourceContentType: otherResourceContentType, lowImpact: lowImpact, completion: {
            completion()
        })
    }
    
    public func collectAllResourceUsage() -> Signal<[(id: String?, path: String, size: Int64)], NoError> {
        return Signal { subscriber in
            self.dataQueue.async {
                var result: [(id: String?, path: String, size: Int64)] = []
                
                var fileIds = Set<Data>()
                
                if let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: self.basePath), includingPropertiesForKeys: [.fileSizeKey, .fileResourceIdentifierKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants], errorHandler: nil) {
                    loop: for url in enumerator {
                        if let url = url as? URL {
                            if let fileId = (try? url.resourceValues(forKeys: Set([.fileResourceIdentifierKey])))?.fileResourceIdentifier as? Data {
                                if fileIds.contains(fileId) {
                                    //paths.append(url.lastPathComponent)
                                    continue loop
                                }
                            
                                if let value = (try? url.resourceValues(forKeys: Set([.fileSizeKey])))?.fileSize, value != 0 {
                                    fileIds.insert(fileId)
                                    result.append((id: MediaBox.idForFileName(name: url.lastPathComponent), path: url.lastPathComponent, size: Int64(value)))
                                    //paths.append(url.lastPathComponent)
                                }
                            }
                        }
                    }
                }
                
                subscriber.putNext(result)
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
    
    public func collectOtherResourceUsage(excludeIds: Set<MediaResourceId>, combinedExcludeIds: Set<MediaResourceId>) -> Signal<(Int64, [String], Int64), NoError> {
        return Signal { subscriber in
            self.dataQueue.async {
                var result: Int64 = 0
                
                var excludeNames = Set<String>()
                for id in combinedExcludeIds {
                    let partial = "\(self.fileNameForId(id))_partial"
                    let meta = "\(self.fileNameForId(id))_meta"
                    let complete = self.fileNameForId(id)
                    
                    excludeNames.insert(meta)
                    excludeNames.insert(partial)
                    excludeNames.insert(complete)
                }
                
                var fileIds = Set<Data>()
                
                var paths: [String] = []
                
                if let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: self.basePath), includingPropertiesForKeys: [.fileSizeKey, .fileResourceIdentifierKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants], errorHandler: nil) {
                    loop: for url in enumerator {
                        if let url = url as? URL {
                            if excludeNames.contains(url.lastPathComponent) {
                                continue loop
                            }
                            
                            if let fileId = (try? url.resourceValues(forKeys: Set([.fileResourceIdentifierKey])))?.fileResourceIdentifier as? Data {
                                if fileIds.contains(fileId) {
                                    paths.append(url.lastPathComponent)
                                    continue loop
                                }
                            
                                if let value = (try? url.resourceValues(forKeys: Set([.fileSizeKey])))?.fileSize, value != 0 {
                                    fileIds.insert(fileId)
                                    paths.append(url.lastPathComponent)
                                    result += Int64(value)
                                }
                            }
                        }
                    }
                }
                
                var cacheResult: Int64 = 0
                
                var excludePrefixes = Set<String>()
                for id in excludeIds {
                    let cachedRepresentationPrefix = self.fileNameForId(id)
                    
                    excludePrefixes.insert(cachedRepresentationPrefix)
                }
                
                if let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: self.basePath + "/cache"), includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants], errorHandler: nil) {
                    loop: for url in enumerator {
                        if let url = url as? URL {
                            if let prefix = url.lastPathComponent.components(separatedBy: ":").first, excludePrefixes.contains(prefix) {
                                continue loop
                            }
                            
                            if let value = (try? url.resourceValues(forKeys: Set([.fileSizeKey])))?.fileSize, value != 0 {
                                paths.append("cache/" + url.lastPathComponent)
                                cacheResult += Int64(value)
                            }
                        }
                    }
                }
                
                func processRecursive(directoryPath: String, subdirectoryPath: String) {
                    if let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: directoryPath), includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants], errorHandler: nil) {
                        loop: for url in enumerator {
                            if let url = url as? URL {
                                if let prefix = url.lastPathComponent.components(separatedBy: ":").first, excludePrefixes.contains(prefix) {
                                    continue loop
                                }
                                
                                if let isDirectory = (try? url.resourceValues(forKeys: Set([.isDirectoryKey])))?.isDirectory, isDirectory {
                                    processRecursive(directoryPath: url.path, subdirectoryPath: subdirectoryPath + "/\(url.lastPathComponent)")
                                } else if let value = (try? url.resourceValues(forKeys: Set([.fileSizeKey])))?.fileSize, value != 0 {
                                    paths.append("\(subdirectoryPath)/" + url.lastPathComponent)
                                    cacheResult += Int64(value)
                                }
                            }
                        }
                    }
                }
                
                processRecursive(directoryPath: self.basePath + "/animation-cache", subdirectoryPath: "animation-cache")
                
                if let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: self.basePath + "/short-cache"), includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants], errorHandler: nil) {
                    loop: for url in enumerator {
                        if let url = url as? URL {
                            if let prefix = url.lastPathComponent.components(separatedBy: ":").first, excludePrefixes.contains(prefix) {
                                continue loop
                            }
                            
                            if let value = (try? url.resourceValues(forKeys: Set([.fileSizeKey])))?.fileSize, value != 0 {
                                paths.append("short-cache/" + url.lastPathComponent)
                                cacheResult += Int64(value)
                            }
                        }
                    }
                }
                
                subscriber.putNext((result, paths, cacheResult))
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
    
    public func removeOtherCachedResources(paths: [String]) -> Signal<Float, NoError> {
        return Signal { subscriber in
            self.dataQueue.async {
                var keepPrefixes: [String] = []
                for id in self.keepResourceContexts.keys {
                    let resourcePaths = self.fileNamesForId(id)
                    keepPrefixes.append(resourcePaths.partial)
                    keepPrefixes.append(resourcePaths.complete)
                }
                
                var count: Int = 0
                let totalCount = paths.count
                if totalCount == 0 {
                    subscriber.putNext(1.0)
                    subscriber.putCompletion()
                    return
                }
                
                let reportProgress: (Int) -> Void = { count in
                    Queue.mainQueue().async {
                        subscriber.putNext(min(1.0, Float(count) / Float(totalCount)))
                    }
                }
                
                outer: for path in paths {
                    for prefix in keepPrefixes {
                        if path.starts(with: prefix) {
                            count += 1
                            continue outer
                        }
                    }
                    
                    count += 1
                    unlink(self.basePath + "/" + path)
                    reportProgress(count)
                }
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
    
    public func removeCachedResources(_ ids: [MediaResourceId], force: Bool = false, notify: Bool = false) -> Signal<Float, NoError> {
        return Signal { subscriber in
            self.dataQueue.async {
                //let uniqueIds = Set(ids.map { $0.stringRepresentation })
                let pathsToDelete: [String] = []
                
                /*for cacheType in ["cache", "short-cache"] {
                    if let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: "\(self.basePath)/\(cacheType)"), includingPropertiesForKeys: [], options: [.skipsSubdirectoryDescendants], errorHandler: nil) {
                        while let item = enumerator.nextObject() {
                            guard let url = item as? NSURL, let path = url.path, let fileName = url.lastPathComponent else {
                                continue
                            }
                            
                            if let range = fileName.range(of: ":") {
                                let resourceId = String(fileName[fileName.startIndex ..< range.lowerBound])
                                if uniqueIds.contains(resourceId) {
                                    pathsToDelete.append(path)
                                }
                            }
                        }
                    }
                }*/
                
                var count: Int = 0
                let totalCount = ids.count * 3 + pathsToDelete.count
                if totalCount == 0 {
                    subscriber.putNext(1.0)
                    subscriber.putCompletion()
                    return
                }
                
                var lastReportValue = 0
                
                let reportProgress: (Int) -> Void = { count in
                    let currentProgress = min(1.0, Float(count) / Float(totalCount))
                    let currentInteger = Int(currentProgress * 100.0)
                    if lastReportValue != currentInteger {
                        lastReportValue = currentInteger
                        subscriber.putNext(currentProgress)
                    }
                }
                
                for id in ids {
                    if !force {
                        if self.fileContexts[id] != nil {
                            count += 3
                            reportProgress(count)
                            continue
                        }
                        if self.keepResourceContexts[id] != nil {
                            count += 3
                            reportProgress(count)
                            continue
                        }
                    }
                    let paths = self.storePathsForId(id)
                    unlink(paths.complete)
                    unlink(paths.partial)
                    unlink(paths.partial + ".meta")
                    self.fileContexts.removeValue(forKey: id)
                    count += 3
                    reportProgress(count)
                }
                
                for path in pathsToDelete {
                    unlink(path)
                    count += 1
                    reportProgress(count)
                }
                
                if notify {
                    for id in ids {
                        if let context = self.statusContexts[id] {
                            context.status = .Remote(progress: 0.0)
                            for f in context.subscribers.copyItems() {
                                f(.Remote(progress: 0.0))
                            }
                        }
                    }
                }
                
                self.dataQueue.justDispatch {
                    self.didRemoveResourcesPipe.putNext(Void())
                }
                
                subscriber.putNext(1.0)
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
    
    public func removeCachedResourcesWithResult(_ ids: [MediaResourceId], force: Bool = false, notify: Bool = false) -> Signal<[MediaResourceId], NoError> {
        return Signal { subscriber in
            self.dataQueue.async {
                var removedIds: [MediaResourceId] = []
                for id in ids {
                    if !force {
                        if self.fileContexts[id] != nil {
                            continue
                        }
                        if self.keepResourceContexts[id] != nil {
                            continue
                        }
                    }
                    let paths = self.storePathsForId(id)
                    unlink(paths.complete)
                    unlink(paths.partial)
                    unlink(paths.partial + ".meta")
                    self.fileContexts.removeValue(forKey: id)
                    removedIds.append(id)
                }
                
                if notify {
                    for id in ids {
                        if let context = self.statusContexts[id] {
                            context.status = .Remote(progress: 0.0)
                            for f in context.subscribers.copyItems() {
                                f(.Remote(progress: 0.0))
                            }
                        }
                    }
                }
                
                self.dataQueue.justDispatch {
                    self.didRemoveResourcesPipe.putNext(Void())
                }
                
                subscriber.putNext(removedIds)
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
    
    public func allFileContextResourceIds() -> Signal<Set<MediaResourceId>, NoError> {
        return Signal { subscriber in
            self.dataQueue.async {
                subscriber.putNext(Set(self.fileContexts.map({ $0.key })))
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }

    public func allFileContexts() -> Signal<[(partial: String, complete: String)], NoError> {
        return Signal { subscriber in
            self.dataQueue.async {
                var result: [(partial: String, complete: String)] = []
                for (id, _) in self.fileContexts {
                    let paths = self.storePathsForId(id)
                    result.append((partial: paths.partial, complete: paths.complete))
                }
                subscriber.putNext(result)
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }

}

private final class ScanFilesContext {
    private let path: String
    private var dirHandle: UnsafeMutablePointer<DIR>?
    private let pathBuffer: UnsafeMutablePointer<Int8>
    
    init(path: String) {
        self.path = path
        self.dirHandle = opendir(path)
        self.pathBuffer = malloc(2048).assumingMemoryBound(to: Int8.self)
    }
    
    deinit {
        if let dirHandle = self.dirHandle {
            closedir(dirHandle)
        }
        free(self.pathBuffer)
    }
    
    func nextBatch(count: Int) -> [String] {
        guard let dirHandle = self.dirHandle else {
            return []
        }
        
        var result: [String] = []
        
        while true {
            guard let dirp = readdir(dirHandle) else {
                closedir(dirHandle)
                self.dirHandle = nil
                break
            }
            
            if dirp.pointee.d_type != DT_REG {
                continue
            }
            
            if strncmp(&dirp.pointee.d_name.0, ".", 1024) == 0 {
                continue
            }
            if strncmp(&dirp.pointee.d_name.0, "..", 1024) == 0 {
                continue
            }
            
            strncpy(self.pathBuffer, self.path, 1024)
            strncat(self.pathBuffer, "/", 1024)
            strncat(self.pathBuffer, &dirp.pointee.d_name.0, 1024)
            
            //puts(pathBuffer)
            //puts("\n")
            
            var value = stat()
            if stat(self.pathBuffer, &value) == 0 {
                if let itemPath = String(data: Data(bytes: &dirp.pointee.d_name.0, count: Int(dirp.pointee.d_namlen)), encoding: .utf8) {
                    result.append(itemPath)
                }
                
                /*result.totalSize += UInt64(value.st_size)
                inodes.append(InodeInfo(
                    inode: value.st_ino,
                    timestamp: Int32(clamping: value.st_mtimespec.tv_sec),
                    size: UInt32(clamping: value.st_size)
                ))*/
            }
        }
        
        return result
    }
}

/*private func scanFiles(at path: String, inodes: inout [InodeInfo]) -> ScanFilesResult {
    var result = ScanFilesResult()
    
    if let dp = opendir(path) {
        let pathBuffer = malloc(2048).assumingMemoryBound(to: Int8.self)
        defer {
            free(pathBuffer)
        }
        
        while true {
            guard let dirp = readdir(dp) else {
                break
            }
            
            if strncmp(&dirp.pointee.d_name.0, ".", 1024) == 0 {
                continue
            }
            if strncmp(&dirp.pointee.d_name.0, "..", 1024) == 0 {
                continue
            }
            strncpy(pathBuffer, path, 1024)
            strncat(pathBuffer, "/", 1024)
            strncat(pathBuffer, &dirp.pointee.d_name.0, 1024)
            
            //puts(pathBuffer)
            //puts("\n")
            
            var value = stat()
            if stat(pathBuffer, &value) == 0 {
                if value.st_mtimespec.tv_sec < minTimestamp {
                    unlink(pathBuffer)
                    result.unlinkedCount += 1
                } else {
                    result.totalSize += UInt64(value.st_size)
                    inodes.append(InodeInfo(
                        inode: value.st_ino,
                        timestamp: Int32(clamping: value.st_mtimespec.tv_sec),
                        size: UInt32(clamping: value.st_size)
                    ))
                }
            }
        }
        closedir(dp)
    }
    
    return result
}*/
