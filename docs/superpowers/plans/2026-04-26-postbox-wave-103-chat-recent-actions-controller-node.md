# Wave 103: ChatRecentActionsControllerNode peer Peer → EnginePeer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `ChatRecentActionsControllerNode`'s stored `peer: Peer` field to `EnginePeer`, dropping the `_asPeer()` boundary call at the single caller site (wave 103 of the Postbox → TelegramEngine refactor).

**Architecture:** Wave-71-shadow close. Single-file private stored-form migration plus a 1-line caller drop. The caller (`ChatRecentActionsController`) already holds `peer: EnginePeer` and demotes once before passing into the node init. The wave drops the demotion and rewrites 3 `as? TelegramChannel` downcasts inside the node body to `case let .channel(...)` (wave-41/45 idiom). All scope is within `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/`.

**Tech Stack:** Swift, Bazel via `Make.py`, no unit tests (per `CLAUDE.md`). Verification is the full-project debug-sim-arm64 build.

**Iteration budget:** 1 (target first-pass-clean given the 7-edit scope and validated pre-flight grep).

**Note on TDD:** This project has no unit tests. The standard TDD test-first cycle does not apply. Each task writes the edits, then verifies via Bazel build + residue grep.

---

## File Structure

| File | Role | Changes |
|---|---|---|
| `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsControllerNode.swift` (CRACN) | Recent-actions screen controller node | Drop `import Postbox`, retype stored field + init param, rewrite 3 `as? TelegramChannel` downcasts (6 edits) |
| `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsController.swift` (CRAC) | Recent-actions screen controller (caller) | Drop `_asPeer()` at the node init (1 edit) |

No public-API ripple — `ChatRecentActionsControllerNode` is local to the module and has a single caller verified by grep.

---

## Task 1: CRACN.swift — drop `import Postbox` + type changes + downcast rewrites

**Files:**
- Modify: `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsControllerNode.swift`

**Edits in this task:** 6 (1 import drop, 1 stored-field retype, 1 init-param retype, 3 cast → case-let).

- [ ] **Step 1: Drop `import Postbox` at line 5**

Find:

```swift
import Postbox
```

Replace with: (delete the line entirely)

This file imports `TelegramCore` at line 4, which provides the `EnginePeer` type and the typealiases needed for the rest of this task.

- [ ] **Step 2: Retype stored field at line 46**

Find:

```swift
    private let peer: Peer
```

Replace with:

```swift
    private let peer: EnginePeer
```

- [ ] **Step 3: Retype init parameter at line 111**

Find:

```swift
    init(context: AccountContext, controller: ChatRecentActionsController, peer: Peer, presentationData: PresentationData, pushController: @escaping (ViewController) -> Void, presentController: @escaping (ViewController, PresentationContextType, Any?) -> Void, getNavigationController: @escaping () -> NavigationController?) {
```

Replace with:

```swift
    init(context: AccountContext, controller: ChatRecentActionsController, peer: EnginePeer, presentationData: PresentationData, pushController: @escaping (ViewController) -> Void, presentController: @escaping (ViewController, PresentationContextType, Any?) -> Void, getNavigationController: @escaping () -> NavigationController?) {
```

- [ ] **Step 4: Rewrite downcast at line 899**

Find:

```swift
                            if let peer = strongSelf.peer as? TelegramChannel {
```

Replace with:

```swift
                            if case let .channel(peer) = strongSelf.peer {
```

The bound name `peer` is preserved so the inner block (`switch peer.info { case .group: ... }`) ports verbatim. `case let .channel(peer)` binds `peer: TelegramChannel` directly (the associated value of `EnginePeer.channel`).

- [ ] **Step 5: Rewrite downcast at line 948**

Find:

```swift
        if let channel = self.peer as? TelegramChannel, case .broadcast = channel.info {
```

Replace with:

```swift
        if case let .channel(channel) = self.peer, case .broadcast = channel.info {
```

The compound condition (`, case .broadcast = channel.info`) ports verbatim because the bound `channel` is still `TelegramChannel`-typed.

- [ ] **Step 6: Rewrite downcast at line 1088**

Find:

