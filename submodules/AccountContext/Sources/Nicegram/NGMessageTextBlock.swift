import TelegramCore

public struct MessageTextBlock {
    let start: String
    let end: String
}

public extension MessageTextBlock {
    static let ngOriginalText = MessageTextBlock(
        start: "\n\n[original]\n",
        end: "\u{2062}"
    )
    
    static let ngTranslation = MessageTextBlock(
        start: "\n\n🗨 GTranslate\n",
        end: "\u{2063}"
    )
}

public extension EngineRawMessage {
    func hasTextBlock(_ block: MessageTextBlock) -> Bool {
        textBlockRange(block) != nil
    }
    
    func addTextBlock(
        text: String,
        block: MessageTextBlock,
        context: AccountContext
    ) {
        var newText = self.text
        newText += "\(block.start)\(text)\(block.end)"
        updateMessageText(
            message: self,
            newMessageText: newText,
            context: context
        )
    }
    
    func removeTextBlock(
        block: MessageTextBlock,
        context: AccountContext
    ) {
        if let range = textBlockRange(block) {
            var newText = self.text
            newText.removeSubrange(range)
            updateMessageText(
                message: self,
                newMessageText: newText,
                context: context
            )
        }
    }
}

private extension EngineRawMessage {
    func textBlockRange(_ block: MessageTextBlock) -> Range<String.Index>? {
        text.findSubrange(
            start: block.start,
            end: block.end
        )
    }
}

public func updateMessageText(
    message: EngineRawMessage,
    newMessageText: String,
    context: AccountContext
) {
    let _ = TelegramRawPostbox.updateMessage(
        message.id,
        engine: context.engine,
        update: { _, attributes in
            (newMessageText, attributes)
        }
    ).start()
}

private extension String {
    func findSubrange(start: String, end: String) -> Range<Index>? {
        guard let startRange = range(of: start) else {
            return nil
        }
        guard let endRange = self[startRange.upperBound...].range(of: end) else {
            return nil
        }
        return startRange.lowerBound..<endRange.upperBound
    }
}
