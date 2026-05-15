# Postbox → TelegramEngine wave 37: `peerTokenTitle` peer parameter Peer → EnginePeer

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the private free function `peerTokenTitle(accountPeerId: PeerId, peer: Peer, strings:, nameDisplayOrder:)` in `submodules/TelegramUI/Sources/ContactMultiselectionController.swift` so `peer` is `EnginePeer`, dropping 5 `._asPeer()` bridges at call sites in the same file.

**Architecture:** Single-file, atomic, private-function refactor. No public API change, no BUILD-file touch, no cross-module effects. Function body simplifies `EnginePeer(peer).displayTitle(...)` → `peer.displayTitle(...)`.

**Tech Stack:** Swift, Bazel via `Make.py` wrapper, Telegram-iOS project conventions (see CLAUDE.md).

**Reference:** Spec `docs/superpowers/specs/2026-04-24-peertokentitle-engine-peer-migration-design.md`.

---

## File Structure

Only one file is touched:

- **Modify:** `submodules/TelegramUI/Sources/ContactMultiselectionController.swift`
  - L21 — signature change (`peer: Peer` → `peer: EnginePeer`)
  - L27 — body simplification (drop redundant `EnginePeer(...)` wrap)
  - L171, L201, L386, L403, L748 — call-site bridge drops (`peer: peer._asPeer()` → `peer: peer`)

No files created. No files deleted. No BUILD files touched.

---

## Task 1: Pre-flight inventory verification

**Files:** None (grep-only).

- [ ] **Step 1: Confirm the function is private and single-file**

Run:

```bash
grep -rn "peerTokenTitle" submodules/ Telegram/ third-party/ --include="*.swift"
```

Expected: exactly 6 matches, all in `submodules/TelegramUI/Sources/ContactMultiselectionController.swift` — 1 definition at L21 and 5 call sites at L171, L201, L386, L403, L748.

If any match appears outside this file, **stop and re-evaluate scope**: the function may not actually be private or another file has copy-pasted the name.

- [ ] **Step 2: Confirm all 5 call sites currently use `._asPeer()`**

Run:

```bash
grep -n "peerTokenTitle(.*_asPeer())" submodules/TelegramUI/Sources/ContactMultiselectionController.swift
```

Expected: 5 matches, line numbers 171, 201, 386, 403, 748.

If the count is not 5, **stop and re-inventory** — a prior change may have shifted line numbers or altered a call site.

- [ ] **Step 3: Confirm no other `peerTokenTitle` overload exists**

Run:

```bash
grep -n "func peerTokenTitle" submodules/TelegramUI/Sources/ContactMultiselectionController.swift
```

Expected: exactly 1 match at line 21 (`private func peerTokenTitle(...)`).

- [ ] **Step 4: Confirm `EnginePeer.displayTitle(strings:displayOrder:)` exists**

Run:

```bash
grep -rn "func displayTitle(strings:" submodules/TelegramCore/Sources/TelegramEngine/ submodules/TelegramCore/Sources/SyncCore/
```

Expected: a match on `EnginePeer` extension exposing `displayTitle(strings: PresentationStrings, displayOrder: PresentationPersonNameOrder)`. (This is the method already called as `EnginePeer(peer).displayTitle(...)` at L27, so its existence is certain — this step just makes the dependency explicit.)

---

## Task 2: Edit the function signature and body

**Files:**
- Modify: `submodules/TelegramUI/Sources/ContactMultiselectionController.swift:21-29`

- [ ] **Step 1: Read the current function definition**

Read the file, lines 21–29. Current state:

```swift
private func peerTokenTitle(accountPeerId: PeerId, peer: Peer, strings: PresentationStrings, nameDisplayOrder: PresentationPersonNameOrder) -> String {
    if peer.id == accountPeerId {
        return strings.DialogList_SavedMessages
    } else if peer.id.isReplies {
        return strings.DialogList_Replies
    } else {
        return EnginePeer(peer).displayTitle(strings: strings, displayOrder: nameDisplayOrder)
    }
}
```

