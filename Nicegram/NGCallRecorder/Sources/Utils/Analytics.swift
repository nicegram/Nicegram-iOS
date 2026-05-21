import NGAnalytics

enum CallRecorderAnalyticsEvent: String {
    case startAuto = "call_recorder_start_auto"
    case start = "call_recorder_start"
    case end = "call_recorder_end"
    case error = "call_recorder_error"
}

func trackCallRecorderEvent(_ event: CallRecorderAnalyticsEvent) {
    let analyticsManager = AnalyticsContainer.shared.analyticsManager()
    analyticsManager.trackEvent(
        event.rawValue,
        params: [:]
    )
}
