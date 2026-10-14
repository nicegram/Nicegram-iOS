import ChatListHeaderComponent
import ComponentFlow
import FeatAssistant
import UIKit

class NicegramButtonComponent: Component {
    typealias EnvironmentType = NavigationButtonComponentEnvironment
    
    static func == (lhs: NicegramButtonComponent, rhs: NicegramButtonComponent) -> Bool {
        return true
    }
    
    func makeView() -> AssistantButton {
        AssistantButton()
    }
    
    func update(view: AssistantButton, availableSize: CGSize, state: EmptyComponentState, environment: Environment<NavigationButtonComponentEnvironment>, transition: ComponentTransition) -> CGSize {
        view.systemLayoutSizeFitting(availableSize)
    }
}
