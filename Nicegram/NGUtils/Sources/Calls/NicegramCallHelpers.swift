import AccountContext
import FeatCalls
import NGCore
import TelegramCore

//  MARK: - Public Functions

public func isNicegramCallsEnabled() -> Bool {
    CallsModule.shared.getConfigUseCase().isFeatureEnabled()
}

public extension CallParticipant {
    static func make(
        peer: EnginePeer
    ) throws -> CallParticipant {
        guard case let .user(user) = peer, user.botInfo == nil else {
            throw UnexpectedError()
        }
        
        return CallParticipant(
            fullname: peer.debugDisplayTitle,
            telegramId: .init(peer.id)
        )
    }
    
    static func make(
        context: AccountContext,
        peerId: EnginePeer.Id
    ) async throws -> CallParticipant {
        let peer = try await context.engine.data
            .get(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
            .awaitForFirstValue()
            .unwrap()
        
        return try .make(peer: peer)
    }
}
