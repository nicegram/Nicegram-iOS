import EsimAuth

public protocol GetUserVerificationStatusUseCase {
    func isUserVerifiedWithTelegram() -> Bool
}

public class GetUserVerificationStatusUseCaseImpl {
    
    //  MARK: - Dependencies
    
    private let esimAuth: EsimAuth
    
    //  MARK: - Lifecycle
    
    public init(esimAuth: EsimAuth) {
        self.esimAuth = esimAuth
    }
    
}

extension GetUserVerificationStatusUseCaseImpl: GetUserVerificationStatusUseCase {
    public func isUserVerifiedWithTelegram() -> Bool {
        guard let currentUser = esimAuth.currentUser else {
            return false
        }
        return currentUser.linkedProviders.contains(.telegram)
    }
}
