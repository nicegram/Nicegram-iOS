import Foundation
import FeatPremium
import FeatSpeechToText

public class GetSpeech2TextSettingsUseCase {
    private let nicegramSettingsRepository: NicegramSettingsRepository
    
    init(
        nicegramSettingsRepository: NicegramSettingsRepository
    ) {
        self.nicegramSettingsRepository = nicegramSettingsRepository
    }
}

public extension GetSpeech2TextSettingsUseCase {    
    func appleRecognizerState(with id: Int64) -> Bool {
        (nicegramSettingsRepository.settings().speechToText.appleRecognizerState[id] ?? false) ?? false
    }
    
    func useOpenAI(with id: Int64) -> Bool {
        (nicegramSettingsRepository.settings().speechToText.useOpenAI[id] ?? false) ?? false
    }
}
