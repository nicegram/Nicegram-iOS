import Postbox
import SwiftSignalKit

// The only way Nicegram code outside TelegramCore reaches Postbox, for the few reads and writes
// TelegramEngine has no member for. Upstream is moving every module but TelegramCore off Postbox, and
// from 13.1.1 build-system/Make/PostboxImportCheck.py refuses new importers; our code stays off it
// entirely. Members take and return engine types, never Postbox, a transaction or the media box.
// Writes change the local copy alone: nothing is sent to the server.
public enum TelegramRawPostbox {}

// MARK: - Messages

public extension TelegramRawPostbox {
    static func messages(
        peerId: EnginePeer.Id,
        namespace: EngineMessage.Id.Namespace,
        from: EngineMessage.Index,
        to: EngineMessage.Index,
        limit: Int,
        engine: TelegramEngine
    ) -> Signal<[EngineMessage], NoError> {
        engine.account.postbox.transaction { transaction in
            transaction.getMessages(
                peerId: peerId,
                namespace: namespace,
                from: from,
                includeFrom: false,
                to: to,
                limit: limit
            )
            .map(EngineMessage.init)
        }
    }

    static func updateMessage(
        _ id: EngineMessage.Id,
        engine: TelegramEngine,
        update: @escaping (_ text: String, _ attributes: [EngineMessage.Attribute]) -> (text: String, attributes: [EngineMessage.Attribute])
    ) -> Signal<Void, NoError> {
        engine.account.postbox.transaction { transaction in
            transaction.updateMessage(id) { currentMessage in
                let (text, attributes) = update(
                    currentMessage.text,
                    currentMessage.attributes
                )
                return .update(StoreMessage(
                    id: currentMessage.id,
                    customStableId: nil,
                    globallyUniqueId: currentMessage.globallyUniqueId,
                    groupingKey: currentMessage.groupingKey,
                    threadId: currentMessage.threadId,
                    timestamp: currentMessage.timestamp,
                    flags: StoreMessageFlags(currentMessage.flags),
                    tags: currentMessage.tags,
                    globalTags: currentMessage.globalTags,
                    localTags: currentMessage.localTags,
                    forwardInfo: currentMessage.forwardInfo.flatMap(StoreMessageForwardInfo.init),
                    authorId: currentMessage.author?.id,
                    text: text,
                    attributes: attributes,
                    media: currentMessage.media
                ))
            }
        }
    }
}
