import Combine
import NGCore

public struct NicegramSettings: Withable {
    public struct SpeechToText: Withable {
        public var enableApple: Bool?
    }
    
    public var disableAnimationsInChatList: Bool
    public var grayscaleAll: Bool
    public var grayscaleInChat: Bool
    public var grayscaleInChatList: Bool
    public var trackDigitalFootprint: Bool
    public var speechToText: SpeechToText
}

public protocol NicegramSettingsRepository {
    func settings() -> NicegramSettings
    func settingsPublisher() -> AnyPublisher<NicegramSettings, Never>
    func update(_: (NicegramSettings) -> (NicegramSettings)) async
}
