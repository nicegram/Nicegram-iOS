import ChatHistoryEntry
import NicegramWallet

func nicegramMapChatHistoryEntries(_ entries: [ChatHistoryEntry]) -> [ChatHistoryEntry] {
    var result = entries
    
    result = parseWalletTransactions(result)
    
    return result
}

private func parseWalletTransactions(_ entries: [ChatHistoryEntry]) -> [ChatHistoryEntry] {
    guard #available(iOS 16.0, *) else {
        return entries
    }
    
    return entries.map { entry in
        if case let .MessageEntry(message, presentationData, isRead, location, selection, attributes) = entry {
            var attributes = attributes
            attributes.walletTx = try? ChatMessageTx(messageText: message.text)
            return .MessageEntry(message, presentationData, isRead, location, selection, attributes)
        } else {
            return entry
        }
    }
}
