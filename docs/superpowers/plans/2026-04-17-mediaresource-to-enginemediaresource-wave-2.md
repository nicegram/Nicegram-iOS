# MediaResource → EngineMediaResource Refactor (Wave 2) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Drive raw `MediaResource` (Postbox protocol) out of the `TelegramEngine` public facade by changing facade-function signatures in-place to take/return `EngineMediaResource`, bridging to the existing `_internal_*` Postbox-facing implementations via wrap/unwrap helpers. In the same commit as each facade change, update every call site. Follow up with a first small batch of consumer type-reference migrations.

**Architecture:** `TelegramEngine` facade methods live alongside `_internal_*` Postbox-using implementations in `submodules/TelegramCore/Sources/TelegramEngine/<Area>/`. Today the facade methods already bridge (storing an `Account` and delegating), but their public signatures still expose raw `MediaResource`. The fix: change facade signatures to `EngineMediaResource` (including the `mapResourceToAvatarSizes` closure types) and add the two-line wrap/unwrap bridging. `_internal_*` functions stay on raw `MediaResource` — they are the Postbox-facing layer and must remain so. Consumer call sites swap `MediaResource` → `EngineMediaResource` (usually via `EngineMediaResource(raw)` wrap or `engineResource._asResource()` unwrap at a nearby boundary).

**Tech Stack:** Swift, Bazel, Postbox (opaque storage), TelegramCore (public facade), SSignalKit.

**Design constraint (IMPORTANT):** `TelegramCore` is shared with the Telegram-Mac codebase and must **not** import UIKit/Display. Any UIKit-requiring logic (image scaling, `UIImage`, `generateScaledImage`, etc.) stays in consumer-side submodules. Engine API additions must not pull in UIKit.

**Why not overloads:** An earlier iteration of this plan added opt-in `EngineMediaResource` overloads and kept the raw overloads. That was rejected: duplicate signatures fragment the public API and leave raw-`MediaResource` leaks forever. The correct pattern is to change the single facade function in-place so it takes engine types and bridges inside, forcing callers to migrate in the same commit.

---

## Background the executor needs

### The full build command

Run from the repo root (`/Users/ali/build/telegram/telegram-ios`):

```bash
source ~/.zshrc 2>/dev/null; \
PATH=/opt/homebrew/opt/ruby/bin:`gem environment gemdir`/bin:$PATH \
  python3 build-system/Make/Make.py --overrideXcodeVersion \
  --cacheDir ~/telegram-bazel-cache \
  build \
  --configurationPath build-system/appstore-configuration.json \
  --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
  --gitCodesigningType development \
  --gitCodesigningUseCurrent \
  --buildNumber 1 \
  --configuration debug_sim_arm64
```

The build is the only verification (no unit tests per `CLAUDE.md`). Every task ends with a full build that must go green before the next task starts.

### What `EngineMediaResource` gives you today (bridge primitives)

Defined in [TelegramEngineResources.swift](../../../submodules/TelegramCore/Sources/TelegramEngine/Resources/TelegramEngineResources.swift):

```swift
public final class EngineMediaResource: Equatable {
    public init(_ resource: MediaResource)
    public func _asResource() -> MediaResource
    public var id: Id
    public struct Id: Equatable, Hashable {
        public init(_ id: MediaResourceId)
        public init(_ stringRepresentation: String)
    }
    public final class ResourceData {
        public let path: String; public let availableSize: Int64; public let isComplete: Bool
    }
    public enum FetchStatus: Equatable { /* Remote/Local/Fetching/Paused */ }
}
public extension EngineMediaResource.ResourceData {
    convenience init(_ data: MediaResourceData)
}
```

### The bridging pattern

For each facade function whose public signature contains `MediaResource`:

**Before** (raw-protocol leak):

```swift
public func uploadedPeerPhoto(resource: MediaResource) -> Signal<UploadedPeerPhotoData, NoError> {
    return _internal_uploadedPeerPhoto(postbox: self.account.postbox, network: self.account.network, resource: resource)
}
```

**After** (engine-typed facade, internal bridge):

```swift
public func uploadedPeerPhoto(resource: EngineMediaResource) -> Signal<UploadedPeerPhotoData, NoError> {
    return _internal_uploadedPeerPhoto(postbox: self.account.postbox, network: self.account.network, resource: resource._asResource())
}
```

For closures that receive a `MediaResource`:

**Before:**

```swift
public func updatePeerPhoto(..., mapResourceToAvatarSizes: @escaping (MediaResource, [TelegramMediaImageRepresentation]) -> Signal<[Int: Data], NoError>) -> ... {
    return _internal_updatePeerPhoto(..., mapResourceToAvatarSizes: mapResourceToAvatarSizes)
}
```

**After:**

```swift
public func updatePeerPhoto(..., mapResourceToAvatarSizes: @escaping (EngineMediaResource, [TelegramMediaImageRepresentation]) -> Signal<[Int: Data], NoError>) -> ... {
    return _internal_updatePeerPhoto(..., mapResourceToAvatarSizes: { rawResource, representations in
        mapResourceToAvatarSizes(EngineMediaResource(rawResource), representations)
    })
}
```

`_internal_*` functions are **not** changed — they stay on raw `MediaResource` as the Postbox-facing layer.

### Call-site migration pattern

At each call site, the change is mechanical:

