import Combine
import Factory
import Foundation
import NGAppCache
import NGAuth
import NGCoreUI
import NGLogging
import NGModels
import NGRemoteConfig
import NGRepoUser
import NGSpecialOffer
import UIKit

typealias AssistantInteractorInput = AssistantViewControllerOutput

protocol AssistantInteractorOutput {
    func onViewDidAppear()
    func handleUser(_: NGUser?, animated: Bool)
    func handleLoading(isLoading: Bool)
    func handleViewDidLoad() 
    func handleLogout()
    func handle(specialOffer: SpecialOffer)
    func handleSuccessSignInWithTelegram()
}

@available(iOS 13.0, *)
class AssistantInteractor: AssistantInteractorInput {
    
    var output: AssistantInteractorOutput!
    var router: AssistantRouterInput!

    @Injected(\AuthContainer.completeTgLoginUseCase) var completeTgLoginUseCase
    @Injected(\RepoUserContainer.getCurrentUserUseCase) var getCurrentUserUseCase
    private let getSpecialOfferUseCase: GetSpecialOfferUseCase
    @Injected(\AuthContainer.initTgLoginUseCase) var initTgLoginUseCase
    @Injected(\AuthContainer.logoutUseCase) var logoutUseCase
    private let eventsLogger: EventsLogger
    
    private var deeplink: Deeplink?
    private var specialOffer: SpecialOffer?
    private var isAuthorized = false
    private var cancellables = Set<AnyCancellable>()
    
    init(deeplink: Deeplink?, getSpecialOfferUseCase: GetSpecialOfferUseCase, eventsLogger: EventsLogger) {
        self.deeplink = deeplink
        self.getSpecialOfferUseCase = getSpecialOfferUseCase
        self.eventsLogger = eventsLogger
    }
    
    func onViewDidLoad() {
        output.handleViewDidLoad()
        trySignInWithTelegram()
        fetchSpecialOffer()
    }
    
    func onViewDidAppear() {
        output.onViewDidAppear()
        tryHandleDeeplink()
    }
    
    func handleAuth(isAnimated: Bool) {
        let currentUser: NGUser?
        if getCurrentUserUseCase.isAuthorized() {
            currentUser = getCurrentUserUseCase()
        } else {
            currentUser = nil
        }
        
        handleUser(currentUser, animated: isAnimated)
    }
    
    func handleDismiss() {
        router.dismiss()
        router = nil
    }
    
    func handleChat(chatURL: URL?) {
        router.showChat(chatURL: chatURL)
    }
    
    func handleOnLogin() {
        initiateLoginWithTelegram()
    }
    
    func handleLogout() {
        logoutUseCase()
        output.handleLogout()
    }
    
    func handleSpecialOffer() {
        guard let specialOffer = specialOffer else {
            return
        }

        eventsLogger.logEvent(name: "special_offer_assistant_with_id_\(specialOffer.id)")
        router.showSpecialOffer()
    }
    
    func handleTelegramBot(session: String) {
        router.dismissWithBot(session: session)
        router = nil
    }
}

@available(iOS 13.0, *)
private extension AssistantInteractor {
    func handleUser(_ user: NGUser?, animated: Bool) {
        isAuthorized = (user != nil)
        output.handleUser(user, animated: animated)
    }
    
    func trySignInWithTelegram() {
        output.handleLoading(isLoading: true)
        
        Task {
            let result = await completeTgLoginUseCase()
            
            await MainActor.run {
                self.output.handleLoading(isLoading: false)
                
                switch result {
                case .success:
                    guard !self.isAuthorized else { break }
                    self.isAuthorized = true
                    self.handleAuth(isAnimated: true)
                    self.output.handleSuccessSignInWithTelegram()
                case .sessionMissed, .sessionNotApproved, .sessionExpired:
                    break
                case .error(let error):
                    Toasts.show(.error(error))
                }
            }
        }
    }
    
    func fetchSpecialOffer() {
        getSpecialOfferUseCase.fetchSpecialOffer { [weak self] specialOffer in
            guard let self = self else { return }
            guard let specialOffer = specialOffer else { return }
            
            DispatchQueue.main.async {
                self.specialOffer = specialOffer
                self.output.handle(specialOffer: specialOffer)
            }
        }
    }
    
    func initiateLoginWithTelegram() {
        output.handleLoading(isLoading: true)
        Task {
            let result = await initTgLoginUseCase(source: .general)
            
            await MainActor.run {
                self.output.handleLoading(isLoading: false)
                
                switch result {
                case .success(let url):
                    UIApplication.shared.open(url)
                case .failure(let failure):
                    Alerts.show(.error(failure))
                }
            }
        }
    }
    
    func tryHandleDeeplink() {
        self.deeplink = nil
    }
}
