# Wave 106 Pivot: engine `data(resource:incremental:)` facade extension + 1-site drain

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Pivot wave 106 from the abandoned import-drop sweep to a small facade-extension wave. Add an `incremental: Bool = false` parameter to `TelegramEngine.Resources.data(resource:)`, drain the 1 live `account.postbox.mediaBox.resourceData(..., option: .incremental(...))` consumer site (`ChatInterfaceStateContextMenus.swift:1327`).

**Background — wave 106 (pure sweep) abandoned 2026-04-26:** Inventory of 576 candidate files showed every one of them legitimately references at least one Postbox-tier token (Postbox/MediaBox/MediaResource/protocol-Peer/protocol-Message/protocol-Media/typealiased identifier). Wave 93's pure import-sweep pattern is exhausted at the file granularity — no single-file orphans remain. See spec `docs/superpowers/specs/2026-04-26-postbox-wave-106-import-drop-sweep-design.md` (committed) for the abandoned methodology.

**Architecture:** Wave-shape G (facade addition + small validation drain). 2 file edits (1 in TelegramCore, 1 in TelegramUI). Single-iter expected.

**Tech Stack:** Swift, Bazel via `Make.py`, no unit tests. Verification is the full-project debug-sim-arm64 build.

**Iteration budget:** 1-2 (TelegramCore touch incurs ~210-260s build).

---

## File Structure

| File | Role | Edits |
|---|---|---|
| `submodules/TelegramCore/Sources/TelegramEngine/Resources/TelegramEngineResources.swift` | Add `incremental` param to `data(resource:)` facade | 1 Edit (signature + body) |
| `submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift` | Migrate L1327 call site | 1 Edit (call + `data.complete` → `data.isComplete`) |

---

## Task 1: Extend the engine `data(resource:)` facade with `incremental:` parameter

**File:** `submodules/TelegramCore/Sources/TelegramEngine/Resources/TelegramEngineResources.swift`

- [ ] **Step 1: Edit the `data(resource:)` facade signature and body**

Find at line 453-466:

```swift
        public func data(
            resource: EngineMediaResource,
            pathExtension: String? = nil,
            waitUntilFetchStatus: Bool = false,
            attemptSynchronously: Bool = false
        ) -> Signal<EngineMediaResource.ResourceData, NoError> {
            return self.account.postbox.mediaBox.resourceData(
                resource._asResource(),
                pathExtension: pathExtension,
                option: .complete(waitUntilFetchStatus: waitUntilFetchStatus),
                attemptSynchronously: attemptSynchronously
            )
            |> map { EngineMediaResource.ResourceData($0) }
        }
```

Replace with:

```swift
        public func data(
            resource: EngineMediaResource,
            pathExtension: String? = nil,
            waitUntilFetchStatus: Bool = false,
            incremental: Bool = false,
            attemptSynchronously: Bool = false
        ) -> Signal<EngineMediaResource.ResourceData, NoError> {
            let option: MediaBoxFetchDataOption = incremental
                ? .incremental(waitUntilFetchStatus: waitUntilFetchStatus)
                : .complete(waitUntilFetchStatus: waitUntilFetchStatus)
            return self.account.postbox.mediaBox.resourceData(
                resource._asResource(),
                pathExtension: pathExtension,
                option: option,
                attemptSynchronously: attemptSynchronously
            )
            |> map { EngineMediaResource.ResourceData($0) }
        }
```

The `incremental` parameter is inserted between `waitUntilFetchStatus` and `attemptSynchronously`. Existing call sites passing only labeled-or-trailing arguments remain compatible because Swift requires labels for these (no positional ordering issue).

---

## Task 2: Migrate the consumer call site

**File:** `submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift`

- [ ] **Step 1: Edit L1327 — replace `account.postbox.mediaBox.resourceData(...)` with engine facade**

Find at line 1327:

```swift
                                            let _ = (context.account.postbox.mediaBox.resourceData(largest.resource, option: .incremental(waitUntilFetchStatus: false))
```

