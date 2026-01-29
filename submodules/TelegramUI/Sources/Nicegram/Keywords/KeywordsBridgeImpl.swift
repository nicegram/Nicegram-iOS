import Combine
import FeatKeywords
import MemberwiseInit
import NGKeywords
import NGUtils

@MemberwiseInit
class KeywordsBridgeImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension KeywordsBridgeImpl: KeywordsBridge {
    func telegramMessagesProvider() -> TelegramMessagesProvider {
        TelegramMessagesProviderImpl(contextProvider: contextProvider)
    }
}

//  MARK: - TelegramMessagesProviderImpl

private final class TelegramMessagesProviderImpl {
    private let keywordsContext: KeywordsContext
    
    init(contextProvider: ContextProvider) {
        self.keywordsContext = KeywordsContext(publisher: contextProvider.contextPublisher())
    }
}

extension TelegramMessagesProviderImpl: TelegramMessagesProvider {
    var messages: AnyPublisher<[TelegramMessage], Never> {
        keywordsContext.messages
    }
    
    var updateMessages: AnyPublisher<[TelegramMessage], Never> {
        keywordsContext.updateMessages
    }

    func startSearchMessages(with id: String, keywords: [String], minDate: Int32?) {
        keywordsContext.start(with: id, keywords: keywords, minDate: minDate)
    }
    
    func stopSearchMessages(with id: String) {
        keywordsContext.stop(with: id)
    }
}
