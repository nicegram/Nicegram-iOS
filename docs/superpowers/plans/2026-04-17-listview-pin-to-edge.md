# ListView pin-to-edge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the first-pinned-item-to-bottom-edge behavior in `ListView` by adding a `calculatePinToEdgeTopInset()` helper and wiring it into `snapToBounds` and `updateScroller`, matching the design in [docs/superpowers/specs/2026-04-17-listview-pin-to-edge-design.md](../specs/2026-04-17-listview-pin-to-edge-design.md).

**Architecture:** Heights-based virtual-top-inset adjustment. A new private helper on `ListViewImpl` computes `max(0, visibleArea - ΣheightsAboveAndIncludingPinned)`. Two call sites add this to `effectiveInsets.top` via the existing `max(…)` chain alongside `stackFromBottomInsetItemFactor`.

**Tech Stack:** Swift, ASDisplayKit, Bazel build system.

**Scope:** Single file — `submodules/Display/Source/ListView.swift`. No protocol change (`pinToEdgeWithInset` is already declared on `ListViewItem`). No consumer changes. Because no item overrides `pinToEdgeWithInset` from its default `false`, the existing app surface's behavior is unchanged after this plan lands; the feature will be exercised only by a future consumer in a separate change.

**No unit tests** exist in this project (per `CLAUDE.md`). Verification is via the full project build.

---

## Task 1: Add `calculatePinToEdgeTopInset` helper and integrate at both call sites

**Files:**
- Modify: `submodules/Display/Source/ListView.swift`

The helper, both call-site edits, and the build verification land in one commit because they are tightly coupled: committing the helper without any call site is a no-op, and committing only one of the two call sites would cause `updateScroller` and `snapToBounds` to disagree about `effectiveInsets.top`, producing scroll-position desync whenever pinning is engaged.

---

- [ ] **Step 1: Insert the `calculatePinToEdgeTopInset` helper after `calculateAdditionalTopInverseInset`**

Use the Edit tool. The helper goes immediately after `calculateAdditionalTopInverseInset`'s closing brace (line 1090) and before `areAllItemsOnScreen` (line 1092).

old_string:
```swift
    private func calculateAdditionalTopInverseInset() -> CGFloat {
        var additionalInverseTopInset: CGFloat = 0.0
        if !self.stackFromBottomInsetItemFactor.isZero {
            var remainingFactor = self.stackFromBottomInsetItemFactor
            for itemNode in self.itemNodes {
                if remainingFactor.isLessThanOrEqualTo(0.0) {
                    break
                }
                
                let itemFactor: CGFloat
                if CGFloat(1.0).isLessThanOrEqualTo(remainingFactor) {
                    itemFactor = 1.0
                } else {
                    itemFactor = remainingFactor
                }
                
                additionalInverseTopInset += floor(itemNode.apparentBounds.height * itemFactor)
                
                remainingFactor -= 1.0
            }
        }
        return additionalInverseTopInset
    }
    
    private func areAllItemsOnScreen() -> Bool {
```

new_string:
```swift
    private func calculateAdditionalTopInverseInset() -> CGFloat {
        var additionalInverseTopInset: CGFloat = 0.0
        if !self.stackFromBottomInsetItemFactor.isZero {
            var remainingFactor = self.stackFromBottomInsetItemFactor
            for itemNode in self.itemNodes {
                if remainingFactor.isLessThanOrEqualTo(0.0) {
                    break
                }
                
                let itemFactor: CGFloat
                if CGFloat(1.0).isLessThanOrEqualTo(remainingFactor) {
                    itemFactor = 1.0
                } else {
                    itemFactor = remainingFactor
                }
                
                additionalInverseTopInset += floor(itemNode.apparentBounds.height * itemFactor)
                
                remainingFactor -= 1.0
            }
        }
        return additionalInverseTopInset
    }
    
    private func calculatePinToEdgeTopInset() -> CGFloat {
        var lowestPinnedIndex: Int = Int.max
        for itemNode in self.itemNodes {
            guard let index = itemNode.index else { continue }
            if index < lowestPinnedIndex && self.items[index].pinToEdgeWithInset {
                lowestPinnedIndex = index
            }
        }
        guard lowestPinnedIndex != Int.max else { return 0.0 }
        
        var totalAboveAndPinned: CGFloat = 0.0
        var sawIndexZero = false
        for itemNode in self.itemNodes {
            guard let index = itemNode.index else { continue }
            if index == 0 {
                sawIndexZero = true
            }
            if index <= lowestPinnedIndex {
                totalAboveAndPinned += itemNode.apparentBounds.height
            }
        }
        guard sawIndexZero else { return 0.0 }
        
        let visibleArea = self.visibleSize.height - self.insets.top - self.insets.bottom
        return max(0.0, visibleArea - totalAboveAndPinned)
    }
    
    private func areAllItemsOnScreen() -> Bool {
```

- [ ] **Step 2: Integrate at the `snapToBounds` call site**

Use the Edit tool. The block at lines 1181-1185 in `snapToBounds` gets a new `pinToEdgeTopInset` stanza after the existing `stackFromBottomInsetItemFactor` branch. Include the following line (`        ` + `if topItemFound {`) in the old_string to disambiguate from the structurally-identical block in `areAllItemsOnScreen` at line 1110.

