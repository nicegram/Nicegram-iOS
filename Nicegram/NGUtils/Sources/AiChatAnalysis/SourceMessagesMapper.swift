import AccountContext
import Factory
import FeatAiChatAnalysis
import TelegramCore

public class SourceMessagesMapper {
    
    //  MARK: - Dependencies
    
    private let context: AccountContext
    
    @Injected(\AiChatAnalysisModule.sourceDataEncoder)
    private var sourceDataEncoder
    
    //  MARK: - Lifecycle
    
    init(context: AccountContext) {
        self.context = context
    }
}

//  MARK: - Public Functions

public extension SourceMessagesMapper {
    func toSourceMessages(_ messages: [EngineRawMessage]) async -> [SourceData.Message] {
        await messages.asyncMap {
            await toSourceMessage($0)
        }
    }
}

public extension [EngineRawMessage] {
    func toSourceMessages(context: AccountContext) async -> [SourceData.Message] {
        await SourceMessagesMapper(context: context).toSourceMessages(self)
    }
}

//  MARK: - Private Functions

private extension SourceMessagesMapper {
    func toSourceMessage(_ message: EngineRawMessage) async -> SourceData.Message {
        let author = message.author?.debugDisplayTitle ?? ""
        let date = Double(message.timestamp)
        let content = await getContent(message)
        
        return SourceData.Message(
            author: author,
            date: date,
            text: content
        )
    }
    
    func getContent(_ message: EngineRawMessage) async -> String {
        var result = message.text
        
        let mediaText = message.media
            .compactMap { getText(for: $0) }
            .joined()
        result += mediaText
        
        for attribute in message.attributes {
            guard let reply = attribute as? ReplyMessageAttribute else {
                continue
            }
            
            do {
                let replyMessage = try await context.engine.data
                    .get(TelegramEngine.EngineData.Item.Messages.Message(id: reply.messageId))
                    .awaitForFirstValue()
                    .unwrap()
                    ._asMessage()
                let sourceMessage = await toSourceMessage(replyMessage)
                let sourceMessageString = sourceDataEncoder.toString(message: sourceMessage)
                result += " (Reply to: \(sourceMessageString))"
            } catch {}
        }
        
        return result
    }
    
    func getText(for media: EngineRawMedia) -> String? {
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
