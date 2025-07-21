import FeatDataSharing
import Foundation
import NGCore
import NGUtils
import Postbox
import TelegramApi
import TelegramCore

//  MARK: - Local

extension FeatDataSharing.Message.Media {
    init?(_ media: Media?) {
        do {
            let media = try media.unwrap()
            let mediaId = try media.id.unwrap()
            
            var type: FeatDataSharing.Message.MediaType?
            
            switch media {
            case let media as TelegramMediaImage:
                let representations = media.representations
                let representation = try representations.first.unwrap()
                let resource = try (representation.resource as? CloudPhotoSizeMediaResource).unwrap()
                
                var sizes: [PhotoSize] = []
                
                if let immediateThumbnailData = media.immediateThumbnailData {
                    sizes.append(
                        .strippedSize(
                            .init(
                                bytes: .init(immediateThumbnailData),
                                type: "i"
                            )
                        )
                    )
                }
                
                for representation in representations {
                    let resource = representation.resource as? CloudPhotoSizeMediaResource
                    sizes.append(
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
                
                type = .photo(
                    .init(
                        accessHash: resource.accessHash,
                        date: 0,
                        dcId: resource.datacenterId,
                        fileReference: .init(resource.fileReference ?? Data()),
                        hasStickers: media.flags.contains(.hasStickers),
                        id: resource.photoId,
                        sizes: sizes,
                        videoSizes: videoSizes
                    )
                )
            case let media as TelegramMediaFile:
                for attribute in media.attributes {
                    switch attribute {
                    case let .Audio(_, duration, title, _, _):
                        type = .audio(
                            .init(
                                duration: duration,
                                title: title
                            )
                        )
                    case let .Video(duration, _, _, _, _, _):
                        type = .video(
                            .init(
                                duration: duration
                            )
                        )
                    default:
                        continue
                    }
                }
            default:
                break
            }
            
            try self.init(
                id: .init(mediaId),
                type: type.unwrap()
            )
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
