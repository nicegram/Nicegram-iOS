import Foundation
import AccountContext
import Display
import FeatAvatarGeneratorUI
import FeatImagesHubUI
import FeatOnboarding
import FeatPremiumUI
import FeatRewardsUI
import FeatTasks
import NGAiChatUI
import NGAnalytics
import NGAssistantUI
import FeatAuth
import NGCore
import class NGCoreUI.SharedLoadingView
import NGModels
import NGRemoteConfig
import NGSpecialOffer
import NGUI
import TelegramPresentationData
import UIKit

class NGDeeplinkHandler {
    
    //  MARK: - Dependencies
    
    private let tgAccountContext: AccountContext
    private let navigationController: NavigationController?
    
    //  MARK: - Lifecycle
    
    init(tgAccountContext: AccountContext, navigationController: NavigationController?) {
        self.tgAccountContext = tgAccountContext
        self.navigationController = navigationController
    }
    
    //  MARK: - Public Functions
    
    func handle(url: String) -> Bool {
        guard let url = URL(string: url) else { return false }
        return handle(url: url)
    }
    
    //  MARK: - Private Functions

    private func handle(url: URL) -> Bool {
        return handleDeeplink(url)
    }
    
    private func handleDeeplink(_ url: URL) -> Bool {
        guard url.scheme == "ncg" else { return false }
        
        switch url.host {
        case "aiAuth":
            return handleAiAuth(url: url)
        case "aiLily":
            return handleAi(url: url)
        case "assistant":
            return handleAssistant(url: url)
        case "assistant-auth":
            return handleLoginToAssistant(url: url)
        case "avatarGenerator":
            if #available(iOS 15.0, *) {
                Task { @MainActor in
                    guard let topController = UIApplication.topViewController else {
                        return
                    }
                    AvatarGeneratorUIHelper().navigateToGenerationFlow(
                        from: topController
                    )
                }
            }
            return true
        case "avatarMyGenerations":
            if #available(iOS 15.0, *) {
                Task { @MainActor in
                    AvatarGeneratorUIHelper().navigateToGenerator()
                }
            }
            return true    
        case "generateImage":
            return handleGenerateImage(url: url)
        case "nicegramPremium":
            return handleNicegramPremium(url: url)
        case "onboarding":
            return handleOnboarding(url: url)
        case "profit":
            if #available(iOS 15.0, *) {
                Task { @MainActor in
                    RewardsUITgHelper.showRewards()
                }   
            }
            return true
        case "specialOffer":
            if #available(iOS 13.0, *) {
                return handleSpecialOffer(url: url)
            } else {
                return false
            }
        case "refferaldraw":
            if #available(iOS 15.0, *) {
                Task { @MainActor in
                    AssistantUITgHelper.showReferralDrawFromDeeplink()
                }
                return true
            } else {
                return false
            }
        case "task":
            if #available(iOS 15.0, *) {
                let taskDeeplinkHandler = TasksContainer.shared.taskDeeplinkHandler()
                taskDeeplinkHandler.handle(url)
            }
            return true
        default:
            showUpdateAppAlert()
            return true
        }
    }
}

//  MARK: - Child Handlers
// TODO: Nicegram Extract each handler to separate class

private extension NGDeeplinkHandler {
    func handleAiAuth(url: URL) -> Bool {
        if #available(iOS 13.0, *) {
            Task { @MainActor in
                AiChatUITgHelper.routeToAiOnboarding(
                    push: { [self] controller in
                        self.push(controller)
                    }
                )
            }
            return true
        }
        return false
    }
    
    func handleAi(url: URL) -> Bool {
        if #available(iOS 13.0, *) {
            Task { @MainActor in
                AiChatUITgHelper.tryRouteToAiChatBotFromDeeplink(
                    push: { [self] controller in
                        self.push(controller)
                    }
                )
            }
            return true
        }
        return false
    }
    
    func handleGenerateImage(url: URL) -> Bool {
        if #available(iOS 15.0, *) {
            Task { @MainActor in
                ImagesHubUITgHelper.showFeed(
                    source: .deeplink,
                    forceGeneration: true
                )
            }
            return true
        } else {
            return false
        }
    }
    
    func handleNicegramPremium(url: URL) -> Bool {
        PremiumUITgHelper.routeToPremium(
            source: .deeplink
        )
        return true
    }
    
    func handleAssistant(url: URL) -> Bool {
        if #available(iOS 15.0, *) {
            Task { @MainActor in
                AssistantUITgHelper.routeToAssistant(
                    source: .deeplink
                )
            }
            return true
        } else {
            return false
        }
    }
    
    func handleOnboarding(url: URL) -> Bool {
        guard #available(iOS 15.0, *) else {
            return false
        }
        
        var dismissImpl: (() -> Void)?
        
        let c = onboardingController() {
            dismissImpl?()
        }
        c.modalPresentationStyle = .fullScreen
        
        dismissImpl = { [weak c] in
            c?.presentingViewController?.dismiss(animated: true)
        }
        
        navigationController?.topViewController?.present(c, animated: true)
        
        return true
    }
    
    func handleLoginToAssistant(url: URL) -> Bool {
        guard #available(iOS 15.0, *) else {
            return false
        }
        
        Task { @MainActor in
            LoginViewPresenter().present(
                feature: LoginFeature(source: .general)
            )
        }
        return true
    }
    
    @available(iOS 13.0, *)
    func handleSpecialOffer(url: URL) -> Bool {
        Task { @MainActor in
            SpecialOfferTgHelper.showSpecialOfferFromDeeplink(
                id: url.queryItems["id"]
            )
        }
        return true
    }
    
    func showUpdateAppAlert() {
        let alert = UIAlertController(
            title: "Update the app",
            message: "Please update the app to use the newest features!",
            preferredStyle: .alert
        )
        
        alert.addAction(
            UIAlertAction(
                title: "Close",
                style: .cancel
            )
        )
        
        alert.addAction(
            UIAlertAction(
                title: "Update",
                style: .default,
                handler: { _ in
                    let urlOpener = CoreContainer.shared.urlOpener()
                    urlOpener.open(.appStoreAppUrl)
                }
            )
        )
        
        UIApplication.topViewController?.present(alert, animated: true)
    }
}

//  MARK: - Helpers

private extension NGDeeplinkHandler {
    func getCurrentPresentationData() -> PresentationData {
        return tgAccountContext.sharedContext.currentPresentationData.with({ $0 })
    }
    
    func push(_ c: UIViewController) {
        self.navigationController?.pushViewController(
            NativeControllerWrapper(
                controller: c,
                accountContext: self.tgAccountContext
            )
        )
    }
}

