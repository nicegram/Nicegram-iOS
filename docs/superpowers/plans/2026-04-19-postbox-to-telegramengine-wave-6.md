# Postbox → TelegramEngine Wave 6 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Speculatively drop `import Postbox` from every consumer file where a plain `^import Postbox$` line appears, run a full project build, restore the import on files that fail to compile, iterate up to 3 times, commit surviving drops as one atomic commit. Then land a CLAUDE.md update with the outcome and permanent methodology guidance.

**Architecture:** Two commits on branch `refactor/postbox-to-engine-wave-6`. C1 is the atomic batch deletion whose diff is N single-line removals (build-verified). C2 is a docs update that (a) records the outcome and (b) codifies the sweep methodology under "Wave-selection guidance" so future sweeps can be triggered directly. The project build is the safety net — anything that compiles after restoration is definitionally safe.

**Tech Stack:** Swift / Bazel. No unit tests — verification is a full project build.

**Spec:** [docs/superpowers/specs/2026-04-19-postbox-to-telegramengine-wave-6-design.md](docs/superpowers/specs/2026-04-19-postbox-to-telegramengine-wave-6-design.md)

**Build command** (use for every "full build" step):

```bash
source ~/.zshrc 2>/dev/null; PATH=/opt/homebrew/opt/ruby/bin:`gem environment gemdir`/bin:$PATH python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber 1 --configuration debug_sim_arm64
```

For background execution (recommended given build length), use `run_in_background: true` from the controller session. Do not let a subagent spawn the build — when the subagent returns the process orphans. The controller owns every build invocation in this wave.

---

## Task 1: Generate and record the candidate list

Read-only setup. No code changes yet.

- [ ] **Step 1: Generate the candidate list**

```bash
grep -rl "^import Postbox$" submodules --include="*.swift" \
  | grep -vE "/(TelegramCore|Postbox|TelegramApi)/" \
  | sort > /tmp/wave-6-candidates.txt
wc -l /tmp/wave-6-candidates.txt
```

Expected: a count somewhere between 100 and 400. Record the exact number — call it `N_candidates`. If the count is outside that range, stop and investigate: either the grep is too narrow (missing `@_exported` etc. ought to be rare) or too broad (accidentally matching TelegramCore).

- [ ] **Step 2: Snapshot baseline**

The snapshot is implicit: every candidate file is at branch HEAD, so `git checkout -- <file>` always restores the pre-sweep content. Verify the working tree is clean:

```bash
git status --short | grep -v '^??' | grep -v sourcekit-bazel-bsp
```

