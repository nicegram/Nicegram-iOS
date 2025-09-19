import FeatCalls
import webrtc_objc

extension RTCIceServer {
    convenience init(_ server: IceServer) {
        self.init(
            urlStrings: server.urls,
            username: server.username,
            credential: server.credential
        )
    }
}
