# Wave 40 — `makeChatQrCodeScreen` + `makeChatRecentActionsController` Peer → EnginePeer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bundle migrate two sibling `AccountContext` methods deferred from wave 39 — `makeChatQrCodeScreen` (4 consumer sites) and `makeChatRecentActionsController` (3 consumer sites) — from raw `peer: Peer` to `peer: EnginePeer`, applying the body-shadow pattern.

**Architecture:** Body-shadow pattern (wave-38/39 style). Protocol + impl signatures change to `peer: EnginePeer`; each impl body gets a `let peer = peer._asPeer()` shadow so the downstream constructors (`ChatQrCodeScreenImpl`, `ChatRecentActionsController`) remain raw-`Peer` consumers (out of scope).

**Tech Stack:** Swift, Bazel, iOS; TelegramCore / AccountContext / TelegramUI / PeerInfoUI / StatisticsUI / SettingsUI / ContactListUI / PeerInfoScreen submodules.

**Reference:** Wave-39 "Out of scope" section in `docs/superpowers/specs/2026-04-24-makePeerInfoController-engine-peer-migration-design.md`.

---

## Pre-flight classification

**`makeChatQrCodeScreen` (4 consumer sites):**

| # | Site | Shape | Edit |
|---|---|---|---|
| 1 | `SettingsSearchableItems.swift:974` | **Shape-A-variant** | Rewrite upstream `guard let peer = peer?._asPeer() else { return }` (line 971) → `guard let peer = peer else { return }`. Call stays `peer: peer`. |
| 2 | `SettingsSearchableItems.swift:992` | **Shape-A-variant** | Same pattern as #1 (upstream guard at line 989). |
| 3 | `ContactsController.swift:478` | **Shape-A** | Drop `._asPeer()` from `peer: peer._asPeer()` → `peer: peer`. Source: `Signal<EnginePeer, NoError>`. |
| 4 | `PeerInfoScreen.swift:4623` | **Shape-C** | Wrap: `peer: peer` → `peer: EnginePeer(peer)`. Source: `data.peer: Peer?`. |

**`makeChatRecentActionsController` (3 consumer sites):**

| # | Site | Shape | Edit |
|---|---|---|---|
| 5 | `ChannelAdminsController.swift:734` | **Shape-A** | Drop `._asPeer()`. Source: `engine.data.get(Peer.Peer(id:))` — `peer` is `EnginePeer` in the `guard let peer` on line 729. |
| 6 | `GroupStatsController.swift:915` | **Shape-A** | Drop `._asPeer()`. Source: `Signal<EnginePeer, NoError>` (mapToSignal at 906). |
| 7 | `PeerInfoScreenOpenChat.swift:115` | **Shape-C** | Wrap: `peer: peer` → `peer: EnginePeer(peer)`. Source: `self.data?.peer: Peer?`. |

**Net bridge delta:** −5 `_asPeer()` drops (sites 1, 2, 3, 5, 6) + 2 `EnginePeer(...)` wraps (sites 4, 7) = **−3 net**. Sites 4 and 7 become ratchet markers for a future `PeerInfoScreenData.peer Peer → EnginePeer` wave.

---

## File touch summary

8 files:

1. `submodules/AccountContext/Sources/AccountContext.swift` — protocol decls (2 lines).
2. `submodules/TelegramUI/Sources/SharedAccountContext.swift` — impl signatures + body shadows (2 sites).
3. `submodules/SettingsUI/Sources/Search/SettingsSearchableItems.swift` — 2 Shape-A-variant upstream guard rewrites.
4. `submodules/ContactListUI/Sources/ContactsController.swift` — 1 Shape-A drop.
5. `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift` — 1 Shape-C wrap.
6. `submodules/PeerInfoUI/Sources/ChannelAdminsController.swift` — 1 Shape-A drop.
7. `submodules/StatisticsUI/Sources/GroupStatsController.swift` — 1 Shape-A drop.
8. `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenOpenChat.swift` — 1 Shape-C wrap.

---

### Task 1: Update `AccountContext` protocol signatures

**Files:**
- Modify: `submodules/AccountContext/Sources/AccountContext.swift:1401` and `:1461`

- [ ] **Step 1: Update `makeChatRecentActionsController` decl**

```swift
// old_string
    func makeChatRecentActionsController(context: AccountContext, peer: Peer, adminPeerId: PeerId?, starsState: StarsRevenueStats?) -> ViewController

// new_string
    func makeChatRecentActionsController(context: AccountContext, peer: EnginePeer, adminPeerId: PeerId?, starsState: StarsRevenueStats?) -> ViewController
```

