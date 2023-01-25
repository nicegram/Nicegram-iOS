import UIKit

public struct PlaceholderState {
    public let title: String?
    public let image: UIImage?
    public let description: String
    public let buttonState: ButtonState?
    
    public init(title: String?, image: UIImage?, description: String, buttonState: ButtonState?) {
        self.title = title
        self.image = image
        self.description = description
        self.buttonState = buttonState
    }
    
    public struct ButtonState {
        public let title: String
        public let image: UIImage?
        public let style: Style
        public let onTap: () -> Void
        
        public init(title: String, image: UIImage? = nil, style: Style = .normal, onTap: @escaping () -> Void) {
            self.title = title
            self.image = image
            self.style = style
            self.onTap = onTap
        }
        
        public enum Style {
            case normal
            case small
        }
    }
}
