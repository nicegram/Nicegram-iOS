import Foundation

public final class AppCache {
    // Old key 'appLaunchCount'
    @UserDefaultsBacked(key: "appLaunchCount_v2", storage: .standard, defaultValue: 0)
    public static var appLaunchCount: Int

    @UserDefaultsBacked(key: "firstAppLaunchDate", storage: .standard, defaultValue: nil)
    public static var firstAppLaunchDate: Date?

    @UserDefaultsBacked(key: "currentUserID", storage: .standard, defaultValue: nil)
    public  static var currentUserID: String?

    @UserDefaultsBacked(key: "isShownIDFA", storage: .standard, defaultValue: false)
    public static var isShownIDFA: Bool

    @UserDefaultsBacked(key: "wasLauchedBefore", storage: .standard, defaultValue: false)
    private static var _wasLauchedBefore: Bool
    
    @UserDefaultsBacked(key: "wasOnboardingShown", storage: .standard, defaultValue: false)
    public static var wasOnboardingShown: Bool
    
    @UserDefaultsBacked(key: "lastSeenBlockedChatId", storage: .standard, defaultValue: nil)
    public static var lastSeenBlockedChatId: Int64?

    public static var wasLauchedBefore: Bool {
        get {
            return _wasLauchedBefore
        }
        set {
            _wasLauchedBefore = newValue
        }
    }

    private init() {}
}


@propertyWrapper
public struct UserDefaultsBacked<Value> {
    let key: String
    let storage: UserDefaults
    let defaultValue: Value

    public init(key: String, storage: UserDefaults = .standard, defaultValue: Value) {
        self.key = key
        self.storage = storage
        self.defaultValue = defaultValue
    }

    public var wrappedValue: Value {
        get { return storage.value(forKey: key) as? Value ?? defaultValue }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                storage.removeObject(forKey: key)
            } else {
                storage.setValue(newValue, forKey: key)
            }
        }
    }
}

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}