- `engine.peers.uploadedPeerPhoto(resource: someRawResource)` → `engine.peers.uploadedPeerPhoto(resource: EngineMediaResource(someRawResource))`.
- `engine.peers.updatePeerPhoto(..., mapResourceToAvatarSizes: { resource, representations in ... resource ... })` — the closure's `resource` is now `EngineMediaResource`. Any expression inside the closure that previously treated `resource` as raw protocol (e.g. `postbox.mediaBox.resourceData(resource)`) must use `resource._asResource()`.

Where the consumer was carrying a `MediaResource?` property / local purely as a pipe into one of these APIs, migrate the property itself to `EngineMediaResource?` so no unwrap/wrap churn is needed.

### Static-check commands

```bash
grep -R "^import Postbox" submodules/<M>/Sources         # expect: empty (only when a module is being fully de-Postboxed)
grep "submodules/Postbox" submodules/<M>/BUILD            # expect: empty (same condition)
```

### Commit convention

- One commit per engine API family: `TelegramCore: migrate <function(s)> to EngineMediaResource` — bundles facade-signature change **and** all call sites updated in the same commit. The repo must build on every commit.
- Consumer-only type-ref commits: `<ModuleName>: migrate MediaResource property to EngineMediaResource` or `<ModuleName>: drop direct Postbox dependency`.
- Always use HEREDOC bodies. No `--amend`.

### What is explicitly out of scope

- Classes that **conform to `TelegramMediaResource`** (must implement `isEqual(to: MediaResource)`): remain `import Postbox`. Enumerated:
  - `submodules/ICloudResources/Sources/ICloudResources.swift` — `ICloudFileResource`
  - `submodules/InstantPageUI/Sources/InstantPageExternalMediaResource.swift` — `InstantPageExternalMediaResource`
  - `submodules/LocalMediaResources/Sources/LocalMediaResources.swift` — `VideoLibraryMediaResource`
  - `submodules/TelegramUniversalVideoContent/Sources/YoutubeEmbedImplementation.swift` — `YoutubeEmbedStoryboardMediaResource`
- TelegramCore-internal `MediaResource` usage (SyncCore, Fetch, `_internal_*` functions, etc.) — Postbox-facing layer.
- Modules already abandoned in wave 1 for non-MediaResource reasons (`FetchManagerImpl` / `ICloudResources` have other umbrella-type blockers).
- The heavy-leak modules in the "Future waves" table at the bottom (`PassportUI`, `TelegramUI`, etc.).
- Importing UIKit/Display into TelegramCore under any circumstance.

---

## Task 0: Baseline verification

**Files:** No code changes.

- [ ] **Step 1: Confirm tree state**

```bash
git status
git log --oneline -5
```

Expected: working tree clean apart from pre-existing untracked (`build-system/tulsi/`, `submodules/TgVoip/`, `third-party/libx264/`) and submodule-content drift on `build-system/bazel-rules/sourcekit-bazel-bsp`. HEAD on `master`.

- [ ] **Step 2: Baseline build**

Run the full build command above. Expected: PASS.

If it fails, stop — a non-green baseline is out of scope.

- [ ] **Step 3: No commit.**

---

## Task 1: Record the new rules in CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add the "TelegramCore no UIKit" rule**

In `CLAUDE.md`, inside the `## Postbox → TelegramEngine refactor (in progress)` section, under `### Rules that apply to every wave`, append a new numbered rule after the existing rule 6:

```markdown
7. **TelegramCore never imports UIKit/Display.** `TelegramCore` is shared with the Telegram-Mac codebase; its Bazel `deps` and source files must not reference UIKit, Display, or any Apple-UI framework. UIKit-needing helpers (image scaling, rendering, etc.) stay in consumer-side submodules.
```

- [ ] **Step 2: Add the MediaResource → EngineMediaResource migration pattern**

After the `### Engine typealias cheat sheet (existing aliases)` block (which ends with the `MediaResource` / `TelegramMediaResource` note), insert a new section:

```markdown
### MediaResource → EngineMediaResource consumer migration

`EngineMediaResource` is a `final class` in `TelegramCore` wrapping a `MediaResource` value. Unlike the typealiases above it is **not** interchangeable with the protocol, but it does provide wrap/unwrap helpers:

- `EngineMediaResource(rawResource)` — wrap a raw `MediaResource`.
- `engineResource._asResource()` — unwrap to the raw `MediaResource`.
- `EngineMediaResource.ResourceData(rawResourceData)` — wrap `MediaResourceData`.
- `EngineMediaResource.Id(rawMediaResourceId)` — wrap `MediaResourceId`.

**Pattern for facade functions:** when a `TelegramEngine.<Area>` method leaks raw `MediaResource` in its public signature, **change the facade signature in place** to `EngineMediaResource` (and change any closure parameter types the same way). Bridge inside the facade body by calling the existing `_internal_*` function with `engineResource._asResource()` / wrapping raw inputs from inner closures with `EngineMediaResource(rawResource)`. Update all call sites in the same commit. The `_internal_*` function stays on raw `MediaResource` — it is the Postbox-facing layer.

Do **not** add opt-in `EngineMediaResource` overloads alongside raw-`MediaResource` overloads. Duplicate signatures fragment the public API and leave the leak in place forever.

For consumer modules, prefer `EngineMediaResource` as the type in properties, locals, generic arguments and function parameters when the usage is a pure type reference. Do **not** try to use `EngineMediaResource` where a class must conform to `TelegramMediaResource` (Postbox protocol) or override `isEqual(to: MediaResource)` — those remain `import Postbox`.
```

