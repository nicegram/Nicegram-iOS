import NGLocalization
import UIKit

public extension PlaceholderState {
    static func retry(error: Error, onTap: @escaping () -> Void) -> PlaceholderState {
        return retry(message: error.localizedDescription, onTap: onTap)
    }
    
    static func retry(message: String?, onTap: @escaping () -> Void) -> PlaceholderState {
        return PlaceholderState(
            title: nil,
            image: nil,
            description: mapErrorDescription(message),
            buttonState: .init(
                title: ngLocalized("Nicegram.Alert.TryAgain").uppercased(),
                image: UIImage(named: "ng.refresh"),
                style: .small,
                onTap: onTap
            )
        )
    }
}
