import Combine
import NGCore

public struct NicegramSettings: Withable {
    public struct SpeechToText: Withable {
        public var useOpenAI: [Int64: Bool?]
        public var appleRecognizerState: [Int64: Bool?]
    }

    public struct Keywords: Withable {
        public var show: [Int64: Bool]
        public var showTooltip: [Int64: Bool]
    }

    public var disableAnimationsInChatList: Bool
    public var grayscaleAll: Bool
    public var grayscaleInChat: Bool
    public var grayscaleInChatList: Bool
    public var trackDigitalFootprint: Bool
    
    public var speechToText: SpeechToText
    public var keywords: Keywords
}

public protocol NicegramSettingsRepository {
    func settings() -> NicegramSettings
    func settingsPublisher() -> AnyPublisher<NicegramSettings, Never>
    func update(_: (NicegramSettings) -> (NicegramSettings)) async
}
