import AVFoundation
import FeatCalls

extension AVCaptureDevice.Position {
    init(_ position: CameraPosition) {
        self = switch position {
        case .unspecified: .unspecified
        case .back: .back
        case .front: .front
        }
    }
}
