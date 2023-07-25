import ChatListHeaderComponent
import ComponentFlow
import NGAssistantUI
import UIKit

@available(iOS 13.0, *)
class NicegramButtonComponent: Component {
    typealias EnvironmentType = NavigationButtonComponentEnvironment
    
    let pressed: () -> Void
    
    init(pressed: @escaping () -> Void) {
        self.pressed = pressed
    }
    
    static func == (lhs: NicegramButtonComponent, rhs: NicegramButtonComponent) -> Bool {
        return true
    }
    
    func makeView() -> AssistantButton {
        return AssistantButton()
    }
    
    func update(view: AssistantButton, availableSize: CGSize, state: EmptyComponentState, environment: Environment<NavigationButtonComponentEnvironment>, transition: Transition) -> CGSize {
        view.pressed = pressed
        
        return view.systemLayoutSizeFitting(availableSize)
    }
}
