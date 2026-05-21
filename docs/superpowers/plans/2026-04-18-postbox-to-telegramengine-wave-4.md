# Postbox → TelegramEngine Wave 4 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `TelegramEngine.Stickers.uploadSticker`'s public surface — `peer: Peer → EnginePeer`, `resource: MediaResource → EngineMediaResource`, `thumbnail: MediaResource? → EngineMediaResource?`, and `UploadStickerStatus.complete(CloudDocumentMediaResource, String) → .complete(EngineMediaResource, String)` — with one atomic commit touching the facade, the internal enum, and the two call sites.

**Architecture:** Two commits on branch `refactor/postbox-to-engine-wave-4`. C1 is the atomic four-file code change. C2 is the CLAUDE.md tally update. `_internal_uploadSticker` keeps its raw `Peer`/`MediaResource` signature; the facade does all the wrapping/unwrapping. One spec-allowed one-line exception: `_internal_uploadSticker` constructs `EngineMediaResource(uploadedResource)` at the `.complete(...)` result-construction site to keep `UploadStickerStatus` as a single enum instead of splitting into raw+engine variants.

**Tech Stack:** Swift / Bazel. No unit tests in this repo — verification is a full project build.

**Spec:** [docs/superpowers/specs/2026-04-18-postbox-to-telegramengine-wave-4-design.md](docs/superpowers/specs/2026-04-18-postbox-to-telegramengine-wave-4-design.md)

**Build command** (use for every "full build" step):

```bash
source ~/.zshrc 2>/dev/null; PATH=/opt/homebrew/opt/ruby/bin:`gem environment gemdir`/bin:$PATH python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber 1 --configuration debug_sim_arm64
```

The `source ~/.zshrc` prefix is required because `TELEGRAM_CODESIGNING_GIT_PASSWORD` lives in `~/.zshrc` and the bash tool does not source shell config by default. For a background build from the controller session, prefer `run_in_background: true` and monitor by tailing the task output file (subagent-spawned background builds orphan when the subagent shell terminates).

---

## Task 1: Pre-flight re-verification

No code changes. Purpose: re-confirm the facade call-site count and the MediaEditorScreen line numbers haven't drifted.

**Files:** (read-only)

- [ ] **Step 1: Re-grep facade call sites**

```bash
grep -rnE "\.uploadSticker\(" submodules --include="*.swift" \
  | grep -v "/TelegramEngine/Stickers/" \
  | grep -v "self\.uploadSticker\|strongSelf\.uploadSticker\|self\?\.uploadSticker"
```

Expected output: exactly 2 lines

- `submodules/ImportStickerPackUI/Sources/ImportStickerPackController.swift:91`
- `submodules/TelegramUI/Components/MediaEditorScreen/Sources/MediaEditorScreen.swift:8099`

If the count or line numbers have drifted meaningfully, stop and revise the plan before editing.

- [ ] **Step 2: Re-read MediaEditorScreen block**

```bash
sed -n '8080,8190p' submodules/TelegramUI/Components/MediaEditorScreen/Sources/MediaEditorScreen.swift
```

Visually confirm:
- Line ~8097 has `.complete(resource, mimeType)` inside an `if let resource = resource as? CloudDocumentMediaResource { … }` branch.
- Line ~8099 has `context.engine.stickers.uploadSticker(peer: peer._asPeer(), resource: resource, thumbnail: file.previewRepresentations.first?.resource, …)`.
- Line ~8105 has `case let .complete(resource, _):` destructuring the inner `.mapToSignal` status.
- Line ~8106 has `stickerFile(resource: resource, thumbnailResource: file.previewRepresentations.first?.resource, …)`.
- Line ~8119 has `ImportSticker(resource: .standalone(resource: resource), …)` inside `case let .createStickerPack(title):`.
- Line ~8138 has a second `ImportSticker(resource: .standalone(resource: resource), …)` inside `case let .addToStickerPack(pack, title):`.
- Line ~8178 has a second `case let .complete(resource, _):` in the outer `.startStandalone(next: …)` handler.
- Line ~8180 has `stickerFile(resource: resource, thumbnailResource: file.previewRepresentations.first?.resource, size: resource.size ?? 0, …)`.

- [ ] **Step 3: Confirm `stickerFile` signature**

```bash
grep -nE "^private func stickerFile\(" submodules/TelegramUI/Components/MediaEditorScreen/Sources/MediaEditorScreen.swift
```

