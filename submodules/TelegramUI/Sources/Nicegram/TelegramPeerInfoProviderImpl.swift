import Combine
import MemberwiseInit
import NGUtils
import Postbox
import SwiftSignalKit
import TelegramBridge
import TelegramCore

@MemberwiseInit
class TelegramPeerInfoProviderImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramPeerInfoProviderImpl: TelegramPeerInfoProvider {
    func currentPeerInfo() async throws -> TelegramPeerInfo {
        try await currentPeerInfoPublisher().awaitForFirstValue().unwrap()
    }
    
    func currentPeerInfoPublisher() -> AnyPublisher<TelegramPeerInfo?, Never> {
        let signal = contextProvider.contextSignal()
        |> mapToSignal { context -> Signal<PeerView, NoError> in
            guard let context else { return .complete() }
            return context.account.postbox.peerView(id: context.account.peerId)
        }
        |> map { view -> TelegramPeerInfo? in
            do {
                let peer = try view.peers[view.peerId].unwrap()
                let user = peer as? TelegramUser
                
                let cachedData = view.cachedData
                let cachedUserData = cachedData as? CachedUserData
                
                return TelegramPeerInfo(
                    id: .init(peer.id),
                    birthday: .init(cachedUserData?.birthday),
                    description: cachedData?.aboutText ?? "",
                    fullname: peer.debugDisplayTitle,
                    isPremium: user?.flags.contains(.isPremium) ?? false,
                    username: peer.usernameWithAtSign
                )
            } catch {
                return nil
            }
        }
        return signal
            .toPublisher()
            .eraseToAnyPublisher()
    }
}

private extension TelegramBridge.TelegramBirthday {
    init(_ birthday: TelegramCore.TelegramBirthday) {
        self.init(
            day: birthday.day,
            month: birthday.month,
            year: birthday.year
        )
    }
    
    init?(_ birthday: TelegramCore.TelegramBirthday?) {
        if let birthday {
            self.init(birthday)
        } else {
            return nil
        }
    }
}
