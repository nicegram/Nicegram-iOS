# Postbox → TelegramEngine Wave 9 Implementation Plan

> **For agentic workers:** This plan was executed in a single session; steps below are a post-hoc record of the work landed, not a to-do list.

**Goal:** Finish the `StorageUsageScreen` de-Postbox work started in wave 8 by rewriting the two remaining direct-postbox sites that observe `AccountSpecificCacheStorageSettings`, and drop `import Postbox` from `StorageUsageScreen.swift`.

**Architecture:** Replace `postbox.combinedView(keys: [.preferences(...)]) + PreferencesView` observation with `context.engine.data.subscribe(TelegramEngine.EngineData.Item.Configuration.ApplicationSpecificPreference(key:))`, which returns `PreferencesEntry?` and is then decoded the same way (`.get(AccountSpecificCacheStorageSettings.self)`). Replace the transaction-based per-peer classification (`transaction.getPeer` + `transaction.getPeerCachedData as? CachedGroupData/CachedChannelData`) with an `EngineDataMap` of `TelegramEngine.EngineData.Item.Peer.Peer.init(id:)` lookups producing `EnginePeer?` values that pattern-match on `.user` / `.legacyGroup` / `.channel(channel)` / `.secretChat`. The `FoundPeer(peer:subscribers:)` wrapper in the signal's element type is dropped entirely since downstream consumers (`peerExceptions.isEmpty`, `.count`, `.prefix(3).map { EnginePeer($0.peer.peer) }`) never read `subscribers`.

**Tech Stack:** Swift / Bazel. No unit tests.

**Build command:**

```bash
source ~/.zshrc 2>/dev/null; PATH=/opt/homebrew/opt/ruby/bin:`gem environment gemdir`/bin:$PATH python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber 1 --configuration debug_sim_arm64 --continueOnError
```

---

## Scope

Two direct-postbox site clusters rewritten in `StorageUsageScreen.swift`:

1. **Site 1 (former lines 1047–1087)** — `cacheSettingsExceptionCount` signal. Preserved its downstream `EngineDataMap` + `EnginePeer` per-category counting logic unchanged; only the preferences observation replaced.
2. **Site 2 (former lines 3131–3196)** — `peerExceptions` signal inside `openKeepMediaCategory`. Both the preferences observation AND the `postbox.transaction { transaction.getPeer / transaction.getPeerCachedData ... FoundPeer(...) }` block replaced. Signal element type changed from `[(peer: FoundPeer, value: Int32)]` to `[(peer: EnginePeer, value: Int32)]`; `FoundPeer` and the unread `subscribers` field dropped.

One consumer-side edit: `peerExceptions.prefix(3).map { EnginePeer($0.peer.peer) }` → `peerExceptions.prefix(3).map { $0.peer }` (at the `MultiplePeerAvatarsContextItem` construction).

One typealias fixup: `var mergedMedia: [MessageId: Int64]` → `[EngineMessage.Id: Int64]` (required once `import Postbox` is removed, since `MessageId` is the raw Postbox name, not a TelegramCore typealias).

`import Postbox` removed from `StorageUsageScreen.swift`.

---

## Tasks

### Task 1: Rewrite site 1 — cacheSettingsExceptionCount

**Files:**
- Modify: `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageUsageScreen.swift` (former 1047–1058).

Replace the preferences observation header. The downstream `mapToSignal { ... EngineDataMap ... EnginePeer ... }` body is already Engine-only and unchanged.

Before:

```swift
let viewKey: PostboxViewKey = .preferences(keys: Set([PreferencesKeys.accountSpecificCacheStorageSettings]))
let cacheSettingsExceptionCount: Signal<[CacheStorageSettings.PeerStorageCategory: Int32], NoError> = component.context.account.postbox.combinedView(keys: [viewKey])
|> map { views -> AccountSpecificCacheStorageSettings in
    let cacheSettings: AccountSpecificCacheStorageSettings
    if let view = views.views[viewKey] as? PreferencesView, let value = view.values[PreferencesKeys.accountSpecificCacheStorageSettings]?.get(AccountSpecificCacheStorageSettings.self) {
        cacheSettings = value
    } else {
        cacheSettings = AccountSpecificCacheStorageSettings.defaultSettings
    }
    return cacheSettings
}
|> distinctUntilChanged
|> mapToSignal { ... }
```

After:

```swift
let cacheSettingsExceptionCount: Signal<[CacheStorageSettings.PeerStorageCategory: Int32], NoError> = context.engine.data.subscribe(
    TelegramEngine.EngineData.Item.Configuration.ApplicationSpecificPreference(key: PreferencesKeys.accountSpecificCacheStorageSettings)
)
|> map { preferencesEntry -> AccountSpecificCacheStorageSettings in
    return preferencesEntry?.get(AccountSpecificCacheStorageSettings.self) ?? AccountSpecificCacheStorageSettings.defaultSettings
}
|> distinctUntilChanged
|> mapToSignal { ... }
```

### Task 2: Rewrite site 2 — peerExceptions

**Files:**
- Modify: `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageUsageScreen.swift` (former 3131–3196).

