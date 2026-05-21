import Foundation
import Postbox
import TelegramApi
import SwiftSignalKit

public final class SpyOnFriendsContext {
    private let queue: Queue = .mainQueue()
    private let impl: QueueLocalObject<SpyOnFriendsContextImpl>
    
    public var state: Signal<SpyOnFriendsState, NoError> {
        return Signal { subscriber in
            let disposable = MetaDisposable()
            
            self.impl.with { impl in
                disposable.set(impl.state.start(next: { value in
                    subscriber.putNext(value)
                }))
            }
            
            return disposable
        }
    }
    
    public init(
        account: Account,
        engine: TelegramEngine,
        peerId: PeerId,
        lastUpdatedDate: @escaping () -> Date?
    ) {
        let queue = self.queue
        self.impl = QueueLocalObject(queue: queue,
                                     generate: {
            SpyOnFriendsContextImpl(
                queue: queue,
                account: account,
                engine: engine,
                peerId: peerId,
                lastUpdatedDate: lastUpdatedDate
            )
        })
    }
    
    public func load() {
        self.impl.with { impl in
            impl.loadCommon()
        }
    }
}

public enum SpyOnFriendsDataState: Equatable {
    case loading
    case ready(canLoadMore: Bool)
}

public struct SpyOnFriendsState: Equatable {
    public static func == (lhs: SpyOnFriendsState, rhs: SpyOnFriendsState) -> Bool {
        lhs.chatsWithMessages.first?.0?.peerId == rhs.chatsWithMessages.first?.0?.peerId
    }
    
    public var chatsWithMessages: [(Api.Chat?, [Message])]
    public var dataState: SpyOnFriendsDataState
}

private final class SpyOnFriendsContextImpl {
    private let queue: Queue
    private let account: Account
    private let engine: TelegramEngine
    private let peerId: PeerId
    private let lastUpdatedDate: () -> Date?
    
    private let disposable = MetaDisposable()
    private let limit: Int32 = 100
    private let loadMore = Promise<Void>()

    private var commonChats: [Api.Chat] = []
    private var chatsWithMessages: [(Api.Chat?, [Message])] = []
    private var dataState: SpyOnFriendsDataState = .ready(canLoadMore: true)
    
    private let stateValue = Promise<SpyOnFriendsState>()
    var state: Signal<SpyOnFriendsState, NoError> {
        return self.stateValue.get()
    }
    
    init(
        queue: Queue,
        account: Account,
        engine: TelegramEngine,
        peerId: PeerId,
        lastUpdatedDate: @escaping () -> Date?
    ) {
        self.queue = queue
        self.account = account
        self.engine = engine
        self.peerId = peerId
        self.lastUpdatedDate = lastUpdatedDate
        
        loadMore.set(.single(Void()))
        loadCommon()
    }
    
    deinit {
        self.disposable.dispose()
    }
    
    func loadCommon() {
        if case .ready(true) = self.dataState {
            self.dataState = .loading
            self.pushState()
                        
            let peerId = self.peerId
            
            let network = self.account.network
            let postbox = self.account.postbox

            let signal = combineLatest(loadMore.get(), postbox.transaction { transaction -> Api.InputUser? in
                return transaction.getPeer(peerId).flatMap(apiInputUser)
            })
            |> mapToSignal { [weak self] result -> Signal<Api.messages.Chats?, NoError> in
                guard let self,
                      let inputUser = result.1 else {
                    return .single(nil)
                }
                
                if peerId == self.account.peerId {
                    switch inputUser {
                    case let .inputUser(_, accessHash):
                        return fetchChatList(
                            accountPeerId: peerId,
                            postbox: account.postbox,
                            network: account.network,
                            location: .general,
                            upperBound: .absoluteUpperBound(),
                            hash: accessHash,
                            limit: self.limit
                        )
                        |> map { result in
                            Api.messages.Chats.chats(chats: result?.peers.chats.map { $0.value } ?? [])
                        }
                    default:
                        return .single(nil)
                    }
                } else {
                    let maxId = self.commonChats.last?.peerId.id
                    
                    return network.request(Api.functions.messages.getCommonChats(
                        userId: inputUser,
                        maxId: maxId?._internalGetInt64Value() ?? 0,
                        limit: self.limit
                    ))
                    |> map(Optional.init)
                    |> `catch` { _ -> Signal<Api.messages.Chats?, NoError> in
                        return .single(nil)
                    }
                }
            }

            self.disposable.set((signal
            |> deliverOn(self.queue)).start(next: { [weak self] result in
                guard let self else { return }
                
                if let result {
                    var resultChats: [Api.Chat]
                    switch result {
                    case let .chats(chats):
                        resultChats = chats
                    case let .chatsSlice(_, chats):
                        resultChats = chats
                    }
                    self.commonChats.append(contentsOf: resultChats)

                    if resultChats.count == self.limit {
                        self.loadMore.set(.single(Void()))
                    } else {
                        if self.lastUpdatedDate() == nil {
                            self.dataState = .ready(canLoadMore: true)
                            self.pushState()
                        } else {
                            self.loadMessages()
                        }
                    }
                } else {
                    self.dataState = .ready(canLoadMore: true)
                    self.pushState()
                }
            }))
        }
    }
    
    private func loadMessages() {
        let peerId = self.peerId
        let signal = combineLatest(
            commonChats.map { chat -> Signal<(Api.Chat?, [Message]), NoError> in
                let location = SearchMessagesLocation.peer(
                    peerId: chat.peerId,
                    fromId: peerId,
                    tags: nil,
                    reactions: nil,
                    threadId: nil,
                    minDate: nil,
                    maxDate: nil
                )
                
                return self.engine.messages.searchMessages(
                    location: location,
                    query: "",
                    state: nil,
                    limit: 15
                )
                |> map {
                    (chat, $0.0.messages)
                }
                |> timeout(1.0, queue: .mainQueue(), alternate: .single((nil, [])))
            }
        )
        
        self.disposable.set((signal
        |> deliverOn(self.queue)).start(next: { [weak self] results in
            guard let self else { return }

            self.chatsWithMessages = results

            self.dataState = .ready(canLoadMore: true)
            self.pushState()
        }))
    }
    
    private func pushState() {
        stateValue.set(.single(SpyOnFriendsState(
            chatsWithMessages: chatsWithMessages,
            dataState: dataState
        )))
    }
}

public extension Api.Chat {
    var title: String? {
        switch self {
        case let .channel(_, _, _, _, title, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _):
            return title
        case let .chat(_, _, title, _, _, _, _, _, _, _):
            return title
        default: return nil
        }
    }
}

extension Message: @retroactive Equatable {
    public static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}

extension Api.Chat: @retroactive Hashable {
    public static func == (lhs: Api.Chat, rhs: Api.Chat) -> Bool {
        lhs.peerId == rhs.peerId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(peerId)
        hasher.combine(title)
    }
}
