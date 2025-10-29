import FeatCalls
import UIKit
import webrtc_objc

class VideoRendererAdapter {
    let renderer: RTCMTLVideoView
    
    init(_ renderer: RTCMTLVideoView) {
        self.renderer = renderer
    }
}

extension VideoRendererAdapter: VideoRenderer {
    func view() -> UIView {
        renderer
    }
}