- [ ] **Step 2: Update `makeChatQrCodeScreen` decl**

```swift
// old_string
    func makeChatQrCodeScreen(context: AccountContext, peer: Peer, threadId: Int64?, temporary: Bool) -> ViewController

// new_string
    func makeChatQrCodeScreen(context: AccountContext, peer: EnginePeer, threadId: Int64?, temporary: Bool) -> ViewController
```

---

### Task 2: Update `SharedAccountContext` impls with body-shadow

**Files:**
- Modify: `submodules/TelegramUI/Sources/SharedAccountContext.swift:2302` (makeChatRecentActionsController)
- Modify: `submodules/TelegramUI/Sources/SharedAccountContext.swift:2730` (makeChatQrCodeScreen)

- [ ] **Step 1: Update `makeChatRecentActionsController` impl**

```swift
// old_string
    public func makeChatRecentActionsController(context: AccountContext, peer: Peer, adminPeerId: PeerId?, starsState: StarsRevenueStats?) -> ViewController {
        return ChatRecentActionsController(context: context, peer: peer, adminPeerId: adminPeerId, starsState: starsState)
    }

// new_string
    public func makeChatRecentActionsController(context: AccountContext, peer: EnginePeer, adminPeerId: PeerId?, starsState: StarsRevenueStats?) -> ViewController {
        let peer = peer._asPeer()
        return ChatRecentActionsController(context: context, peer: peer, adminPeerId: adminPeerId, starsState: starsState)
    }
```

- [ ] **Step 2: Update `makeChatQrCodeScreen` impl**

```swift
// old_string
    public func makeChatQrCodeScreen(context: AccountContext, peer: Peer, threadId: Int64?, temporary: Bool) -> ViewController {
        return ChatQrCodeScreenImpl(context: context, subject: .peer(peer: peer, threadId: threadId, temporary: temporary))
    }

// new_string
    public func makeChatQrCodeScreen(context: AccountContext, peer: EnginePeer, threadId: Int64?, temporary: Bool) -> ViewController {
        let peer = peer._asPeer()
        return ChatQrCodeScreenImpl(context: context, subject: .peer(peer: peer, threadId: threadId, temporary: temporary))
    }
```

---

### Task 3: `SettingsSearchableItems.swift` — two Shape-A-variant guard rewrites

**Files:**
- Modify: `submodules/SettingsUI/Sources/Search/SettingsSearchableItems.swift:971` and `:989`

Both sites share the same structure: an upstream `guard let peer = peer?._asPeer() else { return }` unwraps `EnginePeer?` to `Peer`. Rewrite the guard to keep the local as `EnginePeer`; the call site below stays unchanged.

- [ ] **Step 1: Rewrite guard at line 971 (qr-code item)**

```swift
// old_string
            present: { context, _, present in
                let _ = (context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: context.account.peerId))
                |> deliverOnMainQueue).start(next: { peer in
                    guard let peer = peer?._asPeer() else {
                        return
                    }
                    let controller = context.sharedContext.makeChatQrCodeScreen(context: context, peer: peer, threadId: nil, temporary: false)
                    present(.push, controller)
                })
            }
        )
    )
    
    //TODO:fix
    items.append(
        SettingsSearchableItem(
            id: "qr-code/share",

// new_string
            present: { context, _, present in
                let _ = (context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: context.account.peerId))
                |> deliverOnMainQueue).start(next: { peer in
                    guard let peer = peer else {
                        return
                    }
                    let controller = context.sharedContext.makeChatQrCodeScreen(context: context, peer: peer, threadId: nil, temporary: false)
                    present(.push, controller)
                })
            }
        )
    )
    
    //TODO:fix
    items.append(
        SettingsSearchableItem(
            id: "qr-code/share",
```

- [ ] **Step 2: Rewrite guard at line 989 (qr-code/share item)**

```swift
// old_string
            id: "qr-code/share",
            isVisible: false,
            present: { context, _, present in
                let _ = (context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: context.account.peerId))
                |> deliverOnMainQueue).start(next: { peer in
                    guard let peer = peer?._asPeer() else {
                        return
                    }
                    let controller = context.sharedContext.makeChatQrCodeScreen(context: context, peer: peer, threadId: nil, temporary: false)
                    present(.push, controller)
                })
            }

// new_string
            id: "qr-code/share",
            isVisible: false,
            present: { context, _, present in
                let _ = (context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: context.account.peerId))
                |> deliverOnMainQueue).start(next: { peer in
                    guard let peer = peer else {
                        return
                    }
                    let controller = context.sharedContext.makeChatQrCodeScreen(context: context, peer: peer, threadId: nil, temporary: false)
                    present(.push, controller)
                })
            }
```

