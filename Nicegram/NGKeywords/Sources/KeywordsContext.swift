import TelegramApi
import TelegramCore
import Combine
import AccountContext
import SwiftSignalKit
import Network
import MtProtoKit
import NGUtils
import NGCore
import NGLogging
import Postbox
import TelegramBridge

public final class KeywordsContext {
    private var disposable: Disposable?
    private let messagesSubject = CurrentValueSubject<[TelegramMessage], Never>([])
    
    private var context: AccountContext?
    private var cancellables = Set<AnyCancellable>()
    private var searchContexts: [SearchContext] = []

    public var messagesPublisher: AnyPublisher<[TelegramMessage], Never> {
        messagesSubject.eraseToAnyPublisher()
    }

    public init(publisher: AnyPublisher<AccountContext?, Never>) {
        publisher.sink { [weak self] accountContext in
            if let accountContext {
                self?.context = accountContext
            }
        }.store(in: &cancellables)
    }
    
    deinit {
        self.disposable?.dispose()
    }
    
    public func searchMessages(from keywords: [String], minDate: Int32? = nil) {
        guard let context,
              !keywords.isEmpty else { return }

        searchContexts = keywords.map {
            let searchContext = SearchContext(context: context)
            searchContext.start(from: $0, minDate: minDate)
            
            return searchContext
        }
        
        _ = combineLatest(searchContexts.map(\.messagesPublisher))
            .start { [weak self] result in
                self?.messagesSubject.send(result.flatMap { $0 })
                sendKeywordsAnalytics(with: .apiPreloadedSuccess)
            }
    }

}

private final class SearchContext {
    private let context: AccountContext
    
    private let searchState = ValuePromise<SearchMessagesState?>(nil)
    private let messagesSubject = ValuePromise<[TelegramMessage]>([])
    
    public var messagesPublisher: Signal<[TelegramMessage], NoError> {
        messagesSubject.get()
    }

    init(context: AccountContext) {
        self.context = context
    }
    
    var searchDisposable: Disposable?

    func start(from keyword: String, minDate: Int32? = nil) {
        let location: SearchMessagesLocation = .general(
            scope: .everywhere,
            tags: nil,
            minDate: minDate,
            maxDate: nil
        )

        let context = self.context
        
        searchDisposable = (searchState.get()
        |> mapToSignal { state in
            context.engine.messages.searchMessages(location: location, query: keyword, state: state)
        }).start(next: { [weak self] (updatedResult, updatedState) in
            if updatedResult.completed {
                self?.messagesSubject.set(
                    updatedResult.messages.compactMap { self?.convert(from: $0, keyword: keyword) }
                )
                self?.searchDisposable?.dispose()
                self?.searchState.set(nil)
            } else {
                self?.searchState.set(updatedState)
            }
        })
    }
    
    private func convert(from message: Message, keyword: String) -> TelegramMessage? {
        guard let author = message.author,
              author.id != context.account.peerId else { return nil }
        
        let username: String? = switch EnginePeer(author) {
        case let .channel(channel): channel.username
        case let .user(user): user.username
        case let .legacyGroup(group): group.title
        default: nil
        }
        
        return TelegramMessage(
            peerId: message.id.peerId.toInt64(),
            messageId: message.id.id,
            timestamp: message.timestamp,
            author: author.addressName ?? username,
            text: message.text,
            keyword: keyword
        )
    }
}
