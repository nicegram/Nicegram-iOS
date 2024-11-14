private let nicegramSettingsRepository = NicegramSettingsModule.shared.nicegramSettingsRepository()

public func getNicegramSettings() -> NicegramSettings {
    nicegramSettingsRepository.settings()
}

public func updateNicegramSettings(_ modifier: @escaping (inout NicegramSettings) -> Void) {
    Task {
        await nicegramSettingsRepository.update {
            var result = $0
            modifier(&result)
            return result
        }
    }
}
