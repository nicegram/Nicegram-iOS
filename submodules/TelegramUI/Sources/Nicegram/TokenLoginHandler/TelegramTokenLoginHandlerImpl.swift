import AccountContext
import Foundation
import MemberwiseInit
import NGCore
import NGUtils
import SwiftSignalKit
import TelegramAccountAuxiliaryMethods
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
        let sharedContext = try await sharedContextProvider.sharedContext()
        
        let accountId = generateAccountRecordId()
        
        TelegramSilentAuthRegistry.shared.add(accountId)
        defer { TelegramSilentAuthRegistry.shared.remove(accountId) }
        
        var account = try await createSilentUnauthorizedAccount(
            accountId: accountId,
            sharedContext: sharedContext
        )
        
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
    func createSilentUnauthorizedAccount(
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
