import FirebaseAnalytics
import NGAnalytics

public class FirebaseAnalyticsSender {
    
    //  MARK: - Lifecycle
    
    public init() {}
}

extension FirebaseAnalyticsSender: AnalyticsSender {
    public func trackEvent(_ name: String, params: [String: Any]) {
        Analytics.logEvent(name, parameters: params)
    }
}
