import UIKit

public extension UIImage {
    func asTgIcon() -> UIImage? {
        self
            .resized(CGSize(width: 29, height: 29))?
            .sd_roundedCornerImage(withRadius: 7, corners: .allCorners, borderWidth: 0, borderColor: nil)
    }
}
