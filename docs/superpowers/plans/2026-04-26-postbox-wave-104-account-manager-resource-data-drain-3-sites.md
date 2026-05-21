# Wave 104: accountManager.mediaBox.resourceData drain (3 clean sites) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Drain 3 of 8 `accountManager.mediaBox.resourceData(...)` Shape-A sites against the existing wave-32 / wave-94 `AccountManagerResources.data(resource:)` facade. Wave 104 of the Postbox → TelegramEngine refactor.

**Architecture:** Wave-shape-G drain with a documented consumer field rename. Single-file consumer migration in `submodules/WallpaperResources/Sources/WallpaperResources.swift`. 3 call rewrites + 3 consumer-side `.complete` → `.isComplete` renames, 6 Edit calls total. The remaining 5 of the original 8 `resourceData` candidates are deferred (2 cross a `MediaResourceData` flow-out cascade, 3 are coupled to postbox-side via `combineLatest` typed tuples).

**Tech Stack:** Swift, Bazel via `Make.py`, no unit tests. Verification is the full-project debug-sim-arm64 build.

**Iteration budget:** 1 (target first-pass-clean given verified pre-flight inventory).

**Note on TDD:** This project has no unit tests. Each task writes the edits, then verifies via Bazel build + residue grep.

---

## File Structure

| File | Role | Changes |
|---|---|---|
| `submodules/WallpaperResources/Sources/WallpaperResources.swift` | Wallpaper resource pipeline | 3 call rewrites + 3 consumer renames |

No public-API ripple — leaf-consumer migration against an existing facade.

---

## Task 1: WallpaperResources.swift — call rewrites (3 edits)

**Files:**
- Modify: `submodules/WallpaperResources/Sources/WallpaperResources.swift`

**Edits in this task:** 3.

- [ ] **Step 1: Migrate the call at line 957 (`reference.resource` argument)**

Find:

```swift
    let maybeFetched = accountManager.mediaBox.resourceData(reference.resource, option: .complete(waitUntilFetchStatus: false), attemptSynchronously: synchronousLoad)
```

Replace with:

```swift
    let maybeFetched = accountManager.resources.data(resource: EngineMediaResource(reference.resource), attemptSynchronously: synchronousLoad)
```

Note: `waitUntilFetchStatus: false` is omitted because the facade default is `false`. The site explicitly passed `false`, so behavior is preserved.

- [ ] **Step 2: Migrate the call at line 1164 (`fileReference.media.resource` argument)**

Find:

```swift
            let maybeFetched = accountManager.mediaBox.resourceData(fileReference.media.resource, option: .complete(waitUntilFetchStatus: false), attemptSynchronously: synchronousLoad)
```

Replace with:

```swift
            let maybeFetched = accountManager.resources.data(resource: EngineMediaResource(fileReference.media.resource), attemptSynchronously: synchronousLoad)
```

Same `waitUntilFetchStatus: false` omission rationale.

- [ ] **Step 3: Migrate the call at line 1264 (`file.file.resource` argument, no option)**

Find:

```swift
                                return accountManager.mediaBox.resourceData(file.file.resource)
```

Replace with:

```swift
                                return accountManager.resources.data(resource: EngineMediaResource(file.file.resource))
```

The original used the underlying `MediaBox.resourceData(_ resource:)` overload's defaults — facade defaults match exactly (`pathExtension: nil`, `waitUntilFetchStatus: false`, `attemptSynchronously: false`).

---

## Task 2: WallpaperResources.swift — consumer-side `.complete` → `.isComplete` renames (3 edits)

**Files:**
- Modify: `submodules/WallpaperResources/Sources/WallpaperResources.swift`

**Edits in this task:** 3.

`EngineMediaResource.ResourceData` exposes `.isComplete` (renamed from `MediaResourceData.complete`). All three migrated call sites have a single consumer-side `.complete` access on the migrated result that needs renaming.

- [ ] **Step 1: Rename `maybeData.complete` at line 961 (consumer of site 957)**

Find:

```swift
        if maybeData.complete {
```

Replace with:

```swift
        if maybeData.isComplete {
```

The leading whitespace (8 spaces) must match exactly.

