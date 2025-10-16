import AccountContext
import Combine
import Foundation
import MemberwiseInit
import SwiftSignalKit

@MemberwiseInit(.public)
public struct SharedContextProvider {
    public let sharedContext: () async throws -> SharedAccountContext
    public let sharedContextPublisher: () -> AnyPublisher<SharedAccountContext, Never>
    public let sharedContextSignal: () -> Signal<SharedAccountContext, NoError>
}

@MemberwiseInit(.public)
public struct ContextProvider {
    public let context: () -> AccountContext?
    public let contextPublisher: () -> AnyPublisher<AccountContext?, Never>
    public let contextSignal: () -> Signal<AccountContext?, NoError>
    
    public func awaitContext(
        timeout: Double = 5
    ) async throws -> AccountContext {
        try await contextPublisher()
            .compactMap { $0 }
            .timeout(.seconds(timeout), scheduler: RunLoop.main)
            .awaitForFirstValue()
    }
}
