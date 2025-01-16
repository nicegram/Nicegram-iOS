import MemberwiseInit
import NGCore
import Postbox
import SwiftSignalKit
import TelegramCore
import TelegramBridge
import TelegramCore
import NGUtils
import NGLab
import UIKit
import AccountContext
import AvatarNode
import FeatPersonality

public final class PersonalityProviderImpl {
    private let contextProvider: ContextProvider
    
    public init(contextProvider: ContextProvider) {
        self.contextProvider = contextProvider
    }
}

extension PersonalityProviderImpl: PersonalityProvider {
    public func loadInformation() async -> PersonalityInformation {
        do {
            let context = try contextProvider.context().unwrap()
            
            let result = try await loadUserInformation(with: context).awaitForFirstValue()
            
            return PersonalityInformation(
                id: result.0,
                displayName: result.1,
                avatar: result.2,
                daysFromCreation: result.3
            )
        } catch {
            return PersonalityInformation(id: 0)
        }
    }
    
    public func collect(with id: Int64) async {
        do {
            let context = try contextProvider.context().unwrap()

            try await context.account.postbox.transaction { transaction in
                let contactPeerIds = transaction.getContactPeerIds()
                
                collectContactsActivity(with: id, count: contactPeerIds.count)
            }.awaitForFirstValue()

            await collectDailyActivity(
                with: id,
                notificationName: UIApplication.didBecomeActiveNotification
            )
            await collectGhostScore(with: context)
            await collectInfluencerScore(with: context)
            await collectMessagesActivity(with: context)
        } catch {}
    }
}

private extension PersonalityProviderImpl {
    func loadUserInformation(with context: AccountContext) -> Signal<(Int64, String?, UIImage?, Int?), NoError> {
        return context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.Peer(id: context.account.peerId))
        |> mapToSignal { peer -> Signal<(Int64, String?, UIImage?, Int?), NoError> in
            if case let .user(user) = peer {
                return peerAvatarCompleteImage(
                    account: context.account,
                    peer: EnginePeer(user),
                    forceProvidedRepresentation: false,
                    representation: nil,
                    size: CGSize(width: 50, height: 50)
                )
                |> mapToSignal { image -> Signal<(Int64, String?, UIImage?, Int?), NoError> in
                    getDaysFromRegDate(with: user.id.toInt64())
                    |> map { days -> (Int64, String?, UIImage?, Int?) in
                        var displayName = user.username
                        let firstName = user.firstName
                        let lastName = user.lastName
                        
                        if let firstName,
                           let lastName,
                           !firstName.isEmpty &&
                           !lastName.isEmpty {
                            displayName = "\(firstName) \(lastName)"
                        } else if let firstName,
                                  !firstName.isEmpty {
                            displayName = firstName
                        }

                        return (user.id.toInt64() , displayName?.capitalized, image, days)
                    }
                }
            }
            
            return .single((0, nil, nil, nil))
        }
    }
}
