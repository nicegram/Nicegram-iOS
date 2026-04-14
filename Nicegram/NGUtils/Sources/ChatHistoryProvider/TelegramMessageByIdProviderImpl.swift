import Foundation
import MemberwiseInit
import Postbox
import SwiftSignalKit
import TelegramApi
import TelegramBridge
import TelegramCore

@MemberwiseInit(.public)
public class TelegramMessageByIdProviderImpl {
    @Init(.public) private let contextProvider: ContextProvider
}

extension TelegramMessageByIdProviderImpl: TelegramMessageByIdProvider {
    public func fetch(
        messageId: TelegramMessageId,
        source: TelegramChatHistorySource,
        timeout: TimeInterval?
    ) async throws -> TelegramMessage? {
        switch source {
        case .local:
            try await fetchFromLocal(messageId: messageId)
        case .remote:
            try await fetchFromRemote(messageId: messageId, timeout: timeout)
        }
    }
}

private extension TelegramMessageByIdProviderImpl {
    func fetchFromLocal(
        messageId: TelegramMessageId
    ) async throws -> TelegramMessage? {
        let context = try contextProvider.context().unwrap()
        let id = MessageId(messageId)
        
        let message = try await context.account.postbox
            .messageAtId(id)
            .awaitForFirstValue()
        
        return message.map { TelegramMessage($0) }
    }
    
    func fetchFromRemote(
        messageId: TelegramMessageId,
        timeout timeoutValue: TimeInterval?
    ) async throws -> TelegramMessage? {
        let context = try contextProvider.context().unwrap()
        let id = MessageId(messageId)
        
        let inputPeer = try await context.account.postbox
            .transaction { transaction -> Api.InputPeer? in
                guard let peer = transaction.getPeer(id.peerId) else { return nil }
                return apiInputPeer(peer)
            }
            .awaitForFirstValue()
            .unwrap()
        
        let apiMessagesSignal = switch inputPeer {
        case let .inputPeerChannel(data):
            context.account.network.request(
                Api.functions.channels.getMessages(
                    channel: .inputChannel(.init(channelId: data.channelId, accessHash: data.accessHash)),
                    id: [.inputMessageID(.init(id: id.id))]
                )
            )
        default:
            context.account.network.request(
                Api.functions.messages.getMessages(
                    id: [.inputMessageID(.init(id: id.id))]
                )
            )
        }
        
        let signal = apiMessagesSignal
            |> timeout(timeoutValue, queue: Queue.concurrentDefaultQueue(), alternate: .complete())
        let apiMessages = try await signal.awaitForFirstValue()
        
        return [TelegramMessage](apiMessages: apiMessages, context: context)
            .first { $0.id == messageId }
    }
}
