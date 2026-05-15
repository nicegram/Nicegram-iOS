# Postbox → TelegramEngine Wave 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three thin forwarding methods on `TelegramEngine.Resources` for fetch/status/data, then migrate `SaveToCameraRoll` to use them, drop `import Postbox` from that module, and update all 23 call sites.

**Architecture:** Two atomic commits on branch `refactor/postbox-to-engine-wave-3`. C1 adds the facades in isolation. C2 changes `SaveToCameraRoll`'s public API (drops the `postbox:` parameter, switches `FetchMediaDataState.data` payload from `MediaResourceData` to `EngineMediaResource.ResourceData`), rewrites the module's internals via `context.engine.resources.*`, removes `import Postbox`, and updates every caller in the same commit so the tree remains buildable.

**Tech Stack:** Swift / Bazel. No unit tests exist in this repo — verification is a full project build.

**Spec:** [docs/superpowers/specs/2026-04-18-postbox-to-telegramengine-wave-3-design.md](docs/superpowers/specs/2026-04-18-postbox-to-telegramengine-wave-3-design.md)

**Build command (use for every "full build" step):**

```bash
source ~/.zshrc 2>/dev/null; PATH=/opt/homebrew/opt/ruby/bin:`gem environment gemdir`/bin:$PATH python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber 1 --configuration debug_sim_arm64
```

The prefix `source ~/.zshrc 2>/dev/null;` is required because `TELEGRAM_CODESIGNING_GIT_PASSWORD` lives in `~/.zshrc` and the bash tool does not source shell config by default.

---

## Task 1: Add `TelegramEngine.Resources.fetch/status/data` facades (C1)

