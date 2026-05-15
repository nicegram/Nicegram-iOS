# Wave 106: Speculative `import Postbox` Drop Sweep (round 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Drop `import Postbox` from any consumer-module Swift file in `submodules/` whose remaining content no longer references a Postbox-only symbol. Wave 106 of the Postbox → TelegramEngine refactor — round 2 of the wave-93 speculative-drop sweep.

**Architecture:** Procedural sweep with build-feedback loop. (1) inventory candidates → (2) pre-flight regex pre-restore → (3) drop imports en masse → (4) build with `--continueOnError` → (5) restore failures → iterate → (6) final clean build → (7) optional BUILD-dep sweep → (8) single atomic commit. No code semantic changes — only `import` and BUILD `deps` lines.

**Tech Stack:** Swift, Bazel via `Make.py`, `grep`/`sed` for inventory, no unit tests. Verification is the full-project debug-sim-arm64 build.

**Iteration budget:** 2-5 build cycles (wave-93 precedent: 2 iter — drop, restore, clean).

**Note on TDD:** No unit tests in this project. Each task verifies via Bazel build + diff inspection. Build feedback IS the test.

**Spec:** `docs/superpowers/specs/2026-04-26-postbox-wave-106-import-drop-sweep-design.md`.

---

## File Structure

| Artifact | Role |
|---|---|
| `/tmp/wave106-candidates.txt` | All consumer files currently `import Postbox` |
| `/tmp/wave106-skiplist.txt` | Files that match preemptive-restore regex (keep import) |
| `/tmp/wave106-droplist.txt` | candidates − skiplist; files to edit |
| `/tmp/wave106-build-iterN.log` | Per-iteration build log |
| `/tmp/wave106-restore-iterN.txt` | Files needing restore after iter N |
| `/tmp/wave106-final-droplist.txt` | Net dropped files after all iterations |
| `submodules/**/*.swift` | Edited files (single-line Edit each) |
| `submodules/**/BUILD` | (Optional Step 7) packages with no remaining Postbox imports |

---

## Task 1: Pre-flight WIP check

**File:** none (read-only).

- [ ] **Step 1: Verify clean working tree (modulo known-persistent state)**

Run:

```sh
git status --short
```

Expected output:

```
 m build-system/bazel-rules/sourcekit-bazel-bsp
?? build-system/tulsi/
?? submodules/TgVoip/
?? third-party/libx264/
```

If output contains anything else (modified `M` files, other untracked dirs), HALT — there is unrelated WIP that would get tangled with the wave commit. Resolve before proceeding.

- [ ] **Step 2: Confirm we are on `master`**

Run:

```sh
git branch --show-current
```

Expected: `master`. If not, stop and ask.

---

## Task 2: Inventory candidate files

**File:** none (read-only).

- [ ] **Step 1: Build the candidate list**

Run:

```sh
grep -rl "^import Postbox" submodules --include="*.swift" \
  | grep -v "^submodules/Postbox/" \
  | grep -v "^submodules/TelegramCore/" \
  | grep -v "^submodules/TelegramApi/" \
  | sort -u > /tmp/wave106-candidates.txt
wc -l /tmp/wave106-candidates.txt
```

Expected: between ~700 and ~1200 files (wave-93-era was ~1200; waves 94-105 may have peeled some).

- [ ] **Step 2: Sanity-check the exclusion filters worked**

Run:

```sh
grep -E "^submodules/(Postbox|TelegramCore|TelegramApi)/" /tmp/wave106-candidates.txt | head -5
```

Expected: empty output (no excluded paths leaked through).

---

## Task 3: Build the skip-list via preemptive regex

**File:** none (read-only).

- [ ] **Step 1: Run the combined skip-regex against candidates**

The skip-regex is the union of three tiers from the spec. Run:

```sh
grep -El "\bPostbox\b|\bMediaBox\b|\bMediaResource\b|\bMediaResourceData\b|\bMediaResourceId\b|\bPostboxCoding\b|\bPostboxDecoder\b|\bPostboxEncoder\b|\bMemoryBuffer\b|\bTempBoxFile\b|\bValueBoxKey\b|\bPostboxView\b|\bcombinedView\b|\bPeerId\b|\bMessageId\b|\bMediaId\b|\bMessageIndex\b|\bMessageAndThreadId\b|\bPeerNameIndex\b|\bStoryId\b|\bItemCollectionId\b|\bFetchResourceSourceType\b|\bFetchResourceError\b|\bPeer\b|\bMessage\b|\bMedia\b" \
  $(cat /tmp/wave106-candidates.txt) \
  | sort -u > /tmp/wave106-skiplist.txt
wc -l /tmp/wave106-skiplist.txt
```

