import MemberwiseInit
import NGCore
import NGUtils
import Postbox
import TelegramBridge

@MemberwiseInit
class TelegramChatInviteCheckerImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramChatInviteCheckerImpl: TelegramChatInviteChecker {
    func check(inviteHash: String) async throws -> TelegramChatInvite {
        let context = try contextProvider.context().unwrap()
        
        let result = try await context.engine.peers
            .joinLinkInformation(inviteHash)
            .awaitForFirstValue()
        
        let peerId: PeerId?
        switch result {
        case let .alreadyJoined(peer):
            peerId = peer.id
        case let .peek(peer, _):
            peerId = peer.id
        case .invite, .invalidHash:
            peerId = nil
        }
        
        return TelegramChatInvite(
            peerId: peerId?.ng_toInt64()
        )
    }
}
