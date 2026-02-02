import Display
import NGLab
import NGStrings
import PresentationDataUtils
import SwiftSignalKit

extension PeerInfoScreenNode {
    func getPeerRegDate(peerId: Int64, ownerId: Int64) {
        let progressSignal = Signal<Never, NoError> { subscriber in
            let overlayController = OverlayStatusController(theme: self.presentationData.theme, type: .loading(cancelled: nil))
            self.controller?.present(overlayController, in: .window(.root))
            return ActionDisposable { [weak overlayController] in
                Queue.mainQueue().async() {
                    overlayController?.dismiss()
                }
            }
        }
        |> runOn(Queue.mainQueue())
        //|> delay(0.05, queue: Queue.mainQueue())
        let progressDisposable = progressSignal.start()
        
        // regDate signale
        var _ = (getRegDate(peerId)  |> deliverOnMainQueue).start(next: { response in
            //            let regdateString = makeNiceRegDateStr(response)
            //            let title = "NGLab.RegDate.Notice"
            //            let regdateController = textAlertController(context: self.context, title: regdateString, text: l(title, self.presentationData.strings.baseLanguageCode), actions: [
            //                TextAlertAction(type: .genericAction, title: self.presentationData.strings.Common_OK, action: {
            //                    self.requestLayout()
            //                })
            //            ])
            //            self.controller?.present(regdateController, in: .window(.root))
            self.requestLayout()
            
        }, error: { error in
            var text = ""
            switch (error) {
            case .badDeviceToken:
                text = "NGLab.BadDeviceToken"
            default:
                text = "NGLab.RegDate.FetchError"
            }
            let errorController = textAlertController(context: self.context, title: nil, text: l(text), actions: [
                TextAlertAction(type: .genericAction, title: self.presentationData.strings.Common_OK, action: {
                })])
            self.controller?.present(errorController, in: .window(.root))
            Queue.mainQueue().async {
                progressDisposable.dispose()
            }
        }, completed: {
            Queue.mainQueue().async {
                progressDisposable.dispose()
            }
        })
    }
}