Expected: most of the candidate list (likely 600-1100 files matched) — `\bPeer\b`, `\bMessage\b`, `\bMedia\b` are deliberately broad and catch many false positives. False positives are SAFE — they just mean fewer drops, not bad drops.

- [ ] **Step 2: Compute the drop-list**

Run:

```sh
comm -23 /tmp/wave106-candidates.txt /tmp/wave106-skiplist.txt > /tmp/wave106-droplist.txt
wc -l /tmp/wave106-droplist.txt
head -20 /tmp/wave106-droplist.txt
```

Expected: 5-50 files in the drop-list (wave 93 had 12). If 0, the regex is over-matching — halt and revisit. If >100, the regex is under-matching — halt, expand patterns, re-run.

- [ ] **Step 3: Spot-verify 3 random drop candidates**

Run for each of 3 files from the head of the drop-list:

```sh
head -3 /tmp/wave106-droplist.txt | while read f; do
  echo "=== $f ==="
  grep -nE "Postbox|MediaBox|MediaResource|PeerId|MessageId|MediaId|MessageIndex" "$f" | head -5
done
```

Expected: Only `import Postbox` line appears. If any other Postbox-token appears, the file should have been skipped — add the missing pattern to the regex in Step 1, redo Steps 1-2, and re-spot-check.

---

## Task 4: Drop `import Postbox` from drop-list files

**Files:** every path listed in `/tmp/wave106-droplist.txt`.

- [ ] **Step 1: Read each drop-list file's import block to locate the exact `import Postbox` line**

For each file in the drop-list, the line is `import Postbox` (exact match, no whitespace variations expected). Use a single-purpose `sed` to remove it from all drop-list files:

```sh
while read f; do
  sed -i '' '/^import Postbox$/d' "$f"
done < /tmp/wave106-droplist.txt
```

The `sed -i ''` syntax is BSD/macOS specific — required on Darwin.

- [ ] **Step 2: Verify the imports were removed**

Run:

```sh
grep -lE "^import Postbox$" $(cat /tmp/wave106-droplist.txt) | wc -l
```

Expected: 0 (no file in the drop-list still contains `import Postbox`).

- [ ] **Step 3: Verify no other lines were touched**

Run:

```sh
git diff --stat | tail -5
git diff --shortstat
```

Expected: same number of files modified as drop-list size. Each file should show `-1` insertion (or `-1` deletion). If any file shows multiple deletions, something went wrong — `git checkout -- $(cat /tmp/wave106-droplist.txt)` and investigate.

---

## Task 5: Build iteration 1 — capture failures

**File:** none (build only).

- [ ] **Step 1: Run the build with `--continueOnError`**

Run:

```sh
source ~/.zshrc 2>/dev/null && \
python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 \
 --configuration=debug_sim_arm64 \
 --continueOnError 2>&1 | tee /tmp/wave106-build-iter1.log
```

Expected: Build completes (with errors). Wall-clock 30-260s depending on cache state.

- [ ] **Step 2: Extract failing files**

Run:

```sh
grep -E ":[0-9]+:[0-9]+: error:" /tmp/wave106-build-iter1.log \
  | awk -F: '{print $1}' \
  | sort -u > /tmp/wave106-restore-iter1.txt
wc -l /tmp/wave106-restore-iter1.txt
cat /tmp/wave106-restore-iter1.txt
```

Expected: a subset of the drop-list. Wave 93 saw 5 of 12 needing restore. If the count > 50% of drop-list, the regex is missing a major pattern — HALT, analyze the failure cluster, add the missing pattern to Task 3 Step 1, restart from Task 4.

- [ ] **Step 3: Verify no errors in TelegramCore/Postbox/TelegramApi**

Run:

```sh
grep -E "^submodules/(TelegramCore|Postbox|TelegramApi)/" /tmp/wave106-restore-iter1.txt
```

Expected: empty. If non-empty: HALT immediately, `git checkout -- submodules/`, and revert the wave — scope drift indicates the candidate filter or sed pattern is wrong.

---

## Task 6: Restore failing files (iter 1)

**Files:** every path in `/tmp/wave106-restore-iter1.txt`.

- [ ] **Step 1: Re-add `import Postbox` to each failing file**

Use awk uniformly (BSD `sed -i '' 'i\'` line-continuation is fragile inside shell loops). Insert `import Postbox` immediately before `import TelegramCore` if present, else immediately after the first existing `import ` line:

