import AccountContext
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
    func resolve(link: String) async throws -> ResolvedTelegramLink {
        let resolvedUrl = try await resolve(telegramUrl: link)
        
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
    
    func resolvePeer(link: String) async throws -> TelegramLinkPeerResolution? {
        let resolvedUrl = try await resolve(telegramUrl: link)
        
        switch resolvedUrl {
        case let .peer(peer, _):
            return resolvePeer(peer: peer)
        case let .botStart(peer, _):
            return resolvePeer(peer: peer)
        case let .groupBotStart(peerId, _, _, _):
            return await resolvePeer(peerId: peerId)
        case let .gameStart(peerId, _):
            return await resolvePeer(peerId: peerId)
        case let .channelMessage(peer, _, _):
            return resolvePeer(peer: peer)
        case let .replyThreadMessage(_, messageId):
            return await resolvePeer(messageId: messageId)
        case let .replyThread(messageId):
            return await resolvePeer(messageId: messageId)
        case let .join(link):
            return try await resolvePeer(joinLink: link)
        default:
            return nil
        }
    }
}

private extension TelegramLinkResolverImpl {
    func resolve(telegramUrl: String) async throws -> ResolvedUrl {
        let context = try contextProvider.context().unwrap()
        
        let url = try await context.sharedContext
            .resolveUrl(
                context: context,
                peerId: nil,
                url: telegramUrl,
                skipUrlAuth: true
            )
            .awaitForFirstValue()
        
        if case let .nicegram(nicegram) = url,
           case let .autoJoin(autoJoin) = nicegram {
            return autoJoin.underlyingUrl
        } else {
            return url
        }
    }
}

private extension TelegramLinkResolverImpl {
    func resolvePeer(peer: Peer?) -> TelegramLinkPeerResolution? {
        peer.flatMap { .peer($0.toTelegramBridgePeer()) }
    }
    
    func resolvePeer(peerId: PeerId) async -> TelegramLinkPeerResolution? {
        do {
            let context = try contextProvider.context().unwrap()
            
            let view = try await context.account.postbox
                .peerView(id: peerId)
                .awaitForFirstValue()
            let peer = try view.peers[peerId].unwrap()
            return resolvePeer(peer: peer)
        } catch {
            return nil
        }
    }
    
    func resolvePeer(messageId: MessageId) async -> TelegramLinkPeerResolution? {
        await resolvePeer(peerId: messageId.peerId)
    }
    
    func resolvePeer(joinLink: String) async throws -> TelegramLinkPeerResolution? {
        let context = try contextProvider.context().unwrap()
        
        let state = try await context.engine.peers
            .joinLinkInformation(joinLink)
            .awaitForFirstValue()
        
        switch state {
        case let .alreadyJoined(peer):
            return resolvePeer(peer: peer._asPeer())
        case let .peek(peer, _):
            return resolvePeer(peer: peer._asPeer())
        case let .invite(invite):
            return .requestToJoin(
                .init(
                    peerType: invite.flags.isBroadcast ? .channel : .group,
                    title: invite.title
                )
            )
        case .invalidHash:
            return nil
        }
    }
}
