import Foundation
import NGData
import NGPremiumUI
import NGRemoteConfig
import Postbox
import UIKit

//  MARK: - Logic

public func shouldShowInterfaceForCopyContent(message: Message) -> Bool {
    let isCopyProtectionEnabled = message.isCopyProtected()
    return !isCopyProtectionEnabled || allowCopyProtectedContent
}

public func shouldShowInterfaceForForwardAsCopy(message: Message) -> Bool {
    let isCopyProtectionEnabled = message.isCopyProtected()
    
    if isCopyProtectionEnabled {
        let hasMedia = !message.media.isEmpty
        return !hasMedia && shouldShowInterfaceForCopyContent(message: message)
    } else {
        return true
    }
}

public func shouldSubscribeToCopyContent(message: Message) -> Bool {
    let isCopyProtectionEnabled = message.isCopyProtected()
    
    if isCopyProtectionEnabled {
        return !isPremium() && !getBypassCopyProtection()
    } else {
        return false
    }
}

public func routeToNicegramPremiumForCopyContent() {
    PremiumUITgHelper.routeToPremium()
}

//  MARK: - Bypass setting (Secret Menu)

private let bypassCopyProtectionKey = "ng:bypassCopyProtection"

public func getBypassCopyProtection() -> Bool {
    return UserDefaults.standard.bool(forKey: bypassCopyProtectionKey)
}

public func setBypassCopyProtection(_ value: Bool) {
    UserDefaults.standard.set(value, forKey: bypassCopyProtectionKey)
}
