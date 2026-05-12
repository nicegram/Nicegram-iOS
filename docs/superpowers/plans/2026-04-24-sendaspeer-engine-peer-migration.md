# Wave 35: `SendAsPeer.peer: Peer → EnginePeer` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the public field `SendAsPeer.peer` from the Postbox `Peer` protocol to the TelegramCore `EnginePeer` enum in a single atomic commit. Drops 3 `._asPeer()` bridges at construction sites, collapses 6 redundant `EnginePeer(peer.peer)` wraps, rewrites 1 `peer.peer as? TelegramChannel` downcast to an enum pattern, and adds `EnginePeer(channel)` wraps at 2 raw-`TelegramChannel` construction sites. No outflow `._asPeer()` bridges need to be added for this wave (unlike wave 34's `ContactListPeer.peer(peer:)` bridge).

**Architecture:** One atomic commit. The field-type change is necessarily atomic (half-migrated SendAsPeer doesn't compile), so all edits land together. TelegramCore's `_internal_*SendAsAvailablePeers` functions keep `import Postbox` — only `SendAsPeer`'s public surface changes. No new wrappers, no new typealiases. The manual `==` body is replaced with synthesized Equatable (EnginePeer is Equatable).

**Tech Stack:** Swift, Bazel build via Make.py wrapper. No tests — verification is build success + targeted grep checks.

**Spec:** `docs/superpowers/specs/2026-04-24-sendaspeer-engine-peer-migration-design.md`

---

## File Structure

**Modified files (7 expected — 1 TelegramCore + 6 consumer. Plus 2 "verify no-edit" files.)**

| File | Edit count | Category |
|---|---|---|
| `submodules/TelegramCore/Sources/TelegramEngine/Messages/SendAsPeers.swift` | ~7 spot edits (struct change + 4 constructor wraps + drop manual `==`) | α |
| `submodules/TelegramUI/Components/Chat/ChatSendAsContextMenu/Sources/ChatSendAsPeerListContextItem.swift` | ~5 (1 cast rewrite + 4 wrap drops) | γ |
| `submodules/TelegramUI/Sources/Chat/ChatControllerLoadDisplayNode.swift` | 3 (1 bridge-drop + 2 EnginePeer wraps on raw channel) | δ |
| `submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelComponent.swift` | 1 (bridge-drop) | δ |
| `submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelNode.swift` | 1 (wrap collapse) | δ |
| `submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerViewSendMessage.swift` | ~4 (1 bridge-drop + 1 flatMap simplify + 1 map simplify) | δ |

**Verify-only (no edits expected):**
| File | Reason |
|---|---|
| `submodules/ChatPresentationInterfaceState/Sources/ChatPresentationInterfaceState.swift` | Holds `[SendAsPeer]?` at collection level, no `.peer` access. |
| `submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerComponent.swift` | Passes `currentSendAsPeer` through to `ChatSendAsPeerListContextItem` which keeps taking `[SendAsPeer]`. |

**EnginePeer enum case mapping (used in cast rewrite):**

| Postbox concrete | EnginePeer case |
|---|---|
| `TelegramChannel` | `.channel(TelegramChannel)` |
| `TelegramGroup` | `.legacyGroup(TelegramGroup)` |
| `TelegramUser` | `.user(TelegramUser)` |

---

## Task 1: Edit `SendAsPeers.swift` — struct definition + constructor wraps

**Files:**
- Modify: `submodules/TelegramCore/Sources/TelegramEngine/Messages/SendAsPeers.swift`

Foundational change. Without it, none of the consumer edits compile.

- [ ] **Step 1.1: Update the SendAsPeer struct field, init parameter, and drop manual `==`**

Edit:

```swift
// OLD
public struct SendAsPeer: Equatable {
    public let peer: Peer
    public let subscribers: Int32?
    public let isPremiumRequired: Bool
    
    public init(peer: Peer, subscribers: Int32?, isPremiumRequired: Bool) {
        self.peer = peer
        self.subscribers = subscribers
        self.isPremiumRequired = isPremiumRequired
    }
    
    public static func ==(lhs: SendAsPeer, rhs: SendAsPeer) -> Bool {
        return lhs.peer.isEqual(rhs.peer) && lhs.subscribers == rhs.subscribers && lhs.isPremiumRequired == rhs.isPremiumRequired
    }
}
```

```swift
// NEW
public struct SendAsPeer: Equatable {
    public let peer: EnginePeer
    public let subscribers: Int32?
    public let isPremiumRequired: Bool
    
    public init(peer: EnginePeer, subscribers: Int32?, isPremiumRequired: Bool) {
        self.peer = peer
        self.subscribers = subscribers
        self.isPremiumRequired = isPremiumRequired
    }
}
```

Use the Edit tool with the OLD block as `old_string` and the NEW block as `new_string`. Swift synthesizes Equatable for structs where every stored property is Equatable: `EnginePeer` is Equatable, `Int32?` is Equatable, `Bool` is Equatable — so the manual `==` is no longer needed.

- [ ] **Step 1.2: Wrap raw Postbox `Peer` values at the four constructor sites**

Sites at lines 64, 170, 236, 330. Each binds a raw Postbox `Peer` (from `transaction.getPeer(peerId)` or `peers.map { ... }`) and passes it to the `SendAsPeer(peer: ...)` init. Wrap each with `EnginePeer(...)`.

Edit (line 64, inside `_internal_cachedPeerSendAsAvailablePeers`, cache-hit branch):

```swift
// OLD
                    peers.append(SendAsPeer(peer: peer, subscribers: subscribers, isPremiumRequired: cached.premiumRequiredPeerIds.contains(peer.id)))
```

```swift
// NEW
                    peers.append(SendAsPeer(peer: EnginePeer(peer), subscribers: subscribers, isPremiumRequired: cached.premiumRequiredPeerIds.contains(peer.id)))
```

Edit (line 170, inside `_internal_peerSendAsAvailablePeers`, network-response map):

```swift
// OLD
                    return peers.map { SendAsPeer(peer: $0, subscribers: subscribers[$0.id], isPremiumRequired: premiumRequiredPeerIds.contains($0.id)) }
```

```swift
// NEW
                    return peers.map { SendAsPeer(peer: EnginePeer($0), subscribers: subscribers[$0.id], isPremiumRequired: premiumRequiredPeerIds.contains($0.id)) }
```

Edit (line 236, inside `_internal_cachedLiveStorySendAsAvailablePeers`, cache-hit branch):

```swift
// OLD
                    peers.append(SendAsPeer(peer: peer, subscribers: subscribers, isPremiumRequired: cached.premiumRequiredPeerIds.contains(peer.id)))
```

```swift
// NEW
                    peers.append(SendAsPeer(peer: EnginePeer(peer), subscribers: subscribers, isPremiumRequired: cached.premiumRequiredPeerIds.contains(peer.id)))
```

Note: lines 64 and 236 have identical text. If you prefer `replace_all=true`, do a grep first to confirm the count is exactly 2, then apply once.

Edit (line 330, inside `_internal_liveStorySendAsAvailablePeers`, network-response map):

```swift
// OLD
                    return peers.map { SendAsPeer(peer: $0, subscribers: subscribers[$0.id], isPremiumRequired: premiumRequiredPeerIds.contains($0.id)) }
```

```swift
// NEW
                    return peers.map { SendAsPeer(peer: EnginePeer($0), subscribers: subscribers[$0.id], isPremiumRequired: premiumRequiredPeerIds.contains($0.id)) }
```

Same remark as above: lines 170 and 330 are identical — one `replace_all=true` covers both if the count is exactly 2.

- [ ] **Step 1.3: Verify** — read the updated file and confirm:
    - The struct's `peer` field is now `EnginePeer`
    - The init parameter is `peer: EnginePeer`
    - Manual `==` has been removed
    - All 4 constructor sites wrap with `EnginePeer(...)`
    - `peer.peer.id` accesses inside the caching loops (lines 87, 90, 259, 262) remain unchanged (`EnginePeer.id` typealias to `PeerId` keeps them valid)

Do not commit yet.

---

## Task 2: Edit `ChatSendAsPeerListContextItem.swift` — cast rewrite + wrap collapse

**Files:**
- Modify: `submodules/TelegramUI/Components/Chat/ChatSendAsContextMenu/Sources/ChatSendAsPeerListContextItem.swift`

1 Postbox-concrete downcast rewrite + 4 `EnginePeer(peer.peer)` wrap drops.

- [ ] **Step 2.1: Rewrite the `peer.peer as? TelegramChannel` downcast at line 73**

Edit:

```swift
// OLD
                } else if let subscribers = peer.subscribers {
                    if let peer = peer.peer as? TelegramChannel {
                        if case .broadcast = peer.info {
```

```swift
// NEW
                } else if let subscribers = peer.subscribers {
                    if case let .channel(channel) = peer.peer {
                        if case .broadcast = channel.info {
```

Note: the original `if let peer = peer.peer as? TelegramChannel` shadows the outer `peer: SendAsPeer` loop variable. The rewrite uses `channel` to avoid shadowing. Any subsequent uses of `peer.info`, `peer.flags`, etc. inside the inner `if let peer = ...` block must be renamed to `channel.*`.

Read lines 70–90 before editing to see the full extent of the shadowed-`peer` scope, and ensure every reference to `peer.info` (and any sibling field access like `peer.flags`, `peer.username`, etc.) within the inner block is rewritten to `channel.*`. The snippet above captures the only `peer.info` site from the inventory.

- [ ] **Step 2.2: Drop `EnginePeer(peer.peer)` wraps at lines 89, 110, 116, 121**

The field `peer.peer` is now `EnginePeer`, so `EnginePeer(peer.peer)` becomes a type error. Drop the wrap.

Read the full lines first to confirm each site's shape. Expected patterns (edit one at a time with enough surrounding context to make each unique — the four sites likely differ in surrounding tokens):

For each of the four sites, the pattern to eliminate is `EnginePeer(peer.peer)` → `peer.peer`. Example:

```swift
// OLD
                    let title = EnginePeer(peer.peer).displayTitle(strings: strings, displayOrder: nameDisplayOrder)
```

```swift
// NEW
                    let title = peer.peer.displayTitle(strings: strings, displayOrder: nameDisplayOrder)
```

Identify each of the four sites (lines 89, 110, 116, 121) by reading the file, then apply one Edit per site using enough surrounding context (usually 1–2 tokens before/after the `EnginePeer(peer.peer)` subexpression) to make the `old_string` unique.

If all four lines reduce to the same substring pattern (e.g., `EnginePeer(peer.peer)` as a standalone subexpression), `replace_all=true` on the substring `EnginePeer(peer.peer)` → `peer.peer` is safe — but **first** grep to confirm the count is exactly 4 and no other meaning is captured.

Run before: `grep -cE "EnginePeer\(peer\.peer\)" submodules/TelegramUI/Components/Chat/ChatSendAsContextMenu/Sources/ChatSendAsPeerListContextItem.swift`

Expected: 4.

- [ ] **Step 2.3: Verify** — grep:

Run: `grep -nE "peer\.peer\s+(as\?|is)\s+Telegram|EnginePeer\(peer\.peer\)" submodules/TelegramUI/Components/Chat/ChatSendAsContextMenu/Sources/ChatSendAsPeerListContextItem.swift`

Expected: zero matches.

---

## Task 3: Edit `ChatControllerLoadDisplayNode.swift` — bridge-drop + raw-channel wraps

**Files:**
- Modify: `submodules/TelegramUI/Sources/Chat/ChatControllerLoadDisplayNode.swift`

1 `._asPeer()` bridge-drop at line 772 + 2 `EnginePeer(channel)` wraps for raw `TelegramChannel` at lines 805 and 823.

- [ ] **Step 3.1: Bridge-drop at line 772**

Edit:

```swift
// OLD
                        return SendAsPeer(peer: peer._asPeer(), subscribers: nil, isPremiumRequired: false)
```

```swift
// NEW
                        return SendAsPeer(peer: peer, subscribers: nil, isPremiumRequired: false)
```

Verification: the surrounding signal chain binds `peer` as `EnginePeer` (from `context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: ...))`). The `._asPeer()` bridge is no longer needed.

If the line text differs from the OLD block above (e.g., different field order or trailing arguments), read the file around line 772 and adjust the `old_string` to match byte-for-byte before editing.

- [ ] **Step 3.2: Wrap raw `TelegramChannel` at line 805**

Read lines 800–812 to see the bound `channel` variable. The construction site should be `SendAsPeer(peer: channel, ...)` where `channel: TelegramChannel` is raw Postbox.

Edit:

```swift
// OLD
                    SendAsPeer(peer: channel, subscribers: subscribers, isPremiumRequired: isPremiumRequired)
```

```swift
// NEW
                    SendAsPeer(peer: EnginePeer(channel), subscribers: subscribers, isPremiumRequired: isPremiumRequired)
```

If the surrounding context differs (different field values), match the actual line text when writing `old_string`.

- [ ] **Step 3.3: Wrap raw `TelegramChannel` at line 823**

Same pattern as Step 3.2. Read lines 818–830 first, identify the `SendAsPeer(peer: channel, ...)` construction site, and wrap `channel` with `EnginePeer(...)`.

If the line text at 805 and 823 is identical, `replace_all=true` on the substring `SendAsPeer(peer: channel,` → `SendAsPeer(peer: EnginePeer(channel),` covers both. **First** grep to confirm the count:

Run before: `grep -cE "SendAsPeer\(peer: channel," submodules/TelegramUI/Sources/Chat/ChatControllerLoadDisplayNode.swift`

Expected: 2.

- [ ] **Step 3.4: Verify** — grep:

Run: `grep -nE "SendAsPeer\(peer:\s+\w+\._asPeer\(\)|SendAsPeer\(peer:\s+channel," submodules/TelegramUI/Sources/Chat/ChatControllerLoadDisplayNode.swift`

Expected: zero matches. Lines 792, 826, 835, 844 retaining `.peer.id` accesses are expected and correct.

---

## Task 4: Edit `ChatTextInputPanelComponent.swift` — bridge-drop

**Files:**
- Modify: `submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelComponent.swift`

1 `._asPeer()` bridge-drop.

- [ ] **Step 4.1: Bridge-drop at line 847**

Read lines 843–853 to confirm the surrounding signal chain and the type of `sendAsConfiguration.currentPeer` (expected: `EnginePeer`).

Edit:

```swift
// OLD
                    let sendAsPeers = [SendAsPeer(peer: sendAsConfiguration.currentPeer._asPeer(), subscribers: nil, isPremiumRequired: false)]
```

```swift
// NEW
                    let sendAsPeers = [SendAsPeer(peer: sendAsConfiguration.currentPeer, subscribers: nil, isPremiumRequired: false)]
```

If the actual line text wraps across multiple lines or uses different field values, match the real text byte-for-byte when writing `old_string`.

- [ ] **Step 4.2: Verify** — grep:

Run: `grep -nE "SendAsPeer\(peer:.*\._asPeer\(\)" submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelComponent.swift`

Expected: zero matches.

---

## Task 5: Edit `ChatTextInputPanelNode.swift` — wrap collapse

**Files:**
- Modify: `submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelNode.swift`

1 `EnginePeer(peer)` wrap collapse at line 1625.

- [ ] **Step 5.1: Collapse `EnginePeer(peer)` wrap**

Read lines 1615–1630 to see the full context. `peer` is bound from a preceding `var currentPeer = sendAsPeers.first(where: { $0.peer.id == ... })?.peer` (lines 1620–1622). After migration, `.peer` returns `EnginePeer`, so `EnginePeer(peer)` on an `EnginePeer` is a type error.

Exact edit depends on the actual line text. Example shape:

```swift
// OLD  (at or near line 1625)
                    let enginePeer = EnginePeer(peer)
```

```swift
// NEW
                    let enginePeer = peer
```

Read lines 1623–1628 first and write the Edit with byte-accurate `old_string`. If the bound variable is then used as `enginePeer.displayTitle(...)`, consider whether the rename can be eliminated entirely (e.g., rename `peer` uses downstream), but prefer the minimal edit for commit clarity.

Lines 1616, 1620, 1622, 2948, 5370 should remain unchanged — they perform `.peer.id` comparisons or `.first(where:)` lookups that work identically on `[SendAsPeer]` with `EnginePeer`-typed `.peer`.

- [ ] **Step 5.2: Verify** — grep:

Run: `grep -nE "EnginePeer\(peer\)" submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelNode.swift`

Expected: zero matches. If any remain, inspect each — they may be unrelated wraps on non-SendAsPeer-sourced `peer` variables (in which case they must stay).

---

## Task 6: Edit `StoryItemSetContainerViewSendMessage.swift` — multi-site cleanup

**Files:**
- Modify: `submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerViewSendMessage.swift`

1 bridge-drop + 1 flatMap simplify + 1 map simplify. Many other `.peer.id` / `.peer` accesses remain unchanged.

- [ ] **Step 6.1: Bridge-drop at line 249**

Read lines 244–254 to confirm `accountPeer` is typed as `EnginePeer` upstream.

Edit:

```swift
// OLD
                    availablePeers.append(SendAsPeer(
                        peer: accountPeer._asPeer(),
                        subscribers: nil,
                        isPremiumRequired: false
                    ))
```

```swift
// NEW
                    availablePeers.append(SendAsPeer(
                        peer: accountPeer,
                        subscribers: nil,
                        isPremiumRequired: false
                    ))
```

If the actual layout (whitespace, line breaks) differs from the OLD block, match the real text byte-for-byte when writing `old_string`.

- [ ] **Step 6.2: Simplify flatMap at line 4080**

`EnginePeer.init` as a function reference expects a raw `Peer` and returns `EnginePeer`. After migration, `sendAsPeer?.peer` is already `EnginePeer?`, so `.flatMap(EnginePeer.init)` is both unnecessary and a type error.

Edit:

```swift
// OLD
                myPeer: (sendAsPeer?.peer).flatMap(EnginePeer.init),
```

```swift
// NEW
                myPeer: sendAsPeer?.peer,
```

Read lines 4078–4082 first to confirm the surrounding labeled-argument layout and match byte-for-byte.

- [ ] **Step 6.3: Simplify map at line 4081**

`.map({ EnginePeer($0.peer) })` wraps each already-`EnginePeer` value in `EnginePeer(...)` — a type error. Drop the wrap.

Edit:

```swift
// OLD
                availableSendAsPeers: component.isEmbeddedInCamera ? [] : (self.sendAsData?.availablePeers.map({ EnginePeer($0.peer) }) ?? []),
```

```swift
// NEW
                availableSendAsPeers: component.isEmbeddedInCamera ? [] : (self.sendAsData?.availablePeers.map({ $0.peer }) ?? []),
```

Read lines 4079–4083 first to confirm the exact line text.

- [ ] **Step 6.4: Verify** — grep:

Run: `grep -nE "SendAsPeer\(peer:.*\._asPeer\(\)|EnginePeer\(\$0\.peer\)|\(sendAsPeer\?\.peer\)\.flatMap\(EnginePeer\.init\)" submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerViewSendMessage.swift`

Expected: zero matches.

Retained-as-is accesses (inventory-verified correct after migration): `.peer.id` at lines 254, 688, 4088, 4089, 4327, 4333, 4340, 4356, 4372; optional chaining at 4050, 4068, 4069. These should NOT be edited.

---

## Task 7: Verify "no-edit" consumer files

**Files:**
- Read: `submodules/ChatPresentationInterfaceState/Sources/ChatPresentationInterfaceState.swift`
- Read: `submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerComponent.swift`

Sanity-check: confirm neither file contains `.peer as?`/`is`, `EnginePeer(.peer)`, or `._asPeer()` patterns tied to SendAsPeer. If any such pattern is found, fold the fix into the relevant task above before the build pass.

- [ ] **Step 7.1: Grep ChatPresentationInterfaceState.swift**

Run: `grep -nE "SendAsPeer|sendAsPeers" submodules/ChatPresentationInterfaceState/Sources/ChatPresentationInterfaceState.swift`

Expected shape: field declaration, init param, assignment, equality comparison, `updatedSendAsPeers(_:)` method — all at the `[SendAsPeer]?` collection level. No `.peer` field access.

- [ ] **Step 7.2: Grep StoryItemSetContainerComponent.swift**

Run: `grep -nE "SendAsPeer|currentSendAsPeer|\.peer\b" submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerComponent.swift | grep -iE "sendAsPeer|\.peer"`

Read lines 3056–3072 to confirm `sendMessageContext.currentSendAsPeer` is only passed through to `ChatSendAsPeerListContextItem` (which keeps `[SendAsPeer]`) or accessed for `.peer.id` comparisons — neither requires an edit.

If the verification shows an edit is needed, add the edit as an additional step under the relevant Task 2–6. Do not edit here silently.

---

## Task 8: Build verification (first pass)

- [ ] **Step 8.1: Run the full build with `--continueOnError`**

Run:

```bash
source ~/.zshrc 2>/dev/null && python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 --configuration=debug_sim_arm64 --continueOnError 2>&1 | tee /tmp/wave35-build.log
```

Expected outcome: ideally clean. Realistic outcome: 0–5 errors at sites the inventory missed.

- [ ] **Step 8.2: Triage build errors**

Likely error patterns and their fixes:

| Error | Fix |
|---|---|
| `cannot convert value of type 'EnginePeer' to expected argument type 'Peer'` at site passing `peer.peer` | Add `._asPeer()` bridge: `peer.peer._asPeer()` |
| `cannot convert value of type 'Peer' to expected argument type 'EnginePeer'` at `SendAsPeer(peer: ...)` | Add wrap: `SendAsPeer(peer: EnginePeer(<raw>), ...)` |
| `value of type 'EnginePeer' has no member 'isEqual'` | Replace with `==` |
| `pattern of type 'TelegramChannel' cannot match values of type 'EnginePeer'` | Missed C2 — rewrite to `if case .channel(let channel) = peer.peer` form |
| `cannot invoke initializer for type 'EnginePeer' with an argument list of type '(EnginePeer)'` | Missed wrap collapse — drop `EnginePeer(...)` |
| `extraneous argument label 'peer:' in call` or similar on `SendAsPeer(...)` | Check that the construction arg is `EnginePeer`, not raw — add `EnginePeer(...)` wrap |

For each error, identify the file:line, apply the appropriate fix, and re-run the build until clean.

- [ ] **Step 8.3: Iterate to clean build**

Re-run the build after each batch of fixes. The wave is complete when the build returns 0 errors for the targeted configuration.

If 10+ unexpected errors surface, halt and reassess: the inventory was significantly incomplete and the wave may need to be split into pre-cleanup commits. Discuss with user before continuing.

---

## Task 9: Post-build grep validations

- [ ] **Step 9.1: Bridge-drop validation**

Run:

```bash
grep -rn "SendAsPeer(peer:.*\._asPeer()" submodules/ --include="*.swift" | grep -v "^submodules/TelegramCore/" | grep -v "^submodules/Postbox/"
```

Expected: zero hits. If any remain, those are missed bridge-drops — fix and re-run Task 8.

- [ ] **Step 9.2: Wrap-collapse validation**

Run:

```bash
for f in submodules/TelegramUI/Components/Chat/ChatSendAsContextMenu/Sources/ChatSendAsPeerListContextItem.swift \
         submodules/TelegramUI/Sources/Chat/ChatControllerLoadDisplayNode.swift \
         submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelComponent.swift \
         submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelNode.swift \
         submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerViewSendMessage.swift; do
  echo "=== $f ==="
  grep -nE "EnginePeer\(peer\.peer\)|EnginePeer\(\$0\.peer\)|\(sendAsPeer\?\.peer\)\.flatMap\(EnginePeer\.init\)" "$f"
done
```

Expected: zero hits across all 5 files.

- [ ] **Step 9.3: C2 cast validation**

Run:

```bash
grep -nE "peer\.peer\s+(as\?|is)\s+Telegram" submodules/TelegramUI/Components/Chat/ChatSendAsContextMenu/Sources/ChatSendAsPeerListContextItem.swift
```

Expected: zero hits.

- [ ] **Step 9.4: Construction-site validation**

Ensure all `SendAsPeer(peer: ...)` construction sites outside TelegramCore provide `EnginePeer`:

```bash
grep -rnE "SendAsPeer\(peer:" submodules/ --include="*.swift" | grep -v "^submodules/TelegramCore/"
```

Inspect each hit. Expected forms: `SendAsPeer(peer: <engine-peer-expr>, ...)` or `SendAsPeer(peer: EnginePeer(<raw>), ...)`. Anything of the form `SendAsPeer(peer: <raw-Peer>, ...)` is a miss — fix.

If any of the validations fail, return to Task 8 to fix.

---

## Task 10: Atomic commit + memory + log update

- [ ] **Step 10.1: Stage and review**

Run:

```bash
git status --short
git diff --stat
```

Confirm exactly 6 modified Swift files (1 TelegramCore + 5 consumer — or 7 if Task 7 surfaced a needed edit). Files expected:
- `submodules/TelegramCore/Sources/TelegramEngine/Messages/SendAsPeers.swift`
- `submodules/TelegramUI/Components/Chat/ChatSendAsContextMenu/Sources/ChatSendAsPeerListContextItem.swift`
- `submodules/TelegramUI/Sources/Chat/ChatControllerLoadDisplayNode.swift`
- `submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelComponent.swift`
- `submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelNode.swift`
- `submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerViewSendMessage.swift`

WIP from earlier (`build-system/bazel-rules/sourcekit-bazel-bsp`, `ChatListFilterPresetController.swift`, `ChatListFilterPresetListController.swift`, untracked `build-system/tulsi/` / `submodules/TgVoip/` / `third-party/libx264/`) should NOT be staged.

The `docs/superpowers/plans/2026-04-22-claude-md-reorganization.md` untracked file should ALSO remain unstaged.

- [ ] **Step 10.2: Stage only the wave-35 files**

Run:

```bash
git add submodules/TelegramCore/Sources/TelegramEngine/Messages/SendAsPeers.swift \
        submodules/TelegramUI/Components/Chat/ChatSendAsContextMenu/Sources/ChatSendAsPeerListContextItem.swift \
        submodules/TelegramUI/Sources/Chat/ChatControllerLoadDisplayNode.swift \
        submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelComponent.swift \
        submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelNode.swift \
        submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerViewSendMessage.swift
```

If Task 7 surfaced an additional file, append it here.

- [ ] **Step 10.3: Commit**

Run:

```bash
git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 35: SendAsPeer.peer Peer -> EnginePeer

Migrates the public field `SendAsPeer.peer` from the Postbox `Peer`
protocol to the TelegramCore `EnginePeer` enum. Internal
`_internal_*SendAsAvailablePeers` bodies keep `import Postbox` (they still
call `postbox.transaction`) and wrap raw peer values with `EnginePeer(peer)`
at the SendAsPeer constructor sites. Manual `==` body dropped in favor of
synthesized Equatable.

Consumer-side cascade in 5 files:
  - 3 `._asPeer()` bridge-drops at SendAsPeer constructor sites
  - 6 redundant `EnginePeer(peer.peer)` / `EnginePeer($0.peer)` wrap
    drops (the field is now EnginePeer, so the wrap fails to compile)
  - 1 `peer.peer as? TelegramChannel` downcast rewritten to
    `if case let .channel(channel) = peer.peer` enum-pattern form
  - 2 `EnginePeer(channel)` wraps added where raw `TelegramChannel` is
    passed into `SendAsPeer(peer: ...)`
  - 1 `(sendAsPeer?.peer).flatMap(EnginePeer.init)` simplified to
    `sendAsPeer?.peer` (already `EnginePeer?`)

Files modified:
  submodules/TelegramCore/Sources/TelegramEngine/Messages/SendAsPeers.swift
  submodules/TelegramUI/Components/Chat/ChatSendAsContextMenu/Sources/ChatSendAsPeerListContextItem.swift
  submodules/TelegramUI/Sources/Chat/ChatControllerLoadDisplayNode.swift
  submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelComponent.swift
  submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelNode.swift
  submodules/TelegramUI/Components/Stories/StoryContainerScreen/Sources/StoryItemSetContainerViewSendMessage.swift

Plan: docs/superpowers/plans/2026-04-24-sendaspeer-engine-peer-migration.md
Spec: docs/superpowers/specs/2026-04-24-sendaspeer-engine-peer-migration-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 10.4: Update CLAUDE.md wave counter**

Edit `CLAUDE.md` to bump the "Waves landed so far" line from "34 waves" to "35 waves" and update the "as of" date if the commit lands after 2026-04-24.

- [ ] **Step 10.5: Append wave outcome to the postbox-refactor-log**

Append a "Wave 35 outcome" section to `docs/superpowers/postbox-refactor-log.md` documenting:
- Actual files touched and edit counts vs. plan
- Any inventory undercounts surfaced by Task 8
- Any lessons learned (e.g., whether the flatMap/map simplifications were actually type-required or whether they could have been left as redundant-but-compiling wraps)

Keep concise.

- [ ] **Step 10.6: Commit the docs update**

Run:

```bash
git add CLAUDE.md docs/superpowers/postbox-refactor-log.md
git commit -m "$(cat <<'EOF'
docs: add wave 35 outcome (SendAsPeer.peer Peer→EnginePeer)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 10.7: Update the next-wave memory**

Update `/Users/isaac/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`:
- Add wave 35 to the "Latest commits" section
- Move SendAsPeer migration from "Wave 34+ candidates → Downstream Peer-typed APIs" to landed
- Record the inventory undercount ratio (actual-files-touched ÷ pre-flight-file-count) for calibration of future Peer-typed-API waves
- Update the "Recommended wave 35" section to reflect the new wave 36 recommendation. Candidates to promote: `makePeerInfoController` (largest Peer-typed-API remaining), `ContactListPeer.peer(peer:)` case payload, `canSendMessagesToPeer(_:)` parameter, accountManager-side engine path, Shape-C resourceData module pick

Use the Edit tool on the memory file. No git commit needed (memory lives outside the repo).

---

## Risks and notes

- **Inner `peer` shadowing in ChatSendAsPeerListContextItem:73.** The original `if let peer = peer.peer as? TelegramChannel` shadows the outer `peer: SendAsPeer` loop variable. The rewrite uses `channel` to avoid shadowing. Verify every reference to `peer.info` (and any sibling field access) within the old inner-if scope is updated to `channel.*` — Step 2.1's instructions cover this, but it's easy to miss a field reference.
- **`replace_all` correctness.** Whenever the plan suggests `replace_all=true`, verify the count first via grep. If the count is unexpected, revert to per-site Edits with surrounding context.
- **Inventory undercount.** Wave 34 undercounted by ~30%. The Explore agent for wave 35 explicitly included `.peer as?`/`is`/outflow-helper patterns, so the expected ratio is lower, but budget for 1–3 inventory-missed sites surfacing in Task 8.
- **Name collisions (do NOT touch).** `[EnginePeer]` arrays in `LiveStreamSettingsScreen.swift`, `ShareWithPeersScreen.swift`, and `ChatSendStarsScreen.swift` named `sendAsPeers` / `availableSendAsPeers` are unrelated. `ChatPanelInterfaceInteraction` callbacks named `openSendAsPeer` take `(ASDisplayNode, ContextGesture?)`, not `SendAsPeer`. `initialSendAsPeerId` parameters are `PeerId`-typed. If Task 8 surfaces errors in any of these files, the fix likely indicates a wrong cascade from a real SendAsPeer site — do NOT migrate those files as part of this wave.
- **WIP isolation.** Pre-existing modifications to `ChatListFilterPresetController.swift`, `ChatListFilterPresetListController.swift`, the `sourcekit-bazel-bsp` submodule marker, and untracked `build-system/tulsi/` / `submodules/TgVoip/` / `third-party/libx264/` / `docs/superpowers/plans/2026-04-22-claude-md-reorganization.md` are user WIP — do NOT stage them. Use the explicit `git add <files>` form in Step 10.2.
