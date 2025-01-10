import AccountContext
import MemberwiseInit

@MemberwiseInit(.public)
public struct ContextProvider {
    @Init(.public) private let contextValue: () -> AccountContext?
    
    public func context() -> AccountContext? {
        contextValue()
    }
}
