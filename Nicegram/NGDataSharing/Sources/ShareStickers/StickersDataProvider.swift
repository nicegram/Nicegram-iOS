import AccountContext
import FeatDataSharing
import MemberwiseInit
import NGUtils
import SwiftSignalKit
import TelegramCore

@MemberwiseInit(.public)
public class StickersDataProvider {
    @Init(.public) private let context: AccountContext
}

extension StickersDataProvider {
    public func getStickersData() async -> [StickerSet] {
        do {
            let signal = context.engine.data.get(
                TelegramEngine.EngineData.Item.ItemCollections.InstalledPackInfos(
                    namespace: Namespaces.ItemCollection.CloudStickerPacks
                )
            )
            |> map { entries -> [StickerSet] in
                entries
                    .compactMap {
                        $0.info as? StickerPackCollectionInfo
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
