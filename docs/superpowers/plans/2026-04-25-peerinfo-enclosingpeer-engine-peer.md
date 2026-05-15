# Wave 50: enclosingPeer Peer? → EnginePeer? Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the PeerInfo members chain's `enclosingPeer` field from raw Postbox `Peer?` to `EnginePeer?` (wave 50 of the Postbox → TelegramEngine refactor).

**Architecture:** Cross-file private struct-field migration with stored-form ratchet. Edits stay inside `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/`. Replaces `as? TelegramChannel` / `as? TelegramGroup` casts with `case let .channel(...)` / `case let .legacyGroup(...)` (wave-41/45 idiom), drops `is TelegramChannel` checks for `case .channel = ...` (wave-41 always-false-warning fix), and removes 5 internal `_asPeer()` / `EnginePeer(...)` / `flatMap(EnginePeer.init)` bridges. The engine.data subscription at PIMP:354 already returns `EnginePeer?` — this wave closes the demote-then-promote ratchet.

**Tech Stack:** Swift, Bazel via `Make.py`, no unit tests (per `CLAUDE.md`). Verification is the full-project debug-sim-arm64 build with `--continueOnError`.

**Iteration budget:** 1–2 (target first-pass-clean; recent first-pass-clean streak: waves 42, 43*, 45, 46, 48, 49 — *wave 43 took 2 iterations).

**Note on TDD:** This project has no unit tests (CLAUDE.md "No tests are used at the moment"). The standard TDD test-first cycle in the skill template does not apply. Each task instead writes the edits, then verifies via Bazel build + residue grep.

---

## File Structure

| File | Role | Changes |
|---|---|---|
| `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/ListItems/PeerInfoScreenMemberItem.swift` (PSMI) | List-item view-model + node | Type-change stored field + init param; 4 cast/is-check rewrites; 1 `flatMap(EnginePeer.init)` simplification |
| `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/Panes/PeerInfoMembersPane.swift` (PIMP) | Members-pane node + helpers | 3 func sigs + 1 stored field type-change; 4 cast/is-check rewrites; 1 `EnginePeer(...)` wrap drop; 2 `_asPeer()` drops |
| `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoProfileItems.swift` (PSPB) | Profile-items builder (non-settings members section) | 1 boundary `_asPeer()` drop at the call site that constructs the migrated init |

No public-API ripple — `PeerInfoScreenMemberItem` and `PeerInfoMembersPaneNode` are local to the PeerInfoScreen module.

---

## Task 1: PSMI.swift — type changes + cast/is-check rewrites + flatMap simplification

**Files:**
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/ListItems/PeerInfoScreenMemberItem.swift`

**Edits in this task:** 7 (1 stored-field type, 1 init-param type, 2 cast→case-let, 2 is→case, 1 flatMap simplification).

- [ ] **Step 1: Change stored field type at line 23**

Find:

```swift
    let enclosingPeer: Peer?
```

Replace with:

```swift
    let enclosingPeer: EnginePeer?
```

- [ ] **Step 2: Change init parameter type at line 34**

Find:

```swift
        enclosingPeer: Peer?,
```

Replace with:

```swift
        enclosingPeer: EnginePeer?,
