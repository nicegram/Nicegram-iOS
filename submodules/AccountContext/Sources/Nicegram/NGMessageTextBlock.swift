import Postbox

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

public extension Message {
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

private extension Message {
    func textBlockRange(_ block: MessageTextBlock) -> Range<String.Index>? {
        text.findSubrange(
            start: block.start,
            end: block.end
        )
    }
}

public func updateMessageText(
    message: Message,
    newMessageText: String,
    context: AccountContext
) {
    let _ = (context.account.postbox.transaction { transaction -> Void in
        transaction.updateMessage(message.id, update: { currentMessage in
            var storeForwardInfo: StoreMessageForwardInfo?
            if let forwardInfo = currentMessage.forwardInfo {
                storeForwardInfo = StoreMessageForwardInfo(authorId: forwardInfo.author?.id, sourceId: forwardInfo.source?.id, sourceMessageId: forwardInfo.sourceMessageId, date: forwardInfo.date, authorSignature: forwardInfo.authorSignature, psaType: forwardInfo.psaType, flags: forwardInfo.flags)
            }

            return .update(StoreMessage(id: currentMessage.id, customStableId: nil, globallyUniqueId: currentMessage.globallyUniqueId, groupingKey: currentMessage.groupingKey, threadId:  currentMessage.threadId, timestamp: currentMessage.timestamp, flags: StoreMessageFlags(currentMessage.flags), tags: currentMessage.tags, globalTags: currentMessage.globalTags, localTags: currentMessage.localTags, forwardInfo: storeForwardInfo, authorId: currentMessage.author?.id, text: newMessageText, attributes: currentMessage.attributes, media: currentMessage.media))
        })
    }).start()
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
