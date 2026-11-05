import AccountContext
import Combine
import MemberwiseInit
import SwiftSignalKit
import TelegramBridge
import TelegramCore

@MemberwiseInit(.public)
public class TelegramPeerProviderImpl {
    @Init(.public) private let contextProvider: ContextProvider
}

extension TelegramPeerProviderImpl: TelegramPeerProvider {
    public func peer(id: TelegramId) async -> (any TelegramPeerDetails)? {
        try? await peerPublisher(id: id).awaitForFirstValue()
    }
    
    public func peerPublisher(id: TelegramId) -> AnyPublisher<(any TelegramPeerDetails)?, Never> {
        peerPublisher { _ in EnginePeer.Id(id) }
    }
    
    public func currentPeer() async -> TelegramUserDetails? {
        try? await currentPeerPublisher().awaitForFirstValue()
    }
    
    public func currentPeerPublisher() -> AnyPublisher<TelegramUserDetails?, Never> {
        peerPublisher { context in
            context.account.peerId
        }
        .map { peer in
            peer?.sealed.user
        }
        .eraseToAnyPublisher()
    }
}

private extension TelegramPeerProviderImpl {
    func peerPublisher(
        id: @escaping (AccountContext) -> EnginePeer.Id
    ) -> AnyPublisher<(any TelegramPeerDetails)?, Never> {
        let signal = contextProvider.contextSignal()
        |> mapToSignal { context -> Signal<(EnginePeer?, EngineCachedPeerData?), NoError> in
            guard let context else { return .complete() }
            let peerId = id(context)
            return context.engine.data.subscribe(
                TelegramEngine.EngineData.Item.Peer.Peer(id: peerId),
                TelegramEngine.EngineData.Item.Peer.CachedData(id: peerId)
            )
        }
        |> map { peer, cachedData -> (any TelegramPeerDetails)? in
            peer?._asPeer().toTelegramBridgePeerDetails(cachedData: cachedData)
        }
        return signal
            .toPublisher()
            .eraseToAnyPublisher()
    }
}
