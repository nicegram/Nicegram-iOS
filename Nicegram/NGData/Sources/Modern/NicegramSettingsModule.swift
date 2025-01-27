import Factory

public final class NicegramSettingsModule: SharedContainer {
    public static var shared = NicegramSettingsModule()
    public var manager = ContainerManager()
}

extension NicegramSettingsModule {
    public var getGrayscaleSettingsUseCase: Factory<GetGrayscaleSettingsUseCase> {
        self { [self] in
            GetGrayscaleSettingsUseCase(
                nicegramSettingsRepository: nicegramSettingsRepository()
            )
        }
    }
    
    public var getSpeech2TextSettingsUseCase: Factory<GetSpeech2TextSettingsUseCase> {
        self { [self] in
            GetSpeech2TextSettingsUseCase(
                nicegramSettingsRepository: nicegramSettingsRepository()
            )
        }
    }
    
    public var setDefaultSpeech2TextSettingsUseCase: Factory<SetDefaultSpeech2TextSettingsUseCase> {
        self { [self] in
            SetDefaultSpeech2TextSettingsUseCase(
                nicegramSettingsRepository: nicegramSettingsRepository()
            )
        }
    }
}

extension NicegramSettingsModule {
    public var nicegramSettingsRepository: Factory<NicegramSettingsRepository> {
        self {
            NicegramSettingsRepositoryImpl()
        }.cached
    }
}
