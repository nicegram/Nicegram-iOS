import Combine
import NGCore

class NicegramSettingsRepositoryImpl {
    
    private let repo = UDRepository<NicegramSettings, NicegramSettingsDto>(
        key: "nicegramSettings",
        defaultValue: NicegramSettings(
            disableAnimationsInChatList: false,
            grayscaleAll: false,
            grayscaleInChat: false,
            grayscaleInChatList: false,
            trackDigitalFootprint: false
        ),
        toDomain: \.toDomain,
        toDto: \.toDto
    )
}

extension NicegramSettingsRepositoryImpl: NicegramSettingsRepository {
    func settings() -> NicegramSettings {
        repo.get()
    }
    
    func settingsPublisher() -> AnyPublisher<NicegramSettings, Never> {
        repo.publisher()
    }
    
    func update(_ block: (NicegramSettings) -> (NicegramSettings)) async {
        await repo.update(block)
    }
}

private struct NicegramSettingsDto: Codable {
    let disableAnimationsInChatList: Bool
    let grayscaleAll: Bool
    let grayscaleInChat: Bool
    let grayscaleInChatList: Bool
    let trackDigitalFootprint: Bool
    
    var toDomain: NicegramSettings {
        NicegramSettings(disableAnimationsInChatList: disableAnimationsInChatList, grayscaleAll: grayscaleAll, grayscaleInChat: grayscaleInChat, grayscaleInChatList: grayscaleInChatList, trackDigitalFootprint: trackDigitalFootprint)
    }
}

private extension NicegramSettings {
    var toDto: NicegramSettingsDto {
        NicegramSettingsDto(disableAnimationsInChatList: disableAnimationsInChatList, grayscaleAll: grayscaleAll, grayscaleInChat: grayscaleInChat, grayscaleInChatList: grayscaleInChatList, trackDigitalFootprint: trackDigitalFootprint)
    }
}
