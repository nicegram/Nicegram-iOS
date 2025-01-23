import FeatPremium
import FeatBilling
import Postbox
import Foundation
import NGAppCache
import FeatSpeechToText

@propertyWrapper
public struct NGStorage<T: Codable> {
    private let key: String
    private let defaultValue: T

    public init(key: String, defaultValue: T) {
        self.key = "ng:" + key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get {
            if #available(iOS 13.1, *) {
                // Read value from UserDefaults
                guard let data = UserDefaults.standard.object(forKey: key) as? Data else {
                    // Return defaultValue when no data in UserDefaults
                    return defaultValue
                }

                // Convert data to the desire data type
                let value = try? JSONDecoder().decode(T.self, from: data)
                return value ?? defaultValue
            } else {
                // Fixes for old iOS
                return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
            }
        }
        set {
            if #available(iOS 13.1, *) {
                // Convert newValue to data
                let data = try? JSONEncoder().encode(newValue)
                
                // Set value to UserDefaults
                UserDefaults.standard.set(data, forKey: key)
            } else {
                // Fixes for old iOS
                UserDefaults.standard.set(newValue, forKey: key)
            }
        }
    }
}

public struct NGSettings {
    @NGStorage(key: "oneTapTr", defaultValue: true)
    public static var oneTapTr: Bool
    
    @NGStorage(key: "useIgnoreLanguages", defaultValue: false)
    public static var useIgnoreLanguages: Bool
    
    @NGStorage(key: "ignoreTranslate", defaultValue: [])
    public static var ignoreTranslate: [String]
    
    @NGStorage(key: "rememberFolderOnExit", defaultValue: false)
    public static var rememberFolderOnExit: Bool

    @NGStorage(key: "useOpenAI", defaultValue: false)
    private static var _useOpenAI: Bool

    @available(*, deprecated, message: "Deprecation version 1.9.1(392). Use _useOpenAI instead")
    public static var useOpenAI: Bool {
        get {
            let preferredProviderTypeUseCase = SpeechToTextContainer.shared.getPreferredProviderTypeUseCase()
            let type = preferredProviderTypeUseCase()

            let getSpeech2TextSettingsUseCase = NicegramSettingsModule.shared.getSpeech2TextSettingsUseCase()
            let enableApple = getSpeech2TextSettingsUseCase()

            if enableApple {
                return type == .openAi ? true : NGSettings._useOpenAI
            } else {
                return NGSettings._useOpenAI
            }
        }
        set {
            NGSettings._useOpenAI = newValue
            let preferredProviderTypeUseCase = SpeechToTextContainer.shared.setPreferredProviderTypeUseCase()
            Task {
                await preferredProviderTypeUseCase(.google)
            }
        }
    }
    
    @NGStorage(key: "lastFolder", defaultValue: -1)
    public static var lastFolder: Int32
    
    // MARK: App Settings
    @NGStorage(key: "showContactsTab", defaultValue: true)
    public static var showContactsTab: Bool
    
    @NGStorage(key: "showNicegramButtonInChat", defaultValue: true)
    public static var showNicegramButtonInChat: Bool
    
    @NGStorage(key: "sendWithEnter", defaultValue: false)
    public static var sendWithEnter: Bool
    
    @NGStorage(key: "hidePhoneSettings", defaultValue: false)
    public static var hidePhoneSettings: Bool
    
    @NGStorage(key: "useRearCamTelescopy", defaultValue: false)
    public static var useRearCamTelescopy: Bool
    
    @NGStorage(key: "hideNotifyAccount", defaultValue: false)
    public static var hideNotifyAccount: Bool
    
    @NGStorage(key: "fixNotifications", defaultValue: false)
    public static var fixNotifications: Bool
    
    @NGStorage(key: "showTabNames", defaultValue: true)
    public static var showTabNames: Bool
    
    @NGStorage(key: "showGmodIcon", defaultValue: true)
    public static var showGmodIcon: Bool
    
    @NGStorage(key: "showProfileId", defaultValue: true)
    public static var showProfileId: Bool
    
