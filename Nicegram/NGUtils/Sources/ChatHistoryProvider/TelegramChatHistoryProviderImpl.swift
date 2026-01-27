import MemberwiseInit
import Postbox
import TelegramApi
import TelegramBridge
import TelegramCore

@MemberwiseInit(.public)
public class TelegramChatHistoryProviderImpl {
    @Init(.public) private let contextProvider: ContextProvider
}

extension TelegramChatHistoryProviderImpl: TelegramChatHistoryProvider {
    public func fetch(
        peer: TelegramPeer,
        pagination: TelegramChatHistoryPagination
    ) async throws -> TelegramChatHistoryPage {
        let messages = try await fetchMessages(peer: peer, pagination: pagination)
        let next = getNextPagination(previous: pagination, messages: messages)
        
        return TelegramChatHistoryPage(
            messages: messages,
            next: next
        )
    }
}

private extension TelegramChatHistoryProviderImpl {
    func fetchMessages(
        peer: TelegramPeer,
        pagination: TelegramChatHistoryPagination
    ) async throws -> [TelegramMessage] {
        let context = try contextProvider.context().unwrap()
        
        let inputPeer = try await peer.toTelegramApiInputPeer(context: context)
        let apiMessages = try await context.account.network
            .request(
                Api.functions.messages.getHistory(
                    peer: inputPeer,
                    offsetId: pagination.offsetId.id,
                    offsetDate: 0,
                    addOffset: 0,
                    limit: Int32(pagination.limit),
                    maxId: 0,
                    minId: 0,
                    hash: 0
                )
            )
            .awaitForFirstValue()
        
        return [TelegramMessage](apiMessages: apiMessages, context: context)
    }
    
    func getNextPagination(
        previous: TelegramChatHistoryPagination,
        messages: [TelegramMessage]
    ) -> TelegramChatHistoryPagination? {
        let oldestMessage = messages.min { $0.timestamp < $1.timestamp }
        if let oldestMessage {
            return TelegramChatHistoryPagination(
                offsetId: oldestMessage.id,
                limit: previous.limit
            )
        } else {
            return nil
        }
    }
}
