# Postbox → TelegramEngine refactor, wave 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Drop the direct `import Postbox` dependency from the first 10 leaf consumer submodules (one file each), routing data access through `TelegramEngine` while preserving behavior exactly.

**Architecture:** For each of the 10 modules, apply the same deterministic playbook: inventory every Postbox reference in its single Postbox-importing file, swap bare Postbox type names for their engine typealiases (`PeerId` → `EnginePeer.Id`, etc.), replace imperative Postbox calls with existing engine methods or new thin engine wrappers added to TelegramCore in a preparatory commit, remove `import Postbox` and the Bazel dep, and run the full project build to verify.

**Tech Stack:** Swift, Bazel (primary build system), Postbox (storage lib being made opaque), TelegramCore + TelegramEngine (the public facade), SSignalKit (signals).

**Spec:** [docs/superpowers/specs/2026-04-16-postbox-to-telegramengine-refactor-wave-1-design.md](../specs/2026-04-16-postbox-to-telegramengine-refactor-wave-1-design.md)

---

## Background the executor needs

There are no unit tests in this project (`CLAUDE.md`: "No tests are used at the moment"). **The only verification is the full project build.** Every task ends with a full build that must go green before the next task starts.

### The full build command

Run from the repo root (`/Users/ali/build/telegram/telegram-ios`):

```bash
source ~/.zshrc 2>/dev/null; \
PATH=/opt/homebrew/opt/ruby/bin:`gem environment gemdir`/bin:$PATH \
  python3 build-system/Make/Make.py --overrideXcodeVersion \
  --cacheDir ~/telegram-bazel-cache \
  build \
  --configurationPath build-system/appstore-configuration.json \
  --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
  --gitCodesigningType development \
  --gitCodesigningUseCurrent \
  --buildNumber 1 \
  --configuration debug_sim_arm64
```