- [ ] **Step 3: Full build (sanity — docs only)**

Run the full build. Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
CLAUDE.md: record TelegramCore-no-UIKit rule and EngineMediaResource migration pattern

Wave-2 preparation. Codifies that TelegramCore is shared with
Telegram-Mac and must stay UIKit-free, and documents the
modify-in-place / bridge-inside pattern for migrating
MediaResource-leaking facade functions to EngineMediaResource.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Migrate `TelegramEngine.Peers` photo APIs to `EngineMediaResource`

**Files:**
- Modify: `submodules/TelegramCore/Sources/TelegramEngine/Peers/TelegramEnginePeers.swift`
- Modify: all call sites (13 + 11 + 7, with heavy overlap — see Step 2 grep).

**Functions migrated in this task:**
- `uploadedPeerPhoto(resource:)` (line 704) — `MediaResource` → `EngineMediaResource`
- `uploadedPeerVideo(resource:)` (line 708) — `MediaResource` → `EngineMediaResource`
- `updatePeerPhoto(..., mapResourceToAvatarSizes:)` (line 712) — closure parameter `MediaResource` → `EngineMediaResource`

- [ ] **Step 1: Read the current signatures**

Read lines 704–720 of `submodules/TelegramCore/Sources/TelegramEngine/Peers/TelegramEnginePeers.swift`. Confirm the three functions match the pattern `return _internal_<name>(postbox: self.account.postbox, ..., resource: resource)` or equivalent.

- [ ] **Step 2: Enumerate call sites**

```bash
grep -rnE "\\.(uploadedPeerPhoto|uploadedPeerVideo|updatePeerPhoto)\(" submodules/ \
  | grep -v "submodules/TelegramCore"
```

Capture every hit — file path, line number, approximate surrounding context (what resource expression is passed in / what the closure body does). The distribution as of planning:

- `uploadedPeerPhoto`: 11 call sites (spread across TelegramUI, TelegramCallsUI, AuthorizationUI, etc.)
- `uploadedPeerVideo`: 7
- `updatePeerPhoto`: 13

Many call sites chain these (e.g. `updatePeerPhoto(photo: engine.peers.uploadedPeerPhoto(resource: ...))`) so a single file often touches two or three of them in one call.

- [ ] **Step 3: Change the facade signatures + bridge**

In `TelegramEnginePeers.swift`, change the three functions to:

```swift
public func uploadedPeerPhoto(resource: EngineMediaResource) -> Signal<UploadedPeerPhotoData, NoError> {
    return _internal_uploadedPeerPhoto(postbox: self.account.postbox, network: self.account.network, resource: resource._asResource())
}

public func uploadedPeerVideo(resource: EngineMediaResource) -> Signal<UploadedPeerPhotoData, NoError> {
    return _internal_uploadedPeerVideo(postbox: self.account.postbox, network: self.account.network, messageMediaPreuploadManager: self.account.messageMediaPreuploadManager, resource: resource._asResource())
}

public func updatePeerPhoto(peerId: PeerId, photo: Signal<UploadedPeerPhotoData, NoError>?, video: Signal<UploadedPeerPhotoData?, NoError>? = nil, videoStartTimestamp: Double? = nil, markup: UploadPeerPhotoMarkup? = nil, mapResourceToAvatarSizes: @escaping (EngineMediaResource, [TelegramMediaImageRepresentation]) -> Signal<[Int: Data], NoError>) -> Signal<UpdatePeerPhotoStatus, UploadPeerPhotoError> {
    return _internal_updatePeerPhoto(postbox: self.account.postbox, network: self.account.network, stateManager: self.account.stateManager, accountPeerId: self.account.peerId, peerId: peerId, photo: photo, video: video, videoStartTimestamp: videoStartTimestamp, markup: markup, mapResourceToAvatarSizes: { rawResource, representations in
        return mapResourceToAvatarSizes(EngineMediaResource(rawResource), representations)
    })
}
```

**Before editing, re-read the existing bodies** — the exact arg names passed into `_internal_updatePeerPhoto` etc. must match what's already there (the skeletons above reproduce what's in the file at planning time, but the executor should preserve every argument the current implementation passes). Only the outer signature and the closure-wrapping change.

- [ ] **Step 4: Update every call site** (same commit)

For each hit from Step 2, rewrite the call site per the patterns:

**Pattern A — passing a raw resource to `uploadedPeerPhoto` / `uploadedPeerVideo`:**

```swift
// Before:
engine.peers.uploadedPeerPhoto(resource: someRawResource)
// After:
engine.peers.uploadedPeerPhoto(resource: EngineMediaResource(someRawResource))
```

**Pattern B — the `mapResourceToAvatarSizes` closure of `updatePeerPhoto`:**

```swift
// Before:
mapResourceToAvatarSizes: { resource, representations in
    return mapResourceToAvatarSizes(postbox: postbox, resource: resource, representations: representations)
}
// After (if the helper is still raw-MediaResource-facing at this point):
mapResourceToAvatarSizes: { resource, representations in
    return mapResourceToAvatarSizes(postbox: postbox, resource: resource._asResource(), representations: representations)
}
```

