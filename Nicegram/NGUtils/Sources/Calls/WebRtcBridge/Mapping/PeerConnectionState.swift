import FeatCalls
import webrtc_objc

extension PeerConnectionState {
    init(_ type: RTCPeerConnectionState) {
        self = switch type {
        case .new: .new
        case .connecting: .connecting
        case .connected: .connected
        case .disconnected: .disconnected
        case .failed: .failed
        case .closed: .closed
        default: .new
        }
    }
}

extension RTCPeerConnectionState {
    init(_ type: PeerConnectionState) {
        self = switch type {
        case .new: .new
        case .connecting: .connecting
        case .connected: .connected
        case .disconnected: .disconnected
        case .failed: .failed
        case .closed: .closed
        }
    }
}

