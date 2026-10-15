import Foundation

// managedCleanupAccounts removes the account folders that the records view it
// was handed does not list. In production (crash f5a15966) that view left out
// the account being logged in, at the instant the handover had just listed it,
// and the folder was removed while its databases were opening. A folder is now
// removed only when the current state does not reference it either; a folder
// kept here is re-examined on the next pass. The rule below is the one the
// validPaths loop in managedCleanupAccounts applies: keep the two in step when
// an upstream merge changes that loop.
func accountPathsInUse(
    accountManager: AccountManager<TelegramAccountManagerTypes>,
    currentTemporarySessionId: Int64
) -> Set<String> {
    let view = accountManager._internalAccountRecordsSync()
    var paths = Set<String>()
    for record in view.records {
        if let temporarySessionId = record.temporarySessionId, temporarySessionId != currentTemporarySessionId {
            continue
        }
        paths.insert(accountRecordIdPathName(record.id))
    }
    if let record = view.currentAuthAccount {
        paths.insert(accountRecordIdPathName(record.id))
    }
    for id in TelegramSilentAuthRegistry.shared.getAll() {
        paths.insert(accountRecordIdPathName(id))
    }
    return paths
}
