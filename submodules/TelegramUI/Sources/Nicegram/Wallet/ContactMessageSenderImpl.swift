import AccountContext
import NGUtils
import NicegramWallet
import TelegramCore

struct ContactMessageSenderImpl {
    static func send(
        context: AccountContext,
        text: String,
        contactId: WalletContactId
    ) {
        guard let peerId = WalletTgUtils.contactIdToPeerId(contactId) else {
            return
        }
        
        let message = EnqueueMessage.message(
            text: text,
            attributes: [],
            inlineStickers: [:],
            mediaReference: nil,
            threadId: nil,
            replyToMessageId: nil,
            replyToStoryId: nil,
            localGroupingKey: nil,
            correlationId: nil,
            bubbleUpEmojiOrStickersets: []
        )
        
        let _ = enqueueMessages(
            account: context.account,
            peerId: peerId,
            messages: [message]
        ).start()
    }
}
