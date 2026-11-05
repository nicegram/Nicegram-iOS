import AccountContext
import NGCore
import TelegramCore

class AutoJoinHandler {
    private let params: OpenResolvedUrlParams
    private var context: AccountContext { params.context }
    
    init(_ params: OpenResolvedUrlParams) {
        self.params = params
    }
}

extension AutoJoinHandler {
    func handle(_ autoJoin: ResolvedUrl.Nicegram.AutoJoin) async {
        var mappedUrl = autoJoin.underlyingUrl
        
        do {
            switch autoJoin.underlyingUrl {
            case let .peer(peer, _):
                let peer = try peer.unwrap()
                
                switch EnginePeer(peer) {
                case let .user(user) where user.botInfo != nil:
                    try await startBot(peer: peer, payload: nil)
                case .channel, .legacyGroup:
                    try await join(peerId: peer.id)
                default:
                    break
                }
            case let .botStart(peer, payload):
                try await startBot(peer: peer, payload: payload)
                mappedUrl = .peer(peer, .default)
            case let .channelMessage(peer, _, _):
                try await join(peerId: peer.id)
            case let .join(link):
                let peer = try await join(inviteLink: link)
                mappedUrl = .peer(peer, .default)
            default:
                break
            }
        } catch {}
        
        var params = params
        params.resolvedUrl = mappedUrl
        await openResolvedUrlImpl(params)
    }
}

private extension AutoJoinHandler {
    func join(
        inviteLink: String
    ) async throws -> EngineRawPeer {
        let result = try await context.engine.peers
            .joinChatInteractively(with: inviteLink)
            .awaitForFirstValue()
        switch result {
        case let .joined(peer):
            return try peer.unwrap()._asPeer()
        case .webView:
            throw UnexpectedError()
        }
    }

    func join(
        peerId: EnginePeer.Id
    ) async throws {
        try await context.peerChannelMemberCategoriesContextsManager
            .join(
                engine: context.engine,
                peerId: peerId,
                hash: nil
            )
            .awaitForCompletion()
    }

    func startBot(
        peer: EngineRawPeer,
        payload: String?
    ) async throws {
        try? await unblockIfNeeded(peer: peer)
        
        try await context.engine.messages
            .requestStartBot(botPeerId: peer.id, payload: payload)
            .awaitForCompletion()
    }

    func unblockIfNeeded(
        peer: EngineRawPeer
    ) async throws {
        let isBlocked = try await context.engine.data
            .get(TelegramEngine.EngineData.Item.Peer.IsBlocked(id: peer.id))
            .awaitForFirstValue()
        
        guard case .known(true) = isBlocked else {
            return
        }
        
        try await context.engine.privacy
            .requestUpdatePeerIsBlocked(
                peerId: peer.id,
                isBlocked: false
            )
            .awaitForCompletion()
    }
}
