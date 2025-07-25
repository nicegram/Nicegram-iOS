// MARK: Nicegram RoundedVideos
import NGRoundedVideos
//
import Foundation
import UIKit
import LegacyComponents
import SwiftSignalKit
import TelegramCore
import Postbox
import SSignalKit
import Display
import TelegramPresentationData
import DeviceAccess
import AccountContext
import ImageCompression
import MimeTypes
import LocalMediaResources
import LegacyUI
import TextFormat
import Photos

public func guessMimeTypeByFileExtension(_ ext: String) -> String {
    return TGMimeTypeMap.mimeType(forExtension: ext) ?? "application/binary"
}

public func configureLegacyAssetPicker(_ controller: TGMediaAssetsController, context: AccountContext, peer: Peer, chatLocation: ChatLocation, captionsEnabled: Bool = true, storeCreatedAssets: Bool = true, showFileTooltip: Bool = false, initialCaption: NSAttributedString, hasSchedule: Bool, presentWebSearch: (() -> Void)?, presentSelectionLimitExceeded: @escaping () -> Void, presentSchedulePicker: @escaping (Bool, @escaping (Int32) -> Void) -> Void, presentTimerPicker: @escaping (@escaping (Int32) -> Void) -> Void, getCaptionPanelView: @escaping () -> TGCaptionPanelView?) {
    let paintStickersContext = LegacyPaintStickersContext(context: context)
    paintStickersContext.captionPanelView = {
        return getCaptionPanelView()
    }
    
    controller.captionsEnabled = captionsEnabled
    controller.inhibitDocumentCaptions = false
    controller.stickersContext = paintStickersContext
    if peer.id != context.account.peerId {
        if peer is TelegramUser {
            controller.hasTimer = hasSchedule
        }
        controller.hasSilentPosting = true
    }
    controller.hasSchedule = hasSchedule
    controller.reminder = peer.id == context.account.peerId
    if let channel = peer as? TelegramChannel, case .broadcast = channel.info {
        controller.hasCoverButton = true
    } else if peer.id == context.account.peerId {
        controller.hasCoverButton = true
    }
    controller.presentScheduleController = { media, done in
        presentSchedulePicker(media, { time in
            done?(time)
        })
    }
    controller.presentTimerController = { done in
        presentTimerPicker { time in
            done?(time)
        }
    }
    controller.selectionLimitExceeded = {
        presentSelectionLimitExceeded()
    }
    controller.localMediaCacheEnabled = false
    controller.shouldStoreAssets = storeCreatedAssets
    controller.shouldShowFileTipIfNeeded = showFileTooltip
    controller.requestSearchController = presentWebSearch
    
    if !initialCaption.string.isEmpty {
        controller.editingContext.setForcedCaption(initialCaption)
    }
}

public func legacyAssetPicker(context: AccountContext, presentationData: PresentationData, editingMedia: Bool, fileMode: Bool, peer: Peer?, threadTitle: String?, saveEditedPhotos: Bool, allowGrouping: Bool, selectionLimit: Int) -> Signal<(LegacyComponentsContext) -> TGMediaAssetsController, Void> {
    let isSecretChat = (peer?.id.namespace._internalGetInt32Value() ?? 0) == Namespaces.Peer.SecretChat._internalGetInt32Value()
    
    let recipientName: String?
    if let threadTitle {
        recipientName = threadTitle
    } else {
        if peer?.id == context.account.peerId {
            recipientName = presentationData.strings.DialogList_SavedMessages
        } else {
            recipientName = peer.flatMap(EnginePeer.init)?.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)
        }
    }
    
    return Signal { subscriber in
        let intent = fileMode ? TGMediaAssetsControllerSendFileIntent : TGMediaAssetsControllerSendMediaIntent
        let defaultVideoPreset = defaultVideoPresetForContext(context)
        UserDefaults.standard.set(defaultVideoPreset.rawValue as NSNumber, forKey: "TG_preferredVideoPreset_v0")
        
        DeviceAccess.authorizeAccess(to: .mediaLibrary(.send), presentationData: presentationData, present: context.sharedContext.presentGlobalController, openSettings: context.sharedContext.applicationBindings.openSettings, { value in
            if !value {
                subscriber.putError(Void())
                return
            }
    
            if TGMediaAssetsLibrary.authorizationStatus() == TGMediaLibraryAuthorizationStatusNotDetermined {
                TGMediaAssetsLibrary.requestAuthorization(for: TGMediaAssetAnyType, completion: { (status, group) in
                    if !LegacyComponentsGlobals.provider().accessChecker().checkPhotoAuthorizationStatus(for: TGPhotoAccessIntentRead, alertDismissCompletion: nil) {
                        subscriber.putError(Void())
                    } else {
                        Queue.mainQueue().async {
                            subscriber.putNext({ context in
                                let controller = TGMediaAssetsController(context: context, assetGroup: group, intent: intent, recipientName: recipientName, saveEditedPhotos: !isSecretChat && saveEditedPhotos, allowGrouping: allowGrouping, inhibitSelection: editingMedia, selectionLimit: Int32(selectionLimit))
                                return controller!
                            })
                            subscriber.putCompletion()
                        }
                    }
                })
            } else {
                subscriber.putNext({ context in
                    let controller = TGMediaAssetsController(context: context, assetGroup: nil, intent: intent, recipientName: recipientName, saveEditedPhotos: !isSecretChat && saveEditedPhotos, allowGrouping: allowGrouping, inhibitSelection: editingMedia, selectionLimit: Int32(selectionLimit))
                    return controller!
                })
                subscriber.putCompletion()
            }  
        })
        
        return ActionDisposable {
            
        }
    }
}

private enum LegacyAssetImageData {
    case image(UIImage)
    case asset(PHAsset)
    case tempFile(String)
}

private enum LegacyAssetVideoData {
    case asset(TGMediaAsset)
    case tempFile(path: String, dimensions: CGSize, duration: Double)
}

private enum LegacyAssetItem {
    case image(data: LegacyAssetImageData, thumbnail: UIImage?, caption: NSAttributedString?, stickers: [FileMediaReference])
    case file(data: LegacyAssetImageData, thumbnail: UIImage?, mimeType: String, name: String, caption: NSAttributedString?)
    case video(data: LegacyAssetVideoData, thumbnail: UIImage?, cover: UIImage?, adjustments: TGVideoEditAdjustments?, caption: NSAttributedString?, asFile: Bool, asAnimation: Bool, stickers: [FileMediaReference])
}

private final class LegacyAssetItemWrapper: NSObject {
    let item: LegacyAssetItem
    let timer: Int?
    let spoiler: Bool?
    let price: Int64?
    let forceHd: Bool
    let groupedId: Int64?
    let uniqueId: String?
    
    init(item: LegacyAssetItem, timer: Int?, spoiler: Bool?, price: Int64?, forceHd: Bool = false, groupedId: Int64?, uniqueId: String?) {
        self.item = item
        self.timer = timer
        self.spoiler = spoiler
        self.price = price
        self.forceHd = forceHd
        self.groupedId = groupedId
        self.uniqueId = uniqueId
        
        super.init()
    }
}

