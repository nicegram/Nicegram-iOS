import AccountContext
import Combine
import MemberwiseInit
import NGUtils
import NicegramWallet
import SwiftSignalKit
import TelegramCore

@MemberwiseInit
class TelegramContactsProviderImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramContactsProviderImpl: TelegramContactsProvider {
    func get() async -> [TgContact] {
        do {
            return try await publisher().awaitForFirstValue()
        } catch {
            return []
        }
    }
    
    func publisher() -> AnyPublisher<[TgContact], Never> {
        let signal = contextProvider.contextSignal()
        |> mapToSignal { context -> Signal<(AccountContext, EngineContactList)?, NoError> in
            guard let context else {
                return Signal.single(nil)
            }
            
            return context.engine.data.subscribe(
                TelegramEngine.EngineData.Item.Contacts.List(includePresences: true)
            )
            |> map { contacts in
                (context, contacts)
            }
        }
        |> map { result -> [TgContact] in
            guard let result else {
                return []
            }
            
            let context = result.0
            let contacts = result.1
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            
            return contacts.peers
                .filter { $0.id != context.account.peerId }
                .map { peer in
                    TgContact(
                        peer: peer,
                        presence: contacts.presences[peer.id],
                        presentationData: presentationData
                    )
                }
                .filter { !$0.name.isEmpty }
        }
        
        return signal
            .toPublisher()
            .eraseToAnyPublisher()
    }
}
