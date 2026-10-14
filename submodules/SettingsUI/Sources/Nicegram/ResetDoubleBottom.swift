import NGData
import SwiftSignalKit
import TelegramCore

func resetDoubleBottom(accountManager: AccountManager<TelegramAccountManagerTypes>) {
    VarSystemNGSettings.isDoubleBottomOn = false
    VarSystemNGSettings.inDoubleBottom = false
    let _ = accountManager.transaction({ transaction -> Void in
        for record in transaction.getRecords() {
            transaction.updateRecord(record.id) { record in
                guard let record = record else { return nil }
                var attributes = record.attributes
                attributes.removeAll { $0.isHiddenAccountAttribute }
                return AccountRecord(
                    id: record.id,
                    attributes: attributes,
                    temporarySessionId: record.temporarySessionId
                )
            }
        }
    }).start()
}

// Reads the challenge rather than trusting the store's result: disabling can report an error after the passcode is already gone
func resetDoubleBottomIfPasscodeRemoved(accountManager: AccountManager<TelegramAccountManagerTypes>) {
    let _ = (accountManager.transaction { transaction -> PostboxAccessChallengeData in
        return transaction.getAccessChallengeData()
    }
    |> deliverOnMainQueue).start(next: { challenge in
        if case .none = challenge {
            resetDoubleBottom(accountManager: accountManager)
        }
    })
}
