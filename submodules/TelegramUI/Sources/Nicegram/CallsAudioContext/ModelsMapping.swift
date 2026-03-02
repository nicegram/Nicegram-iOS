import FeatCalls
import TelegramAudio

extension NGAudioSessionOutput {
    init(_ original: AudioSessionOutput) {
        switch original {
        case .builtin:
            self = .builtin
        case .speaker:
            self = .speaker
        case .headphones:
            self = .headphones
        case .port(let port):
            self = .port(NGAudioSessionPort(port))
        }
    }
    
    func toOriginal() -> AudioSessionOutput {
        switch self {
        case .builtin:
            return .builtin
        case .speaker:
            return .speaker
        case .headphones:
            return .headphones
        case .port(let port):
            return .port(port.toOriginal())
        }
    }
}

extension NGAudioSessionPortType {
    init(_ original: AudioSessionPortType) {
        switch original {
        case .generic:
            self = .generic
        case .bluetooth:
            self = .bluetooth
        case .wired:
            self = .wired
        }
    }
    
    func toOriginal() -> AudioSessionPortType {
        switch self {
        case .generic:
            return .generic
        case .bluetooth:
            return .bluetooth
        case .wired:
            return .wired
        }
    }
}

extension NGAudioSessionPort {
    init(_ original: AudioSessionPort) {
        self.init(
            uid: original.uid,
            name: original.name,
            type: NGAudioSessionPortType(original.type)
        )
    }
    
    func toOriginal() -> AudioSessionPort {
        AudioSessionPort(
            uid: uid,
            name: name,
            type: type.toOriginal()
        )
    }
}
