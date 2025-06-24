import FeatDataSharing
import TelegramApi
import class Postbox.Message
import protocol Postbox.MessageAttribute
import TelegramCore

//  MARK: - Local

extension FeatDataSharing.Message {
    init(_ message: Postbox.Message) {
        let reactionsAttr = message.getAttribute(ReactionsMessageAttribute.self)
        let replyThreadAttr = message.getAttribute(ReplyThreadMessageAttribute.self)
        let viewCountAttr = message.getAttribute(ViewCountMessageAttribute.self)
        
        self.init(
            author: .init(message.author),
            commentsCount: replyThreadAttr?.count ?? 0,
            date: message.timestamp,
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

private extension Postbox.Message {
    func getAttribute<T: MessageAttribute>(_ type: T.Type) -> T? {
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
    init?(
        message: Api.Message,
        chats: [Api.Chat],
        users: [Api.User]
    ) {
        do {
            let message = try message.wrapped().message.unwrap()
            
            let author = Author(
                message: message,
                chats: chats,
                users: users
            )
            
            let commentsCount: Int32
            switch message.replies {
            case let .messageReplies(_, replies, _, _, _, _, _):
                commentsCount = replies
            case nil:
                commentsCount = 0
            }
            
            self.init(
                author: author,
                commentsCount: commentsCount,
                date: message.date,
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

extension [FeatDataSharing.Message] {
    init(
        messages: [Api.Message],
        chats: [Api.Chat],
        users: [Api.User]
    ) {
        self = messages.compactMap {
            .init(message: $0, chats: chats, users: users)
        }
    }
}