```swift
            if let channel = self.peer as? TelegramChannel {
```

Replace with:

```swift
            if case let .channel(channel) = self.peer {
```

The inner block (`channel.hasPermission(.banMembers)`, `case .broadcast = channel.info`) ports verbatim.

The `self.peer.id` accesses at lines 145, 161, 1138, 1490 require no edit — `EnginePeer.id` is a typealiased `PeerId`, identical at the call sites.

---

## Task 2: CRAC.swift — drop boundary `_asPeer()`

**Files:**
- Modify: `submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsController.swift`

**Edits in this task:** 1.

- [ ] **Step 1: Drop `_asPeer()` at line 277**

Find:

```swift
        self.displayNode = ChatRecentActionsControllerNode(context: self.context, controller: self, peer: self.peer._asPeer(), presentationData: self.presentationData, pushController: { [weak self] c in
```

Replace with:

```swift
        self.displayNode = ChatRecentActionsControllerNode(context: self.context, controller: self, peer: self.peer, presentationData: self.presentationData, pushController: { [weak self] c in
```

`ChatRecentActionsController.peer` is already declared `EnginePeer` at line 42 (`public init(context: AccountContext, peer: EnginePeer, ...)`) — the type carries through to the now-`EnginePeer`-typed init parameter.

---

## Task 3: Full-project Bazel build

**Files:** none (verification only).

- [ ] **Step 1: Run the build**

Run:

```sh
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent \
 --buildNumber=1 --configuration=debug_sim_arm64
```

Expected: clean build (`bazel build complete` or equivalent green output). No `--continueOnError` because the small scope makes the first error informative.

Build cost projection: consumer-only, ~25s. If it exceeds ~60s, suspect a cascade leak.

- [ ] **Step 2: If build fails, triage iteration**

If errors land in `ChatRecentActionsControllerNode.swift` or `ChatRecentActionsController.swift`:
- Read the failing line.
- Common failure modes from prior waves:
  - **Always-false `is` warning under `-warnings-as-errors`:** none expected here (pre-flight grep confirmed no `is TelegramChannel` checks on `self.peer`). If one surfaces anyway, convert to `case .channel = self.peer`.
  - **Always-failing `as?` cast warning:** leftover `as? TelegramX` not converted in step 4/5/6. Re-grep `(self|strongSelf)\.peer as\?` over the file.
  - **Type mismatch on closure-capture alias:** none expected here (pre-flight grep confirmed only `strongSelf.peer` and `self.peer` aliases, both ride the type change).
  - **Type mismatch on `.id` access:** would indicate a regression in the `EnginePeer.Id` typealias — STOP and re-read CLAUDE.md, this is not a wave-103 issue.
  - **Unused-variable warning under `-warnings-as-errors`:** a `case let .channel(peer)` binding not used inside the body. Re-read step 4/5/6 — if the inner block never references the bound name, switch to `case .channel = ...` and remove the binding.

Fix in place and re-run step 1. Budget: 2 iterations.

If errors land outside those 2 files: **STOP**. The wave was supposed to be self-contained. Re-read the spec, identify the missed call site, decide whether to add it or abandon the wave.

---

## Task 4: Post-edit residue grep

**Files:** none (verification only).

- [ ] **Step 1: Cast residue grep**

Run:

```sh
grep -nE "(self|strongSelf)\.peer as\? Telegram(Channel|Group|User)" \
  submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/
```

Expected: empty output.

- [ ] **Step 2: Boundary `_asPeer()` residue grep**

Run:

```sh
grep -nE "self\.peer\._asPeer\(\)" \
  submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/
```

Expected: empty output.

- [ ] **Step 3: `import Postbox` residue grep**

Run:

```sh
grep -rn "^import Postbox$" \
  submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/
```

Expected: empty output. The module is now Postbox-import-free.

- [ ] **Step 4: Sanity check — `peer: Peer` annotations**

Run:

```sh
grep -nE "peer: Peer\b" \
  submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsControllerNode.swift
```

Expected: empty output. (The 3 `as? TelegramChannel` downcasts on `self.peer` were the only sources; both `peer: Peer` annotations on stored field and init param are now `peer: EnginePeer`.)

