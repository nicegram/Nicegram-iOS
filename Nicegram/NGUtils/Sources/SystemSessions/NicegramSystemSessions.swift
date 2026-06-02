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
    let systemApiIds = systemApiIds()
    return { signal in
        signal |> map { state in
            var state = state
            state.sessions.removeAll {
                systemApiIds.contains($0.apiId)
            }
            return state
        }
    }
}

public extension ActiveSessionsContext {
    func removeOtherExceptSystem() -> Signal<Never, TerminateSessionError> {
        let systemApiIds = systemApiIds()
        return self.state
        |> take(1)
        |> castError(TerminateSessionError.self)
        |> mapToSignal { state -> Signal<Never, TerminateSessionError> in
            let hasSystemSessions = state.sessions.contains { systemApiIds.contains($0.apiId) }
            if !hasSystemSessions {
                return self.removeOther()
            }
            
            let targets = state.sessions.filter { session in
                !session.isCurrent && !systemApiIds.contains(session.apiId)
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

private func systemApiIds() -> Set<Int32> {
    let getConfigUseCase = FeatTgAccountShop.Module.shared.getConfigUseCase()
    let config = getConfigUseCase()
    return Set(config.systemApiIds)
}