Expected: `private func stickerFile(resource: TelegramMediaResource, thumbnailResource: TelegramMediaResource?, size: Int64, dimensions: PixelDimensions, duration: Double?, isVideo: Bool) -> TelegramMediaFile` at line ~9196. This confirms `stickerFile` takes `TelegramMediaResource` (requires `resource._asResource()` at every call).

- [ ] **Step 4: Confirm ImportStickerPackController's `peer` type**

```bash
sed -n '82,95p' submodules/ImportStickerPackUI/Sources/ImportStickerPackController.swift
```

Expected pattern:
```swift
let _ = (self.context.account.postbox.loadedPeerWithId(self.context.account.peerId)
|> deliverOnMainQueue).start(next: { [weak self] peer in
```

`postbox.loadedPeerWithId` returns `Signal<Peer, NoError>`. The local `peer` is therefore a raw `Peer`, not an `EnginePeer`. The call-site edit will need `EnginePeer(peer)` to wrap.

If any of these expectations fails to match the current source, stop and revise the plan.

---

## Task 2: Migrate `UploadStickerStatus` enum and internal wrap

No build; the project won't compile until Tasks 3–5 also land. Do not commit.

**File:** `submodules/TelegramCore/Sources/TelegramEngine/Stickers/ImportStickers.swift`

- [ ] **Step 1: Update enum payload (line 7–10)**

Replace:

```swift
public enum UploadStickerStatus {
    case progress(Float)
    case complete(CloudDocumentMediaResource, String)
}
```

with:

```swift
public enum UploadStickerStatus {
    case progress(Float)
    case complete(EngineMediaResource, String)
}
```

- [ ] **Step 2: Update the `.complete(...)` construction in `_internal_uploadSticker` (line ~97)**

Replace the line reading:

```swift
                                        return .single(.complete(uploadedResource, file.mimeType))
```

with:

```swift
                                        return .single(.complete(EngineMediaResource(uploadedResource), file.mimeType))
```

Nothing else in `_internal_uploadSticker` changes. In particular its parameter list (`peer: Peer, resource: MediaResource, thumbnail: MediaResource? = nil, …`) stays exactly as is.

---

## Task 3: Migrate the public facade signature

No build; no commit.

**File:** `submodules/TelegramCore/Sources/TelegramEngine/Stickers/TelegramEngineStickers.swift`

- [ ] **Step 1: Update the `uploadSticker` facade (line 85–87)**

Replace:

```swift
        public func uploadSticker(peer: Peer, resource: MediaResource, thumbnail: MediaResource?, alt: String, dimensions: PixelDimensions, duration: Double?, mimeType: String) -> Signal<UploadStickerStatus, UploadStickerError> {
            return _internal_uploadSticker(account: self.account, peer: peer, resource: resource, thumbnail: thumbnail, alt: alt, dimensions: dimensions, duration: duration, mimeType: mimeType)
        }
```

with:

```swift
        public func uploadSticker(peer: EnginePeer, resource: EngineMediaResource, thumbnail: EngineMediaResource?, alt: String, dimensions: PixelDimensions, duration: Double?, mimeType: String) -> Signal<UploadStickerStatus, UploadStickerError> {
            return _internal_uploadSticker(account: self.account, peer: peer._asPeer(), resource: resource._asResource(), thumbnail: thumbnail?._asResource(), alt: alt, dimensions: dimensions, duration: duration, mimeType: mimeType)
        }
```

No other method in `TelegramEngineStickers.swift` changes.

---

## Task 4: Migrate `ImportStickerPackController.swift:91`

No build; no commit.

**File:** `submodules/ImportStickerPackUI/Sources/ImportStickerPackController.swift`

- [ ] **Step 1: Update the facade call (line ~91)**

Replace:

```swift
                            signals.append(strongSelf.context.engine.stickers.uploadSticker(peer: peer, resource: resource._asResource(), thumbnail: nil, alt: sticker.emojis.first ?? "", dimensions: PixelDimensions(width: 512, height: 512), duration: nil, mimeType: sticker.mimeType)
```

with:

```swift
                            signals.append(strongSelf.context.engine.stickers.uploadSticker(peer: EnginePeer(peer), resource: resource, thumbnail: nil, alt: sticker.emojis.first ?? "", dimensions: PixelDimensions(width: 512, height: 512), duration: nil, mimeType: sticker.mimeType)
```

Two changes: `peer` (raw `Peer`) → `EnginePeer(peer)`, and `resource._asResource()` → `resource` (the local `resource` is an `EngineMediaResource`).

- [ ] **Step 2: Update the destructure re-wrap (line ~99)**

Replace:

