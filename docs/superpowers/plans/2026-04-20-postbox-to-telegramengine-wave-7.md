# Postbox → TelegramEngine Wave 7 Implementation Plan

> **For agentic workers:** This plan was executed in a single session; steps below are a post-hoc record of the work landed, not a to-do list.

**Goal:** Close out the remaining raw-Postbox leaks in `TelegramEngine.*` public facades surfaced by the wave-6 post-sweep scouting pass (2026-04-20). Six facade-signature migrations + one dead-facade deletion + consumer call-site bridging, landed as a single wave commit.

**Architecture:** Wave-2 shape scaled to seven facades at once: each facade signature changes in place from raw Postbox domain types (`Message`, `Peer`) to engine equivalents (`EngineMessage`, `EnginePeer`), with `_internal_*` implementations left raw per the standing "internal Postbox-facing stays raw" rule. Consumer call sites bridge at the facade boundary via `EngineMessage.init` / `._asMessage()` wrap/unwrap helpers or drop now-redundant wrapping.

**Tech Stack:** Swift / Bazel. No unit tests by repo policy — verification is a full project build.

**Build command:**

```bash
source ~/.zshrc 2>/dev/null; PATH=/opt/homebrew/opt/ruby/bin:`gem environment gemdir`/bin:$PATH python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber 1 --configuration debug_sim_arm64 --continueOnError
```

---

## Scope — candidate list

All seven items from the wave-6 post-sweep scouting pass:

1. `TelegramEngine.Messages.downloadMessage(messageId: MessageId) -> Signal<Message?, NoError>` → `(messageId: EngineMessage.Id) -> Signal<EngineMessage?, NoError>`. Callers: 1 (`ChatListSearchListPaneNode`).
2. `TelegramEngine.Messages.topPeerActiveLiveLocationMessages(peerId: PeerId) -> Signal<(Peer?, [Message]), NoError>` → `(peerId: EnginePeer.Id) -> Signal<(EnginePeer?, [EngineMessage]), NoError>`. Callers: 2 (`LocationViewControllerNode`, `LiveLocationSummaryManager`).
3. `TelegramEngine.Messages.getSynchronizeAutosaveItemOperations()` — dead facade (sole caller `StoreDownloadedMedia.swift:298` uses `_internal_*` directly). Deleted.
4. `TelegramEngine.Peers.updatedRemotePeer(peer: PeerReference) -> Signal<Peer, UpdatedRemotePeerError>` → `Signal<EnginePeer, UpdatedRemotePeerError>`. `PeerReference` param kept (no `EnginePeer.Reference` alias today). Callers: 1 (`ChannelAdminsController`, `ignoreValues` so no caller change needed).
5. `TelegramEngine.Resources.renderStorageUsageStatsMessages(…existingMessages: [EngineMessage.Id: Message]) -> Signal<[EngineMessage.Id: Message], NoError>` → `[EngineMessage.Id: EngineMessage]` on both sides. Callers: 1 (`StorageUsageScreen`).
6–8. `TelegramEngine.Resources.clearStorage(...)` overloads (three) — `[Message]` params → `[EngineMessage]`. Real external callers: 2 (`StorageUsageScreen`, two overloads). The third overload `clearStorage(messages:)` has no callers; migrated for overload-set consistency.

---

## Tasks

### Task 1: Migrate three `TelegramEngine.Messages` facades

**Files:**
- Modify: `submodules/TelegramCore/Sources/TelegramEngine/Messages/TelegramEngineMessages.swift` (3 facades)
- Modify: `submodules/ChatListUI/Sources/ChatListSearchListPaneNode.swift` (drop redundant `.flatMap(EngineMessage.init)`)
- Modify: `submodules/LocationUI/Sources/LocationViewControllerNode.swift` (drop redundant `.map(EngineMessage.init)`)
- Modify: `submodules/LiveLocationManager/Sources/LiveLocationSummaryManager.swift` (drop redundant `EnginePeer(...)` / `EngineMessage(...)` wrappers)

**Changes:**

`downloadMessage` — wrap return `Message?` → `EngineMessage?` via `|> map { $0.flatMap(EngineMessage.init) }`. `_internal_downloadMessage` still takes `messageId: MessageId`, which is typealiased to `EngineMessage.Id`, so the param change is purely a rename at the public surface.

