import AccountContext
import FeatAiReply
import TelegramBridge
import TelegramCore

public final class AiReplyHelper {
    private let context: AccountContext
    
    public init(context: AccountContext) {
        self.context = context
    }
}

public extension AiReplyHelper {
    static func isEnabled() -> Bool {
        guard #available(iOS 15.0, *) else { return false }
        return AiReplyModule.shared.getAiReplyGenerationConfigUseCase()().enabled
    }
    
    func present(
        messageId: EngineMessage.Id,
        draftText: String?,
        onSelectReply: @escaping (String) -> Void
    ) {
        guard #available(iOS 15.0, *) else { return }
        
        Task { @MainActor in
            AiReplyPresenter().present(
                source: AiReplySource(
                    messageId: messageId.ng_toTelegramMessageId(),
                    replyText: draftText
                ),
                onSelectReply: onSelectReply
            )
        }
    }
}

private extension EngineMessage.Id {
    func ng_toTelegramMessageId() -> TelegramMessageId {
        TelegramMessageId(
            peerId: TelegramId(peerId),
            namespace: namespace,
            id: id
        )
    }
}
