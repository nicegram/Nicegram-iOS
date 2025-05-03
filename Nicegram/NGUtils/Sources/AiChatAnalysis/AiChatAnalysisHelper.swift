import AccountContext
import Factory
import FeatAiChatAnalysis
import Postbox
import TelegramCore

public class AiChatAnalysisHelper {
    
    //  MARK: - Dependencies
    
    private let context: AccountContext
    
    @Injected(\AiChatAnalysisModule.getConfigUseCase)
    private var getConfigUseCase
    
    //  MARK: - Lifecycle
    
    public init(context: AccountContext) {
        self.context = context
    }
}

//  MARK: - Public Functions

public extension AiChatAnalysisHelper {
    func presentFromChat(peerId: PeerId?) {
        guard #available(iOS 17.0, *) else { return }
        
        Task {
            try await AiChatAnalysisPresenter().present(
                source: .chat(
                    getSourceData(
                        peerId: peerId
                    )
                )
            )
        }
    }
    
    func presentFromChatContextMenu(peerId: PeerId?) {
        guard #available(iOS 17.0, *) else { return }
        
        Task {
            try await AiChatAnalysisPresenter().present(
                source: .chatContextMenu(
                    getSourceData(
                        peerId: peerId
                    )
                )
            )
        }
    }
}

//  MARK: - Private Functions

private extension AiChatAnalysisHelper {
    func getSourceData(peerId: PeerId?) async throws -> SourceData {
        let peerId = try peerId.unwrap()
        
        let config = getConfigUseCase()
        
        let messages = try await context.engine.messages
            .allMessages(
                peerId: peerId,
                namespace: Namespaces.Message.Cloud
            )
            .awaitForFirstValue()
            .sorted { $0.timestamp < $1.timestamp }
            .suffix(config.premiumPlusSourceLimit)
            .toSourceMessages(context: context)
        
        let peer = try await getPeer(id: peerId)
        
        return SourceData(
            chatId: peerId.ng_toInt64(),
            chatFullname: peer.debugDisplayTitle,
            chatUsername: peer.usernameWithAtSign,
            messages: messages
        )
    }
    
    func getPeer(id: PeerId) async throws -> Peer {
        let view = try await context.account.postbox
            .peerView(id: id)
            .awaitForFirstValue()
        return try view.peers[id].unwrap()
    }
}
