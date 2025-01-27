import AccountContext
import Display
import Foundation
import MemberwiseInit
import NGCore
import NGUtils
import UIKit

@MemberwiseInit
class UrlOpenerImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension UrlOpenerImpl: UrlOpener {
    func open(_ url: URL, options: Options) {
        let url = prepare(url: url)
        
        guard let accountContext = contextProvider.context() else {
            UIApplication.shared.open(url)
            return
        }
        
        let sharedContext = accountContext.sharedContext
        let navigationController = sharedContext.mainWindow?.viewController as? NavigationController
        let presentationData = sharedContext.currentPresentationData.with { $0 }
        
        let telegramHosts = ["t.me", "telegram.me"]
        let isTelegramHost = telegramHosts.contains(url._wrapperHost() ?? "")
        let isExternalLink = !isTelegramHost
        
        let forceExternal: Bool
        if isExternalLink, options.externalLinkBehavior == .openExternally {
            forceExternal = true
        } else {
            forceExternal = false
        }
        
        sharedContext.openExternalUrl(
            context: accountContext,
            urlContext: .generic,
            url: url.absoluteString,
            forceExternal: forceExternal,
            presentationData: presentationData,
            navigationController: navigationController,
            dismissInput: {}
        )
    }
}

private extension UrlOpenerImpl {
    func prepare(url: URL) -> URL {
        var result = url.absoluteString
        
        let isSchemeEmpty = url.scheme?.isEmpty ?? true
        if isSchemeEmpty {
            result = "https://\(result)"
        }
        
        return URL(string: result) ?? url
    }
}