- [ ] **Step 2: Apply the signature change**

Use Edit with:

- `old_string`:
  ```
  private func peerTokenTitle(accountPeerId: PeerId, peer: Peer, strings: PresentationStrings, nameDisplayOrder: PresentationPersonNameOrder) -> String {
      if peer.id == accountPeerId {
          return strings.DialogList_SavedMessages
      } else if peer.id.isReplies {
          return strings.DialogList_Replies
      } else {
          return EnginePeer(peer).displayTitle(strings: strings, displayOrder: nameDisplayOrder)
      }
  }
  ```
- `new_string`:
  ```
  private func peerTokenTitle(accountPeerId: PeerId, peer: EnginePeer, strings: PresentationStrings, nameDisplayOrder: PresentationPersonNameOrder) -> String {
      if peer.id == accountPeerId {
          return strings.DialogList_SavedMessages
      } else if peer.id.isReplies {
          return strings.DialogList_Replies
      } else {
          return peer.displayTitle(strings: strings, displayOrder: nameDisplayOrder)
      }
  }
  ```

Note: `accountPeerId: PeerId` stays as-is — `PeerId` is already the typealias for `EnginePeer.Id`. `peer.id.isReplies` works unchanged because `EnginePeer.Id` exposes `isReplies`.

---

## Task 3: Drop `._asPeer()` bridges at all 5 call sites

**Files:**
- Modify: `submodules/TelegramUI/Sources/ContactMultiselectionController.swift` (L171, L201, L386, L403, L748)

All 5 call sites have an identical argument fragment:

```
peer: peer._asPeer(),
```

…which must become:

```
peer: peer,
```

The surrounding context differs per site (two distinct `strings/nameDisplayOrder` chains, see below), so we handle the substitution in two batches.

- [ ] **Step 1: Replace sites L171, L201, L748 (use `strongSelf.presentationData.strings` / `strongSelf.presentationData.nameDisplayOrder` or `self.presentationData.strings` / `self.presentationData.nameDisplayOrder`)**

Three call sites share identical code but with different leading `accountPeerId` expressions. Apply them individually.

**L171 and L201 are identical** — both read:

```swift
return EditableTokenListToken(id: peer.id, title: peerTokenTitle(accountPeerId: params.context.account.peerId, peer: peer._asPeer(), strings: strongSelf.presentationData.strings, nameDisplayOrder: strongSelf.presentationData.nameDisplayOrder), fixedPosition: nil, subject: .peer(peer))
```

Use Edit with `replace_all=true`:

- `old_string`:
  ```
  return EditableTokenListToken(id: peer.id, title: peerTokenTitle(accountPeerId: params.context.account.peerId, peer: peer._asPeer(), strings: strongSelf.presentationData.strings, nameDisplayOrder: strongSelf.presentationData.nameDisplayOrder), fixedPosition: nil, subject: .peer(peer))
  ```
- `new_string`:
  ```
  return EditableTokenListToken(id: peer.id, title: peerTokenTitle(accountPeerId: params.context.account.peerId, peer: peer, strings: strongSelf.presentationData.strings, nameDisplayOrder: strongSelf.presentationData.nameDisplayOrder), fixedPosition: nil, subject: .peer(peer))
  ```

**L748** reads:

```swift
tokens.append(EditableTokenListToken(id: peer.id, title: peerTokenTitle(accountPeerId: self.context.account.peerId, peer: peer._asPeer(), strings: self.presentationData.strings, nameDisplayOrder: self.presentationData.nameDisplayOrder), fixedPosition: nil, subject: .peer(peer)))
```

Use Edit (no `replace_all` — this line is unique):

- `old_string`:
  ```
  tokens.append(EditableTokenListToken(id: peer.id, title: peerTokenTitle(accountPeerId: self.context.account.peerId, peer: peer._asPeer(), strings: self.presentationData.strings, nameDisplayOrder: self.presentationData.nameDisplayOrder), fixedPosition: nil, subject: .peer(peer)))
  ```
