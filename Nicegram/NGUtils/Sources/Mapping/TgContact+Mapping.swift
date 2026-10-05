import Foundation
import TelegramBridge
import TelegramCore
import TelegramPresentationData
import TelegramStringFormatting

public extension TelegramContact {
    init(
        peer: EnginePeer,
        presence: EnginePeer.Presence?,
        presentationData: PresentationData
    ) {
        let username: String
        if let addressName = peer.addressName, !addressName.isEmpty {
            username = "@\(addressName)"
        } else {
            username = ""
        }

        let canSendMessage = canSendMessagesToPeer(peer)

        self.init(
            canSendMessage: canSendMessage,
            id: .init(peer.id),
            name: peer.debugDisplayTitle,
            presence: presence.flatMap { presence in
                TelegramContact.Presence(
                    presence: presence,
                    presentationData: presentationData
                )
            },
            username: username
        )
    }
}

public extension TelegramContact.Presence {
    init(
        presence: EnginePeer.Presence,
        presentationData: PresentationData
    ) {
        let (string, _) = stringAndActivityForUserPresence(
            strings: presentationData.strings,
            dateTimeFormat: presentationData.dateTimeFormat,
            presence: presence,
            relativeTo: Int32(Date().timeIntervalSince1970)
        )
        
        self.init(
            stringValue: string
        )
    }
}
