# Wave 105: DeviceContactInfoSubject enum payload Peer? → EnginePeer? Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate `DeviceContactInfoSubject` enum's 3 case payloads + 2 callback signatures + 1 computed property from raw Postbox `Peer?` to `EnginePeer?`. Wave 105 of the Postbox → TelegramEngine refactor.

**Architecture:** Multi-module enum-payload migration (wave-91 shape). 17 edits across 5 files. AccountContext.swift hosts the enum + property. DeviceContactInfoController.swift is the primary consumer. 4 construction sites in TelegramUI/PeerInfoUI/StoryContainerScreen/ChatController. Net wrap delta: −8 (drops 10, adds 2 at Chat-side construction barriers documented per spec).

**Tech Stack:** Swift, Bazel via `Make.py`, no unit tests. Verification is the full-project debug-sim-arm64 build.

**Iteration budget:** 1-3 (wave-91 precedent: 2 iter for similar shape).

**Note on TDD:** No unit tests in this project. Each task writes the edits, then verifies via Bazel build + residue grep.

---

## File Structure

| File | Role | Edits |
|---|---|---|
| `submodules/AccountContext/Sources/AccountContext.swift` | Enum definition + computed property | 4 type-line edits |
| `submodules/PeerInfoUI/Sources/DeviceContactInfoController.swift` | Primary consumer | 9 edits (5 `_asPeer` drops + 3 `.flatMap` simplifications + 1 downcast rewrite) |
| `submodules/TelegramUI/Sources/ChatControllerOpenAttachmentMenu.swift` | Chat-side construction (Pattern E ADD bridges) | 1 Edit (replace_all=true covers 2 sites) |
| `submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerViewSendMessage.swift` | Story-side construction | 1 edit |
| `submodules/TelegramUI/Sources/OpenChatMessage.swift` | OpenChatMessage construction | 1 edit |

---

## Task 1: AccountContext.swift — enum + computed property type changes

**File:** `submodules/AccountContext/Sources/AccountContext.swift`

- [ ] **Step 1: Migrate the 3 enum case payloads (single Edit covers consecutive lines)**

Find:

```swift
public enum DeviceContactInfoSubject {
    case vcard(Peer?, DeviceContactStableId?, DeviceContactExtendedData)
    case filter(peer: Peer?, contactId: DeviceContactStableId?, contactData: DeviceContactExtendedData, completion: (Peer?, DeviceContactExtendedData) -> Void)
    case create(peer: Peer?, contactData: DeviceContactExtendedData, isSharing: Bool, shareViaException: Bool, completion: (Peer?, DeviceContactStableId, DeviceContactExtendedData) -> Void)
    
    public var peer: Peer? {
```

Replace with:

```swift
public enum DeviceContactInfoSubject {
    case vcard(EnginePeer?, DeviceContactStableId?, DeviceContactExtendedData)
    case filter(peer: EnginePeer?, contactId: DeviceContactStableId?, contactData: DeviceContactExtendedData, completion: (EnginePeer?, DeviceContactExtendedData) -> Void)
    case create(peer: EnginePeer?, contactData: DeviceContactExtendedData, isSharing: Bool, shareViaException: Bool, completion: (EnginePeer?, DeviceContactStableId, DeviceContactExtendedData) -> Void)
    
    public var peer: EnginePeer? {
```

This single Edit covers all 4 type-line changes in `AccountContext.swift`. The `contactData: DeviceContactExtendedData` computed property (lines 719-727) is unaffected.

---

## Task 2: DeviceContactInfoController.swift — Pattern D downcast rewrite (1 edit)

**File:** `submodules/PeerInfoUI/Sources/DeviceContactInfoController.swift`

- [ ] **Step 1: Rewrite the `as? TelegramUser` downcast at line 849**

Find:

```swift
        if let peer = peer as? TelegramUser {
```

Replace with:

```swift
        if case let .user(peer) = peer {
```

