import AccountContext
import FeatPremium
import NGCore
import NGStrings
import TelegramUIPreferences

public struct NGStealthMode {
    private static var stealthModeSubscription: Any?
}

public extension NGStealthMode {
    static func initialize(
        sharedContext: SharedAccountContext
    ) {
        guard #available(iOS 13.0, *) else {
            return
        }
        
        let getPremiumStatusUseCase = PremiumContainer.shared.getPremiumStatusUseCase()
        
        stealthModeSubscription = $stealthModeEnabled
            .combineLatest(getPremiumStatusUseCase.hasPremiumOnDevicePublisher())
            .map { stealthModeEnabled, hasPremium in
                stealthModeEnabled && hasPremium
            }
            .sink { [weak sharedContext] useStealthMode in
                guard let sharedContext else {
                    return
                }
                
                let _ = updateExperimentalUISettingsInteractively(accountManager: sharedContext.accountManager, { settings in
                    var settings = settings
                    settings.skipReadHistory = useStealthMode
                    return settings
                }).start()
            }
    }
    
    static func isStealthModeEnabled() -> Bool {
        if #available(iOS 13.0, *) {
            stealthModeEnabled
        } else {
            false
        }
    }
    
    static func setStealthModeEnabled(_ enabled: Bool) {
        if #available(iOS 13.0, *) {
            stealthModeEnabled = enabled
        }
    }
}

public extension NGStealthMode {
    struct Resources {}
}
public extension NGStealthMode.Resources {
    static func toggleTitle() -> String {
        l("StealthMode.Toggle")
    }
}

@available(iOS 13.0, *)
private extension NGStealthMode {
    @UserDefaultsValue(
        key: "stealthModeEnabled",
        defaultValue: false
    )
    static var stealthModeEnabled: Bool
}
