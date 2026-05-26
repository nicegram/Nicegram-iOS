import SwiftSignalKit

public final class TelegramSilentAuthRegistry {
    public static let shared = TelegramSilentAuthRegistry()
    private init() {}

    private let ids = Atomic<Set<AccountRecordId>>(value: [])
}

public extension TelegramSilentAuthRegistry {
    func add(_ id: AccountRecordId) {
        ids.modifyInPlace { $0.insert(id) }
    }
    
    func remove(_ id: AccountRecordId) {
        ids.modifyInPlace { $0.remove(id) }
    }
    
    func getAll() -> Set<AccountRecordId> {
        ids.with { $0 }
    }
}

private extension Atomic {
    func modifyInPlace(_ f: (inout T) -> Void) {
        _ = modify { value in
            var newValue = value
            f(&newValue)
            return newValue
        }
    }
}
