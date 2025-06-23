import Display
import Foundation
import ItemListUI
import NicegramWallet
import TelegramBridge
import TelegramPresentationData

public extension TelegramBridge.TelegramTheme {
    init(_ presentationData: PresentationData) {
        let theme = presentationData.theme
        let chatList = theme.chatList
        let list = theme.list
        
        self.init(
            chatList: .init(
                itemHighlightedBackgroundColor: chatList.itemHighlightedBackgroundColor,
                messageTextColor: chatList.messageTextColor,
                messageTextFont: Font.regular(floor(presentationData.listsFontSize.itemListBaseFontSize * 15.0 / 17.0)),
                pinnedItemBackgroundColor: chatList.pinnedItemBackgroundColor,
                titleColor: chatList.titleColor,
                titleFont: Font.medium(floor(presentationData.listsFontSize.itemListBaseFontSize * 16.0 / 17.0))
            ),
            list: .init(
                itemAccentColor: list.itemAccentColor,
                itemBlocksBackgroundColor: list.itemBlocksBackgroundColor,
                itemPrimaryTextColor: list.itemPrimaryTextColor
            )
        )
    }
}

public extension WalletTelegramTheme {
    init(_ presentationData: PresentationData) {
        self.init(TelegramBridge.TelegramTheme(presentationData))
    }
}
