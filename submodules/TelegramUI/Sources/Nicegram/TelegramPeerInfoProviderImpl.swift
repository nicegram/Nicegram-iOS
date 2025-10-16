import MemberwiseInit
import NGUtils
import TelegramBridge
import TelegramCore

@MemberwiseInit
class TelegramPeerInfoProviderImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramPeerInfoProviderImpl: TelegramPeerInfoProvider {
    func currentPeerInfo() async throws -> TelegramPeerInfo {
        let context = try await contextProvider.awaitContext()
        let peerId = context.account.peerId
        let view = try await context.account.postbox
            .peerView(id: peerId)
            .awaitForFirstValue()
        
        let peer = try view.peers[peerId].unwrap()
        let user = peer as? TelegramUser
        
        let cachedData = view.cachedData
        let cachedUserData = cachedData as? CachedUserData
        
        return TelegramPeerInfo(
            id: .init(peerId),
            birthday: .init(cachedUserData?.birthday),
            description: cachedData?.aboutText ?? "",
            fullname: peer.debugDisplayTitle,
            isPremium: user?.flags.contains(.isPremium) ?? false,
            username: peer.usernameWithAtSign
        )
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