```swift
                                    case let .complete(resource, mimeType):
                                        if ["application/x-tgsticker", "video/webm"].contains(mimeType) {
                                            return (sticker.uuid, .verified, EngineMediaResource(resource))
                                        } else {
```

with:

```swift
                                    case let .complete(resource, mimeType):
                                        if ["application/x-tgsticker", "video/webm"].contains(mimeType) {
                                            return (sticker.uuid, .verified, resource)
                                        } else {
```

One change: `EngineMediaResource(resource)` → `resource`. The destructured `resource` is now already an `EngineMediaResource`.

Nothing else in this file changes.

---

## Task 5: Migrate `MediaEditorScreen.swift` sticker-upload block

No build; no commit. This task touches multiple lines inside a single nested block (~8084–8190). The `UploadStickerStatus` payload migration cascades: wherever the code constructs or destructures `.complete(...)`, types change.

**File:** `submodules/TelegramUI/Components/MediaEditorScreen/Sources/MediaEditorScreen.swift`

- [ ] **Step 1: Wrap at the direct construction site (line ~8097)**

Replace the line reading:

```swift
                        return .single((.progress(1.0), nil)) |> then(.single((.complete(resource, mimeType), nil)))
```

with:

```swift
                        return .single((.progress(1.0), nil)) |> then(.single((.complete(EngineMediaResource(resource), mimeType), nil)))
```

Context: this is inside `if let resource = resource as? CloudDocumentMediaResource { … }`, so `resource` here is `CloudDocumentMediaResource`; the outer tuple's `UploadStickerStatus.complete` now takes `EngineMediaResource`.

- [ ] **Step 2: Migrate the facade call (line ~8099)**

Replace:

```swift
                    return context.engine.stickers.uploadSticker(peer: peer._asPeer(), resource: resource, thumbnail: file.previewRepresentations.first?.resource, alt: "", dimensions: dimensions, duration: duration, mimeType: mimeType)
```

with:

```swift
                    return context.engine.stickers.uploadSticker(peer: peer, resource: EngineMediaResource(resource), thumbnail: file.previewRepresentations.first.flatMap { EngineMediaResource($0.resource) }, alt: "", dimensions: dimensions, duration: duration, mimeType: mimeType)
```

Three changes: `peer._asPeer()` → `peer` (local is `EnginePeer`); `resource` → `EngineMediaResource(resource)` (local is raw `MediaResource` from the outer enum destructure); `file.previewRepresentations.first?.resource` → `file.previewRepresentations.first.flatMap { EngineMediaResource($0.resource) }`.

- [ ] **Step 3: Unwrap at inner-handler `stickerFile` call (line ~8106)**

Replace:

```swift
                            case let .complete(resource, _):
                                let file = stickerFile(resource: resource, thumbnailResource: file.previewRepresentations.first?.resource, size: file.size ?? 0, dimensions: dimensions, duration: file.duration, isVideo: isVideo)
```

with:

```swift
                            case let .complete(resource, _):
                                let file = stickerFile(resource: resource._asResource(), thumbnailResource: file.previewRepresentations.first?.resource, size: file.size ?? 0, dimensions: dimensions, duration: file.duration, isVideo: isVideo)
```

The destructured `resource` is now an `EngineMediaResource`. `stickerFile` (see line 9196) takes `TelegramMediaResource`, so unwrap with `._asResource()`. `file.previewRepresentations.first?.resource` is already a `TelegramMediaResource?` — no change there.

- [ ] **Step 4: Unwrap at `.createStickerPack` sticker construction (line ~8119)**

Replace:

```swift
                                case let .createStickerPack(title):
                                    let sticker = ImportSticker(
                                        resource: .standalone(resource: resource),
                                        emojis: emojis,
                                        dimensions: dimensions,
                                        duration: duration,
                                        mimeType: mimeType,
                                        keywords: ""
                                    )
```

with:

```swift
                                case let .createStickerPack(title):
                                    let sticker = ImportSticker(
                                        resource: .standalone(resource: resource._asResource()),
                                        emojis: emojis,
                                        dimensions: dimensions,
                                        duration: duration,
                                        mimeType: mimeType,
                                        keywords: ""
                                    )
```

`MediaResourceReference.standalone(resource:)` takes `MediaResource`; `resource` here is the `EngineMediaResource` destructured at line ~8105. Unwrap with `._asResource()`.

- [ ] **Step 5: Unwrap at `.addToStickerPack` sticker construction (line ~8138)**

Replace:

