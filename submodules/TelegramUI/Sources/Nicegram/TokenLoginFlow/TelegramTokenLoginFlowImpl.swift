import AccountContext
import Foundation
import MemberwiseInit
import NGCore
import NGUtils
import SwiftSignalKit
import TelegramAccountAuxiliaryMethods
import TelegramBridge
import TelegramCore

@MemberwiseInit
final class TelegramTokenLoginFlowImpl {
    @Init(.internal) private let sharedContextProvider: SharedContextProvider
}

extension TelegramTokenLoginFlowImpl: TelegramTokenLoginFlow {
    func run(
        approveToken: (Data) async throws -> Void,
        password: TelegramLoginPassword
    ) async throws -> TelegramId? {
        let sharedContext = try await sharedContextProvider.sharedContext()
        let accountId = generateAccountRecordId()
        // The silent account's id stays registered while it lives, or the account manager's
        // cleanup deletes its directory.
        TelegramSilentAuthRegistry.shared.add(accountId)
        defer { TelegramSilentAuthRegistry.shared.remove(accountId) }

        var account = try await Self.silentAccount(
            accountId: accountId,
            sharedContext: sharedContext
        )
        guard case let .displayToken(token) = try await Self.exportToken(
            account: &account,
            sharedContext: sharedContext
        ) else {
            throw UnexpectedError()
        }
        // Load-bearing: the stream subscribes as it is made, here, before the approval. Telegram
        // sends updateLoginToken once, possibly while the approval is still running, and keeps
        // nothing for a late subscriber. Moving this below the call, or into a Task, loses the
        // event.
        let accepted = account.updateLoginTokenEvents.asyncStream(.bufferingNewest(1))
        do {
            try await approveToken(token.value)
        } catch is TimeoutError {
            // The approver stopped waiting, not the approval, which may still land: the
            // acceptance below decides.
        }
        // Running out fails the run; it never re-exports, which would mint a token nobody approved.
        try await accepted.firstValue(timeout: Self.acceptanceTimeout)
        try await Self.signIn(
            account: &account,
            password: password,
            sharedContext: sharedContext
        )
        return try await Self.signedInTelegramId(account: account)
    }
}

private extension TelegramTokenLoginFlowImpl {
    static let acceptanceTimeout: TimeInterval = 20

    /// A not-yet-authorized account beside the app's own, with no auth record, so the app's
    /// sign-in screens never appear for it.
    static func silentAccount(
        accountId: AccountRecordId,
        sharedContext: SharedAccountContext
    ) async throws -> UnauthorizedAccount {
        let sharedContext = try (sharedContext as? SharedAccountContextImpl).unwrap()
        let accountSignal = accountWithId(
            accountManager: sharedContext.accountManager,
            networkArguments: sharedContext.networkArguments,
            id: accountId,
            encryptionParameters: sharedContext.encryptionParameters,
            supplementary: false,
            isSupportUser: false,
            rootPath: sharedContext.rootPath,
            beginWithTestingEnvironment: false,
            backupData: nil,
            auxiliaryMethods: makeTelegramAccountAuxiliaryMethods(uploadInBackground: nil)
        )
        |> mapToSignal { result in
            if case let .unauthorized(unauthorizedAccount) = result {
                return .single(unauthorizedAccount)
            } else {
                return .complete()
            }
        }
        let account = try await accountSignal.awaitForFirstValue()
        account.shouldBeServiceTaskMaster.set(.single(.always))
        return account
    }

    /// Follows `changeAccountAndRetry` to the datacentre it names. The accounts already signed in
    /// here go as `except_ids`, as the app's own QR login sends them, so Telegram refuses to sign
    /// one of them in a second time instead of adding a duplicate.
    static func exportToken(
        account: inout UnauthorizedAccount,
        sharedContext: SharedAccountContext
    ) async throws -> ExportAuthTransferTokenResult {
        let otherAccountUserIds = try await signedInUserIds(sharedContext: sharedContext)
        let result = try await TelegramEngineUnauthorized(account: account).auth
            .exportAuthTransferToken(
                accountManager: sharedContext.accountManager,
                otherAccountUserIds: otherAccountUserIds,
                syncContacts: false
            )
            .awaitForFirstValue()
        switch result {
        case let .changeAccountAndRetry(newAccount):
            account = newAccount
            return try await exportToken(
                account: &account,
                sharedContext: sharedContext
            )
        default:
            return result
        }
    }

    /// The silent account is a production one, so only production accounts can collide with it.
    static func signedInUserIds(sharedContext: SharedAccountContext) async throws -> [EnginePeer.Id.Id] {
        let (_, accounts, _) = try await sharedContext.activeAccountContexts.awaitForFirstValue()
        return accounts
            .map { $0.1.account }
            .filter { !$0.testingEnvironment }
            .map { $0.peerId.id }
    }

