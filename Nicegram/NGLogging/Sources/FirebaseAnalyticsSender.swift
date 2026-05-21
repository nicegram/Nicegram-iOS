import FirebaseAnalytics
import NGAnalytics

public class FirebaseAnalyticsSender {
    
    //  MARK: - Lifecycle
    
    public init() {}
}

extension FirebaseAnalyticsSender: AnalyticsSender {
    public func trackEvent(_ name: String, params: [String: Any]) {
        Analytics.logEvent(
            // Event names can be up to 40 characters long
            // https://firebase.google.com/docs/reference/swift/firebaseanalytics/api/reference/Classes/Analytics#logevent_:parameters:
            String(name.prefix(40)),
            parameters: params
        )
    }
}
