import AccountContext
import Combine
import MemberwiseInit

@MemberwiseInit(.public)
public struct SharedContextProvider {
    public let sharedContext: () async throws -> SharedAccountContext
    public let sharedContextPublisher: () -> AnyPublisher<SharedAccountContext, Never>
}

@MemberwiseInit(.public)
public struct ContextProvider {
    public let context: () -> AccountContext?
    public let contextPublisher: () -> AnyPublisher<AccountContext?, Never>
}
