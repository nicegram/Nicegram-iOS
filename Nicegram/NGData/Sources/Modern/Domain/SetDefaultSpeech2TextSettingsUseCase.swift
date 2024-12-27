import Foundation
import FeatPremium

public final class SetDefaultSpeech2TextSettingsUseCase {
    private let nicegramSettingsRepository: NicegramSettingsRepository
    
    init(
        nicegramSettingsRepository: NicegramSettingsRepository
    ) {
        self.nicegramSettingsRepository = nicegramSettingsRepository
    }
}

public extension SetDefaultSpeech2TextSettingsUseCase {
    func callAsFunction(with isTelegramPremium: Bool) {
        guard nicegramSettingsRepository.settings().speechToText.enableApple == nil else { return }
        var result: Bool = true
        
        let isNicegramPremium = PremiumContainer.shared
            .getPremiumStatusUseCase()
            .hasPremiumOnDevice()

        if isTelegramPremium {
            result = false
        } else if isNicegramPremium &&
                  isTelegramPremium {
            result = false
        }
        
        Task {
            await nicegramSettingsRepository.update { settings in
                var settings = settings
                settings.speechToText.enableApple = result
                
                return settings
            }
        }
    }
}