The leading whitespace (8 spaces) must match exactly. The outer `peer: EnginePeer?` (from `case let .create(peer, ...) = subject` at L845) is shadowed inside the if-body by `peer: TelegramUser` (the `.user` case associated value). Inner body access (`peer.firstName`, `peer.lastName`, `peer.phone`) works on the rebinding.

---

## Task 3: DeviceContactInfoController.swift — Pattern C `.flatMap` simplifications (3 edits)

**File:** `submodules/PeerInfoUI/Sources/DeviceContactInfoController.swift`

- [ ] **Step 1: Simplify `.vcard` case body at line 942**

Find:

```swift
    case let .vcard(peer, id, data):
        contactData = .single((peer.flatMap(EnginePeer.init), id, data))
```

Replace with:

```swift
    case let .vcard(peer, id, data):
        contactData = .single((peer, id, data))
```

- [ ] **Step 2: Simplify `.filter` case body at line 944**

Find:

```swift
    case let .filter(peer, id, data, _):
        contactData = .single((peer.flatMap(EnginePeer.init), id, data))
```

Replace with:

```swift
    case let .filter(peer, id, data, _):
        contactData = .single((peer, id, data))
```

- [ ] **Step 3: Simplify `.create` case body at line 946**

Find:

```swift
    case let .create(peer, data, share, shareViaExceptionValue, _):
        contactData = .single((peer.flatMap(EnginePeer.init), nil, data))
```

Replace with:

```swift
    case let .create(peer, data, share, shareViaExceptionValue, _):
        contactData = .single((peer, nil, data))
```

After Task 1's enum migration, the destructured `peer: EnginePeer?` is the target type — `.flatMap(EnginePeer.init)` becomes a redundant round-trip.

---

## Task 4: DeviceContactInfoController.swift — Pattern B `_asPeer` drops at completion calls (2 edits)

**File:** `submodules/PeerInfoUI/Sources/DeviceContactInfoController.swift`

- [ ] **Step 1: Drop `_asPeer()` at completion call line 1105**

Find:

```swift
                completion(peerAndContactData.0?._asPeer(), filteredData)
```

Replace with:

```swift
                completion(peerAndContactData.0, filteredData)
```

`peerAndContactData.0` is `EnginePeer?` from the typed signal at L939. Completion's first parameter type changes from `Peer?` to `EnginePeer?` per Task 1.

- [ ] **Step 2: Drop `_asPeer()` at completion call line 1224**

Find:

```swift
                                completion(contactIdAndData.2?._asPeer(), contactIdAndData.0, contactIdAndData.1)
```

Replace with:

```swift
                                completion(contactIdAndData.2, contactIdAndData.0, contactIdAndData.1)
```

`contactIdAndData.2` is `EnginePeer?` per the typed signal `(DeviceContactStableId, DeviceContactExtendedData, EnginePeer?)?` declared at L1175.

---

## Task 5: DeviceContactInfoController.swift — Pattern A `_asPeer` drops at construction (3 edits)

**File:** `submodules/PeerInfoUI/Sources/DeviceContactInfoController.swift`

- [ ] **Step 1: Drop `_asPeer()` at line 1289**

Find:

```swift
            replaceControllerImpl?(deviceContactInfoController(context: context, environment: environment, subject: .vcard(peer?._asPeer(), contactId, contactData), completed: nil, cancelled: nil))
```

Replace with:

```swift
            replaceControllerImpl?(deviceContactInfoController(context: context, environment: environment, subject: .vcard(peer, contactId, contactData), completed: nil, cancelled: nil))
```

- [ ] **Step 2: Drop `_asPeer()` at line 1443**

Find:

```swift
                    parentController.present(deviceContactInfoController(context: ShareControllerAppAccountContext(context: context), environment: ShareControllerAppEnvironment(sharedContext: context.sharedContext), subject: .create(peer: peer?._asPeer(), contactData: contactData, isSharing: false, shareViaException: false, completion: { peer, stableId, contactData in
```

