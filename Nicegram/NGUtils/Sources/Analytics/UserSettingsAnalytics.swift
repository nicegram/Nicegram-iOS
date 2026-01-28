import Foundation
import NGAnalytics

public enum UserSettingsAnalyticsEvent: String {
    case recordAllCallsOn = "user_settings_record_all_calls_on"
//    case openSameFolderAfterExitOn = "user_settings_open_same_folder_after_exit_on"
//    case hideMessagesPreviewInFoldersOn = "user_settings_hide_messages_preview_in_folders_on"
}

public func sendUserSettingsAnalytics(with event: UserSettingsAnalyticsEvent) {
    let analyticsManager = AnalyticsContainer.shared.analyticsManager()
    analyticsManager.trackEvent(
        event.rawValue,
        params: [:]
    )
}
