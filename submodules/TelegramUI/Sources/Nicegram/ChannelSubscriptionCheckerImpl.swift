import AccountContext
import FeatTasks
import SwiftSignalKit
import TelegramCore

@available(iOS 13.0, *)
class ChannelSubscriptionCheckerImpl {
    
    //  MARK: - Dependencies
    
    private let context: AccountContext
    
    //  MARK: - Lifecycle
    
    init(context: AccountContext) {
        self.context = context
    }
}

@available(iOS 13.0, *)
extension ChannelSubscriptionCheckerImpl: ChannelSubscriptionChecker {
    public func isSubscribed(to id: ChannelId) async -> Bool {
        await withCheckedContinuation { continuation in
            _ = (context.engine.peers.resolvePeerByName(name: id)
            |> mapToSignal { result -> Signal<EnginePeer?, NoError> in
                guard case let .result(result) = result else {
                    return .complete()
                }
                return .single(result)
            }
            |> deliverOnMainQueue)
            .start(next: { peer in
                guard case let .channel(channel) = peer else {
                    continuation.resume(returning: false)
                    return
                }
                
                switch channel.participationStatus {
                case .member:
                    continuation.resume(returning: true)
                case .left, .kicked:
                    continuation.resume(returning: false)
                }
            })
        }
    }
}