```sh
while read f; do
  awk '
    BEGIN { added = 0 }
    !added && /^import TelegramCore$/ { print "import Postbox"; print; added = 1; next }
    { print }
    END {
      if (!added) {
        # fallback path was not used — try post-first-import injection
        # (this END block is a no-op; awk cannot re-emit lines after END)
      }
    }
  ' "$f" > "$f.tmp"
  if ! grep -q "^import Postbox$" "$f.tmp"; then
    # no TelegramCore anchor found — fall back to "after first import"
    awk '
      BEGIN { added = 0 }
      !added && /^import / { print; print "import Postbox"; added = 1; next }
      { print }
    ' "$f" > "$f.tmp"
  fi
  mv "$f.tmp" "$f"
done < /tmp/wave106-restore-iter1.txt
```

- [ ] **Step 2: Verify restorations**

Run:

```sh
grep -L "^import Postbox$" $(cat /tmp/wave106-restore-iter1.txt)
```

Expected: empty (every file in the restore list now contains `import Postbox` again).

- [ ] **Step 3: Update the working drop-list**

Run:

```sh
comm -23 /tmp/wave106-droplist.txt /tmp/wave106-restore-iter1.txt > /tmp/wave106-final-droplist.txt
wc -l /tmp/wave106-final-droplist.txt
```

This is the current "successfully dropped" set.

---

## Task 7: Build iteration 2 — verify clean (or iterate further)

**File:** none (build only).

- [ ] **Step 1: Re-run the build with `--continueOnError`**

Run:

```sh
source ~/.zshrc 2>/dev/null && \
python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 \
 --configuration=debug_sim_arm64 \
 --continueOnError 2>&1 | tee /tmp/wave106-build-iter2.log
```

- [ ] **Step 2: Extract any new failures**

Run:

```sh
grep -E ":[0-9]+:[0-9]+: error:" /tmp/wave106-build-iter2.log \
  | awk -F: '{print $1}' \
  | sort -u > /tmp/wave106-restore-iter2.txt
wc -l /tmp/wave106-restore-iter2.txt
```

- [ ] **Step 3: If non-empty, repeat Task 6 with `iter2.txt` and run Task 7 again as iter3.**

Stop when:
- `restore-iterN.txt` is empty → proceed to Task 8.
- `N == 5` → HALT (diminishing returns); commit what is green via Task 9.

Each repeat: substitute `iter1` → `iter2` → `iter3` etc. throughout. Update the final-droplist after each restore: `comm -23 /tmp/wave106-final-droplist.txt /tmp/wave106-restore-iterN.txt > /tmp/wave106-final-droplist.txt.new && mv /tmp/wave106-final-droplist.txt.new /tmp/wave106-final-droplist.txt`.

---

## Task 8: Final clean build (no `--continueOnError`)

**File:** none (build only).

- [ ] **Step 1: Run a clean build to confirm no inter-module ordering issue was masked**

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

Expected: build success, no `error:` lines in the tail. If failure: an inter-module visibility issue exists that `--continueOnError` masked. Restore the final-droplist file(s) implicated by the error, repeat Task 7 / Task 8.

---

## Task 9 (optional): BUILD-dep sweep

**Files:** various `submodules/*/BUILD` files.

This step removes `//submodules/Postbox` from any Bazel package whose Swift sources no longer contain `import Postbox`. Skip this task if iteration time is constrained — the import drops alone are the core wave value; deps trim is housekeeping.

- [ ] **Step 1: Find packages whose `BUILD` still depends on `//submodules/Postbox` but whose `Sources/**/*.swift` no longer imports it**

Run:

```sh
for build in $(find submodules -name BUILD -not -path "submodules/Postbox/*"); do
  pkg_dir=$(dirname "$build")
  if grep -q "//submodules/Postbox" "$build" 2>/dev/null; then
    if ! grep -rq "^import Postbox$" "$pkg_dir" --include="*.swift" 2>/dev/null; then
      echo "$build"
    fi
  fi
done > /tmp/wave106-build-deps-candidates.txt
wc -l /tmp/wave106-build-deps-candidates.txt
cat /tmp/wave106-build-deps-candidates.txt
```

Expected: 0-5 candidates. If 0, skip to Task 10.

- [ ] **Step 2: For each candidate BUILD, locate the `//submodules/Postbox` line and remove it via Edit**