Replace with:

```swift
                    parentController.present(deviceContactInfoController(context: ShareControllerAppAccountContext(context: context), environment: ShareControllerAppEnvironment(sharedContext: context.sharedContext), subject: .create(peer: peer, contactData: contactData, isSharing: false, shareViaException: false, completion: { peer, stableId, contactData in
```

- [ ] **Step 3: Drop `_asPeer()` at line 1489**

Find:

```swift
                controller?.present(context.sharedContext.makeDeviceContactInfoController(context: ShareControllerAppAccountContext(context: context), environment: ShareControllerAppEnvironment(sharedContext: context.sharedContext), subject: .create(peer: peer?._asPeer(), contactData: contactData, isSharing: peer != nil, shareViaException: false, completion: { _, _, _ in
```

Replace with:

```swift
                controller?.present(context.sharedContext.makeDeviceContactInfoController(context: ShareControllerAppAccountContext(context: context), environment: ShareControllerAppEnvironment(sharedContext: context.sharedContext), subject: .create(peer: peer, contactData: contactData, isSharing: peer != nil, shareViaException: false, completion: { _, _, _ in
```

All 3 sites have `peer` source already typed as `EnginePeer?` per inventory.

---

## Task 6: ChatControllerOpenAttachmentMenu.swift — Pattern E ADD wraps (1 Edit, 2 sites via replace_all=true)

**File:** `submodules/TelegramUI/Sources/ChatControllerOpenAttachmentMenu.swift`

- [ ] **Step 1: Add `.flatMap(EnginePeer.init)` wrap at lines 683 and 1850**

Use Edit with `replace_all=true`. Find:

```swift
subject: .filter(peer: peerAndContactData.0, contactId: nil, contactData: contactData, completion: { peer, contactData in
```

Replace with:

```swift
subject: .filter(peer: peerAndContactData.0.flatMap(EnginePeer.init), contactId: nil, contactData: contactData, completion: { peer, contactData in
```

`replace_all=true` is required — both sites at L683 and L1850 share identical text. The upstream signal type is `(Peer?, DeviceContactExtendedData?)` (verified at L634 and L1822); `.flatMap(EnginePeer.init)` wraps `Peer?` to `EnginePeer?` to satisfy the migrated `.filter(peer: EnginePeer?, ...)` signature.

---

## Task 7: StoryItemSetContainerViewSendMessage.swift — Pattern A `_asPeer` drop (1 edit)

**File:** `submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerViewSendMessage.swift`

- [ ] **Step 1: Drop `_asPeer()` at line 2132**

Find:

```swift
                                        let contactController = component.context.sharedContext.makeDeviceContactInfoController(context: ShareControllerAppAccountContext(context: component.context), environment: ShareControllerAppEnvironment(sharedContext: component.context.sharedContext), subject: .filter(peer: peerAndContactData.0?._asPeer(), contactId: nil, contactData: contactData, completion: { [weak self, weak view] peer, contactData in
```

Replace with:

```swift
                                        let contactController = component.context.sharedContext.makeDeviceContactInfoController(context: ShareControllerAppAccountContext(context: component.context), environment: ShareControllerAppEnvironment(sharedContext: component.context.sharedContext), subject: .filter(peer: peerAndContactData.0, contactId: nil, contactData: contactData, completion: { [weak self, weak view] peer, contactData in
```

`peerAndContactData.0` is `EnginePeer?` from the typed signal at this site (the presence of `?._asPeer()` confirms it).

---

## Task 8: OpenChatMessage.swift — Pattern A `_asPeer` drop (1 edit)

**File:** `submodules/TelegramUI/Sources/OpenChatMessage.swift`

- [ ] **Step 1: Drop `_asPeer()` at line 443**

Find:

```swift
                        let controller = deviceContactInfoController(context: ShareControllerAppAccountContext(context: params.context), environment: ShareControllerAppEnvironment(sharedContext: params.context.sharedContext), updatedPresentationData: params.updatedPresentationData, subject: .vcard(peer?._asPeer(), nil, contactData), completed: nil, cancelled: nil)
```

