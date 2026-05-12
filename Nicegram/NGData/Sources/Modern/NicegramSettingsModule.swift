import Factory
import FeatSpeechToText
import MemberwiseInit

@MemberwiseInit(.private)
public final class NicegramSettingsModule: SharedContainer {
    public static var shared = NicegramSettingsModule(
        speechToTextModule: .shared
    )
    public var manager: ContainerManager = ContainerManager()
    
    private let speechToTextModule: SpeechToTextContainer
}

extension NicegramSettingsModule {
    public var nicegramSettingsRepository: Factory<NicegramSettingsRepository> {
        self {
            NicegramSettingsRepositoryImpl()
        }.cached
    }
}
