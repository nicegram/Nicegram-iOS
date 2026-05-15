# Wave 103 (retry): accountManager.mediaBox.storeResourceData drain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Drain 5 remaining `accountManager.mediaBox.storeResourceData(...)` Shape-A sites against the wave-94 `AccountManagerResources.storeResourceData(id:data:synchronous:)` facade. Wave 103 (retry) of the Postbox → TelegramEngine refactor, after the abandonment of the original wave-103 plan.

**Architecture:** Wave-shape-G drain. Pure call-site rewrite; no facade addition, no TelegramCore touch, no public-API change. 5 sites across 2 consumer files (`ThemeUpdateManager.swift`, `WallpaperResources.swift`) migrated via 3 `Edit` calls (1 single + 2 `replace_all=true` batches).

**Tech Stack:** Swift, Bazel via `Make.py`, no unit tests (per `CLAUDE.md`). Verification is the full-project debug-sim-arm64 build.

**Iteration budget:** 1 (target first-pass-clean given mechanical scope and validated facade).

**Note on TDD:** This project has no unit tests. Each task writes the edits, then verifies via Bazel build + residue grep.

---

## File Structure

| File | Role | Changes |
|---|---|---|
| `submodules/TelegramUI/Sources/ThemeUpdateManager.swift` | Theme-update background sync | 1 site migrated |
| `submodules/WallpaperResources/Sources/WallpaperResources.swift` | Wallpaper resource pipeline | 4 sites migrated via 2 `replace_all=true` batches |

No public-API ripple — both files are leaf consumers of the wave-94 facade.

---

## Task 1: ThemeUpdateManager.swift — single-site migration

**Files:**
- Modify: `submodules/TelegramUI/Sources/ThemeUpdateManager.swift`

**Edits in this task:** 1.

- [ ] **Step 1: Migrate the storeResourceData call at line 112**

Find:

```swift
                                        accountManager.mediaBox.storeResourceData(file.file.resource.id, data: fullSizeData, synchronous: true)
```

Replace with:

```swift
                                        accountManager.resources.storeResourceData(id: EngineMediaResource.Id(file.file.resource.id), data: fullSizeData, synchronous: true)
```

`accountManager` here is closure-captured from `presentationThemeSettingsUpdated(_:)` scope, typed `AccountManager<TelegramAccountManagerTypes>`. The facade is exposed via `public extension AccountManager { var resources: AccountManagerResources }`.

---

## Task 2: WallpaperResources.swift — two batched migrations

**Files:**
- Modify: `submodules/WallpaperResources/Sources/WallpaperResources.swift`

**Edits in this task:** 2 (each `replace_all=true`, covering 2 sites apiece).

- [ ] **Step 1: Migrate the `reference.resource.id` pattern (lines 973, 1214)**

Use `Edit` with `replace_all=true`:

Find:

```swift
accountManager.mediaBox.storeResourceData(reference.resource.id, data: data)
```

Replace with:

```swift
accountManager.resources.storeResourceData(id: EngineMediaResource.Id(reference.resource.id), data: data)
```

Both sites share identical text (verified by pre-flight grep). `replace_all=true` handles both atomically.

- [ ] **Step 2: Migrate the `file.file.resource.id` pattern (lines 1260, 1523)**

Use `Edit` with `replace_all=true`:

Find:

```swift
accountManager.mediaBox.storeResourceData(file.file.resource.id, data: fullSizeData)
```

Replace with:

```swift
accountManager.resources.storeResourceData(id: EngineMediaResource.Id(file.file.resource.id), data: fullSizeData)
```

Both sites share identical text. `replace_all=true` handles both atomically.

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

Expected: clean build (`bazel build complete` / `INFO: Build completed successfully`). No `--continueOnError` because the small scope makes the first error informative.

Build cost projection: WallpaperResources is foundational with wide rebuild fan-out; expect ~30-90s.

- [ ] **Step 2: If build fails, triage iteration**

Common failure modes:
- **`EngineMediaResource.Id` not in scope** — verify `import TelegramCore` is at the top of the failing file (it should be — pre-flight inventoried both files have it). If absent, add it.
- **Type mismatch on `id:` parameter** — would suggest an unexpected `MediaResourceId` subtype. STOP and re-read; the migration assumed `MediaResource.id: MediaResourceId` for both `reference.resource` and `file.file.resource`. Both should resolve to `MediaResourceId` per Postbox protocol.
- **`accountManager.resources` not in scope** — the `public extension AccountManager` exists in TelegramCore (wave 94). If unreachable, the consumer's BUILD might be missing a TelegramCore dep — but both files already use TelegramCore types, so this should not happen. STOP if it does.

