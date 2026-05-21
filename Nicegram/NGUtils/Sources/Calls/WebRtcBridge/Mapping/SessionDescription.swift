import FeatCalls
import webrtc_objc

//  MARK: - SessionDescription

extension SessionDescription {
    init(_ sdp: RTCSessionDescription) {
        self.init(sdp: sdp.sdp, type: .init(sdp.type))
    }
}

extension RTCSessionDescription {
    convenience init(_ sdp: SessionDescription) {
        self.init(type: .init(sdp.type), sdp: sdp.sdp)
    }
}

//  MARK: - SdpType

extension SdpType {
    init(_ type: RTCSdpType) {
        self = switch type {
        case .offer: .offer
        case .prAnswer: .prAnswer
        case .answer: .answer
        case .rollback: .rollback
        default: .offer
        }
    }
}

extension RTCSdpType {
    init(_ type: SdpType) {
        self = switch type {
        case .offer: .offer
        case .prAnswer: .prAnswer
        case .answer: .answer
        case .rollback: .rollback
        }
    }
}
