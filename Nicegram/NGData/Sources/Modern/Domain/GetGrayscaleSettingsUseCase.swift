import Combine

public class GetGrayscaleSettingsUseCase {
    
    //  MARK: - Dependencies
    
    private let nicegramSettingsRepository: NicegramSettingsRepository
    
    //  MARK: - Lifecycle
    
    init(nicegramSettingsRepository: NicegramSettingsRepository) {
        self.nicegramSettingsRepository = nicegramSettingsRepository
    }
}

public extension GetGrayscaleSettingsUseCase {
    func grayscaleAllPublisher() -> AnyPublisher<Bool, Never> {
        adjustedSetting(\.grayscaleAll)
    }
    
    func grayscaleInChatPublisher() -> AnyPublisher<Bool, Never> {
        adjustedSetting(\.grayscaleInChat)
    }
    
    func grayscaleInChatListPublisher() -> AnyPublisher<Bool, Never> {
        adjustedSetting(\.grayscaleInChatList)
    }
}

private extension GetGrayscaleSettingsUseCase {
    func adjustedSetting<T>(_ setting: @escaping (NicegramSettings) -> T) -> AnyPublisher<T, Never> {
        nicegramSettingsRepository
            .settingsPublisher()
            .map { settings in
                var result = settings
                if result.grayscaleAll {
                    result.grayscaleInChat = false
                    result.grayscaleInChatList = false
                }
                return result
            }
            .map(setting)
            .eraseToAnyPublisher()
    }
}