Task 6 will change `mapResourceToAvatarSizes` itself to accept `EngineMediaResource` and drop the `_asResource()` call. Until Task 6 lands, keep the `_asResource()` here. This keeps the build green between tasks.

**Pattern C — the consumer was already carrying the resource as a `MediaResource?` local purely as a pipe:**

If a nearby local/property typed `MediaResource?` only exists to feed `uploadedPeerPhoto(resource:)` or similar, change the local's type to `EngineMediaResource?` at the same time. This avoids wrap/unwrap churn at the call site.

- [ ] **Step 5: Full build**

Run the full build. Expected: PASS.

If it fails, the first error locates the broken call site. Apply Pattern A / B / C at that site and rebuild. If a file imports Postbox only for `MediaResource` and now has no other Postbox identifier, you may optionally remove `import Postbox` in the same commit — but that is not required here; it is a separate goal.

- [ ] **Step 6: Commit**

```bash
git add submodules/TelegramCore/Sources/TelegramEngine/Peers/TelegramEnginePeers.swift submodules/
git commit -m "$(cat <<'EOF'
TelegramCore: migrate peer-photo facade to EngineMediaResource

Change TelegramEngine.Peers.uploadedPeerPhoto / uploadedPeerVideo /
updatePeerPhoto so their public signatures take EngineMediaResource
instead of raw MediaResource (and the mapResourceToAvatarSizes closure
receives EngineMediaResource). The facade bridges to the existing
_internal_* Postbox-facing implementations via _asResource() /
EngineMediaResource(_:). All call sites updated in this commit.

Part of the MediaResource -> EngineMediaResource migration (wave 2).
No behavior change.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Migrate `TelegramEngine.AccountData.updateAccountPhoto` and `updateFallbackPhoto`

**Files:**
- Modify: `submodules/TelegramCore/Sources/TelegramEngine/AccountData/TelegramEngineAccountData.swift`
- Modify: all call sites (5 + 4).

- [ ] **Step 1: Read the current signatures**

Read lines 55–90 of `submodules/TelegramCore/Sources/TelegramEngine/AccountData/TelegramEngineAccountData.swift`. Confirm both functions match the expected pattern.

- [ ] **Step 2: Enumerate call sites**

```bash
grep -rnE "\\.(updateAccountPhoto|updateFallbackPhoto)\(" submodules/ \
  | grep -v "submodules/TelegramCore"
```

- [ ] **Step 3: Change the facade signatures + bridge**

Change both functions in place:

```swift
public func updateAccountPhoto(resource: EngineMediaResource?, videoResource: EngineMediaResource?, videoStartTimestamp: Double?, markup: UploadPeerPhotoMarkup?, mapResourceToAvatarSizes: @escaping (EngineMediaResource, [TelegramMediaImageRepresentation]) -> Signal<[Int: Data], NoError>) -> Signal<UpdatePeerPhotoStatus, UploadPeerPhotoError> {
    return _internal_updateAccountPhoto(account: self.account, resource: resource?._asResource(), videoResource: videoResource?._asResource(), videoStartTimestamp: videoStartTimestamp, markup: markup, mapResourceToAvatarSizes: { rawResource, representations in
        return mapResourceToAvatarSizes(EngineMediaResource(rawResource), representations)
    })
}

