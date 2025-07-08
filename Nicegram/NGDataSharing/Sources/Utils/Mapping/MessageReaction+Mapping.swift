import FeatDataSharing
import TelegramApi
import TelegramCore

//  MARK: - Local

extension [Message.Reaction] {
    init(_ attr: ReactionsMessageAttribute?) {
        guard let attr else {
            self = []
            return
        }
        
        self = attr.reactions.map { reaction in
            let count = reaction.count
            switch reaction.value {
            case let .builtin(emoticon):
                return .emoji(
                    .init(
                        emoticon: emoticon,
                        count: count
                    )
                )
            case let .custom(documentId):
                return .customEmoji(
                    .init(
                        documentId: documentId,
                        count: count
                    )
                )
            case .stars:
                return .paid(
                    .init(
                        count: count
                    )
                )
            }
        }
    }
}

//  MARK: - Api

extension [Message.Reaction] {
    init(_ reactions: Api.MessageReactions?) {
        guard let reactions else {
            self = []
            return
        }
        
        self.init(ReactionsMessageAttribute(apiReactions: reactions))
    }
}
