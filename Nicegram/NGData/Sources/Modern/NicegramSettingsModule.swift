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
}

extension NicegramSettingsModule {
    public var nicegramSettingsRepository: Factory<NicegramSettingsRepository> {
        self {
            NicegramSettingsRepositoryImpl()
        }.cached
    }
}
