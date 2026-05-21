import AccountContext
import Combine
import MemberwiseInit
import NGUtils
import NicegramWallet
import Postbox
import SwiftSignalKit
import TelegramCore

@MemberwiseInit
class TelegramContactsProviderImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramContactsProviderImpl: TelegramContactsProvider {
    func get(_ params: Params) async -> Contacts? {
        do {
            return try await publisher(params).awaitForFirstValue()
        } catch {
            return nil
        }
    }
    
    func publisher(_ params: Params) -> AnyPublisher<Contacts?, Never> {
        let signal = contextProvider.contextSignal()
        |> mapToSignal { context -> Signal<(AccountContext, EngineContactList)?, NoError> in
            guard let context else {
                return .single(nil)
            }
            
            if let userId = params.userId,
               context.account.peerId != PeerId(userId) {
                return .single(nil)
            }
            
            return context.engine.data.subscribe(
                TelegramEngine.EngineData.Item.Contacts.List(includePresences: true)
            )
            |> map { contacts in
                (context, contacts)
            }
        }
        |> map { result -> Contacts? in
            guard let result else {
                return nil
            }
            
            let context = result.0
            let contacts = result.1
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            
            let contactList = contacts.peers
                .filter { $0.id != context.account.peerId }
                .map { peer in
                    TgContact(
                        peer: peer,
                        presence: contacts.presences[peer.id],
                        presentationData: presentationData
                    )
                }
                .filter { !$0.name.isEmpty }
            return Contacts(contacts: contactList)
        }
        
        return signal
            .toPublisher()
            .eraseToAnyPublisher()
    }
}
