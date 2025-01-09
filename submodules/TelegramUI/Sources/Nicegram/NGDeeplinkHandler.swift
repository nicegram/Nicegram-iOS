import FeatAssistant
import FeatAttentionEconomy
import Foundation
import AccountContext
import Display
import FeatAvatarGeneratorUI
import FeatImagesHubUI
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
import FeatPersonalityUI

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
        case "avatarGenerator":
            if #available(iOS 15.0, *) {
                if let topController = UIApplication.topViewController {
                    AvatarGeneratorUIHelper().navigateToGenerationFlow(
                        from: topController
                    )
                }
            }
            return true
        case "avatarMyGenerations":
            if #available(iOS 15.0, *) {
                AvatarGeneratorUIHelper().navigateToGenerator()
            }
            return true    
        case "generateImage":
            return handleGenerateImage(url: url)
        case "nicegramPremium":
            return handleNicegramPremium(url: url)
        case "onboarding":
            return handleOnboarding(url: url)
        case "specialOffer":
            return handleSpecialOffer(url: url)
        case "refferaldraw":
            if #available(iOS 15.0, *) {
                AssistantTgHelper.showReferralDrawFromDeeplink()
            }
            return true
        case "tgAuthSuccess":
            if #available(iOS 15.0, *) {
                TgAuthSuccessPresenter().presentIfNeeded()
            }
            return true
        case "personality":
            if #available(iOS 15.0, *) {
                PersonalityPresenter().present()
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
    
    func handleGenerateImage(url: URL) -> Bool {
        if #available(iOS 15.0, *) {
            ImagesHubUITgHelper.showFeed(
                source: .deeplink,
                forceGeneration: true
            )
        }
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
        
        let c = LaunchOnboardingFactory().makeController(
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
        
        Task { @MainActor in
            let getCurrentUserUseCase = RepoUserContainer.shared.getCurrentUserUseCase()
            let initTgLoginUseCase = AuthContainer.shared.initTgLoginUseCase()
            let toastManager = CoreContainer.shared.toastManager()
            let urlOpener = CoreContainer.shared.urlOpener()
            
            guard !getCurrentUserUseCase.isAuthorized() else {
                return
            }
            
            SharedLoadingView.start()
            
            let result = await initTgLoginUseCase(source: .general)
            
            SharedLoadingView.stop()
            switch result {
            case let .success(url):
                urlOpener.open(url)
            case let .failure(error):
                toastManager.showError(error)
            }
        }
        
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