Note that BUILD files often list deps as either `"//submodules/Postbox"` (string) or via aliases. Use Read to inspect each, then Edit to drop just the dep line. The exact string pattern varies — typically `"//submodules/Postbox",` on its own line within a `deps = [ ... ]` block.

For each candidate file, Read the lines around the match, then Edit to remove the line preserving the surrounding bracket structure.

- [ ] **Step 3: Re-run the clean build (no `--continueOnError`) to confirm no dep was load-bearing**

Run the same command as Task 8 Step 1.

If failure: a transitive dep was being satisfied through Postbox. Restore the dep line(s) implicated by the error and re-run.

---

## Task 10: Commit the wave

**File:** `git`.

- [ ] **Step 1: Inspect final diff statistics**

Run:

```sh
git diff --stat
git diff --shortstat
```

Expected: N file modifications, all `-1` line changes (just `import Postbox` lines), possibly plus a small number of BUILD diffs from Task 9.

- [ ] **Step 2: Confirm only allowed paths are touched**

Run:

```sh
git diff --name-only | grep -vE "^submodules/" | head -5
git diff --name-only | grep -E "^submodules/(Postbox|TelegramCore|TelegramApi)/" | head -5
```

Both expected: empty. If either has output: HALT — rogue changes exist; investigate before committing.

- [ ] **Step 3: Stage only the modified Swift and BUILD files**

Run:

```sh
git add $(git diff --name-only)
git status --short
```

Expected: all changes staged with `M`. Untracked dirs (`build-system/tulsi/`, `submodules/TgVoip/`, `third-party/libx264/`) and the `m` submodule marker remain untouched.

- [ ] **Step 4: Commit with the wave message**

Substitute `<N>` with the count from `/tmp/wave106-final-droplist.txt`, `<M>` with the total restored across iterations, and `<K>` with the BUILD deps removed (0 if Task 9 skipped).

```sh
N=$(wc -l < /tmp/wave106-final-droplist.txt | tr -d ' ')
M=$(cat /tmp/wave106-restore-iter*.txt 2>/dev/null | sort -u | wc -l | tr -d ' ')
K=$(git diff --cached --name-only | grep -c BUILD)

git commit -m "$(cat <<EOF
Postbox -> TelegramEngine wave 106 (import drop sweep round 2)

Speculative drop of \`import Postbox\` in $N files where the last
Postbox-typed symbol reference was peeled off by waves 94-105.
Methodology: pattern-based pre-flight skip + drop + build-feedback
restore loop (wave-93-validated recipe). $M files restored after build.
$K BUILD deps removed.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
git status --short
```

Expected: clean commit, working tree returns to the known-persistent untracked-only state.

---

## Task 11: Update memory file with wave outcome

**File:** `/Users/isaac/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`.

- [ ] **Step 1: Read the current memory file to find the recent-commits section**

Read the top section listing wave commits.

- [ ] **Step 2: Insert a wave-106 line below the wave-105 entry**

Append (substituting the actual commit hash from `git log -1 --format=%H | head -c 10`):

```markdown
- `<HASH>` — wave 106: speculative `import Postbox` drop sweep round 2. <N> files dropped, <M> restored after build feedback. Methodology re-run of wave 93 (`72de7c4fd5`) with expanded pre-flight regex (added bare-name escapes `\bPeer\b`/`\bMessage\b`/`\bMedia\b` per wave-93 lesson). <K> BUILD deps removed. <iter-count> build cycles.
```

Update the memory file's `description:` frontmatter to reflect wave 106 as the latest.

---

## Halt-and-revert recipe (if anything goes seriously wrong)

If at any point the build fails in TelegramCore/Postbox/TelegramApi, or iteration count exceeds 5 with non-trivial residue, or scope drifts beyond the spec:

```sh
git checkout -- submodules/
git status --short  # should match the pre-flight expected output
```

The wave is fully reversible until Task 10 commits.

---

## Plan Self-Review Notes

- **Spec coverage:** Tasks 1-11 map 1:1 to the 8-step procedure in the spec plus pre-flight (Task 1) and post-commit memory update (Task 11). Halt conditions appear in Tasks 5/7/9 and the final halt-and-revert recipe.
- **Placeholder scan:** No TBDs/TODOs. All `<N>`/`<M>`/`<K>`/`<HASH>` are explicitly substituted via shell expansion in Step 4 of Task 10.
- **Type/method consistency:** Single-purpose tasks operating on filesystem and grep — no method-name drift risk.
- **Iteration shape:** Tasks 5-7 form the iteration loop; Task 8 is the validation gate; Task 9 is optional housekeeping; Task 10 commits.
