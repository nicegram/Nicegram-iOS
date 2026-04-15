import AccountContext
import FeatVoiceTyping

public final class VoiceTypingHelper {
    private let context: AccountContext
    
    public init(context: AccountContext) {
        self.context = context
    }
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