Replace both the preferences observation (as in Task 1) AND the subsequent `mapToSignal { context.account.postbox.transaction { ... } }` block. Signal element type changes from `[(peer: FoundPeer, value: Int32)]` to `[(peer: EnginePeer, value: Int32)]`. `subscriberCount` is not preserved — it's computed but never read by downstream consumers.

After (showing the `peerExceptions` signal in full):

```swift
let peerExceptions: Signal<[(peer: EnginePeer, value: Int32)], NoError> = accountSpecificSettings
|> mapToSignal { accountSpecificSettings -> Signal<[(peer: EnginePeer, value: Int32)], NoError> in
    return context.engine.data.get(
        EngineDataMap(accountSpecificSettings.peerStorageTimeoutExceptions.map(\.key).map(TelegramEngine.EngineData.Item.Peer.Peer.init(id:)))
    )
    |> map { peers -> [(peer: EnginePeer, value: Int32)] in
        var result: [(peer: EnginePeer, value: Int32)] = []
        for item in accountSpecificSettings.peerStorageTimeoutExceptions {
            guard let peer = peers[item.key] ?? nil else { continue }
            let peerCategory: CacheStorageSettings.PeerStorageCategory
            switch peer {
            case .user, .secretChat:
                peerCategory = .privateChats
            case .legacyGroup:
                peerCategory = .groups
            case let .channel(channel):
                if case .group = channel.info {
                    peerCategory = .groups
                } else {
                    peerCategory = .channels
                }
            }
            if peerCategory != mappedCategory { continue }
            result.append((peer: peer, value: item.value))
        }
        return result.sorted(by: { lhs, rhs in
            if lhs.value != rhs.value {
                return lhs.value < rhs.value
            }
            return lhs.peer.debugDisplayTitle < rhs.peer.debugDisplayTitle
        })
    }
}
```

### Task 3: Update consumer of `peerExceptions`

**Files:**
- Modify: `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageUsageScreen.swift` (former 3288).

`peerExceptions.prefix(3).map { EnginePeer($0.peer.peer) }` → `peerExceptions.prefix(3).map { $0.peer }`. The `MultiplePeerAvatarsContextItem(context:, peers: [EnginePeer], totalCount:, action:)` signature is unchanged — we simply drop the redundant `EnginePeer(...)` wrap because `$0.peer` is now already an `EnginePeer`.

### Task 4: Drop `import Postbox`

**Files:**
- Modify: `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageUsageScreen.swift` (line 12).

Remove the `import Postbox` line.

### Task 5: Typealias fixup for `MessageId`

**Files:**
- Modify: `submodules/TelegramUI/Components/StorageUsageScreen/Sources/StorageUsageScreen.swift` (former 2397).

`var mergedMedia: [MessageId: Int64]` → `[EngineMessage.Id: Int64]`. `MessageId` is the raw Postbox type name; with `import Postbox` removed, the type must be named through the `EngineMessage.Id` typealias. Discovered by first-pass build failure `cannot find type 'MessageId' in scope`.

### Task 6: Full project build

Expected green. Incremental build: ~60s (cached), 27 actions.

### Task 7: Commit

Single wave-9 atomic commit. CLAUDE.md updates the wave 8 outcome's "future-wave candidates" note since this wave closes both of them. `StorageUsageScreen` (the module as a whole) now has `StorageUsageScreen.swift` Postbox-free; the module's `StorageFileListPanelComponent.swift` still imports Postbox because of the `Icon.media(Media, TelegramMediaImageRepresentation)` enum case (trivial future wave, as previously noted).

---

## Outcome (2026-04-20)

Single atomic commit. Build verified green (27 actions, ~60s incremental).

Net change: 1 file, +30 / -54 lines (-24 simplification).

Lessons:

- **`ApplicationSpecificPreference(key:)` is the general-purpose engine replacement** for any `postbox.combinedView(keys: [.preferences(keys: Set([key]))])` idiom. Takes a `ValueBoxKey`, returns `PreferencesEntry?`, decodes via `.get(T.self)`. Usable from any module that imports `TelegramCore` even without `import Postbox`, because the `ValueBoxKey`-typed input is obtained through a statically-named `PreferencesKeys.*` member (no `ValueBoxKey` identifier appears in the consumer).
- **`MessageId` is raw Postbox, not a TelegramCore typealias.** CLAUDE.md's "engine typealias cheat sheet" labels `PeerId`, `MessageId`, etc. as migration *targets*, not existing aliases. Files that drop `import Postbox` must rename these to `EngineMessage.Id` / `EnginePeer.Id`. Caught by the first-pass build failure.
- **Dead-code detection during rewrites.** The transaction block's `subscriberCount` computation and the `FoundPeer.subscribers` field it populated were never consumed downstream. The rewrite simply dropped them, shrinking the code further than a 1:1 rewrite would have.

`StorageUsageScreen.swift` is now Postbox-free. The `StorageUsageScreen` consumer module as a whole is still not fully Postbox-free because `StorageFileListPanelComponent.swift` retains `import Postbox` for its `Icon.media(Media, TelegramMediaImageRepresentation)` enum case (3 construction sites; trivial future wave splits into `.mediaFile(TelegramMediaFile, ...)` / `.mediaImage(TelegramMediaImage, ...)`).
