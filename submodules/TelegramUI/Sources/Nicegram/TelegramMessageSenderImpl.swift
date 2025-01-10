import MemberwiseInit
import NGCore
import NGUtils
import Postbox
import SwiftSignalKit
import TelegramBridge
import TelegramCore

@MemberwiseInit
class TelegramMessageSenderImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramMessageSenderImpl: TelegramMessageSender {
    func sendBotStart(botName: String, start: String?) async {
        do {
            let context = try contextProvider.context().unwrap()
            
            let peerSignal = context.engine.peers.resolvePeerByName(name: botName, referrer: nil)
             |> mapToSignal { result -> Signal<EnginePeer?, NoError> in
                 guard case let .result(result) = result else {
                     return .complete()
                 }
                 return .single(result)
             }
            guard let peer = try await peerSignal.awaitForFirstValue() else {
                throw UnexpectedError()
            }
            
            try await context.engine.messages
                .requestStartBot(botPeerId: peer.id, payload: start)
                .awaitForFirstValue()
        } catch {}
    }
    
    func sendMessage(to: TelegramId, text: String) async {
        guard let context = contextProvider.context() else {
            return
        }
        
        let peerId = PeerId(to)

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

        try? await enqueueMessages(
            account: context.account,
            peerId: peerId,
            messages: [message]
        ).awaitForFirstValue()
    }
}