public func legacyAssetPickerItemGenerator() -> ((Any?, NSAttributedString?, String?, String?) -> [AnyHashable : Any]?) {
    return { anyDict, caption, hash, uniqueId in
        let dict = anyDict as! NSDictionary
        let stickers = (dict["stickers"] as? [Data])?.compactMap { data -> FileMediaReference? in
            let decoder = PostboxDecoder(buffer: MemoryBuffer(data: data))
            if let file = decoder.decodeRootObject() as? TelegramMediaFile {
                return FileMediaReference.standalone(media: file)
            } else {
                return nil
            }
        } ?? []
        
        let price = dict["price"] as? Int64
        
        if (dict["type"] as! NSString) == "editedPhoto" || (dict["type"] as! NSString) == "capturedPhoto" {
            let image = dict["image"] as! UIImage
            let thumbnail = dict["previewImage"] as? UIImage
            let cover = dict["coverImage"] as? UIImage
            let forceHd = (dict["hd"] as? NSNumber)?.boolValue ?? false
            
            var result: [AnyHashable : Any] = [:]
            if let isAnimation = dict["isAnimation"] as? NSNumber, isAnimation.boolValue {
                let url: String? = (dict["url"] as? String) ?? (dict["url"] as? URL)?.path
                if let url = url {
                    let dimensions = image.size
                    result["item" as NSString] = LegacyAssetItemWrapper(item: .video(data: .tempFile(path: url, dimensions: dimensions, duration: 4.0), thumbnail: thumbnail, cover: cover, adjustments: dict["adjustments"] as? TGVideoEditAdjustments, caption: caption, asFile: false, asAnimation: true, stickers: stickers), timer: (dict["timer"] as? NSNumber)?.intValue, spoiler: (dict["spoiler"] as? NSNumber)?.boolValue, price: price, groupedId: (dict["groupedId"] as? NSNumber)?.int64Value, uniqueId: uniqueId)
                }
            } else {
                result["item" as NSString] = LegacyAssetItemWrapper(item: .image(data: .image(image), thumbnail: thumbnail, caption: caption, stickers: stickers), timer: (dict["timer"] as? NSNumber)?.intValue,  spoiler: (dict["spoiler"] as? NSNumber)?.boolValue, price: price, forceHd: forceHd, groupedId: (dict["groupedId"] as? NSNumber)?.int64Value, uniqueId: uniqueId)
            }
            return result
        } else if (dict["type"] as! NSString) == "cloudPhoto" {
            let asset = dict["asset"] as! TGMediaAsset
            let thumbnail = dict["previewImage"] as? UIImage
            var asFile = false
            if let document = dict["document"] as? NSNumber, document.boolValue {
                asFile = true
            }
            var result: [AnyHashable: Any] = [:]
            if asFile {
                var mimeType = "image/jpeg"
                if let customMimeType = dict["mimeType"] as? String {
                    mimeType = customMimeType
                }
                var name = "image.jpg"
                if let customName = dict["fileName"] as? String {
                    name = customName
                }
                result["item" as NSString] = LegacyAssetItemWrapper(item: .file(data: .asset(asset.backingAsset), thumbnail: thumbnail, mimeType: mimeType, name: name, caption: caption), timer: nil, spoiler: nil, price: price, groupedId: (dict["groupedId"] as? NSNumber)?.int64Value, uniqueId: uniqueId)
            } else {
                let forceHd = (dict["hd"] as? NSNumber)?.boolValue ?? false
                result["item" as NSString] = LegacyAssetItemWrapper(item: .image(data: .asset(asset.backingAsset), thumbnail: thumbnail, caption: caption, stickers: []), timer: (dict["timer"] as? NSNumber)?.intValue, spoiler: (dict["spoiler"] as? NSNumber)?.boolValue, price: price, forceHd: forceHd, groupedId: (dict["groupedId"] as? NSNumber)?.int64Value, uniqueId: uniqueId)
            }
            return result
        } else if (dict["type"] as! NSString) == "file" {
            if let tempFileUrl = dict["tempFileUrl"] as? URL {
                let thumbnail = dict["previewImage"] as? UIImage
                var mimeType = "application/binary"
                if let customMimeType = dict["mimeType"] as? String {
                    mimeType = customMimeType
                }
                var name = "file"
                if let customName = dict["fileName"] as? String {
                    name = customName
                }
                
                if let isAnimation = dict["isAnimation"] as? NSNumber, isAnimation.boolValue, mimeType == "video/mp4" {
                    var result: [AnyHashable: Any] = [:]
                    
                    let dimensions = (dict["dimensions"]! as AnyObject).cgSizeValue!
                    let duration = (dict["duration"]! as AnyObject).doubleValue!
                    
                    result["item" as NSString] = LegacyAssetItemWrapper(item: .video(data: .tempFile(path: tempFileUrl.path, dimensions: dimensions, duration: duration), thumbnail: thumbnail, cover: nil, adjustments: nil, caption: caption, asFile: false, asAnimation: true, stickers: []), timer: (dict["timer"] as? NSNumber)?.intValue, spoiler: (dict["spoiler"] as? NSNumber)?.boolValue, price: price, groupedId: (dict["groupedId"] as? NSNumber)?.int64Value, uniqueId: uniqueId)
                    return result
                }
                
                var result: [AnyHashable: Any] = [:]
                result["item" as NSString] = LegacyAssetItemWrapper(item: .file(data: .tempFile(tempFileUrl.path), thumbnail: thumbnail, mimeType: mimeType, name: name, caption: caption), timer: (dict["timer"] as? NSNumber)?.intValue, spoiler: (dict["spoiler"] as? NSNumber)?.boolValue, price: price,  groupedId: (dict["groupedId"] as? NSNumber)?.int64Value, uniqueId: uniqueId)
                return result
            }
        } else if (dict["type"] as! NSString) == "video" {
            let thumbnail = dict["previewImage"] as? UIImage
            let cover = dict["coverImage"] as? UIImage
            var asFile = false
            if let document = dict["document"] as? NSNumber, document.boolValue {
                asFile = true
            }
            
            if let asset = dict["asset"] as? TGMediaAsset {
                var result: [AnyHashable: Any] = [:]
                result["item" as NSString] = LegacyAssetItemWrapper(item: .video(data: .asset(asset), thumbnail: thumbnail, cover: cover, adjustments: dict["adjustments"] as? TGVideoEditAdjustments, caption: caption, asFile: asFile, asAnimation: false, stickers: stickers), timer: (dict["timer"] as? NSNumber)?.intValue, spoiler: (dict["spoiler"] as? NSNumber)?.boolValue, price: price, groupedId: (dict["groupedId"] as? NSNumber)?.int64Value, uniqueId: uniqueId)
                return result
            } else if let url = (dict["url"] as? String) ?? (dict["url"] as? URL)?.absoluteString {
                let dimensions = (dict["dimensions"]! as AnyObject).cgSizeValue!
                let duration = (dict["duration"]! as AnyObject).doubleValue!
                var result: [AnyHashable: Any] = [:]
                result["item" as NSString] = LegacyAssetItemWrapper(item: .video(data: .tempFile(path: url, dimensions: dimensions, duration: duration), thumbnail: thumbnail, cover: cover, adjustments: dict["adjustments"] as? TGVideoEditAdjustments, caption: caption, asFile: asFile, asAnimation: false, stickers: stickers), timer: (dict["timer"] as? NSNumber)?.intValue, spoiler: (dict["spoiler"] as? NSNumber)?.boolValue, price: price, groupedId: (dict["groupedId"] as? NSNumber)?.int64Value, uniqueId: uniqueId)
                return result
            }
        } else if (dict["type"] as! NSString) == "cameraVideo" {
            let thumbnail = dict["previewImage"] as? UIImage
            let cover = dict["coverImage"] as? UIImage
            var asFile = false
            if let document = dict["document"] as? NSNumber, document.boolValue {
                asFile = true
            }
            
            let url: String? = (dict["url"] as? String) ?? (dict["url"] as? URL)?.path
            
            if let url = url, let previewImage = dict["previewImage"] as? UIImage {
                let dimensions = previewImage.pixelSize()
                let duration = (dict["duration"]! as AnyObject).doubleValue!
                var result: [AnyHashable: Any] = [:]
                result["item" as NSString] = LegacyAssetItemWrapper(item: .video(data: .tempFile(path: url, dimensions: dimensions, duration: duration), thumbnail: thumbnail, cover: cover, adjustments: dict["adjustments"] as? TGVideoEditAdjustments, caption: caption, asFile: asFile, asAnimation: false, stickers: stickers), timer: (dict["timer"] as? NSNumber)?.intValue, spoiler: (dict["spoiler"] as? NSNumber)?.boolValue, price: price, groupedId: (dict["groupedId"] as? NSNumber)?.int64Value, uniqueId: uniqueId)
                return result
            }
        }
        return nil
    }
}

