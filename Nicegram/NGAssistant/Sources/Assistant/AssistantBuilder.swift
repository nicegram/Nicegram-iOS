import UIKit
import NGAuth
import NGLogging
import NGModels
import NGRepoTg
import NGRepoUser
import NGSpecialOffer
import NGTheme
import Postbox

public protocol AssistantBuilder {
    func build(deeplink: Deeplink?) -> UIViewController
}

public protocol AssistantListener: AnyObject {
    func onOpenChat(chatURL: URL?)
}

@available(iOS 13, *)
public class AssistantBuilderImpl: AssistantBuilder {
    private let specialOfferService: SpecialOfferService
    private let ngTheme: NGThemeColors
    private weak var listener: AssistantListener?
    
    public init(specialOfferService: SpecialOfferService, ngTheme: NGThemeColors, listener: AssistantListener?) {
        self.specialOfferService = specialOfferService
        self.ngTheme = ngTheme
        self.listener = listener
    }

    public func build(deeplink: Deeplink?) -> UIViewController {
        let controller = AssistantViewController(ngTheme: ngTheme)
        let specialOfferBuilder = SpecialOfferBuilderImpl(
            specialOfferService: specialOfferService,
            ngTheme: ngTheme
        )
        
        let router = AssistantRouter(
            assistantListener: listener,
            specialOfferBuilder: specialOfferBuilder,
            ngTheme: ngTheme
        )
        router.parentViewController = controller

        let presenter = AssistantPresenter()
        presenter.output = controller

        let interactor = AssistantInteractor(
            deeplink: deeplink,
            getSpecialOfferUseCase: GetSpecialOfferUseCaseImpl(
                specialOfferService: specialOfferService
            ),
            eventsLogger: LoggersFactory().createDefaultEventsLogger()
        )
        interactor.output = presenter
        interactor.router = router

        controller.output = interactor

        return controller
    }
}