```swift
                                case let .addToStickerPack(pack, title):
                                    let sticker = ImportSticker(
                                        resource: .standalone(resource: resource),
                                        emojis: emojis,
                                        dimensions: dimensions,
                                        duration: duration,
                                        mimeType: mimeType,
                                        keywords: ""
                                    )
```

with:

```swift
                                case let .addToStickerPack(pack, title):
                                    let sticker = ImportSticker(
                                        resource: .standalone(resource: resource._asResource()),
                                        emojis: emojis,
                                        dimensions: dimensions,
                                        duration: duration,
                                        mimeType: mimeType,
                                        keywords: ""
                                    )
```

Same unwrap as Step 4.

- [ ] **Step 6: Unwrap at outer-handler `stickerFile` call (line ~8178–8180)**

Replace:

```swift
            case let .complete(resource, _):
                let navigationController = self.effectiveNavigationController as? NavigationController
                
                let result: MediaEditorScreenImpl.Result
                switch action {
                case .update:
                    result = MediaEditorScreenImpl.Result(media: .sticker(file: file, emoji: emojis))
                case .upload, .send:
                    let file = stickerFile(resource: resource, thumbnailResource: file.previewRepresentations.first?.resource, size: resource.size ?? 0, dimensions: dimensions, duration: self.preferredStickerDuration(), isVideo: isVideo)
```

with:

```swift
            case let .complete(resource, _):
                let rawResource = resource._asResource()
                let navigationController = self.effectiveNavigationController as? NavigationController
                
                let result: MediaEditorScreenImpl.Result
                switch action {
                case .update:
                    result = MediaEditorScreenImpl.Result(media: .sticker(file: file, emoji: emojis))
                case .upload, .send:
                    let file = stickerFile(resource: rawResource, thumbnailResource: file.previewRepresentations.first?.resource, size: rawResource.size ?? 0, dimensions: dimensions, duration: self.preferredStickerDuration(), isVideo: isVideo)
```

Two changes: introduce `let rawResource = resource._asResource()` at the top of the `case let .complete(resource, _):` block, and use `rawResource` at both the `resource:` argument and the `size: rawResource.size ?? 0` read. (`EngineMediaResource` does not expose `.size`; only the raw `MediaResource` does.)

- [ ] **Step 7: Scan for any missed downstream use**

Run inside the repo:

```bash
sed -n '8080,8200p' submodules/TelegramUI/Components/MediaEditorScreen/Sources/MediaEditorScreen.swift | grep -nE "\bresource\b"
```

Skim the output. Every reference to the destructured `resource` inside the nested block (lines ~8084–8190) should either be the new `EngineMediaResource`-typed local or a wrapped/unwrapped form. If you spot a use that would still expect `CloudDocumentMediaResource`-specific members or raw `MediaResource` without the unwrap, stop and report.

---

## Task 6: Full build and commit C1

- [ ] **Step 1: Run the full project build**

Run the build command from the header. Expected: clean success.

Typical failure modes and fixes (do them inline — do not split into another commit):

- **"cannot convert value of type 'Peer' to expected argument type 'EnginePeer'"** — a call site was missed or the wrap is misplaced.
- **"value of type 'EngineMediaResource' has no member 'size'"** — Task 5 Step 6 wasn't applied (or similar `.size`/`.id.stringRepresentation`/`.isEqual` access on `EngineMediaResource`).
- **"cannot convert value of type 'EngineMediaResource' to expected argument type 'TelegramMediaResource'"** — an `._asResource()` is missing at a `stickerFile(...)` or `.standalone(resource:)` call.
- **"reference to enum case 'UploadStickerStatus.complete' requires that 'CloudDocumentMediaResource' conform to 'something'"** — a `.complete(...)` construction site wasn't migrated to pass `EngineMediaResource`.

Re-run the build after each fix.

- [ ] **Step 2: Stage the 4 files**

```bash
git add \
  submodules/TelegramCore/Sources/TelegramEngine/Stickers/ImportStickers.swift \
  submodules/TelegramCore/Sources/TelegramEngine/Stickers/TelegramEngineStickers.swift \
  submodules/ImportStickerPackUI/Sources/ImportStickerPackController.swift \
  submodules/TelegramUI/Components/MediaEditorScreen/Sources/MediaEditorScreen.swift
```

- [ ] **Step 3: Verify diff scope**

```bash
git diff --staged --stat
```

Expected: exactly 4 files staged, with MediaEditorScreen having the largest diff (~8 line changes), ImportStickers ~2, TelegramEngineStickers ~2, ImportStickerPackController ~2.

