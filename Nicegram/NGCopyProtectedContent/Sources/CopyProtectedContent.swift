import Foundation
import NGCore
import NGData
import NGRemoteConfig
import NGSubscription
import Postbox
import TelegramPresentationData
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

public func routeToNicegramPremiumForCopyContent(presentationData: PresentationData) {
    let c = SubscriptionBuilderImpl(presentationData: presentationData).build()
    c.modalPresentationStyle = .fullScreen
    if let topViewController = UIApplication.topViewController {
        topViewController.present(c, animated: true)
    }
}

//  MARK: - Bypass setting (Secret Menu)

private let bypassCopyProtectionKey = "ng:bypassCopyProtection"

public func getBypassCopyProtection() -> Bool {
    return UserDefaults.standard.bool(forKey: bypassCopyProtectionKey)
}

public func setBypassCopyProtection(_ value: Bool) {
    UserDefaults.standard.set(value, forKey: bypassCopyProtectionKey)
}
