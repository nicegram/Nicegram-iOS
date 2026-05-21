import Combine
import NGCore

public final class TelegramAuthUISuppressor {
    
    //  MARK: - Logic

    private var lock = ActivationLock(
        onActivate: {},
        onDeactivate: {}
    )
    private var suppressed = false
    
    //  MARK: - Lifecycle

    public static let shared = TelegramAuthUISuppressor()
    
    private init() {
        self.lock = ActivationLock(
            onActivate: { [weak self] in
                self?.suppressed = true
            },
            onDeactivate: { [weak self] in
                self?.suppressed = false
            }
        )
    }
}

public extension TelegramAuthUISuppressor {
    func isSuppressed() -> Bool {
        suppressed
    }
    
    func suppress() -> AnyCancellable {
        lock.activate()
    }
}
