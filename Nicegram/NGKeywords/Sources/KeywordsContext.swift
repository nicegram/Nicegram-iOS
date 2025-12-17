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
    private let queue = Queue(name: "keywords_context")
    private let updateServiceDisposable = MetaDisposable()
    private let internalUpdateMessages = PassthroughSubject<[TelegramMessage], Never>()
    
    private var context: AccountContext?
    private var updateService: UpdateMessageService?
    private var cancellables = Set<AnyCancellable>()
    private var keywordContexts: [String: KeywordContext] = [:]

    public var messages: AnyPublisher<[TelegramMessage], Never> {
        Publishers.MergeMany(keywordContexts.map(\.value.messages)).eraseToAnyPublisher()
    }
    public var updateMessages: AnyPublisher<[TelegramMessage], Never> {
        internalUpdateMessages.eraseToAnyPublisher()
    }

    public init(publisher: AnyPublisher<AccountContext?, Never>) {
        publisher.sink { [weak self] accountContext in
            if let self, let accountContext {
                self.context = accountContext
                self.startUpdate(with: accountContext)
            }
        }.store(in: &cancellables)
    }
    
    deinit {
        keywordContexts.forEach { $0.value.stop() }
        keywordContexts.removeAll()
        updateServiceDisposable.dispose()
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
    
    private func startUpdate(with accountContext: AccountContext) {
        self.queue.async {
            if self.updateService == nil {
                self.updateService = UpdateMessageService(peerId: accountContext.account.peerId)

                if let updateService = self.updateService {
                    self.updateServiceDisposable.set(
                        self.updateService!.pipe.signal()
                            .start(next: { [weak self] messages in
                                if let self {
                                    let convertedMessages = messages.compactMap {
                                        switch $0 {
                                        case let .message(_, _, id, _, _, peerId, _, _, _, _, _, date, message, _, _, _, _, _, _, _, postAuthor, _, _, _, _, _, _, _, _, _, _, _):
                                            
                                            let peerId: Int64 = switch peerId {
                                            case let .peerChannel(channelId): channelId
                                            case let .peerChat(chatId): chatId
                                            case let .peerUser(userId): userId
                                            }                            
                                            
                                            if peerId != accountContext.account.peerId.toInt64() {
                                                return TelegramMessage(
                                                    peerId: peerId,
                                                    messageId: id,
                                                    timestamp: date,
                                                    author: postAuthor,
                                                    text: message,
                                                    keywordId: ""
                                                )
                                            } else {
                                                return nil
                                            }
                                        default: return nil
                                        }
                                    }
                                    
                                    internalUpdateMessages.send(convertedMessages)
                            }
                        })
                    )
                    accountContext.account.network.addMessageService(with: updateService)
                }
            }
        }
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
            guard let self else { return }
            
            self.internalMessages.send(
                updatedResult.messages.compactMap { self.convert(from: $0, keywordId: id) }
            )            
        }
    }
    
    func stop() {
        searchDisposable?.dispose()
    }
    
    private func convert(from message: Message, keywordId: String) -> TelegramMessage? {
        guard let author = message.author,
              author.id != context.account.peerId else { return nil }
        
        var text = message.text
        if text.isEmpty {
            if let _ = message.media.first(where: { $0 is TelegramMediaImage }) {
                text = "Image"
            }
            if let _ = message.media.first(where: { $0 is TelegramMediaFile }) {
                text = "Video"
            }
        }
        
        return TelegramMessage(
            peerId: message.id.peerId.toInt64(),
            messageId: message.id.id,
            timestamp: message.timestamp,
            author: author.authorName,
            text: text,
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

private class UpdateMessageService: NSObject, MTMessageService {
    var peerId: PeerId!
    var mtProto: MTProto?
    let pipe: ValuePipe<[Api.Message]> = ValuePipe()
    
    override init() {
        super.init()
    }
    
    convenience init(peerId: PeerId) {
        self.init()
        self.peerId = peerId
    }
    
    func mtProtoWillAdd(_ mtProto: MTProto!) {
        self.mtProto = mtProto
    }
    
    func mtProto(
        _ mtProto: MTProto!,
        receivedMessage message: MTIncomingMessage!,
        authInfoSelector: MTDatacenterAuthInfoSelector,
        networkType: Int32
    ) {
        if let updates = (message.body as? BoxedMessage)?.body as? Api.Updates {
            self.addUpdates(updates)
        }
    }
    
    func addUpdates(_ updates: Api.Updates) {
        switch updates {
        case let .updates(updates, _, _, _, _):
            let messages = updates.compactMap { update in
                switch update {
                case let .updateNewChannelMessage(message, _, _):
                    return message
                default: return nil
                }
            }
            if messages.count > 0 {
                pipe.putNext(messages)
            }
        case let .updateShort(update, _):
            switch update {
            case let .updateNewChannelMessage(message, _, _):
                pipe.putNext([message])
            default: break
            }

        case let .updatesCombined(updates, _, _, _, _, _):
            let messages = updates.compactMap { update in
                switch update {
                case let .updateNewChannelMessage(message, _, _):
                    return message
                default: return nil
                }
            }
            pipe.putNext(messages)
        default: break
        }
    }
}
