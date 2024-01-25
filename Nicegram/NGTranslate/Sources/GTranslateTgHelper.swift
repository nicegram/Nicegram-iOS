import AccountContext
import Postbox

public extension Message {
    func hasNicegramTranslation() -> Bool {
        hasTextBlock(.ngTranslation)
    }
    
    func addNicegramTranslation(
        _ text: String,
        context: AccountContext
    ) {
        addTextBlock(text: text, block: .ngTranslation, context: context)
    }
    
    func removeNicegramTranslation(
        context: AccountContext
    ) {
        removeTextBlock(block: .ngTranslation, context: context)
    }
}
