import Combine
import MemberwiseInit
import NGUtils
import TelegramBridge
import NGKeywords

final class TelegramMessagesProviderImpl {
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
