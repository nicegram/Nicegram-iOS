import AccountContext
import CoreAnalytics
import Postbox
import SwiftSignalKit
import TelegramCore

public func trackChatOpen(peerId: PeerId, context: AccountContext) {
    _ = (context.account.viewTracker.peerView(peerId, updateData: true)
    |> take(1))
    .start(next: { peerView in
        guard let peer = peerView.peers[peerView.peerId],
              let chat = openedChat(
                  peer: EnginePeer(peer),
                  cachedData: peerView.cachedData as? CachedChannelData
              ) else {
            return
        }

        track(chat)
    })
}

private struct OpenedChat {
    let memberCount: Int
    let restricted: Bool
    let role: Role
    let type: GroupType
    let visibility: Visibility
}

private func openedChat(
    peer: EnginePeer,
    cachedData: CachedChannelData?
) -> OpenedChat? {
    switch peer {
    case let .channel(channel):
        openedChat(
            channel: channel,
            cachedData: cachedData
        )
    case let .legacyGroup(group):
        openedChat(group: group)
    case .community, .secretChat, .user:
        nil
    }
}

private func openedChat(
    channel: TelegramChannel,
    cachedData: CachedChannelData?
) -> OpenedChat {
    let role: Role
    if channel.flags.contains(.isCreator) {
        role = .owner
    } else if let _ = channel.adminRights {
        role = .admin
    } else {
        role = .user
    }

    let type: GroupType
    switch channel.info {
    case .broadcast:
        type = .channel
    case .group:
        if channel.flags.contains(.isGigagroup) {
            type = .gigagroup
        } else {
            type = .supergroup
        }
    }

    return OpenedChat(
        memberCount: Int(cachedData?.participantsSummary.memberCount ?? 0),
        restricted: !(channel.restrictionInfo?.rules.isEmpty ?? true),
        role: role,
        type: type,
        visibility: channel.addressName != nil ? .public : .private
    )
}

private func openedChat(group: TelegramGroup) -> OpenedChat {
    let role: Role
    switch group.role {
    case .creator:
        role = .owner
    case .admin:
        role = .admin
    case .member:
        role = .user
    }

    return OpenedChat(
        memberCount: group.participantCount,
        restricted: false,
        role: role,
        type: .group,
        visibility: .private
    )
}

private func track(_ chat: OpenedChat) {
    let analyticsManager = AnalyticsContainer.shared.analyticsManager()
    analyticsManager.trackEvent(
        "group_open_by_\(chat.role.rawValue)",
        params: [
            "participants_count": roundedMemberCount(chat.memberCount),
            "restricted": chat.restricted,
            .type: chat.type.rawValue,
            "visibility": chat.visibility.rawValue
        ]
    )
}

private func roundedMemberCount(_ count: Int) -> Int {
    if count < 50 {
        50
    } else {
        ((count / 1000) + 1) * 1000
    }
}

private enum Role: String {
    case user
    case admin
    case owner
}

private enum GroupType: String {
    case channel
    case gigagroup
    case group
    case supergroup
}

private enum Visibility: String {
    case `public`
    case `private`
}
