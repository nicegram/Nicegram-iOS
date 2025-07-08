import AccountContext
import FeatDataSharing
import MemberwiseInit
import NGUtils
import TelegramCore

@MemberwiseInit(.public)
public class StickersDataProvider {
    @Init(.public) private let context: AccountContext
}

extension StickersDataProvider {
    public func getStickersData() async -> [StickerSet] {
        do {
            let signal = context.account.postbox.transaction { transaction in
                transaction
                    .getItemCollectionsInfos(
                        namespace: Namespaces.ItemCollection.CloudStickerPacks
                    ).compactMap {
                        $0.1 as? StickerPackCollectionInfo
                    }.map { pack in
                        let resource = pack.thumbnail?.resource as? CloudStickerPackThumbnailMediaResource
                        
                        let flags = pack.flags
                        
                        return StickerSet(
                            archived: false,
                            channelEmojiStatus: flags.contains(.isAvailableAsChannelStatus),
                            official: flags.contains(.isOfficial),
                            masks: flags.contains(.isMasks),
                            animated: false,
                            videos: false,
                            emojis: flags.contains(.isEmoji),
                            id: pack.id.id,
                            title: pack.title,
                            shortName: pack.shortName,
                            thumbDcId: resource?.datacenterId,
                            thumbVersion: resource?.thumbVersion,
                            thumbDocumentId: pack.thumbnailFileId,
                            count: pack.count
                        )
                    }
            }
            return try await signal.awaitForFirstValue()
        } catch {
            return []
        }
    }
}