Replace with:

```swift
                                            let _ = (context.engine.resources.data(resource: EngineMediaResource(largest.resource), incremental: true)
```

- [ ] **Step 2: Rename downstream `data.complete` field access to `data.isComplete`**

Find at line 1330:

```swift
                                                if data.complete, let imageData = try? Data(contentsOf: URL(fileURLWithPath: data.path)) {
```

Replace with:

```swift
                                                if data.isComplete, let imageData = try? Data(contentsOf: URL(fileURLWithPath: data.path)) {
```

The `.path` field name is unchanged (both `MediaResourceData` and `EngineMediaResource.ResourceData` use `path`).

---

## Task 3: Verify residue and build

- [ ] **Step 1: Residue grep for the migrated expression**

Run:

```sh
grep -nE "context\.account\.postbox\.mediaBox\.resourceData\(.*option: \.incremental" submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift
```

Expected: empty.

- [ ] **Step 2: Verify the new facade signature compiles without breaking existing callers**

Existing call sites of `engine.resources.data(resource:)` use these forms (per wave 32+ history):
- `engine.resources.data(resource: EngineMediaResource(x))` — default args, fine
- `engine.resources.data(resource: EngineMediaResource(x), pathExtension: "ext")` — labeled, fine
- `engine.resources.data(resource: EngineMediaResource(x), waitUntilFetchStatus: true)` — labeled, fine

Adding `incremental: Bool = false` between `waitUntilFetchStatus` and `attemptSynchronously` doesn't reorder existing call sites because all parameters use labels. Confirm with grep:

```sh
grep -rnE "engine\.resources\.data\(resource:" submodules --include="*.swift" | wc -l
```

Just for visibility — number of existing call sites that should remain green.

- [ ] **Step 3: Run the full clean build**

Run:

```sh
source ~/.zshrc 2>/dev/null && \
python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 \
 --configuration=debug_sim_arm64 2>&1 | tail -30
```

Expected: build success, no errors. If failure, fix in place and re-run (single iter expected).

---

## Task 4: Commit the wave

- [ ] **Step 1: Inspect diff**

Run:

```sh
git diff --stat
```

Expected: 2 files modified.

- [ ] **Step 2: Stage and commit**

```sh
git add submodules/TelegramCore/Sources/TelegramEngine/Resources/TelegramEngineResources.swift \
        submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift

git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 106 (pivot: engine data() incremental facade + 1-site drain)

Original wave 106 pure import-drop sweep abandoned: 576 candidate files
all genuinely reference Postbox-tier tokens; wave 93's pattern exhausted
at file granularity (no single-file orphans remain).

Pivot: extend engine.resources.data(resource:) facade with
`incremental: Bool = false` parameter. Drain the 1 live consumer site
(ChatInterfaceStateContextMenus:1327) plus consumer-side
`data.complete` -> `data.isComplete` rename.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Update memory file

**File:** `/Users/isaac/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`

- [ ] **Step 1: Update frontmatter description and append wave 106 entries**

Update the `description:` line to reflect wave 106 (pivot).

Append two lines under the recent-commits section:
- One for the abandoned wave 106 import-drop sweep with the key finding (sweep pattern exhausted, save future sessions a re-attempt).
- One for the wave 106 pivot commit hash with cost/yield.

- [ ] **Step 2: Append a "Wave 106 ABANDONED" subsection** documenting the import-sweep exhaustion finding so future sessions don't re-attempt the pure sweep shape. Note the regex set tested and the conclusion ("any consumer file with `import Postbox` legitimately needs at least one Tier-1/Tier-2 token").

---

## Halt-and-revert recipe

If build fails for non-trivial reasons (more than 1 iter):

```sh
git checkout -- submodules/TelegramCore/Sources/TelegramEngine/Resources/TelegramEngineResources.swift \
                submodules/TelegramUI/Sources/ChatInterfaceStateContextMenus.swift
git status --short
```

Wave is reversible until Task 4 commits.
