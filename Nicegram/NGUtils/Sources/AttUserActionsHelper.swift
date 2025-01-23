import FeatAttentionEconomy
import Foundation
import Postbox
import TelegramCore

public struct AttUserActionsHelper {
    private static let saveUserActionUseCase = AttUserActionsModule.shared.saveUserActionUseCase()
    
    public static func save(
        peerId: PeerId?,
        type: AttUserActionType,
        userId: PeerId?
    ) {
        guard let peerId, let userId else {
            return
        }
        
        guard peerId.isChannelOrGroup() else {
            return
        }
        
        Task {
            await saveUserActionUseCase(
                AttUserAction(
                    id: UUID().uuidString,
                    chatId: peerId.ng_toInt64(),
                    timestamp: Int64(Date().timeIntervalSince1970),
                    type: type,
                    userId: userId.ng_toInt64()
                )
            )
        }
    }
}

private extension PeerId {
    func isChannelOrGroup() -> Bool {
        namespace == Namespaces.Peer.CloudChannel ||
        namespace == Namespaces.Peer.CloudGroup
    }
}
