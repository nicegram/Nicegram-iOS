import ChatListUI
import Combine
import class Dispatch.DispatchQueue
import MemberwiseInit
import NGUtils
import SwiftSignalKit
import TelegramBridge
import TelegramCore

@MemberwiseInit
class ChatListPeersProviderImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension ChatListPeersProviderImpl: ChatListPeersProvider {
    func usernamesPublisher(categories: Set<Category>) -> AnyPublisher<[String], Never> {
        let signal = contextProvider.contextSignal()
        |> mapToSignal { context -> Signal<[String], NoError> in
            guard let context else {
                return .single([])
            }
            
            let filterPredicate = chatListFilterPredicate(
                filter: ChatListFilterData(
                    isShared: false,
                    hasSharedLinks: false,
                    categories: categories.toTgCategories(),
                    excludeMuted: false,
                    excludeRead: false,
                    excludeArchived: false,
                    includePeers: .init(),
                    excludePeers: [],
                    color: nil
                ),
                accountPeerId: context.account.peerId
            )
            return context.engine.messages.chatListPeers(
                group: .root,
                filterPredicate: filterPredicate,
                count: 100
            )
            |> map { peers, _ in
                // chatListPeers lists the newest chat first; keep the chat list's own order.
                peers.reversed().compactMap(\.addressName)
            }
        }
        |> distinctUntilChanged
        
        return signal
            .toPublisher()
            .eraseToAnyPublisher()
    }
}

private extension Set<ChatListPeersProvider.Category> {
    func toTgCategories() -> ChatListFilterPeerCategories {
        var result = ChatListFilterPeerCategories(rawValue: 0)
        for category in self {
            switch category {
            case .contacts:
                result.insert(.contacts)
            case .nonContacts:
                result.insert(.nonContacts)
            case .groups:
                result.insert(.groups)
            case .channels:
                result.insert(.channels)
            case .bots:
                result.insert(.bots)
            }
        }
        return result
    }
}
