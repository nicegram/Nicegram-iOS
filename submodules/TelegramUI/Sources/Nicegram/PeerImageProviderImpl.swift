import AccountContext
import MemberwiseInit
import NGUtils
import Postbox
import TelegramCore
import UIKit
import SwiftSignalKit
import AvatarNode
import TelegramBridge

@MemberwiseInit
class TelegramPeerImageProviderImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramPeerImageProviderImpl: TelegramPeerImageProvider {
    func image(for id: Int64) async -> UIImage? {
        guard let context = contextProvider.context() else {
            return nil
        }

        do {
            let image = try await peerAvatar(with: context, peerId: PeerId(id)).awaitForFirstValue()
            
            return image
        } catch {
            return nil
        }
        
//        let peerId = PeerId(id)
//        
//        guard let peer = await WalletTgUtils.peerById(
//            peerId,
//            context: context
//        ) else {
//            return nil
//        }
//
//        let imageData = try? await fetchAvatarImage(
//            peer: peer._asPeer(),
//            context: context
//        ).awaitForFirstValue()
//
//        guard let imageData else { return nil }
//        
//        return UIImage(data: imageData)
    }
    
    private func peerAvatar(with context: AccountContext, peerId: PeerId) -> Signal<UIImage?, NoError> {
        return context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
        |> mapToSignal { peer -> Signal<UIImage?, NoError> in
            guard let peer else { return .single(nil) }
            
            return peerAvatarCompleteImage(
                account: context.account,
                peer: peer,
                forceProvidedRepresentation: false,
                representation: nil,
                size: CGSize(width: 50, height: 50)
            )
        }
    }
}