**Files:**
- Modify: [submodules/TelegramCore/Sources/TelegramEngine/Resources/TelegramEngineResources.swift:415-417](submodules/TelegramCore/Sources/TelegramEngine/Resources/TelegramEngineResources.swift#L415)

- [ ] **Step 1: Insert the three facade methods**

Open `submodules/TelegramCore/Sources/TelegramEngine/Resources/TelegramEngineResources.swift`. Find the existing `applicationIcons()` method (currently the last method in the `Resources` class). Insert the three new methods immediately after it, still inside the `final class Resources` brace (before the closing `}`):

```swift
        public func applicationIcons() -> Signal<TelegramApplicationIcons, NoError> {
            return _internal_applicationIcons(account: account)
        }

        public func fetch(
            reference: MediaResourceReference,
            userLocation: MediaResourceUserLocation,
            userContentType: MediaResourceUserContentType
        ) -> Signal<FetchResourceSourceType, FetchResourceError> {
            return fetchedMediaResource(
                mediaBox: self.account.postbox.mediaBox,
                userLocation: userLocation,
                userContentType: userContentType,
                reference: reference
            )
        }

        public func status(
            resource: EngineMediaResource
        ) -> Signal<EngineMediaResource.FetchStatus, NoError> {
            return self.account.postbox.mediaBox.resourceStatus(resource._asResource())
            |> map { EngineMediaResource.FetchStatus($0) }
        }

        public func data(
            resource: EngineMediaResource,
            pathExtension: String?,
            waitUntilFetchStatus: Bool
        ) -> Signal<EngineMediaResource.ResourceData, NoError> {
            return self.account.postbox.mediaBox.resourceData(
                resource._asResource(),
                pathExtension: pathExtension,
                option: .complete(waitUntilFetchStatus: waitUntilFetchStatus)
            )
            |> map { EngineMediaResource.ResourceData($0) }
        }
    }
}
```

- [ ] **Step 2: Full build — verify C1 compiles cleanly**

Run the build command from the header. Expected: build succeeds with no errors. If a `signature mismatch` or `cannot find 'fetchedMediaResource'` error appears, double-check that `FetchedMediaResource.swift` and `MediaBox.swift` already export the referenced symbols (they do as of this plan's writing — no import changes are needed in `TelegramEngineResources.swift`, which already imports `Postbox`, `SwiftSignalKit`, and `TelegramApi`).

- [ ] **Step 3: Commit C1**

```bash
git add submodules/TelegramCore/Sources/TelegramEngine/Resources/TelegramEngineResources.swift
git commit -m "$(cat <<'EOF'
TelegramEngine.Resources: add fetch/status/data facades

Thin forwarders over MediaBox for the narrow surface SaveToCameraRoll
needs. Takes EngineMediaResource and returns EngineMediaResource-typed
results where applicable. Wave-3 groundwork.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Pre-flight — re-inventory call sites and verify ShareController postbox

No code changes in this task. Its purpose is to catch drift from the spec's inventory before editing code, per CLAUDE.md's "inventory at execution time" guidance.

**Files:** (read-only)
- Spec inventory: [docs/superpowers/specs/2026-04-18-postbox-to-telegramengine-wave-3-design.md](docs/superpowers/specs/2026-04-18-postbox-to-telegramengine-wave-3-design.md)
- Definition to verify: `submodules/ShareController/Sources/ShareController.swift` around line 2403 and `ShareControllerAppAccountContext`

- [ ] **Step 1: Re-grep the current call-site set**

Run:

```bash
grep -rnE "(fetchMediaData|saveToCameraRoll|copyToPasteboard)\(" submodules --include="*.swift" \
  | grep -v "SaveToCameraRoll/Sources/SaveToCameraRoll.swift" \
  | grep -v "private func saveToCameraRoll" \
  | grep -v "self\?\.saveToCameraRoll\|strongSelf\.saveToCameraRoll"
```

Expected output has exactly 23 lines across 14 files, matching the spec's inventory table:

| Module | File | Expected count |
|---|---|---|
| InstantPageUI | `Sources/InstantPageControllerNode.swift` | 2 |
| LegacyMediaPickerUI | `Sources/LegacyAttachmentMenu.swift` | 2 |
| LegacyMediaPickerUI | `Sources/LegacyAvatarPicker.swift` | 2 |
| BrowserUI | `Sources/BrowserInstantPageContent.swift` | 2 |
| GalleryUI | `Sources/Items/ChatImageGalleryItem.swift` | 2 |
| GalleryUI | `Sources/Items/UniversalVideoGalleryItem.swift` | 3 |
| TelegramUI (MediaEditorScreen) | `Components/MediaEditorScreen/Sources/MediaEditorScreen.swift` | 1 |
| TelegramUI (MediaEditorScreen) | `Components/MediaEditorScreen/Sources/EditStories.swift` | 1 |
| TelegramUI (ChatQrCodeScreen) | `Components/Chat/ChatQrCodeScreen/Sources/ChatQrCodeScreen.swift` | 1 |
| TelegramUI (StoryContainer) | `Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerComponent.swift` | 1 |
| TelegramUI (PeerInfoStoryGrid) | `Components/PeerInfo/PeerInfoStoryGridScreen/Sources/PeerInfoStoryGridScreen.swift` | 1 |
| TelegramUI | `Sources/ChatInterfaceStateContextMenus.swift` | 1 |
| TelegramUI | `Sources/SaveMediaToFiles.swift` | 1 |
| ShareController | `Sources/ShareController.swift` | 3 |

If the count or file list has drifted meaningfully from this table, **stop**, report the drift, and request a spec revision before continuing. Additions of one or two call sites can be folded in; larger drift should pause the wave.

- [ ] **Step 2: Verify `ShareController:2406` postbox equivalence**

Read `submodules/ShareController/Sources/ShareController.swift` lines 2395–2420. The private helper `saveToCameraRoll(messages:completion:)` contains `let postbox = self.currentContext.stateManager.postbox` and passes it to `SaveToCameraRoll.saveToCameraRoll`. After the migration, `SaveToCameraRoll` will use `context.account.postbox.mediaBox` internally.

The enclosing function gates on `self.currentContext as? ShareControllerAppAccountContext`. In that code path, `accountContext.context.account` is the `Account` that `ShareControllerAppAccountContext` was built from, and `self.currentContext.stateManager` is that same account's state manager. Therefore `accountContext.context.account.postbox === self.currentContext.stateManager.postbox`.

Confirm this by reading the definition of `ShareControllerAppAccountContext` in `submodules/AccountContext/Sources/ShareController.swift` (or the file where it's defined — grep for `ShareControllerAppAccountContext` to locate). If the `stateManager` there is derived from the same `account` whose `postbox` is reachable via `context.account.postbox`, treat the two as equivalent and proceed. If they can diverge (e.g., share-extension account switching creates a separate state manager), **stop** and abandon the ShareController:2406 edit with a recorded reason before continuing — the rest of the wave still applies.

- [ ] **Step 3: Record verification outcome**

Write a one-line note in the executor's task log noting either "ShareController:2406 postbox equivalence confirmed" or "ShareController:2406 abandoned — reason: ...". No commit.

---

## Task 3: Migrate `SaveToCameraRoll` module

This task changes the module's public API and internals. Build will fail after this task because all callers are still passing `postbox:` — that's expected and will be fixed in Task 4, which must land in the same commit as this task.

**Files:**
- Modify: [submodules/SaveToCameraRoll/Sources/SaveToCameraRoll.swift](submodules/SaveToCameraRoll/Sources/SaveToCameraRoll.swift) (entire file rewritten as shown below)

- [ ] **Step 1: Rewrite `SaveToCameraRoll.swift`**

Replace the file's contents with:

```swift
import Foundation
import UIKit
import SwiftSignalKit
import TelegramCore
import Photos
import Display
import MobileCoreServices
import DeviceAccess
import AccountContext
import LegacyComponents

public enum FetchMediaDataState {
    case progress(Float)
    case data(EngineMediaResource.ResourceData)
}

public func fetchMediaData(context: AccountContext, userLocation: MediaResourceUserLocation, customUserContentType: MediaResourceUserContentType? = nil, mediaReference: AnyMediaReference, forceVideo: Bool = false) -> Signal<(FetchMediaDataState, Bool), NoError> {
    var resource: TelegramMediaResource?
    var isImage = true
    var fileExtension: String?
    var userContentType: MediaResourceUserContentType = .other
    if let image = mediaReference.media as? TelegramMediaImage {
        userContentType = .image
        if let video = image.videoRepresentations.last, forceVideo {
            resource = video.resource
            isImage = false
        } else if let representation = largestImageRepresentation(image.representations) {
            resource = representation.resource
        }
    } else if let file = mediaReference.media as? TelegramMediaFile {
        userContentType = MediaResourceUserContentType(file: file)
        resource = file.resource
        if file.isVideo || file.mimeType.hasPrefix("video/") {
            isImage = false
        }
        let maybeExtension = ((file.fileName ?? "") as NSString).pathExtension
        if !maybeExtension.isEmpty {
            fileExtension = maybeExtension
        }
    } else if let webpage = mediaReference.media as? TelegramMediaWebpage, case let .Loaded(content) = webpage.content {
        if let file = content.file {
            resource = file.resource
            if file.isVideo {
                isImage = false
            }
        } else if let image = content.image {
            if let representation = largestImageRepresentation(image.representations) {
                resource = representation.resource
            }
        }
    }
    if let customUserContentType {
        userContentType = customUserContentType
    }
    
    if let resource = resource {
        let engineResource = EngineMediaResource(resource)
        let fetchedData: Signal<FetchMediaDataState, NoError> = Signal { subscriber in
            let fetched = context.engine.resources.fetch(
                reference: mediaReference.resourceReference(resource),
                userLocation: userLocation,
                userContentType: userContentType
            ).start()
            let status = context.engine.resources.status(resource: engineResource).start(next: { status in
                switch status {
                    case .Local:
                        subscriber.putNext(.progress(1.0))
                    case .Remote:
                        subscriber.putNext(.progress(0.0))
                    case let .Fetching(_, progress):
                        subscriber.putNext(.progress(progress))
                    case let .Paused(progress):
                        subscriber.putNext(.progress(progress))
                }
            })
            let data = context.engine.resources.data(
                resource: engineResource,
                pathExtension: fileExtension,
                waitUntilFetchStatus: true
            ).start(next: { next in
                subscriber.putNext(.data(next))
            }, completed: {
                subscriber.putCompletion()
            })
            return ActionDisposable {
                fetched.dispose()
                status.dispose()
                data.dispose()
            }
        }
        return fetchedData
        |> map { data in
            return (data, isImage)
        }
    } else {
        return .complete()
    }
}

public func saveToCameraRoll(context: AccountContext, userLocation: MediaResourceUserLocation, customUserContentType: MediaResourceUserContentType? = nil, mediaReference: AnyMediaReference, video: AnyMediaReference? = nil) -> Signal<Float, NoError> {
    let mediaData: Signal<(FetchMediaDataState, Bool), NoError> = fetchMediaData(context: context, userLocation: userLocation, customUserContentType: customUserContentType, mediaReference: mediaReference)
    let videoData: Signal<FetchMediaDataState?, NoError>
    if let video {
        videoData = fetchMediaData(context: context, userLocation: userLocation, customUserContentType: customUserContentType, mediaReference: video)
        |> map { state, _ in
            return state
        }
        |> map(Optional.init)
    } else {
        videoData = .single(nil)
    }
    
    return combineLatest(
        queue: Queue.mainQueue(),
        mediaData,
        videoData
    )
    |> mapToSignal { stateAndIsImage, videoStateAndIsImage -> Signal<Float, NoError> in
        let isImage = stateAndIsImage.1
        var mainData: EngineMediaResource.ResourceData?
        var videoData: EngineMediaResource.ResourceData?
        var waitForVideo = false
        if let videoState = videoStateAndIsImage {
            switch videoState {
            case let .progress(value):
                return .single(value * 0.95)
            case let .data(data):
                videoData = data
            }
            switch stateAndIsImage.0 {
            case let .progress(value):
                return .single(0.95 + 0.05 * value)
            case let .data(data):
                mainData = data
            }
            waitForVideo = true
        } else {
            switch stateAndIsImage.0 {
            case let .progress(value):
                return .single(value)
            case let .data(data):
                mainData = data
            }
        }
        if let mainData, mainData.isComplete, videoData != nil || !waitForVideo {
            return Signal<Float, NoError> { subscriber in
                DeviceAccess.authorizeAccess(to: .mediaLibrary(.save), presentationData: context.sharedContext.currentPresentationData.with { $0 }, present: { c, a in
                    context.sharedContext.presentGlobalController(c, a)
                }, openSettings: context.sharedContext.applicationBindings.openSettings, { authorized in
                    if !authorized {
                        subscriber.putCompletion()
                        return
                    }
                    
                    let tempVideoPath = NSTemporaryDirectory() + "\(Int64.random(in: Int64.min ... Int64.max)).mp4"
                    if isImage, let videoData, let imageData = try? Data(contentsOf: URL(fileURLWithPath: mainData.path)) {
                        let id = UUID().uuidString

                        let jpegWithID = addAssetIdentifierToJPEG(imageData, assetIdentifier: id)!
                        let outputVideoURL = URL(fileURLWithPath: NSTemporaryDirectory() + "\(id).mov")
                        
                        try? FileManager.default.copyItem(atPath: videoData.path, toPath: tempVideoPath)
                        
                        addAssetIdentifierToVideo(inputURL: URL(fileURLWithPath: tempVideoPath), outputURL: outputVideoURL, assetIdentifier: id) { success in
                            guard success else { return }

                            PHPhotoLibrary.shared().performChanges({
                                let request = PHAssetCreationRequest.forAsset()

                                request.addResource(with: .photo, data: jpegWithID, options: nil)
                                request.addResource(with: .pairedVideo, fileURL: outputVideoURL, options: nil)
                            }, completionHandler: { _, error in
                                let _ = try? FileManager.default.removeItem(atPath: tempVideoPath)
                                subscriber.putNext(1.0)
                                subscriber.putCompletion()
                            })
                        }
                    } else {
                        PHPhotoLibrary.shared().performChanges({
                            if isImage {
                                if let imageData = try? Data(contentsOf: URL(fileURLWithPath: mainData.path)) {
                                    PHAssetCreationRequest.forAsset().addResource(with: .photo, data: imageData, options: nil)
                                }
                            } else {
                                if let _ = try? FileManager.default.copyItem(atPath: mainData.path, toPath: tempVideoPath) {
                                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: tempVideoPath))
                                }
                            }
                        }, completionHandler: { _, error in
                            if let error {
                                print("\(error)")
                            }
                            let _ = try? FileManager.default.removeItem(atPath: tempVideoPath)
                            subscriber.putNext(1.0)
                            subscriber.putCompletion()
                        })
                    }
                })
                
                return ActionDisposable {
                }
            }
        } else {
            return .complete()
        }
    }
}

