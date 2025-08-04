import Foundation
import UIKit
import TelegramCore
import Postbox
import SwiftSignalKit
import TelegramUIPreferences
import RangeSet

public func freeMediaFileInteractiveFetched(account: Account, userLocation: MediaResourceUserLocation, fileReference: FileMediaReference) -> Signal<FetchResourceSourceType, FetchResourceError> {
    return fetchedMediaResource(mediaBox: account.postbox.mediaBox, userLocation: userLocation, userContentType: MediaResourceUserContentType(file: fileReference.media), reference: fileReference.resourceReference(fileReference.media.resource))
}
// Nicegram downloading feature
public func freeMediaFileInteractiveFetched(fetchManager: FetchManager, fileReference: FileMediaReference, priority: FetchManagerPriority, accountContext: AccountContext?) -> Signal<Void, NoError> {
    let file = fileReference.media
    let mediaReference = AnyMediaReference.standalone(media: fileReference.media)
    // Nicegram downloading feature, 'accountContext, shouldSave' params added
    return fetchManager.interactivelyFetched(category: fetchCategoryForFile(file), location: .chat(PeerId(0)), locationKey: .free, mediaReference: mediaReference, resourceReference: mediaReference.resourceReference(file.resource), ranges: RangeSet<Int64>(0 ..< Int64.max), statsCategory: statsCategoryForFileWithAttributes(file.attributes), elevatedPriority: false, userInitiated: false, priority: priority, storeToDownloadsPeerId: nil, accountContext: accountContext, shouldSave: false)
}

public func freeMediaFileResourceInteractiveFetched(account: Account, userLocation: MediaResourceUserLocation, fileReference: FileMediaReference, resource: MediaResource) -> Signal<FetchResourceSourceType, FetchResourceError> {
    return fetchedMediaResource(mediaBox: account.postbox.mediaBox, userLocation: userLocation, userContentType: MediaResourceUserContentType(file: fileReference.media), reference: fileReference.resourceReference(resource))
}

public func freeMediaFileResourceInteractiveFetched(postbox: Postbox, userLocation: MediaResourceUserLocation, fileReference: FileMediaReference, resource: MediaResource, range: (Range<Int64>, MediaBoxFetchPriority)? = nil) -> Signal<FetchResourceSourceType, FetchResourceError> {
    return fetchedMediaResource(mediaBox: postbox.mediaBox, userLocation: userLocation, userContentType: MediaResourceUserContentType(file: fileReference.media), reference: fileReference.resourceReference(resource), range: range)
}

public func cancelFreeMediaFileInteractiveFetch(account: Account, file: TelegramMediaFile) {
    account.postbox.mediaBox.cancelInteractiveResourceFetch(file.resource)
}

private func fetchCategoryForFile(_ file: TelegramMediaFile) -> FetchManagerCategory {
    if file.isVoice || file.isInstantVideo {
        return .voice
    } else if file.isAnimated {
        return .animation
    } else {
        return .file
    }
}
// Nicegram downloading feature
public func messageMediaFileInteractiveFetched(context: AccountContext, message: Message, file: TelegramMediaFile, userInitiated: Bool, storeToDownloadsPeerId: EnginePeer.Id? = nil, shouldSave: Bool = false) -> Signal<Void, NoError> {
    // Nicegram downloading feature, 'accountContext, shouldSave' params added
    return messageMediaFileInteractiveFetched(fetchManager: context.fetchManager, messageId: message.id, messageReference: MessageReference(message), file: file, userInitiated: userInitiated, priority: .userInitiated, storeToDownloadsPeerId: storeToDownloadsPeerId, accountContext: context, shouldSave: shouldSave)
}
// Nicegram downloading feature, 'accountContext, shouldSave' params added
public func messageMediaFileInteractiveFetched(fetchManager: FetchManager, messageId: MessageId, messageReference: MessageReference, file: TelegramMediaFile, ranges: RangeSet<Int64> = RangeSet<Int64>(0 ..< Int64.max), userInitiated: Bool, priority: FetchManagerPriority, storeToDownloadsPeerId: EnginePeer.Id? = nil, accountContext: AccountContext?, shouldSave: Bool = false) -> Signal<Void, NoError> {
    let mediaReference = AnyMediaReference.message(message: messageReference, media: file)
    // Nicegram downloading feature, 'accountContext, shouldSave' params added
    return fetchManager.interactivelyFetched(category: fetchCategoryForFile(file), location: .chat(messageId.peerId), locationKey: .messageId(messageId), mediaReference: mediaReference, resourceReference: mediaReference.resourceReference(file.resource), ranges: ranges, statsCategory: statsCategoryForFileWithAttributes(file.attributes), elevatedPriority: false, userInitiated: userInitiated, priority: priority, storeToDownloadsPeerId: storeToDownloadsPeerId, accountContext: accountContext, shouldSave: shouldSave)
}

