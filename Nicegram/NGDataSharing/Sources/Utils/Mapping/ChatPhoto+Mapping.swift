import FeatDataSharing
import Foundation
import TelegramCore

//  MARK: - Local

extension ChatPhoto {
    init(_ representations: [TelegramMediaImageRepresentation]) {
        do {
            let representation = try representations.first.unwrap()
            let resource = try (representation.resource as? CloudPeerPhotoSizeMediaResource).unwrap()
            let stripedThumb = representation.immediateThumbnailData ?? Data()
            self = .photo(
                .init(
                    dcId: resource.datacenterId,
                    hasVideo: representation.hasVideo,
                    personal: representation.isPersonal,
                    photoId: resource.photoId ?? 0,
                    stripedThumb: .init(stripedThumb)
                )
            )
        } catch {
            self = .empty(.init())
        }
    }
}
