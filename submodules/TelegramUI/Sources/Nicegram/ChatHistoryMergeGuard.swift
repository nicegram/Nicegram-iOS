import ChatHistoryEntry

typealias ChatHistoryMergeResult = (
    deleteIndices: [Int],
    indicesAndItems: [(Int, ChatHistoryEntry, Int?)],
    updateIndices: [(Int, ChatHistoryEntry, Int)]
)

// The merge rebuilds the right list only when both lists are sorted by `<` and every entry is `==`
// to itself, and release builds strip its own check. Otherwise a survivor is skipped and inserted
// again, the result outgrows the right list, and ListView traps on a negative index (crash
// 25264d71). The length below differs from the right list's exactly when that happened. In
// production the unsorted entry is an album: a MessageGroupEntry sits where its first message is
// but sorts by its last.
func guardedChatHistoryMergeResult(
    _ result: ChatHistoryMergeResult,
    leftList: [ChatHistoryEntry],
    rightList: [ChatHistoryEntry]
) -> ChatHistoryMergeResult {
    let resultCount = leftList.count - result.deleteIndices.count + result.indicesAndItems.count
    if resultCount == rightList.count {
        return result
    }

    return chatHistoryMergeFullReplacement(
        leftList: leftList,
        rightList: rightList
    )
}

private func chatHistoryMergeFullReplacement(
    leftList: [ChatHistoryEntry],
    rightList: [ChatHistoryEntry]
) -> ChatHistoryMergeResult {
    var previousIndices: [UInt64: Int] = [:]
    for (index, entry) in leftList.enumerated() {
        previousIndices[entry.stableId] = index
    }
    return (
        deleteIndices: Array(0 ..< leftList.count),
        indicesAndItems: rightList.enumerated().map { ($0.offset, $0.element, previousIndices[$0.element.stableId]) },
        updateIndices: []
    )
}
