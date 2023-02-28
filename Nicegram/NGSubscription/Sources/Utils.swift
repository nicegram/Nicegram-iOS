import NGCore
import TelegramPresentationData
import UIKit

public func routeToNicegramPremium(presentationData: PresentationData) {
    let c = SubscriptionBuilderImpl(presentationData: presentationData).build()
    c.modalPresentationStyle = .fullScreen
    if let topViewController = UIApplication.topViewController {
        topViewController.present(c, animated: true)
    }
}
