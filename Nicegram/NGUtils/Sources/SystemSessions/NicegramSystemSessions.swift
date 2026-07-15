// The TgAccountShop system session is created with a dedicated api_id so that
// purchased accounts can be re-logged-in at any time via the loginToken flow.
// If a buyer terminates that session, the account can no longer be logged into
// through our flow, so we hide it from the active-sessions list and exclude it
// from the "Terminate other sessions" action.

import FeatTgAccountShop
import SwiftSignalKit
import TelegramCore

//  Public

public func hidingSystemSessions<E>() -> (Signal<ActiveSessionsContextState, E>) -> Signal<ActiveSessionsContextState, E> {
    let config = getConfig()
    return { signal in
        signal |> map { state in
            var state = state
            state.sessions.removeAll {
                config.isSystemSession($0)
            }
            return state
        }
    }
}

public extension ActiveSessionsContextState {
    func hasSystemSession() -> Bool {
        let config = getConfig()
        return sessions.contains { config.isSystemSession($0) }
    }
}

public extension ActiveSessionsContext {
    func removeOtherExceptSystem() -> Signal<Never, TerminateSessionError> {
        let config = getConfig()
        return self.state
        |> take(1)
        |> castError(TerminateSessionError.self)
        |> mapToSignal { state -> Signal<Never, TerminateSessionError> in
            if !state.hasSystemSession() {
                return self.removeOther()
            }
            
            let targets = state.sessions.filter { session in
                !session.isCurrent && !config.isSystemSession(session)
            }
            if targets.isEmpty {
                return .complete()
            }
            
            let attempts = targets.map { session in
                Signal<TerminateSessionError?, NoError> { subscriber in
                    self.remove(hash: session.hash).start(
                        error: { error in
                            subscriber.putNext(error)
                            subscriber.putCompletion()
                        },
                        completed: {
                            subscriber.putNext(nil)
                            subscriber.putCompletion()
                        }
                    )
                }
            }
            return combineLatest(attempts)
            |> castError(TerminateSessionError.self)
            |> mapToSignal { results -> Signal<Never, TerminateSessionError> in
                if let error = results.compactMap({ $0 }).first {
                    .fail(error)
                } else {
                    .complete()
                }
            }
        }
    }
}

//  Private

private func getConfig() -> FeatTgAccountShop.Config {
    let getConfigUseCase = FeatTgAccountShop.Module.shared.getConfigUseCase()
    return getConfigUseCase()
}

private extension FeatTgAccountShop.Config {
    func isSystemSession(_ session: RecentAccountSession) -> Bool {
        self.systemApiIds.contains(session.apiId) &&
        self.systemDeviceModels.contains(session.deviceModel)
    }
}