old_string:
```swift
        var effectiveInsets = self.insets
        if topItemFound && !self.stackFromBottomInsetItemFactor.isZero {
            let additionalInverseTopInset = self.calculateAdditionalTopInverseInset()
            effectiveInsets.top = max(effectiveInsets.top, self.visibleSize.height - additionalInverseTopInset)
        }
        
        if topItemFound {
```

new_string:
```swift
        var effectiveInsets = self.insets
        if topItemFound && !self.stackFromBottomInsetItemFactor.isZero {
            let additionalInverseTopInset = self.calculateAdditionalTopInverseInset()
            effectiveInsets.top = max(effectiveInsets.top, self.visibleSize.height - additionalInverseTopInset)
        }
        let pinToEdgeTopInset = self.calculatePinToEdgeTopInset()
        if pinToEdgeTopInset > 0.0 {
            effectiveInsets.top = max(effectiveInsets.top, self.insets.top + pinToEdgeTopInset)
        }
        
        if topItemFound {
```

- [ ] **Step 3: Integrate at the `updateScroller` call site**

Use the Edit tool. The block at lines 1612-1616 in `updateScroller` is nested one extra level (12-space indent rather than 8-space), so the string alone is unique and the old_string doesn't need extra context.

old_string:
```swift
            var effectiveInsets = self.insets
            if topItemFound && !self.stackFromBottomInsetItemFactor.isZero {
                let additionalInverseTopInset = self.calculateAdditionalTopInverseInset()
                effectiveInsets.top = max(effectiveInsets.top, self.visibleSize.height - additionalInverseTopInset)
            }
            
            completeHeight = effectiveInsets.top + effectiveInsets.bottom
```

new_string:
```swift
            var effectiveInsets = self.insets
            if topItemFound && !self.stackFromBottomInsetItemFactor.isZero {
                let additionalInverseTopInset = self.calculateAdditionalTopInverseInset()
                effectiveInsets.top = max(effectiveInsets.top, self.visibleSize.height - additionalInverseTopInset)
            }
            let pinToEdgeTopInset = self.calculatePinToEdgeTopInset()
            if pinToEdgeTopInset > 0.0 {
                effectiveInsets.top = max(effectiveInsets.top, self.insets.top + pinToEdgeTopInset)
            }
            
            completeHeight = effectiveInsets.top + effectiveInsets.bottom
```

- [ ] **Step 4: Run the full project build**

Use the Bash tool. The build takes several minutes; run it in the foreground so the agent waits for completion and surfaces failures immediately. The `source ~/.zshrc` prefix picks up `TELEGRAM_CODESIGNING_GIT_PASSWORD` per the build-environment quirk documented in `CLAUDE.md`.

```
source ~/.zshrc 2>/dev/null; PATH=/opt/homebrew/opt/ruby/bin:`gem environment gemdir`/bin:$PATH python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache build --configurationPath build-system/appstore-configuration.json --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber 1 --configuration debug_sim_arm64
```

Expected: successful build. No warnings or errors touching `ListView.swift`.

If the build fails:
- Swift syntax error → re-read `ListView.swift` around the edited regions; compare against the plan's old_string/new_string; fix and re-run.
- "`pinToEdgeWithInset` has no member" → the protocol property wasn't found; verify `submodules/Display/Source/ListViewItem.swift:80` still declares `var pinToEdgeWithInset: Bool { get }` and the default implementation at `ListViewItem.swift:102` is intact. If intact but the error persists, check that the `items` array's element type is `ListViewItem` (it is — see `public final var items: [ListViewItem]` in `ListView.swift`).
- Any other failure in unrelated files → not caused by this plan; investigate separately.

- [ ] **Step 5: Commit**

```bash
git add submodules/Display/Source/ListView.swift
git commit -m "$(cat <<'EOF'
Display/ListView: pin first pinToEdgeWithInset item to bottom edge

Adds calculatePinToEdgeTopInset() and wires it into snapToBounds and
updateScroller. When the smallest-index item with pinToEdgeWithInset=true
plus all items above it have a combined apparentBounds height less than
the available scrolling area, the helper returns a positive top-inset
contribution that pushes the pinned item's maxY to visibleSize.height -
insets.bottom. Once items above reach the available area, the
contribution is zero and scrolling is fully ordinary.

Spec: docs/superpowers/specs/2026-04-17-listview-pin-to-edge-design.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Verify with `git status` that the tree is clean after the commit.

---

## Rationale for task granularity

This plan has a single task. I considered splitting "add helper" from "apply at two call sites" into two commits:

- **For splitting:** one commit per "unit of change" is more bisectable.
- **Against splitting:** the helper alone is unused (runtime no-op, and Swift does not warn on unused private methods). Applying at one call site without the other would produce a live bug — `snapToBounds` and `updateScroller` would disagree whenever pinning engages, and `updateScroller` is what sets `scroller.contentSize`/`contentOffset`. Three commits land an internally-consistent state only at the third commit.

Bundling all edits preserves bisectability at the feature-level boundary (the commit either introduces pin-to-edge support or it doesn't) and keeps the repo free of intermediate broken states.