public func legacyEnqueueGifMessage(account: Account, data: Data, correlationId: Int64? = nil) -> Signal<EnqueueMessage, Void> {
    return Signal { subscriber in
        if let previewImage = UIImage(data: data) {
            let dimensions = previewImage.size
            var previewRepresentations: [TelegramMediaImageRepresentation] = []
            
            let thumbnailSize = dimensions.aspectFitted(CGSize(width: 320.0, height: 320.0))
            let thumbnailImage = TGScaleImageToPixelSize(previewImage, thumbnailSize)!
            if let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.4) {
                let resource = LocalFileMediaResource(fileId: Int64.random(in: Int64.min ... Int64.max))
                account.postbox.mediaBox.storeResourceData(resource.id, data: thumbnailData)
                previewRepresentations.append(TelegramMediaImageRepresentation(dimensions: PixelDimensions(thumbnailSize), resource: resource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false, isPersonal: false))
            }
            
            var randomId: Int64 = 0
            arc4random_buf(&randomId, 8)
            let tempFilePath = NSTemporaryDirectory() + "\(randomId).gif"
            
            let _ = try? FileManager.default.removeItem(atPath: tempFilePath)
            let _ = try? data.write(to: URL(fileURLWithPath: tempFilePath), options: [.atomic])
        
            let resource = LocalFileGifMediaResource(randomId: Int64.random(in: Int64.min ... Int64.max), path: tempFilePath)
            let fileName: String = "video.mp4"
            
            let finalDimensions = TGMediaVideoConverter.dimensions(for: dimensions, adjustments: nil, preset: TGMediaVideoConversionPresetAnimation)
            
            var fileAttributes: [TelegramMediaFileAttribute] = []
            fileAttributes.append(.Video(duration: 0.0, size: PixelDimensions(finalDimensions), flags: [.supportsStreaming], preloadSize: nil, coverTime: nil, videoCodec: nil))
            fileAttributes.append(.FileName(fileName: fileName))
            fileAttributes.append(.Animated)
            
            let media = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: Int64.random(in: Int64.min ... Int64.max)), partialReference: nil, resource: resource, previewRepresentations: previewRepresentations, videoThumbnails: [], immediateThumbnailData: nil, mimeType: "video/mp4", size: nil, attributes: fileAttributes, alternativeRepresentations: [])
            subscriber.putNext(.message(text: "", attributes: [], inlineStickers: [:], mediaReference: .standalone(media: media), threadId: nil, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: []))
            subscriber.putCompletion()
        } else {
            subscriber.putError(Void())
        }
        
        return EmptyDisposable
    } |> runOn(Queue.concurrentDefaultQueue())
}

public func legacyEnqueueVideoMessage(account: Account, data: Data, correlationId: Int64? = nil) -> Signal<EnqueueMessage, Void> {
    return Signal { subscriber in
        if let previewImage = UIImage(data: data) {
            let dimensions = previewImage.size
            var previewRepresentations: [TelegramMediaImageRepresentation] = []
            
            let thumbnailSize = dimensions.aspectFitted(CGSize(width: 320.0, height: 320.0))
            let thumbnailImage = TGScaleImageToPixelSize(previewImage, thumbnailSize)!
            if let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.4) {
                let resource = LocalFileMediaResource(fileId: Int64.random(in: Int64.min ... Int64.max))
                account.postbox.mediaBox.storeResourceData(resource.id, data: thumbnailData)
                previewRepresentations.append(TelegramMediaImageRepresentation(dimensions: PixelDimensions(thumbnailSize), resource: resource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false, isPersonal: false))
            }
            
            var randomId: Int64 = 0
            arc4random_buf(&randomId, 8)
            let tempFilePath = NSTemporaryDirectory() + "\(randomId).mp4"
            
            let _ = try? FileManager.default.removeItem(atPath: tempFilePath)
            let _ = try? data.write(to: URL(fileURLWithPath: tempFilePath), options: [.atomic])
        
            let resource = LocalFileGifMediaResource(randomId: Int64.random(in: Int64.min ... Int64.max), path: tempFilePath)
            let fileName: String = "video.mp4"
            
            let finalDimensions = TGMediaVideoConverter.dimensions(for: dimensions, adjustments: nil, preset: TGMediaVideoConversionPresetAnimation)
            
            var fileAttributes: [TelegramMediaFileAttribute] = []
            fileAttributes.append(.Video(duration: 0.0, size: PixelDimensions(finalDimensions), flags: [.supportsStreaming], preloadSize: nil, coverTime: nil, videoCodec: nil))
            fileAttributes.append(.FileName(fileName: fileName))
            fileAttributes.append(.Animated)
            
            let media = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: Int64.random(in: Int64.min ... Int64.max)), partialReference: nil, resource: resource, previewRepresentations: previewRepresentations, videoThumbnails: [], immediateThumbnailData: nil, mimeType: "video/mp4", size: nil, attributes: fileAttributes, alternativeRepresentations: [])
            subscriber.putNext(.message(text: "", attributes: [], inlineStickers: [:], mediaReference: .standalone(media: media), threadId: nil, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: []))
            subscriber.putCompletion()
        } else {
            subscriber.putError(Void())
        }
        
        return EmptyDisposable
    } |> runOn(Queue.concurrentDefaultQueue())
}

public struct LegacyAssetPickerEnqueueMessage {
    public var message: EnqueueMessage
    public var uniqueId: String?
    public var isFile: Bool
}

