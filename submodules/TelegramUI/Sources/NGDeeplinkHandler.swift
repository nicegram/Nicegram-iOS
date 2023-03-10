import Foundation
import AccountContext
import Display
import NGAppContext
import NGExtensions
import NGLoadingIndicator
import NGLogging
import NGModels
import NGOnboarding
import NGRemoteConfig
import NGSpecialOffer
import NGSubscription
import NGTheme
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
        case "nicegramPremium":
            return handleNicegramPremium(url: url)
        case "assistant":
            return handleAssistant(url: url)
        case "getEsim":
            return handlePurchaseEsim(url: url)
        case "onboarding":
            return handleOnboarding(url: url)
        case "assistant-auth":
            if #available(iOS 13.0, *) {
                return handleLoginWithTelegram(url: url)
            } else {
                return false
            }
        case "specialOffer":
            return handleSpecialOffer(url: url)
        default:
            return false
        }
    }
}

//  MARK: - Child Handlers
// TODO: Nicegram Extract each handler to separate class

private extension NGDeeplinkHandler {
    func handleNicegramPremium(url: URL) -> Bool {
        let presentationData = getCurrentPresentationData()
        
        let c = SubscriptionBuilderImpl(presentationData: presentationData).build()
        c.modalPresentationStyle = .fullScreen
        
        navigationController?.topViewController?.present(c, animated: true)
        
        return true
    }
    
    func handleAssistant(url: URL) -> Bool {
        showNicegramAssistant(deeplink: AssistantDeeplink())
        return true
    }
    
    func handlePurchaseEsim(url: URL) -> Bool {
        let bundleId: Int?
        if let bundleIdParam = url.queryItems["bundleId"] {
            bundleId = Int(bundleIdParam)
        } else {
            bundleId = nil
        }
        
        showNicegramAssistant(deeplink: PurchaseEsimDeeplink(bundleId: bundleId))
        
        return true
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
        let appContext = AppContext(accountContext: tgAccountContext)
        let initiateLoginWithTelegramUseCase = appContext.resolveInitiateLoginWithTelegramUseCase()
        
        NGLoadingIndicator.shared.startAnimating()
        // Retain initiateLoginWithTelegramUseCase
        initiateLoginWithTelegramUseCase.initiateLoginWithTelegram { [initiateLoginWithTelegramUseCase] result in
            DispatchQueue.main.async {
                NGLoadingIndicator.shared.stopAnimating()
                switch result {
                case .success(let url):
                    UIApplication.shared.open(url)
                case .failure(_):
                    break
                }
            }
            debugPrint(initiateLoginWithTelegramUseCase)
        }
        return true
    }
    
    func handleSpecialOffer(url: URL) -> Bool {
        let specialOfferService = SpecialOfferServiceImpl(
            remoteConfig: RemoteConfigServiceImpl.shared
        )
        
        let specialOffer: SpecialOffer?
        if let offerId = url.queryItems["id"] {
            specialOffer = specialOfferService.getSpecialOfferWith(id: offerId)
        } else {
            specialOffer = specialOfferService.getMainSpecialOffer()
        }
        guard let specialOffer else { return false }
        
        guard let topController = navigationController?.topViewController else {
            return false
        }
        
        let ngTheme = NGThemeColors(
            telegramTheme: getCurrentPresentationData().theme.intro.statusBarStyle,
            statusBarStyle: (topController as? ViewController)?.statusBar.statusBarStyle ?? .Black
        )
        
        let builder = SpecialOfferBuilderImpl(
            specialOfferService: specialOfferService,
            ngTheme: ngTheme
        )
        
        var closeImpl: (() -> Void)?
        
        let c = builder.build(offerId: specialOffer.id) {
            closeImpl?()
        }
        
        closeImpl = { [weak c] in
            c?.dismiss(animated: true)
        }
        
        LoggersFactory().createDefaultEventsLogger().logEvent(
            name: "special_offer_deeplink_with_id_\(specialOffer.id)"
        )
        
        topController.present(c, animated: true)
        
        return true
    }
}

//  MARK: - Helpers

private extension NGDeeplinkHandler {
    func showNicegramAssistant(deeplink: Deeplink) {
        guard let rootController = navigationController as? TelegramRootController else { return }
        rootController.openChatsController(activateSearch: false)
        rootController.popToRoot(animated: true)
        rootController.chatListController?.showNicegramAssistant(deeplink: deeplink)
    }
    
    func getCurrentPresentationData() -> PresentationData {
        return tgAccountContext.sharedContext.currentPresentationData.with({ $0 })
    }
}