`topPeerActiveLiveLocationMessages` — wrap tuple return via `|> map { peer, messages -> (EnginePeer?, [EngineMessage]) in (peer.flatMap(EnginePeer.init), messages.map(EngineMessage.init)) }`.

`getSynchronizeAutosaveItemOperations` — deleted. The sole caller `StoreDownloadedMedia.swift:298` was already calling `_internal_getSynchronizeAutosaveItemOperations` directly (inside its own transaction block), so no caller update needed.

### Task 2: Migrate `TelegramEngine.Peers.updatedRemotePeer`

**Files:**
- Modify: `submodules/TelegramCore/Sources/TelegramEngine/Peers/TelegramEnginePeers.swift`

Append `|> map(EnginePeer.init)` to wrap the `Peer` result. `PeerReference` param stays. Single call site in `ChannelAdminsController.swift` uses `ignoreValues`, so no caller-side change.

### Task 3: Migrate four `TelegramEngine.Resources` facades

**Files:**
- Modify: `submodules/TelegramCore/Sources/TelegramEngine/Resources/TelegramEngineResources.swift` (4 facades)
- Modify: `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageUsageScreen.swift` (3 call sites)

`renderStorageUsageStatsMessages` — unwrap `[EngineMessage.Id: EngineMessage]` input via `.mapValues { $0._asMessage() }`, wrap raw result via `.mapValues(EngineMessage.init)`. Caller bridges the other direction at its single call site (`.mapValues(EngineMessage.init)` on the input `existingMessages`, `.mapValues { $0._asMessage() }` on the mapped result).

`clearStorage(peerId:categories:includeMessages:excludeMessages:)` / `clearStorage(peerIds:includeMessages:excludeMessages:)` / `clearStorage(messages:)` — unwrap `[EngineMessage]` params via `.map { $0._asMessage() }` before forwarding to `_internal_clearStorage`. Callers bridge `[Message]` locals with `.map(EngineMessage.init)` at the facade call site.

Call-site changes in `StorageUsageScreen` are intentionally minimal: the file's `AggregatedData` type keeps `[MessageId: Message]` / `[Message]` internally, with bridging applied only at the four facade-call points. A full-consumer-module migration to `EngineMessage` is out of scope for this wave (would require changing ~30 sites plus the item types in `StorageFileListPanelComponent`; a future "StorageUsageScreen full de-Postbox" wave could land that).

### Task 4: Full project build

Run the build command above with `--continueOnError`. Expected: clean build (no errors or warnings introduced). One full build covers all facades since they're in TelegramCore and rebuilding TelegramCore re-verifies every consumer.

### Task 5: Commit

Single wave-7 atomic commit covering the 8 modified files and the CLAUDE.md outcome update.

---

## Outcome (2026-04-20)

All seven candidates landed. Single atomic commit. Build verified green (`bazel-bin/Telegram/Telegram.ipa` produced; 5854 total actions, 1009 executed).

- 3 `TelegramEngine.Messages` facades migrated (1 rewrite, 1 rewrite, 1 deletion)
- 1 `TelegramEngine.Peers` facade migrated
- 4 `TelegramEngine.Resources` facades migrated (1 dict, 3 overloads)
- 5 consumer files updated: `ChatListSearchListPaneNode`, `LocationViewControllerNode`, `LiveLocationSummaryManager`, `StorageUsageScreen`, CLAUDE.md

No modules became Postbox-free in this wave (all five touched consumers still import Postbox for unrelated reasons — `StorageUsageScreen` especially, which still has 43 raw `Message` / `MessageId` references outside the facade boundary).

**Lesson recorded:** when a facade's consumer file uses the raw Postbox type extensively outside the facade boundary (e.g. `StorageUsageScreen` with its `[MessageId: Message]` dict stored in a helper class and threaded through ~30 sites), bridging at the facade call site is the correct scope. Full-consumer-module migration is its own separate wave, not a side-effect of facade migration.

**Next-wave candidates.** The sum of the scouting pass's 8 candidates has been closed. No new `TelegramEngine.*` public facades with raw `Postbox`/`Account`/`MediaBox`/`Peer`/`Message`/`MediaResource` leaks remain. Future-wave focus shifts to:

1. Full-consumer-module migrations (e.g. `StorageUsageScreen` — drop `AggregatedData`'s raw-Postbox storage types, drop `import Postbox`).
2. Another speculative unused-import sweep pass like wave 6, to catch imports that became unused after waves 4–7.
