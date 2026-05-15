# Postbox → TelegramEngine Wave 10 Implementation Plan

> **For agentic workers:** This plan was executed in a single session; steps below are a post-hoc record of the work landed, not a to-do list.

**Goal:** Finish the `StorageUsageScreen` consumer-module de-Postbox work started in wave 8 and continued in wave 9 by eliminating the last `import Postbox` in the module: `StorageFileListPanelComponent.swift`'s `Icon.media(Media, TelegramMediaImageRepresentation)` enum case.

**Architecture:** Replace the heterogeneous-protocol `Icon.media(Media, ...)` case with two concrete-type cases `.mediaFile(TelegramMediaFile, ...)` and `.mediaImage(TelegramMediaImage, ...)`. The split is lossless because the two construction sites already knew the concrete subtype (`imageIconValue = .media(file, representation)` vs `.media(image, representation)`), and the one consumer binding site immediately downcasted via `as? TelegramMediaFile` / `as? TelegramMediaImage` to pick which `setSignal(...)` to call. Auto-split the switch body over the two new cases; no downcast needed. Also replaces a placeholder `PeerId(namespace:..., id:...)` construction in the `measureItem` layout-measurement instance with `component.context.account.peerId` (a real, already-available `EnginePeer.Id`).

**Tech Stack:** Swift / Bazel. No unit tests.

**Build command:**

```bash
source ~/.zshrc 2>/dev/null; PATH=/opt/homebrew/opt/ruby/bin:`gem environment gemdir`/bin:$PATH python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber 1 --configuration debug_sim_arm64 --continueOnError
```

---

## Scope

**In scope:**
- `StorageFileListPanelComponent.swift`'s `Icon` enum: replace `case media(Media, TelegramMediaImageRepresentation)` with two concrete-type cases.
- Equatable rewrite: switch-over-tuple `(lhs, rhs)` pattern with id-based equality per concrete type (`lFile.fileId == rFile.fileId`, `lImage.imageId == rImage.imageId`).
- Binding rewrite at the `if case let .media(media, representation)` site (former line 448): lift `representation` via a compound `case let .mediaFile(_, representation), let .mediaImage(_, representation):` pattern, then inner switch-over-`component.icon` selects `setSignal` flavor.
- Construction rewrite at two `imageIconValue = .media(...)` sites: use the concrete case name (`.mediaFile`, `.mediaImage`).
- Placeholder `PeerId(namespace:..., id:...)` at former line 1062 (in the `measureItem` layout-measurement instance): replace with `component.context.account.peerId`.
- Remove `import Postbox` from `StorageFileListPanelComponent.swift`.

**Out of scope:**
- None. This is the last file in the `StorageUsageScreen` module that imports Postbox; after this wave, the module is fully Postbox-free.

---

## Tasks

### Task 1: Split `Icon.media` into two concrete cases

**Files:**
- Modify: `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageFileListPanelComponent.swift` (former 103–135).

Before:

```swift
enum Icon: Equatable {
    case fileExtension(String)
    case media(Media, TelegramMediaImageRepresentation)
    case audio

    static func ==(lhs: Icon, rhs: Icon) -> Bool {
        switch lhs {
        case let .fileExtension(value):
            if case .fileExtension(value) = rhs { return true } else { return false }
        case let .media(media, representation):
            if case let .media(rhsMedia, rhsRepresentation) = rhs {
                if media.id != rhsMedia.id { return false }
                if representation != rhsRepresentation { return false }
                return true
            } else { return false }
        case .audio:
            if case .audio = rhs { return true } else { return false }
        }
    }
}
```

After:

```swift
enum Icon: Equatable {
    case fileExtension(String)
    case mediaFile(TelegramMediaFile, TelegramMediaImageRepresentation)
    case mediaImage(TelegramMediaImage, TelegramMediaImageRepresentation)
    case audio

    static func ==(lhs: Icon, rhs: Icon) -> Bool {
        switch (lhs, rhs) {
        case let (.fileExtension(l), .fileExtension(r)):
            return l == r
        case let (.mediaFile(lFile, lRepresentation), .mediaFile(rFile, rRepresentation)):
            return lFile.fileId == rFile.fileId && lRepresentation == rRepresentation
        case let (.mediaImage(lImage, lRepresentation), .mediaImage(rImage, rRepresentation)):
            return lImage.imageId == rImage.imageId && lRepresentation == rRepresentation
        case (.audio, .audio):
            return true
        default:
            return false
        }
    }
}
```

### Task 2: Rewrite the binding site

**Files:**
- Modify: `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageFileListPanelComponent.swift` (former 448–500).

Before, the block started with `if case let .media(media, representation) = component.icon { ... }` then inside did `if let file = media as? TelegramMediaFile { ... } else if let image = media as? TelegramMediaImage { ... }`.

