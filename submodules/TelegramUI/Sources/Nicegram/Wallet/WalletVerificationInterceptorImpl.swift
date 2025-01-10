import AccountContext
import MemberwiseInit
import NGUtils
import NicegramWallet

@MemberwiseInit
class WalletVerificationInterceptorImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension WalletVerificationInterceptorImpl: WalletVerificationInterceptor {
    func shouldVerifyOnApplicationResignActive() async -> Bool {
        guard let context = contextProvider.context() else {
            return false
        }
        
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