public func copyToPasteboard(context: AccountContext, userLocation: MediaResourceUserLocation, mediaReference: AnyMediaReference) -> Signal<Void, NoError> {
    return fetchMediaData(context: context, userLocation: userLocation, mediaReference: mediaReference)
    |> mapToSignal { state, isImage -> Signal<Void, NoError> in
        if case let .data(data) = state, data.isComplete {
            return Signal<Void, NoError> { subscriber in
                let pasteboard = UIPasteboard.general
                
                if mediaReference.media is TelegramMediaImage {
                    if let fileData = try? Data(contentsOf: URL(fileURLWithPath: data.path), options: .mappedIfSafe) {
                        pasteboard.setData(fileData, forPasteboardType: kUTTypeJPEG as String)
                    }
                }
                subscriber.putNext(Void())
                subscriber.putCompletion()
                
                return EmptyDisposable
            }
        } else {
            return .complete()
        }
    }
    |> mapToSignal { _ -> Signal<Void, NoError> in return .complete() }
}

private func addAssetIdentifierToJPEG(_ imageData: Data, assetIdentifier: String) -> Data? {
    guard let source = CGImageSourceCreateWithData(imageData as CFData, nil), let uti = CGImageSourceGetType(source), let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        return nil
    }

    let mutableData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(mutableData, uti, 1, nil) else {
        return nil
    }

    var metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] ?? [:]

    var maker = metadata[kCGImagePropertyMakerAppleDictionary as String] as? [String: Any] ?? [:]
    maker["17"] = assetIdentifier
    metadata[kCGImagePropertyMakerAppleDictionary as String] = maker

    CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)
    CGImageDestinationFinalize(destination)

    return mutableData as Data
}