- [ ] **Step 2: Rename `maybeData.complete` at line 1168 (consumer of site 1164)**

Find:

```swift
                if maybeData.complete && isSupportedTheme {
```

Replace with:

```swift
                if maybeData.isComplete && isSupportedTheme {
```

The leading whitespace (16 spaces) must match exactly.

- [ ] **Step 3: Rename `data.complete` at line 1266 (consumer of site 1264)**

Find:

```swift
                                    if data.complete, let imageData = try? Data(contentsOf: URL(fileURLWithPath: data.path)) {
```

Replace with:

```swift
                                    if data.isComplete, let imageData = try? Data(contentsOf: URL(fileURLWithPath: data.path)) {
```

The leading whitespace (36 spaces) must match exactly.

The `data.path` access on the same line is unchanged — both `MediaResourceData.path` and `EngineMediaResource.ResourceData.path` are `String`.

---

## Sites NOT touched (deferred)

For the implementer's awareness — these `.complete` accesses on UNRELATED bindings stay raw and are NOT to be renamed:

- `WallpaperResources.swift:968` — `return data.complete ? try? Data(contentsOf: URL(fileURLWithPath: data.path)) : nil` — this `data` is bound from `account.postbox.mediaBox.resourceData(...)` (postbox-side, not migrated). STAYS `.complete`.
- Other `.complete` accesses elsewhere in the file that aren't on the 3 migrated bindings — STAY.

The 3 renames target only the 3 specific lines listed in Task 2 steps 1-3. Do NOT use `replace_all=true` for renames — bindings differ per scope.

---

## Task 3: Full-project Bazel build

**Files:** none (verification only).

- [ ] **Step 1: Run the build**

```sh
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent \
 --buildNumber=1 --configuration=debug_sim_arm64
```

Expected: clean build (`bazel build complete` / `INFO: Build completed successfully`). No `--continueOnError`. Build cost projection: ~30-60s (consumer-only, foundational module rebuild fan-out).

- [ ] **Step 2: If build fails, triage iteration**

