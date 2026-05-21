import AccountContext
import Foundation
import MemberwiseInit
import NGCore
import SwiftSignalKit
import TelegramBridge
import TelegramCore

@MemberwiseInit(.public)
public final class TelegramTokenLoginHandlerImpl {
    @Init(.public) private let sharedContextProvider: SharedContextProvider
}

extension TelegramTokenLoginHandlerImpl: TelegramTokenLoginHandler {
    public func login(
        approveToken: (Data) async throws -> Void,
        twofaPassword: String?
    ) async throws {
        let suppressionToken = TelegramAuthUISuppressor.shared.suppress()
        defer { suppressionToken.cancel() }
        
        let sharedContext = try await sharedContextProvider.sharedContext()
        var account = try await getOrCreateUnauthorizedAccount(sharedContext: sharedContext)
        
        let token = try await generateToken(
            account: &account,
            sharedContext: sharedContext
        )
        
        try await approveToken(token)
        
        try await completeLogin(
            account: &account,
            sharedContext: sharedContext,
            twofaPassword: twofaPassword
        )
    }
}

//  MARK: - Steps

private extension TelegramTokenLoginHandlerImpl {
    func generateToken(
        account: inout UnauthorizedAccount,
        sharedContext: SharedAccountContext
    ) async throws -> Data {
        let result = try await internalExportLoginToken(
            account: &account,
            sharedContext: sharedContext
        )
        
        if case let .displayToken(token) = result {
            return token.value
        } else {
            throw UnexpectedError()
        }
    }
    
    func completeLogin(
        account: inout UnauthorizedAccount,
        sharedContext: SharedAccountContext,
        twofaPassword: String?
    ) async throws {
        let result = try await internalExportLoginToken(
            account: &account,
            sharedContext: sharedContext
        )
        
        switch result {
        case .loggedIn:
            break
        case let .passwordRequested(account):
            try await authorizeWithPassword(
                accountManager: sharedContext.accountManager,
                account: account,
                password: twofaPassword.unwrap(),
                syncContacts: false
            ).awaitForCompletion()
        default:
            throw UnexpectedError()
        }
    }
}

//  MARK: - Helpers

private extension TelegramTokenLoginHandlerImpl {
    func getOrCreateUnauthorizedAccount(
        sharedContext: SharedAccountContext
    ) async throws -> UnauthorizedAccount {
        let currentAuth = try await sharedContext.activeAccountContexts.awaitForFirstValue().currentAuth
        if let currentAuth {
            return currentAuth
        } else {
            return try await createAuth(sharedContext: sharedContext)
        }
    }
    
    func createAuth(
        sharedContext: SharedAccountContext
    ) async throws -> UnauthorizedAccount {
        _ = try await sharedContext.accountManager
            .transaction { $0.createAuth([]) }
            .awaitForFirstValue()
            .unwrap()
        
        let createdAuthSignal = sharedContext.activeAccountContexts
        |> mapToSignal { _, _, currentAuth in
            if let currentAuth {
                return .single(currentAuth)
            } else {
                return .complete()
            }
        }
        |> timeout(5, queue: .mainQueue(), alternate: .complete())
        let createdAuth = try await createdAuthSignal.awaitForFirstValue()
        
        return createdAuth
    }
    
    func internalExportLoginToken(
        account: inout UnauthorizedAccount,
        sharedContext: SharedAccountContext
    ) async throws -> ExportAuthTransferTokenResult {
        let result = try await TelegramEngineUnauthorized(account: account).auth
            .exportAuthTransferToken(
                accountManager: sharedContext.accountManager,
                otherAccountUserIds: [],
                syncContacts: false
            )
            .awaitForFirstValue()
        
        switch result {
        case let .changeAccountAndRetry(newAccount):
            account = newAccount
            return try await internalExportLoginToken(account: &account, sharedContext: sharedContext)
        default:
            return result
        }
    }
}
