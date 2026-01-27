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
    func send(_ intent: TelegramSendMessageIntent) async throws {
        let peerId = try await resolvePeerId(intent.recipient)
        
        try await send(
            media: intent.media,
            peerId: peerId,
            text: intent.text
        )
    }
    
    func sendBotStart(botName: String, start: String?) async {
        do {
            let context = try contextProvider.context().unwrap()
            
            let peer = try await getPeer(username: botName)
            
            try await context.engine.messages
                .requestStartBot(botPeerId: peer.id, payload: start)
                .awaitForFirstValue()
        } catch {}
    }
}

//  MARK: - Utils

private extension TelegramMessageSenderImpl {
    func send(
        media: TelegramSendMessageIntent.Media?,
        peerId: PeerId,
        text: String
    ) async throws {
        let context = try contextProvider.context().unwrap()
        
        let mediaReference = try media.flatMap {
            try toTelegramMediaReference($0)
        }

        let message = EnqueueMessage.message(
            text: text,
            attributes: [],
            inlineStickers: [:],
            mediaReference: mediaReference,
            threadId: nil,
            replyToMessageId: nil,
            replyToStoryId: nil,
            localGroupingKey: nil,
            correlationId: nil,
            bubbleUpEmojiOrStickersets: []
        )

        _ = try await enqueueMessages(
            account: context.account,
            peerId: peerId,
            messages: [message]
        ).awaitForFirstValue()
    }
    
    func resolvePeerId(
        _ recipient: TelegramSendMessageIntent.Recipient
    ) async throws -> PeerId {
        switch recipient {
        case let .peerId(peerId):
            return PeerId(peerId)
        case .savedMessages:
            let context = try contextProvider.context().unwrap()
            return context.account.peerId
        case let .username(username):
            return try await getPeer(username: username).id
        }
    }
    
    func getPeer(
        username: String
    ) async throws -> EnginePeer {
        let context = try contextProvider.context().unwrap()
        
        let peerSignal = context.engine.peers.resolvePeerByName(name: username, referrer: nil)
         |> mapToSignal { result -> Signal<EnginePeer?, NoError> in
             guard case let .result(result) = result else {
                 return .complete()
             }
             return .single(result)
         }
        let peer = try await peerSignal.awaitForFirstValue().unwrap()
        
        return peer
    }
}

//  MARK: - Media Mapping

private extension TelegramMessageSenderImpl {
    func toTelegramMediaReference(
        _ media: TelegramSendMessageIntent.Media
    ) throws -> AnyMediaReference {
        let telegramMedia = switch media {
        case let .file(file):
            try toTelegramMedia(file)
        }
        
        return .standalone(media: telegramMedia)
    }
    
    func toTelegramMedia(
        _ file: LocalFile
    ) throws -> Media {
        let context = try contextProvider.context().unwrap()
        
        let path = file.url.path
        let size = try fileSize(path).unwrap()
        let id = Int64.random(in: Int64.min...Int64.max)
        let resource = LocalFileMediaResource(
            fileId: id,
            size: size
        )
        
        if file.isTemporary {
            context.account.postbox.mediaBox.moveResourceData(
                resource.id,
                fromTempPath: path
            )
        } else {
            context.account.postbox.mediaBox.copyResourceData(
                resource.id,
                fromTempPath: path
            )
        }
        
        let media = TelegramMediaFile(
            fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: id),
            partialReference: nil,
            resource: resource,
            previewRepresentations: [],
            videoThumbnails: [],
            immediateThumbnailData: nil,
            mimeType: file.mimeType ?? "application/text",
            size: size,
            attributes: [
                .FileName(fileName: file.name)
            ],
            alternativeRepresentations: []
        )
        
        return media
    }
}