Replace with:

```swift
                        let controller = deviceContactInfoController(context: ShareControllerAppAccountContext(context: params.context), environment: ShareControllerAppEnvironment(sharedContext: params.context.sharedContext), updatedPresentationData: params.updatedPresentationData, subject: .vcard(peer, nil, contactData), completed: nil, cancelled: nil)
```

`peer` source is already `EnginePeer?` (the `?._asPeer()` confirms the source type).

---

## Task 9: Full-project Bazel build

**Files:** none (verification only).

- [ ] **Step 1: Run the build with `--continueOnError`**

```sh
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent \
 --buildNumber=1 --configuration=debug_sim_arm64 --continueOnError
```

`--continueOnError` enabled — multi-module wave; surface all errors at once if iter-1 fails.

Expected: clean build. AccountContext is foundational; expect 60-180s build cost.

- [ ] **Step 2: If build fails, triage iteration**

Common failure modes (per wave-91 precedent):
- **Type mismatch on a destructured `peer`** — a destructure body may use `peer.X` where `X` is a Peer-protocol-only method not on EnginePeer. Pre-flight inventory found ZERO such sites, but verify the failing line.
- **`.id` access on EnginePeer? doesn't compile** — would indicate an EnginePeer.Id typealias regression (very unlikely; would have failed all prior waves).
- **`case let .user(peer) = peer` doesn't compile** — verify the outer `peer` is `EnginePeer?` (after migration) and not still `Peer?`.
- **A construction site missed an `_asPeer()` drop** — re-grep `_asPeer\(\)` over the 5 touched files.
- **Hidden `Peer?`-typed completion call site** — would indicate an unmigrated callback consumer. Re-grep across consumer module sources.

If errors land outside the 5 touched files: STOP and report BLOCKED — the wave is supposed to be self-contained.

Iteration budget: 3.

---

## Task 10: Post-edit residue grep

**Files:** none (verification only).

- [ ] **Step 1: Construction-site `_asPeer` residue (expected empty)**

```sh
grep -nE "subject:\s*\.(vcard|filter|create)\(.*_asPeer\(\)" \
  submodules/PeerInfoUI/Sources/DeviceContactInfoController.swift \
  submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerViewSendMessage.swift \
  submodules/TelegramUI/Sources/OpenChatMessage.swift
```

- [ ] **Step 2: Completion `_asPeer` residue (expected empty)**

```sh
grep -nE "completion\(.*_asPeer\(\)" submodules/PeerInfoUI/Sources/DeviceContactInfoController.swift
```

- [ ] **Step 3: `.flatMap(EnginePeer.init)` simplification residue (expected empty)**

```sh
grep -nE "peer\.flatMap\(EnginePeer\.init\)" submodules/PeerInfoUI/Sources/DeviceContactInfoController.swift
```

- [ ] **Step 4: Downcast residue (expected empty)**

```sh
grep -nE "peer as\? TelegramUser" submodules/PeerInfoUI/Sources/DeviceContactInfoController.swift
```

- [ ] **Step 5: ADD wraps applied (expected 2 lines)**

```sh
grep -nE "peerAndContactData\.0\.flatMap\(EnginePeer\.init\)" submodules/TelegramUI/Sources/ChatControllerOpenAttachmentMenu.swift
```

Expected: 2 lines (originally L683 and L1850, line numbers may have shifted slightly).

---

## Task 11: Commit the wave

**Files:** none (git only).

- [ ] **Step 1: Stage the 5 modified files**

```sh
git add \
  submodules/AccountContext/Sources/AccountContext.swift \
  submodules/PeerInfoUI/Sources/DeviceContactInfoController.swift \
  submodules/TelegramUI/Sources/ChatControllerOpenAttachmentMenu.swift \
  submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerViewSendMessage.swift \
  submodules/TelegramUI/Sources/OpenChatMessage.swift
```