```

- [ ] **Step 3: Rewrite cast at line 152 (TelegramChannel)**

Find:

```swift
                    if let channel = item.enclosingPeer as? TelegramChannel, channel.hasPermission(.editRank) {
```

Replace with:

```swift
                    if case let .channel(channel) = item.enclosingPeer, channel.hasPermission(.editRank) {
```

- [ ] **Step 4: Rewrite cast at line 154 (TelegramGroup)**

Find:

```swift
                    } else if let group = item.enclosingPeer as? TelegramGroup, !group.hasBannedPermission(.banEditRank) {
```

Replace with:

```swift
                    } else if case let .legacyGroup(group) = item.enclosingPeer, !group.hasBannedPermission(.banEditRank) {
```

- [ ] **Step 5: Simplify flatMap at line 178**

Find:

```swift
        let actions = availableActionsForMemberOfPeer(accountPeerId: item.context.accountPeerId, peer: item.enclosingPeer.flatMap(EnginePeer.init), member: item.member)
```

Replace with:

```swift
        let actions = availableActionsForMemberOfPeer(accountPeerId: item.context.accountPeerId, peer: item.enclosingPeer, member: item.member)
```

- [ ] **Step 6: Rewrite is-check at line 181**

Find:

```swift
        if actions.contains(.promote) && item.enclosingPeer is TelegramChannel {
```

Replace with:

```swift
        if actions.contains(.promote), case .channel = item.enclosingPeer {
```

- [ ] **Step 7: Rewrite is-check at line 187**

Find:

```swift
            if item.enclosingPeer is TelegramChannel {
```

Replace with:

```swift
            if case .channel = item.enclosingPeer {
```

---

## Task 2: PIMP.swift — signatures + stored field + body rewrites + demotion drops

**Files:**
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/Panes/PeerInfoMembersPane.swift`

**Edits in this task:** 11 (3 func sigs + 1 stored-field type + 4 cast/is rewrites + 1 EnginePeer wrap drop + 2 `_asPeer()` drops).

- [ ] **Step 1: Change `func item(...)` signature at line 92**

Find:

```swift
    func item(context: AccountContext, presentationData: PresentationData, enclosingPeer: Peer, addMemberAction: @escaping () -> Void, action: @escaping (PeerInfoMember, PeerMembersListAction) -> Void, contextAction: ((PeerInfoMember, ASDisplayNode, ContextGesture?) -> Void)?) -> ListViewItem {
```

Replace with:

```swift
    func item(context: AccountContext, presentationData: PresentationData, enclosingPeer: EnginePeer, addMemberAction: @escaping () -> Void, action: @escaping (PeerInfoMember, PeerMembersListAction) -> Void, contextAction: ((PeerInfoMember, ASDisplayNode, ContextGesture?) -> Void)?) -> ListViewItem {
```

- [ ] **Step 2: Rewrite cast at line 113 (TelegramChannel, non-optional context)**

Find:

```swift
                            if let channel = enclosingPeer as? TelegramChannel, channel.hasPermission(.editRank) {
```

Replace with:

```swift
                            if case let .channel(channel) = enclosingPeer, channel.hasPermission(.editRank) {
```

- [ ] **Step 3: Rewrite cast at line 115 (TelegramGroup, non-optional context)**

Find:

```swift
                            } else if let group = enclosingPeer as? TelegramGroup, !group.hasBannedPermission(.banEditRank) {
```

Replace with:

```swift
                            } else if case let .legacyGroup(group) = enclosingPeer, !group.hasBannedPermission(.banEditRank) {
```

- [ ] **Step 4: Drop the `EnginePeer(...)` wrap at line 139**

Find:

```swift
                let actions = availableActionsForMemberOfPeer(accountPeerId: context.account.peerId, peer: EnginePeer(enclosingPeer), member: member)
```

Replace with:

```swift
                let actions = availableActionsForMemberOfPeer(accountPeerId: context.account.peerId, peer: enclosingPeer, member: member)
```

`availableActionsForMemberOfPeer` takes `peer: EnginePeer?` (PeerInfoData.swift:2314); Swift auto-wraps the non-optional `enclosingPeer: EnginePeer` to optional.

- [ ] **Step 5: Rewrite is-check at line 142 (non-optional context)**

Find:

```swift
                if actions.contains(.promote) && enclosingPeer is TelegramChannel {
```

Replace with:

```swift
                if actions.contains(.promote), case .channel = enclosingPeer {
```

- [ ] **Step 6: Rewrite is-check at line 148 (non-optional context)**

Find:

```swift
                    if enclosingPeer is TelegramChannel {
```

Replace with:

```swift
                    if case .channel = enclosingPeer {
```

- [ ] **Step 7: Change `preparedTransition` signature at line 271**

Find:

```swift
private func preparedTransition(from fromEntries: [PeerMembersListEntry], to toEntries: [PeerMembersListEntry], context: AccountContext, presentationData: PresentationData, enclosingPeer: Peer, addMemberAction: @escaping () -> Void, action: @escaping (PeerInfoMember, PeerMembersListAction) -> Void, contextAction: ((PeerInfoMember, ASDisplayNode, ContextGesture?) -> Void)?) -> PeerMembersListTransaction {
```

Replace with:

```swift
private func preparedTransition(from fromEntries: [PeerMembersListEntry], to toEntries: [PeerMembersListEntry], context: AccountContext, presentationData: PresentationData, enclosingPeer: EnginePeer, addMemberAction: @escaping () -> Void, action: @escaping (PeerInfoMember, PeerMembersListAction) -> Void, contextAction: ((PeerInfoMember, ASDisplayNode, ContextGesture?) -> Void)?) -> PeerMembersListTransaction {
```

- [ ] **Step 8: Change stored field type at line 293**

Find:

```swift
    private var enclosingPeer: Peer?
```

Replace with:

```swift
    private var enclosingPeer: EnginePeer?
```

- [ ] **Step 9: Drop `_asPeer()` at line 361**

Find:

```swift
            strongSelf.enclosingPeer = enclosingPeer._asPeer()
```

Replace with:

```swift
            strongSelf.enclosingPeer = enclosingPeer
```

- [ ] **Step 10: Drop `_asPeer()` at line 363**

Find:

```swift
            strongSelf.updateState(enclosingPeer: enclosingPeer._asPeer(), state: state, presentationData: presentationData)
```

Replace with:

```swift
            strongSelf.updateState(enclosingPeer: enclosingPeer, state: state, presentationData: presentationData)
```

- [ ] **Step 11: Change `updateState` signature at line 442**

Find:

```swift
    private func updateState(enclosingPeer: Peer, state: PeerInfoMembersState, presentationData: PresentationData) {
```

Replace with:

```swift
    private func updateState(enclosingPeer: EnginePeer, state: PeerInfoMembersState, presentationData: PresentationData) {
```

The pass-through call sites at PIMP:275, :276, :437, :438, :451, :485 require no edit — types flow through transparently.

---

## Task 3: PSPB.swift — boundary lift at members-section call site

**Files:**
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoProfileItems.swift`

**Edits in this task:** 1.

- [ ] **Step 1: Drop `_asPeer()` at line 852**

Find:

```swift
            items[.peerMembers]!.append(PeerInfoScreenMemberItem(id: member.id, context: .account(context), enclosingPeer: peer._asPeer(), member: member, isAccount: false, action: isAccountPeer ? { _ in
```

Replace with:

```swift
            items[.peerMembers]!.append(PeerInfoScreenMemberItem(id: member.id, context: .account(context), enclosingPeer: peer, member: member, isAccount: false, action: isAccountPeer ? { _ in
```

`peer` here is the closure-bound `EnginePeer` from the `data.peer` source pipeline (`PeerInfoScreenData.peer: EnginePeer?` post-wave-42, unwrapped to non-optional `EnginePeer` and being passed to a now-`EnginePeer?` param — auto-promotes to optional).

The other `PeerInfoScreenMemberItem(...)` construction at `PeerInfoSettingsItems.swift:132` passes `enclosingPeer: nil`, which is valid for either optional type — no edit.

---

## Task 4: Full-project Bazel build

**Files:** none (verification only).

- [ ] **Step 1: Run the build with `--continueOnError`**

Run:

```sh
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent \
 --buildNumber=1 --configuration=debug_sim_arm64 --continueOnError
```

Expected: clean build (`bazel build complete` or equivalent green output).

- [ ] **Step 2: If build fails, triage iteration**

If errors land in `PeerInfoScreenMemberItem.swift` or `PeerInfoMembersPane.swift` or `PeerInfoProfileItems.swift`:
- Read the failing line.
- Common failure modes from prior waves:
  - **Always-false `is` warning under `-warnings-as-errors`**: leftover `is TelegramX` not converted in step. Re-grep `enclosingPeer is Telegram` over the 3 files.
  - **Always-failing `as?` cast warning**: leftover `as? TelegramX` not converted. Re-grep `enclosingPeer.*as\?`.
  - **Type mismatch on closure-capture alias**: a `strongSelf.enclosingPeer` or `self.enclosingPeer` site missed a `_asPeer()` drop. Re-grep `enclosingPeer\._asPeer\|EnginePeer\(enclosingPeer`.
  - **Unused variable warning**: a binding from `case let .channel(channel)` not actually used. Re-read the body.

Fix in place and re-run step 1. Budget: 2 iterations.

If errors land outside those 3 files: **STOP**. The wave was supposed to be self-contained. Re-read the spec, identify the missed call site, decide whether to add it or abandon the wave.

---

## Task 5: Post-edit residue grep

**Files:** none (verification only).

- [ ] **Step 1: Bridge residue grep**

Run:

```sh
grep -rnE "enclosingPeer\._asPeer|EnginePeer\(enclosingPeer\)|enclosingPeer\.flatMap\(EnginePeer" \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/
```

Expected: empty output.

- [ ] **Step 2: Cast/is-check residue grep**

Run:

```sh
grep -rnE "enclosingPeer.*as\? TelegramChannel|enclosingPeer.*as\? TelegramGroup|enclosingPeer is TelegramChannel" \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/
```

Expected: empty output.

- [ ] **Step 3: Sanity check — `enclosingPeer` references should now exclusively type-resolve to EnginePeer**

Run:

```sh
grep -nE ": Peer\b" submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/ListItems/PeerInfoScreenMemberItem.swift submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/Panes/PeerInfoMembersPane.swift
```

Expected: no `enclosingPeer: Peer` or `enclosingPeer: Peer?` annotations remain. (Other `: Peer` annotations on unrelated symbols are fine.)

---

## Task 6: Commit the wave

**Files:** none (git only).

- [ ] **Step 1: Stage the 3 modified files**

```sh
git add \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/ListItems/PeerInfoScreenMemberItem.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/Panes/PeerInfoMembersPane.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoProfileItems.swift
```

- [ ] **Step 2: Confirm staging is clean**

```sh
git status --short | grep -v "^??"
```

Expected output: only the 3 staged files (lines starting with `M ` or `A `). If other modified files appear, they predate the wave (per CLAUDE.md memory: build-system/bazel-rules/sourcekit-bazel-bsp submodule marker is pre-existing WIP).

- [ ] **Step 3: Commit**

```sh
git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 50

Migrate enclosingPeer Peer? -> EnginePeer? across PeerInfoScreenMemberItem
+ PeerInfoMembersPaneNode + 1 PSPB call site. 19 edits / 3 files.

Drops 5 internal bridges: 2 _asPeer() demotions at PIMP:361/363, 1
EnginePeer(enclosingPeer) wrap at PIMP:139, 1 flatMap(EnginePeer.init)
at PSMI:178, 1 boundary _asPeer() lift at PSPB:852.

Closes the wave-48-pattern internal-demotion-and-external-re-promotion
ratchet at PIMP:354-363 (engine.data subscription returns EnginePeer?,
previously demoted to Peer? at storage).

All `as? TelegramChannel` / `as? TelegramGroup` casts converted to
`case let .channel(...)` / `case let .legacyGroup(...)` (wave-41/45
idiom). All `is TelegramChannel` checks converted to
`case .channel = ...` (wave-41 always-false-warning fix).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: Verify commit**

```sh
git log --oneline -1
```

Expected: shows the wave 50 commit.

---

## Task 7: Update outcome log + memory

**Files:**
- Modify: `docs/superpowers/postbox-refactor-log.md`
- Modify: `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`

- [ ] **Step 1: Append wave 50 outcome to refactor log**

Add a "Wave 50 outcome" entry at the appropriate chronological position in `docs/superpowers/postbox-refactor-log.md`. Use the wave 49 outcome entry as the template. Include:
- Commit hash (from Task 6 step 4).
- Iteration count (1 if first-pass-clean; 2 if Task 4 step 2 fired once).
- Net-bridge accounting: −5 internal bridges (2 `_asPeer()` + 1 `EnginePeer(...)` wrap + 1 `flatMap(EnginePeer.init)` + 1 boundary `_asPeer()` lift). 0 ADD wraps. 0 boundary lifts net new.
- Bazel build duration (from Task 4 step 1 output).
- Any wave-specific lessons surfaced.

- [ ] **Step 2: Update wave-50-next-wave memory**

Edit `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`:
- Promote wave 50 outcome line into the "Latest commits" section using the format of the wave 49 entry.
- Update the top frontmatter `description` to reflect wave 50 landed and propose wave 51.
- Promote the wave-51 candidate (`PeerInfoGroupsInCommonPaneNode.PeerEntry.peer: Peer → EnginePeer`) to the top of the "Wave 51 candidates" section, replacing the now-stale "Wave 50 candidates" header. Re-run the broader grep if needed:

```sh
grep -rnE "^\s*(let|var|public let|public var|private let|private var) [a-zA-Z_]+: Peer\??$|^\s*(let|var|public let|public var|private let|private var) [a-zA-Z_]+: Peer\? = " \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/ --include="*.swift" | grep -v "EnginePeer"
```

- [ ] **Step 3: Commit the doc update**

```sh
git add docs/superpowers/postbox-refactor-log.md
git commit -m "$(cat <<'EOF'
docs: log wave 50 outcome

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

(Memory file updates are not committed — they live outside the repo.)

---

## Net delta projection (from spec)

| Category | Count | Sites |
|---|---|---|
| Internal bridge drops | −5 | PIMP:361, PIMP:363, PIMP:139, PSMI:178, PSPB:852 |
| Boundary lifts (net new) | 0 | source pipeline already EnginePeer? |
| ADD wraps | 0 | no Peer-only property accesses on bare `enclosingPeer` |
| Cast→case-let conversions | 4 | PSMI:152/154, PIMP:113/115 |
| `is`→`case` conversions | 4 | PSMI:181/187, PIMP:142/148 |
| Type annotations updated | 6 | PSMI:23/34, PIMP:92/271/293/442 |

**Total commit footprint:** 19 line edits across 3 files, plus a docs commit for the outcome log.
