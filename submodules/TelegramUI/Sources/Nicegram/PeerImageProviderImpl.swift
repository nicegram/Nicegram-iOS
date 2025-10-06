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
        await getAvatar(PeerId(id))
    }
    
    func image(for id: TelegramId) async -> UIImage? {
        await getAvatar(PeerId(id))
    }
}

private extension TelegramPeerImageProviderImpl {
    func getAvatar(_ peerId: PeerId) async -> UIImage? {
        do {
            let context = try contextProvider.context().unwrap()
            
            let signal =  context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
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
            return try await signal.awaitForFirstValue()
        } catch {
            return nil
        }
    }
}
