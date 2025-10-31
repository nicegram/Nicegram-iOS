import AccountContext
import Combine
import MemberwiseInit
import NGUtils
import PeerMessagesMediaPlaylist
import Postbox
import SwiftSignalKit
import TelegramBridge
import TelegramCore

@MemberwiseInit
class TelegramMediaManagerImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramMediaManagerImpl: TelegramMediaManager {
    func holdAudioSession() async throws {
        let context = try contextProvider.context().unwrap()
        
        let stream = AsyncStream<Void> { continuation in
            let disposable = context.sharedContext.mediaManager.audioSession.pushExternalHolder()
            
            continuation.onTermination = { _ in
                disposable.dispose()
            }
        }
        
        for await _ in stream {}
    }
    
    func playAudio(_ messageId: TelegramMessageId) {
        Task { @MainActor in
            let context = try contextProvider.context().unwrap()
            
            let messageId = MessageId(messageId)
            
            let playlist = PeerMessagesMediaPlaylist(
                context: context,
                location: .messages(
                    chatLocation: .peer(id: messageId.peerId),
                    tagMask: .voiceOrInstantVideo,
                    at: messageId
                ),
                chatLocationContextHolder: nil
            )
            
            context.sharedContext.mediaManager.setPlaylist(
                (context, playlist),
                type: .voice,
                control: .playback(.play)
            )
        }
    }
    
    func state() -> AnyPublisher<TelegramMediaPlayerState?, Never> {
        let signal = contextProvider.contextSignal()
        |> mapToSignal { context -> Signal<(Account, SharedMediaPlayerItemPlaybackStateOrLoading, MediaManagerPlayerType)?, NoError> in
            guard let context else { return .complete() }
            return context.sharedContext.mediaManager.globalMediaPlayerState
        }
        |> map { output -> TelegramMediaPlayerState? in
            guard let (_, state, _) = output,
                  case let .state(playbackState) = state else {
                return nil
            }
            
            let status: TelegramMediaPlayerState.Status
            switch playbackState.status.status {
            case .playing, .buffering:
                status = .playing
            case .paused:
                status = .paused
            }
            
            return TelegramMediaPlayerState(status: status)
        }
        
        return signal
            .toPublisher()
            .eraseToAnyPublisher()
    }
}
