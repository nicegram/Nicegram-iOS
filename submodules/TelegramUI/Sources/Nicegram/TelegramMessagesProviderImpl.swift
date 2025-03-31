import Combine
import MemberwiseInit
import NGUtils
import TelegramBridge
import NGKeywords

final class TelegramMessagesProviderImpl {
    private let folderForKeywordsContext: KeywordsContext
    
    init(contextProvider: ContextProvider) {
        self.folderForKeywordsContext = KeywordsContext(publisher: contextProvider.contextPublisher())
    }
}

extension TelegramMessagesProviderImpl: TelegramMessagesProvider {
    var messages: AnyPublisher<[TelegramMessage], Never> {
        folderForKeywordsContext.messagesPublisher
    }

    func searchMessages(for keywords: [String], minDate: Int32? = nil) {
        folderForKeywordsContext.searchMessages(from: keywords, minDate: minDate)
    }
}
