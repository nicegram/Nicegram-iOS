import AccountContext
import ChatHistoryEntry
import CoreAnalytics
import FirebaseCrashlytics
import Foundation
import TelegramCore

private let chatHistoryMergeFailureEventName = "nicegram_chat_history_merge_failed"

typealias ChatHistoryMergeResult = (
    deleteIndices: [Int],
    indicesAndItems: [(Int, ChatHistoryEntry, Int?)],
    updateIndices: [(Int, ChatHistoryEntry, Int)]
)

// The merge rebuilds the right list only when both lists are sorted by `<` and every entry is `==`
// to itself, and release builds strip its own check. Otherwise a survivor is skipped and inserted
// again, the result outgrows the right list, and ListView traps on a negative index (crash
// 25264d71). The length below differs from the right list's exactly when that happened.
//
// The report is temporary instrumentation for that crash: delete it, and its sending, once the
// malformed input is repaired in chatHistoryEntriesForView. Whether the fallback stays is decided
// then.
func guardedChatHistoryMergeResult(
    _ result: ChatHistoryMergeResult,
    chatLocation: ChatLocation,
    leftList: [ChatHistoryEntry],
    reason: ChatHistoryViewTransitionReason,
    rightList: [ChatHistoryEntry]
) -> ChatHistoryMergeResult {
    let resultCount = leftList.count - result.deleteIndices.count + result.indicesAndItems.count
    if resultCount == rightList.count {
        return result
    }

    sendChatHistoryMergeFailureAnalytics(
        chatHistoryMergeFailureReport(
            chatLocation: chatLocation,
            leftList: leftList,
            reason: reason,
            resultCount: resultCount,
            rightList: rightList
        )
    )

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

private func chatHistoryMergeFailureReport(
    chatLocation: ChatLocation,
    leftList: [ChatHistoryEntry],
    reason: ChatHistoryViewTransitionReason,
    resultCount: Int,
    rightList: [ChatHistoryEntry]
) -> [String: String] {
    let restricted = restrictedFlag(
        entries: rightList + leftList,
        peerId: chatLocation.peerId
    )
    var report: [String: String] = [
        "chat_location": chatLocationKind(chatLocation),
        "left_count": "\(leftList.count)",
        "peer_namespace": peerNamespaceName(chatLocation.peerId),
        "reason": reasonName(reason),
        "restricted": restricted,
        "result_count": "\(resultCount)",
        "right_count": "\(rightList.count)",
    ]
    for (prefix, list) in [("left", leftList), ("right", rightList)] {
        for (key, value) in listDefects(list) {
            report["\(prefix)_\(key)"] = value
        }
    }
    return report
}

private func sendChatHistoryMergeFailureAnalytics(_ params: [String: String]) {
    // Unlike sendPostboxFailureAnalytics, no crash follows, so the report rides this one non-fatal's
    // user info. Custom keys would persist for the rest of the session and tag every later report.
    // Not UnexpectedError: Crashlytics groups by domain and code, so this would merge with its non-fatals.
    Crashlytics.crashlytics().record(
        error: NSError(
            domain: "ChatHistoryMergeFailure",
            code: 1,
            userInfo: params
        )
    )

    AnalyticsContainer.shared.analyticsManager().trackEvent(
        chatHistoryMergeFailureEventName,
        params: params.mapValues { $0 as AnalyticsEvent.ParameterValue }
    )
}

private func listDefects(_ list: [ChatHistoryEntry]) -> [String: String] {
    let unsortedAt = list.indices.dropFirst().first { list[$0] < list[$0 - 1] }
    let irreflexive = list.filter { !($0 == $0) }
    let duplicateIds = list.count - Set(list.map(\.stableId)).count
    return [
        "duplicate_ids": "\(duplicateIds)",
        "irreflexive_count": "\(irreflexive.count)",
        "irreflexive_kind": irreflexive.first.map(entryKind) ?? "none",
        "unsorted_at": unsortedAt.map { "\($0)" } ?? "none",
        "unsorted_pair": unsortedAt.map { "\(entryKind(list[$0 - 1])) > \(entryKind(list[$0]))" } ?? "none",
    ]
}

private func entryKind(_ entry: ChatHistoryEntry) -> String {
    switch entry {
    case let .MessageEntry(message, _, _, _, _, _):
        return messageKind(message)
    case .MessageGroupEntry:
        return "group"
    case .UnreadEntry:
        return "unread"
    case .ReplyCountEntry:
        return "reply_count"
    case .ChatInfoEntry:
        return "chat_info"
    }
}

private func messageKind(_ message: EngineRawMessage) -> String {
    var kind = "message:\(message.id.namespace)"
    if message.adAttribute != nil {
        kind += ":ad"
    }
    if let action = message.media.first(where: { $0 is TelegramMediaAction }) as? TelegramMediaAction, case .joinedChannel = action.action {
        kind += ":join"
    }
    if message.groupingKey != nil {
        kind += ":grouped"
    }
    return kind
}

private func chatLocationKind(_ chatLocation: ChatLocation) -> String {
    switch chatLocation {
    case .peer:
        return "peer"
    case .replyThread:
        return "reply_thread"
    case .customChatContents:
        return "custom"
    }
}

private func peerNamespaceName(_ peerId: EnginePeer.Id?) -> String {
    guard let peerId else {
        return "none"
    }
    switch peerId.namespace {
    case Namespaces.Peer.CloudUser:
        return "user"
    case Namespaces.Peer.CloudGroup:
        return "group"
    case Namespaces.Peer.CloudChannel:
        return "channel"
    case Namespaces.Peer.SecretChat:
        return "secret_chat"
    default:
        return "other"
    }
}

private func reasonName(_ reason: ChatHistoryViewTransitionReason) -> String {
    switch reason {
    case .Initial:
        return "initial"
    case .InteractiveChanges:
        return "interactive_changes"
    case .Reload:
        return "reload"
    case .HoleReload:
        return "hole_reload"
    }
}

private func restrictedFlag(
    entries: [ChatHistoryEntry],
    peerId: EnginePeer.Id?
) -> String {
    guard let peerId else {
        return "unknown"
    }
    for case let .MessageEntry(message, _, _, _, _, _) in entries {
        if let peer = message.peers[peerId] {
            guard let channel = peer as? TelegramChannel else {
                return "0"
            }
            let isRestricted = !(channel.restrictionInfo?.rules.isEmpty ?? true)
            return isRestricted ? "1" : "0"
        }
    }
    return "unknown"
}