Expected: empty output. (The `sourcekit-bazel-bsp` submodule shows as modified across the whole repo; that's pre-existing and orthogonal.) If there are any other unstaged changes, commit or stash them before proceeding.

- [ ] **Step 3: Confirm branch and HEAD**

```bash
git branch --show-current
git log --oneline -3
```

Expected:
- current branch: `refactor/postbox-to-engine-wave-6`
- top commit: the wave-6 spec commit.

---

## Task 2: Speculative drop pass

Mutates all candidate files. No commit yet.

- [ ] **Step 1: Drop `import Postbox` from every candidate**

```bash
while IFS= read -r f; do
    /usr/bin/sed -i '' '/^import Postbox$/d' "$f"
done < /tmp/wave-6-candidates.txt
```

macOS `sed` requires the `''` after `-i` (BSD flavor).

- [ ] **Step 2: Verify every candidate had exactly one line removed**

```bash
git diff --stat | wc -l
```

Expected: `N_candidates + 1` (one line per file in `--stat` output, plus the summary line).

```bash
git diff --stat | awk '{print $3}' | grep -v deletion | head -5
```

Expected: each shown entry is `1` (one insertion, zero counted since all are single-line deletes). If any file shows more than 1 line changed, something went wrong — investigate.

- [ ] **Step 3: Confirm no `@_exported` lines were accidentally touched**

```bash
grep -r "@_exported import Postbox" submodules --include="*.swift" | head -5
```

If this returns results, those lines must still be intact — verify. The regex used in Step 1 only matches bare `^import Postbox$`, so `@_exported import Postbox` is untouched. This step is a sanity check.

---

## Task 3: Iteration 1 — first build, parse errors, restore failing files

- [ ] **Step 1: Run the full project build (iteration 1)**

Run the build command from the header. Expected: many errors — this is by design. Capture stderr to the build output file.

Watch the tail of the output file for either `INFO: Build completed successfully` (rare: means zero imports were needed) or a cascade of compile errors (expected).

- [ ] **Step 2: Extract failing files from the build output**

```bash
BUILD_OUT=/private/tmp/claude-501/-Users-ali-build-telegram-telegram-ios/5d9b3268-5c9f-45fc-bd4e-87cac5361498/tasks/<task-id>.output
grep -E "^submodules/.*\.swift:[0-9]+:[0-9]+: error:" "$BUILD_OUT" \
    | awk -F: '{print $1}' \
    | sort -u > /tmp/wave-6-failing.txt
wc -l /tmp/wave-6-failing.txt
```

The task-id comes from the background Bash tool's output file. Substitute the actual `/private/tmp/claude-501/.../<task-id>.output` path.

Sanity-check the content:

```bash
head -3 /tmp/wave-6-failing.txt
```

Every line should be a path under `submodules/` that appears in `/tmp/wave-6-candidates.txt`. If any line is from `TelegramCore`, `Postbox`, or `TelegramApi`, the sweep has cascaded beyond the candidate set — halt and investigate.

- [ ] **Step 3: Validate error types**

```bash
grep -E "^submodules/.*\.swift:[0-9]+:[0-9]+: error:" "$BUILD_OUT" \
    | head -10
```

Expected error patterns:
- `cannot find type 'X' in scope`
- `use of unresolved identifier 'X'`
- `cannot find 'X' in scope`
- `reference to invalid associated type 'X' of type 'Y'` (occasional)

If you see `no such module 'Postbox'` or errors unrelated to missing Postbox symbols (e.g., codesign failures, Bazel graph errors), halt and investigate — those are not the sweep's signal.

- [ ] **Step 4: Restore `import Postbox` on failing files**

```bash
while IFS= read -r f; do
    git checkout -- "$f"
done < /tmp/wave-6-failing.txt
```

- [ ] **Step 5: Verify restoration**

```bash
git diff --stat | wc -l
```

Expected: `N_candidates - N_failing + 1` lines in `--stat` output (one per still-modified file plus summary). The count should be lower than Task 2 Step 2's count by exactly `N_failing`.

---

## Task 4: Iteration 2 — rebuild, parse new errors, restore

- [ ] **Step 1: Run the full project build (iteration 2)**

Run the build command again. Expected: ideally clean success. If errors persist, it's because restoring some files in iteration 1 removed a symbol that another file (still in the candidate set with import dropped) needed transitively via that symbol's module-level re-export.

Watch for `INFO: Build completed successfully`. If found, proceed to Task 6 (skipping Task 5). If errors persist, continue with Step 2.

- [ ] **Step 2: Extract failing files**

```bash
BUILD_OUT=/private/tmp/claude-501/-Users-ali-build-telegram-telegram-ios/5d9b3268-5c9f-45fc-bd4e-87cac5361498/tasks/<task-id-2>.output
grep -E "^submodules/.*\.swift:[0-9]+:[0-9]+: error:" "$BUILD_OUT" \
    | awk -F: '{print $1}' \
    | sort -u > /tmp/wave-6-failing-2.txt
wc -l /tmp/wave-6-failing-2.txt
```

- [ ] **Step 3: Restore**

```bash
while IFS= read -r f; do
    git checkout -- "$f"
done < /tmp/wave-6-failing-2.txt
```

- [ ] **Step 4: Decision point**

If `wc -l /tmp/wave-6-failing-2.txt` is 0, the iteration-2 rebuild actually succeeded — proceed to Task 6. If it's greater than 0, proceed to Task 5 for iteration 3.

---

## Task 5: Iteration 3 — final rebuild

- [ ] **Step 1: Run the full project build (iteration 3)**

Run the build command again. If this iteration does not complete successfully, the sweep has failed the stability test.

- [ ] **Step 2: Clean-success check**

Expected: `INFO: Build completed successfully`.

If successful, proceed to Task 6.

If a third iteration of errors appears, **abandon the wave**:

```bash
git checkout -- .
git status --short
```

Working tree should now be clean (modulo the pre-existing sourcekit-bazel-bsp submodule marker). Do not commit. Skip Task 6. Jump straight to an updated Task 7 that records the failed attempt in CLAUDE.md instead of a success outcome, and document what kind of errors surfaced so a future attempt can plan around them.

---

## Task 6: Commit C1 — build-verified batch drop

- [ ] **Step 1: Compute the final count**

```bash
git diff --stat | tail -1
```

Expected: something like ` N files changed, 0 insertions(+), N deletions(-)` where N is the number of files that survived the sweep. Record this count as `N_dropped`.

- [ ] **Step 2: Spot-check a few diffs**

```bash
git diff | grep -E "^-import Postbox$" | wc -l
```

Expected: `N_dropped` (every surviving diff is a single-line `-import Postbox` removal).

```bash
git diff | grep -E "^\+" | grep -v "^+++" | head
```

Expected: no output. (The sweep only removes lines; it never adds any.)

- [ ] **Step 3: Stage all changes**

```bash
git add -u
```

`-u` stages only files that are already tracked and modified. No need to enumerate each file — the sweep touched many and they're all known to git.

- [ ] **Step 4: Commit**

```bash
N_DROPPED=$(git diff --staged --stat | tail -1 | awk '{print $1}')
git commit -m "$(cat <<EOF
Drop unused import Postbox from ${N_DROPPED} consumer files

Build-verified speculative drop: removed the import line from every
consumer submodule file where it appeared, rebuilt the full project,
and restored the import on the files that needed it. The commit
contains only survivors — every file here compiles cleanly without
import Postbox.

Methodology documented in CLAUDE.md (wave-selection guidance).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 5: Verify branch state**

```bash
git log --oneline master..HEAD
```

Expected:
- `<sha> Drop unused import Postbox from N consumer files`
- `816e7699ec docs(spec): wave-6 unused import Postbox batch sweep`

---

## Task 7: CLAUDE.md — record outcome and add permanent sweep methodology

- [ ] **Step 1: Add Wave 6 outcome subsection**

Open `CLAUDE.md`. Find the "Wave 5 outcome (2026-04-19)" block. Insert a new "Wave 6 outcome (2026-04-19)" subsection immediately after Wave 5 and before "Modules currently free of `import Postbox`":

```markdown
### Wave 6 outcome (2026-04-19)

First unused-import sweep. Ran the speculative-drop + build-verify methodology (see "Unused-import sweeps" under Wave-selection guidance): dropped `import Postbox` from every consumer file where a plain `^import Postbox$` appeared (out of ~N_CANDIDATES candidates), rebuilt, restored the import on failures, iterated. N_DROPPED drops survived.

No behavior change; zero facade migrations in this wave. Running tally updated for any modules whose last `import Postbox`-bearing file was swept (see the per-module list below).

Plan: `docs/superpowers/plans/2026-04-19-postbox-to-telegramengine-wave-6.md`
```

Replace `N_CANDIDATES` and `N_DROPPED` with the actual numbers from Task 1 Step 1 and Task 6 Step 1. If the wave was abandoned (see Task 5 Step 2), replace the outcome text with a failed-attempt description instead: what iteration the sweep stalled at and what error category.

- [ ] **Step 2: Add permanent "Unused-import sweeps" subsection under Wave-selection guidance**

Still in `CLAUDE.md`, find the "Wave-selection guidance" block. Insert the following new subsection at the end of that block (immediately before "### Wave 1 outcome"):

```markdown
**Unused-import sweeps are a valid wave shape.** After a round of facade migrations, consumer files accumulate `import Postbox` lines whose last semantic use was removed. Periodically sweep these:

1. `grep -rl "^import Postbox$" submodules --include="*.swift" | grep -vE "/(TelegramCore|Postbox|TelegramApi)/"` generates the candidate list.
2. `sed -i '' '/^import Postbox$/d' <file>` (BSD sed) speculatively drops the import from every candidate.
3. Run the full project build. Swift compile errors (`<file>:<line>:<col>: error: cannot find type 'X'`) identify files that need the import restored via `git checkout -- <file>`.
4. Rebuild. Iterate up to 3 times. Only restore files from the candidate set — if errors surface in `TelegramCore`, `Postbox`, or `TelegramApi`, halt and investigate (cascading breakage).
5. Commit the surviving drops as one atomic commit.

Re-run this after every 2–3 facade-migration waves. First run: wave 6.
```

- [ ] **Step 3: Update "Modules currently free of `import Postbox`" tally**

For each module in `submodules/` that has **no** remaining `import Postbox` after this wave, add a bullet under "Modules currently free of `import Postbox` (running tally)". Determine this list with:

```bash
for d in submodules/*/; do
    mod=$(basename "$d")
    if [ -d "$d/Sources" ]; then
        count=$(grep -rlE "^(@_exported )?import Postbox" "$d/Sources" --include="*.swift" 2>/dev/null | wc -l)
        if [ "$count" -eq 0 ]; then
            # Check this module isn't already in CLAUDE.md's tally
            if ! grep -qF "\`$mod\`" CLAUDE.md; then
                echo "$mod"
            fi
        fi
    fi
done
```

Each printed module becomes a new bullet like `- \`<ModuleName>\` (wave 6)` in the list.

If the output is empty, no new module-level additions — individual file drops across multiple mixed modules aren't tally-eligible. That's fine, the Wave-6 outcome subsection still records the raw count.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
CLAUDE.md: record wave-6 outcome and unused-import-sweep methodology

Adds the wave-6 outcome subsection with the candidate/drop counts,
documents the speculative-drop + build-verify methodology as
permanent guidance under wave-selection so future waves can re-run
the sweep directly, and updates the Postbox-free running tally for
any modules whose last import Postbox file was swept in this wave.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 5: Verify final branch state**

```bash
git log --oneline master..HEAD
```

Expected (newest first):
- `<sha> CLAUDE.md: record wave-6 outcome and unused-import-sweep methodology`
- `<sha> Drop unused import Postbox from N consumer files`
- `816e7699ec docs(spec): wave-6 unused import Postbox batch sweep`

---

## Success criteria

- At least one `import Postbox` line has been removed from at least one consumer file, build-verified.
- Full build succeeds in `debug_sim_arm64`.
- `CLAUDE.md` has a "Wave 6 outcome (2026-04-19)" subsection with actual numeric results.
- `CLAUDE.md`'s "Wave-selection guidance" section has a new permanent "Unused-import sweeps" bullet list that describes the methodology for future re-runs.
- `CLAUDE.md`'s "Modules currently free of `import Postbox`" running tally includes any newly-fully-clean modules (if any).
- Branch `refactor/postbox-to-engine-wave-6` contains 3 commits above `master`: 1 doc (spec) + 1 code (C1 batch drop) + 1 tally (C2).