private func addAssetIdentifierToVideo(inputURL: URL, outputURL: URL, assetIdentifier: String, completion: @escaping (Bool) -> Void) {
    let asset = AVAsset(url: inputURL)

    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
        completion(false)
        return
    }

    let identifierItem = AVMutableMetadataItem()
    identifierItem.keySpace = .quickTimeMetadata
    identifierItem.key = AVMetadataKey.quickTimeMetadataKeyContentIdentifier as NSString
    identifierItem.value = assetIdentifier as NSString

    let stillImageTimeItem = AVMutableMetadataItem()
    let keyStillImageTime = "com.apple.quicktime.still-image-time"
    let keySpaceQuickTimeMetadata = "mdta"
    stillImageTimeItem.key = keyStillImageTime as (NSCopying & NSObjectProtocol)?
    stillImageTimeItem.keySpace = AVMetadataKeySpace(rawValue: keySpaceQuickTimeMetadata)
    stillImageTimeItem.value = 0 as (NSCopying & NSObjectProtocol)?
    stillImageTimeItem.dataType = "com.apple.metadata.datatype.int8"

    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mov
    exportSession.metadata = [identifierItem, stillImageTimeItem]
    exportSession.shouldOptimizeForNetworkUse = true

    exportSession.exportAsynchronously {
        completion(exportSession.status == .completed)
    }
}
```

The key differences from the original file:

1. `import Postbox` — removed.
2. `FetchMediaDataState.data(MediaResourceData)` → `FetchMediaDataState.data(EngineMediaResource.ResourceData)`.
3. Three public functions drop their `postbox: Postbox` parameter.
4. `var resource: MediaResource?` → `var resource: TelegramMediaResource?`.
5. Inside `fetchMediaData`: build an `EngineMediaResource(resource)` once, and call `context.engine.resources.fetch / status / data` instead of `fetchedMediaResource(...)` / `postbox.mediaBox.resourceStatus(...)` / `postbox.mediaBox.resourceData(...)`.
6. `var mainData: MediaResourceData?` / `var videoData: MediaResourceData?` → `var ...: EngineMediaResource.ResourceData?`.
7. `mainData.complete` → `mainData.isComplete`. `data.complete` (in `copyToPasteboard`) → `data.isComplete`. Field `data.path` is unchanged.

- [ ] **Step 2: Do not build yet — proceed to Task 4**

Builds will fail until every caller in Task 4 is migrated. Do not run the build command here. No commit yet either — Task 3 and Task 4 share a single atomic commit in Task 5.

---

## Task 4: Update all 23 call sites

Every call site does one or both of two edits:

- **Edit A (all 23 sites):** drop `postbox: someExpression,` from the argument list.
- **Edit B (the 7 sites that destructure `fetchMediaData`):** rename `.complete` → `.isComplete` on the destructured data value; `.path` stays the same.

Each sub-step below is one file. No builds between files. No commit. Task 5 builds everything together.

**Sub-task 4.1 — InstantPageUI**

- [ ] **File:** [submodules/InstantPageUI/Sources/InstantPageControllerNode.swift](submodules/InstantPageUI/Sources/InstantPageControllerNode.swift)

At line 1027, replace:

```swift
                let _ = copyToPasteboard(context: strongSelf.context, postbox: strongSelf.context.account.postbox, userLocation: strongSelf.sourceLocation.userLocation, mediaReference: .standalone(media: media)).start()
