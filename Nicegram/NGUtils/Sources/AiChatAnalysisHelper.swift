import AccountContext
import Factory
import FeatAiChatAnalysis
import Postbox
import TelegramCore

public class AiChatAnalysisHelper {
    private let context: AccountContext
    
    @Injected(\AiChatAnalysisModule.getConfigUseCase)
    private var getConfigUseCase
    
    public init(context: AccountContext) {
        self.context = context
    }
}

public extension AiChatAnalysisHelper {
    func presentSession(peerId: PeerId?) {
        guard #available(iOS 17.0, *) else { return }
        
        Task {
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
                .compactMap { message -> SourceData.Message? in
                    do {
                        let author = try message.author.unwrap()
                        
                        let mediaText = message.media
                            .compactMap { getText(for: $0) }
                            .joined()
                        let text = message.text + mediaText
                        
                        return SourceData.Message(
                            author: author.debugDisplayTitle,
                            date: Double(message.timestamp),
                            text: text
                        )
                    } catch {
                        return nil
                    }
                }
            
            let peer = try await getPeer(id: peerId)
            
            let sourceData = SourceData(
                chatId: peerId.ng_toInt64(),
                chatFullname: peer.debugDisplayTitle,
                chatUsername: peer.usernameWithAtSign,
                messages: messages
            )
            
            await AiChatAnalysisPresenter().presentFromChat(sourceData)
        }
    }
}

private extension AiChatAnalysisHelper {
    func getPeer(id: PeerId) async throws -> Peer {
        let view = try await context.account.postbox
            .peerView(id: id)
            .awaitForFirstValue()
        return try view.peers[id].unwrap()
    }
    
    func getText(for media: Media) -> String? {
        switch media {
        case let media as TelegramMediaFile:
            "[File_attached_\(media.fileName ?? media.mimeType)]"
        case _ as TelegramMediaImage:
            "[Image_attached]"
        default:
            nil
        }
    }
}