If errors land outside those 2 files: **STOP and report BLOCKED**. The wave is supposed to be self-contained.

Fix in place and re-run step 1. Budget: 2 iterations.

---

## Task 4: Post-edit residue grep

**Files:** none (verification only).

- [ ] **Step 1: Verify zero remaining `accountManager.mediaBox.storeResourceData` in the 2 touched files**

Run:

```sh
grep -rn "accountManager\.mediaBox\.storeResourceData" \
  submodules/TelegramUI/Sources/ThemeUpdateManager.swift \
  submodules/WallpaperResources/Sources/WallpaperResources.swift
```

Expected: empty output.

---

## Task 5: Commit the wave

**Files:** none (git only).

- [ ] **Step 1: Stage the 2 modified files**

```sh
git add \
  submodules/TelegramUI/Sources/ThemeUpdateManager.swift \
  submodules/WallpaperResources/Sources/WallpaperResources.swift
```

- [ ] **Step 2: Confirm staging is clean**

```sh
git status --short | grep -v "^??"
```

Expected output: only the 2 staged files (lines starting with `M `). The line `m build-system/bazel-rules/sourcekit-bazel-bsp` is pre-existing WIP and should NOT appear in the staged list.

- [ ] **Step 3: Commit**

```sh
git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 103 (retry)

Drain 5 accountManager.mediaBox.storeResourceData(...) Shape-A sites
that the wave-94/95-99 sweep missed. All 5 migrated to
accountManager.resources.storeResourceData(id: EngineMediaResource.Id(...))
against the existing wave-94 facade.

Sites: ThemeUpdateManager:112 (with synchronous: true),
WallpaperResources:973, 1214 (reference.resource.id pattern, replace_all),
WallpaperResources:1260, 1523 (file.file.resource.id pattern, replace_all).

5 sites / 2 files / 3 Edit calls. Consumer-only build.

Wave-103 retry after the abandonment of ChatRecentActionsControllerNode
peer migration; see postbox-refactor-log "Wave 103 outcome" for the
forensics.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: Verify commit**

```sh
git log --oneline -1
```

Expected: shows the wave 103 (retry) commit as HEAD.

---

## Task 6: Update outcome log + memory

**Files:**
- Modify: `docs/superpowers/postbox-refactor-log.md`
- Modify: `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`
- Modify: `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/MEMORY.md`

- [ ] **Step 1: Append wave 103 (retry) outcome to refactor log**

Append a "Wave 103 (retry) outcome" entry to `docs/superpowers/postbox-refactor-log.md`. Include:
- Commit hash (from Task 5 step 4).
- Iteration count (1 if first-pass-clean; 2 if Task 3 step 2 fired).
- Bazel build duration.
- Net-delta accounting: −5 raw `mediaBox.X` accesses, +5 facade calls, +5 `EngineMediaResource.Id(...)` wraps (canonical engine-side, not Postbox bridges).
- Wave-shape note: G drain, validates the wave-94 facade across an additional 2-module footprint.

- [ ] **Step 2: Update next-wave memory**

Edit `project_postbox_refactor_next_wave.md`:
- Add wave 103 (retry) outcome line into the recent-waves section.
- Mark the 5 sites as drained; remove from candidate inventories (the file currently lists "Wave 95+ candidates" with stale storeResourceData entries — clean those up).
- Update the top frontmatter `description` to reflect wave 103 (retry) landed.
- Promote next candidate. Options: 7-site `resourceData(...)` drain (would need a new facade method or use existing `data(resource:)`), DirectMediaImageCache Shape-C/D, or pivot to a foundational wave.

- [ ] **Step 3: Update MEMORY.md index**

Edit `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/MEMORY.md`:
- Update the `[Postbox refactor next wave]` line to mention wave 103 (retry) landed.

- [ ] **Step 4: Commit the doc update**

```sh
git add docs/superpowers/postbox-refactor-log.md
git commit -m "$(cat <<'EOF'
docs: log wave 103 (retry) outcome

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

(Memory file updates are not committed — they live outside the repo.)

---

## Net delta projection

| Category | Count | Sites |
|---|---|---|
| Raw `mediaBox.X` access drops | −5 | TUM:112 + WR:973, 1214, 1260, 1523 |
| Facade calls added | +5 | same sites, migrated form |
| `EngineMediaResource.Id(...)` wraps | +5 | canonical engine-side constructs (not Postbox bridges) |
| `import Postbox` drops | 0 | both files retain Postbox import for unrelated symbols |
| Postbox-free module count | 0 | no module dropped from the import list |

**Total commit footprint:** 5 line edits (3 Edit calls) across 2 files, plus a docs commit for the outcome log.
