import Factory
import FeatOnboardingLegacy
import NGData

class LaunchOnboardingBridgeImpl {
    @Injected(\NicegramSettingsModule.nicegramSettingsRepository)
    private var nicegramSettingsRepository
}

extension LaunchOnboardingBridgeImpl: LaunchOnboardingBridge {
    func apply(
        aiEnabled: Bool,
        dataControlEnabled: Bool,
        focusModeOption: FocusModeOption?
    ) async {
        await nicegramSettingsRepository.update {
            $0.with(\.trackDigitalFootprint, dataControlEnabled)
        }
        
        await apply(focusModeOption: focusModeOption)
    }
}

private extension LaunchOnboardingBridgeImpl {
    func apply(focusModeOption: FocusModeOption?) async {
        guard let focusModeOption else { return }
        
        switch focusModeOption {
        case .light:
            NGSettings.hideStories = true
            NGSettings.hideBadgeCounters = true
        case .builder:
            await apply(focusModeOption: .light)
            
            NGSettings.hideUnreadCounters = true
        case .deep:
            await apply(focusModeOption: .builder)
            
            await nicegramSettingsRepository.update {
                $0.with(\.grayscaleAll, true)
            }
        }
    }
}
