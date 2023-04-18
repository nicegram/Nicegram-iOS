import FirebaseAnalytics
import NGAnalytics

public class FirebaseLogger {
    
    //  MARK: - Lifecycle
    
    public init() {}
}

extension FirebaseLogger: EventsLogger {
    public func logEvent(name: String, params: [String : Encodable]) {
        Analytics.logEvent(name, parameters: params)
    }
}

extension FirebaseLogger: AnalyticsSender {
    public func trackEvent(_ name: String, params: [String: Any]) {
        Analytics.logEvent(name, parameters: params)
    }
}
