import AccountContext
import FirebaseAnalytics
import NGAnalytics
import Postbox
import SwiftSignalKit
import TelegramCore

public func trackChatOpen(peerId: PeerId, context: AccountContext) {
    _ = (context.account.viewTracker.peerView(peerId, updateData: true)
    |> take(1))
    .start(next: { peerView in
        guard let peer = peerView.peers[peerView.peerId],
              let channel = peer as? TelegramChannel else {
            return
        }
        
        trackChatOpen(
            channel: channel,
            cachedData: peerView.cachedData as? CachedChannelData
        )
    })
}

private func trackChatOpen(
    channel: TelegramChannel,
    cachedData: CachedChannelData?
) {
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
    
    let memberCount = cachedData?.participantsSummary.memberCount ?? 0
    let roundedMemberCount: Int32
    if memberCount < 50 {
        roundedMemberCount = 50
    } else {
        roundedMemberCount = ((memberCount / 1000) + 1) * 1000
    }
    
    let hasRestrictions = !(channel.restrictionInfo?.rules.isEmpty ?? true)
    
    let isPublic = (channel.addressName != nil)
    let visibility = isPublic ? Visibility.public : .private
    
    let eventName = "group_open_by_\(role.rawValue)"
    let params: [String: Any] = [
        "type": type.rawValue,
        "participantsCount": roundedMemberCount,
        "hasRestrictions": hasRestrictions,
        "visibility": visibility.rawValue,
        AnalyticsParameterValue: memberCount
    ]
    
    let analyticsManager = AnalyticsContainer.shared.analyticsManager()
    analyticsManager.trackEvent(
        eventName,
        params: params
    )
}

private enum Role: String {
    case user
    case admin
    case owner
}

private enum GroupType: String {
    case channel
    case supergroup
    case gigagroup
}

private enum Visibility: String {
    case `public`
    case `private`
}