---

### Task 4: `ContactsController.swift` — Shape-A drop

**Files:**
- Modify: `submodules/ContactListUI/Sources/ContactsController.swift:478`

- [ ] **Step 1: Drop `._asPeer()` at the call site**

```swift
// old_string
                                    controller.present(strongSelf.context.sharedContext.makeChatQrCodeScreen(context: strongSelf.context, peer: peer._asPeer(), threadId: nil, temporary: false), in: .window(.root))

// new_string
                                    controller.present(strongSelf.context.sharedContext.makeChatQrCodeScreen(context: strongSelf.context, peer: peer, threadId: nil, temporary: false), in: .window(.root))
```

---

### Task 5: `PeerInfoScreen.swift` — Shape-C wrap

**Files:**
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift:4623`

Local `peer` comes from `data.peer` (type `Peer`). Wrap at the call site.

- [ ] **Step 1: Wrap with `EnginePeer(...)`**

```swift
// old_string
        let qrController = self.context.sharedContext.makeChatQrCodeScreen(context: self.context, peer: peer, threadId: threadId, temporary: temporary)

// new_string
        let qrController = self.context.sharedContext.makeChatQrCodeScreen(context: self.context, peer: EnginePeer(peer), threadId: threadId, temporary: temporary)
```

---

### Task 6: `ChannelAdminsController.swift` — Shape-A drop

**Files:**
- Modify: `submodules/PeerInfoUI/Sources/ChannelAdminsController.swift:734`

Local `peer` is `EnginePeer` (from `guard let peer` on :729 unwrapping `EnginePeer?` from `engine.data.get(Peer.Peer(id:))`).

- [ ] **Step 1: Drop `._asPeer()`**

```swift
// old_string
                    pushControllerImpl?(context.sharedContext.makeChatRecentActionsController(context: context, peer: peer._asPeer(), adminPeerId: nil, starsState: nil))

// new_string
                    pushControllerImpl?(context.sharedContext.makeChatRecentActionsController(context: context, peer: peer, adminPeerId: nil, starsState: nil))
```

---

### Task 7: `GroupStatsController.swift` — Shape-A drop

**Files:**
- Modify: `submodules/StatisticsUI/Sources/GroupStatsController.swift:915`

Local `peer` is `EnginePeer` (from `Signal<EnginePeer, NoError>` via the `mapToSignal` at :906).

- [ ] **Step 1: Drop `._asPeer()`**

```swift
// old_string
                let controller = context.sharedContext.makeChatRecentActionsController(context: context, peer: peer._asPeer(), adminPeerId: participantPeerId, starsState: nil)

// new_string
                let controller = context.sharedContext.makeChatRecentActionsController(context: context, peer: peer, adminPeerId: participantPeerId, starsState: nil)
```

---

### Task 8: `PeerInfoScreenOpenChat.swift` — Shape-C wrap

**Files:**
- Modify: `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenOpenChat.swift:115`

Local `peer` comes from `self.data?.peer` (type `Peer`). Wrap at the call site.

- [ ] **Step 1: Wrap with `EnginePeer(...)`**

```swift
// old_string
        let controller = self.context.sharedContext.makeChatRecentActionsController(context: self.context, peer: peer, adminPeerId: nil, starsState: self.data?.starsRevenueStatsState)

// new_string
        let controller = self.context.sharedContext.makeChatRecentActionsController(context: self.context, peer: EnginePeer(peer), adminPeerId: nil, starsState: self.data?.starsRevenueStatsState)
```

---

### Task 9: Build + iterate

- [ ] **Step 1: Run full build**

```bash
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 --configuration=debug_sim_arm64 \
 --continueOnError