// MARK: Nicegram RoundedVideos
private func ngMapLegacyAssetPickerValues(
    _ values: Any?,
    sendAsRoundedVideo: Bool
) -> Any? {
    guard sendAsRoundedVideo else {
        return values
    }
    
    var result: [Any] = []
    for value in (values as! NSArray) {
        if let itemWrapper = (value as? NSDictionary)?.object(forKey: "item") as? LegacyAssetItemWrapper,
           case let .video(data, thumbnail, cover, adjustments, caption, asFile, asAnimation, stickers) = itemWrapper.item {
            let trimTimeRange: CMTimeRange
            if let adjustments,
               !adjustments.trimTimeRange().isEmpty {
                trimTimeRange = adjustments.trimTimeRange()
            } else {
                let duration: Double
                switch data {
                case let .asset(asset):
                    duration = asset.videoDuration
                case let .tempFile(_, _, _duration):
                    duration = _duration
                }
                trimTimeRange = CMTimeRange(
                    start: .zero,
                    duration: CMTime(
                        seconds: duration,
                        preferredTimescale: 60
                    )
                )
            }
            
            let originalSize: CGSize
            if let adjustments {
                originalSize = adjustments.originalSize
            } else {
                switch data {
                case let .asset(asset):
                    originalSize = asset.dimensions
                case let .tempFile(_, _dimensions, _):
                    originalSize = _dimensions
                }
            }
            
            let chunks = NGRoundedVideos.trim(range: trimTimeRange)
            
            for (index, chunk) in chunks.enumerated() {
                let chunkAdjustments = TGVideoEditAdjustments(
                    originalSize: originalSize,
                    cropRect: adjustments?.cropRect ?? .zero,
                    cropOrientation: adjustments?.cropOrientation ?? .up,
                    cropRotation: adjustments?.cropRotation ?? .zero,
                    cropLockedAspectRatio: adjustments?.cropLockedAspectRatio ?? 1,
                    cropMirrored: adjustments?.cropMirrored ?? false,
                    trimStartValue: chunk.start.seconds,
                    trimEndValue: chunk.end.seconds,
                    toolValues: adjustments?.toolValues,
                    paintingData: adjustments?.paintingData,
                    sendAsGif: adjustments?.sendAsGif ?? false,
                    preset: TGMediaVideoConversionPresetVideoMessage
                )
                
                var chunkUniqueId = itemWrapper.uniqueId
                chunkUniqueId?.append("-\(index)")
                
                let chunkCaption: NSAttributedString? = if index == chunks.startIndex {
                    caption
                } else {
                    nil
                }
                
                let newValue: NSDictionary = [
                    "item": LegacyAssetItemWrapper(
                        item: .video(data: data, thumbnail: thumbnail, cover: cover, adjustments: chunkAdjustments, caption: chunkCaption, asFile: asFile, asAnimation: asAnimation, stickers: stickers),
                        timer: itemWrapper.timer,
                        spoiler: itemWrapper.spoiler,
                        price: itemWrapper.price,
                        groupedId: nil,
                        uniqueId: chunkUniqueId
                    )
                ]
                result.append(newValue)
            }
        } else {
            result.append(value)
        }
    }
    
    return result
}
//

