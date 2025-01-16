import Foundation
import FeatPremium

public class GetSpeech2TextSettingsUseCase {
    private let nicegramSettingsRepository: NicegramSettingsRepository
    
    init(
        nicegramSettingsRepository: NicegramSettingsRepository
    ) {
        self.nicegramSettingsRepository = nicegramSettingsRepository
    }
}

public extension GetSpeech2TextSettingsUseCase {    
    func callAsFunction() -> Bool {
        nicegramSettingsRepository.settings().speechToText.enableApple ?? false
    }
}
