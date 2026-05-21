import ComponentFlow
import FeatAdsgram
import UIKit

@available(iOS 16.0, *)
final class NicegramChatHeaderAdComponent: Component {
    let viewModel: ChatHeaderAdViewModel
    let height: Double
    
    init(viewModel: ChatHeaderAdViewModel, height: Double) {
        self.viewModel = viewModel
        self.height = height
    }
    
    static func ==(lhs: NicegramChatHeaderAdComponent, rhs: NicegramChatHeaderAdComponent) -> Bool {
        lhs.viewModel === rhs.viewModel &&
        lhs.height == rhs.height
    }
    
    func makeView() -> UIView {
        makeChatHeaderAdView(viewModel: viewModel)
    }
    
    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        CGSize(
            width: availableSize.width,
            height: height
        )
    }
}
