import NGAuth
import UIKit
import NGCore
import NGEnv
import NGModels
import NGSpecialOffer
import NGTheme
import Postbox

protocol AssistantRouterInput: AnyObject {
    func dismiss()
    func showChat(chatURL: URL?)
    func dismissWithBot(session: String)
    func showSpecialOffer()
}

final class AssistantRouter: AssistantRouterInput {
    private weak var assistantListener: AssistantListener?
    
    weak var parentViewController: AssistantViewController?
    
    private let specialOfferBuilder: SpecialOfferBuilder
    
    init(assistantListener: AssistantListener?,
         specialOfferBuilder: SpecialOfferBuilder,
         ngTheme: NGThemeColors) {
        self.assistantListener = assistantListener
        self.specialOfferBuilder = specialOfferBuilder
    }

    func dismiss() {
        parentViewController?.dismiss(animated: false, completion: nil)
    }
    
    func showChat(chatURL: URL?) {
        parentViewController?.dismiss(animated: false) { [weak self] in
            guard let self = self else { return }
            self.assistantListener?.onOpenChat(chatURL: chatURL)
        }
    }
    
    func dismissWithBot(session: String) {
        parentViewController?.dismiss(animated: true, completion: { 
            guard var url = URL(string: "ncg://resolve") else { return }
            url = url
                .appendingQuery(key: "domain", value: NGENV.telegram_auth_bot)
                .appendingQuery(key: "start", value: session)
            
            UIApplication.shared.openURL(url)
        })
    }
    
    func showSpecialOffer() {
        let vc = specialOfferBuilder.build() { [weak self] in
            self?.parentViewController?.dismiss(animated: true)
        }
        
        parentViewController?.present(vc, animated: true)
    }
}
