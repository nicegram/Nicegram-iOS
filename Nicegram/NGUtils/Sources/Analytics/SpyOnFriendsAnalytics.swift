import Foundation
import NGAnalytics

public enum SpyOnFriendsAnalyticsEvent: String {
    case show = "spy_friends_show"
    case usage = "spy_friends_usage"
}

public func sendSpyOnFriendsAnalytics(with event: SpyOnFriendsAnalyticsEvent) {
    let analyticsManager = AnalyticsContainer.shared.analyticsManager()
    analyticsManager.trackEvent(
        event.rawValue,
        params: [:]
    )
}
