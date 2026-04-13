import AccountContext
import FeatAiReply
import Postbox
import TelegramBridge

public final class AiReplyHelper {
    private let context: AccountContext
    
    public init(context: AccountContext) {
        self.context = context
    }
}

public extension AiReplyHelper {
    func present(
        messageId: MessageId,
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

private extension MessageId {
    func ng_toTelegramMessageId() -> TelegramMessageId {
        TelegramMessageId(
            peerId: TelegramId(peerId),
            namespace: namespace,
            id: id
        )
    }
}
