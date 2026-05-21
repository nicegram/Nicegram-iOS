import FeatCalls
import webrtc_objc

extension IceCandidate {
    init(_ candidate: RTCIceCandidate) {
        self.init(
            candidate: candidate.sdp,
            sdpMid: candidate.sdpMid,
            sdpMLineIndex: candidate.sdpMLineIndex
        )
    }
}

extension RTCIceCandidate {
    convenience init(_ candidate: IceCandidate) {
        self.init(
            sdp: candidate.candidate,
            sdpMLineIndex: candidate.sdpMLineIndex,
            sdpMid: candidate.sdpMid
        )
    }
}
