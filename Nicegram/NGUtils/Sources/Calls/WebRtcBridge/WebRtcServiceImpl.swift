import FeatCalls
import webrtc_objc

class WebRtcServiceImpl: NSObject, WebRtcService {
    
    //  MARK: - Dependencies
    
    private let factory: RTCPeerConnectionFactory
    private let peerConnection: RTCPeerConnection?
    private let sharedCallAudioContext: Any?
    
    weak var delegate: WebRtcServiceDelegate?
    
    //  MARK: - Logic
    
    private var localVideoCapturer: RTCCameraVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    
    //  MARK: - Lifecycle
    
    init(
        callConfiguration: CallConfiguration,
        sharedCallAudioContext: Any?
    ) {
        let config = RTCConfiguration()
        config.iceServers = callConfiguration.iceServers.map { .init($0) }
        config.iceTransportPolicy = .relay
        config.bundlePolicy = .maxBundle
        config.rtcpMuxPolicy = .require
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        
        let factory = RTCPeerConnectionFactory(
            encoderFactory: RTCDefaultVideoEncoderFactory(),
            decoderFactory: RTCDefaultVideoDecoderFactory()
        )
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
        self.sharedCallAudioContext = sharedCallAudioContext
        
        super.init()
        
        peerConnection?.delegate = self
    }
}

//  MARK: - WebRtcService

extension WebRtcServiceImpl {
    func initialize() {
        createMediaSenders()
    }
    
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
    
    func setLocalVideo(enabled: Bool) {
        setTrack(RTCVideoTrack.self, enabled: enabled)
        
        if enabled {
            startCapture()
        } else {
            stopCapture()
        }
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
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if let videoTrack = stream.videoTracks.first {
            delegate?.didReceiveRemoteVideoTrack(VideoTrackAdapter(videoTrack))
        }
    }
    
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
        let session = RTCAudioSession.sharedInstance()
        
        session.lockForConfiguration()
        do {
            try session.setCategory(
                .playAndRecord,
                with: [.allowBluetoothA2DP, .mixWithOthers]
            )
            try session.setMode(.voiceChat)
        } catch {}
        session.unlockForConfiguration()
    }
    
    func createMediaSenders() {
        configureAudioSession()
        
        let streamId = "stream"
        
        let audioTrack = createAudioTrack()
        peerConnection?.add(audioTrack, streamIds: [streamId])
        
        let videoTrack = createVideoTrack()
        peerConnection?.add(videoTrack, streamIds: [streamId])
    }
    
    func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = factory.audioSource(with: audioConstrains)
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")
        return audioTrack
    }
    
    func createVideoTrack() -> RTCVideoTrack {
        let source = factory.videoSource()
        let capturer = RTCCameraVideoCapturer(delegate: source)
        let track = factory.videoTrack(with: source, trackId: "video0")
        
        self.localVideoCapturer = capturer
        
        self.localVideoTrack = track
        self.delegate?.didReceiveLocalVideoTrack(VideoTrackAdapter(track))
        
        return track
    }
    
    func getMediaConstraints() -> RTCMediaConstraints{
        RTCMediaConstraints(
            mandatoryConstraints: [
                kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue,
            ],
            optionalConstraints: nil
        )
    }
    
    func setTrack<T: RTCMediaStreamTrack>(_ type: T.Type, enabled: Bool) {
        peerConnection?.transceivers
            .compactMap { $0.sender.track as? T }
            .forEach { $0.isEnabled = enabled }
    }
    
    func startCapture() {
        do {
            let capturer = try localVideoCapturer.unwrap()
            let device = try RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == .front }).unwrap()
            
            let format = try RTCCameraVideoCapturer.supportedFormats(for: device).last.unwrap()
            let fps = try format.videoSupportedFrameRateRanges.first.unwrap().maxFrameRate
            
            capturer.startCapture(with: device, format: format, fps: Int(fps))
        } catch {}
    }
    
    func stopCapture() {
        localVideoCapturer?.stopCapture()
    }
}