Common failure modes:
- **`EngineMediaResource` constructor not found** — verify `import TelegramCore` at the top of WallpaperResources.swift (it should already be there). If missing, add it.
- **Type mismatch on `resource:` parameter** — would suggest the argument expression isn't `MediaResource`-typed. STOP and check the actual type at the failing site.
- **Type mismatch on `.isComplete` rename** — if the closure parameter binding is somehow inferred wrong (e.g., Swift inferred the OLD `MediaResourceData` type because the call rewrite didn't take effect), the rename will fail. Re-read the diff and verify the call rewrite landed.
- **`data.path` type mismatch** — should not happen; both types expose `path: String`. If it does, STOP and re-read.

If errors land outside WallpaperResources.swift: STOP and report BLOCKED. The wave is supposed to be self-contained.

Iteration budget: 2.

---

## Task 4: Post-edit residue grep

**Files:** none (verification only).

- [ ] **Step 1: Verify the 3 migrated call sites are gone**

Run:

```sh
grep -nE "accountManager\.mediaBox\.resourceData\(" submodules/WallpaperResources/Sources/WallpaperResources.swift
```

Expected: exactly 3 lines remaining (L33, L59, L401 — the deferred combineLatest sites). The migrated lines (originally 957, 1164, 1264) should NOT appear.

- [ ] **Step 2: Verify the 3 renames are applied**

Run:

```sh
grep -nE "maybeData\.complete\b" submodules/WallpaperResources/Sources/WallpaperResources.swift
```

Expected: empty output. Both `maybeData.complete` accesses (originally L961, L1168) should be gone.

```sh
grep -nE "if data\.complete," submodules/WallpaperResources/Sources/WallpaperResources.swift
```

Expected: no line at L1266 (the migrated site). Other `data.complete` accesses on postbox-side bindings (e.g., L968) may remain — those are out of scope.

---

## Task 5: Commit the wave

**Files:** none (git only).

- [ ] **Step 1: Stage the 1 modified file**

```sh
git add submodules/WallpaperResources/Sources/WallpaperResources.swift
```

- [ ] **Step 2: Confirm staging is clean**

```sh
git status --short | grep -v "^??"
```

Expected: only the 1 staged file (line starting with `M `). The line `m build-system/bazel-rules/sourcekit-bazel-bsp` is pre-existing WIP and should NOT appear in the staged list.

- [ ] **Step 3: Commit**

```sh
git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 104

Drain 3 accountManager.mediaBox.resourceData(...) Shape-A sites against
the existing wave-32 / wave-94 AccountManagerResources.data(resource:)
facade. Sites: WallpaperResources:957 (reference.resource), :1164
(fileReference.media.resource), :1264 (file.file.resource).

Migration: accountManager.mediaBox.resourceData(X, option: .complete(
waitUntilFetchStatus: false)[, attemptSynchronously: Y]) -> accountManager
.resources.data(resource: EngineMediaResource(X)[, attemptSynchronously:
Y]). Plus 3 consumer-side .complete -> .isComplete renames at L961,
L1168, L1266 to match EngineMediaResource.ResourceData field name.

3 sites / 1 file / 6 Edit calls. Consumer-only build.

Deferred: 2 sites in FetchCachedRepresentations.swift (482, 490) flow
data: MediaResourceData into fetchCachedScaled*Representation cascade;
3 sites in WallpaperResources (33, 59, 401) coupled to postbox-side via
combineLatest typed tuples.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: Verify commit**

```sh
git log --oneline -1
```

Expected: shows the wave 104 commit as HEAD.

---

## Task 6: Update outcome log + memory

**Files:**
- Modify: `docs/superpowers/postbox-refactor-log.md`
- Modify: `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`
- Modify: `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/MEMORY.md`

- [ ] **Step 1: Append wave 104 outcome to refactor log**

Append a "Wave 104 outcome" entry to `docs/superpowers/postbox-refactor-log.md` matching the format of "Wave 103 (retry) outcome". Include:
- Commit hash (from Task 5 step 4).
- Iteration count (1 if first-pass-clean; 2 if Task 3 step 2 fired).
- Bazel build duration (from Task 3 step 1 output).
- Net-delta accounting: −3 raw `mediaBox.X` accesses, +3 facade calls, +3 `EngineMediaResource(...)` wraps, +3 consumer field renames.
- Wave-shape note: G drain with documented consumer field rename. The pre-flight identified a `MediaResourceData`-typed-function-parameter barrier (`fetchCachedScaled*Representation` family) that forced 2 sites into the deferred bucket — illustrates the wave-71-shadow lesson applied to result-type cascades, not just peer migrations.

- [ ] **Step 2: Update next-wave memory**

Edit `project_postbox_refactor_next_wave.md`:
- Add wave 104 outcome line into the recent-waves section.
- Update accountManager-side facade drain status table: `resourceData` count drops from 8 → 5 (3 drained, 5 deferred).
- Add a new section (or extend an existing one) documenting the "Postbox-typed-function-parameter barrier" pattern, with `Message.peers: SimpleDictionary<PeerId, Peer>` (wave-103 lesson) and now `fetchCachedScaled*Representation(resourceData: MediaResourceData)` as the two known instances.

- [ ] **Step 3: Update MEMORY.md index**

Edit `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/MEMORY.md`:
- Update the `[Postbox refactor next wave]` line to mention wave 104 landed.

- [ ] **Step 4: Commit the doc update**

```sh
git add docs/superpowers/postbox-refactor-log.md
git commit -m "$(cat <<'EOF'
docs: log wave 104 outcome

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

(Memory file updates are not committed — they live outside the repo.)

---

## Net delta projection

| Category | Count | Sites |
|---|---|---|
| Raw `mediaBox.X` access drops | −3 | WR:957, 1164, 1264 |
| Facade calls added | +3 | same sites, migrated form |
| `EngineMediaResource(...)` wraps | +3 | canonical engine-side, not Postbox bridges |
| Consumer field renames | +3 | WR:961 (`maybeData.complete` → `.isComplete`), WR:1168 (same), WR:1266 (`data.complete` → `.isComplete`) |
| `import Postbox` drops | 0 | WallpaperResources retains import for unrelated symbols |

**Total commit footprint:** 6 line edits in 1 file, plus a docs commit for the outcome log.
