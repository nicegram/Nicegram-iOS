import AccountContext
import Combine
import MemberwiseInit
import Postbox
import SwiftSignalKit
import TelegramBridge

@MemberwiseInit(.public)
public class TelegramPeerProviderImpl {
    @Init(.public) private let contextProvider: ContextProvider
}

extension TelegramPeerProviderImpl: TelegramPeerProvider {
    public func peer(id: TelegramId) async -> (any TelegramPeerDetails)? {
        try? await peerPublisher(id: id).awaitForFirstValue()
    }
    
    public func peerPublisher(id: TelegramId) -> AnyPublisher<(any TelegramPeerDetails)?, Never> {
        peerPublisher { _ in PeerId(id) }
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
        id: @escaping (AccountContext) -> PeerId
    ) -> AnyPublisher<(any TelegramPeerDetails)?, Never> {
        let signal = contextProvider.contextSignal()
        |> mapToSignal { context -> Signal<PeerView, NoError> in
            guard let context else { return .complete() }
            return context.account.postbox.peerView(id: id(context))
        }
        |> map { $0.toTelegramBridgePeerDetails() }
        return signal
            .toPublisher()
            .eraseToAnyPublisher()
    }
}
