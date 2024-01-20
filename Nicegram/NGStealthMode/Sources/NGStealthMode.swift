import AccountContext
import NGCore
import TelegramUIPreferences

public struct NGStealthMode {}

public extension NGStealthMode {
    static func initialize(
        sharedContext: SharedAccountContext
    ) {
        if #available(iOS 13.0, *) {
            maybeDisableStealthMode(
                sharedContext: sharedContext
            )
        }
    }
}

@available(iOS 13.0, *)
private extension NGStealthMode {
    @UserDefaultsValue(
        key: "ngStealthModeWasDisabled",
        defaultValue: false
    )
    static var stealthModeWasDisabled
    
    static func maybeDisableStealthMode(
        sharedContext: SharedAccountContext
    ) {
        guard !stealthModeWasDisabled else {
            return
        }
        
        let _ = updateExperimentalUISettingsInteractively(accountManager: sharedContext.accountManager, { settings in
            var settings = settings
            settings.skipReadHistory = false
            return settings
        }).start()
        
        stealthModeWasDisabled = true
    }
}
