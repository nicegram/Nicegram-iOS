import AccountContext
import FeatCalls
import NGCore
import Postbox
import TelegramCore

//  MARK: - Public Functions

public func isNicegramCallsEnabled() -> Bool {
    CallsModule.shared.getConfigUseCase().isFeatureEnabled()
}

public extension CallParticipant {
    static func make(
        peer: Peer
    ) throws -> CallParticipant {
        guard let user = peer as? TelegramUser, user.botInfo == nil else {
            throw UnexpectedError()
        }
        
        return CallParticipant(
            fullname: peer.debugDisplayTitle,
            telegramId: .init(peer.id)
        )
    }
    
    static func make(
        context: AccountContext,
        peerId: PeerId
    ) async throws -> CallParticipant {
        let peer = try await context.engine.data
            .get(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
            .awaitForFirstValue()
            .unwrap()
        
        return try .make(peer: peer._asPeer())
    }
}
