import MemberwiseInit
import NGUtils
import TelegramBridge

@MemberwiseInit
class TelegramPeerInfoProviderImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramPeerInfoProviderImpl: TelegramPeerInfoProvider {
    func currentPeerInfo() async throws -> TelegramPeerInfo {
        let context = try contextProvider.context().unwrap()
        let peerId = context.account.peerId
        let view = try await context.account.postbox
            .peerView(id: peerId)
            .awaitForFirstValue()
        let peer = try view.peers[peerId].unwrap()
        let cachedData = view.cachedData
        return TelegramPeerInfo(
            description: cachedData?.aboutText ?? "",
            fullname: peer.debugDisplayTitle,
            username: peer.usernameWithAtSign
        )
    }
}
