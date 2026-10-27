import Foundation
import SwiftSignalKit

/// An SRP answer to `account.getPassword` built somewhere other than this device — for a
/// delegated business account, by its custodian, which holds the cloud password the device
/// never sees. Repeats the three fields of the internal `PasswordKDFResult` rather than
/// widening that upstream type.
public struct SrpPasswordProof {
    let A: Data
    let M1: Data
    let srpId: Int64

    public init(
        A: Data,
        M1: Data,
        srpId: Int64
    ) {
        self.A = A
        self.M1 = M1
        self.srpId = srpId
    }
}

/// Finishes a 2FA login with a proof built elsewhere, through Telegram's own
/// `authorizeWithPassword` tail — shared, not copied — which ends in `switchToAuthorizedAccount`.
public func authorizeWithPasswordProof(
    accountManager: AccountManager<TelegramAccountManagerTypes>,
    account: UnauthorizedAccount,
    proof: SrpPasswordProof,
    syncContacts: Bool
) -> Signal<Void, AuthorizationPasswordVerificationError> {
    return authorizeWithPasswordCheck(
        accountManager: accountManager,
        account: account,
        check: checkPassword(
            account,
            srpId: proof.srpId,
            A: proof.A,
            M1: proof.M1
        ),
        syncContacts: syncContacts
    )
}
