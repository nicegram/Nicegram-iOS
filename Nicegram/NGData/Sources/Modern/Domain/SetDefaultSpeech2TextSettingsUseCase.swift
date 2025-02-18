import Foundation
import FeatPremium
import FeatSpeechToText

public final class SetDefaultSpeech2TextSettingsUseCase {
    private let nicegramSettingsRepository: NicegramSettingsRepository
    private let getPreferredProviderTypeUseCase: GetPreferredProviderTypeUseCase
    private let setPreferredProviderTypeUseCase: SetPreferredProviderTypeUseCase
    
    init(
        nicegramSettingsRepository: NicegramSettingsRepository,
        speechToTextModule: SpeechToTextContainer
    ) {
        self.nicegramSettingsRepository = nicegramSettingsRepository
        self.getPreferredProviderTypeUseCase = speechToTextModule.getPreferredProviderTypeUseCase()
        self.setPreferredProviderTypeUseCase = speechToTextModule.setPreferredProviderTypeUseCase()
    }
}

public extension SetDefaultSpeech2TextSettingsUseCase {
    func callAsFunction(
        with id: Int64,
        isTelegramPremium: Bool
    ) {
        if nicegramSettingsRepository.settings().speechToText.useOpenAI[id] == nil {
            let type = getPreferredProviderTypeUseCase()
            var result = false
            
            if (type == .openAi || NGSettings.useOpenAI) && !isTelegramPremium {
                result = true
            }
            
            updateNicegramSettings {
                $0.speechToText.useOpenAI[id] = result
            }

            Task {
                await setPreferredProviderTypeUseCase(.google)
            }
        }

        if nicegramSettingsRepository.settings().speechToText.appleRecognizerState[id] == nil {
            var result = true
            
            let isNicegramPremium = isPremium()
            
            if isTelegramPremium {
                result = false
            } else if isNicegramPremium &&
                        isTelegramPremium {
                result = false
            }
            
            updateNicegramSettings {
                $0.speechToText.appleRecognizerState[id] = result
            }
        }
    }
}
