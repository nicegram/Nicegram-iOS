import AsyncDisplayKit
import FeatAssistant
import UIKit

// A hosted node rather than `.custom` bar content: the bar turns off interaction on
// custom content and takes the tap itself, which would drop AssistantButton's own
// long-press menu (show/hide hidden chats).
final class NicegramButtonNode: ASDisplayNode {
    override init() {
        super.init()
        self.setViewBlock {
            AssistantButton()
        }
    }

    // The size of upstream's own icon buttons in this bar: 30pt icons in a max(44, width) cell
    // of the bar's 44pt row.
    override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        CGSize(width: 44.0, height: 44.0)
    }
}
