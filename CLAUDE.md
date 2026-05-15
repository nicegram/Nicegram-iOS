# CLAUDE.md

This file provides guidance to AI assistants when working with code in this repository.

## Build

The app is built using Bazel via the `Make.py` wrapper. There is no selective per-module build — the only supported invocation builds the full `Telegram/Telegram` target.

**Command:**

```sh
python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 --configuration=debug_sim_arm64
```

Add `--continueOnError` after `build` (forwards to bazel's `--keep_going`) when verifying changes that may surface errors in many files at once — it lets the full set of errors land in one pass instead of stopping at the first failing target.

The build needs `TELEGRAM_CODESIGNING_GIT_PASSWORD` in the environment. It is set in `~/.zshrc` but Claude Code's bash tool does NOT source shell config by default. Prefix build commands with `source ~/.zshrc 2>/dev/null;` to pick it up.

## Code Style Guidelines
- **Naming**: PascalCase for types, camelCase for variables/methods
- **Imports**: Group and sort imports at the top of files
- **Error Handling**: Properly handle errors with appropriate redaction of sensitive data
- **Formatting**: Use standard Swift/Objective-C formatting and spacing
- **Types**: Prefer strong typing and explicit type annotations where needed
- **Documentation**: Document public APIs with comments

## Project Structure
- Core launch and application extensions code is in `Telegram/` directory
- Most code is organized into libraries in `submodules/`
- External code is located in `third-party/`
- No tests are used at the moment

## Postbox → TelegramEngine refactor (in progress)

A gradual migration is underway to eliminate direct `import Postbox` from consumer submodules in favor of `TelegramEngine`.

**Historical record:** Wave-by-wave outcomes, the running tally of Postbox-free modules, and full verbose forms of the guidance subsections below live in [`docs/superpowers/postbox-refactor-log.md`](docs/superpowers/postbox-refactor-log.md). Read that file when you need wave-specific context, a full worked example of a pattern, or the history of a particular module's migration.

Waves landed so far (as of 2026-04-24): 45 waves plus standalone cleanups. See the log file for per-wave detail; the list of still-open migration opportunities lives in the `project_postbox_refactor_next_wave.md` memory file.

### Rules that apply to every wave

1. `TelegramCore` does **not** `@_exported import Postbox`. Once a consumer drops `import Postbox`, every remaining Postbox-type reference must use an engine-typealiased equivalent.
2. **Never typealias `Postbox`, `Account`, or `MediaBox`.** These umbrella types rename without encapsulating. Narrow utility typealiases (`MemoryBuffer`, `PostboxDecoder`, `PostboxEncoder`, `AdaptedPostboxDecoder`, `MediaResource`, …) remain allowed and expected.
3. No new engine wrapper **structs** unless the wave's spec explicitly allows — only typealiases and thin forwarding methods.
4. **Discovery first:** before adding any new engine wrapper/typealias, grep `submodules/TelegramCore/Sources/TelegramEngine/` for existing equivalents. Record the search result in the commit message.
5. **Abandonment protocol:** if a module can only be refactored by violating rule 2 or by editing a module outside the current wave's list, mark the task Abandoned with a recorded reason. Do NOT substitute a new module mid-wave.
6. Full project build per module. No unit tests exist in this project.
7. **TelegramCore never imports UIKit/Display.** `TelegramCore` is shared with the Telegram-Mac codebase; its Bazel `deps` and source files must not reference UIKit, Display, or any Apple-UI framework. UIKit-needing helpers (image scaling, rendering, etc.) stay in consumer-side submodules.

### Engine typealias cheat sheet (existing aliases)

```
PeerId              → EnginePeer.Id
MessageId           → EngineMessage.Id
MessageIndex        → EngineMessage.Index
MessageTags         → EngineMessage.Tags
MessageAttribute    → EngineMessage.Attribute
MessageFlags        → EngineMessage.Flags
MessageForwardInfo  → EngineMessage.ForwardInfo
MediaId             → EngineMedia.Id
PreferencesEntry    → EnginePreferencesEntry
TempBox             → EngineTempBox
PinnedItemId        → EngineChatList.PinnedItem.Id
MemoryBuffer        → EngineMemoryBuffer           (added 2026-04)
PostboxDecoder      → EnginePostboxDecoder         (added 2026-04)
PostboxEncoder      → EnginePostboxEncoder         (added 2026-04)
AdaptedPostboxDecoder → EngineAdaptedPostboxDecoder (added 2026-04)
ItemCollectionId    → EngineItemCollectionId       (added 2026-04-20)
FetchResourceSourceType → EngineFetchResourceSourceType (added 2026-04-20)
FetchResourceError  → EngineFetchResourceError     (added 2026-04-20)
```

For the `MediaResource` Postbox protocol, prefer the TelegramCore subtype `TelegramMediaResource` when the consumer's usage allows (note: `EngineMediaResource` is a wrapper **class**, not a typealias, so it is not interchangeable with the protocol).

### MediaResource → EngineMediaResource consumer migration

`EngineMediaResource` is a `final class` in `TelegramCore` wrapping a `MediaResource` value. Unlike the typealiases above it is **not** interchangeable with the protocol, but it does provide wrap/unwrap helpers:

- `EngineMediaResource(rawResource)` — wrap a raw `MediaResource`.
- `engineResource._asResource()` — unwrap to the raw `MediaResource`.
- `EngineMediaResource.ResourceData(rawResourceData)` — wrap `MediaResourceData`.
- `EngineMediaResource.Id(rawMediaResourceId)` — wrap `MediaResourceId`.

**Pattern for facade functions:** when a `TelegramEngine.<Area>` method leaks raw `MediaResource` in its public signature, **change the facade signature in place** to `EngineMediaResource` (and change any closure parameter types the same way). Bridge inside the facade body by calling the existing `_internal_*` function with `engineResource._asResource()` / wrapping raw inputs from inner closures with `EngineMediaResource(rawResource)`. Update all call sites in the same commit. The `_internal_*` function stays on raw `MediaResource` — it is the Postbox-facing layer.

Do **not** add opt-in `EngineMediaResource` overloads alongside raw-`MediaResource` overloads. Duplicate signatures fragment the public API and leave the leak in place forever.

For consumer modules, prefer `EngineMediaResource` as the type in properties, locals, generic arguments and function parameters when the usage is a pure type reference. Do **not** try to use `EngineMediaResource` where a class must conform to `TelegramMediaResource` (Postbox protocol) or override `isEqual(to: MediaResource)` — those remain `import Postbox`.

### Wave-selection guidance

Distilled lessons from waves 1–26. Each bullet below has a full-form counterpart in `postbox-refactor-log.md` (same subsection heading) with backstory, example scripts, and per-wave numbers.

**Shape selection.** The "leaf module, drop Postbox in isolation" approach (wave 1) only works when the candidate's public API doesn't leak Postbox domain types. Most candidates DO leak (`postbox: Postbox` / `account: Account` in public inits, `Media`/`Message` as public parameter types). Grep each candidate for `:\s*Postbox\b`, `:\s*Account\b`, `:\s*MediaBox\b`, and `Media`/`Message` as public parameter types before committing to a wave; abandon candidates whose public API leaks.

**Inventory at execution time, not just planning time.** Planning-time grep often undercounts. Re-inventory at Task-1 time using the full token set `\b(postbox|mediaBox|transaction|PostboxView|combinedView|MediaResource|PostboxDecoder|PostboxEncoder|MemoryBuffer)\b|^import Postbox` over the module's sources. If the count exceeds the plan, abandon before editing code rather than substituting a different module.

**Two feasible wave shapes.** Shape 1 = "per-module Postbox drop" (fragile; wave 1 lost 6 of 10 candidates). Shape 2 = "per-engine-facade-API migrate in place, update all call sites in one commit" (validated from wave 2 onward). Prefer shape 2 when the target is an API surface that multiple consumer modules depend on.

**Enum-payload migrations need full case-site grep.** When changing the payload type of a public enum, grep `case \.` / `let \.` / `\.<caseName>\(` across the enum's defining module — not just call sites of the facade that returns it. Wave 4 undercounted by 6 sites (shortcut constructions and destructures inside the same file as the facade) because the inventory only grepped facade callers.

**Unused-import sweeps** (wave-shape applied in waves 6, 14). Speculatively drop `^import Postbox$` from every candidate file, build with `--continueOnError`, extract failing files and restore their imports, iterate. After a few iterations, do pattern-based preemptive restores for files naming Postbox-only symbols (`MediaBox`, `PostboxCoding`, `PostboxDecoder`, `PostboxEncoder`, `TempBoxFile`, `ValueBoxKey`, `Postbox\b`, `PeerId`, `MessageId`, `MediaId`, `MessageIndex`, `MessageAndThreadId`, `PeerNameIndex`). Scope never leaves the consumer-module candidate set — halt if errors surface in TelegramCore / Postbox / TelegramApi. Run a matching BUILD-dep sweep immediately after (near-zero execution risk). Full methodology, scripts, and iteration-count history in the log.

**Public-Postbox-type inventory** (wave-11-pattern planning). Grep candidate modules against the full Postbox public-types allowlist, not just the pattern's target tokens. Waves before 16 missed types like `EngineMessageHistoryThread.Info` (Postbox-defined despite its "Engine" prefix) and `PeerStoryStats`. "Engine"-prefixed types can still be Postbox-defined — grep for the defining module, don't trust naming. Build allowlist with `grep -rhE "^public\s+(class|struct|enum|protocol|typealias)\s+\w+" submodules/Postbox/Sources/ | awk '{print $3}' | sed 's/[(:<].*//' | sort -u`, then grep candidates against it. Full script in the log.

**Wave-shape G: facade addition + consumer sweep in one commit** (validated across waves 19–26). Recipe:
1. Target a `MediaBox` method whose Postbox signature uses clean leaf types (`MediaResourceId`, `Data`, `String`, `Bool`) and whose return type is either non-Postbox or has an existing `Engine*` wrapper.
2. Pre-flight inventory: classify each call site as Shape A (`context.account.postbox.mediaBox.X(...)`, migratable), Shape B (different overload via `AccountContext`, migratable), Shape C (raw `account: Account` local, skip — needs per-module rework), Shape D (`self.postbox` stored field, skip). Also check for `accountManager.mediaBox.X(...)` — a separate migration path.
3. Design facade with `EngineMediaResource.Id` or `EngineMediaResource` parameters and engine-or-clean return types; preserve default argument values.
4. WIP-interference check: `git status --short | grep -v "^??"` — if any Shape-A site is in a WIP file, either skip those sites or wait.
5. Name-collision check: if the facade signature names a Swift stdlib type with availability restrictions (`RangeSet`, iOS 18+), verify the third-party module import is present in `TelegramEngineResources.swift`.
6. Batch duplicate call expressions with `replace_all=true`.
7. Cheapness: 5–50 sites per wave, single atomic commit, expected first-pass-clean build. If post-migration grep for the migrated expression returns empty (excluding Shape C/D) and build is green, commit.

Full per-shape recipe and wave-specific examples in the log.

### TelegramEngine.Resources facade inventory (as of wave 32)

All mediaBox methods with clean signatures (no Postbox-protocol leaks, no complex return-type migrations) have been migrated to `TelegramEngine.Resources`. Quick reference for consumers — all of these live in `submodules/TelegramCore/Sources/TelegramEngine/Resources/TelegramEngineResources.swift`:

| Facade | Wave | Wraps |
|---|---|---|
| `fetch(reference:userLocation:userContentType:)` | 3 | `fetchedMediaResource` |
| `status(resource:)` | 3 | `MediaBox.resourceStatus` (resource-based) |
| `status(id:, resourceSize:)` | 32 | `MediaBox.resourceStatus(_ id:, resourceSize:)` |
| `data(resource:, pathExtension:, waitUntilFetchStatus:)` | 3 | `MediaBox.resourceData` (resource-based) |
| `data(id:, attemptSynchronously:)` | 3 | `MediaBox.resourceData` (id-based, defaults to `.complete(waitUntilFetchStatus: false)`) |
| `custom(id:, fetch:, cacheTimeout:, attemptSynchronously:)` | pre-wave-21 | `MediaBox.customResourceData` |
| `httpData(url:, preserveExactUrl:)` | pre-wave-21 | `fetchHttpResource` |
| `shortLivedResourceCachePathPrefix(id:)` | 19 | `MediaBox.shortLivedResourceCachePathPrefix` |
| `completedResourcePath(id:, pathExtension:)` | 21 | `MediaBox.completedResourcePath(id:, pathExtension:)` |
| `storeResourceData(id:, data:, synchronous:)` | 22 | `MediaBox.storeResourceData(_ id:, data:, synchronous:)` |
| `cancelInteractiveResourceFetch(id:)` | 23 | `MediaBox.cancelInteractiveResourceFetch(resourceId:)` |
| `moveResourceData(id:, toTempPath:)` | 24 | `MediaBox.moveResourceData(_ id:, toTempPath:)` |
| `moveResourceData(from:, to:, synchronous:)` | 24 | `MediaBox.moveResourceData(from:, to:, synchronous:)` |
| `copyResourceData(id:, fromTempPath:)` | 25 | `MediaBox.copyResourceData(_ id:, fromTempPath:)` |
| `copyResourceData(from:, to:, synchronous:)` | 25 | `MediaBox.copyResourceData(from:, to:, synchronous:)` |
| `resourceRangesStatus(resource:)` | 26 | `MediaBox.resourceRangesStatus(_ resource:)` |
| `removeCachedResources(ids:, force:, notify:)` | 26 | `MediaBox.removeCachedResources(_ ids:, force:, notify:)` |

**Facade-shape convention:** all of these take `EngineMediaResource.Id` or `EngineMediaResource` (never raw `MediaResourceId`/`MediaResource`). Return types either don't leak Postbox (`Void`, `String`, `String?`, `Signal<RangeSet<Int64>, NoError>`, `Signal<Float, NoError>`) or wrap via TelegramCore type (`Signal<EngineMediaResource.ResourceData, NoError>`).

**Swift-stdlib-vs-third-party-module name collisions** (learned in wave 26): `RangeSet<Int64>` collides with Swift stdlib's `RangeSet` (iOS 18+ only). Fix: `import RangeSet` at the file top of any TelegramCore file that names `RangeSet` in a signature. `TelegramCore/BUILD` already depends on `//submodules/Utils/RangeSet:RangeSet`. Future facade additions in TelegramEngineResources.swift should re-check this if new signature types are introduced.
