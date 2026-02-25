import FeatAgents
import FeatAssistant
import FeatAttentionEconomy
import Foundation
import AccountContext
import Display
import FeatOnboarding
import FeatPremiumUI
import NGAiChatUI
import NGAnalytics
import NGEntryPoint
import FeatAuth
import NGCore
import class NGCoreUI.SharedLoadingView
import NGModels
import NGRemoteConfig
import NGRepoUser
import NGSpecialOffer
import NGUI
import TelegramPresentationData
import UIKit

@MainActor
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
        case "aiAgents":
            if #available(iOS 15.0, *) {
                AgentsPresenter().present()
            }
            return true
        case "aiAuth":
            return handleAiAuth(url: url)
        case "aiLily":
            return handleAi(url: url)
        case "assistant":
            return handleAssistant(url: url)
        case "assistant-auth":
            return handleLoginToAssistant(url: url)
        case "attention-economy":
            if #available(iOS 15.0, *) {
                AttPresenter().present()
            }
            return true 
        case "nicegramPremium":
            return handleNicegramPremium(url: url)
        case "onboarding":
            return handleOnboarding(url: url)
        case "specialOffer":
            return handleSpecialOffer(url: url)
        case "tgAuthSuccess":
            if #available(iOS 15.0, *) {
                AssistantTgHelper.routeToAssistant(source: .generic)
            }
            return true
        default:
            return false
        }
    }
}

//  MARK: - Child Handlers
// TODO: Nicegram Extract each handler to separate class

private extension NGDeeplinkHandler {
    func handleAiAuth(url: URL) -> Bool {
        AiChatUITgHelper.routeToAiOnboarding()
        return true
    }
    
    func handleAi(url: URL) -> Bool {
        AiChatUITgHelper.tryRouteToAiChatBotFromDeeplink()
        return true
    }
    
    func handleNicegramPremium(url: URL) -> Bool {
        PremiumUITgHelper.routeToPremium(
            source: .deeplink
        )
        return true
    }
    
    func handleAssistant(url: URL) -> Bool {
        if #available(iOS 15.0, *) {
            AssistantTgHelper.routeToAssistant(
                source: .deeplink
            )
        }
        return true
    }
    
    func handleOnboarding(url: URL) -> Bool {
        guard #available(iOS 15.0, *) else {
            return false
        }
        
        var dismissImpl: (() -> Void)?
        
        let c = OnboardingRoot().makeController(
            launchOnboardingBridge: LaunchOnboardingBridgeImpl(),
            onFinish: {
                dismissImpl?()
            }
        )
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
        
        LoginViewPresenter().present(feature: LoginFeature())
        
        return true
    }
    
    func handleSpecialOffer(url: URL) -> Bool {
        SpecialOfferTgHelper.showSpecialOfferFromDeeplink(
            id: url.queryItems["id"]
        )
        return true
    }
}

//  MARK: - Helpers

private extension NGDeeplinkHandler {
    func getCurrentPresentationData() -> PresentationData {
        return tgAccountContext.sharedContext.currentPresentationData.with({ $0 })
    }
}

