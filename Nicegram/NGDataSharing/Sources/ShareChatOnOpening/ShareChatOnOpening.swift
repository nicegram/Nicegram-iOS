import AccountContext
import FeatDataSharing
import NGCore
import Postbox
import TelegramCore

public func shareChatOnOpening(
    peerId: PeerId,
    context: AccountContext
) {
    Task {
        let shareChatOnOpeningUseCase = DataSharingModule.shared.shareChatOnOpeningUseCase()
        
        let peerType: ShareChatOnOpeningUseCase.PeerType
        switch peerId.namespace {
        case Namespaces.Peer.CloudChannel:
            peerType = .channel
        case Namespaces.Peer.CloudUser:
            peerType = .user
        default:
            throw UnexpectedError()
        }
        
        try await shareChatOnOpeningUseCase(
            peerId: peerId.id._internalGetInt64Value(),
            peerType: peerType,
            dataProvider: {
                let parser = ChatParserFromLocal(context: context)
                return try await parser.parse(id: peerId)
            }
        )
    }
}
