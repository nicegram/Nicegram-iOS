import NGCallRecorder
import SwiftSignalKit
import TelegramCore

extension CallRecordable {
    convenience init(_ call: PresentationCallImpl) {
        let context = call.context
        let peerId = call.peerId
        
        self.init(
            accountContext: context,
            audioDevice: call.sharedAudioContext?.audioDevice,
            callActive: call.state
            |> map { state in
                if case .active = state.state {
                    true
                } else {
                    false
                }
            },
            callTitle: { [weak call] in
                do {
                    let peer: EnginePeer
                    if let cachedPeer = call?.peer {
                        peer = cachedPeer
                    } else {
                        peer = try await context.engine.data.get(
                            TelegramEngine.EngineData.Item.Peer.Peer(id: peerId)
                        ).awaitForFirstValue().unwrap()
                    }
                    
                    return peer.debugDisplayTitle
                } catch {
                    return ""
                }
            }
        )
    }
}
