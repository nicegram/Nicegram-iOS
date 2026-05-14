# Postbox → TelegramEngine Wave 8 Implementation Plan

> **For agentic workers:** This plan was executed in a single session; steps below are a post-hoc record of the work landed, not a to-do list.

**Goal:** `StorageUsageScreen` consumer-module migration — drop all raw `Message` domain types from the screen's internal storage and public peer-panel item types, and eliminate the wave-7 facade-boundary bridging. Scope is narrower than a full de-Postbox of the module: direct `postbox.combinedView` / `postbox.transaction` sites for `AccountSpecificCacheStorageSettings` observation are left for a future wave.

**Architecture:** Two files modified. `StorageFileListPanelComponent.Item.message` and `StorageUsageScreen`'s `AggregatedData` + `RenderResult` + `SelectionState` internal types are migrated from raw `Message`/`[Message]`/`[MessageId: Message]` to `EngineMessage`/`[EngineMessage]`/`[EngineMessage.Id: EngineMessage]`. The two external APIs that still take raw `Message` (`OpenChatMessageParams.message`, `chatMediaListPreviewControllerData(message:)`) are called with `engineMessage._asMessage()` at the call site.

**Tech Stack:** Swift / Bazel. No unit tests by repo policy — verification is a full project build.

**Build command:**

```bash
source ~/.zshrc 2>/dev/null; PATH=/opt/homebrew/opt/ruby/bin:`gem environment gemdir`/bin:$PATH python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber 1 --configuration debug_sim_arm64 --continueOnError
```

---

## Scope

**In scope:**

