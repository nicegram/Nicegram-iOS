import AccountContext

struct WalletVerificationInterceptorImpl {
    static func shouldVerifyOnApplicationResignActive(
        context: AccountContext
    ) async -> Bool {
        do {
            let accountManager = context.sharedContext.accountManager
            
            let accessChallengeData = try await accountManager
                .accessChallengeData()
                .awaitForFirstValue()
                .data
            
            let hasTelegramPasscode = switch accessChallengeData {
            case .none:
                false
            default:
                true
            }
            
            return !hasTelegramPasscode
        } catch {
            return false
        }        
    }
}
