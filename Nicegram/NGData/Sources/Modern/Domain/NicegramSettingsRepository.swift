import Combine
import NGCore

public struct NicegramSettings: Withable {
    public var disableAnimationsInChatList: Bool
    public var grayscaleAll: Bool
    public var grayscaleInChat: Bool
    public var grayscaleInChatList: Bool
}

public protocol NicegramSettingsRepository {
    func settings() -> NicegramSettings
    func settingsPublisher() -> AnyPublisher<NicegramSettings, Never>
    func update(_: (NicegramSettings) -> (NicegramSettings)) async
}
