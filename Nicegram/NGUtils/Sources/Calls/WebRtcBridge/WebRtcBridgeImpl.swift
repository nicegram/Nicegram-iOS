import FeatCalls

public class WebRtcBridgeImpl {
    public init() {}
}

extension WebRtcBridgeImpl: WebRtcBridge {
    public func webRtcService(_ configuration: CallConfiguration) -> WebRtcService {
        WebRtcServiceImpl(callConfiguration: configuration)
    }
}
