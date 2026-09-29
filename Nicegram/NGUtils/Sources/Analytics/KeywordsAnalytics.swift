import CoreAnalytics
import Foundation

public enum KeywordsAnalyticsEvent: String {
    case added = "keyword_added"
    case addedFromFolder = "keyword_added_from_folder"
    case addedFromSearch = "keyword_added_from_search"
    case folderDisabled = "keywords_folder_disabled"
    case folderOpen = "keywords_folder_open"
    case tooltipShow = "keywords_folder_tooltip_show"
}

public func sendKeywordsAnalytics(with event: KeywordsAnalyticsEvent) {
    let analyticsManager = AnalyticsContainer.shared.analyticsManager()
    analyticsManager.trackEvent(
        event.rawValue,
        params: [:]
    )
}
