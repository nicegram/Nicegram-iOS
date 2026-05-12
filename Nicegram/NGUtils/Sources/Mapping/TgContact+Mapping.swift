import Foundation
import NicegramWallet
import TelegramCore
import TelegramPresentationData
import TelegramStringFormatting

public extension TgContact {
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
        
        let canSendMessage = canSendMessagesToPeer(peer._asPeer())
        
        self.init(
            id: .init(peer.id),
            canSendMessage: canSendMessage,
            name: peer.debugDisplayTitle,
            presence: presence.flatMap { presence in
                TgContact.Presence(
                    presence: presence,
                    presentationData: presentationData
                )
            },
            username: username
        )
    }
}

public extension TgContact.Presence {
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
