import ChatHistoryEntry
import FeatAdsgram
import NicegramWallet

func nicegramMapChatHistoryEntries(
    entries: [ChatHistoryEntry],
    ngMessageAd: ChatHistoryEntry.NicegramAd?
) -> [ChatHistoryEntry] {
    var result = entries
    
    result = parseWalletTransactions(result)

    if #available(iOS 16.0, *), let ngMessageAd {
        result.append(.nicegramAd(ngMessageAd))
    }
    
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
