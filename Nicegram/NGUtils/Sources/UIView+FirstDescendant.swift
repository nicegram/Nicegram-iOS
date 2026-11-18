import UIKit

public extension UIView {
    func firstDescendant<T: UIView>(ofType type: T.Type) -> T? {
        for subview in subviews {
            if let match = subview as? T ?? subview.firstDescendant(ofType: type) {
                return match
            }
        }
        return nil
    }
}
