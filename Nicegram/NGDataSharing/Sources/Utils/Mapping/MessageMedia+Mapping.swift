import FeatDataSharing
import Foundation
import NGCore
import Postbox
import TelegramApi
import TelegramCore

//  MARK: - Local

extension FeatDataSharing.Message.Media {
    init?(_ media: Media?) {
        do {
            let media = try media.unwrap()
            
            switch media {
            case let media as TelegramMediaImage:
                let representations = media.representations
                let representation = try representations.first.unwrap()
                let resource = try (representation.resource as? CloudPhotoSizeMediaResource).unwrap()
                
                var videoSizes: [VideoSize] = []
                if let emojiMarkup = media.emojiMarkup {
                    switch emojiMarkup.content {
                    case let .emoji(fileId):
                        videoSizes.append(
                            .emojiMarkup(
                                .init(
                                    emojiId: fileId,
                                    backgroundsColors: emojiMarkup.backgroundColors
                                )
                            )
                        )
                    case let .sticker(_, fileId):
                        videoSizes.append(
                            .stickerMarkup(
                                .init(
                                    stickerId: fileId,
                                    backgroundsColors: emojiMarkup.backgroundColors
                                )
                            )
                        )
                    }
                }
                
                for representation in media.videoRepresentations {
                    let resource = representation.resource as? CloudPhotoSizeMediaResource
                    videoSizes.append(
                        .size(
                            .init(
                                w: representation.dimensions.width,
                                h: representation.dimensions.height,
                                size: resource?.size ?? 0,
                                type: resource?.sizeSpec ?? ""
                            )
                        )
                    )
                }
                
                self = .photo(
                    .init(
                        accessHash: resource.accessHash,
                        date: 0,
                        dcId: resource.datacenterId,
                        fileReference: .init(resource.fileReference ?? Data()),
                        hasStickers: media.flags.contains(.hasStickers),
                        id: resource.photoId,
                        sizes: representations.map { representation in
                            let resource = representation.resource as? CloudPhotoSizeMediaResource
                            return .size(
                                .init(
                                    w: representation.dimensions.width,
                                    h: representation.dimensions.height,
                                    size: resource?.size ?? 0,
                                    type: resource?.sizeSpec ?? ""
                                )
                            )
                        },
                        videoSizes: videoSizes
                    )
                )
            case let media as TelegramMediaFile:
                for attribute in media.attributes {
                    switch attribute {
                    case let .Audio(_, duration, title, _, _):
                        self = .audio(
                            .init(
                                duration: duration,
                                title: title
                            )
                        )
                        return
                    case let .Video(duration, _, _, _, _, _):
                        self = .video(
                            .init(
                                duration: duration
                            )
                        )
                        return
                    default:
                        continue
                    }
                }
                return nil
            default:
                return nil
            }
        } catch {
            return nil
        }
    }
}

//  MARK: - Api

extension FeatDataSharing.Message.Media {
    init?(_ media: Api.MessageMedia?) {
        guard let media = mediaFromApiMedia(media) else {
            return nil
        }
        self.init(media)
    }
}