```

Expected: first-pass-clean (wave 39's 50-file wave landed first-pass-clean; this 8-file wave should too).

- [ ] **Step 2: If errors, iterate**

Each error should point at a call site the plan missed. Fix, re-run. Do not widen the scope — if a call site not in the classification table above appears as an error, investigate whether the memory/inventory was stale.

---

### Task 10: Verify no residue

- [ ] **Step 1: Grep for raw-`Peer` sites**

```bash
grep -rn "makeChatQrCodeScreen\|makeChatRecentActionsController" --include="*.swift" submodules/
```

Expected output: 2 protocol-decl lines (AccountContext.swift), 2 impl-decl lines (SharedAccountContext.swift), and exactly 7 consumer sites — all with `peer: peer`, `peer: EnginePeer(peer)`, or similar (no `peer: x._asPeer()` remaining for these two methods).

---

### Task 11: Commit + update refactor log

**Files:**
- Modify: `docs/superpowers/postbox-refactor-log.md` — append wave-40 outcome section.

- [ ] **Step 1: Stage exactly these 8 files (enumerate, do not use `git add -u`)**

```bash
git add \
  submodules/AccountContext/Sources/AccountContext.swift \
  submodules/TelegramUI/Sources/SharedAccountContext.swift \
  submodules/SettingsUI/Sources/Search/SettingsSearchableItems.swift \
  submodules/ContactListUI/Sources/ContactsController.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift \
  submodules/PeerInfoUI/Sources/ChannelAdminsController.swift \
  submodules/StatisticsUI/Sources/GroupStatsController.swift \
  submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreenOpenChat.swift \
  docs/superpowers/plans/2026-04-24-makeChatQrCodeScreen-recentActions-engine-peer-migration.md
```

- [ ] **Step 2: Verify staging with `git status --short`**

Verify only the 9 files above are staged. If other files appear (e.g. `ChatMessageTransitionNode.swift` WIP, `sourcekit-bazel-bsp` submodule marker) — reset them out of the index with `git restore --staged <file>` and re-check.

- [ ] **Step 3: Commit (wave 40)**

```bash
git commit -m "$(cat <<'EOF'
Postbox -> TelegramEngine wave 40

makeChatQrCodeScreen + makeChatRecentActionsController peer Peer->EnginePeer.

- AccountContext protocol: 2 decls updated
- SharedAccountContext impls: 2 signatures + 2 body-shadow `let peer = peer._asPeer()`
- 5 Shape-A `._asPeer()` drops (SettingsSearchableItems x2 guard-variant, ContactsController, ChannelAdminsController, GroupStatsController)
- 2 Shape-C `EnginePeer(peer)` wraps (PeerInfoScreen, PeerInfoScreenOpenChat)
- Net: -3 bridges

Sibling follow-up to wave 39 (makePeerInfoController). Pre-flight classification
completed in wave-39 design doc's "Out of scope" section.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: Log wave 40 outcome**

Append a new section to `docs/superpowers/postbox-refactor-log.md`:

```markdown
## Wave 40 outcome

Commit: `<hash>`. Bundle of `AccountContext.makeChatQrCodeScreen` + `makeChatRecentActionsController` peer `Peer → EnginePeer`. 8 files / ~12 lines changed. Pre-flight classification from wave-39 design doc held: 5 Shape-A drops + 2 Shape-C wraps + 2 impl body-shadows + 2 protocol decls. Net −3 bridges. Build outcome: <first-pass-clean | N iterations>.

Sibling follow-up to wave 39 — completes the "Option 1 cluster" (makePeerInfoController family from wave-38 memory). Ratchet markers installed at PeerInfoScreen:4623 and PeerInfoScreenOpenChat:115 for a future `PeerInfoScreenData.peer Peer → EnginePeer` wave.
```

Then commit the log update:

```bash
git add docs/superpowers/postbox-refactor-log.md
git commit -m "$(cat <<'EOF'
docs: log wave 40 outcome

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 5: Update memory**

Update `/Users/isaac/.claude/projects/-Users-isaac-build-telegram-telegram-ios/memory/project_postbox_refactor_next_wave.md`:
- Move wave-40 (this bundle) from "candidates" to "Latest commits".
- Bump wave-41 recommendation to RenderedChannelParticipant.peer (Option 3) or RenderedPeer (Option 2).
- Add wave-40 lesson if any (e.g. "bundled sibling migration with shared pre-flight is cheap" or similar).

---

## Self-review checklist (writing-plans skill)

- **Spec coverage:** Every site from the memory/wave-39-doc pre-flight is a task. Sites 1+2 → Task 3; Site 3 → Task 4; Site 4 → Task 5; Site 5 → Task 6; Site 6 → Task 7; Site 7 → Task 8. Impl bodies → Task 2. Protocol → Task 1. Build → Task 9. Verify → Task 10. Commit+log → Task 11. ✓
- **Placeholders:** None. Every Edit step has exact `old_string` / `new_string`. Commit message and log-update text are spelled out. ✓
- **Type consistency:** Both methods take `peer: EnginePeer` everywhere — protocol decl, impl decl, and call sites' parameter passes. ✓
