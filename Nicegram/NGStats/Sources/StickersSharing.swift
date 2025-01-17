import AccountContext
import FeatNicegramHub
import MemberwiseInit
import NGUtils
import TelegramCore

@MemberwiseInit(.public)
public class StickersDataProviderImpl {
    @Init(.public) private let contextProvider: ContextProvider
}

extension StickersDataProviderImpl: StickersDataProvider {
    public func getStickersData() async -> StickersData? {
        guard let context = contextProvider.context() else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            _ = context.account.postbox.transaction { transaction in
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
            }.start(next: { stickerSets in
                continuation.resume(
                    returning: StickersData(
                        stickerSets: stickerSets
                    )
                )
            })
        }
    }
}
