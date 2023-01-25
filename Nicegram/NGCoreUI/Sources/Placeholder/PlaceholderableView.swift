import NGCustomViews
import SnapKit
import UIKit

public typealias PlaceholderableView = NGCustomViews.PlaceholderableView

public extension PlaceholderableView {
    func showPlaceholder(_ state: PlaceholderState) {
        let view = DefaultPlaceholderView()
        
        switch state.buttonState?.style {
        case .small:
            view.configureWithSmallButton()
        case .normal, .none:
            break
        }
        
        view.display(image: state.image, description: state.description, buttonTitle: state.buttonState?.title, buttonImage: state.buttonState?.image)
        
        view.onButtonClick = state.buttonState?.onTap
        
        self.showPlaceholder(view)
    }
}