public func updateFallbackPhoto(resource: EngineMediaResource?, videoResource: EngineMediaResource?, videoStartTimestamp: Double?, markup: UploadPeerPhotoMarkup?, mapResourceToAvatarSizes: @escaping (EngineMediaResource, [TelegramMediaImageRepresentation]) -> Signal<[Int: Data], NoError>) -> Signal<UpdatePeerPhotoStatus, UploadPeerPhotoError> {
    return _internal_updateFallbackPhoto(account: self.account, resource: resource?._asResource(), videoResource: videoResource?._asResource(), videoStartTimestamp: videoStartTimestamp, markup: markup, mapResourceToAvatarSizes: { rawResource, representations in
        return mapResourceToAvatarSizes(EngineMediaResource(rawResource), representations)
    })
}
```

**Before editing, verify the exact argument names passed to `_internal_updateAccountPhoto` / `_internal_updateFallbackPhoto`** in the current file. Copy those argument spellings verbatim (only the outer signature and inner closure wrapping change).

- [ ] **Step 4: Update every call site** (same commit)

Apply Pattern A/B/C from Task 2 to every hit. Wrap `EngineMediaResource(...)` around raw-resource args; add `._asResource()` inside any `mapResourceToAvatarSizes:` closure body where it hands the value onward to a still-raw helper (removed in Task 6).

- [ ] **Step 5: Full build**

Run the full build. Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add submodules/TelegramCore/Sources/TelegramEngine/AccountData/TelegramEngineAccountData.swift submodules/
git commit -m "$(cat <<'EOF'
TelegramCore: migrate account-photo facade to EngineMediaResource

Change TelegramEngine.AccountData.updateAccountPhoto and
updateFallbackPhoto so their public signatures take EngineMediaResource
(and the mapResourceToAvatarSizes closure receives
EngineMediaResource). Bridges to _internal_* functions via
_asResource()/EngineMediaResource(_:). All call sites updated in this
commit.

Part of the MediaResource -> EngineMediaResource migration (wave 2).
No behavior change.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Migrate `TelegramEngine.Contacts.updateContactPhoto`

**Files:**
- Modify: `submodules/TelegramCore/Sources/TelegramEngine/Contacts/TelegramEngineContacts.swift`
- Modify: all call sites (8).

- [ ] **Step 1: Read the current signature**

Read around line 33 of `submodules/TelegramCore/Sources/TelegramEngine/Contacts/TelegramEngineContacts.swift`.

- [ ] **Step 2: Enumerate call sites**

```bash
grep -rn "\.updateContactPhoto(" submodules/ | grep -v "submodules/TelegramCore"
```

- [ ] **Step 3: Change the facade signature + bridge**

```swift
public func updateContactPhoto(peerId: PeerId, resource: EngineMediaResource?, videoResource: EngineMediaResource?, videoStartTimestamp: Double?, markup: UploadPeerPhotoMarkup?, mode: SetCustomPeerPhotoMode, mapResourceToAvatarSizes: @escaping (EngineMediaResource, [TelegramMediaImageRepresentation]) -> Signal<[Int: Data], NoError>) -> Signal<UpdatePeerPhotoStatus, UploadPeerPhotoError> {
    return _internal_updateContactPhoto(account: self.account, peerId: peerId, resource: resource?._asResource(), videoResource: videoResource?._asResource(), videoStartTimestamp: videoStartTimestamp, markup: markup, mode: mode, mapResourceToAvatarSizes: { rawResource, representations in
        return mapResourceToAvatarSizes(EngineMediaResource(rawResource), representations)
    })
}
```

Verify the `_internal_updateContactPhoto` call spelling against the existing file before committing.

- [ ] **Step 4: Update every call site** (same commit)

Pattern A/B/C as in Task 2.

- [ ] **Step 5: Full build**

Run the full build. Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add submodules/TelegramCore/Sources/TelegramEngine/Contacts/TelegramEngineContacts.swift submodules/
git commit -m "$(cat <<'EOF'
TelegramCore: migrate updateContactPhoto facade to EngineMediaResource

Change TelegramEngine.Contacts.updateContactPhoto so its public
signature takes EngineMediaResource parameters and the
mapResourceToAvatarSizes closure receives EngineMediaResource. Bridges
to _internal_updateContactPhoto via _asResource()/EngineMediaResource(_:).
All call sites updated in this commit.

Part of the MediaResource -> EngineMediaResource migration (wave 2).
No behavior change.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Migrate `TelegramEngine.Auth.uploadedPeerVideo`

**Files:**
- Modify: `submodules/TelegramCore/Sources/TelegramEngine/Auth/TelegramEngineAuth.swift`
- Modify: call sites that route through `TelegramEngine.Auth.uploadedPeerVideo` (separate from `TelegramEngine.Peers.uploadedPeerVideo`).

- [ ] **Step 1: Read the current signature**

Read around line 51 of `submodules/TelegramCore/Sources/TelegramEngine/Auth/TelegramEngineAuth.swift`.

- [ ] **Step 2: Enumerate call sites**

```bash
grep -rn "engine\.auth\.uploadedPeerVideo\|\.auth\.uploadedPeerVideo" submodules/ | grep -v "submodules/TelegramCore"
```

The call site count is small (the sign-up flow). If zero, skip Step 4.

- [ ] **Step 3: Change the facade signature + bridge**

```swift
public func uploadedPeerVideo(resource: EngineMediaResource) -> Signal<UploadedPeerPhotoData, NoError> {
    return _internal_uploadedPeerVideo(postbox: self.account.postbox, network: self.account.network, messageMediaPreuploadManager: self.account.messageMediaPreuploadManager, resource: resource._asResource())
}
```

Preserve the exact argument spellings from the existing function body.

- [ ] **Step 4: Update call sites** (same commit)

Pattern A.

- [ ] **Step 5: Full build**

Run the full build. Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add submodules/TelegramCore/Sources/TelegramEngine/Auth/TelegramEngineAuth.swift submodules/
git commit -m "$(cat <<'EOF'
TelegramCore: migrate Auth.uploadedPeerVideo facade to EngineMediaResource

Signature change + call sites.

Part of the MediaResource -> EngineMediaResource migration (wave 2).
No behavior change.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Migrate `mapResourceToAvatarSizes` utility and drop `import Postbox` from `MapResourceToAvatarSizes`

**Files:**
- Modify: `submodules/MapResourceToAvatarSizes/Sources/MapResourceToAvatarSizes.swift`
- Modify: `submodules/MapResourceToAvatarSizes/BUILD`
- Modify: all 27 call sites of the old `mapResourceToAvatarSizes(postbox:resource:representations:)`.

**Preconditions:** Tasks 2–5 have landed, so every `mapResourceToAvatarSizes:` closure at call sites now receives an `EngineMediaResource` (because the facade closures were retyped). At this point the inner `mapResourceToAvatarSizes(postbox: …, resource: …._asResource(), …)` unwrap becomes avoidable.

- [ ] **Step 1: Read the current file**

```
submodules/MapResourceToAvatarSizes/Sources/MapResourceToAvatarSizes.swift
```

Confirm the function body uses `postbox.mediaBox.resourceData(resource)` and requires `UIImage` / `generateScaledImage` / `jpegData(compressionQuality:)`.

- [ ] **Step 2: Enumerate call sites**

```bash
grep -rn "mapResourceToAvatarSizes(postbox:" submodules/ | grep -v "submodules/MapResourceToAvatarSizes"
```

Expected: 27 call sites, concentrated in `submodules/TelegramUI/...PeerInfoScreenAvatarSetup.swift` (19), `TelegramCallsUI/...VideoChatScreenParticipantContextMenu.swift` (5), and three other TelegramUI files (1 each).

- [ ] **Step 3: Rewrite the function to use `EngineMediaResource` + `TelegramEngine.Resources.data`**

Replace the body of `submodules/MapResourceToAvatarSizes/Sources/MapResourceToAvatarSizes.swift` with:

```swift
import Foundation
import UIKit
import SwiftSignalKit
import TelegramCore
import Display

