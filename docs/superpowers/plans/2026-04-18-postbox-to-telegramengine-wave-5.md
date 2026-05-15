# Postbox → TelegramEngine Wave 5 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `uploadSecureIdFile`'s public surface to `(context:, engine: TelegramEngine, resource: EngineMediaResource)`, refactor `SecureIdVerificationDocumentsContext` to take `engine: TelegramEngine` in place of raw `Postbox` + `Network`, and drop `import Postbox` from that caller module. Land as one atomic code commit + one CLAUDE.md tally commit on branch `refactor/postbox-to-engine-wave-5`.

**Architecture:** Three files land together in C1 because the facade signature change, the caller class's stored-property change, and the one instantiation site are mutually breaking. The facade body inside TelegramCore continues to access raw Postbox types via `engine.account.postbox` / `engine.account.network` — CLAUDE.md's "internal Postbox-facing stays raw" rule applies to the body, while the public signature is the clean surface. C2 updates the CLAUDE.md tally and removes the wave-5-named bullet from "Known future-wave candidates".

**Tech Stack:** Swift / Bazel. No unit tests by repo policy — verification is a full project build.

**Spec:** [docs/superpowers/specs/2026-04-18-postbox-to-telegramengine-wave-5-design.md](docs/superpowers/specs/2026-04-18-postbox-to-telegramengine-wave-5-design.md)

**Build command** (use for every "full build" step):

```bash
source ~/.zshrc 2>/dev/null; PATH=/opt/homebrew/opt/ruby/bin:`gem environment gemdir`/bin:$PATH python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber 1 --configuration debug_sim_arm64
```