    static func signIn(
        account: inout UnauthorizedAccount,
        password: TelegramLoginPassword,
        sharedContext: SharedAccountContext
    ) async throws {
        switch try await exportToken(
            account: &account,
            sharedContext: sharedContext
        ) {
        case .loggedIn:
            return
        case let .passwordRequested(passwordAccount):
            try await signIn(
                passwordAccount: passwordAccount,
                password: password,
                sharedContext: sharedContext
            )
        default:
            // A fresh token: the approval did not land on this connection, and exporting
            // again would only mint another.
            throw UnexpectedError()
        }
    }

    static func signIn(
        passwordAccount: UnauthorizedAccount,
        password: TelegramLoginPassword,
        sharedContext: SharedAccountContext
    ) async throws {
        switch password {
        case let .proof(proof):
            try await signIn(
                passwordAccount: passwordAccount,
                proof: proof,
                sharedContext: sharedContext
            )
        case let .raw(rawPassword):
            try await authorizeWithPassword(
                accountManager: sharedContext.accountManager,
                account: passwordAccount,
                password: rawPassword.unwrap(),
                syncContacts: false
            ).awaitForCompletion()
        }
    }

    /// A refused check is asked again over freshly read parameters and never shown: whoever
    /// builds the proof may have had a superseded SRP session, or a wrong password it can still
    /// correct. After `proof.attemptLimit` proofs, or on a refusal no new proof changes, it throws
    /// `TelegramPasswordCheckRefusedError`. A cancelled task never sends a check, and a check it
    /// cuts short is never read as a sign-in.
    static func signIn(
        passwordAccount: UnauthorizedAccount,
        proof: TelegramLoginPassword.Proof,
        sharedContext: SharedAccountContext
    ) async throws {
        for attempt in 1...proof.attemptLimit {
            let parameters = try await srpParameters(account: passwordAccount)
            let srpProof = try await proof.make(parameters)
            try Task.checkCancellation()
            let check = authorizeWithPasswordProof(
                accountManager: sharedContext.accountManager,
                account: passwordAccount,
                proof: SrpPasswordProof(
                    A: srpProof.a,
                    M1: srpProof.m1,
                    srpId: srpProof.srpId
                ),
                syncContacts: false
            )
            |> mapError { AuthorizationPasswordVerificationErrorWrapper(error: $0) }
            do {
                try await check.awaitForCompletion()
                // A cancelled task ends the stream without an error: that is not a sign-in.
                try Task.checkCancellation()
                return
            } catch let wrapper as AuthorizationPasswordVerificationErrorWrapper {
                guard wrapper.error.asksForAnotherProof,
                      attempt < proof.attemptLimit else {
                    throw TelegramPasswordCheckRefusedError()
                }
            }
        }
        throw UnexpectedError()
    }

    /// From the state Telegram has just written, not from the account list, which omits the account
    /// until its user loads; it does not wait for the account to load either.
    static func signedInTelegramId(account: UnauthorizedAccount) async throws -> TelegramId? {
        try await account.postbox.transaction { transaction in
            (transaction.getState() as? AuthorizedAccountState)?.peerId
        }
        .awaitForFirstValue()
        .map { TelegramId($0) }
    }

    static func srpParameters(account: UnauthorizedAccount) async throws -> TelegramSrpParameters {
        let authData = try await TelegramEngineUnauthorized(account: account).auth
            .twoStepAuthData()
            .awaitForFirstValue()
        guard case let .sha256_sha256_PBKDF2_HMAC_sha512_sha256_srp(salt1, salt2, _, g, p) = authData.currentPasswordDerivation,
              let session = authData.srpSessionData else {
            throw UnexpectedError()
        }
        return TelegramSrpParameters(
            algo: "PasswordKdfAlgoSHA256SHA256PBKDF2HMACSHA512iter100000SHA256ModPow",
            g: g,
            p: p,
            salt1: salt1,
            salt2: salt2,
            srpB: session.B,
            srpId: session.id
        )
    }
}

/// TelegramCore's `AuthorizationPasswordVerificationError` as a Swift `Error`, so the check's
/// `awaitForCompletion()` throws it as it is: the enum is not one.
private struct AuthorizationPasswordVerificationErrorWrapper: Error {
    let error: AuthorizationPasswordVerificationError
}

private extension AuthorizationPasswordVerificationError {
    /// A stale SRP session (`SRP_ID_INVALID`) arrives as `.generic`: TelegramCore names only a
    /// flood wait and a wrong password apart. Fresh parameters are what both a stale session and a
    /// wrong password need; a flood wait no new proof changes.
    var asksForAnotherProof: Bool {
        switch self {
        case .generic, .invalidPassword:
            true
        case .limitExceeded:
            false
        }
    }
}