public func mapResourceToAvatarSizes(engine: TelegramEngine, resource: EngineMediaResource, representations: [TelegramMediaImageRepresentation]) -> Signal<[Int: Data], NoError> {
    return engine.resources.data(id: resource.id)
    |> take(1)
    |> map { data -> [Int: Data] in
        guard data.isComplete, let image = UIImage(contentsOfFile: data.path) else {
            return [:]
        }
        var result: [Int: Data] = [:]
        for i in 0 ..< representations.count {
            let size: CGSize
            if representations[i].dimensions.width == 80 {
                size = CGSize(width: 160.0, height: 160.0)
            } else {
                size = representations[i].dimensions.cgSize
            }
            if let scaledImage = generateScaledImage(image: image, size: size, scale: 1.0), let scaledData = scaledImage.jpegData(compressionQuality: 0.8) {
                result[i] = scaledData
            }
        }
        return result
    }
}
```

Notes:
- Signature: `(engine: TelegramEngine, resource: EngineMediaResource, representations: [TelegramMediaImageRepresentation]) -> Signal<[Int: Data], NoError>`.
- `import Postbox` is gone; replaced usage with `engine.resources.data(id:)` which returns `Signal<EngineMediaResource.ResourceData, NoError>`.
- `data.complete` → `data.isComplete` (field rename on the engine wrapper).

- [ ] **Step 4: Drop the Bazel dep**

Edit `submodules/MapResourceToAvatarSizes/BUILD` and remove `"//submodules/Postbox:Postbox",` from `deps`. Leave the rest untouched.

- [ ] **Step 5: Update every call site** (same commit)

At each of the 27 sites, two changes:

**Pattern D — the call site already lives inside a `mapResourceToAvatarSizes:` closure on a facade function (post-Task-2/3/4, the closure's `resource` parameter is now `EngineMediaResource`):**

```swift
// Before (from an intermediate state between tasks):
mapResourceToAvatarSizes: { resource, representations in
    return mapResourceToAvatarSizes(postbox: postbox, resource: resource._asResource(), representations: representations)
}
// After:
mapResourceToAvatarSizes: { resource, representations in
    return mapResourceToAvatarSizes(engine: engine, resource: resource, representations: representations)
}
```

The `engine` value is always reachable at the call site — it's either a stored reference used right above the closure or `context.engine` / `accountContext.engine`. Grep shows every current call site has a `postbox = context.account.postbox` (or similar) just above, so `context.engine` / the adjacent engine reference is in scope.

**Pattern E — direct (non-closure) call with a raw `MediaResource` in scope:**

Rare in the current code, but if you find one, wrap with `EngineMediaResource(rawResource)` at the call.

- [ ] **Step 6: Static checks**

```bash
grep -R "^import Postbox" submodules/MapResourceToAvatarSizes/Sources   # expect: empty
grep "submodules/Postbox" submodules/MapResourceToAvatarSizes/BUILD      # expect: empty
```

- [ ] **Step 7: Full build**

Run the full build. Expected: PASS.

Likely failure modes:
- A call site's surrounding scope doesn't have an `engine` in context. Fix: use `<nearby-accountContext>.engine` or promote `engine` to a nearby `let`.
- A consumer file passed a non-`EngineMediaResource` into the closure because it wasn't updated by Task 2/3/4. Fix forward (update it now) and record the miss.

- [ ] **Step 8: Commit**

```bash
git add submodules/MapResourceToAvatarSizes/ submodules/TelegramUI/ submodules/TelegramCallsUI/
git commit -m "$(cat <<'EOF'
MapResourceToAvatarSizes: migrate to EngineMediaResource and drop Postbox

Change the signature of mapResourceToAvatarSizes from
(postbox: Postbox, resource: MediaResource, ...) to
(engine: TelegramEngine, resource: EngineMediaResource, ...), using
engine.resources.data(id:) internally. All 27 call sites updated in
this commit. `import Postbox` and the Bazel dep are removed.
Behavior-preserving.

Part of the MediaResource -> EngineMediaResource migration (wave 2).

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Migrate `AuthorizationUI` signal type

**Files:**
- Modify: `submodules/AuthorizationUI/Sources/AuthorizationSequenceController.swift`

**Starting inventory:** exactly one reference — `Signal<TelegramMediaResource?, NoError>` at line 1162. AuthorizationUI has six files importing Postbox overall; dropping `import Postbox` from the module as a whole is **not** in scope for this task.

- [ ] **Step 1: Read line 1162 ± 20**

Understand:
- What value is put into the signal? Likely some TelegramMediaResource subclass (e.g. `LocalFileMediaResource`). 
- Who consumes the signal downstream? After Tasks 2–5, any facade that ultimately receives this signal's value (via `updateAccountPhoto`, `uploadedPeerVideo`, etc.) expects `EngineMediaResource`.

- [ ] **Step 2: Change the signal type**

