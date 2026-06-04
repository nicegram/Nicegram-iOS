import CopilotCore
import SwiftUI
import UIKit

@available(iOS 15.0, *)
public enum VoiceTypingOverlayHostingControllerFactory {
    public enum OutputEvent {
        case onCancel
        case onRecordingFinished
        case onRecognizingFinished(text: String)
    }
    
    public static func make(
        eventsHandler: @escaping (OutputEvent) -> Void
    ) -> UIViewController {
        let controller = UIHostingController(
            rootView: VoiceRecordingView { event in
                switch event {
                case .onCancel:
                    eventsHandler(.onCancel)
                case .onRecordingFinished:
                    eventsHandler(.onRecordingFinished)
                case .onRecognizingFinished(let text):
                    eventsHandler(.onRecognizingFinished(text: text))
                }
            }
        )
        controller.view.backgroundColor = .clear
        return controller
    }
}

