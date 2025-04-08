import Foundation
import NGAnalytics

public enum KeywordsAnalyticsEvent: String {
    case tooltipShow = "keywords_folder_tooltip_show"
    case folderOpen = "keywords_folder_open"
    case folderDisabled = "keywords_folder_disabled"
    case addedFromSearch = "keyword_added_from_search"
    case addedFromFolder = "keyword_added_from_folder"
    case apiPreloadedSuccess = "keyword_api_preloaded_success"
    case apiPreloadedError = "keyword_api_preloaded_error"
}

public func sendKeywordsAnalytics(with event: KeywordsAnalyticsEvent) {
    let analyticsManager = AnalyticsContainer.shared.analyticsManager()
    analyticsManager.trackEvent(
        event.rawValue,
        params: [:]
    )
}