- [ ] **Step 4: Commit**

```bash
git commit -m "$(cat <<'EOF'
TelegramEngine.Stickers.uploadSticker: migrate to EnginePeer + EngineMediaResource

Public facade and UploadStickerStatus.complete payload now use
EnginePeer and EngineMediaResource instead of raw Peer / MediaResource
/ CloudDocumentMediaResource. _internal_uploadSticker stays on raw
Postbox types with one inline EngineMediaResource(uploadedResource)
construction at the .complete result site.

Both call sites (ImportStickerPackController, MediaEditorScreen)
updated atomically in the same commit.

Wave-4 of the Postbox -> TelegramEngine refactor.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 5: Verify branch state**

```bash
git log --oneline master..HEAD
```

Expected (newest at top):

- `<sha> TelegramEngine.Stickers.uploadSticker: migrate to EnginePeer + EngineMediaResource`
- `b6392bce7c docs(spec): wave-4 enumerate MediaEditorScreen downstream edits`
- `59a01b0d4d docs(spec): wave-4 TelegramEngine.Stickers.uploadSticker facade migration`

---

## Task 7: Update CLAUDE.md tally and commit C2

- [ ] **Step 1: Add Wave 4 outcome subsection**

Open `CLAUDE.md`. Find the "Wave 3 outcome (2026-04-18)" section (currently around line 96 onward). Insert a new subsection **after** Wave 3's outcome block and **before** "### Modules currently free of `import Postbox` (running tally)":

```markdown
### Wave 4 outcome (2026-04-18)

1 `TelegramEngine` facade migrated in place to `EnginePeer` + `EngineMediaResource` (signatures changed; `_internal_uploadSticker` keeps raw `Peer`/`MediaResource`):

- `TelegramEngine.Stickers.uploadSticker(peer: Peer → EnginePeer, resource: MediaResource → EngineMediaResource, thumbnail: MediaResource? → EngineMediaResource?, …)`

1 public enum payload migrated: `UploadStickerStatus.complete(CloudDocumentMediaResource, String)` → `.complete(EngineMediaResource, String)`. The internal `_internal_uploadSticker` constructs `EngineMediaResource(uploadedResource)` at the result site — a narrow, spec-allowed one-line deviation from "internal Postbox-facing stays raw", taken to keep `UploadStickerStatus` as a single public enum.

2 call sites migrated atomically with the facade:
- `submodules/ImportStickerPackUI/Sources/ImportStickerPackController.swift:91`
- `submodules/TelegramUI/Components/MediaEditorScreen/Sources/MediaEditorScreen.swift:8099` (plus ~5 cascading sites in the same enclosing block for the new `UploadStickerStatus.complete` payload)

No module becomes Postbox-free in this wave (both caller files import Postbox for unrelated reasons).

Plan: `docs/superpowers/plans/2026-04-18-postbox-to-telegramengine-wave-4.md`
```

- [ ] **Step 2: Remove the `uploadSticker` entry from "Known future-wave candidates"**

Still in `CLAUDE.md`, find the "Known future-wave candidates" list and delete this bullet (currently around line 143):

```markdown
- `TelegramEngine.Stickers.uploadSticker(peer: Peer, resource: MediaResource, thumbnail: MediaResource?, …)` — same MediaResource migration as wave 2, plus `peer: Peer` which would naturally migrate to `EnginePeer` at the same time. Self-contained to a small number of call sites.
```

Do not touch the other bullets in that list.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
CLAUDE.md: record wave-4 outcome

Documents the uploadSticker facade migration + UploadStickerStatus
payload change; removes uploadSticker from the future-wave candidates
list.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Success criteria

- `TelegramEngine.Stickers.uploadSticker`'s public signature references neither `Peer` nor `MediaResource` nor `CloudDocumentMediaResource`.
- `UploadStickerStatus.complete`'s payload is `(EngineMediaResource, String)`.
- `_internal_uploadSticker`'s signature is unchanged (still raw `Peer` / `MediaResource`).
- Full build succeeds in `debug_sim_arm64`.
- The two call sites (`ImportStickerPackController`, `MediaEditorScreen`) and the cascading sites within MediaEditorScreen's nested block compile against the new types.
- `CLAUDE.md` has a "Wave 4 outcome (2026-04-18)" subsection; the `uploadSticker` bullet is gone from "Known future-wave candidates".
- Branch `refactor/postbox-to-engine-wave-4` contains 4 commits above `master`: 2 docs (spec + spec fix), 1 code (C1), 1 tally (C2).
