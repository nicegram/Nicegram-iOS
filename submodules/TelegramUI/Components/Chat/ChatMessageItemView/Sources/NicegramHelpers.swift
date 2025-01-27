import Display
import TelegramPresentationData
import UIKit

public struct ChatMessageBubbleNicegramParams {
    public let insets: UIEdgeInsets
    public let maximumWidthFill: CGFloat
}

public extension ChatMessageBubbleNicegramParams {
    init(
        params: ListViewItemLayoutParams,
        presentationData: ChatPresentationData
    ) {
        let layoutConstants = chatMessageItemLayoutConstants(
            (.compact, .regular),
            params: params,
            presentationData: presentationData
        )
        let maximumWidthFill = layoutConstants.bubble.maximumWidthFill.widthFor(params.width)
        
        var insets = layoutConstants.bubble.contentInsets
            .sum(.vertical(layoutConstants.bubble.defaultSpacing))
            .sum(.horizontal(layoutConstants.bubble.edgeInset))
            .sum(.left(params.leftInset).right(params.rightInset))
        let horizontalInset = max(insets.left, insets.right)
        insets.left = horizontalInset
        insets.right = horizontalInset
        
        self.init(
            insets: insets,
            maximumWidthFill: maximumWidthFill
        )
    }
}

private extension UIEdgeInsets {
    func sum(_ other: UIEdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(
            top: self.top + other.top,
            left: self.left + other.left,
            bottom: self.bottom + other.bottom,
            right: self.right + other.right
        )
    }
}
