import LegacyComponents

public func canSendAsRoundedVideo(
    currentItem: TGMediaPickerGalleryItem?,
    editingContext: TGMediaEditingContext?,
    selectionContext: TGMediaSelectionContext?
) -> Bool {
    guard let editingContext, let selectionContext else {
        return false
    }
    
    var hasVideo = false
    for case let item as TGMediaEditableItem in selectionContext.selectedItems() {
        if item.isVideo {
            hasVideo = true
            break
        }
    }
    if let currentItem, currentItem.asset.isVideo {
        hasVideo = true
    }
    
    var hasSpoilers = false
    for case let item as TGMediaEditableItem in selectionContext.selectedItems() {
        if editingContext.spoiler(for: item) {
            hasSpoilers = true
            break
        }
    }
    
    return hasVideo && !hasSpoilers
}