    @NGStorage(key: "showRegDate", defaultValue: true)
    public static var showRegDate: Bool
    
    @NGStorage(key: "shouldDownloadVideo", defaultValue: false)
    public static var shouldDownloadVideo: Bool
    
    @NGStorage(key: "shareChannelsInfo", defaultValue: false)
    public static var shareChannelsInfo: Bool
    
    @NGStorage(key: "hideStories", defaultValue: false)
    public static var hideStories: Bool
    
    @NGStorage(key: "recordAllCalls", defaultValue: false)
    public static var recordAllCalls: Bool
    
    @NGStorage(key: "showFeedTab", defaultValue: false)
    public static var showFeedTab: Bool
    
    @NGStorage(key: "feedPeer", defaultValue: [:])
    public static var feedPeer: [Int64: PeerId]
    
    @NGStorage(key: "hideBadgeCounters", defaultValue: false)
    public static var hideBadgeCounters: Bool
    
    @NGStorage(key: "hideUnreadCounters", defaultValue: false)
    public static var hideUnreadCounters: Bool

    @NGStorage(key: "hideMentionNotification", defaultValue: false)
    public static var hideMentionNotification: Bool
    
    @NGStorage(key: "appleSpeechToTextLocale", defaultValue: [:])
    public static var appleSpeechToTextLocale: [Int64: Locale]
}

public struct NGWebSettings {
    // MARK: Remote Settings
    @NGStorage(key: "syncPins", defaultValue: false)
    static var syncPins: Bool
    
    @NGStorage(key: "restricted", defaultValue: [])
    static var resticted: [Int64]
    
    @NGStorage(key: "RR", defaultValue: [])
    static var RR: [String]
    
    @NGStorage(key: "allowed", defaultValue: [])
    static var allowed: [Int64]
      
}


public struct NGSharedSettings {
    let UD = UserDefaults(suiteName: "group.\(Bundle.main.bundleIdentifier!)")

    public init() {}
}

public var VarNGSharedSettings = NGSharedSettings()

public func checkPremium(completion: @escaping (Bool) -> Void) {
    Task {
        let refreshPremiumSubStatusUseCase = BillingContainer.shared.refreshPremiumSubStatusUseCase()
        await refreshPremiumSubStatusUseCase()

        await MainActor.run {
            completion(PremiumContainer.shared.getPremiumStatusUseCase().hasPremiumOnDevice())
        }
    }
}

public func isPremium() -> Bool {
    if #available(iOS 13.0, *) {
        return PremiumContainer.shared
            .getPremiumStatusUseCase()
            .hasPremiumOnDevice()
    } else {
        return false
    }
}

public func usetrButton() -> [(Bool, [String])] {
    var ignoredLangs = NGSettings.ignoreTranslate
    if !NGSettings.useIgnoreLanguages {
        ignoredLangs = []
    }
    return [(NGSettings.oneTapTr, ignoredLangs)]
}

public class SystemNGSettings {
    let UD = UserDefaults.standard
    
    public init() {}
    
    public var dbReset: Bool {
        get {
            return UD.bool(forKey: "ng_db_reset")
        }
        set {
            UD.set(newValue, forKey: "ng_db_reset")
        }
    }
    
    public var hideReactions: Bool {
        get {
            return UD.bool(forKey: "hideReactions")
        }
        set {
            UD.set(newValue, forKey: "hideReactions")
        }
    }
    
    public var isDoubleBottomOn: Bool {
        get {
            return UD.bool(forKey: "isDoubleBottomOn")
        }
        set {
            UD.set(newValue, forKey: "isDoubleBottomOn")
        }
    }
    
    public var inDoubleBottom: Bool {
        get {
            return UD.bool(forKey: "inDoubleBottom")
        }
        set {
            UD.set(newValue, forKey: "inDoubleBottom")
        }
    }
    
    public var hideReactionsToYourMessages: Bool {
        get {
            return UD.bool(forKey: "hideReactionsToYourMessages")
        }
        set {
            UD.set(newValue, forKey: "hideReactionsToYourMessages")
        }
    }
}

public var VarSystemNGSettings = SystemNGSettings()
