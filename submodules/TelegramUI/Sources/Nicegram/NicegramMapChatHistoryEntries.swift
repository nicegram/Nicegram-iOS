import FeatAttentionEconomy
import Foundation
import NGUtils
import NicegramWallet

import ChatHistoryEntry
import Display
import Postbox
import TelegramPresentationData

private let THRESHOLD_MEMBERS = 1000

struct NicegramAdInChat {
    let ad: AttAd?
    let forceRemove: Bool
}

func nicegramMapChatHistoryEntries(
    oldEntries: [ChatHistoryEntry],
    newEntries: [ChatHistoryEntry],
    nicegramAd: NicegramAdInChat,
    visibleItemRange: ListViewVisibleItemRange?,
    chatPresentationData: ChatPresentationData,
    cachedPeerData: CachedPeerData?,
    attConfig: AttConfig
) -> [ChatHistoryEntry] {
    var result = newEntries
    
    result = parseWalletTransactions(result)
    
    guard !nicegramAd.forceRemove else {
        return result
    }
    let nicegramAd = nicegramAd.ad
    
    guard areAdsAllowed(
        cachedPeerData: cachedPeerData
    ) else {
        return result
    }
    
    guard let visibleRange = parseVisibleRange(
        oldEntries: oldEntries,
        visibleItemRange: visibleItemRange
    ) else {
        return result
    }
    
    result = insertOldAdEntries(
        oldEntries: oldEntries,
        result: result,
        nicegramAd: nicegramAd,
        visibleRange: visibleRange,
        attConfig: attConfig
    )
    result = updateOldAdEntries(
        result: result,
        nicegramAd: nicegramAd
    )
    result = insertNewAdEntries(
        result: result,
        nicegramAd: nicegramAd,
        visibleRange: visibleRange,
        chatPresentationData: chatPresentationData,
        attConfig: attConfig
    )
    result = removeNeighboringAds(
        result: result
    )
    
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

private func areAdsAllowed(
    cachedPeerData: CachedPeerData?
) -> Bool {
    guard #available(iOS 15.0, *) else {
        return false
    }
    
    let membersCount = getMembersCount(cachedPeerData: cachedPeerData)
    if let membersCount, membersCount > THRESHOLD_MEMBERS {
        return true
    } else {
        return false
    }
}

private func parseVisibleRange(
    oldEntries: [ChatHistoryEntry],
    visibleItemRange: ListViewVisibleItemRange?
) -> Range<Int>? {
    guard let visibleItemRange else {
        return nil
    }
    let leftIndex = oldEntries.count - 1 - visibleItemRange.lastIndex
    let rightIndex = oldEntries.count - 1 - visibleItemRange.firstIndex
    guard leftIndex <= rightIndex else {
        return nil
    }
    return leftIndex..<rightIndex + 1
}

private func insertOldAdEntries(
    oldEntries: [ChatHistoryEntry],
    result: [ChatHistoryEntry],
    nicegramAd: AttAd?,
    visibleRange: Range<Int>,
    attConfig: AttConfig
) -> [ChatHistoryEntry] {
    struct OldEntry {
        let entry: ChatHistoryEntry
        let index: Int
    }
    
    var result = result
    
    let filteredOldEntries = oldEntries.enumerated()
        .filter { _, entry in
            if case .NicegramAdEntry = entry {
                true
            } else {
                result.contains { entry.stableId == $0.stableId }
            }
        }
        .map { OldEntry(entry: $1, index: $0) }
    
    filteredOldEntries.forEachWithNeighbors { left, mid, right in
        let entry = mid.entry
        let index = mid.index
        
        guard case let .NicegramAdEntry(_, ad, _) = entry else {
            return
        }
        
        let expandedOffset = attConfig.CHAT_AD_OFFSET + 5
        let expandedVisibleRange = visibleRange.expanded(
            leftOffset: expandedOffset,
            rightOffset: expandedOffset
        )
        
        if expandedVisibleRange.contains(index) {
            let targetIndex: Int
            if let left, let index = result.firstIndex(where: { $0.stableId == left.entry.stableId }) {
                targetIndex = index + 1
            } else if let right, let index = result.firstIndex(where: { $0.stableId == right.entry.stableId }) {
                targetIndex = index
            } else {
                targetIndex = 0
            }
             
            result.insert(entry, at: targetIndex)
        }
    }
    
    return result
}

private func updateOldAdEntries(
    result: [ChatHistoryEntry],
    nicegramAd: AttAd?
) -> [ChatHistoryEntry] {
    guard let nicegramAd else {
        return result
    }
    
    return result.map { entry in
        if case let .NicegramAdEntry(id, ad, presentationData) = entry,
           ad.adId == nicegramAd.adId {
            .NicegramAdEntry(id, nicegramAd, presentationData)
        } else {
            entry
        }
    }
}

private func insertNewAdEntries(
    result: [ChatHistoryEntry],
    nicegramAd: AttAd?,
    visibleRange: Range<Int>,
    chatPresentationData: ChatPresentationData,
    attConfig: AttConfig
) -> [ChatHistoryEntry] {
    var result = result
    
    guard let nicegramAd else {
        return result
    }
    
    let alreadyContainsAd = result.contains {
        if case let .NicegramAdEntry(_, ad, _) = $0,
           ad.adId == nicegramAd.adId {
            true
        } else {
            false
        }
    }
    if !alreadyContainsAd {
        let indicesToInsert = [
            visibleRange.lowerBound - attConfig.CHAT_AD_OFFSET,
            visibleRange.upperBound + attConfig.CHAT_AD_OFFSET
        ]
        indicesToInsert.forEach { index in
            let index = index.clamped(to: result.startIndex...result.endIndex)
            
            if index != result.startIndex,
               index != result.endIndex {
                result.insert(
                    .NicegramAdEntry(
                        UUID().uuidString,
                        nicegramAd,
                        chatPresentationData
                    ),
                    at: index
                )
            }
        }
    }
    
    return result
}

private func removeNeighboringAds(
    result: [ChatHistoryEntry]
) -> [ChatHistoryEntry] {
    var filteredResult: [ChatHistoryEntry] = []
    
    var lastAdIndex = -100
    for entry in result {
        if case .NicegramAdEntry = entry {
            let currentIndex = filteredResult.count
            if currentIndex - lastAdIndex > 5 {
                filteredResult.append(entry)
                lastAdIndex = currentIndex
            }
        } else {
            filteredResult.append(entry)
        }
    }
    
    return filteredResult
}

private extension Array {
    func forEachWithNeighbors(_ body: (Element?, Element, Element?) -> Void) {
        for i in 0..<self.count {
            let left = i > 0 ? self[i - 1] : nil
            let right = i < self.count - 1 ? self[i + 1] : nil
            body(left, self[i], right)
        }
    }
}

private extension Range<Int> {
    func expanded(
        leftOffset: Int,
        rightOffset: Int
    ) -> Range<Int> {
        let leftIndex = self.lowerBound - leftOffset
        let rightIndex = self.upperBound + rightOffset
        return leftIndex..<rightIndex
    }
}