After, use a compound case-binding pattern at the entry (both cases have the same `representation` type, so the pattern works) and an inner switch for the `setSignal` branch:

```swift
let mediaRepresentation: TelegramMediaImageRepresentation?
switch component.icon {
case let .mediaFile(_, representation), let .mediaImage(_, representation):
    mediaRepresentation = representation
default:
    mediaRepresentation = nil
}

if let representation = mediaRepresentation {
    // ... setup iconImageNode as before ...
    if resetImage {
        switch component.icon {
        case let .mediaFile(file, _):
            iconImageNode.setSignal(chatWebpageSnippetFile(
                account: component.context.account,
                userLocation: .peer(component.messageId.peerId),
                mediaReference: FileMediaReference.standalone(media: file).abstract,
                representation: representation,
                automaticFetch: false
            ))
        case let .mediaImage(image, _):
            iconImageNode.setSignal(mediaGridMessagePhoto(
                account: component.context.account,
                userLocation: .peer(component.messageId.peerId),
                photoReference: ImageMediaReference.standalone(media: image),
                automaticFetch: false
            ))
        default:
            break
        }
    }
    // ... frame + asyncLayout + apply as before ...
}
```

### Task 3: Update the two construction sites

**Files:**
- Modify: `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageFileListPanelComponent.swift` (former 985 and 992).

`imageIconValue = .media(file, representation)` → `.mediaFile(file, representation)` (for `TelegramMediaFile` branch).
`imageIconValue = .media(image, representation)` → `.mediaImage(image, representation)` (for `TelegramMediaImage` branch).

### Task 4: Replace the placeholder `PeerId(...)` construction

**Files:**
- Modify: `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageFileListPanelComponent.swift` (former 1062).

The `measureItem` layout-measurement instance uses a fully-zero placeholder peer id:

```swift
messageId: EngineMessage.Id(peerId: PeerId(namespace: PeerId.Namespace._internalFromInt32Value(0), id: PeerId.Id._internalFromInt64Value(0)), namespace: 0, id: 0),
```

Naming `PeerId`, `PeerId.Namespace`, `PeerId.Id` all require `import Postbox` (these are raw Postbox types, not TelegramCore typealiases). Replace with `component.context.account.peerId`, a real `EnginePeer.Id` already in scope:

```swift
messageId: EngineMessage.Id(peerId: component.context.account.peerId, namespace: 0, id: 0),
```

Semantically equivalent for the measurement use case — `messageId` is used downstream only for `.peerId` extraction in the image-fetch userLocation and for Equatable comparison; the measurement instance is standalone and not compared. The `id: 0, namespace: 0` part stays; those are plain `Int32`, nothing Postbox-specific.

Caught by second-pass build failure `cannot find 'PeerId' in scope` after dropping `import Postbox`.

### Task 5: Drop `import Postbox`

**Files:**
- Modify: `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageFileListPanelComponent.swift` (former line 14).

Remove the `import Postbox` line.

### Task 6: Full project build

Expected green after Tasks 4 and 5. The first build attempt surfaced the `PeerId` issue; Task 4's fix addressed it.

### Task 7: Commit

Single wave-10 atomic commit. CLAUDE.md gets a wave-10 outcome section; the "Modules currently free of `import Postbox`" tally gains `StorageUsageScreen` (the module as a whole). Both files that previously imported Postbox in this module (`StorageUsageScreen.swift` from wave 9 and `StorageFileListPanelComponent.swift` from wave 10) are now Postbox-free.

---

## Outcome (2026-04-20)

Single atomic commit. Build verified green (27 actions, cached).

**`StorageUsageScreen` consumer module is now fully Postbox-free** — last file (`StorageFileListPanelComponent.swift`) landed in this wave; the other file (`StorageUsageScreen.swift`) landed in wave 9.

Net: 1 file changed, +22 / -29 lines (−7 simplification — the new switch-over-tuple Equatable is both terser and more idiomatic than the old three-way nested `switch` + `if case` pattern).

**Lessons:**

- **Heterogeneous-protocol enum cases are an easy de-Postbox win** when the protocol values already get downcast to a fixed small set of concrete subtypes. The compiler-enforced exhaustiveness of the split improves call-site safety (no silent `else` branch that forgot a subtype).
- **Placeholder `PeerId(...)` constructions in layout-measurement code are traps.** Common pattern in this codebase: a "dummy" component instance is constructed purely to run `.update(...)` and harvest the returned size. The dummy values (`messageId`, `peerId`) are not used for anything but type-filling, yet naming the types forces `import Postbox`. When de-Postboxing, look for `PeerId(namespace:...`/`MessageId(peerId:...` constructions with all-zero arguments and replace with any convenient real value already in scope (`context.account.peerId` works for peer-id placeholders).
