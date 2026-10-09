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
    //
    // Crashlytics persists each call in its own asynchronous block and the trap
    // can land between two of them, so one call writes all of a report's keys.
    // A per-field key this report omits keeps an earlier report's value, which
    // is why `postbox_write_failed` also carries the report whole.
    var keysAndValues: [String: Any] = [:]
    for (key, value) in params {
        keysAndValues["postbox_write_failed_\(key)"] = value
    }
    keysAndValues["postbox_write_failed"] = params
        .sorted { $0.key < $1.key }
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: ";")
    Crashlytics.crashlytics().setCustomKeysAndValues(keysAndValues)

    AnalyticsContainer.shared.analyticsManager().trackEvent(
        postboxFailureEventName,
        params: params.mapValues { $0 as AnalyticsEvent.ParameterValue }
    )
}
