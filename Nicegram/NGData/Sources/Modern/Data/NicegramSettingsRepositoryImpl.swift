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
            trackDigitalFootprint: false,
            speechToText: .init(
                useOpenAI: [:],
                appleRecognizerState: [:]
            ),
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
    struct SpeechToTextDto: Codable {
        let useOpenAI: [Int64: Bool?]
        let appleRecognizerState: [Int64: Bool?]
    }
    
    struct KeywordsDto: Codable {
        public var show: [Int64: Bool]
        public var showTooltip: [Int64: Bool]
    }

    let disableAnimationsInChatList: Bool
    let grayscaleAll: Bool
    let grayscaleInChat: Bool
    let grayscaleInChatList: Bool
    let trackDigitalFootprint: Bool
    let speechToText: SpeechToTextDto
    let keywords: KeywordsDto
    
    var toDomain: NicegramSettings {
        NicegramSettings(
            disableAnimationsInChatList: disableAnimationsInChatList,
            grayscaleAll: grayscaleAll,
            grayscaleInChat: grayscaleInChat,
            grayscaleInChatList: grayscaleInChatList,
            trackDigitalFootprint: trackDigitalFootprint,
            speechToText: speechToText.toDomain,
            keywords: keywords.toDomain
        )
    }
}

private extension NicegramSettingsDto.SpeechToTextDto {
    var toDomain: NicegramSettings.SpeechToText {
        NicegramSettings.SpeechToText(
            useOpenAI: useOpenAI,
            appleRecognizerState: appleRecognizerState
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
            disableAnimationsInChatList: disableAnimationsInChatList,
            grayscaleAll: grayscaleAll,
            grayscaleInChat: grayscaleInChat,
            grayscaleInChatList: grayscaleInChatList,
            trackDigitalFootprint: trackDigitalFootprint,
            speechToText: speechToText.toDto,
            keywords: keywords.toDto
        )
    }
}

private extension NicegramSettings.SpeechToText {
    var toDto: NicegramSettingsDto.SpeechToTextDto {
        NicegramSettingsDto.SpeechToTextDto(
            useOpenAI: useOpenAI,
            appleRecognizerState: appleRecognizerState
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
