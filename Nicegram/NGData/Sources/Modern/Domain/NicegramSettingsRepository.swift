import Combine
import NGCore

public struct NicegramSettings: Withable {
    public struct Keywords: Withable {
        public var show: [Int64: Bool]
        public var showTooltip: [Int64: Bool]
    }

    public var trackDigitalFootprint: Bool
    
    public var keywords: Keywords
}

public protocol NicegramSettingsRepository {
    func settings() -> NicegramSettings
    func settingsPublisher() -> AnyPublisher<NicegramSettings, Never>
    func update(_: (NicegramSettings) -> (NicegramSettings)) async
}