```swift
// Before:
avatarVideo = Signal<TelegramMediaResource?, NoError> { subscriber in
    // ... produces a TelegramMediaResource ...
    subscriber.putNext(someResource)
}
// After:
avatarVideo = Signal<EngineMediaResource?, NoError> { subscriber in
    // ... produces a TelegramMediaResource ...
    subscriber.putNext(someResource.flatMap { EngineMediaResource($0) })  // or wrap the non-optional path
}
```

The exact wrapping site depends on where the raw resource flows in. The grep + read from Step 1 tells you.

Downstream, any call site that consumed the raw resource and handed it to an engine facade now has an `EngineMediaResource?` which it can pass directly (post-Tasks 2–5).

- [ ] **Step 3: Full build**

Run the full build. Expected: PASS.

If the downstream expected a `TelegramMediaResource?` (e.g. for direct Postbox access that wasn't part of Tasks 2–5), revert this task as `Abandoned — downstream expects raw protocol` with a recorded reason.

- [ ] **Step 4: Commit**

```bash
git add submodules/AuthorizationUI/Sources/AuthorizationSequenceController.swift
git commit -m "$(cat <<'EOF'
AuthorizationUI: migrate avatar-video signal type to EngineMediaResource

Single type-reference swap. Downstream engine facades already accept
EngineMediaResource after the Phase-1 migrations. Behavior-preserving.

Part of the MediaResource -> EngineMediaResource migration (wave 2).

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Migrate `SaveToCameraRoll` property type — **ABANDONED**

**Status:** Abandoned in wave 2. No code changes from this task.

**Reason:** The planning-time grep that produced the "one reference" inventory only matched `MediaResource`/`TelegramMediaResource` tokens, not the broader set of Postbox usages. Re-inventorying the module at execution time (`grep -nE "\b(postbox|mediaBox|MediaResource)\b|^import Postbox" submodules/SaveToCameraRoll/Sources/SaveToCameraRoll.swift`) shows three public functions with `postbox: Postbox` in their signatures (`fetchMediaData`, `saveToCameraRoll`, `copyToPasteboard`) plus multiple `postbox.mediaBox.*` calls in their bodies. Per spec rule 2, `Postbox` is an umbrella type that cannot be typealiased, so those public-API signatures cannot be de-Postboxed without editing every caller; and the internal `postbox.mediaBox.*` calls require engine-side wrappers (closer to Task 6's shape) rather than a simple type swap. Scope is a full module-migration wave, not a single type swap — parked for a future wave.

**Original task body (retained for audit trail, do not implement):**

**Files:**
- Modify: `submodules/SaveToCameraRoll/Sources/SaveToCameraRoll.swift`
- Possibly modify: `submodules/SaveToCameraRoll/BUILD`

**Starting inventory:** one reference — `var resource: MediaResource?` at line 19.

- [ ] **Step 1: Read + full grep**

```bash
grep -nE "\b(MediaResource|TelegramMediaResource|postbox|mediaBox|transaction|PostboxView|combinedView)\b|^import Postbox" submodules/SaveToCameraRoll/Sources/SaveToCameraRoll.swift
```

Capture every hit.

- [ ] **Step 2: Abandon-check**

If the grep shows Postbox usages other than the single `MediaResource?` property and an `import Postbox` line, abandon this task with a recorded reason. Do not substitute.

If it shows only the property + import, proceed.

- [ ] **Step 3: Swap the property type + boundary wrap/unwrap**

Change `var resource: MediaResource?` to `var resource: EngineMediaResource?`. At each assignment/use:

- Assignment from a raw resource: `self.resource = EngineMediaResource(rawResource)`; `self.resource = nil` unchanged.
- Read that hands to mediaBox/postbox (if any remains): `self.resource?._asResource()`.

- [ ] **Step 4: Drop `import Postbox` if now unused**

If Step 1 showed `import Postbox` as the only remaining Postbox reference:

- Remove the `import Postbox` line.
- Remove `"//submodules/Postbox:Postbox",` from `submodules/SaveToCameraRoll/BUILD`.

Static checks:

```bash
grep -R "^import Postbox" submodules/SaveToCameraRoll/Sources   # expect: empty
grep "submodules/Postbox" submodules/SaveToCameraRoll/BUILD      # expect: empty
```

Else skip this step.

- [ ] **Step 5: Full build**

Run the full build. Expected: PASS.

- [ ] **Step 6: Commit**

If the import was removed:

```bash
git add submodules/SaveToCameraRoll/
git commit -m "$(cat <<'EOF'
SaveToCameraRoll: migrate resource property to EngineMediaResource and drop Postbox

Swaps the single MediaResource? property for EngineMediaResource?,
wrapping/unwrapping at boundaries. With the only Postbox reference
gone, removes `import Postbox` and the Bazel dep.
Behavior-preserving.

Part of the MediaResource -> EngineMediaResource migration (wave 2).

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

If the import was kept:

```bash
git add submodules/SaveToCameraRoll/Sources/SaveToCameraRoll.swift
git commit -m "$(cat <<'EOF'
SaveToCameraRoll: migrate resource property to EngineMediaResource

Swaps the single MediaResource? property for EngineMediaResource?,
wrapping/unwrapping at boundaries. import Postbox remains because
other identifiers still need it. Behavior-preserving.

Part of the MediaResource -> EngineMediaResource migration (wave 2).

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Wave-2 completion verification

**Files:** No code changes.

- [ ] **Step 1: Commit-log check**

```bash
git log --oneline master..HEAD   # or whatever branch this was executed on
```

Expected commits (some may be absent if tasks abandoned):

- `CLAUDE.md: record TelegramCore-no-UIKit rule and EngineMediaResource migration pattern`
- `TelegramCore: migrate peer-photo facade to EngineMediaResource`
- `TelegramCore: migrate account-photo facade to EngineMediaResource`
- `TelegramCore: migrate updateContactPhoto facade to EngineMediaResource`
- `TelegramCore: migrate Auth.uploadedPeerVideo facade to EngineMediaResource`
- `MapResourceToAvatarSizes: migrate to EngineMediaResource and drop Postbox`
- `AuthorizationUI: migrate avatar-video signal type to EngineMediaResource`
- `SaveToCameraRoll: migrate resource property to EngineMediaResource[...]`

- [ ] **Step 2: Public-API leak check**

```bash
grep -nE "^\s*public func .*: MediaResource|public func .*MediaResource, \[" \
  submodules/TelegramCore/Sources/TelegramEngine/
```

Expected: no matches in the facade files touched by Tasks 2–5 (`TelegramEngine/Peers/TelegramEnginePeers.swift`, `TelegramEngine/AccountData/TelegramEngineAccountData.swift`, `TelegramEngine/Contacts/TelegramEngineContacts.swift`, `TelegramEngine/Auth/TelegramEngineAuth.swift`). Other TelegramEngine files may still leak `MediaResource` — those are for future waves.

- [ ] **Step 3: Final full build from clean state**

Run the full build. Expected: PASS (cached, fast).

- [ ] **Step 4: No commit.** Verification only.

---

## Future waves (not in this plan)

Ranked consumer modules by MediaResource/TelegramMediaResource reference count (from `grep -rE "\\b(MediaResource|TelegramMediaResource)\\b"` over `submodules/<M>/Sources/`, excluding TelegramCore/Postbox). Classifications are preliminary and must be re-audited at the start of each future wave.

| Refs | Module | Future-wave notes |
| --- | --- | --- |
| 2 | ChatPresentationInterfaceState | Public struct field `resource: TelegramMediaResource` — needs caller audit. |
| 2 | ItemListStickerPackItem | Enum case leaks `MediaResource` — needs caller audit. |
| 2 | TelegramCallsUI | Signal<TelegramMediaResource, …> locals; mostly type-refs. |
| 3 | LegacyMediaPickerUI | `thumbnailResource: TelegramMediaResource?` internal properties — likely safe. |
| 3 | ReactionSelectionNode | `customEffectResource: MediaResource?` in public func — caller audit. |
| 3 | TelegramAnimatedStickerNode | `public init(postbox: Postbox, resource: MediaResource, …)` + `public convenience init(account: Account, …)` — umbrella-type leaks; needs a paired wave. |
| 4 | GalleryUI | `private func setupStatus(resource: MediaResource)` — internal, 4 files. |
| 5 | StickerResources | Multiple public funcs take `postbox: Postbox, resource: MediaResource` / `mediaBox: MediaBox`. |
| 6 | PhotoResources | Similar to StickerResources; also `securePhoto(account: Account, resource: TelegramMediaResource, …)`. |
| 7 | MediaPlayer | `mediaBox: MediaBox, resource: MediaResource` in public init — umbrella leaks. |
| 7 | WebSearchUI | `thumbnailResource: TelegramMediaResource?` in multiple structs/inits. |
| 8 | AccountContext | Protocol surface — audit carefully. |
| 8 | SoftwareVideo | Public init takes `mediaBox: MediaBox` + `resource: MediaResource`. |
| 12 | LocalMediaResources | Contains `VideoLibraryMediaResource: TelegramMediaResource` — blocked for conformance. |
| 14 | LegacyDataImport | Legacy path; audit scope. |
| 25 | PassportUI | Large surface; break into multiple tasks. |
| 36 | TelegramUI | Umbrella module; never as one wave. |

**Blocked-by-conformance modules, explicitly out of all waves:**

- `submodules/ICloudResources/Sources/ICloudResources.swift` — `ICloudFileResource`
- `submodules/InstantPageUI/Sources/InstantPageExternalMediaResource.swift` — `InstantPageExternalMediaResource`
- `submodules/LocalMediaResources/Sources/LocalMediaResources.swift` — `VideoLibraryMediaResource`
- `submodules/TelegramUniversalVideoContent/Sources/YoutubeEmbedImplementation.swift` — `YoutubeEmbedStoryboardMediaResource`

These classes must conform to `TelegramMediaResource` to satisfy the PostboxCoding serialization contract. They remain `import Postbox`.

---

## What's explicitly NOT in this plan

- Adding opt-in `EngineMediaResource` overloads alongside raw-`MediaResource` overloads. The facade is changed in place.
- Touching any class conforming to `TelegramMediaResource`.
- Editing `TelegramUI`, `PassportUI`, `LegacyDataImport`, or the other heavy-ref modules in the Future-waves table beyond what the Phase-1 call-site migrations require.
- Importing UIKit/Display into TelegramCore under any circumstance.
- Modifying `_internal_*` functions in TelegramCore — they stay on raw `MediaResource`.
- Any behavior change, performance tweak, or "while we're here" cleanup.
