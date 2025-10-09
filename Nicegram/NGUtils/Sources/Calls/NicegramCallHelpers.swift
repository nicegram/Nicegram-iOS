import AccountContext
import FeatCalls
import NGCore
import Postbox
import TelegramCore

//  MARK: - Public Functions

public func isNicegramCallsEnabled() -> Bool {
    CallsModule.shared.getConfigUseCase().isFeatureEnabled()
}

@available(iOS 15.0, *)
public func maybePresentNicegramCallsOnboarding(
    context: AccountContext,
    peerId: PeerId
) {
    Task {
        let interlocutor = try await toCallParticipant(
            context: context,
            peerId: peerId
        )
        
        maybePresentNicegramCallsOnboarding(interlocutor: interlocutor)
    }
}

public func startNicegramCall(
    context: AccountContext,
    to peerId: PeerId
) {
    Task {
        let callsManager = CallsModule.shared.callsManager()
        
        let interlocutor = try await toCallParticipant(
            context: context,
            peerId: peerId
        )
        
        callsManager.startOutgoingCall(
            StartOutgoingCallParams(
                to: interlocutor,
                type: .personal
            )
        )
    }
}

//  MARK: - Private Functions

private func toCallParticipant(
    context: AccountContext,
    peerId: PeerId
) async throws -> CallParticipant {
    let peer = try await context.engine.data
        .get(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
        .awaitForFirstValue()
        .unwrap()
    
    guard case .user = peer else {
        throw UnexpectedError()
    }
    
    return CallParticipant(
        fullname: peer.debugDisplayTitle,
        telegramId: .init(peerId)
    )
}
