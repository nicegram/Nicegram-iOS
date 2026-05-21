import Combine
import protocol NGCore.IdleTimerManager
import MemberwiseInit
import NGUtils

@MemberwiseInit
class IdleTimerManagerImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension IdleTimerManagerImpl: IdleTimerManager {
    func disableIdleTimer() -> AnyCancellable {
        do {
            let context = try contextProvider.context().unwrap()
            let sharedContext = context.sharedContext
            
            let disposable = sharedContext.applicationBindings.pushIdleTimerExtension()
            return AnyCancellable(disposable)
        } catch {
            return AnyCancellable({})
        }
    }
}
