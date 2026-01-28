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
        dataControlEnabled: Bool
    ) async {
        await nicegramSettingsRepository.update {
            $0.with(\.trackDigitalFootprint, dataControlEnabled)
        }
    }
}