- [ ] **Step 2: Confirm staging**

```sh
git status --short | grep -v "^??"
```

Expected: 5 staged files (lines starting with `M `). The pre-existing `m build-system/bazel-rules/sourcekit-bazel-bsp` WIP marker should NOT appear in staged.

- [ ] **Step 3: Commit**

```sh
git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 105

Migrate DeviceContactInfoSubject enum 3 case Peer? payloads + 2 callback
(Peer?, ...) -> Void signatures + 1 computed peer: Peer? property to
EnginePeer?. Wave-91-pattern multi-module enum-payload migration.

Drops 10 wraps:
- 5 _asPeer() at construction sites: DeviceContactInfoController:1289,
  1443, 1489 + StoryItemSetContainerViewSendMessage:2132 +
  OpenChatMessage:443.
- 2 _asPeer() at completion-call sites:
  DeviceContactInfoController:1105, 1224.
- 3 .flatMap(EnginePeer.init) simplifications at
  DeviceContactInfoController:942, 944, 946.

Adds 2 ADD bridges: ChatControllerOpenAttachmentMenu:683, 1850 — both
construct .filter(peer:) from peerAndContactData.0 typed (Peer?, ...);
.flatMap(EnginePeer.init) wraps to EnginePeer?. Net wrap delta: -8.

Plus 1 downcast rewrite: DeviceContactInfoController:849 — `if let peer
= peer as? TelegramUser` to `if case let .user(peer) = peer`.

5 files / 17 edits.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: Verify commit**

```sh
git log --oneline -1
```

---

## Task 12: Update outcome log + memory

**Files:**
- Modify: `docs/superpowers/postbox-refactor-log.md`
- Modify: `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`
- Modify: `~/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/MEMORY.md`

- [ ] **Step 1: Append wave 105 outcome to refactor log**

Include:
- Commit hash (from Task 11 step 4).
- Iteration count (1 if first-pass-clean; 2-3 if Task 9 step 2 fired).
- Bazel build duration.
- Net-delta accounting: −10 wrap drops, +2 ADD wraps, +1 downcast rewrite. Net −8 wraps.
- Wave-shape note: wave-91-pattern multi-module enum-payload migration with full pre-flight inventory clearing layers 1-4 of the wave-71-shadow checklist. Documents the value of thorough pre-flight inventory: 17 mechanical edits with 0 surprises.

- [ ] **Step 2: Update next-wave memory**

Edit `project_postbox_refactor_next_wave.md`:
- Add wave 105 outcome line into the recent-waves section.
- Mark `DeviceContactInfoSubject` candidate as drained (currently bullet 9 in deferred list).
- Promote next candidate.

- [ ] **Step 3: Update MEMORY.md index**

Update the `[Postbox refactor next wave]` line.

- [ ] **Step 4: Commit the doc update**

```sh
git add docs/superpowers/postbox-refactor-log.md
git commit -m "$(cat <<'EOF'
docs: log wave 105 outcome

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

(Memory file updates not committed — they live outside the repo.)

---

## Net delta projection

| Category | Count | Sites |
|---|---|---|
| `_asPeer()` drops at construction | −5 | DCIC:1289, 1443, 1489 + SISCVSM:2132 + OCM:443 |
| `_asPeer()` drops at completion calls | −2 | DCIC:1105, 1224 |
| `.flatMap(EnginePeer.init)` simplifications | −3 | DCIC:942, 944, 946 |
| `.flatMap(EnginePeer.init)` ADD wraps | +2 | CCOAM:683, 1850 |
| Downcast → case-let | +1 | DCIC:849 |
| Type annotations migrated | 4 | AccountContext: 3 enum cases + 1 computed property |

**Total commit footprint:** 17 line edits across 5 files, plus a docs commit for the outcome log.

**Net wrap delta:** **−8** (the wave's headline metric).
