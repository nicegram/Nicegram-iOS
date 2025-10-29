import AccountContext
import FeatCallRecorder
import NGStrings
import Postbox
import TelegramCore
import UIKit
import UndoUI

extension CallRecorder {
    func showRecordSavedToast(
        receiverId: PeerId?
    ) {
        Task {
            let context = try call.unwrap().accountContext
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }

            let text = await toastText(
                context: context,
                receiverId: receiverId
            )

            let content: UndoOverlayContent = try .image(
                image: UIImage(bundleImageName: "RecordSave").unwrap(),
                title: nil,
                text: text,
                round: true,
                undoText: nil
            )

            let controller = UndoOverlayController(
                presentationData: presentationData,
                content: content,
                elevatedLayout: false,
                position: .top,
                animateInAsReplacement: false,
                action: { _ in return false }
            )

            context.sharedContext.mainWindow?.present(controller, on: .root)
        }
    }
}

private extension CallRecorder {
    func toastText(
        context: AccountContext,
        receiverId: PeerId?
    ) async -> String {
        await FeatCallRecorder.strings.recordSavedToast(
            receiverChatName(context: context, receiverId: receiverId)
        )
    }

    func receiverChatName(
        context: AccountContext,
        receiverId: PeerId?
    ) async -> String {
        guard let receiverId else {
            return FeatCallRecorder.strings.savedMessages()
        }
        
        let peer = try? await context.engine.data
            .get(TelegramEngine.EngineData.Item.Peer.Peer(id: receiverId))
            .awaitForFirstValue()
        return peer?.debugDisplayTitle ?? receiverId.ng_toInt64Text()
    }
}
