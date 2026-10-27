import Foundation
import MemberwiseInit
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
        let id = EngineMessage.Id(messageId)
        
        let message = try await context.engine.data
            .get(TelegramEngine.EngineData.Item.Messages.Message(id: id))
            .awaitForFirstValue()
        
        return message.map { TelegramMessage($0._asMessage()) }
    }
    
    func fetchFromRemote(
        messageId: TelegramMessageId,
        timeout timeoutValue: TimeInterval?
    ) async throws -> TelegramMessage? {
        let context = try contextProvider.context().unwrap()
        let id = EngineMessage.Id(messageId)
        
        let peer = try await context.engine.data
            .get(TelegramEngine.EngineData.Item.Peer.Peer(id: id.peerId))
            .awaitForFirstValue()
            .unwrap()
        let inputPeer = try TelegramRawApi.inputPeer(peer._asPeer()).unwrap()
        
        let apiMessagesSignal = switch inputPeer {
        case let .inputPeerChannel(data):
            TelegramRawApi.request(
                Api.functions.channels.getMessages(
                    channel: .inputChannel(.init(channelId: data.channelId, accessHash: data.accessHash)),
                    id: [.inputMessageID(.init(id: id.id))]
                ),
                network: context.account.network
            )
        default:
            TelegramRawApi.request(
                Api.functions.messages.getMessages(
                    id: [.inputMessageID(.init(id: id.id))]
                ),
                network: context.account.network
            )
        }
        
        let signal = apiMessagesSignal
            |> timeout(timeoutValue, queue: Queue.concurrentDefaultQueue(), alternate: .complete())
        let apiMessages = try await signal.awaitForFirstValue()
        
        return [TelegramMessage](apiMessages: apiMessages, context: context)
            .first { $0.id == messageId }
    }
}
