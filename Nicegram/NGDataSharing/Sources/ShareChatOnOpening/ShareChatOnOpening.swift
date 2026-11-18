import AccountContext
import NGUtils
import FeatDataSharing
import NGCore
import TelegramCore

public func shareChatOnOpening(
    peerId: EnginePeer.Id,
    context: AccountContext
) {
    // Nicegram Business, work-account data sharing: share-on-opening
    guard !context.nicegramBusiness.restrictsAccountControl() else {
        return
    }
    //
    _ = Task {
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
