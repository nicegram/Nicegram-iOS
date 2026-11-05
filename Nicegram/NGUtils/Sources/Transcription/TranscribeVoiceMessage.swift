import AccountContext
import ConvertOpusToAAC
import FeatTranscription
import Foundation
import NGCore
import SwiftSignalKit
import TelegramCore

public func ngTranscribeVoiceMessage(
    context: AccountContext,
    message: EngineRawMessage
) async throws {
    let surface = VoiceMessageSurface()
    let gate = await GatePresenter()

    try await gate.ensureAllowed(surface: surface)

    let file = try message.media
        .compactMap { $0 as? TelegramMediaFile }
        .first { $0.isVoice }
        .unwrap()

    // Nothing guarantees the voice message was downloaded: a long one comes here
    // instead of to Telegram's transcription. Read from the media box alone, a
    // missing file is an empty partial one, which converts into an m4a that
    // AVFoundation cannot open. The timeout leaves room for an hour-long message
    // on a slow connection.
    let voiceFile = try await MediaFetcher(context: context).getResourceFile(
        mediaResourceReference: AnyMediaReference.message(
            message: MessageReference(message),
            media: file
        ).resourceReference(file.resource),
        userLocation: .peer(message.id.peerId),
        userContentType: MediaResourceUserContentType(file: file),
        options: MediaFetcher.Options(
            fetchIfMissing: true,
            fetchTimeout: 120
        )
    )

    // A Telegram voice message is Ogg/Opus, and the media box stores it under a
    // hash name with no extension at all. Both matter: the transcription request
    // names the file and declares its mime type, and the provider validates the
    // bytes against them. Sending the Opus payload as `audio.m4a` -- which is
    // what an extension-less path used to infer -- fails with an opaque
    // `Provider returned 400`. So convert to the same AAC/m4a the microphone
    // recorder produces, which is the format this pipeline is known to accept.
    let audioPath = try await convertOpusToAAC(
        sourcePath: voiceFile.path,
        allocateTempFile: { EngineTempBox.shared.tempFile(fileName: "audio.m4a").path }
    )
    .awaitForFirstValue()
    .unwrap()

    defer {
        try? FileManager.default.removeItem(atPath: audioPath)
    }

    do {
        let result = try await FeatTranscription.Module.shared.transcribeUseCase()(
            audio: URL(fileURLWithPath: audioPath)
        )
        if let substituted = result.substitutedModel {
            await gate.notifySubstitution(model: substituted)
        }
        await message.setTranscription(
            result.text,
            context: context
        )
    } catch {
        await gate.handle(
            error: error,
            surface: surface
        )
        throw error
    }
}
