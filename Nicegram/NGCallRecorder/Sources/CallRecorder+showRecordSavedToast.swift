import NGStrings
import UIKit
import UndoUI

extension CallRecorder {
    func showRecordSavedToast() {
        do {
            let context = try call.unwrap().accountContext
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }

            let content: UndoOverlayContent = try .image(
                image: UIImage(bundleImageName: "RecordSave").unwrap(),
                title: nil,
                text: l("NicegramCallRecord.SavedMessage"),
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
        } catch {}
    }
}
