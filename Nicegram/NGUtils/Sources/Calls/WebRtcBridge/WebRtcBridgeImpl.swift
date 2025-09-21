import FeatCalls
import MemberwiseInit

@MemberwiseInit(.public)
public class WebRtcBridgeImpl {
    @Init(.public) private let sharedCallAudioContext: () -> Any?
}

extension WebRtcBridgeImpl: WebRtcBridge {
    public func webRtcService(_ configuration: CallConfiguration) -> WebRtcService {
        WebRtcServiceImpl(
            callConfiguration: configuration,
            sharedCallAudioContext: sharedCallAudioContext()
        )
    }
}
