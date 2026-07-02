import FeatVoiceTyping

public final class VoiceTypingHelper {
    public init() {}
}

public extension VoiceTypingHelper {
    static func isEnabled() -> Bool {
        guard #available(iOS 15.0, *) else { return false }
        return VoiceTypingModule.shared.getVoiceTypingConfigUseCase()().enabled
    }
    
    func present(
        onReadyToRecord: @escaping () -> Void
    ) {
        guard #available(iOS 15.0, *) else { return }
        
        Task { @MainActor in
            VoiceTypingPresenter().present(
                onReadyToRecord: onReadyToRecord
            )
        }
    }
}
