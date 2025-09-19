import FeatCalls
import webrtc_objc

class WebRtcServiceImpl: NSObject, WebRtcService {
    
    //  MARK: - Dependencies
    
    private let factory: RTCPeerConnectionFactory
    private let peerConnection: RTCPeerConnection?
    
    weak var delegate: WebRtcServiceDelegate?
    
    //  MARK: - Lifecycle
    
    init(callConfiguration: CallConfiguration) {
        let config = RTCConfiguration()
        config.iceServers = callConfiguration.iceServers.map { .init($0) }
        config.iceTransportPolicy = .relay
        config.bundlePolicy = .maxBundle
        config.rtcpMuxPolicy = .require
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        
        let factory = RTCPeerConnectionFactory()
        let peerConnection = factory.peerConnection(
            with: config,
            constraints: RTCMediaConstraints(
                mandatoryConstraints: nil,
                optionalConstraints: nil
            ),
            delegate: nil
        )
        
        self.factory = factory
        self.peerConnection = peerConnection
        
        super.init()
        
        createMediaSenders()
        peerConnection?.delegate = self
    }
}

//  MARK: - WebRtcService

extension WebRtcServiceImpl {
    func offer() async throws -> SessionDescription {
        let peerConnection = try peerConnection.unwrap()
        
        let sdp = try await peerConnection.offer(for: getMediaConstraints())
        try await peerConnection.setLocalDescription(sdp)
        
        return .init(sdp)
    }
    
    func answer() async throws -> SessionDescription {
        let peerConnection = try peerConnection.unwrap()
        
        let sdp = try await peerConnection.answer(for: getMediaConstraints())
        try await peerConnection.setLocalDescription(sdp)
        
        return .init(sdp)
    }
    
    func set(remoteSdp: SessionDescription) async throws {
        try await peerConnection.unwrap().setRemoteDescription(.init(remoteSdp))
    }
    
    func set(remoteCandidate: IceCandidate) async throws {
        try await peerConnection.unwrap().add(.init(remoteCandidate))
    }
    
    func close() {
        peerConnection?.close()
    }
    
    func setMuted(_ muted: Bool) {
        setTrack(RTCAudioTrack.self, enabled: !muted)
    }
    
    func setSpeaker(enabled: Bool) {
        try? AVAudioSession.sharedInstance().overrideOutputAudioPort(
            enabled ? .speaker : .none
        )
    }
}

//  MARK: - RTCPeerConnectionDelegate

extension WebRtcServiceImpl: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        delegate?.didGenerateIceCandidate(.init(candidate))
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
        delegate?.didChangeConnectionState(.init(newState))
    }
}

//  MARK: - Private Functions

private extension WebRtcServiceImpl {
    func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.duckOthers, .allowBluetooth]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {}
    }
    
    func createMediaSenders() {
        configureAudioSession()
        
        let streamId = "stream"
        
        let audioTrack = createAudioTrack()
        peerConnection?.add(audioTrack, streamIds: [streamId])
    }
    
    func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = factory.audioSource(with: audioConstrains)
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")
        return audioTrack
    }
    
    func getMediaConstraints() -> RTCMediaConstraints{
        RTCMediaConstraints(
            mandatoryConstraints: [
                kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueFalse,
            ],
            optionalConstraints: nil
        )
    }
    
    func setTrack<T: RTCMediaStreamTrack>(_ type: T.Type, enabled: Bool) {
        peerConnection?.transceivers
            .compactMap { $0.sender.track as? T }
            .forEach { $0.isEnabled = enabled }
    }
}
