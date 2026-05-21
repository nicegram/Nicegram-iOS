import Combine
import NGCore

class NicegramSettingsRepositoryImpl {
    
    private let repo = UDRepository<NicegramSettings, NicegramSettingsDto>(
        key: "nicegramSettings",
        defaultValue: NicegramSettings(
            trackDigitalFootprint: false,
            keywords: .init(
                show: [:],
                showTooltip: [:]
            )
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
    struct KeywordsDto: Codable {
        public var show: [Int64: Bool]
        public var showTooltip: [Int64: Bool]
    }

    let trackDigitalFootprint: Bool
    let keywords: KeywordsDto
    
    var toDomain: NicegramSettings {
        NicegramSettings(
            trackDigitalFootprint: trackDigitalFootprint,
            keywords: keywords.toDomain
        )
    }
}

private extension NicegramSettingsDto.KeywordsDto {
    var toDomain: NicegramSettings.Keywords {
        NicegramSettings.Keywords(
            show: show,
            showTooltip: showTooltip
        )
    }
}

private extension NicegramSettings {
    var toDto: NicegramSettingsDto {
        NicegramSettingsDto(
            trackDigitalFootprint: trackDigitalFootprint,
            keywords: keywords.toDto
        )
    }
}

private extension NicegramSettings.Keywords {
    var toDto: NicegramSettingsDto.KeywordsDto {
        NicegramSettingsDto.KeywordsDto(
            show: show,
            showTooltip: showTooltip
        )
    }
}
