import CoreAnalytics
import FeatWhitebridge
import Foundation

public enum WhitebridgeAnalyticsEvent {
    case show(source: WhitebridgeSource)
}

public func sendWhitebridgeAnalytics(with event: WhitebridgeAnalyticsEvent) {
    let analyticsManager = AnalyticsContainer.shared.analyticsManager()
    let eventName: String = {
        switch event {
        case let .show(source):
            return "whitebridge_show_\(source.rawValue)"
        }
    }()
    
    analyticsManager.trackEvent(
        eventName,
        params: [:]
    )
}