- `StorageFileListPanelComponent.Item.message: Message` → `EngineMessage` (the item type co-located with the panel component).
- `StorageUsageScreen.Component.SelectionState.togglePeer(id:availableMessages: [EngineMessage.Id: Message])` → `[EngineMessage.Id: EngineMessage]`.
- `StorageUsageScreen.Component.AggregatedData.messages: [MessageId: Message]` → `[EngineMessage.Id: EngineMessage]`.
- `AggregatedData.clearIncludeMessages: [Message]` / `.clearExcludeMessages: [Message]` → `[EngineMessage]` (plus the corresponding local vars in `AggregatedData.updateSelected...`).
- `AggregatedData.init(..., messages: [MessageId: Message])` → `[EngineMessage.Id: EngineMessage]`.
- `StorageUsageScreen.Component.RenderResult.messages: [MessageId: Message]` → `[EngineMessage.Id: EngineMessage]`.
- `openMessage(message: Message)` → `openMessage(message: EngineMessage)`.
- Drop the now-redundant wave-7 facade-boundary bridging (`.mapValues(EngineMessage.init)` on `existingMessages`, `.mapValues { $0._asMessage() }` on the facade's engineMessages output, `.map(EngineMessage.init)` on the two `clearStorage` call sites, `._asMessage()` on `item.message` inside the `AggregatedData.updateSelected...` loop, and `EngineMessage(message)` inside the `result.imageItems.append(...)` site).

**Out of scope — left for a future wave:**

- Direct postbox usage for `AccountSpecificCacheStorageSettings` observation: `StorageUsageScreen.swift:1047-1062` and `3131-3185`. Blocks `import Postbox` removal. Requires engine equivalents for `PostboxViewKey.preferences` / `PreferencesView` observation and for `transaction.getPeer` / `transaction.getPeerCachedData` — likely an `EngineData`-subscription based rewrite plus peer-category classification via already-existing engine APIs.
- `StorageFileListPanelComponent`'s `Icon.media(Media, TelegramMediaImageRepresentation)` enum case. Holds either `TelegramMediaFile` or `TelegramMediaImage` (always one of these two TelegramCore types per `imageIconValue = .media(file, ...)` and `.media(image, ...)` construction sites). Could be split into `.mediaFile(TelegramMediaFile, ...)` / `.mediaImage(TelegramMediaImage, ...)` to eliminate the raw `Media` protocol dependency; out of scope as it's unrelated to Message-type migration.

---

## Tasks

### Task 1: Migrate `StorageFileListPanelComponent.Item.message`

**Files:**
- Modify: `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageFileListPanelComponent.swift` — `Item.message` type and `init(message:)` param.

No other changes inside the file. Internal usage (`item.message.id`, `item.message.timestamp`, `item.message.media`) already works on `EngineMessage` — `EngineMessage.media` returns `[Media]` (raw), so the `as? TelegramMediaFile` / `as? TelegramMediaImage` downcasts inside the `for media in item.message.media` loop still compile.

### Task 2: Migrate `StorageUsageScreen` internal storage types

**Files:**
- Modify: `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageUsageScreen.swift`

Change:
- `SelectionState.togglePeer(availableMessages: [EngineMessage.Id: Message])` → `[EngineMessage.Id: EngineMessage]`. Body only uses `messageId.peerId` so no body change required.
- `AggregatedData.messages` / `.clearIncludeMessages` / `.clearExcludeMessages` type declarations and the init param.
- The selected-messages accumulation loop inside `AggregatedData` (the block running from the photo/video/file/music category branches): drop `item.message._asMessage()` in the two photo/video branches (`imageItems` holds EngineMessage items, so `._asMessage()` was the EngineMessage→Message unwrap to fit the old `[Message]` local); `item.message` in the file/music branches now passes through since Item.message is EngineMessage.
- `RenderResult.messages` type.

### Task 3: Drop wave-7 facade-boundary bridging

At `StorageUsageScreen.swift:2397` the `renderStorageUsageStatsMessages` call previously wrapped input via `(self.aggregatedData?.messages ?? [:]).mapValues(EngineMessage.init)` and unwrapped output via `.mapValues { $0._asMessage() }`. With `AggregatedData.messages` and `RenderResult.messages` now EngineMessage-typed, both bridges vanish: the call just passes `self.aggregatedData?.messages ?? [:]` directly and assigns the result to `result.messages` unchanged.

At the two `clearStorage` call sites in `StorageUsageScreen.swift` (inside `clearSelected(...)`): `aggregatedData.clearIncludeMessages.map(EngineMessage.init)` → `aggregatedData.clearIncludeMessages` (same for `excludeMessages`), plus the local `includeMessages: [Message]` / `excludeMessages: [Message]` vars become `[EngineMessage]`.

At the `RenderResult`-building loop (post-`renderStorageUsageStatsMessages`), `StorageMediaGridPanelComponent.Item(message: EngineMessage(message), ...)` → `message: message` since `message` is already `EngineMessage`.

### Task 4: Migrate `openMessage` + external-API unwraps

`openMessage(message: Message)` → `openMessage(message: EngineMessage)`. Two external APIs receive raw `Message`: pass `message._asMessage()` to `OpenChatMessageParams(message:)` inside `openMessage`, and to `chatMediaListPreviewControllerData(message:)` inside `messageGaleryContextAction`. Also drop the one-line `let foundGalleryMessage: Message? = message` + `guard let galleryMessage = foundGalleryMessage` dance inside `openMessage` — it's a no-op wrap preserved from an older version.

### Task 5: Full project build

Expected clean (cached — 30 seconds on an incremental build; ~60s from a cold start since wave 7).

### Task 6: Commit

Single wave-8 atomic commit.

---

## Outcome (2026-04-20)

Single atomic commit landing the migration. Build verified green (59s incremental, 27 actions). Net -5 lines (simplification, as expected — most changes are type swaps and a handful of redundant wraps/unwraps removed).

Two files modified:

| File | Δ |
|---|---|
| `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageUsageScreen.swift` | +33 / -44 |
| `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageFileListPanelComponent.swift` | +3 / -3 |

**Module did NOT become Postbox-free.** Both files retain `import Postbox` for the out-of-scope sites listed above. Drop-candidacy inventory in `StorageUsageScreen.swift`:

- 1047–1062: preferences-view observation of `AccountSpecificCacheStorageSettings` via `postbox.combinedView` + `PreferencesView`.
- 3131–3185: second preferences-view observation + `postbox.transaction { transaction in ... transaction.getPeer / transaction.getPeerCachedData as? CachedGroupData / CachedChannelData ... }` for classifying peer-storage-timeout exceptions.

And in `StorageFileListPanelComponent.swift`:

- 105: `Icon.media(Media, TelegramMediaImageRepresentation)` enum case.

Future wave targets either the preferences-view observation sites (substantial — `EngineData`-subscription rewrite + peer-category classification via engine APIs) or the `Icon.media` split (trivial — 3 sites to update).

Plan / record: `docs/superpowers/plans/2026-04-20-postbox-to-telegramengine-wave-8.md`.