public func messageMediaFileCancelInteractiveFetch(context: AccountContext, messageId: MessageId, file: TelegramMediaFile) {
    context.fetchManager.cancelInteractiveFetches(category: fetchCategoryForFile(file), location: .chat(messageId.peerId), locationKey: .messageId(messageId), resource: file.resource)
}

public func messageMediaImageInteractiveFetched(context: AccountContext, message: Message, image: TelegramMediaImage, resource: MediaResource, range: Range<Int64>? = nil, userInitiated: Bool = true, storeToDownloadsPeerId: EnginePeer.Id?) -> Signal<Void, NoError> {
    return messageMediaImageInteractiveFetched(fetchManager: context.fetchManager, messageId: message.id, messageReference: MessageReference(message), image: image, resource: resource, range: range, userInitiated: userInitiated, priority: .userInitiated, storeToDownloadsPeerId: storeToDownloadsPeerId)
}

public func messageMediaImageInteractiveFetched(fetchManager: FetchManager, messageId: MessageId, messageReference: MessageReference, image: TelegramMediaImage, resource: MediaResource, range: Range<Int64>? = nil, userInitiated: Bool, priority: FetchManagerPriority, storeToDownloadsPeerId: EnginePeer.Id?) -> Signal<Void, NoError> {
    let mediaReference = AnyMediaReference.message(message: messageReference, media: image)
    let ranges: RangeSet<Int64>
    if let range = range {
        ranges = RangeSet(range.lowerBound ..< range.upperBound)
    } else {
        ranges = RangeSet(0 ..< Int64.max)
    }
    // Nicegram downloading feature, 'accountContext, shouldSave' params added
    return fetchManager.interactivelyFetched(category: .image, location: .chat(messageId.peerId), locationKey: .messageId(messageId), mediaReference: mediaReference, resourceReference: mediaReference.resourceReference(resource), ranges: ranges, statsCategory: .image, elevatedPriority: false, userInitiated: userInitiated, priority: priority, storeToDownloadsPeerId: storeToDownloadsPeerId, accountContext: nil, shouldSave: false)
}

public func messageMediaImageCancelInteractiveFetch(context: AccountContext, messageId: MessageId, image: TelegramMediaImage, resource: MediaResource) {
    context.fetchManager.cancelInteractiveFetches(category: .image, location: .chat(messageId.peerId), locationKey: .messageId(messageId), resource: resource)
}

public func messageMediaFileStatus(context: AccountContext, messageId: MessageId, file: TelegramMediaFile, adjustForVideoThumbnail: Bool = false) -> Signal<MediaResourceStatus, NoError> {
    let fileStatus = context.fetchManager.fetchStatus(category: fetchCategoryForFile(file), location: .chat(messageId.peerId), locationKey: .messageId(messageId), resource: file.resource)
    if !adjustForVideoThumbnail {
        return fileStatus
    }
    
    var thumbnailStatus: Signal<MediaResourceStatus?, NoError> = .single(nil)
    if let videoThumbnail = file.videoThumbnails.first {
        thumbnailStatus = context.account.postbox.mediaBox.resourceStatus(videoThumbnail.resource)
        |> map(Optional.init)
    }
    
    return combineLatest(queue: context.fetchManager.queue,
        fileStatus,
        thumbnailStatus
    )
    |> map { fileStatus, thumbnailStatus -> MediaResourceStatus in
        guard let thumbnailStatus = thumbnailStatus else {
            return fileStatus
        }
        if case .Local = thumbnailStatus {
            return thumbnailStatus
        } else {
            return fileStatus
        }
    }
    |> distinctUntilChanged
}

public func messageMediaImageStatus(context: AccountContext, messageId: MessageId, image: TelegramMediaImage) -> Signal<MediaResourceStatus, NoError> {
    guard let representation = image.representations.last else {
        return .single(.Remote(progress: 0.0))
    }
    return context.fetchManager.fetchStatus(category: .image, location: .chat(messageId.peerId), locationKey: .messageId(messageId), resource: representation.resource)
}
