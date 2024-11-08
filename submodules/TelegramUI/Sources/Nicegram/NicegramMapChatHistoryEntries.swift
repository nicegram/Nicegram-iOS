import FeatAttentionEconomy
import Foundation
import NGUtils

import ChatHistoryEntry
import Display
import Postbox
import TelegramPresentationData

private let TOP_OFFSET_FROM_VISIBLE_RANGE = 10
private let BOTTOM_OFFSET_FROM_VISIBLE_RANGE = 10
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
    cachedPeerData: CachedPeerData?
) -> [ChatHistoryEntry] {
    var result = newEntries
    
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
        visibleRange: visibleRange
    )
    result = updateOldAdEntries(
        result: result,
        nicegramAd: nicegramAd
    )
    result = insertNewAdEntries(
        result: result,
        nicegramAd: nicegramAd,
        visibleRange: visibleRange,
        chatPresentationData: chatPresentationData
    )
    
    return result
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
    visibleRange: Range<Int>
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
        
        let isCurrentAd = (nicegramAd?.adId == ad.adId)
        let isVisible = visibleRange.contains(index)
        
        if isCurrentAd || isVisible {
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
    chatPresentationData: ChatPresentationData
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
            visibleRange.lowerBound - TOP_OFFSET_FROM_VISIBLE_RANGE,
            visibleRange.upperBound + BOTTOM_OFFSET_FROM_VISIBLE_RANGE
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

private extension Array {
    func forEachWithNeighbors(_ body: (Element?, Element, Element?) -> Void) {
        for i in 0..<self.count {
            let left = i > 0 ? self[i - 1] : nil
            let right = i < self.count - 1 ? self[i + 1] : nil
            body(left, self[i], right)
        }
    }
}
