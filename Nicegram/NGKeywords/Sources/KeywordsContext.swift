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
    private var context: AccountContext?
    private var cancellables = Set<AnyCancellable>()
    private var keywordContexts: [String: KeywordContext] = [:]

    public var messages: AnyPublisher<[TelegramMessage], Never> {
        Publishers.MergeMany(keywordContexts.map(\.value.messages)).eraseToAnyPublisher()
    }

    public init(publisher: AnyPublisher<AccountContext?, Never>) {
        publisher.sink { [weak self] accountContext in
            if let accountContext {
                self?.context = accountContext
            }
        }.store(in: &cancellables)
    }
    
    deinit {
        keywordContexts.forEach { $0.value.stop() }
        keywordContexts.removeAll()
    }
    
    public func start(
        with id: String,
        keywords: [String],
        minDate: Int32? = nil
    ) {
        guard let context else { return }

        let keywordContext = KeywordContext(context: context)
        keywordContext.start(with: id, keywords: keywords, minDate: minDate)
        
        keywordContexts[id] = keywordContext
    }

    public func stop(with id: String) {
        let context = keywordContexts[id]
        context?.stop()
        keywordContexts.removeValue(forKey: id)
    }
}

final class KeywordContext {
    private let context: AccountContext

    private var searchContexts: [SearchContext] = []
    
    public var messages: AnyPublisher<[TelegramMessage], Never> {
        Publishers.MergeMany(searchContexts.map(\.messages)).eraseToAnyPublisher()
    }

    init(context: AccountContext) {
        self.context = context
    }
    
    deinit {
        stop()
    }
    
    public func start(
        with id: String,
        keywords: [String],
        minDate: Int32? = nil
    ) {
        guard !keywords.isEmpty else { return }

        
        searchContexts = keywords.map {
            let searchContext = SearchContext(context: context)
            searchContext.start(with: id, keyword: $0, minDate: minDate)
            
            return searchContext
        }
    }
    
    public func stop() {
        searchContexts.forEach { $0.stop() }
        searchContexts.removeAll()
    }
}

private final class SearchContext {
    private let context: AccountContext
    private let internalMessages = PassthroughSubject<[TelegramMessage], Never>()
    
    private var searchDisposable: Disposable?

    public var messages: AnyPublisher<[TelegramMessage], Never> {
        internalMessages.eraseToAnyPublisher()
    }

    init(context: AccountContext) {
        self.context = context
    }

    deinit {
        searchDisposable?.dispose()
    }
    
    func start(with id: String, keyword: String, minDate: Int32? = nil) {
        let location: SearchMessagesLocation = .general(
            scope: .everywhere,
            tags: nil,
            minDate: minDate,
            maxDate: nil
        )

        let context = self.context
        
        searchDisposable = context.engine.messages.searchMessages(
            location: location,
            query: keyword.lowercased(),
            state: nil,
            limit: 20
        )
        .start { [weak self] (updatedResult, updatedState) in
            self?.internalMessages.send(
                updatedResult.messages.compactMap { self?.convert(from: $0, keywordId: id) }
            )            
        }
    }
    
    func stop() {
        searchDisposable?.dispose()
    }
    
    private func convert(from message: Message, keywordId: String) -> TelegramMessage? {
        guard let author = message.author,
              author.id != context.account.peerId else { return nil }
        
        return TelegramMessage(
            peerId: message.id.peerId.toInt64(),
            messageId: message.id.id,
            timestamp: message.timestamp,
            author: author.authorName,
            text: message.text,
            keywordId: keywordId
        )
    }
}

private extension Peer {
    var authorName: String? {
        switch self {
        case let user as TelegramUser:
            return user.firstName ?? user.username
        case let group as TelegramGroup:
            return group.title
        case let channel as TelegramChannel:
            return channel.username ?? channel.title
        default:
            return nil
        }
    }
}
