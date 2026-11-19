import FeatDataSharing
import TelegramApi
import TelegramCore

//  MARK: - Local

extension FeatDataSharing.Message.Media {
    init?(_ media: EngineRawMedia?) {
        guard let media else { return nil }
        self.init(type: Self.tlName(of: media))
    }
}

//  MARK: - Api

extension FeatDataSharing.Message.Media {
    init?(_ media: Api.MessageMedia?) {
        switch media {
        case nil, .messageMediaEmpty:
            return nil
        case let media?:
            self.init(type: media.descriptionFields().0)
        }
    }
}

private extension FeatDataSharing.Message.Media {
    static func tlName(of media: EngineRawMedia) -> String {
        switch media {
        case is TelegramMediaImage: "messageMediaPhoto"
        case is TelegramMediaFile: "messageMediaDocument"
        case is TelegramMediaWebpage: "messageMediaWebPage"
        case is TelegramMediaPoll: "messageMediaPoll"
        case is TelegramMediaMap: "messageMediaGeo"
        case is TelegramMediaContact: "messageMediaContact"
        case is TelegramMediaDice: "messageMediaDice"
        case is TelegramMediaGiveaway: "messageMediaGiveaway"
        case is TelegramMediaStory: "messageMediaStory"
        case is TelegramMediaInvoice: "messageMediaInvoice"
        case is TelegramMediaPaidContent: "messageMediaPaidMedia"
        default: "messageMediaUnsupported"
        }
    }
}
