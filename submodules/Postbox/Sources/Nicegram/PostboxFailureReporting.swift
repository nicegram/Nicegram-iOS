import Foundation
import sqlcipher
import SwiftSignalKit

// Release builds compile out `assert`, so a failed sqlite write inside
// SqliteValueBox is completely silent and only resurfaces later as an
// unexplained trap in insertOrReplaceStatement. These hooks capture the sqlite
// error while it still exists. Postbox must not depend on Firebase, so the
// channel is a closure the app fills in, mirroring setPostboxLogger. It carries
// a payload only: Postbox holds no analytics vocabulary, so the event name
// belongs with every other one, in NGUtils.
private var postboxFailureReporter: ([String: String]) -> Void = { _ in }

private let removedFolderTimestamps = Atomic<[String: CFAbsoluteTime]>(value: [:])
private let writeFailureCount = Atomic<Int>(value: 0)

public func setPostboxFailureReporter(_ f: @escaping ([String: String]) -> Void) {
    postboxFailureReporter = f
}

// A folder removed between sqlite creating a database file and its first write is
// the one way this build produces SQLITE_IOERR_FSTAT, so a failure report says
// whether a removal reached the failing database's account folder, and when.
// Called before the removal, so a removal that fails still counts. Keyed by the
// folder's name rather than its path, because sqlite may report the database's
// path resolved through the `/private` symlink while the caller's URL is not.
public func notePostboxFolderRemoval(_ folderName: String) {
    let now = CFAbsoluteTimeGetCurrent()
    let _ = removedFolderTimestamps.modify { timestamps in
        var timestamps = timestamps
        timestamps[folderName] = now
        return timestamps
    }
}

enum PostboxWriteFailureStage {
    case createTableBinary(id: Int32)
    case createTableInt64(id: Int32)
    case metaFulltextTables
    case userVersion
}

extension PostboxWriteFailureStage {
    var name: String {
        switch self {
        case .createTableBinary:
            return "create_table_binary"
        case .createTableInt64:
            return "create_table_int64"
        case .metaFulltextTables:
            return "meta_fulltext_tables"
        case .userVersion:
            return "user_version"
        }
    }

    var tableId: Int32? {
        switch self {
        case let .createTableBinary(id):
            return id
        case let .createTableInt64(id):
            return id
        case .metaFulltextTables, .userVersion:
            return nil
        }
    }
}

extension Database {
    func reportWriteFailure(_ stage: PostboxWriteFailureStage) {
        var parameters: [String: String] = [
            "code": "\(sqlite3_errcode(self.handle))",
            "count": "\(writeFailureCount.modify { $0 + 1 })",
            "errno": "\(sqlite3_system_errno(self.handle))",
            "error": String((self.currentError() ?? "unknown").prefix(100)),
            "ext_code": "\(sqlite3_extended_errcode(self.handle))",
            "stage": stage.name
        ]

        if let tableId = stage.tableId {
            parameters["table"] = "\(tableId)"
        }

        self.addDatabaseLocation(to: &parameters)

        // Free space is a property of the volume, and every app container lives
        // on the same data volume as the home directory, so this does not need
        // the database's own path. `.systemFreeSize` rather than
        // volumeAvailableCapacityForImportantUsage: the latter counts purgeable
        // space and reads large on a volume that is genuinely full, while raw
        // free space is what governs whether sqlite can write.
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeBytes = attributes[.systemFreeSize] as? NSNumber {
            parameters["free_bytes"] = "\(freeBytes.int64Value)"
        }

        postboxLog("Nicegram: postbox write failed: \(parameters)")
        postboxLogSync()

        postboxFailureReporter(parameters)
    }

    private func addDatabaseLocation(to parameters: inout [String: String]) {
        guard let filename = sqlite3_db_filename(
            self.handle,
            "main"
        ) else {
            return
        }
        let path = String(cString: filename)
        // An in-memory database has an empty filename, and "0" would read as deleted.
        guard !path.isEmpty else {
            return
        }
        parameters["db_exists"] = FileManager.default.fileExists(atPath: path) ? "1" : "0"

        // The account folder's name is a local record id, so only what follows it is sent.
        let components = path.split(separator: "/").map(String.init)
        let accountIndex = components.lastIndex { $0.hasPrefix("account-") }
        guard let accountIndex else {
            parameters["db"] = components.suffix(2).joined(separator: "/")
            return
        }
        parameters["db"] = components[(accountIndex + 1)...].joined(separator: "/")

        let removedAt = removedFolderTimestamps.with { $0[components[accountIndex]] }
        if let removedAt {
            parameters["removed_ms_ago"] = "\(Int((CFAbsoluteTimeGetCurrent() - removedAt) * 1000))"
        }
    }
}
