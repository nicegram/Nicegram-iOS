import Foundation
import AccountContext
import Display
import FeatImagesHubUI
import NGAiChatUI
import NGAnalytics
import NGAssistantUI
import NGAuth
import NGCardUI
import class NGCoreUI.SharedLoadingView
import NGModels
import NGOnboarding
import NGRemoteConfig
import NGPremiumUI
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
            if #available(iOS 13.0, *) {
                return handleLoginWithTelegram(url: url)
            } else {
                return false
            }
        case "generateImage":
            return handleGenerateImage(url: url)
        case "nicegramPremium":
            return handleNicegramPremium(url: url)
        case "onboarding":
            return handleOnboarding(url: url)
        case "specialOffer":
            if #available(iOS 13.0, *) {
                return handleSpecialOffer(url: url)
            } else {
                return false
            }
        case "pstAuth":
            return handlePstAuth(url: url)
        default:
            return false
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
        PremiumUITgHelper.routeToPremium()
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
        let presentationData = getCurrentPresentationData()
        
        var dismissImpl: (() -> Void)?
        
        let c = onboardingController(languageCode: presentationData.strings.baseLanguageCode) {
            dismissImpl?()
        }
        c.modalPresentationStyle = .fullScreen
        
        dismissImpl = { [weak c] in
            c?.presentingViewController?.dismiss(animated: true)
        }
        
        navigationController?.topViewController?.present(c, animated: true)
        
        return true
    }
    
    @available(iOS 13.0, *)
    func handleLoginWithTelegram(url: URL) -> Bool {
        let initTgLoginUseCase = AuthTgHelper.resolveInitTgLoginUseCase()
        
        SharedLoadingView.start()
        // Retain initTgLoginUseCase
        Task {
            let result = await initTgLoginUseCase(source: .general)
            
            await MainActor.run {
                SharedLoadingView.stop()
                
                switch result {
                case .success(let url):
                    UIApplication.shared.open(url)
                case .failure(_):
                    break
                }
            }
        }
        return true
    }
    
    @available(iOS 13.0, *)
    func handleSpecialOffer(url: URL) -> Bool {
        return SpecialOfferTgHelper.showSpecialOfferFromDeeplink(
            id: url.queryItems["id"]
        )
    }
    
    func handlePstAuth(url: URL) -> Bool {
        if #available(iOS 13.0, *) {
            Task { @MainActor in
                CardUITgHelper.showSplashFromDeeplink()
            }
            return true
        }
        return false
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

