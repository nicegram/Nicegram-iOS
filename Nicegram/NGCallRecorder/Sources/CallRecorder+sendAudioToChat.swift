import FeatCallRecorder
import Foundation
import NGCore
import NGUtils
import Postbox
import TelegramCore

extension CallRecorder {
    func sendAudioToChat(
        audio: RecordedAudio,
        partNumber: Int
    ) async throws -> PeerId? {
        defer {
            deleteFile(path: audio.path)
        }
        
        if call == nil {
            log("sendAudioToChat call=nil")
        }
        
        let text = try await makeText(
            audio: audio,
            partNumber: partNumber
        )
        let media = makeMedia(audio)
        
        let message: EnqueueMessage = .message(
            text: text,
            attributes: [],
            inlineStickers: [:],
            mediaReference: .standalone(media: media),
            threadId: nil,
            replyToMessageId: nil,
            replyToStoryId: nil,
            localGroupingKey: nil,
            correlationId: nil,
            bubbleUpEmojiOrStickersets: []
        )

        do {
            let peerId = await getReceiverId()
            try await send(message: message, to: peerId)
            return peerId
        } catch {
            try await send(message: message, to: nil)
            return nil
        }
    }
}

private extension CallRecorder {
    func deleteFile(path: String) {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
    }
    
    func getReceiverId() async -> PeerId? {
        let getSettingsUseCase = CallRecorderModule.shared.getSettingsUseCase()
        
        if let receiverId = await getSettingsUseCase().receiverId {
            return PeerId.ng_fromInt64(receiverId)
        } else {
            return nil
        }
    }
    
    func makeMedia(_ audio: RecordedAudio) -> TelegramMediaFile {
        let id = Int64.random(in: 0 ... Int64.max)
        let resource = LocalFileReferenceMediaResource(
            localFilePath: audio.path,
            randomId: id
        )
        return TelegramMediaFile(
            fileId: EngineMedia.Id(namespace: Namespaces.Media.LocalFile, id: id),
            partialReference: nil,
            resource: resource,
            previewRepresentations: [],
            videoThumbnails: [],
            immediateThumbnailData: nil,
            mimeType: "audio/ogg",
            size: Int64(audio.size),
            attributes: [
                .Audio(
                    isVoice: true,
                    duration: Int(audio.duration),
                    title: "",
                    performer: nil,
                    waveform: nil
                )
            ],
            alternativeRepresentations: []
        )
    }
    
    func makeText(
        audio: RecordedAudio,
        partNumber: Int
    ) async throws -> String {
        let title = try await call.unwrap().callTitle()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let date = dateFormatter.string(from: Date())
        
        var text = "\(title)-\(date)"
        if let peerId = call?.peerId?.ng_toInt64() {
            text = "\(peerId)-\(text)"
        }
        if partNumber > 1 {
            text += "-part-\(partNumber)"
        }
        
        return text
    }
    
    func send(
        message: EnqueueMessage,
        to: PeerId?
    ) async throws {
        let context = try call.unwrap().accountContext
        let account = context.account
        let ids = try await enqueueMessages(
            account: account,
            peerId: to ?? account.peerId,
            messages: [message]
        ).awaitForFirstValue()
        if ids.isEmpty {
            throw UnexpectedError()
        }
    }
}