- `new_string`:
  ```
  tokens.append(EditableTokenListToken(id: peer.id, title: peerTokenTitle(accountPeerId: self.context.account.peerId, peer: peer, strings: self.presentationData.strings, nameDisplayOrder: self.presentationData.nameDisplayOrder), fixedPosition: nil, subject: .peer(peer)))
  ```

- [ ] **Step 2: Replace sites L386 and L403 (use `accountPeerId` local)**

**L386 and L403 are identical** — both read:

```swift
addedToken = EditableTokenListToken(id: peer.id, title: peerTokenTitle(accountPeerId: accountPeerId, peer: peer._asPeer(), strings: strongSelf.presentationData.strings, nameDisplayOrder: strongSelf.presentationData.nameDisplayOrder), fixedPosition: nil, subject: .peer(peer))
```

Use Edit with `replace_all=true`:

- `old_string`:
  ```
  addedToken = EditableTokenListToken(id: peer.id, title: peerTokenTitle(accountPeerId: accountPeerId, peer: peer._asPeer(), strings: strongSelf.presentationData.strings, nameDisplayOrder: strongSelf.presentationData.nameDisplayOrder), fixedPosition: nil, subject: .peer(peer))
  ```
- `new_string`:
  ```
  addedToken = EditableTokenListToken(id: peer.id, title: peerTokenTitle(accountPeerId: accountPeerId, peer: peer, strings: strongSelf.presentationData.strings, nameDisplayOrder: strongSelf.presentationData.nameDisplayOrder), fixedPosition: nil, subject: .peer(peer))
  ```

- [ ] **Step 3: Grep to confirm zero remaining bridge sites**

Run:

```bash
grep -n "peerTokenTitle(.*_asPeer())" submodules/TelegramUI/Sources/ContactMultiselectionController.swift
```

Expected: **0 matches**.

If any match remains, the previous edits missed a line variant — re-read the file around each missed line and apply a targeted Edit for that variant.

- [ ] **Step 4: Confirm the 5 expected `peer: peer,` call sites now appear**

Run:

```bash
grep -n "peerTokenTitle(.*peer: peer," submodules/TelegramUI/Sources/ContactMultiselectionController.swift
```

