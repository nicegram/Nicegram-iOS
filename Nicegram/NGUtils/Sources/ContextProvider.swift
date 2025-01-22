import AccountContext
import Combine
import MemberwiseInit

@MemberwiseInit(.public)
public struct ContextProvider {
    @Init(.public) private let getContext: () -> AccountContext?
    @Init(.public) private let getContextPublisher: () -> AnyPublisher<AccountContext?, Never>
    
    public func context() -> AccountContext? {
        getContext()
    }
    
    public func contextPublisher() -> AnyPublisher<AccountContext?, Never> {
        getContextPublisher()
    }
}