The `source ~/.zshrc` prefix is required because `TELEGRAM_CODESIGNING_GIT_PASSWORD` lives in `~/.zshrc` and the bash tool does not source shell config by default. For a long-running build, prefer `run_in_background: true` from the controller session (subagent-spawned background builds orphan when the subagent's shell terminates).

---

## Task 1: Pre-flight re-verification

No code changes. Confirms the inventory hasn't drifted.

- [ ] **Step 1: Re-grep `uploadSecureIdFile` call sites**

```bash
grep -rnE "uploadSecureIdFile\(" submodules --include="*.swift" | grep -v "/SecureId/"
```

Expected: exactly 1 match — `submodules/PassportUI/Sources/SecureIdVerificationDocumentsContext.swift:43`. If the count or file has drifted, stop and revise the plan.

- [ ] **Step 2: Re-grep `SecureIdVerificationDocumentsContext(...)` instantiation sites**

```bash
grep -rnE "SecureIdVerificationDocumentsContext\(" submodules --include="*.swift" | grep -v "final class SecureIdVerificationDocumentsContext"
```

Expected: exactly 1 match — `submodules/PassportUI/Sources/SecureIdDocumentFormControllerNode.swift:2172`. If drift, stop.

- [ ] **Step 3: Confirm `AccountContext.engine` protocol requirement**

```bash
grep -nE "var engine: TelegramEngine" submodules/AccountContext/Sources/AccountContext.swift
```

Expected: one line matching `var engine: TelegramEngine { get }` (the protocol requirement). This confirms `self.context.engine` will be available at the instantiation site in Task 4.

- [ ] **Step 4: Confirm `info.resource` type**

```bash
grep -nE "let resource:" submodules/PassportUI/Sources/SecureIdVerificationDocument.swift
```

Expected: two matches, both showing `resource: TelegramMediaResource`. Confirms `EngineMediaResource(info.resource)` will compile (the `EngineMediaResource(_:)` init takes `MediaResource`, which `TelegramMediaResource` inherits).

---

## Task 2: Migrate `uploadSecureIdFile`'s public facade and body

No build; no commit. Tasks 2–4 share one atomic commit in Task 5.

**File:** `submodules/TelegramCore/Sources/TelegramEngine/SecureId/UploadSecureIdFile.swift`

- [ ] **Step 1: Replace the function signature and body**

Find the `uploadSecureIdFile` function (currently starts at line 90). Replace the entire function (from `public func uploadSecureIdFile` through its closing `}`) with this version:

```swift
public func uploadSecureIdFile(context: SecureIdAccessContext, engine: TelegramEngine, resource: EngineMediaResource) -> Signal<UploadSecureIdFileResult, UploadSecureIdFileError> {
    return engine.account.postbox.mediaBox.resourceData(resource._asResource())
    |> mapError { _ -> UploadSecureIdFileError in
    }
    |> mapToSignal { next -> Signal<UploadSecureIdFileResult, UploadSecureIdFileError> in
        if !next.complete {
            return .complete()
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: next.path)) else {
            return .fail(.generic)
        }
        
        guard let encryptedData = encryptedSecureIdFile(context: context, data: data) else {
            return .fail(.generic)
        }
        
        return multipartUpload(network: engine.account.network, postbox: engine.account.postbox, source: .data(encryptedData.data), encrypt: false, tag: TelegramMediaResourceFetchTag(statsCategory: .image, userContentType: .image), hintFileSize: nil, hintFileIsLarge: false, forceNoBigParts: false)
        |> mapError { _ -> UploadSecureIdFileError in
            return .generic
        }
        |> mapToSignal { result -> Signal<UploadSecureIdFileResult, UploadSecureIdFileError> in
            switch result {
                case let .progress(value):
                    return .single(.progress(value))
                case let .inputFile(.inputFile(fileData)):
                    return .single(.result(UploadedSecureIdFile(id: fileData.id, parts: fileData.parts, md5Checksum: fileData.md5Checksum, fileHash: encryptedData.hash, encryptedSecret: encryptedData.encryptedSecret), encryptedData.data))
                default:
                    return .fail(.generic)
            }
        }
    }
}
```

Changes from the original:

- Signature: `(context: SecureIdAccessContext, postbox: Postbox, network: Network, resource: MediaResource)` → `(context: SecureIdAccessContext, engine: TelegramEngine, resource: EngineMediaResource)`.
- Line 1 of body: `postbox.mediaBox.resourceData(resource)` → `engine.account.postbox.mediaBox.resourceData(resource._asResource())`.
- Inside the `mapToSignal`: `multipartUpload(network: network, postbox: postbox, ...)` → `multipartUpload(network: engine.account.network, postbox: engine.account.postbox, ...)`.

No other file in `TelegramCore/Sources/TelegramEngine/SecureId/` is touched. No imports change inside `UploadSecureIdFile.swift` — it continues to `import Foundation`, `import Postbox`, `import MtProtoKit`, `import SwiftSignalKit`, which remain correct (the body still uses raw Postbox types via `engine.account.postbox`).

---

## Task 3: Migrate `SecureIdVerificationDocumentsContext`

No build; no commit.

**File:** `submodules/PassportUI/Sources/SecureIdVerificationDocumentsContext.swift`

- [ ] **Step 1: Drop `import Postbox`**

Replace the import block at the top (lines 1–4):

```swift
import Foundation
import Postbox
import TelegramCore
import SwiftSignalKit
```

with:

```swift
import Foundation
import TelegramCore
import SwiftSignalKit
```

Only `Postbox` is removed. The three remaining imports stay.

- [ ] **Step 2: Replace stored properties**

Find the `final class SecureIdVerificationDocumentsContext` block (starting around line 18). Replace lines 20–21:

```swift
    private let postbox: Postbox
    private let network: Network
```

with:

```swift
    private let engine: TelegramEngine
```

- [ ] **Step 3: Update the constructor**

Replace the `init` (lines 26–31):

```swift
    init(postbox: Postbox, network: Network, context: SecureIdAccessContext, update: @escaping (Int64, SecureIdVerificationLocalDocumentState) -> Void) {
        self.postbox = postbox
        self.network = network
        self.context = context
        self.update = update
    }
```

with:

```swift
    init(engine: TelegramEngine, context: SecureIdAccessContext, update: @escaping (Int64, SecureIdVerificationLocalDocumentState) -> Void) {
        self.engine = engine
        self.context = context
        self.update = update
    }
```

- [ ] **Step 4: Update the `uploadSecureIdFile` call inside `stateUpdated`**

Find line 43, which currently reads:

```swift
                        disposable.set((uploadSecureIdFile(context: self.context, postbox: self.postbox, network: self.network, resource: info.resource)
```

Replace with:

```swift
                        disposable.set((uploadSecureIdFile(context: self.context, engine: self.engine, resource: EngineMediaResource(info.resource))
```

Two changes:
- `postbox: self.postbox, network: self.network` → `engine: self.engine`.
- `resource: info.resource` → `resource: EngineMediaResource(info.resource)`.

No other line in this file changes. The `DocumentContext` inner class is untouched. The `stateUpdated` method's outer structure is untouched.

---

## Task 4: Update the instantiation site

No build; no commit.

**File:** `submodules/PassportUI/Sources/SecureIdDocumentFormControllerNode.swift`

- [ ] **Step 1: Update line 2172**

Find line 2172, which currently reads:

```swift
        self.uploadContext = SecureIdVerificationDocumentsContext(postbox: self.context.account.postbox, network: self.context.account.network, context: self.secureIdContext, update: { id, state in
```

Replace with:

```swift
        self.uploadContext = SecureIdVerificationDocumentsContext(engine: self.context.engine, context: self.secureIdContext, update: { id, state in
```

Two removed arguments (`postbox:`, `network:`) collapse into one new argument (`engine:`). The closure body inside `update: { id, state in ... }` is unchanged.

No other line in this file changes. The file continues to `import Postbox` for unrelated reasons — this is expected, do not remove.

---

## Task 5: Full build and commit C1

- [ ] **Step 1: Run the full project build**

Run the build command from the header. Expected: clean success.

Typical failure modes and fixes (do them inline — do not split):

- **"cannot convert value of type 'Postbox' to expected argument type 'TelegramEngine'"** — a call site was missed. Re-grep both `uploadSecureIdFile(` and `SecureIdVerificationDocumentsContext(` across the repo.
- **"cannot convert value of type 'MediaResource' to expected argument type 'EngineMediaResource'"** — Task 3 Step 4's `EngineMediaResource(info.resource)` wrap was missed.
- **"use of unresolved identifier 'Network'"** or **"use of unresolved identifier 'Postbox'"** inside `SecureIdVerificationDocumentsContext.swift`** — Tasks 3 Steps 2–3 or 4 weren't fully applied.
- **"missing argument for parameter 'engine'"** — the Task 4 call site wasn't updated.

Re-run the build after each fix.

- [ ] **Step 2: Stage the three files**

```bash
git add \
  submodules/TelegramCore/Sources/TelegramEngine/SecureId/UploadSecureIdFile.swift \
  submodules/PassportUI/Sources/SecureIdVerificationDocumentsContext.swift \
  submodules/PassportUI/Sources/SecureIdDocumentFormControllerNode.swift
```

- [ ] **Step 3: Verify diff scope**

```bash
git diff --staged --stat
```

Expected: exactly 3 files staged. Approximate line changes:
- `UploadSecureIdFile.swift`: ~3 lines (signature + 2 body sites).
- `SecureIdVerificationDocumentsContext.swift`: ~8 lines (1 import removed, stored props, constructor, call site).
- `SecureIdDocumentFormControllerNode.swift`: 1 line.

- [ ] **Step 4: Commit C1**

```bash
git commit -m "$(cat <<'EOF'
SecureId: migrate uploadSecureIdFile + context to TelegramEngine

uploadSecureIdFile's public signature now takes engine: TelegramEngine
and resource: EngineMediaResource instead of raw postbox: Postbox +
network: Network + MediaResource. The function body accesses raw
Postbox types via engine.account.postbox / engine.account.network
(internal Postbox-facing layer stays raw per CLAUDE.md).

SecureIdVerificationDocumentsContext refactored in lockstep: stores
engine: TelegramEngine instead of raw postbox + network, drops
import Postbox. The one instantiation site in
SecureIdDocumentFormControllerNode updates to pass engine:
self.context.engine.

Wave-5 of the Postbox -> TelegramEngine refactor; completes the last
explicitly-named future-wave candidate.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 5: Verify branch state**

```bash
git log --oneline master..HEAD
```

Expected (newest at top):
- `<sha> SecureId: migrate uploadSecureIdFile + context to TelegramEngine`
- `b7a1a5dfb0 docs(spec): wave-5 uploadSecureIdFile facade + SecureId context migration`

---

## Task 6: Update CLAUDE.md tally and commit C2

- [ ] **Step 1: Add `SecureIdVerificationDocumentsContext` to the Postbox-free tally**

Open `CLAUDE.md`. Find the "Modules currently free of `import Postbox` (running tally)" section. Add `- SecureIdVerificationDocumentsContext (wave 5)` as the last bullet in the list, immediately after `- SaveToCameraRoll (wave 3)`:

```markdown
- `MapResourceToAvatarSizes` (wave 2)
- `SaveToCameraRoll` (wave 3)
- `SecureIdVerificationDocumentsContext` (wave 5)
```

- [ ] **Step 2: Add a "Wave 5 outcome" subsection**

Still in `CLAUDE.md`, find the "Wave 4 outcome (2026-04-18)" block. Insert a new "Wave 5 outcome" subsection **after** Wave 4 and **before** "Modules currently free of `import Postbox`":

```markdown
### Wave 5 outcome (2026-04-18)

Completes the last explicitly-named future-wave candidate from the wave-2 final review.

`uploadSecureIdFile(context: SecureIdAccessContext, postbox: Postbox, network: Network, resource: MediaResource)` migrated in place to `(context:, engine: TelegramEngine, resource: EngineMediaResource)`. Function body accesses raw Postbox types via `engine.account.postbox` / `engine.account.network` (internal Postbox-facing layer stays raw per the standing rule).

1 consumer submodule fully de-Postboxed: `SecureIdVerificationDocumentsContext` (PassportUI/Sources). Signature changed from `(postbox: Postbox, network: Network, context: SecureIdAccessContext, update: ...)` to `(engine: TelegramEngine, context: SecureIdAccessContext, update: ...)`; stored props collapsed into a single `engine: TelegramEngine` field. One instantiation site updated in the same commit.

After this wave, the "Known future-wave candidates" list contains only the 4 permanently-blocked classes conforming to `TelegramMediaResource`.

Plan: `docs/superpowers/plans/2026-04-18-postbox-to-telegramengine-wave-5.md`
```

- [ ] **Step 3: Remove the `uploadSecureIdFile` bullet from "Known future-wave candidates"**

Still in `CLAUDE.md`, find the "Known future-wave candidates" list. Delete this bullet entirely:

```markdown
- `submodules/TelegramCore/Sources/TelegramEngine/SecureId/UploadSecureIdFile.swift: public func uploadSecureIdFile(…, postbox: Postbox, …, resource: MediaResource)` — rule-2-sensitive (umbrella-type leak). Needs a paired wave with its caller(s).
```

Do not touch the remaining bullet about permanently-blocked classes.

- [ ] **Step 4: Commit C2**

```bash
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
CLAUDE.md: record wave-5 outcome

Adds SecureIdVerificationDocumentsContext to the Postbox-free module
tally, documents the uploadSecureIdFile facade migration, and removes
the uploadSecureIdFile bullet from "Known future-wave candidates".
After this wave, the candidate list contains only the 4 permanently-
blocked TelegramMediaResource-conforming classes.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 5: Verify final branch state**

```bash
git log --oneline master..HEAD
```

Expected:
- `<sha> CLAUDE.md: record wave-5 outcome`
- `<sha> SecureId: migrate uploadSecureIdFile + context to TelegramEngine`
- `b7a1a5dfb0 docs(spec): wave-5 uploadSecureIdFile facade + SecureId context migration`

---

## Success criteria

- `uploadSecureIdFile`'s public signature references neither `Postbox`, `Network`, nor `MediaResource`.
- `SecureIdVerificationDocumentsContext.swift` does not contain `import Postbox`.
- Full build succeeds in `debug_sim_arm64`.
- `grep -l "import Postbox" submodules/PassportUI/Sources/SecureIdVerificationDocumentsContext.swift` returns no match.
- `CLAUDE.md`'s "Known future-wave candidates" list no longer mentions `uploadSecureIdFile`; the Postbox-free running tally includes `SecureIdVerificationDocumentsContext (wave 5)`.
- Branch `refactor/postbox-to-engine-wave-5` contains 3 commits above `master`: 1 doc (spec) + 1 code (C1) + 1 tally (C2).
