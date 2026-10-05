import CoreAnalytics
import FirebaseCrashlytics
import Foundation

private let postboxFailureEventName = "nicegram_postbox_write_failed"

public func sendPostboxFailureAnalytics(_ params: [String: String]) {
    // The trap follows within microseconds on this same thread, so the
    // analytics event will usually not survive to be uploaded. Crashlytics
    // custom keys ride the crash report itself, which is the one channel these
    // devices demonstrably complete. The event still covers the case where a
    // table creation fails but nothing writes to that table, so no crash
    // follows and there is no report to attach keys to.
    let crashlytics = Crashlytics.crashlytics()
    for (key, value) in params {
        crashlytics.setCustomValue(
            value,
            forKey: "postbox_write_failed_\(key)"
        )
    }

    AnalyticsContainer.shared.analyticsManager().trackEvent(
        postboxFailureEventName,
        params: params.mapValues { $0 as AnalyticsEvent.ParameterValue }
    )
}