---

## Task 5: Commit the wave

**Files:** none (git only).

- [ ] **Step 1: Stage the 2 modified files**

```sh
git add \
  submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsControllerNode.swift \
  submodules/TelegramUI/Components/Chat/ChatRecentActionsController/Sources/ChatRecentActionsController.swift
```

- [ ] **Step 2: Confirm staging is clean**

```sh
git status --short | grep -v "^??"
```

Expected output: only the 2 staged files (lines starting with `M `). If other modified files appear, they predate the wave (per CLAUDE.md memory: `build-system/bazel-rules/sourcekit-bazel-bsp` submodule marker is pre-existing WIP).

- [ ] **Step 3: Commit**

```sh
git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 103

Migrate ChatRecentActionsControllerNode.peer Peer -> EnginePeer.
Closes the wave-71 shadow: caller already held EnginePeer and demoted
at the boundary. 7 edits / 2 files.

Drops 1 boundary _asPeer() at ChatRecentActionsController:277, drops
import Postbox at ChatRecentActionsControllerNode:5, rewrites 3
`as? TelegramChannel` downcasts to `case let .channel(...)` (wave-41/45
idiom).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: Verify commit**

```sh
git log --oneline -1
```

Expected: shows the wave 103 commit as HEAD.

---

## Task 6: Update outcome log + memory

**Files:**
- Modify: `docs/superpowers/postbox-refactor-log.md`
- Modify: `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`
- Modify: `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/MEMORY.md`

- [ ] **Step 1: Append wave 103 outcome to refactor log**

Append a "Wave 103 outcome" entry at the chronological end of `docs/superpowers/postbox-refactor-log.md`. Use the most recent wave-outcome entry as a structural template. Include:
- Commit hash (from Task 5 step 4).
- Iteration count (1 if first-pass-clean; 2 if Task 3 step 2 fired).
- Net-bridge accounting: −1 boundary `_asPeer()` (CRAC:277), −1 `import Postbox` (CRACN:5). 0 ADD wraps. 3 cast → case-let conversions (CRACN:899/948/1088).
- Bazel build duration (from Task 3 step 1 output).
- Wave-shape note: wave-71-shadow close, single-iter target validated.

- [ ] **Step 2: Update next-wave memory**

Edit `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`:
- Add the wave 103 outcome line into the recent-waves section (commit hash + 7-edit / 2-file / 1-iter summary).
- Remove the now-stale `ChatRecentActionsControllerNode.peer: Peer -> EnginePeer` candidate line (currently bullet 5 in the candidates list).
- Update the top frontmatter `description` to reflect wave 103 landed and propose wave 104.
- Promote the next candidate (likely one of: `cachedResourceRepresentation` foundational facade, `RenderedPeer` cascade kickoff, `SelectivePrivacyPeer` foundational, or another Shape-C/D mini-refactor) to the top of the candidates list.

- [ ] **Step 3: Update MEMORY.md index**

Edit `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/MEMORY.md`:
- Update the `[Postbox refactor next wave]` line to mention wave 103 landed and shift the "Wave 103+ Shape-C/D candidates" framing forward to "Wave 104+ candidates".

- [ ] **Step 4: Commit the doc update**

```sh
git add docs/superpowers/postbox-refactor-log.md
git commit -m "$(cat <<'EOF'
docs: log wave 103 outcome

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

(Memory file updates at `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/` are not committed — they live outside the repo.)

---

## Net delta projection (from spec)

| Category | Count | Sites |
|---|---|---|
| Internal bridge drops | −1 | CRAC:277 (`_asPeer()`) |
| `import Postbox` drops | −1 | CRACN:5 |
| ADD wraps | 0 | no Peer-only property accesses on bare `self.peer` |
| Cast → case-let conversions | 3 | CRACN:899, CRACN:948, CRACN:1088 |
| Type annotations updated | 2 | CRACN:46 (stored field), CRACN:111 (init param) |
| Postbox-free module count | +1 | `Components/Chat/ChatRecentActionsController/` joins the list |

**Total commit footprint:** 7 line edits across 2 files, plus a docs commit for the outcome log.
