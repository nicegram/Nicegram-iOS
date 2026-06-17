import Foundation

final class MutableAllTypingDraftsView: MutablePostboxView {
    fileprivate var keys: Set<PeerAndThreadId>

    init(postbox: PostboxImpl) {
        self.keys = Set(postbox.currentTypingDrafts.keys)
    }

    func replay(postbox: PostboxImpl, transaction: PostboxTransaction) -> Bool {
        if transaction.updatedTypingDrafts.isEmpty {
            return false
        }
        var updated = false
        for (key, update) in transaction.updatedTypingDrafts {
            if update.value != nil {
                if self.keys.insert(key).inserted {
                    updated = true
                }
            } else {
                if self.keys.remove(key) != nil {
                    updated = true
                }
            }
        }
        return updated
    }

    func refreshDueToExternalTransaction(postbox: PostboxImpl) -> Bool {
        let new = Set(postbox.currentTypingDrafts.keys)
        if new == self.keys {
            return false
        }
        self.keys = new
        return true
    }

    func immutableView() -> PostboxView {
        return AllTypingDraftsView(self)
    }
}

public final class AllTypingDraftsView: PostboxView {
    public let keys: Set<PeerAndThreadId>

    init(_ view: MutableAllTypingDraftsView) {
        self.keys = view.keys
    }
}
