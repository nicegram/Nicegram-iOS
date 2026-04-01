import Foundation
import MemberwiseInit
import Postbox
import SwiftSignalKit
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
        pagination: TelegramChatHistoryPagination,
        source: TelegramChatHistorySource,
        timeout: TimeInterval?
    ) async throws -> TelegramChatHistoryPage {
        let messages = try await fetchMessagesFromSource(
            peer: peer,
            pagination: pagination,
            source: source,
            timeout: timeout
        )
        let next = getNextPagination(
            previous: pagination,
            messages: messages
        )
        
        return TelegramChatHistoryPage(
            messages: messages,
            next: next
        )
    }
}

private extension TelegramChatHistoryProviderImpl {
    func fetchMessagesFromSource(
        peer: TelegramPeer,
        pagination: TelegramChatHistoryPagination,
        source: TelegramChatHistorySource,
        timeout timeoutValue: TimeInterval?
    ) async throws -> [TelegramMessage] {
        switch source {
        case .local:
            try await fetchMessagesFromLocal(
                peer: peer,
                pagination: pagination
            )
        case .remote:
            try await fetchMessagesFromRemote(
                peer: peer,
                pagination: pagination,
                timeout: timeoutValue
            )
        }
    }
    
    func fetchMessagesFromLocal(
        peer: TelegramPeer,
        pagination: TelegramChatHistoryPagination
    ) async throws -> [TelegramMessage] {
        let context = try contextProvider.context().unwrap()
        
        let peerId = PeerId(peer.id)
        let namespace = Namespaces.Message.Cloud
        
        let from: MessageIndex
        if let olderThan = pagination.olderThan {
            from = MessageIndex(olderThan)
        } else {
            from = .upperBound(peerId: peerId, namespace: namespace)
        }
        
        let messages = try await context.account.postbox
            .transaction { transaction in
                transaction.getMessages(
                    peerId: peerId,
                    namespace: namespace,
                    from: from,
                    to: .lowerBound(peerId: peerId, namespace: namespace),
                    limit: pagination.limit
                )
            }
            .awaitForFirstValue()
        return [TelegramMessage](messages)
    }
    
    func fetchMessagesFromRemote(
        peer: TelegramPeer,
        pagination: TelegramChatHistoryPagination,
        timeout timeoutValue: TimeInterval?
    ) async throws -> [TelegramMessage] {
        let context = try contextProvider.context().unwrap()
        
        let inputPeer = try await peer.toTelegramApiInputPeer(context: context)
        let apiMessagesSignal = context.account.network.request(
            Api.functions.messages.getHistory(
                peer: inputPeer,
                offsetId: pagination.olderThan?.id.id ?? 0,
                offsetDate: 0,
                addOffset: 0,
                limit: Int32(pagination.limit),
                maxId: 0,
                minId: 0,
                hash: 0
            )
        )
        |> timeout(timeoutValue, queue: Queue.concurrentDefaultQueue(), alternate: .complete())
        let apiMessages = try await apiMessagesSignal.awaitForFirstValue()
        
        return [TelegramMessage](apiMessages: apiMessages, context: context)
    }
    
    func getNextPagination(
        previous: TelegramChatHistoryPagination,
        messages: [TelegramMessage]
    ) -> TelegramChatHistoryPagination? {
        let oldestMessage = messages.min { $0.timestamp < $1.timestamp }
        if let oldestMessage {
            return TelegramChatHistoryPagination(
                olderThan: oldestMessage.index,
                limit: previous.limit
            )
        } else {
            return nil
        }
    }
}
