import Foundation
import TelegramCore

extension CallRecorder {
    func sendAudioToSavedMessages(
        audio: RecordedAudio,
        partNumber: Int
    ) async throws {
        defer {
            deleteFile(path: audio.path)
        }
        
        let context = try call.unwrap().accountContext
        
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

        let account = context.account
        _ = try await enqueueMessages(
            account: account,
            peerId: account.peerId,
            messages: [message]
        ).awaitForFirstValue()
    }
}

private extension CallRecorder {
    func deleteFile(path: String) {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
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
        if partNumber > 1 {
            text += "-part-\(partNumber)"
        }
        
        return text
    }
}