Expected: 5 matches, line numbers approximately 171, 201, 386, 403, 748 (exact numbers unchanged — the edits don't shift line counts).

---

## Task 4: Build verification

**Files:** None edited in this task.

- [ ] **Step 1: Run the full project build with --continueOnError**

Run:

```bash
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 --configuration=debug_sim_arm64 \
 --continueOnError
```

Expected: build succeeds with exit code 0 and no compilation errors.

**If the build fails:**

1. Inspect the error output. Three failure modes are anticipated (all should be rare given the scope):
   - **Missing `displayTitle` on `EnginePeer`:** unlikely, since L27 was calling it pre-migration. If it happens, verify the `EnginePeer` import chain — but do not add new imports; this file already imports `TelegramCore`.
   - **A 6th call site exists** that the pre-flight grep missed (e.g., one using a different string pattern like `peer:peer` with no space, or a multi-line call). Locate it with `grep -n "peerTokenTitle" submodules/TelegramUI/Sources/ContactMultiselectionController.swift` and apply the bridge drop manually.
   - **Unrelated type-inference cascade**, e.g., some `peer` local was previously inferred as `Peer` via the callback chain and now can't be. Read the error line and assess: if it's inside the function body or call site, adjust; if it's elsewhere in the file, it was pre-existing and unrelated — still, don't touch it mid-wave. Abandon per wave-rule 5 if scope creep is required.
2. Re-run the build after the fix.

- [ ] **Step 2: Confirm the post-migration grep is clean**

Run (after successful build):

```bash
grep -n "peerTokenTitle(.*_asPeer())" submodules/TelegramUI/Sources/ContactMultiselectionController.swift
```

Expected: **0 matches**.

---

## Task 5: Commit

**Files:**
- `submodules/TelegramUI/Sources/ContactMultiselectionController.swift`

- [ ] **Step 1: Stage the one file**

Run:

```bash
git add submodules/TelegramUI/Sources/ContactMultiselectionController.swift
```

- [ ] **Step 2: Verify the staged diff**

Run:

```bash
git diff --cached --stat
```

Expected: `1 file changed, 6 insertions(+), 6 deletions(-)` (or thereabouts — 1 line's worth of signature change, 1 body-line change, 5 identical call-site changes; each is a 1-line replacement, net zero line-count delta).

Also run:

```bash
git diff --cached
```

Inspect manually to confirm: (a) the function signature changed `peer: Peer` → `peer: EnginePeer`; (b) the body `EnginePeer(peer).displayTitle(...)` → `peer.displayTitle(...)`; (c) 5 call sites lost `._asPeer()`. No other edits.

- [ ] **Step 3: Commit**

Run:

```bash
git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 37

peerTokenTitle: peer parameter Peer -> EnginePeer.

Drops 5 _asPeer() bridges in ContactMultiselectionController.swift
(L171, L201, L386, L403, L748) - bridges installed by prior waves.

Private free function, single-file change.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: Confirm commit**

Run:

```bash
git log --oneline -3
```

Expected: the new wave-37 commit at the top.

---

## Task 6: Update memory / log

**Files:**
- Modify: `/Users/isaac/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`
- Modify: `docs/superpowers/postbox-refactor-log.md`

- [ ] **Step 1: Read the current memory file for the refactor**

Read `/Users/isaac/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`.

- [ ] **Step 2: Update frontmatter + add wave-37 entry**

Update the `description:` frontmatter field to reference wave 37 outcome (number of bridges dropped, build-iteration count, first-pass-clean-or-not). Add a bullet to "Latest commits" section with the new SHA and a one-line summary. Remove the "peerTokenTitle parameter migration" bullet from the "Wave 37 candidates" section (it's now landed). Update "Recommended wave 37" section to "Recommended wave 38" with a fresh recommendation from the remaining candidates.

- [ ] **Step 3: Read the refactor log**

Read `docs/superpowers/postbox-refactor-log.md`, locate the "Wave 36 outcome" section.

- [ ] **Step 4: Append wave-37 outcome**

Under the "Wave N outcomes" section, append a "Wave 37 outcome" subsection with:

- Commit SHA (from `git log --oneline -1`)
- File touched (1: ContactMultiselectionController.swift)
- Lines changed (6 deletions, 6 insertions)
- Bridges dropped (5)
- Build iterations to converge (should be 1)
- Any lessons observed (likely none — this wave is mechanical)

- [ ] **Step 5: Commit memory + log update**

Run:

```bash
git add docs/superpowers/postbox-refactor-log.md
git commit -m "$(cat <<'EOF'
docs: log wave 37 outcome

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

(Memory file under `~/.claude/` is not in the repo — save it separately via the Write tool; do not try to `git add` it.)

---

## Self-review results

**Spec coverage:** Every scope item in the spec maps to a task:
- Spec L21 signature change → Task 2 Step 2
- Spec L27 body simplification → Task 2 Step 2
- Spec L171/201/386/403/748 bridge drops → Task 3 Steps 1–2
- Spec verification (grep + build + post-grep) → Task 1 + Task 4
- Spec commit message → Task 5 Step 3

Out-of-scope items (L459, `import Postbox`, `accountPeerId: PeerId`) remain explicitly untouched — no task edits them.

**Placeholder scan:** No TBD, TODO, placeholder phrases, or "handle edge cases"-style hand-waves. Every step has a concrete command or code block.

**Type consistency:** `peer: EnginePeer`, `EnginePeer.Id` (= `PeerId` typealias), and `EnginePeer.displayTitle(strings:displayOrder:)` are all consistent across tasks.
