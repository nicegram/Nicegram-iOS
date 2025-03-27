import ChatListUI
import Combine
import class Dispatch.DispatchQueue
import MemberwiseInit
import NGUtils
import TelegramBridge
import TelegramCore

@MemberwiseInit
class ChatListPeersProviderImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension ChatListPeersProviderImpl: ChatListPeersProvider {
    func usernamesPublisher(categories: Set<Category>) -> AnyPublisher<[String], Never> {
        contextProvider.contextPublisher()
            .map { context -> AnyPublisher<[String], Never> in
                guard let context else {
                    return Just([]).eraseToAnyPublisher()
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
                return context.account.postbox
                    .tailChatListView(
                        groupId: .root,
                        filterPredicate: filterPredicate,
                        count: 100,
                        summaryComponents: .init(components: [:])
                    )
                    .toPublisher()
                    .map { chatListView, _ in
                        chatListView.entries.compactMap { entry in
                            if case let .MessageEntry(messageEntry) = entry {
                                messageEntry.renderedPeer.peer?.addressName
                            } else {
                                nil
                            }
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatestThreadSafe()
            .removeDuplicates()
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

private extension Publisher
where Self.Failure == Never, Self.Output : Publisher, Self.Output.Failure == Never {
    func switchToLatestThreadSafe() -> AnyPublisher<Self.Output.Output, Never> {
        let queue = DispatchQueue(label: "")
        
        return self
            .map { publisher in
                publisher.receive(on: queue)
            }
            .receive(on: queue)
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
