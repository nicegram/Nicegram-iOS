import NicegramWallet
import TelegramPresentationData

public extension TelegramTheme {
    init(_ theme: PresentationTheme) {
        let list = theme.list
        self.init(
            list: .init(
                itemAccentColor: list.itemAccentColor,
                itemBlocksBackgroundColor: list.itemBlocksBackgroundColor,
                itemPrimaryTextColor: list.itemPrimaryTextColor
            )
        )
    }
    
    init(_ presentationData: PresentationData) {
        self.init(presentationData.theme)
    }
}