public func legacyAssetPickerEnqueueMessages(context: AccountContext, account: Account, signals: [Any]) -> Signal<[LegacyAssetPickerEnqueueMessage], Void> {
    
    // MARK: Nicegram RoundedVideos
    let sendAsRoundedVideo = NGRoundedVideos.sendAsRoundedVideo
    NGRoundedVideos.sendAsRoundedVideo = false
    //
    
    return Signal { subscriber in
        let disposable = SSignal.combineSignals(signals).start(next: { anyValues in
            var messages: [LegacyAssetPickerEnqueueMessage] = []
                    
            struct EnqueuePaidMessage {
                var price: Int64
                var text: String
                var entities: [MessageTextEntity]
                var media: [Media]
            }
            
            var paidMessage: EnqueuePaidMessage?
            
            // MARK: Nicegram RoundedVideos
            let anyValues = ngMapLegacyAssetPickerValues(
                anyValues,
                sendAsRoundedVideo: sendAsRoundedVideo
            )
            //
            
            outer: for item in (anyValues as! NSArray) {
                if let item = (item as? NSDictionary)?.object(forKey: "item") as? LegacyAssetItemWrapper {
                    switch item.item {
                        case let .image(data, thumbnail, caption, stickers):
                            var representations: [TelegramMediaImageRepresentation] = []
                            if let thumbnail = thumbnail {
                                let resource = LocalFileMediaResource(fileId: Int64.random(in: Int64.min ... Int64.max))
                                let thumbnailSize = thumbnail.size.aspectFitted(CGSize(width: 320.0, height: 320.0))
                                let thumbnailImage = TGScaleImageToPixelSize(thumbnail, thumbnailSize)!
                                if let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.4) {
                                    account.postbox.mediaBox.storeResourceData(resource.id, data: thumbnailData)
                                    representations.append(TelegramMediaImageRepresentation(dimensions: PixelDimensions(thumbnailSize), resource: resource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false, isPersonal: false))
                                }
                            }
                            switch data {
                                case let .image(image):
                                    var randomId: Int64 = 0
                                    arc4random_buf(&randomId, 8)
                                    let tempFilePath = NSTemporaryDirectory() + "\(randomId).jpeg"
                                    let maxSize = item.forceHd ? CGSize(width: 2560.0, height: 2560.0) : CGSize(width: 1280.0, height: 1280.0)
                                    let scaledSize = image.size.aspectFittedOrSmaller(maxSize)
                                
                                    if let scaledImage = TGScaleImageToPixelSize(image, scaledSize) {
                                        let tempFile = TempBox.shared.tempFile(fileName: "file")
                                        defer {
                                            TempBox.shared.dispose(tempFile)
                                        }
                                        if let scaledImageData = compressImageToJPEG(scaledImage, quality: 0.6, tempFilePath: tempFile.path) {
                                            let _ = try? scaledImageData.write(to: URL(fileURLWithPath: tempFilePath))

                                            let resource = LocalFileReferenceMediaResource(localFilePath: tempFilePath, randomId: randomId)
                                            representations.append(TelegramMediaImageRepresentation(dimensions: PixelDimensions(scaledSize), resource: resource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false, isPersonal: false))
                                            
                                            var imageFlags: TelegramMediaImageFlags = []
                                                                                        
                                            var attributes: [MessageAttribute] = []
                                            
                                            var stickerFiles: [TelegramMediaFile] = []
                                            if !stickers.isEmpty {
                                                for fileReference in stickers {
                                                    stickerFiles.append(fileReference.media)
                                                }
                                            }
                                            if !stickerFiles.isEmpty {
                                                attributes.append(EmbeddedMediaStickersMessageAttribute(files: stickerFiles))
                                                imageFlags.insert(.hasStickers)
                                            }

                                            let media = TelegramMediaImage(imageId: MediaId(namespace: Namespaces.Media.LocalImage, id: randomId), representations: representations, immediateThumbnailData: nil, reference: nil, partialReference: nil, flags: imageFlags)
                                            if let timer = item.timer, timer > 0 && (timer <= 60 || timer == viewOnceTimeout) {
                                                attributes.append(AutoremoveTimeoutMessageAttribute(timeout: Int32(timer), countdownBeginTime: nil))
                                            }
                                            if let spoiler = item.spoiler, spoiler {
                                                attributes.append(MediaSpoilerMessageAttribute())
                                            }
                                                                                        
                                            let text = trimChatInputText(convertMarkdownToAttributes(caption ?? NSAttributedString()))
                                            let entities = generateTextEntities(text.string, enabledTypes: .all, currentEntities: generateChatInputTextEntities(text))
                                            if !entities.isEmpty {
                                                attributes.append(TextEntitiesMessageAttribute(entities: entities))
                                            }
                                            var bubbleUpEmojiOrStickersetsById: [Int64: ItemCollectionId] = [:]
                                            text.enumerateAttribute(ChatTextInputAttributes.customEmoji, in: NSRange(location: 0, length: text.length), using: { value, _, _ in
                                                if let value = value as? ChatTextInputTextCustomEmojiAttribute {
                                                    if let file = value.file {
                                                        if let packId = value.interactivelySelectedFromPackId {
                                                            bubbleUpEmojiOrStickersetsById[file.fileId.id] = packId
                                                        }
                                                    }
                                                }
                                            })
                                            var bubbleUpEmojiOrStickersets: [ItemCollectionId] = []
                                            for entity in entities {
                                                if case let .CustomEmoji(_, fileId) = entity.type {
                                                    if let packId = bubbleUpEmojiOrStickersetsById[fileId] {
                                                        if !bubbleUpEmojiOrStickersets.contains(packId) {
                                                            bubbleUpEmojiOrStickersets.append(packId)
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            if let price = item.price {
                                                if var current = paidMessage {
                                                    if current.text.isEmpty && !text.string.isEmpty {
                                                        current.text = text.string
                                                        current.entities = entities
                                                    }
                                                    current.media.append(media)
                                                    paidMessage = current
                                                } else {
                                                    paidMessage = EnqueuePaidMessage(
                                                        price: price,
                                                        text: text.string,
                                                        entities: entities,
                                                        media: [media]
                                                    )
                                                }
                                            } else {
                                                messages.append(LegacyAssetPickerEnqueueMessage(message: .message(text: text.string, attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: media), threadId: nil, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: item.groupedId, correlationId: nil, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets), uniqueId: item.uniqueId, isFile: false))
                                            }
                                        }
                                    }
                                case let .asset(asset):
                                    if context.sharedContext.immediateExperimentalUISettings.storiesJpegExperiment {
                                        let sizes: [Int32] = [2048, 1280]
                                        let formats: [MediaImageFormat] = [.jxl, .jpeg]
                                        let qualities: [Int32: [Int32]] = [
                                            MediaImageFormat.jxl.rawValue: [
                                                50,
                                                75
                                            ],
                                            MediaImageFormat.jpeg.rawValue: [
                                                75
                                            ]
                                        ]
                                        for sizeSide in sizes {
                                            for format in formats {
                                                for quality in qualities[format.rawValue]! {
                                                    var randomId: Int64 = 0
                                                    arc4random_buf(&randomId, 8)
                                                    let resource = PhotoLibraryMediaResource(
                                                        localIdentifier: asset.localIdentifier,
                                                        uniqueId: Int64.random(in: Int64.min ... Int64.max),
                                                        width: sizeSide,
                                                        height: sizeSide,
                                                        format: format,
                                                        quality: quality
                                                    )
                                                    
                                                    let size = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))
                                                    let scaledSize = size.aspectFittedOrSmaller(CGSize(width: CGFloat(sizeSide), height: CGFloat(sizeSide)))
                                                    
                                                    let media: Media
                                                    media = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: Int64.random(in: Int64.min ... Int64.max)), partialReference: nil, resource: resource, previewRepresentations: [], videoThumbnails: [], immediateThumbnailData: nil, mimeType: format == .jxl ? "image/jxl" : "image/jpeg", size: nil, attributes: [
                                                        .FileName(fileName: format == .jxl ? "image\(sizeSide)-q\(quality).jxl" : "image\(sizeSide)-q\(quality).jpg"),
                                                        .ImageSize(size: PixelDimensions(scaledSize))
                                                    ], alternativeRepresentations: [])
                                                    
                                                    var attributes: [MessageAttribute] = []
                                                    if let timer = item.timer, timer > 0 && (timer <= 60 || timer == viewOnceTimeout) {
                                                        attributes.append(AutoremoveTimeoutMessageAttribute(timeout: Int32(timer), countdownBeginTime: nil))
                                                    }
                                                    if let spoiler = item.spoiler, spoiler {
                                                        attributes.append(MediaSpoilerMessageAttribute())
                                                    }
                                                    
                                                    let text = trimChatInputText(convertMarkdownToAttributes(caption ?? NSAttributedString()))
                                                    let entities = generateTextEntities(text.string, enabledTypes: .all, currentEntities: generateChatInputTextEntities(text))
                                                    if !entities.isEmpty {
                                                        attributes.append(TextEntitiesMessageAttribute(entities: entities))
                                                    }
                                                    
                                                    var bubbleUpEmojiOrStickersetsById: [Int64: ItemCollectionId] = [:]
                                                    text.enumerateAttribute(ChatTextInputAttributes.customEmoji, in: NSRange(location: 0, length: text.length), using: { value, _, _ in
                                                        if let value = value as? ChatTextInputTextCustomEmojiAttribute {
                                                            if let file = value.file {
                                                                if let packId = value.interactivelySelectedFromPackId {
                                                                    bubbleUpEmojiOrStickersetsById[file.fileId.id] = packId
                                                                }
                                                            }
                                                        }
                                                    })
                                                    var bubbleUpEmojiOrStickersets: [ItemCollectionId] = []
                                                    for entity in entities {
                                                        if case let .CustomEmoji(_, fileId) = entity.type {
                                                            if let packId = bubbleUpEmojiOrStickersetsById[fileId] {
                                                                if !bubbleUpEmojiOrStickersets.contains(packId) {
                                                                    bubbleUpEmojiOrStickersets.append(packId)
                                                                }
                                                            }
                                                        }
                                                    }
                                                    
                                                    if let price = item.price {
                                                        if var current = paidMessage {
                                                            if current.text.isEmpty && !text.string.isEmpty {
                                                                current.text = text.string
                                                                current.entities = entities
                                                            }
                                                            current.media.append(media)
                                                            paidMessage = current
                                                        } else {
                                                            paidMessage = EnqueuePaidMessage(
                                                                price: price,
                                                                text: text.string,
                                                                entities: entities,
                                                                media: [media]
                                                            )
                                                        }
                                                    } else {
                                                        messages.append(LegacyAssetPickerEnqueueMessage(message: .message(text: text.string, attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: media), threadId: nil, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: item.groupedId, correlationId: nil, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets), uniqueId: item.uniqueId, isFile: false))
                                                    }
                                                }
                                            }
                                        }
                                    } else {
                                        var randomId: Int64 = 0
                                        arc4random_buf(&randomId, 8)
                                        let size = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))
                                        let scaledSize = size.aspectFittedOrSmaller(CGSize(width: 1280.0, height: 1280.0))
                                        let resource = PhotoLibraryMediaResource(localIdentifier: asset.localIdentifier, uniqueId: Int64.random(in: Int64.min ... Int64.max), forceHd: item.forceHd)
                                    
                                        let media: Media
                                        representations.append(TelegramMediaImageRepresentation(dimensions: PixelDimensions(scaledSize), resource: resource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false, isPersonal: false))
                                        media = TelegramMediaImage(imageId: MediaId(namespace: Namespaces.Media.LocalImage, id: randomId), representations: representations, immediateThumbnailData: nil, reference: nil, partialReference: nil, flags: [])
                                    
                                        var attributes: [MessageAttribute] = []
                                        if let timer = item.timer, timer > 0 && (timer <= 60 || timer == viewOnceTimeout) {
                                            attributes.append(AutoremoveTimeoutMessageAttribute(timeout: Int32(timer), countdownBeginTime: nil))
                                        }
                                        if let spoiler = item.spoiler, spoiler {
                                            attributes.append(MediaSpoilerMessageAttribute())
                                        }
                                    
                                        let text = trimChatInputText(convertMarkdownToAttributes(caption ?? NSAttributedString()))
                                        let entities = generateTextEntities(text.string, enabledTypes: .all, currentEntities: generateChatInputTextEntities(text))
                                        if !entities.isEmpty {
                                            attributes.append(TextEntitiesMessageAttribute(entities: entities))
                                        }
                                    
                                        var bubbleUpEmojiOrStickersetsById: [Int64: ItemCollectionId] = [:]
                                        text.enumerateAttribute(ChatTextInputAttributes.customEmoji, in: NSRange(location: 0, length: text.length), using: { value, _, _ in
                                            if let value = value as? ChatTextInputTextCustomEmojiAttribute {
                                                if let file = value.file {
                                                    if let packId = value.interactivelySelectedFromPackId {
                                                        bubbleUpEmojiOrStickersetsById[file.fileId.id] = packId
                                                    }
                                                }
                                            }
                                        })
                                        var bubbleUpEmojiOrStickersets: [ItemCollectionId] = []
                                        for entity in entities {
                                            if case let .CustomEmoji(_, fileId) = entity.type {
                                                if let packId = bubbleUpEmojiOrStickersetsById[fileId] {
                                                    if !bubbleUpEmojiOrStickersets.contains(packId) {
                                                        bubbleUpEmojiOrStickersets.append(packId)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        if let price = item.price {
                                            if var current = paidMessage {
                                                if current.text.isEmpty && !text.string.isEmpty {
                                                    current.text = text.string
                                                    current.entities = entities
                                                }
                                                current.media.append(media)
                                                paidMessage = current
                                            } else {
                                                paidMessage = EnqueuePaidMessage(
                                                    price: price,
                                                    text: text.string,
                                                    entities: entities,
                                                    media: [media]
                                                )
                                            }
                                        } else {
                                            messages.append(LegacyAssetPickerEnqueueMessage(message: .message(text: text.string, attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: media), threadId: nil, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: item.groupedId, correlationId: nil, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets), uniqueId: item.uniqueId, isFile: false))
                                        }
                                    }
                                case .tempFile:
                                    break
                            }
                        case let .file(data, thumbnail, mimeType, name, caption):
                            switch data {
                                case let .tempFile(path):
                                    var previewRepresentations: [TelegramMediaImageRepresentation] = []
                                    if let thumbnail = thumbnail {
                                        let resource = LocalFileMediaResource(fileId: Int64.random(in: Int64.min ... Int64.max))
                                        let thumbnailSize = thumbnail.size.aspectFitted(CGSize(width: 320.0, height: 320.0))
                                        let thumbnailImage = TGScaleImageToPixelSize(thumbnail, thumbnailSize)!
                                        if let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.4) {
                                            account.postbox.mediaBox.storeResourceData(resource.id, data: thumbnailData)
                                            previewRepresentations.append(TelegramMediaImageRepresentation(dimensions: PixelDimensions(thumbnailSize), resource: resource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false, isPersonal: false))
                                        }
                                    }
                                    
                                    var randomId: Int64 = 0
                                    arc4random_buf(&randomId, 8)
                                    let resource = LocalFileReferenceMediaResource(localFilePath: path, randomId: randomId)
                                    let media = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: randomId), partialReference: nil, resource: resource, previewRepresentations: previewRepresentations, videoThumbnails: [], immediateThumbnailData: nil, mimeType: mimeType, size: fileSize(path), attributes: [.FileName(fileName: name)], alternativeRepresentations: [])
                                    
                                    var attributes: [MessageAttribute] = []
                                    let text = trimChatInputText(convertMarkdownToAttributes(caption ?? NSAttributedString()))
                                    let entities = generateTextEntities(text.string, enabledTypes: .all, currentEntities: generateChatInputTextEntities(text))
                                    if !entities.isEmpty {
                                        attributes.append(TextEntitiesMessageAttribute(entities: entities))
                                    }
                                
                                    var bubbleUpEmojiOrStickersetsById: [Int64: ItemCollectionId] = [:]
                                    text.enumerateAttribute(ChatTextInputAttributes.customEmoji, in: NSRange(location: 0, length: text.length), using: { value, _, _ in
                                        if let value = value as? ChatTextInputTextCustomEmojiAttribute {
                                            if let file = value.file {
                                                if let packId = value.interactivelySelectedFromPackId {
                                                    bubbleUpEmojiOrStickersetsById[file.fileId.id] = packId
                                                }
                                            }
                                        }
                                    })
                                    var bubbleUpEmojiOrStickersets: [ItemCollectionId] = []
                                    for entity in entities {
                                        if case let .CustomEmoji(_, fileId) = entity.type {
                                            if let packId = bubbleUpEmojiOrStickersetsById[fileId] {
                                                if !bubbleUpEmojiOrStickersets.contains(packId) {
                                                    bubbleUpEmojiOrStickersets.append(packId)
                                                }
                                            }
                                        }
                                    }
                                    
                                    if let price = item.price {
                                        if var current = paidMessage {
                                            if current.text.isEmpty && !text.string.isEmpty {
                                                current.text = text.string
                                                current.entities = entities
                                            }
                                            current.media.append(media)
                                            paidMessage = current
                                        } else {
                                            paidMessage = EnqueuePaidMessage(
                                                price: price,
                                                text: text.string,
                                                entities: entities,
                                                media: [media]
                                            )
                                        }
                                    } else {
                                        messages.append(LegacyAssetPickerEnqueueMessage(message: .message(text: text.string, attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: media), threadId: nil, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: item.groupedId, correlationId: nil, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets), uniqueId: item.uniqueId, isFile: true))
                                    }
                                case let .asset(asset):
                                    var randomId: Int64 = 0
                                    arc4random_buf(&randomId, 8)
                                    let resource = PhotoLibraryMediaResource(localIdentifier: asset.localIdentifier, uniqueId: Int64.random(in: Int64.min ... Int64.max))
                                    let media = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: randomId), partialReference: nil, resource: resource, previewRepresentations: [], videoThumbnails: [], immediateThumbnailData: nil, mimeType: mimeType, size: nil, attributes: [.FileName(fileName: name)], alternativeRepresentations: [])
                                    
                                    var attributes: [MessageAttribute] = []
                                    let text = trimChatInputText(convertMarkdownToAttributes(caption ?? NSAttributedString()))
                                    let entities = generateTextEntities(text.string, enabledTypes: .all, currentEntities: generateChatInputTextEntities(text))
                                    if !entities.isEmpty {
                                        attributes.append(TextEntitiesMessageAttribute(entities: entities))
                                    }
                                
                                    var bubbleUpEmojiOrStickersetsById: [Int64: ItemCollectionId] = [:]
                                    text.enumerateAttribute(ChatTextInputAttributes.customEmoji, in: NSRange(location: 0, length: text.length), using: { value, _, _ in
                                        if let value = value as? ChatTextInputTextCustomEmojiAttribute {
                                            if let file = value.file {
                                                if let packId = value.interactivelySelectedFromPackId {
                                                    bubbleUpEmojiOrStickersetsById[file.fileId.id] = packId
                                                }
                                            }
                                        }
                                    })
                                    var bubbleUpEmojiOrStickersets: [ItemCollectionId] = []
                                    for entity in entities {
                                        if case let .CustomEmoji(_, fileId) = entity.type {
                                            if let packId = bubbleUpEmojiOrStickersetsById[fileId] {
                                                if !bubbleUpEmojiOrStickersets.contains(packId) {
                                                    bubbleUpEmojiOrStickersets.append(packId)
                                                }
                                            }
                                        }
                                    }
                                    
                                    if let price = item.price {
                                        if var current = paidMessage {
                                            if current.text.isEmpty && !text.string.isEmpty {
                                                current.text = text.string
                                                current.entities = entities
                                            }
                                            current.media.append(media)
                                            paidMessage = current
                                        } else {
                                            paidMessage = EnqueuePaidMessage(
                                                price: price,
                                                text: text.string,
                                                entities: entities,
                                                media: [media]
                                            )
                                        }
                                    } else {
                                        messages.append(LegacyAssetPickerEnqueueMessage(message: .message(text: text.string, attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: media), threadId: nil, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: item.groupedId, correlationId: nil, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets), uniqueId: item.uniqueId, isFile: true))
                                    }
                                default:
                                    break
                            }
                        case let .video(data, thumbnail, cover, adjustments, caption, asFile, asAnimation, stickers):
                            var finalDimensions: CGSize
                            var finalDuration: Double
                            switch data {
                                case let .asset(asset):
                                    if let adjustments = adjustments {
                                        if adjustments.cropApplied(forAvatar: false) {
                                            finalDimensions = adjustments.cropRect.size
                                            if adjustments.cropOrientation == .left || adjustments.cropOrientation == .right {
                                                finalDimensions = CGSize(width: finalDimensions.height, height: finalDimensions.width)
                                            }
                                        } else {
                                            finalDimensions = asset.dimensions
                                        }
                                        if adjustments.trimEndValue > 0.0 {
                                            finalDuration = adjustments.trimEndValue - adjustments.trimStartValue
                                        } else {
                                            finalDuration = asset.videoDuration
                                        }
                                    } else {
                                        finalDimensions = asset.dimensions
                                        finalDuration = asset.videoDuration
                                    }
                                case let .tempFile(_, dimensions, duration):
                                    finalDimensions = dimensions
                                    finalDuration = duration
                            }
                            
                            /*if !asAnimation {
                                finalDimensions = TGFitSize(finalDimensions, CGSize(width: 848.0, height: 848.0))
                            }*/
                            
                            var previewRepresentations: [TelegramMediaImageRepresentation] = []
                            if let thumbnail = thumbnail {
                                let resource = LocalFileMediaResource(fileId: Int64.random(in: Int64.min ... Int64.max))
                                let thumbnailSize = finalDimensions.aspectFitted(CGSize(width: 320.0, height: 320.0))
                                let thumbnailImage = TGScaleImageToPixelSize(thumbnail, thumbnailSize)!
                                if let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.4) {
                                    account.postbox.mediaBox.storeResourceData(resource.id, data: thumbnailData)
                                    previewRepresentations.append(TelegramMediaImageRepresentation(dimensions: PixelDimensions(thumbnailSize), resource: resource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false, isPersonal: false))
                                }
                            }
                            
                            var videoCover: TelegramMediaImage?
                            if let cover {
                                let resource = LocalFileMediaResource(fileId: Int64.random(in: Int64.min ... Int64.max))
                                let coverSize = cover.size.aspectFitted(CGSize(width: 320.0, height: 320.0))
                                let coverImage = TGScaleImageToPixelSize(cover, coverSize)!
                                if let coverData = coverImage.jpegData(compressionQuality: 0.6) {
                                    account.postbox.mediaBox.storeResourceData(resource.id, data: coverData)
                                    videoCover = TelegramMediaImage(
                                        imageId: MediaId(namespace: 0, id: 0),
                                        representations: [
                                            TelegramMediaImageRepresentation(dimensions: PixelDimensions(coverSize), resource: resource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false, isPersonal: false)
                                        ],
                                        immediateThumbnailData: nil,
                                        reference: nil,
                                        partialReference: nil,
                                        flags: []
                                    )
                                }
                            }
                        
                            let defaultPreset = TGMediaVideoConversionPreset(rawValue: UInt32(UserDefaults.standard.integer(forKey: "TG_preferredVideoPreset_v0")))
                            
                            var preset: TGMediaVideoConversionPreset = TGMediaVideoConversionPresetCompressedMedium
                            if let selectedPreset = adjustments?.preset {
                                preset = selectedPreset
                            } else if preset == TGMediaVideoConversionPresetCompressedDefault && defaultPreset != TGMediaVideoConversionPresetCompressedDefault {
                                preset = defaultPreset
                            }
                            if asAnimation {
                                preset = TGMediaVideoConversionPresetAnimation
                            }
                            
                            if !asAnimation {
                                finalDimensions = TGMediaVideoConverter.dimensions(for: finalDimensions, adjustments: adjustments, preset: TGMediaVideoConversionPresetCompressedMedium)
                            }
                            
                            var resourceAdjustments: VideoMediaResourceAdjustments?
                            if let adjustments = adjustments {
                                if adjustments.trimApplied() {
                                    finalDuration = adjustments.trimEndValue - adjustments.trimStartValue
                                }
                                
                                if let dict = adjustments.dictionary(), let data = try? NSKeyedArchiver.archivedData(withRootObject: dict, requiringSecureCoding: false) {
                                    let adjustmentsData = MemoryBuffer(data: data)
                                    let digest = MemoryBuffer(data: adjustmentsData.md5Digest())
                                    resourceAdjustments = VideoMediaResourceAdjustments(data: adjustmentsData, digest: digest, isStory: false)
                                }
                            }
                            
                            let resource: TelegramMediaResource
                            var fileName: String = "video.mp4"
                            switch data {
                                case let .asset(asset):
                                    if let assetFileName = asset.fileName, !assetFileName.isEmpty {
                                        fileName = (assetFileName as NSString).lastPathComponent
                                    }
                                    resource = VideoLibraryMediaResource(localIdentifier: asset.backingAsset.localIdentifier, conversion: asFile ? .passthrough : .compress(resourceAdjustments))
                                case let .tempFile(path, _, _):
                                    if asFile || (asAnimation && !path.contains(".jpg")) {
                                        if let size = fileSize(path) {
                                            resource = LocalFileMediaResource(fileId: Int64.random(in: Int64.min ... Int64.max), size: size)
                                            account.postbox.mediaBox.moveResourceData(resource.id, fromTempPath: path)
                                        } else {
                                            continue outer
                                        }
                                    } else {
                                        resource = LocalFileVideoMediaResource(randomId: Int64.random(in: Int64.min ... Int64.max), path: path, adjustments: resourceAdjustments)
                                    }
                            }
                            
                            let estimatedSize = TGMediaVideoConverter.estimatedSize(for: preset, duration: finalDuration, hasAudio: !asAnimation)
                            
                            var fileAttributes: [TelegramMediaFileAttribute] = []
                            fileAttributes.append(.FileName(fileName: fileName))
                            if asAnimation {
                                fileAttributes.append(.Animated)
                            }
                            
                            // MARK: Nicegram RoundedVideos
                            let videoFlags: TelegramMediaVideoFlags = if sendAsRoundedVideo {
                                [.instantRoundVideo]
                            } else {
                                [.supportsStreaming]
                            }
                        
                            if sendAsRoundedVideo {
                                finalDimensions = NGRoundedVideos.Constants.videoSize
                            }
                            //
                        
                            if !asFile {
                                // MARK: Nicegram RoundedVideos, change to 'flags: videoFlags'
                                fileAttributes.append(.Video(duration: finalDuration, size: PixelDimensions(finalDimensions), flags: videoFlags, preloadSize: nil, coverTime: nil, videoCodec: nil))
                                if let adjustments = adjustments {
                                    if adjustments.sendAsGif {
                                        fileAttributes.append(.Animated)
                                    }
                                }
                                
                                if estimatedSize > 10 * 1024 * 1024 {
                                    fileAttributes.append(.hintFileIsLarge)
                                }
                            } else {
                                if case let .asset(asset) = data, let phAsset = asset.backingAsset, let resource = PHAssetResource.assetResources(for: phAsset).last, let sizeValue = resource.value(forKey: "fileSize") as? CLong, sizeValue > 0 {
                                    let size = Int64(bitPattern: UInt64(sizeValue))
                                    
                                    if size > 10 * 1024 * 1024 {
                                        fileAttributes.append(.hintFileIsLarge)
                                    }
                                }
                            }
                            
                            
                            var attributes: [MessageAttribute] = []
                            
                            var stickerFiles: [TelegramMediaFile] = []
                            if !stickers.isEmpty {
                                for fileReference in stickers {
                                    stickerFiles.append(fileReference.media)
                                }
                            }
                            if !stickerFiles.isEmpty {
                                attributes.append(EmbeddedMediaStickersMessageAttribute(files: stickerFiles))
                                fileAttributes.append(.HasLinkedStickers)
                            }
                            
                            let media = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: Int64.random(in: Int64.min ... Int64.max)), partialReference: nil, resource: resource, previewRepresentations: previewRepresentations, videoThumbnails: [], videoCover: videoCover, immediateThumbnailData: nil, mimeType: "video/mp4", size: nil, attributes: fileAttributes, alternativeRepresentations: [])

                            if let timer = item.timer, timer > 0 && (timer <= 60 || timer == viewOnceTimeout) {
                                attributes.append(AutoremoveTimeoutMessageAttribute(timeout: Int32(timer), countdownBeginTime: nil))
                            }
                            if let spoiler = item.spoiler, spoiler {
                                attributes.append(MediaSpoilerMessageAttribute())
                            }
                            
                            let text = trimChatInputText(convertMarkdownToAttributes(caption ?? NSAttributedString()))
                            let entities = generateTextEntities(text.string, enabledTypes: .all, currentEntities: generateChatInputTextEntities(text))
                            if !entities.isEmpty {
                                attributes.append(TextEntitiesMessageAttribute(entities: entities))
                            }
                        
                            var bubbleUpEmojiOrStickersetsById: [Int64: ItemCollectionId] = [:]
                            text.enumerateAttribute(ChatTextInputAttributes.customEmoji, in: NSRange(location: 0, length: text.length), using: { value, _, _ in
                                if let value = value as? ChatTextInputTextCustomEmojiAttribute {
                                    if let file = value.file {
                                        if let packId = value.interactivelySelectedFromPackId {
                                            bubbleUpEmojiOrStickersetsById[file.fileId.id] = packId
                                        }
                                    }
                                }
                            })
                            var bubbleUpEmojiOrStickersets: [ItemCollectionId] = []
                            for entity in entities {
                                if case let .CustomEmoji(_, fileId) = entity.type {
                                    if let packId = bubbleUpEmojiOrStickersetsById[fileId] {
                                        if !bubbleUpEmojiOrStickersets.contains(packId) {
                                            bubbleUpEmojiOrStickersets.append(packId)
                                        }
                                    }
                                }
                            }
                        
                            // MARK: Nicegram RoundedVideos
                            let localGroupingKey: Int64? = if sendAsRoundedVideo {
                                nil
                            } else {
                                item.groupedId
                            }
                        
                            let messageText = if sendAsRoundedVideo {
                                ""
                            } else {
                                text.string
                            }
                            //
                            
                            if let price = item.price {
                                if var current = paidMessage {
                                    if current.text.isEmpty && !text.string.isEmpty {
                                        current.text = text.string
                                        current.entities = entities
                                    }
                                    current.media.append(media)
                                    paidMessage = current
                                } else {
                                    paidMessage = EnqueuePaidMessage(
                                        price: price,
                                        text: text.string,
                                        entities: entities,
                                        media: [media]
                                    )
                                }
                            } else {
                                // MARK: Nicegram RoundedVideos, change (text, localGroupingKey)
                                messages.append(LegacyAssetPickerEnqueueMessage(message: .message(text: messageText, attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: media), threadId: nil, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: localGroupingKey, correlationId: nil, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets), uniqueId: item.uniqueId, isFile: asFile))
                                
                                // MARK: Nicegram RoundedVideos
                                if sendAsRoundedVideo {
                                    let videoMessageText = text
                                        .string
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                    
                                    if !videoMessageText.isEmpty {
                                        var uniqueId = item.uniqueId
                                        uniqueId?.append("-text")
                                        messages.append(LegacyAssetPickerEnqueueMessage(message: .message(text: videoMessageText, attributes: [], inlineStickers: [:], mediaReference: nil, threadId: nil, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: localGroupingKey, correlationId: nil, bubbleUpEmojiOrStickersets: []), uniqueId: uniqueId, isFile: false))
                                    }
                                }
                                //
                            }
                    }
                }
            }
            
            if let paidMessage {
                var attributes: [MessageAttribute] = []
                if !paidMessage.entities.isEmpty {
                    attributes.append(TextEntitiesMessageAttribute(entities: paidMessage.entities))
                }
                messages.append(
                    LegacyAssetPickerEnqueueMessage(
                        message: .message(
                            text: paidMessage.text,
                            attributes: attributes,
                            inlineStickers: [:],
                            mediaReference: .standalone(
                                media: TelegramMediaPaidContent(
                                    amount: paidMessage.price,
                                    extendedMedia: paidMessage.media.map { .full(media: $0) }
                                )),
                            threadId: nil,
                            replyToMessageId: nil,
                            replyToStoryId: nil,
                            localGroupingKey: nil,
                            correlationId: nil,
                            bubbleUpEmojiOrStickersets: []
                        ),
                        uniqueId: nil,
                        isFile: false
                    )
                )
            }
            
            subscriber.putNext(messages)
            subscriber.putCompletion()
        }, error: { _ in
            subscriber.putError(Void())
        }, completed: nil)
        
        return ActionDisposable {
            disposable?.dispose()
        }
    }
}
