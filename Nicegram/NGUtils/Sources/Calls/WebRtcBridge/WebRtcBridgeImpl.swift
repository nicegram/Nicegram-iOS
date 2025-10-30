import FeatCalls
import MemberwiseInit
import webrtc_objc

@MemberwiseInit(.public)
public class WebRtcBridgeImpl {
    @Init(.public) private let sharedCallAudioContext: () -> Any?
}

extension WebRtcBridgeImpl: WebRtcBridge {
    public func videoRenderer() -> VideoRenderer {
        let view = RTCMTLVideoView()
        view.videoContentMode = .scaleAspectFill
        
        return VideoRendererAdapter(view)
    }
    
    public func webRtcService(_ configuration: CallConfiguration) -> WebRtcService {
        WebRtcServiceImpl(
            callConfiguration: configuration,
            sharedCallAudioContext: sharedCallAudioContext()
        )
    }
}
