import AccountContext
import ConvertOpusToAAC
import Display
import FeatCallRecorder
import Foundation
import LocalizedPeerData
import NGCore
import OverlayStatusController
import PresentationDataUtils
import SaveToCameraRoll
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import UIKit

private var currentVoiceMessageDownload: Task<Void, Never>?

func downloadVoiceMessage(
    context: AccountContext,
    messageId: EngineMessage.Id,
    present: @escaping (ViewController, Any?) -> Void
) {
    currentVoiceMessageDownload?.cancel()
    currentVoiceMessageDownload = Task { @MainActor in
        await VoiceMessageDownload(
            context: context,
            messageId: messageId,
            present: present
        ).run()
    }
}

@MainActor
private struct VoiceMessageDownload {
    let context: AccountContext
    let messageId: EngineMessage.Id
    let present: (ViewController, Any?) -> Void
}

private extension VoiceMessageDownload {
    func run() async {
        do {
            let file = try await exportShowingProgress()
            presentShareSheet(file)
        } catch {
            // A fetch that ends without data also surfaces as CancellationError,
            // so only an actual cancel stays silent.
            if !Task.isCancelled {
                presentError()
            }
        }
    }

    func exportShowingProgress() async throws -> EngineTempBoxFile {
        let progress = Task {
            await presentProgressAfterDelay()
        }
        defer {
            progress.cancel()
            Task {
                await progress.value?.dismiss()
            }
        }
        return try await export()
    }

    // The delay keeps a voice message that is already cached from flashing the overlay.
    func presentProgressAfterDelay() async -> ViewController? {
        do {
            try await Task.sleep(nanoseconds: 150_000_000)
        } catch {
            return nil
        }
        let controller = OverlayStatusController(
            theme: context.sharedContext.currentPresentationData.with { $0 }.theme,
            type: .loading(cancelled: {
                currentVoiceMessageDownload?.cancel()
            })
        )
        present(
            controller,
            nil
        )
        return controller
    }

    func export() async throws -> EngineTempBoxFile {
        let (message, renderedPeer) = try await loadMessage()
        let voiceFile = try findVoiceFile(in: message).unwrap()
        let sourcePath = try await fetchSourcePath(
            file: voiceFile,
            message: message
        )
        let file = EngineTempBox.shared.tempFile(
            fileName: makeFileName(
                message: message,
                renderedPeer: renderedPeer
            )
        )
        do {
            try await convert(
                sourcePath: sourcePath,
                to: file
            )
            return file
        } catch {
            EngineTempBox.shared.dispose(file)
            throw error
        }
    }

    func loadMessage() async throws -> (EngineMessage, EngineRenderedPeer?) {
        let (message, renderedPeer) = try await context.engine.data.get(
            TelegramEngine.EngineData.Item.Messages.Message(id: messageId),
            TelegramEngine.EngineData.Item.Peer.RenderedPeer(id: messageId.peerId)
        ).awaitForFirstValue()
        return (try message.unwrap(), renderedPeer)
    }

    func findVoiceFile(in message: EngineMessage) -> TelegramMediaFile? {
        message.media
            .compactMap { $0 as? TelegramMediaFile }
            .first { $0.isVoice }
    }

    func fetchSourcePath(
        file: TelegramMediaFile,
        message: EngineMessage
    ) async throws -> String {
        let completedPath = fetchMediaData(
            context: context,
            userLocation: .other,
            mediaReference: .message(
                message: MessageReference(message._asMessage()),
                media: file
            )
        )
        |> mapToSignal { state, _ -> Signal<String, NoError> in
            guard case let .data(data) = state, data.isComplete else {
                return .complete()
            }
            return .single(data.path)
        }
        |> take(1)
        return try await completedPath.awaitForFirstValue()
    }

    func convert(
        sourcePath: String,
        to file: EngineTempBoxFile
    ) async throws {
        let outputPath = try await convertOpusToAAC(
            sourcePath: sourcePath,
            allocateTempFile: { file.path }
        ).awaitForFirstValue().unwrap()
        // convertOpusToAAC reports its output path even when the writer produced nothing.
        let size = try engineFileSize(outputPath).unwrap()
        if size == 0 {
            throw UnexpectedError()
        }
    }

    func makeFileName(
        message: EngineMessage,
        renderedPeer: EngineRenderedPeer?
    ) -> String {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        return VoiceMessageFileName(
            caption: message.text,
            chatTitle: makeChatTitle(
                presentationData: presentationData,
                renderedPeer: renderedPeer
            ),
            date: Date(timeIntervalSince1970: TimeInterval(message.timestamp)),
            fallbackTitle: presentationData.strings.Message_Audio,
            timeZone: .current
        ).toString()
    }

    // The chat's main peer, as the chat list uses: a secret chat's own peer has no title.
    func makeChatTitle(
        presentationData: PresentationData,
        renderedPeer: EngineRenderedPeer?
    ) -> String {
        guard let renderedPeer else {
            return ""
        }
        if renderedPeer.peerId == context.account.peerId {
            return presentationData.strings.DialogList_SavedMessages
        }
        return renderedPeer.chatMainPeer?.displayTitle(
            strings: presentationData.strings,
            displayOrder: presentationData.nameDisplayOrder
        ) ?? ""
    }

    func presentShareSheet(_ file: EngineTempBoxFile) {
        let controller = UIActivityViewController(
            activityItems: [URL(fileURLWithPath: file.path)],
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, _, _, _ in
            EngineTempBox.shared.dispose(file)
        }
        if let window = context.sharedContext.mainWindow?.hostView.containerView.window {
            controller.popoverPresentationController?.sourceView = window
            controller.popoverPresentationController?.sourceRect = CGRect(
                x: window.bounds.width / 2.0,
                y: window.bounds.height - 1.0,
                width: 1.0,
                height: 1.0
            )
        }
        context.sharedContext.applicationBindings.presentNativeController(controller)
    }

    func presentError() {
        let strings = context.sharedContext.currentPresentationData.with { $0 }.strings
        present(
            textAlertController(
                context: context,
                title: nil,
                text: strings.Login_UnknownError,
                actions: [
                    TextAlertAction(
                        type: .defaultAction,
                        title: strings.Common_OK,
                        action: {}
                    ),
                ]
            ),
            nil
        )
    }
}
