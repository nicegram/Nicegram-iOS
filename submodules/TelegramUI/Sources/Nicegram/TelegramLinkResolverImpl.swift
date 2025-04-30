import MemberwiseInit
import NGCore
import NGUtils
import Postbox
import TelegramBridge

@MemberwiseInit
class TelegramLinkResolverImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramLinkResolverImpl: TelegramLinkResolver {
    func resolve(link: String) async  throws -> ResolvedTelegramLink {
        let context = try contextProvider.context().unwrap()
        
        let resolvedUrl = try await context.sharedContext
            .resolveUrl(
                context: context,
                peerId: nil,
                url: link,
                skipUrlAuth: true
            )
            .awaitForFirstValue()
        
        switch resolvedUrl {
        case let .peer(peer, _):
            let peer = try peer.unwrap()
            return .peer(
                .init(
                    peerId: peer.id.ng_toInt64()
                )
            )
        case let .botStart(peer, _):
            return .botStart(
                .init(
                    peerId: peer.id.ng_toInt64()
                )
            )
        case let .gameStart(peerId, _):
            return .gameStart(
                .init(
                    peerId: peerId.ng_toInt64()
                )
            )
        case let .join(hash):
            return .join(
                .init(
                    hash: hash
                )
            )
        default:
            throw UnexpectedError()
        }
    }
}
