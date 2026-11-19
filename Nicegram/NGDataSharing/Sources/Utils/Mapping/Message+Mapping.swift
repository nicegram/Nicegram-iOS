import FeatDataSharing
import NGUtils
import TelegramApi
import TelegramCore

//  MARK: - Local

extension FeatDataSharing.Message {
    /// Nil for a service message (a join, a pin) and for one not on the server yet (being sent, or failed to send):
    /// neither is a post, and the local id of an unsent one could collide with a real post's id.
    init?(_ message: EngineRawMessage) {
        guard message.id.namespace == Namespaces.Message.Cloud,
              !message.media.contains(where: { $0 is TelegramMediaAction }) else {
            return nil
        }

        let forwardCountAttr = message.getAttribute(ForwardCountMessageAttribute.self)
        let reactionsAttr = message.getAttribute(ReactionsMessageAttribute.self)
        let replyThreadAttr = message.getAttribute(ReplyThreadMessageAttribute.self)
        let viewCountAttr = message.getAttribute(ViewCountMessageAttribute.self)
        
        self.init(
            commentsCount: replyThreadAttr?.count ?? 0,
            date: message.timestamp,
            forwardsCount: forwardCountAttr.map { Int32(clamping: $0.count) },
            fwdFrom: .init(message.forwardInfo),
            groupedId: message.groupingKey,
            id: message.id.id,
            media: .init(message.media.first),
            message: message.text,
            peerId: message.id.peerId.id._internalGetInt64Value(),
            reactions: .init(reactionsAttr),
            viewsCount: viewCountAttr?.count
        )
    }
}

extension FeatDataSharing.Message.FwdFrom {
    init?(_ info: EngineMessage.ForwardInfo?) {
        guard let info,
              let source = info.sourceMessageId,
              source.peerId.namespace == Namespaces.Peer.CloudChannel else {
            return nil
        }
        
        self.init(
            chatId: source.peerId.ng_toInt64(),
            date: info.date,
            messageId: source.id
        )
    }
}

private extension EngineRawMessage {
    func getAttribute<T: EngineMessage.Attribute>(_ type: T.Type) -> T? {
        for attribute in self.attributes {
            if let attribute = attribute as? T {
                return attribute
            }
        }
        return nil
    }
}

//  MARK: - Api

extension FeatDataSharing.Message {
    init?(_ message: Api.Message) {
        do {
            let message = try message.message.unwrap()
            
            let commentsCount: Int32
            switch message.replies {
            case let .messageReplies(messageReplies):
                commentsCount = messageReplies.replies
            case nil:
                commentsCount = 0
            }
            
            self.init(
                commentsCount: commentsCount,
                date: message.date,
                forwardsCount: message.forwards,
                fwdFrom: .init(message.fwdFrom),
                groupedId: message.groupedId,
                id: message.id,
                media: .init(message.media),
                message: message.message,
                peerId: message.peerId.id,
                reactions: .init(message.reactions),
                viewsCount: message.views.flatMap(Int.init)
            )
        } catch {
            return nil
        }
    }
}

extension FeatDataSharing.Message.FwdFrom {
    init?(_ fwdHeader: Api.MessageFwdHeader?) {
        guard case let .messageFwdHeader(header) = fwdHeader,
              case let .peerChannel(peerChannel) = header.fromId,
              let channelPost = header.channelPost else {
            return nil
        }
        
        let channelId = EnginePeer.Id(
            namespace: Namespaces.Peer.CloudChannel,
            id: ._internalFromInt64Value(peerChannel.channelId)
        )
        self.init(
            chatId: channelId.ng_toInt64(),
            date: header.date,
            messageId: channelPost
        )
    }
}

extension [FeatDataSharing.Message] {
    init(messages: [Api.Message]) {
        self = messages.compactMap { .init($0) }
    }
}
