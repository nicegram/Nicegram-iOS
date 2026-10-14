import AccountContext
import NGCallRecorder

extension VideoChatCall {
    var callRecorder: CallRecorder? {
        switch self {
        case let .conferenceSource(call):
            (call as? PresentationCallImpl)?.callRecorder
        case let .group(call):
            (call as? PresentationGroupCallImpl)?.callRecorder
        }
    }
}
