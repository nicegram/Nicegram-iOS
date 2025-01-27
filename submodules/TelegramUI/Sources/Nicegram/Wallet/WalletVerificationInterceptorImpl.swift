import AccountContext
import MemberwiseInit
import NGUtils
import NicegramWallet

@MemberwiseInit
class WalletVerificationInterceptorImpl {
    @Init(.internal) private let sharedContextProvider: SharedContextProvider
}

extension WalletVerificationInterceptorImpl: WalletVerificationInterceptor {
    func shouldVerifyOnApplicationResignActive() async -> Bool {
        do {
            let sharedContext = try await sharedContextProvider.sharedContext()
            let accountManager = sharedContext.accountManager
            
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