```

with:

```swift
                let _ = copyToPasteboard(context: strongSelf.context, userLocation: strongSelf.sourceLocation.userLocation, mediaReference: .standalone(media: media)).start()
```

At line 1032, replace:

```swift
                let _ = saveToCameraRoll(context: strongSelf.context, postbox: strongSelf.context.account.postbox, userLocation: strongSelf.sourceLocation.userLocation, mediaReference: .standalone(media: media)).start()
```

with:

```swift
                let _ = saveToCameraRoll(context: strongSelf.context, userLocation: strongSelf.sourceLocation.userLocation, mediaReference: .standalone(media: media)).start()
```

**Sub-task 4.2 — LegacyMediaPickerUI / LegacyAttachmentMenu.swift** (destructures)

- [ ] **File:** [submodules/LegacyMediaPickerUI/Sources/LegacyAttachmentMenu.swift](submodules/LegacyMediaPickerUI/Sources/LegacyAttachmentMenu.swift)

At line 173, replace:

```swift
    let _ = (fetchMediaData(context: context, postbox: context.account.postbox, userLocation: .other, mediaReference: media)
```

with:

```swift
    let _ = (fetchMediaData(context: context, userLocation: .other, mediaReference: media)
```

In the `.start` block that follows (around line 175), replace `data.complete` with `data.isComplete` (only the `.complete` boolean access — do not touch `data.path`).

At line 490, replace:

```swift
            let _ = (fetchMediaData(context: context, postbox: context.account.postbox, userLocation: .other, mediaReference: editCurrentMedia)
```

with:

```swift
            let _ = (fetchMediaData(context: context, userLocation: .other, mediaReference: editCurrentMedia)
```

In the destructuring block that follows (around line 492), replace `data.complete` with `data.isComplete`.

**Sub-task 4.3 — LegacyMediaPickerUI / LegacyAvatarPicker.swift** (destructures)

- [ ] **File:** [submodules/LegacyMediaPickerUI/Sources/LegacyAvatarPicker.swift](submodules/LegacyMediaPickerUI/Sources/LegacyAvatarPicker.swift)

At line 58, replace:

```swift
    let imageSignal = fetchMediaData(context: context, postbox: context.account.postbox, userLocation: .other, mediaReference: media, forceVideo: false)
```

with:

```swift
    let imageSignal = fetchMediaData(context: context, userLocation: .other, mediaReference: media, forceVideo: false)
```

In the `|> map` block immediately after (line ~60), replace `data.complete` with `data.isComplete`.

At line 67, replace:

```swift
    let videoSignal = isVideo ? fetchMediaData(context: context, postbox: context.account.postbox, userLocation: .other, mediaReference: media, forceVideo: true)
```

with:

```swift
    let videoSignal = isVideo ? fetchMediaData(context: context, userLocation: .other, mediaReference: media, forceVideo: true)
```

In the `|> map` block immediately after (line ~69), replace `data.complete` with `data.isComplete`.

**Sub-task 4.4 — BrowserUI / BrowserInstantPageContent.swift**

- [ ] **File:** [submodules/BrowserUI/Sources/BrowserInstantPageContent.swift](submodules/BrowserUI/Sources/BrowserInstantPageContent.swift)

At line 1175, replace:

```swift
                let _ = copyToPasteboard(context: self.context, postbox: self.context.account.postbox, userLocation: self.sourceLocation.userLocation, mediaReference: .standalone(media: media)).start()
```

with:

```swift
                let _ = copyToPasteboard(context: self.context, userLocation: self.sourceLocation.userLocation, mediaReference: .standalone(media: media)).start()
```

At line 1180, replace:

```swift
                let _ = saveToCameraRoll(context: self.context, postbox: self.context.account.postbox, userLocation: self.sourceLocation.userLocation, mediaReference: .standalone(media: media)).start()
```

with:

```swift
                let _ = saveToCameraRoll(context: self.context, userLocation: self.sourceLocation.userLocation, mediaReference: .standalone(media: media)).start()
```

**Sub-task 4.5 — GalleryUI / ChatImageGalleryItem.swift** (one destructures)

- [ ] **File:** [submodules/GalleryUI/Sources/Items/ChatImageGalleryItem.swift](submodules/GalleryUI/Sources/Items/ChatImageGalleryItem.swift)

At line 732, replace:

```swift
                        let _ = (fetchMediaData(context: context, postbox: context.account.postbox, userLocation: .other, mediaReference: media)
```

with:

```swift
                        let _ = (fetchMediaData(context: context, userLocation: .other, mediaReference: media)
```

In the `.start` block that follows (around line 734), replace `data.complete` with `data.isComplete`.

At line 758, replace:

```swift
                        let _ = (SaveToCameraRoll.saveToCameraRoll(context: context, postbox: context.account.postbox, userLocation: .peer(message.id.peerId), mediaReference: media)
```

with:

```swift
                        let _ = (SaveToCameraRoll.saveToCameraRoll(context: context, userLocation: .peer(message.id.peerId), mediaReference: media)
```

**Sub-task 4.6 — GalleryUI / UniversalVideoGalleryItem.swift**

- [ ] **File:** [submodules/GalleryUI/Sources/Items/UniversalVideoGalleryItem.swift](submodules/GalleryUI/Sources/Items/UniversalVideoGalleryItem.swift)

At line 3764, replace:

```swift
                                        let saveSignal = SaveToCameraRoll.saveToCameraRoll(context: self.context, postbox: self.context.account.postbox, userLocation: .peer(message.id.peerId), mediaReference: saveFileReference)
```

with:

```swift
                                        let saveSignal = SaveToCameraRoll.saveToCameraRoll(context: self.context, userLocation: .peer(message.id.peerId), mediaReference: saveFileReference)
```

At line 3810, replace:

```swift
                                let _ = (SaveToCameraRoll.saveToCameraRoll(context: self.context, postbox: self.context.account.postbox, userLocation: .peer(message.id.peerId), mediaReference: .message(message: MessageReference(message), media: file))
```

with:

```swift
                                let _ = (SaveToCameraRoll.saveToCameraRoll(context: self.context, userLocation: .peer(message.id.peerId), mediaReference: .message(message: MessageReference(message), media: file))
```

At line 3867, replace:

```swift
                        let _ = (SaveToCameraRoll.saveToCameraRoll(context: context, postbox: context.account.postbox, userLocation: .peer(message.id.peerId), mediaReference: .message(message: MessageReference(message), media: image), video: videoReference)
```

with:

```swift
                        let _ = (SaveToCameraRoll.saveToCameraRoll(context: context, userLocation: .peer(message.id.peerId), mediaReference: .message(message: MessageReference(message), media: image), video: videoReference)
```

**Sub-task 4.7 — TelegramUI / MediaEditorScreen / MediaEditorScreen.swift** (destructures)

- [ ] **File:** [submodules/TelegramUI/Components/MediaEditorScreen/Sources/MediaEditorScreen.swift](submodules/TelegramUI/Components/MediaEditorScreen/Sources/MediaEditorScreen.swift)

At line 5136, in the multi-line call starting with `let _ = (fetchMediaData(`, delete the line `                        postbox: self.context.account.postbox,`. The remaining call should read:

```swift
                    let _ = (fetchMediaData(
                        context: self.context,
                        userLocation: .other,
                        mediaReference: file
                    ) |> deliverOnMainQueue).start(next: { [weak self] state, _ in
```

Inside this closure, the destructuring is `if case let .data(data) = state { let path = data.path ... }` — `data.path` stays unchanged, and this site does not access `data.complete` (verified against the current file). No Edit B rename needed here.

**Sub-task 4.8 — TelegramUI / MediaEditorScreen / EditStories.swift** (destructures)

- [ ] **File:** [submodules/TelegramUI/Components/MediaEditorScreen/Sources/EditStories.swift](submodules/TelegramUI/Components/MediaEditorScreen/Sources/EditStories.swift)

At line 37, replace:

```swift
                return fetchMediaData(context: context, postbox: context.account.postbox, userLocation: .peer(peerReference.id), customUserContentType: .story, mediaReference: .story(peer: peerReference, id: storyItem.id, media: media))
```

with:

```swift
                return fetchMediaData(context: context, userLocation: .peer(peerReference.id), customUserContentType: .story, mediaReference: .story(peer: peerReference, id: storyItem.id, media: media))
```

At line 39 (inside the `mapToSignal`), replace:

```swift
                    guard case let .data(data) = value, data.complete else {
```

with:

```swift
                    guard case let .data(data) = value, data.isComplete else {
```

(`data.path` accesses below this line remain unchanged.)

**Sub-task 4.9 — TelegramUI / ChatQrCodeScreen / ChatQrCodeScreen.swift** (destructures)

- [ ] **File:** [submodules/TelegramUI/Components/Chat/ChatQrCodeScreen/Sources/ChatQrCodeScreen.swift](submodules/TelegramUI/Components/Chat/ChatQrCodeScreen/Sources/ChatQrCodeScreen.swift)

At line 2505, replace:

```swift
    let _ = (fetchMediaData(context: context, postbox: context.account.postbox, userLocation: userLocation, mediaReference: AnyMediaReference.standalone(media: media))
```

with:

```swift
    let _ = (fetchMediaData(context: context, userLocation: userLocation, mediaReference: AnyMediaReference.standalone(media: media))
```

At line 2507, replace:

```swift
        guard case let .data(data) = value, data.complete else {
```

with:

```swift
        guard case let .data(data) = value, data.isComplete else {
```

**Sub-task 4.10 — TelegramUI / StoryContainerScreen / StoryItemSetContainerComponent.swift**

- [ ] **File:** [submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerComponent.swift](submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerComponent.swift)

At line 5980, replace:

```swift
            let disposable = (saveToCameraRoll(context: component.context, postbox: component.context.account.postbox, userLocation: .peer(peerReference.id), customUserContentType: .story, mediaReference: .story(peer: peerReference, id: component.slice.item.storyItem.id, media: component.slice.item.storyItem.media._asMedia()))
```

with:

```swift
            let disposable = (saveToCameraRoll(context: component.context, userLocation: .peer(peerReference.id), customUserContentType: .story, mediaReference: .story(peer: peerReference, id: component.slice.item.storyItem.id, media: component.slice.item.storyItem.media._asMedia()))
```

**Sub-task 4.11 — TelegramUI / PeerInfoStoryGridScreen / PeerInfoStoryGridScreen.swift**

- [ ] **File:** [submodules/TelegramUI/Components/PeerInfo/PeerInfoStoryGridScreen/Sources/PeerInfoStoryGridScreen.swift](submodules/TelegramUI/Components/PeerInfo/PeerInfoStoryGridScreen/Sources/PeerInfoStoryGridScreen.swift)

At line 268, replace:

```swift
                    signals.append(saveToCameraRoll(context: component.context, postbox: component.context.account.postbox, userLocation: .other, mediaReference: .story(peer: peerReference, id: item.id, media: item.media._asMedia()))
```

with:

```swift
                    signals.append(saveToCameraRoll(context: component.context, userLocation: .other, mediaReference: .story(peer: peerReference, id: item.id, media: item.media._asMedia()))
```

**Sub-task 4.12 — TelegramUI / Sources / ChatInterfaceStateContextMenus.swift**

- [ ] **File:** [submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift](submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift)

At line 1419, replace:

```swift
                    let _ = (saveToCameraRoll(context: context, postbox: context.account.postbox, userLocation: .peer(message.id.peerId), mediaReference: mediaReference)
```

with:

```swift
                    let _ = (saveToCameraRoll(context: context, userLocation: .peer(message.id.peerId), mediaReference: mediaReference)
```

**Sub-task 4.13 — TelegramUI / Sources / SaveMediaToFiles.swift** (destructures)

- [ ] **File:** [submodules/TelegramUI/Sources/SaveMediaToFiles.swift](submodules/TelegramUI/Sources/SaveMediaToFiles.swift)

At line 27, replace:

```swift
    var signal = fetchMediaData(context: context, postbox: context.account.postbox, userLocation: .other, mediaReference: fileReference.abstract)
```

with:

```swift
    var signal = fetchMediaData(context: context, userLocation: .other, mediaReference: fileReference.abstract)
```

At line 63, replace:

```swift
            if data.complete {
```

with:

```swift
            if data.isComplete {
```

(`data.path` accesses in the block below remain unchanged.)

**Sub-task 4.14 — ShareController / ShareController.swift**

- [ ] **File:** [submodules/ShareController/Sources/ShareController.swift](submodules/ShareController/Sources/ShareController.swift)

At line 2406, after verifying Task 2's postbox-equivalence, replace:

```swift
                return SaveToCameraRoll.saveToCameraRoll(context: context, postbox: postbox, userLocation: .peer(message.id.peerId), mediaReference: .message(message: MessageReference(message), media: media))
```

with:

```swift
                return SaveToCameraRoll.saveToCameraRoll(context: context, userLocation: .peer(message.id.peerId), mediaReference: .message(message: MessageReference(message), media: media))
```

Also delete the now-unused local binding above (line 2403):

```swift
        let postbox = self.currentContext.stateManager.postbox
```

(This line is used only by the `saveToCameraRoll` call on line 2406. If the build later flags it as unused instead of an error, leave it; but preferred is to remove the dead binding.)

At line 2432, replace:

```swift
        self.controllerNode.transitionToProgressWithValue(signal: SaveToCameraRoll.saveToCameraRoll(context: context, postbox: context.account.postbox, userLocation: .other, mediaReference: .standalone(media: media)) |> map(Optional.init), dismissImmediately: true, completion: {})
```

with:

```swift
        self.controllerNode.transitionToProgressWithValue(signal: SaveToCameraRoll.saveToCameraRoll(context: context, userLocation: .other, mediaReference: .standalone(media: media)) |> map(Optional.init), dismissImmediately: true, completion: {})
```

At line 2441, replace:

```swift
        self.controllerNode.transitionToProgressWithValue(signal: SaveToCameraRoll.saveToCameraRoll(context: context, postbox: context.account.postbox, userLocation: .other, mediaReference: mediaReference) |> map(Optional.init), dismissImmediately: completion == nil, completion: completion ?? {})
```

with:

```swift
        self.controllerNode.transitionToProgressWithValue(signal: SaveToCameraRoll.saveToCameraRoll(context: context, userLocation: .other, mediaReference: mediaReference) |> map(Optional.init), dismissImmediately: completion == nil, completion: completion ?? {})
```

(The abandonment branch: if Task 2's verification found `stateManager.postbox` and `account.postbox` are non-equivalent, skip the `line 2406` edit, leave `let postbox = self.currentContext.stateManager.postbox` in place, and revert Task 3's change to the `saveToCameraRoll` public signature only for this one callsite — which is impossible without duplicate signatures, so in that case abandon the entire wave and record the reason in a new commit to the plan.)

---

## Task 5: Full build and commit C2

- [ ] **Step 1: Run the full project build**

Run the build command from the header. Expected: build succeeds with no errors across all modules.

If there are failures, they fall into a few predictable categories and are fixed in place — do not split into another commit:

- **"cannot convert value of type 'Postbox' to expected argument type"** — a call site was missed. Grep again for `postbox: ` usages in the migrated files and fix.
- **"value of type 'EngineMediaResource.ResourceData' has no member 'complete'"** — an Edit B site was missed. Rename to `isComplete`.
- **"use of unresolved identifier 'fetchedMediaResource'" or similar inside `SaveToCameraRoll.swift`** — indicates `import Postbox` was dropped but a bare Postbox top-level function is still referenced. Replace the call with the engine facade introduced in Task 1.
- **Warnings about unused local `let postbox = ...`** — delete the binding.

Re-run the build after each fix until it succeeds.

- [ ] **Step 2: Stage all touched files**

```bash
git add \
  submodules/SaveToCameraRoll/Sources/SaveToCameraRoll.swift \
  submodules/InstantPageUI/Sources/InstantPageControllerNode.swift \
  submodules/LegacyMediaPickerUI/Sources/LegacyAttachmentMenu.swift \
  submodules/LegacyMediaPickerUI/Sources/LegacyAvatarPicker.swift \
  submodules/BrowserUI/Sources/BrowserInstantPageContent.swift \
  submodules/GalleryUI/Sources/Items/ChatImageGalleryItem.swift \
  submodules/GalleryUI/Sources/Items/UniversalVideoGalleryItem.swift \
  submodules/TelegramUI/Components/MediaEditorScreen/Sources/MediaEditorScreen.swift \
  submodules/TelegramUI/Components/MediaEditorScreen/Sources/EditStories.swift \
  submodules/TelegramUI/Components/Chat/ChatQrCodeScreen/Sources/ChatQrCodeScreen.swift \
  submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerComponent.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoStoryGridScreen/Sources/PeerInfoStoryGridScreen.swift \
  submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift \
  submodules/TelegramUI/Sources/SaveMediaToFiles.swift \
  submodules/ShareController/Sources/ShareController.swift
```

- [ ] **Step 3: Verify the diff is clean**

Run:

```bash
git diff --staged --stat
```

Expected: exactly 15 files changed, with SaveToCameraRoll.swift having the largest diff (the full-file rewrite) and each call-site file showing small line-count changes.

- [ ] **Step 4: Commit C2**

```bash
git commit -m "$(cat <<'EOF'
SaveToCameraRoll: drop import Postbox via engine.resources facades

Migrates SaveToCameraRoll's three public functions to take context
only (no more postbox:), switches the FetchMediaDataState.data payload
from MediaResourceData to EngineMediaResource.ResourceData, rewrites
internals via TelegramEngine.Resources.fetch/status/data, and drops
import Postbox from the module. All 23 call sites across 14 files
updated in the same commit to keep the tree buildable.

Wave-3 of the Postbox -> TelegramEngine refactor.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 5: Verify branch log**

Run:

```bash
git log --oneline refactor/postbox-to-engine-wave-3 | head -5
```

Expected: the top two commits on the branch are `SaveToCameraRoll: drop import Postbox ...` (C2) and `TelegramEngine.Resources: add fetch/status/data facades` (C1), above the previous spec commits.

- [ ] **Step 6: Update CLAUDE.md tally**

Open `CLAUDE.md`, find the "Modules currently free of `import Postbox`" section, and add `SaveToCameraRoll (wave 3)` to the bullet list. Also add a "Wave 3 outcome (2026-04-18)" subsection documenting: three facades added on `TelegramEngine.Resources`, `SaveToCameraRoll` fully de-Postboxed, 23 call sites migrated. If any call site was abandoned in Task 2, record the reason here.

Commit:

```bash
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
CLAUDE.md: record wave-3 outcome

Adds SaveToCameraRoll to the Postbox-free module tally and documents
the three new TelegramEngine.Resources facades added in wave 3.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Success criteria

- `submodules/SaveToCameraRoll/Sources/SaveToCameraRoll.swift` contains no `import Postbox`.
- `grep -rnE "(fetchMediaData|saveToCameraRoll|copyToPasteboard)\\(" submodules --include="*.swift" | grep "postbox:"` returns zero matches outside of the private `collectExternalShareResource`/`collectExternalShareItems` helpers in `ShareController.swift` (which take their own `postbox:` parameters unrelated to SaveToCameraRoll).
- Full build succeeds in `debug_sim_arm64` configuration.
- Three branch commits above the spec commits: C1 (facades), C2 (SaveToCameraRoll + callers), C3 (CLAUDE.md tally).