(`source ~/.zshrc` picks up `TELEGRAM_CODESIGNING_GIT_PASSWORD` and other env exports that the Claude Code bash shell doesn't inherit by default.)

It is slow. Do not shortcut it with `bazel build //submodules/X` — the spec chose full build per module.

### Engine typealias cheat sheet (already in TelegramCore)

When removing `import Postbox`, bare Postbox names in the file must be swapped for their engine equivalents. The ones that exist as typealiases today (confirmed by grep over `submodules/TelegramCore/Sources/TelegramEngine/`):

- `PeerId` → `EnginePeer.Id`
- `MessageId` → `EngineMessage.Id`
- `MessageIndex` → `EngineMessage.Index`
- `MessageTags` → `EngineMessage.Tags`
- `MessageAttribute` → `EngineMessage.Attribute`
- `MessageFlags` → `EngineMessage.Flags`
- `MessageForwardInfo` → `EngineMessage.ForwardInfo`
- `MediaId` → `EngineMedia.Id`
- `PreferencesEntry` → `EnginePreferencesEntry`
- `TempBox` (the singleton helper) → `EngineTempBox`
- `PinnedItemId` → `EngineChatList.PinnedItem.Id`

If a task needs a Postbox type that has **no** existing engine typealias, the task may add one in `TelegramCore` (trivial `public typealias EngineX = X`) in the preparatory commit — this is explicitly allowed by the spec.

### Engine wrapper locations (per the spec)

- Data reads / subscriptions → new `TelegramEngine.EngineData.Item.<Area>.<Name>` in `submodules/TelegramCore/Sources/TelegramEngine/Data/<Area>Data.swift`.
- Imperative signal-returning calls → new method on `Peers` / `Messages` / `Resources` / `AccountData` under `submodules/TelegramCore/Sources/TelegramEngine/<Area>/`.
- Media-resource access → extend `engine.resources` (e.g. `engine.resources.data(...)`, `engine.resources.status(...)`), forwarding to `account.postbox.mediaBox.*` internally.
- Consumer-run `account.postbox.transaction { ... }` → a specific purpose-built engine method. No generic transaction escape hatch.

### Static-check commands (run before the build in every task)

```bash
grep -R "^import Postbox" submodules/<M>/Sources         # must return empty
grep "submodules/Postbox" submodules/<M>/BUILD            # must return empty
```

### Commit convention

Per module, up to two commits (optional first, required second):

1. `TelegramCore: add <wrapper name>` — only if new engine wrappers were needed.
2. `<ModuleName>: drop direct Postbox dependency` — consumer edits + BUILD change.

Always use a HEREDOC commit body. No `--amend`. Every commit must build.

**TelegramCore wrapper commit template** (used by any task's Step 2a when engine wrappers/typealiases are added):

```bash
git add submodules/TelegramCore/...
git commit -m "$(cat <<'EOF'
TelegramCore: add <wrapper name(s)>

Prepares for <ModuleName> to drop Postbox.
Searched TelegramEngine/ for existing equivalents: <found list, or "not found">.
<one-line summary of what each wrapper exposes>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

### Build-failure handling (applies to every task's Step 6)

When the full build fails after a consumer edit:

- Read the **first** compiler error in the build output.
- If it's a name-resolution or type error in the module file being refactored, fix the mapping in that file and rebuild.
- If it's in a **different** module that depends on the module being refactored, a public signature changed unexpectedly. Either (a) revert that signature change so the public surface stays identical, or (b) if the new surface is genuinely better, extend the fix to the downstream call site **in the same commit**.
- If fixing would require editing a module outside the wave-1 list — or would require aliasing an umbrella type banned by spec rule 2 (`Postbox`, `Account`, `MediaBox`) — revert all changes from the current task and mark the module **Abandoned** in its task body with a one-line reason. Do NOT substitute a different module; the wave's done-count simply goes down by one.

### The 10 modules (from the spec's deterministic selection rule)

Reverse-dep count (over the 30-candidate pool) ascending, alphabetical tiebreak. Verified by running the selection script in Task 0:

1. ActionSheetPeerItem — **ABANDONED** (see Task 1 body). Public init takes `postbox: Postbox`; ShareController caller is out-of-wave.
2. ChatInterfaceState — `submodules/ChatInterfaceState/Sources/ChatInterfaceState.swift` — DONE
3. ChatListSearchRecentPeersNode — **ABANDONED** (see Task 3 body). Public init takes `postbox: Postbox`; ShareController + ChatListUI callers are out-of-wave.
4. ChatSendMessageActionUI — `submodules/ChatSendMessageActionUI/Sources/ChatSendMessageContextScreen.swift`
5. ContactListUI — `submodules/ContactListUI/Sources/ContactListNode.swift`
6. DirectMediaImageCache — **ABANDONED** (see Task 6 body). Public init takes `account: Account`; six out-of-wave callers.
7. DrawingUI — `submodules/DrawingUI/Sources/DrawingScreen.swift`
8. FetchManagerImpl — **ABANDONED** (see Task 8 body). Public init takes `postbox: Postbox`; TelegramUI caller is out-of-wave.
9. GalleryData — **ABANDONED** (see Task 9 body). Four public functions take `Media`/`Message` as parameters; refactor cascades into many out-of-wave downstream types (`AvatarGalleryEntry`, `MessageReference`, etc.). Good candidate for a bespoke future wave that migrates the domain types together.
10. ICloudResources — **ABANDONED** (see Task 10 body). Class conforms to `TelegramMediaResource` and inherits `isEqual(to: MediaResource)`; overriding that without aliasing the `MediaResource` protocol isn't possible.

**Wave-1 done-count: 4** (Tasks 2, 4, 5, 7 done; Tasks 1, 3, 6, 8, 9, 10 abandoned).

Per the spec's **abandonment protocol**, if a module hits an unresolvable blocker (requires aliasing an umbrella type such as `Postbox`/`Account`/`MediaBox`, or requires editing a module outside the wave-1 list), it is marked Abandoned in its task body and **not substituted**. The wave's done-count goes down by one; fallback modules are not pulled into the wave mid-execution. A later wave can revisit the abandoned module with tools not available in wave 1 (e.g. a real engine wrapper rather than a typealias, or a refactor that migrates the caller first).

---

## Task 0: Verify selection and baseline build

**Files:**
- Read: `submodules/<each module>/BUILD`

- [ ] **Step 1: Re-run the selection script to confirm the 10**

Save and run this Python snippet from the repo root. It should output exactly the 10 modules listed above, in that order.

```bash
python3 <<'EOF'
import os, re
pool = ["ActionSheetPeerItem","ChatInterfaceState","ChatListSearchRecentPeersNode","ChatSendMessageActionUI","ContactListUI","DirectMediaImageCache","DrawingUI","FetchManagerImpl","GalleryData","HorizontalPeerItem","ICloudResources","InAppPurchaseManager","InstantPageCache","InviteLinksUI","ItemListAvatarAndNameInfoItem","ItemListPeerItem","ItemListStickerPackItem","MapResourceToAvatarSizes","PhotoResources","PlatformRestrictionMatching","PresentationDataUtils","PromptUI","SaveToCameraRoll","SelectablePeerNode","ShareItems","SoftwareVideo","StickerPeekUI","StickerResources","TelegramIntents","TelegramNotices"]
deps = {}
for m in pool:
    p = f"submodules/{m}/BUILD"
    txt = open(p).read() if os.path.exists(p) else ""
    deps[m] = {o for o in pool if o != m and re.search(rf'//submodules/{re.escape(o)}(:|"|$)', txt)}
rdep = {m:0 for m in pool}
for m,ds in deps.items():
    for d in ds: rdep[d]+=1
for m in sorted(pool, key=lambda m:(rdep[m],m))[:10]:
    print(m, rdep[m])
EOF
```

Expected output (one per line): `ActionSheetPeerItem 0`, `ChatInterfaceState 0`, `ChatListSearchRecentPeersNode 0`, `ChatSendMessageActionUI 0`, `ContactListUI 0`, `DirectMediaImageCache 0`, `DrawingUI 0`, `FetchManagerImpl 0`, `GalleryData 0`, `ICloudResources 0`.

If the output differs, stop and investigate — someone changed a BUILD file since the spec was written.

- [ ] **Step 2: Run the baseline full build**

Run the full build command above. Expected: PASS (green master). If it fails, stop — we need a green baseline before changing anything. Do not attempt to fix pre-existing build breakage as part of this plan.

- [ ] **Step 3: No commit**

Task 0 produces no code changes.

---

## Task 1: Refactor `ActionSheetPeerItem` — **ABANDONED**

**Status:** Abandoned for wave 1. No code changes in this repo from this task.

**Reason:** Refactoring this module requires either (a) typealiasing the `Postbox` class itself (banned — see spec §Guiding rules rule 2: umbrella-type typealiases rename without encapsulating) or (b) editing `submodules/ShareController/` which is not in the wave-1 list. The module's designated init takes `postbox: Postbox` as a parameter and its sole out-of-wave caller (ShareController) passes `info.account.stateManager.postbox` directly, so there is no path to drop the `import Postbox` here without crossing the wave boundary or violating rule 2. Per the spec's **abandonment protocol**, the module is skipped for this wave. Wave-1 done-count is therefore 9, not 10.

**Original task body (retained for audit trail, do not implement):**

**Files:**
- Modify: `submodules/ActionSheetPeerItem/Sources/ActionSheetPeerItem.swift`
- Modify: `submodules/ActionSheetPeerItem/BUILD`

**Starting inventory** (computed during planning):

Grep for common Postbox API/type names in `ActionSheetPeerItem.swift` returned zero hits on `mediaBox`, `transaction`, `PostboxView`, `combinedView`, `PeerId`, `MessageId`, `MediaResource`, `CachedPeerData`, etc. The `import Postbox` line appears unused. Confirm this during inventory — it's the most likely case, but other Postbox symbols (e.g. types referenced inside a parameter type) may still be present. (Subsequent inventory discovered the module does take `postbox: Postbox` as a parameter type — this is what makes the module unrefactorable under the wave-1 rules.)

- [ ] **Step 1: Inventory**

Read `submodules/ActionSheetPeerItem/Sources/ActionSheetPeerItem.swift` top to bottom. Record every identifier that is Postbox-owned. If the inventory is empty, skip straight to Step 4.

Run this helper grep too:

```bash
grep -nE "\b(PeerId|MessageId|MessageIndex|MessageTags|MessageAttribute|MessageFlags|Peer|Media|MediaId|MediaResource|PostboxView|CachedPeerData|PreferencesEntry|ChatListIndex|PeerReference|TelegramMediaFile|TelegramMediaImage|Namespaces|TempBox)\b" submodules/ActionSheetPeerItem/Sources/ActionSheetPeerItem.swift
```

- [ ] **Step 2: Map each reference to a replacement**

For each finding from Step 1, decide: existing engine typealias (see cheat sheet), existing engine method, existing TelegramCore non-Postbox export, or new engine wrapper. Record the mapping in your working notes. If a new wrapper is needed, it is added in Task 1a before Task 1 continues.

- [ ] **Step 2a: (Only if Step 2 identified a missing engine wrapper/typealias) Add to TelegramCore**

Edit the relevant file under `submodules/TelegramCore/Sources/TelegramEngine/<Area>/` or `submodules/TelegramCore/Sources/TelegramEngine/Data/<Area>Data.swift`, following the wrapper-location rules in the Background section. Keep the wrapper minimal: a single typealias for name-only adds, or a thin method that forwards to the underlying Postbox call for imperative ones.

Run the full build. It must pass. Commit:

```bash
git add submodules/TelegramCore/...
git commit -m "$(cat <<'EOF'
TelegramCore: add <wrapper name>

Prepares for ActionSheetPeerItem to drop Postbox.
<one-line summary of what the wrapper exposes>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

Skip this step if Step 2 didn't identify any missing wrappers.

- [ ] **Step 3: Edit the consumer file**

In `submodules/ActionSheetPeerItem/Sources/ActionSheetPeerItem.swift`:

- Apply every mapping from Step 2.
- Remove the line `import Postbox`.

- [ ] **Step 4: Drop the Bazel dep**

Edit `submodules/ActionSheetPeerItem/BUILD`. Remove the line `"//submodules/Postbox:Postbox",` from the `deps` array. Leave the rest of the BUILD untouched.

- [ ] **Step 5: Static checks**

Run:

```bash
grep -R "^import Postbox" submodules/ActionSheetPeerItem/Sources   # expect: empty
grep "submodules/Postbox" submodules/ActionSheetPeerItem/BUILD      # expect: empty
```

Both must return no output. If either produces a hit, go back to Step 3 or Step 4.

- [ ] **Step 6: Full project build**

Run the full build command from the Background section. Expected: PASS.

If it fails:
- Read the first error. If it's a name-resolution error in `ActionSheetPeerItem.swift`, fix the mapping and rebuild.
- If it's in a *different* module that depends on `ActionSheetPeerItem`, you changed a public signature unexpectedly; either revert that signature change or, if it's genuinely better, extend the fix to that downstream call site in the same commit.
- If the fix would require editing a module outside the wave-1 list, revert all Task 1 changes and skip to the next fallback module listed in the Background section.

- [ ] **Step 7: Commit**

```bash
git add submodules/ActionSheetPeerItem/
git commit -m "$(cat <<'EOF'
ActionSheetPeerItem: drop direct Postbox dependency

Route data access through TelegramEngine/TelegramCore; remove the
Postbox import and Bazel dep. Behavior-preserving.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Refactor `ChatInterfaceState`

**Files:**
- Modify: `submodules/ChatInterfaceState/Sources/ChatInterfaceState.swift`
- Modify: `submodules/ChatInterfaceState/BUILD`

**Starting inventory** (computed during planning): file references `MessageId` (×2) and `MediaResource` (×3). No `mediaBox`, `transaction`, `combinedView`, or `PostboxView` usage. This is a **type-reference-only** case — expected replacements are `MessageId` → `EngineMessage.Id` and `MediaResource` stays as-is only if a typealias exists, otherwise a typealias `EngineMediaResource = MediaResource` is added in TelegramCore.

- [ ] **Step 1: Inventory**

Read `submodules/ChatInterfaceState/Sources/ChatInterfaceState.swift`. Confirm the grep below matches the planning inventory and records exact line numbers and declaration contexts (parameter types, property types, return types, generic arguments).

```bash
grep -nE "\b(PeerId|MessageId|MessageIndex|MessageTags|MessageAttribute|MessageFlags|Peer|Media|MediaId|MediaResource|PostboxView|CachedPeerData|PreferencesEntry|ChatListIndex|PeerReference|TelegramMediaFile|TelegramMediaImage|Namespaces|TempBox)\b" submodules/ChatInterfaceState/Sources/ChatInterfaceState.swift
```

- [ ] **Step 2: Map each reference**

- `MessageId` → `EngineMessage.Id` (existing typealias, no wrapper needed).
- `MediaResource`: search `submodules/TelegramCore/Sources/TelegramEngine/` for a `public typealias Engine.*Resource.*= MediaResource`. If present, use it. If absent, proceed to Step 2a and add a typealias `public typealias EngineMediaResource = MediaResource` in `submodules/TelegramCore/Sources/TelegramEngine/Resources/` (new file `EngineMediaResource.swift`, or the most natural existing file in that folder).

- [ ] **Step 2a: (Only if needed) Add engine typealias(es) in TelegramCore**

For each Postbox type without an engine typealias, add a `public typealias Engine<Name> = <PostboxName>` in the appropriate TelegramEngine area file. Do not introduce any new wrapper structs.

Run full build, expect PASS. Commit:

```bash
git add submodules/TelegramCore/...
git commit -m "$(cat <<'EOF'
TelegramCore: add engine typealiases for <list>

Prepares for ChatInterfaceState to drop Postbox.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 3: Edit the consumer file**

Apply the mappings from Step 2 to every reference. Remove the line `import Postbox`.

- [ ] **Step 4: Drop the Bazel dep**

Edit `submodules/ChatInterfaceState/BUILD`. Remove `"//submodules/Postbox:Postbox",` from `deps`.

- [ ] **Step 5: Static checks**

```bash
grep -R "^import Postbox" submodules/ChatInterfaceState/Sources   # expect: empty
grep "submodules/Postbox" submodules/ChatInterfaceState/BUILD      # expect: empty
```

- [ ] **Step 6: Full project build**

Run the full build command. Expected: PASS. Handle failures per the rules in Task 1 Step 6.

- [ ] **Step 7: Commit**

```bash
git add submodules/ChatInterfaceState/
git commit -m "$(cat <<'EOF'
ChatInterfaceState: drop direct Postbox dependency

Switch remaining Postbox-typed references to engine typealiases;
remove the Postbox import and Bazel dep. Behavior-preserving.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Refactor `ChatListSearchRecentPeersNode` — **ABANDONED**

**Status:** Abandoned for wave 1. No code changes in this repo from this task.

**Reason:** The module's public `init` at line 207 takes `postbox: Postbox` as a parameter. Two out-of-wave callers (`submodules/ShareController/Sources/ShareControllerRecentPeersGridItem.swift`, `submodules/ChatListUI/Sources/ChatListRecentPeersListItem.swift`) use this init. Refactoring requires either typealiasing the `Postbox` class (banned by spec rule 2) or editing those two out-of-wave modules (banned by wave boundary). Per the abandonment protocol, the module is skipped.

**Original task body (retained for audit trail, do not implement):**

**Files:**
- Modify: `submodules/ChatListSearchRecentPeersNode/Sources/ChatListSearchRecentPeersNode.swift`
- Modify: `submodules/ChatListSearchRecentPeersNode/BUILD`

**Starting inventory** (computed during planning): file uses `postbox.transaction { ... }` (×2), `postbox.combinedView(...)` (×1), and references `TelegramMedia*` types (×3). This is the **first hard module** in the wave — it has real imperative Postbox calls that require engine wrappers, not just typealiases.

- [ ] **Step 1: Inventory**

Read the whole file. For each Postbox call, capture:
- The call site (line number, containing function).
- The `PostboxViewKey`(s) passed to `combinedView`.
- What the closure body of each `transaction` does — the *intent*, not just the code. (This determines which engine method to add.)

Run:

```bash
grep -nE "\b(postbox\.|mediaBox|transaction\s*\{|combinedView|PostboxView|PostboxViewKey|Namespaces\.|TelegramMedia|PeerId|MessageId)\b" submodules/ChatListSearchRecentPeersNode/Sources/ChatListSearchRecentPeersNode.swift
```

- [ ] **Step 2: Map each reference**

- `TelegramMedia*` — these classes are defined in `TelegramCore` (check `submodules/TelegramCore/Sources/`), not Postbox. After `import Postbox` is removed they remain reachable via `import TelegramCore`, which the file already imports. No action beyond confirming.
- Each `postbox.combinedView` / view subscription → map to an existing `TelegramEngine.data.subscribe(...)` item if one exists for the same `PostboxViewKey`; if not, add an `EngineData.Item` under `submodules/TelegramCore/Sources/TelegramEngine/Data/<Area>Data.swift`.
- Each `postbox.transaction { ... }` → a specific new method on the matching engine area (e.g. `TelegramEngine.Peers.recordRecentPeer(id:)` if that's what the closure does). Do **not** add a generic transaction passthrough.

Write the mapping down before editing. Each new engine method is small and focused.

- [ ] **Step 2a: Add engine wrappers in TelegramCore**

For each new `EngineData.Item` or engine method identified in Step 2:

- Add it to the appropriate file under `submodules/TelegramCore/Sources/TelegramEngine/<Area>/` (or `…/Data/<Area>Data.swift` for data items).
- Keep the body to a minimal pass-through: the new engine method opens a transaction internally and calls the same Postbox code that the consumer was running; the new `EngineData.Item` forwards a `PostboxViewKey` in `keys()` and extracts its `PostboxView` in `extract()`.
- Return engine-typed values where existing engine types are available; otherwise return primitives or `Void`. Do not return bare Postbox types.

Before editing TelegramCore, grep for existing wrappers covering the same need:

```bash
grep -rn "<plausible method name>\|<PostboxViewKey case>" submodules/TelegramCore/Sources/TelegramEngine/
```

Record "searched for X, found/not found" in the commit message.

Run the full build. Expected: PASS.

Commit:

```bash
git add submodules/TelegramCore/...
git commit -m "$(cat <<'EOF'
TelegramCore: add <wrapper name(s)>

Prepares for ChatListSearchRecentPeersNode to drop Postbox.
Searched TelegramEngine/ for existing equivalents: not found.
<one-line summary of what each wrapper exposes>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 3: Edit the consumer file**

Replace each `postbox.transaction` and `postbox.combinedView` call with the engine method/subscription added in Step 2a. Swap any Postbox-typed names for engine typealiases per the cheat sheet. Remove `import Postbox`.

- [ ] **Step 4: Drop the Bazel dep**

Edit `submodules/ChatListSearchRecentPeersNode/BUILD`. Remove `"//submodules/Postbox:Postbox",` from `deps`.

- [ ] **Step 5: Static checks**

```bash
grep -R "^import Postbox" submodules/ChatListSearchRecentPeersNode/Sources   # expect: empty
grep "submodules/Postbox" submodules/ChatListSearchRecentPeersNode/BUILD      # expect: empty
```

- [ ] **Step 6: Full project build**

Run the full build command. Expected: PASS. Handle failures per the Build-failure handling rules in the Background section.

- [ ] **Step 7: Commit**

```bash
git add submodules/ChatListSearchRecentPeersNode/
git commit -m "$(cat <<'EOF'
ChatListSearchRecentPeersNode: drop direct Postbox dependency

Route combined-view subscription and transactions through
TelegramEngine; remove the Postbox import and Bazel dep.
Behavior-preserving.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Refactor `ChatSendMessageActionUI`

**Files:**
- Modify: `submodules/ChatSendMessageActionUI/Sources/ChatSendMessageContextScreen.swift`
- Modify: `submodules/ChatSendMessageActionUI/BUILD`

**Starting inventory** (computed during planning): `mediaBox` (×2), `Peer` type reference (×1), `Media` type reference (×1), `MediaResource` (×1), `Namespaces.` (×1). The mediaBox calls are the substantive work.

- [ ] **Step 1: Inventory**

Read the whole file. Capture every `mediaBox` call — what resource is being asked for and what is done with the result (data read, status subscription, fetch start, path access)? Capture each Postbox-typed reference's line/context.

```bash
grep -nE "\bmediaBox\b|\bNamespaces\.|\b(Peer|Media|MediaResource)\b" submodules/ChatSendMessageActionUI/Sources/ChatSendMessageContextScreen.swift
```

- [ ] **Step 2: Map each reference**

- Each `mediaBox.<op>` call → `engine.resources.<equivalent>(...)`. Check for an existing method on `TelegramEngine.Resources` first:
  ```bash
  grep -rn "extension.*Resources\|public func" submodules/TelegramCore/Sources/TelegramEngine/Resources/
  ```
  If an equivalent exists, use it. If not, add one in Step 2a.
- `Peer`, `Media`, `MediaResource` type references → use `EnginePeer`, `EngineMedia`, or `EngineMediaResource` (add typealias if missing, per the cheat sheet).
- `Namespaces.Peer.<case>` — defined in TelegramCore, not Postbox. Confirm via grep; no change needed.

- [ ] **Step 2a: (Only if needed) Add engine wrappers in TelegramCore**

Per the rules — minimal pass-through, return engine-typed values. Build, commit `TelegramCore: add <name>` per the template in Task 3 Step 2a.

- [ ] **Step 3: Edit the consumer file**

Apply mappings. Remove `import Postbox`.

- [ ] **Step 4: Drop the Bazel dep**

Edit `submodules/ChatSendMessageActionUI/BUILD`. Remove `"//submodules/Postbox:Postbox",` from `deps`.

- [ ] **Step 5: Static checks**

```bash
grep -R "^import Postbox" submodules/ChatSendMessageActionUI/Sources   # expect: empty
grep "submodules/Postbox" submodules/ChatSendMessageActionUI/BUILD      # expect: empty
```

- [ ] **Step 6: Full project build**

Run the full build. Expected: PASS. Handle failures per the Build-failure handling rules in the Background section.

- [ ] **Step 7: Commit**

```bash
git add submodules/ChatSendMessageActionUI/
git commit -m "$(cat <<'EOF'
ChatSendMessageActionUI: drop direct Postbox dependency

Route MediaBox calls through TelegramEngine.resources and switch
type references to engine typealiases; remove the Postbox import
and Bazel dep. Behavior-preserving.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Refactor `ContactListUI`

**Files:**
- Modify: `submodules/ContactListUI/Sources/ContactListNode.swift`
- Modify: `submodules/ContactListUI/BUILD`

**Starting inventory** (computed during planning): `postbox.transaction { ... }` (×4), `Peer` references (×15), `Namespaces.` (×1). Transactions are the substantive work; the 15 `Peer` references are likely in closures reading transaction state and will switch to engine-typed returns once the transactions are replaced.

- [ ] **Step 1: Inventory**

Read the whole file. For each `transaction` call, describe what the closure does — this drives what new engine methods to add. Capture every `Peer`-typed declaration.

```bash
grep -nE "\btransaction\s*\{|account\.postbox|\b(Peer|PeerId|Namespaces)\b" submodules/ContactListUI/Sources/ContactListNode.swift
```

- [ ] **Step 2: Map each reference**

- Each `postbox.transaction { ... }` → a dedicated engine method under `submodules/TelegramCore/Sources/TelegramEngine/{Peers,Contacts,AccountData}/` capturing the closure's intent. Never add a generic transaction passthrough.
- `Peer` type → `EnginePeer` where the value actually flows through the replaced engine method (the engine method should return `EnginePeer` / `[EnginePeer]`). For local variable types that receive the engine-method return, use the engine type.
- `Namespaces.*` — defined in TelegramCore. No change.

Before adding methods, grep for existing engine functions that may already cover the intent:

```bash
grep -rn "public func" submodules/TelegramCore/Sources/TelegramEngine/Contacts/
grep -rn "public func" submodules/TelegramCore/Sources/TelegramEngine/Peers/ | head -60
```

- [ ] **Step 2a: Add engine wrappers in TelegramCore**

Add each new method. Return engine-typed values. Build; then use the TelegramCore wrapper commit template from the Background section.

- [ ] **Step 3: Edit the consumer file**

Replace every `transaction` call with its engine method. Switch `Peer` locals to `EnginePeer`. Remove `import Postbox`.

- [ ] **Step 4: Drop the Bazel dep**

Edit `submodules/ContactListUI/BUILD`. Remove `"//submodules/Postbox:Postbox",` from `deps`.

- [ ] **Step 5: Static checks**

```bash
grep -R "^import Postbox" submodules/ContactListUI/Sources   # expect: empty
grep "submodules/Postbox" submodules/ContactListUI/BUILD      # expect: empty
```

- [ ] **Step 6: Full project build**

Run the full build. Expected: PASS. Handle failures per the Build-failure handling rules in the Background section. ContactListUI is imported by other submodules (TelegramUI, SettingsUI, etc.); downstream breakage is most likely here. If a downstream consumer needs a bare `Peer`, either keep the public surface returning engine types (preferred — they're typealiases under the hood) or, if the downstream change is large, revert Task 5 and skip.

- [ ] **Step 7: Commit**

```bash
git add submodules/ContactListUI/
git commit -m "$(cat <<'EOF'
ContactListUI: drop direct Postbox dependency

Replace direct postbox.transaction calls with dedicated engine
methods; switch peer references to engine-typed equivalents;
remove the Postbox import and Bazel dep. Behavior-preserving.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Refactor `DirectMediaImageCache` — **ABANDONED**

**Status:** Abandoned for wave 1. No code changes in this repo from this task.

**Reason:** The module's public `init(account: Account)` at line 241 takes `account: Account` (an umbrella type banned by spec rule 2). Out-of-wave callers include `submodules/CalendarMessageScreen/`, four TelegramUI components (`StoryContainerScreen`, `ShareWithPeersScreen`, `PeerInfoVisualMediaPaneNode` × 2), and `submodules/TelegramUI/Sources/AccountContext.swift`. Refactoring requires either aliasing `Account` (banned) or editing all those out-of-wave callers (banned). Per the abandonment protocol, the module is skipped.

**Original task body (retained for audit trail, do not implement):**

**Files:**
- Modify: `submodules/DirectMediaImageCache/Sources/DirectMediaImageCache.swift`
- Modify: `submodules/DirectMediaImageCache/BUILD`

**Starting inventory** (computed during planning): `mediaBox` (×11), `PeerReference` (×6), `MediaResource` (×1), `TelegramMedia*` (×13), `Media`/`Message` type references. This module is **mediaBox-heavy** and is the canonical shape for the `engine.resources.*` extension work.

- [ ] **Step 1: Inventory**

Read the whole file. For each `mediaBox` call, record the method (`resourceData`, `resourceStatus`, `cachedResourceRepresentation`, `storeCachedResourceRepresentation`, `fetchedResource`, etc.) and whether it reads, writes, or subscribes.

```bash
grep -nE "\bmediaBox\b|\b(PeerReference|MediaResource|TelegramMedia)" submodules/DirectMediaImageCache/Sources/DirectMediaImageCache.swift
```

- [ ] **Step 2: Map each reference**

Each distinct `mediaBox.<op>` signature → a method on `TelegramEngine.Resources`. Expected additions (names are suggestions — match existing naming if anything close already exists):

- `engine.resources.data(_:pathExtension:option:attemptSynchronously:) -> Signal<MediaResourceData, NoError>`
- `engine.resources.status(_:approximateSynchronousValue:) -> Signal<MediaResourceStatus, NoError>`
- `engine.resources.cachedRepresentationData(_:representation:complete:) -> Signal<...>`
- `engine.resources.storeCachedRepresentation(_:representation:data:) -> Signal<Void, NoError>`

Before adding any of these, grep `submodules/TelegramCore/Sources/TelegramEngine/Resources/` for existing equivalents and only add what's missing.

`PeerReference`, `TelegramMedia*`, `MediaResource` — check each: `TelegramMedia*` types live in `TelegramCore` (not Postbox). `PeerReference` lives in `TelegramCore`. `MediaResource` is a Postbox protocol; add `EngineMediaResource = MediaResource` typealias if not already present.

- [ ] **Step 2a: Add engine wrappers in TelegramCore**

Add all missing methods on `Resources` and any missing typealiases. Each method is a one-line forward to `account.postbox.mediaBox.*`. Build; then commit using the TelegramCore wrapper commit template from the Background section, recording "searched Resources/ for equivalents: found/not found" in the message.

- [ ] **Step 3: Edit the consumer file**

Replace every `mediaBox.*` with `engine.resources.*`. This likely requires adding an `engine: TelegramEngine` parameter to a few internal functions in the file (or surfacing it from an existing `AccountContext` already in scope — prefer that). Switch types to engine typealiases. Remove `import Postbox`.

- [ ] **Step 4: Drop the Bazel dep**

Edit `submodules/DirectMediaImageCache/BUILD`. Remove `"//submodules/Postbox:Postbox",` from `deps`.

- [ ] **Step 5: Static checks**

```bash
grep -R "^import Postbox" submodules/DirectMediaImageCache/Sources   # expect: empty
grep "submodules/Postbox" submodules/DirectMediaImageCache/BUILD      # expect: empty
```

- [ ] **Step 6: Full project build**

Run the full build. Expected: PASS. Handle failures per the Build-failure handling rules in the Background section.

- [ ] **Step 7: Commit**

```bash
git add submodules/DirectMediaImageCache/
git commit -m "$(cat <<'EOF'
DirectMediaImageCache: drop direct Postbox dependency

Route MediaBox calls through TelegramEngine.resources; remove the
Postbox import and Bazel dep. Behavior-preserving.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Refactor `DrawingUI`

**Files:**
- Modify: `submodules/DrawingUI/Sources/DrawingScreen.swift`
- Modify: `submodules/DrawingUI/BUILD`

**Starting inventory** (computed during planning): `transaction` (×3), `Media` type references (×13), `Namespaces.` (×4). Transactions are the substantive work; `Media`/`Namespaces` are mostly referencing TelegramCore-defined types already.

- [ ] **Step 1: Inventory**

Read the whole file. For each `transaction` call, describe what the closure does. Capture every `Media`-typed declaration and every `Namespaces.*` reference.

```bash
grep -nE "\btransaction\s*\{|account\.postbox|\b(Media|MediaId|Namespaces)\b" submodules/DrawingUI/Sources/DrawingScreen.swift
```

- [ ] **Step 2: Map each reference**

- Each `postbox.transaction` → dedicated engine method. Inspect the closure to find the right home (`Stickers`, `Messages`, `Peers`, …).
- `Media` → `EngineMedia` where the value flows through new engine methods; keep as `Media` (TelegramCore re-defined concrete classes like `TelegramMediaFile` live in TelegramCore and are fine) where the type is already TelegramCore's.
- `Namespaces.*` — TelegramCore. No change.

- [ ] **Step 2a: Add engine wrappers in TelegramCore**

Add each new transaction-replacing method. Build; then use the TelegramCore wrapper commit template from the Background section.

- [ ] **Step 3: Edit the consumer file**

Apply mappings. Remove `import Postbox`.

- [ ] **Step 4: Drop the Bazel dep**

Edit `submodules/DrawingUI/BUILD`. Remove `"//submodules/Postbox:Postbox",` from `deps`.

- [ ] **Step 5: Static checks**

```bash
grep -R "^import Postbox" submodules/DrawingUI/Sources   # expect: empty
grep "submodules/Postbox" submodules/DrawingUI/BUILD      # expect: empty
```

- [ ] **Step 6: Full project build**

Run the full build. Expected: PASS. Handle failures per the Build-failure handling rules in the Background section.

- [ ] **Step 7: Commit**

```bash
git add submodules/DrawingUI/
git commit -m "$(cat <<'EOF'
DrawingUI: drop direct Postbox dependency

Replace direct postbox.transaction calls with dedicated engine
methods; switch type references to engine equivalents; remove the
Postbox import and Bazel dep. Behavior-preserving.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Refactor `FetchManagerImpl` — **ABANDONED**

**Status:** Abandoned for wave 1. No code changes in this repo from this task.

**Reason:** The module's public `init(postbox: Postbox, storeManager: DownloadedMediaStoreManager?)` at line 708 takes `postbox: Postbox`. Out-of-wave caller: `submodules/TelegramUI/Sources/AccountContext.swift:296`. Refactoring requires either aliasing the `Postbox` class (banned by spec rule 2) or editing TelegramUI (banned by wave boundary). Per the abandonment protocol, the module is skipped.

**Original task body (retained for audit trail, do not implement):**

**Files:**
- Modify: `submodules/FetchManagerImpl/Sources/FetchManagerImpl.swift`
- Modify: `submodules/FetchManagerImpl/BUILD`

**Starting inventory** (computed during planning): `mediaBox` (×8), `MediaResource` (×4), `TelegramMedia` (×1). Shape is similar to DirectMediaImageCache — heavy `mediaBox` usage, no transactions.

- [ ] **Step 1: Inventory**

Read the whole file. For each `mediaBox` call, record the method and direction (read / subscribe / fetch-start).

```bash
grep -nE "\bmediaBox\b|\b(MediaResource|TelegramMedia)\b" submodules/FetchManagerImpl/Sources/FetchManagerImpl.swift
```

- [ ] **Step 2: Map each reference**

Reuse every `engine.resources.*` method added in Task 6 — do not re-add them. Grep:

```bash
grep -rn "extension.*Resources\|public func" submodules/TelegramCore/Sources/TelegramEngine/Resources/
```

If this task needs a `mediaBox` operation that Task 6 did not add (e.g. `cancelInteractiveResourceFetch`, `completeInteractiveResourceFetch`), add it now in the same pattern.

`MediaResource` → `EngineMediaResource` typealias (already added in an earlier task if needed). `TelegramMedia` — TelegramCore type, no change.

- [ ] **Step 2a: (Only if needed) Add missing engine methods**

Minimal pass-through on `TelegramEngine.Resources`. Build, commit.

- [ ] **Step 3: Edit the consumer file**

Replace every `mediaBox.*` with `engine.resources.*`. Thread an `engine` argument through internal functions as needed (prefer reading it off an existing `AccountContext` already in scope). Remove `import Postbox`.

- [ ] **Step 4: Drop the Bazel dep**

Edit `submodules/FetchManagerImpl/BUILD`. Remove `"//submodules/Postbox:Postbox",` from `deps`.

- [ ] **Step 5: Static checks**

```bash
grep -R "^import Postbox" submodules/FetchManagerImpl/Sources   # expect: empty
grep "submodules/Postbox" submodules/FetchManagerImpl/BUILD      # expect: empty
```

- [ ] **Step 6: Full project build**

Run the full build. Expected: PASS. Handle failures per the Build-failure handling rules in the Background section.

- [ ] **Step 7: Commit**

```bash
git add submodules/FetchManagerImpl/
git commit -m "$(cat <<'EOF'
FetchManagerImpl: drop direct Postbox dependency

Route MediaBox fetch/status calls through TelegramEngine.resources;
remove the Postbox import and Bazel dep. Behavior-preserving.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Refactor `GalleryData` — **ABANDONED**

**Status:** Abandoned for wave 1. No code changes in this repo from this task.

**Reason:** Four public functions take `Media` (Postbox protocol) and/or `Message` (Postbox class) as parameters, called from TelegramUI and ChatListUI (out-of-wave). Refactoring to `EngineMedia` / `EngineMessage` requires `.init(_:)` / `._asMedia()` / `._asMessage()` coercions threaded through many local variables (e.g. `var galleryMedia: Media?` in `chatMessageGalleryControllerData` is reassigned from various `TelegramMedia*` casts and passed to `MessageReference(...)` chains and enum cases), which would cascade into `AvatarGalleryEntry`, `MessageReference`, and other out-of-wave types. The narrow-utility alias path is ruled out because `Media` and especially `Message` are domain types, not utilities. Per the abandonment protocol, the module is skipped.

**Original task body (retained for audit trail, do not implement):**

**Files:**
- Modify: `submodules/GalleryData/Sources/GalleryData.swift`
- Modify: `submodules/GalleryData/BUILD`

**Starting inventory** (computed during planning): `Peer` (×1), `Media` (×9), `Message` (×4), `Namespaces.` (×3), `TelegramMedia*` (×30). No `mediaBox`, no `transaction`, no `combinedView`. This is a **type-reference-only** case at scale.

- [ ] **Step 1: Inventory**

Read the whole file. Record every declaration that uses a Postbox-owned type (`Peer`, `Media`, `Message`, `MessageId`, etc.) — note that `TelegramMedia*` and `Namespaces` are TelegramCore, not Postbox, and do **not** need changing.

```bash
grep -nE "\b(Peer|Media|Message|MessageId|MessageIndex)\b" submodules/GalleryData/Sources/GalleryData.swift | head -60
```

- [ ] **Step 2: Map each reference**

- `Peer` → `EnginePeer` at the call-site level where the value is newly produced; for existing public signatures that already accept a `Peer` from elsewhere, prefer `EnginePeer` **only if** downstream consumers accept it. Otherwise leave the signature alone and swap only the internal uses.
- `Media`, `Message`, `MessageId` → engine typealiases per the cheat sheet.
- `TelegramMedia*`, `Namespaces.*` — no change.

- [ ] **Step 2a: (Only if needed) Add engine typealiases**

Add any missing typealias in `submodules/TelegramCore/Sources/TelegramEngine/…`. Build, commit.

- [ ] **Step 3: Edit the consumer file**

Apply mappings. Remove `import Postbox`.

- [ ] **Step 4: Drop the Bazel dep**

Edit `submodules/GalleryData/BUILD`. Remove `"//submodules/Postbox:Postbox",` from `deps`.

- [ ] **Step 5: Static checks**

```bash
grep -R "^import Postbox" submodules/GalleryData/Sources   # expect: empty
grep "submodules/Postbox" submodules/GalleryData/BUILD      # expect: empty
```

- [ ] **Step 6: Full project build**

Run the full build. Expected: PASS. Handle failures per the Build-failure handling rules in the Background section.

- [ ] **Step 7: Commit**

```bash
git add submodules/GalleryData/
git commit -m "$(cat <<'EOF'
GalleryData: drop direct Postbox dependency

Switch Postbox-typed references to engine typealiases; remove the
Postbox import and Bazel dep. Behavior-preserving.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Refactor `ICloudResources` — **ABANDONED**

**Status:** Abandoned for wave 1. No code changes in this repo from this task.

**Reason:** The module declares `public class ICloudFileResource: TelegramMediaResource` and thus must implement `func isEqual(to: MediaResource) -> Bool` (protocol requirement inherited from `MediaResource`). That override's parameter type is fixed at `MediaResource`, which can only be named by importing Postbox or adding a typealias for the raw `MediaResource` protocol. The protocol-alias would be borderline per rule 2; user directed to skip. Per the abandonment protocol, the module is skipped.

**Original task body (retained for audit trail, do not implement):**

### Original Task 10

**Files:**
- Modify: `submodules/ICloudResources/Sources/ICloudResources.swift`
- Modify: `submodules/ICloudResources/BUILD`

**Starting inventory** (computed during planning): `MediaResource` (×2), `TelegramMedia` (×1). No `mediaBox`, no `transaction`. Small type-reference-only module. The `MediaResource` uses may be a custom `MediaResource`-conforming class defined in this file — confirm during inventory.

- [ ] **Step 1: Inventory**

Read the whole file. `MediaResource` is a Postbox protocol; `ICloudResources` likely declares a custom class conforming to it. Capture whether (a) the file declares new `MediaResource`-conforming types, (b) it only references the protocol, or both.

```bash
grep -nE "\b(MediaResource|TelegramMedia)\b|class.*:.*MediaResource|struct.*:.*MediaResource" submodules/ICloudResources/Sources/ICloudResources.swift
```

- [ ] **Step 2: Map each reference**

- If the file declares a type conforming to `MediaResource`, use the `EngineMediaResource` typealias in the declaration (`class FooResource: EngineMediaResource { ... }`). Because typealiases are transparent, this keeps protocol conformance identical.
- All other `MediaResource` references → `EngineMediaResource`.
- `TelegramMedia*` — TelegramCore, no change.

Add `EngineMediaResource` typealias in TelegramCore if not already present (Task 2 / Task 6 may have added it; check first).

- [ ] **Step 2a: (Only if needed) Add `EngineMediaResource` typealias**

```swift
// submodules/TelegramCore/Sources/TelegramEngine/Resources/EngineMediaResource.swift
import Postbox
public typealias EngineMediaResource = MediaResource
```

Build, commit.

- [ ] **Step 3: Edit the consumer file**

Apply mappings. Remove `import Postbox`.

- [ ] **Step 4: Drop the Bazel dep**

Edit `submodules/ICloudResources/BUILD`. Remove `"//submodules/Postbox:Postbox",` from `deps`.

- [ ] **Step 5: Static checks**

```bash
grep -R "^import Postbox" submodules/ICloudResources/Sources   # expect: empty
grep "submodules/Postbox" submodules/ICloudResources/BUILD      # expect: empty
```

- [ ] **Step 6: Full project build**

Run the full build. Expected: PASS. Handle failures per the Build-failure handling rules in the Background section.

- [ ] **Step 7: Commit**

```bash
git add submodules/ICloudResources/
git commit -m "$(cat <<'EOF'
ICloudResources: drop direct Postbox dependency

Switch MediaResource references to EngineMediaResource; remove the
Postbox import and Bazel dep. Behavior-preserving.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Wave-1 completion verification

**Files:** No code changes.

- [ ] **Step 1: Static check across all 10 modules**

```bash
for m in ActionSheetPeerItem ChatInterfaceState ChatListSearchRecentPeersNode ChatSendMessageActionUI ContactListUI DirectMediaImageCache DrawingUI FetchManagerImpl GalleryData ICloudResources; do
  echo "=== $m ==="
  grep -R "^import Postbox" submodules/$m/Sources && echo "FAIL: import in $m"
  grep "submodules/Postbox" submodules/$m/BUILD && echo "FAIL: dep in $m"
done
```

Expected: no `FAIL` lines printed. If any appear, return to the corresponding task and fix.

- [ ] **Step 2: Final full build**

Run the full build one more time from a clean state. Expected: PASS. (If it passed at the end of Task 10 and nothing else has changed, this should be cached and fast.)

- [ ] **Step 3: Review the commit log**

```bash
git log --oneline master..HEAD
```

Expected: a run of commits matching the pattern `TelegramCore: add …` (optional) and `<Module>: drop direct Postbox dependency` (one per module done). If any module was skipped per the fallback rule, verify the fallback ran and a replacement module completed so the total is 10.

- [ ] **Step 4: No commit**

Verification only.

---

## What's explicitly NOT in this plan

- Any edits to `TelegramCore`, `Postbox`, or the 64 modules outside the chosen 10 (except the minimum engine-wrapper / typealias additions to `TelegramCore` that the chosen modules need).
- Any new `Engine*` wrapper *structs* (only typealiases and forwarding methods are in scope this wave).
- Any generic `engine.transaction { postbox in … }` escape hatch.
- Any behavior change, performance tweak, or "while we're here" cleanup.
- Any test work — there are no tests in this project.
