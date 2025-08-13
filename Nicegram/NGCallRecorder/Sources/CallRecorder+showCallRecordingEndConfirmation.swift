import NGStrings
import UIKit

extension CallRecorder {
    func showCallRecordingEndConfirmation() {
        let alert = UIAlertController(
            title: l("NicegramCallRecord.StopAlertTitle"),
            message: l("NicegramCallRecord.StopAlertDescription"),
            preferredStyle: .alert
        )
        
        alert.addAction(
            UIAlertAction(
                title: l("NicegramCallRecord.StopAlertButtonCancel"),
                style: .cancel
            )
        )
        alert.addAction(
            UIAlertAction(
                title: l("NicegramCallRecord.StopAlertButtonStop"),
                style: .default,
                handler: { [self] _ in
                    stopRecordCall()
                }
            )
        )
        
        UIApplication.topViewController?.present(alert, animated: true)
    }
}
