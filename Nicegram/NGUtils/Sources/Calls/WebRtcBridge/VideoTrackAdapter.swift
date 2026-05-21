import FeatCalls
import webrtc_objc

class VideoTrackAdapter {
    let track: RTCVideoTrack
    
    init(_ track: RTCVideoTrack) {
        self.track = track
    }
}

extension VideoTrackAdapter: VideoTrack {
    func add(renderer: VideoRenderer) {
        guard let renderer = renderer as? VideoRendererAdapter else { return }
        track.add(renderer.renderer)
    }
    
    func remove(renderer: VideoRenderer) {
        guard let renderer = renderer as? VideoRendererAdapter else { return }
        track.remove(renderer.renderer)
    }
}
