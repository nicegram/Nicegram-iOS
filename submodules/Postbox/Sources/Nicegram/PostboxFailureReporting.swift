import Foundation
import sqlcipher

// Release builds compile out `assert`, so a failed sqlite write inside
// SqliteValueBox is completely silent and only resurfaces later as an
// unexplained trap in insertOrReplaceStatement. These hooks capture the sqlite
// error while it still exists. Postbox must not depend on Firebase, so the
// channel is a closure the app fills in, mirroring setPostboxLogger. It carries
// a payload only: Postbox holds no analytics vocabulary, so the event name
// belongs with every other one, in NGUtils.
private var postboxFailureReporter: ([String: String]) -> Void = { _ in }

public func setPostboxFailureReporter(_ f: @escaping ([String: String]) -> Void) {
    postboxFailureReporter = f
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
            "error": String((self.currentError() ?? "unknown").prefix(100)),
            "ext_code": "\(sqlite3_extended_errcode(self.handle))",
            "stage": stage.name
        ]

        if let tableId = stage.tableId {
            parameters["table"] = "\(tableId)"
        }

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
}
