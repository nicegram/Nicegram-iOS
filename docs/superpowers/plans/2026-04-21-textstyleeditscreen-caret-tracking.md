# TextStyleEditScreen caret-tracking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On every text change inside `TextStyleEditScreen`, scroll the enclosing `ResizableSheetComponent` scroll view so the caret in the active `ListMultilineTextFieldItemComponent` stays visible ~24pt above the keyboard/bottom button area.

**Architecture:** Single-file change in `submodules/TelegramUI/Components/TextProcessingScreen/Sources/TextStyleEditScreen.swift`. Give each text field a `ListMultilineTextFieldItemComponent.Tag`; at the end of `TextStyleEditContentComponent.View.update(...)`, read `TextFieldComponent.AnimationHint` off the transition's userData; on a `.textChanged` hint, resolve the editing field, compute the caret rect via `UITextInput.caretRect(for:)`, walk `superview` to the enclosing `UIScrollView`, and adjust its `bounds.origin.y` using the direct-assign + additive-animate pattern from `ComposePollScreen.swift:2873-2895`.

**Tech Stack:** Swift, UIKit, Telegram's ComponentFlow (`ComponentView`, `ComponentTransition`, `TextFieldComponent.AnimationHint`), Bazel via `Make.py`. No unit tests exist in this project — verification is a full build + manual smoke test per `CLAUDE.md`.

**Reference spec:** `docs/superpowers/specs/2026-04-21-textstyleeditscreen-caret-tracking-design.md`.

**Reference precedent:** `submodules/TelegramUI/Components/ComposePollScreen/Sources/ComposePollScreen.swift:2733-2895` (field-bounds variant of this same pattern).

---

## File Structure

Only one file is touched:

- **Modify:** `submodules/TelegramUI/Components/TextProcessingScreen/Sources/TextStyleEditScreen.swift`
  - Add two stored `ListMultilineTextFieldItemComponent.Tag` properties on `TextStyleEditContentComponent.View`.
  - Thread those tags into the two existing `ListMultilineTextFieldItemComponent(...)` constructions inside `update(...)`.
  - Add a private `recenterCaret(hintView:transition:)` method on `TextStyleEditContentComponent.View`.
  - Call `recenterCaret` from the tail of `update(...)` when the transition carries a `.textChanged` `TextFieldComponent.AnimationHint`.

No other files are modified. Public API of `ResizableSheetComponent`, `ListMultilineTextFieldItemComponent`, and `TextFieldComponent` is used as-is.

---

## Task 1: Add field tags and wire them into the two text field constructors

**Files:**
- Modify: `submodules/TelegramUI/Components/TextProcessingScreen/Sources/TextStyleEditScreen.swift` (around lines 64-77, 277, 322)

- [ ] **Step 1: Add the two `Tag` stored properties to `TextStyleEditContentComponent.View`**

In `TextStyleEditScreen.swift`, locate the stored-property block at the top of `final class View: UIView` (lines 64-77). Below `private let linkOption = ComponentView<Empty>()` (line 76) add:

```swift
        private let titleFieldTag = ListMultilineTextFieldItemComponent.Tag()
        private let textFieldTag = ListMultilineTextFieldItemComponent.Tag()
```

Keep them above the `override init(frame: CGRect)` at line 78.

- [ ] **Step 2: Pass `self.titleFieldTag` into the title field constructor**

Locate the `ListMultilineTextFieldItemComponent(...)` construction for the title section (starts at line 260). Its last argument currently reads `tag: nil` (line 277). Change it to:

```swift
                tag: self.titleFieldTag
```

- [ ] **Step 3: Pass `self.textFieldTag` into the prompt field constructor**

Locate the second `ListMultilineTextFieldItemComponent(...)` construction for the text section (starts at line 304). Its last argument currently reads `tag: nil` (line 322). Change it to:

```swift
                tag: self.textFieldTag
```

- [ ] **Step 4: Verify the change compiles**

Run:

```bash
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 --configuration=debug_sim_arm64 \
 --continueOnError
```

Expected: build succeeds (or the same pre-existing failures unrelated to `TextStyleEditScreen.swift`). A failure in `TextStyleEditScreen.swift` means the tag types or property names are wrong — fix before moving on.

- [ ] **Step 5: Do not commit yet** — tag wiring is inert without the recenter logic. Defer commit to Task 4.

---

## Task 2: Add the `recenterCaret` helper

**Files:**
- Modify: `submodules/TelegramUI/Components/TextProcessingScreen/Sources/TextStyleEditScreen.swift`

- [ ] **Step 1: Add the method on `TextStyleEditContentComponent.View`**

Inside `final class View: UIView` (the class that starts at line 64), directly **before** the `func update(component:availableSize:state:environment:transition:)` method (line 86), add this private method. It covers steps 1–6 from the design spec (locate field view → caret rect → scroll view → scroll view coordinates → visible region → adjust bounds).

```swift
        private func recenterCaret(hintView: UIView, transition: ComponentTransition) {
            var fieldView: ListMultilineTextFieldItemComponent.View?
            var ancestor: UIView? = hintView
            while let current = ancestor {
                if let candidate = current as? ListMultilineTextFieldItemComponent.View {
                    fieldView = candidate
                    break
                }
                ancestor = current.superview
            }
            guard let fieldView else {
                return
            }
            if !(fieldView.matches(tag: self.titleFieldTag) || fieldView.matches(tag: self.textFieldTag)) {
                return
            }
            guard let inputTextView = fieldView.textFieldView?.inputTextView else {
                return
            }
            let caretPosition = inputTextView.selectedTextRange?.end ?? inputTextView.endOfDocument
            let caretRect = inputTextView.caretRect(for: caretPosition)
            if caretRect.isNull || caretRect.isInfinite {
                return
            }
            
            var scrollAncestor: UIView? = self.superview
            var scrollView: UIScrollView?
            while let current = scrollAncestor {
                if let candidate = current as? UIScrollView {
                    scrollView = candidate
                    break
                }
                scrollAncestor = current.superview
            }
            guard let scrollView, let environment = self.environment else {
                return
            }
            
            let caretInScroll = inputTextView.convert(caretRect, to: scrollView)
            
            let bottomActionAreaHeight: CGFloat = 60.0
            let caretTopInset: CGFloat = 24.0
            let caretBottomInset: CGFloat = 24.0
            let visibleTop = scrollView.bounds.minY + caretTopInset
            let visibleBottom = scrollView.bounds.maxY - environment.inputHeight - bottomActionAreaHeight - caretBottomInset
            
            let previousBounds = scrollView.bounds
            var newBounds = previousBounds
            if caretInScroll.maxY > visibleBottom {
                newBounds.origin.y += (caretInScroll.maxY - visibleBottom)
            } else if caretInScroll.minY < visibleTop {
                newBounds.origin.y -= (visibleTop - caretInScroll.minY)
            }
            let maxOriginY = max(0.0, scrollView.contentSize.height - scrollView.bounds.height)
            newBounds.origin.y = min(max(0.0, newBounds.origin.y), maxOriginY)
            
            if newBounds != previousBounds {
                scrollView.bounds = newBounds
                if !transition.animation.isImmediate {
                    let offsetY = previousBounds.origin.y - newBounds.origin.y
                    transition.animateBoundsOrigin(view: scrollView, from: CGPoint(x: 0.0, y: offsetY), to: CGPoint(), additive: true)
                }
            }
        }
```

Notes on key choices:

- `bottomActionAreaHeight: 60.0` = `52.0` (bottom item height — see `ResizableSheetComponent.swift:750`) + `8.0` gap above the button (matches `ResizableSheetComponent.swift:732`).
- `caretTopInset` / `caretBottomInset` (both `24.0`) provide the "small inset" biased positioning the user confirmed.
- The hint's view ancestor walk is used (rather than `self.titleFieldTag`'s / `self.textFieldTag`'s views directly) because the hint already carries the `TextFieldComponent.View` that actually fired the change — this is safer than guessing which of our two fields is editing when both may have briefly claimed focus.
- `transition.animateBoundsOrigin` is the proven pattern from `ComposePollScreen.swift:2891-2894`; `transition.animation.isImmediate` gating avoids an unnecessary animation when the transition is immediate.
- Silent bails on missing scroll view or text view keep the code robust against host refactors (they should never happen in normal operation).

- [ ] **Step 2: Verify compilation**

Re-run the build command from Task 1 Step 4. Expected: the method compiles cleanly. Common failure modes to watch for:

- `cannot find 'ListMultilineTextFieldItemComponent.View' in scope` → wrong type path; check the import and the class name in `ListMultilineTextFieldItemComponent.swift:196` (it is the nested `View` class of `ListMultilineTextFieldItemComponent`).
- `value of type 'TextFieldComponent.View' has no member 'inputTextView'` → the property is defined at `TextFieldComponent.swift:359`; ensure you're reading `fieldView.textFieldView?.inputTextView`, not reaching into private internals.
- `'ComponentTransition' has no member 'animateBoundsOrigin'` → this is a ComponentFlow method; grep confirms it exists and is used at `ComposePollScreen.swift:2893`. If missing, the import line (`import ComponentFlow`) at file top is the place to check.

- [ ] **Step 3: Do not commit yet** — the helper is unreferenced and unused. Defer commit to Task 4.

---

## Task 3: Hook up the `.textChanged` trigger in `update(...)`

**Files:**
- Modify: `submodules/TelegramUI/Components/TextProcessingScreen/Sources/TextStyleEditScreen.swift`

- [ ] **Step 1: Add the trigger at the tail of `update(...)`**

At the end of `func update(component:availableSize:state:environment:transition:)` on `TextStyleEditContentComponent.View`, locate lines 455-460:

```swift
            contentHeight += 104.0
            
            let _ = alphaTransition

            return CGSize(width: availableSize.width, height: contentHeight)
```

Insert the trigger block **before** `return`:

```swift
            contentHeight += 104.0
            
            let _ = alphaTransition
            
            if let hint = transition.userData(TextFieldComponent.AnimationHint.self), case .textChanged = hint.kind, let hintView = hint.view {
                self.recenterCaret(hintView: hintView, transition: transition)
            }

            return CGSize(width: availableSize.width, height: contentHeight)
```

Do NOT match on `.textFocusChanged` — per the user's requirement, scrolling fires only on text edits.

- [ ] **Step 2: Ensure `TextFieldComponent` is importable**

`TextFieldComponent.AnimationHint` is vended from the `TextFieldComponent` module. Check the file's import list at the top (lines 1-25). `TextFieldComponent` is used transitively today via `ListMultilineTextFieldItemComponent`, but the type is only re-exposed if we explicitly import it.

Locate the import block (around lines 1-25). If `import TextFieldComponent` is not present, add it alphabetically — for example, between `import ResizableSheetComponent` and `import TelegramCore`:

```swift
import TextFieldComponent
```

If it is already present, skip this sub-step.

- [ ] **Step 3: Ensure the BUILD dep is present**

Locate the sibling `BUILD` file:

```bash
cat submodules/TelegramUI/Components/TextProcessingScreen/BUILD
```

Look for `//submodules/TelegramUI/Components/TextFieldComponent:TextFieldComponent` in the `deps` list. If present, skip to the next step. If absent, add it to the `deps` array (preserving alphabetical order where the BUILD file follows that convention). For example:

```
        "//submodules/TelegramUI/Components/TextFieldComponent:TextFieldComponent",
```

- [ ] **Step 4: Verify compilation**

Re-run the build command from Task 1 Step 4.

Expected: clean build for `TextStyleEditScreen.swift` and its host module (`TextProcessingScreen`). Common failure modes:

- `cannot find 'TextFieldComponent' in scope` → missing `import TextFieldComponent` (fix in Step 2).
- Bazel link error naming `TextFieldComponent` → missing BUILD dep (fix in Step 3).
- `instance method requires the types 'X' and 'Y' to be equivalent` on the `case .textChanged = hint.kind` line → the `case let` pattern binding; verify with `grep -n 'case \\.textChanged' submodules/TelegramUI/Components/TextFieldComponent/Sources/TextFieldComponent.swift` that the case is payload-less (it is, per `TextFieldComponent.swift:95-103` where `Kind` declares `case textChanged` without associated values and `case textFocusChanged(isFocused: Bool)` with one).

- [ ] **Step 5: Do not commit yet** — verify end-to-end behavior in Task 4 first.

---

## Task 4: Manual smoke test and commit

**Files:**
- Modify (commit): `submodules/TelegramUI/Components/TextProcessingScreen/Sources/TextStyleEditScreen.swift`
- Possibly modify (commit): `submodules/TelegramUI/Components/TextProcessingScreen/BUILD`

- [ ] **Step 1: Launch the app on the simulator**

Run:

```bash
source ~/.zshrc 2>/dev/null; python3 build-system/Make/Make.py --overrideXcodeVersion \
 --cacheDir ~/telegram-bazel-cache \
 build \
 --configurationPath build-system/appstore-configuration.json \
 --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
 --gitCodesigningType development --gitCodesigningUseCurrent --buildNumber=1 --configuration=debug_sim_arm64
```

Expected: `Telegram.ipa` target built successfully, 0 errors.

Note: this project has no unit tests; feature correctness for UI changes requires a manual check on device or simulator. Install the built app on the iOS simulator (`xcrun simctl install booted ...` if not done by the build script) and navigate to the AI style-edit sheet — this is typically reached from a chat's AI compose-mode style selector or from Settings, depending on build flavour. If the entry point is unclear, grep for `TextStyleEditScreen(` to find a test harness or the production call site:

```bash
grep -rn "TextStyleEditScreen(" submodules --include="*.swift"
```

- [ ] **Step 2: Smoke test — short content path**

1. Tap the "Style Name" field. Confirm the keyboard slides up and the "Create" button rides above the keyboard (pre-existing behavior from the earlier `inputHeight` work).
2. Type one character. With short content no scroll should occur; the scroll view should remain at origin zero (visual check: the emoji icon at the top stays visible).

Pass criterion: no visual regression; the title field is visible and typable.

- [ ] **Step 3: Smoke test — long prompt path**

1. Tap the "Instructions" field.
2. Type enough text (or paste a paragraph) to make the prompt field taller than the viewport with the keyboard up.
3. Continue typing so new characters appear at the caret.

Pass criterion: as each newline is added, the caret stays approximately 24pt above the keyboard/button area. The field's top may scroll out of view — that's expected.

- [ ] **Step 4: Smoke test — manual-scroll-then-type**

1. Still in the "Instructions" field with enough content that scroll is possible.
2. Manually drag the sheet content up so the caret is pushed above the visible area.
3. Type one character.

Pass criterion: the scroll view snaps downward so the caret is visible again, above the keyboard with the configured inset.

- [ ] **Step 5: Smoke test — edit-mode mid-field tap (non-goal regression check)**

1. Trigger the screen in edit mode on a style with a long pre-populated prompt (enough text to exceed the viewport).
2. Tap **in the middle** of the prompt so the caret lands off-screen-top (no text change).

Pass criterion: **no** scroll occurs (this is per the non-goal — we only scroll on text change). A follow-up text edit is expected to trigger a scroll; that is covered by Step 3.

- [ ] **Step 6: Check for regressions in adjacent flows**

Briefly exercise:

1. The emoji-selection sheet (tap the big round emoji area at the top) — must still open, select, and dismiss without issue.
2. The "Add a link to my account" checkbox — toggling still flips the check.
3. The "Delete Style" row (edit mode) — still pushes the confirm alert.

Pass criterion: all three work as before.

- [ ] **Step 7: Commit**

```bash
git add submodules/TelegramUI/Components/TextProcessingScreen/Sources/TextStyleEditScreen.swift
# Only stage the BUILD file if it was modified in Task 3 Step 3:
git status --short submodules/TelegramUI/Components/TextProcessingScreen/BUILD
# If the BUILD file shows up modified, stage it too:
git add submodules/TelegramUI/Components/TextProcessingScreen/BUILD
git commit -m "$(cat <<'EOF'
TextStyleEditScreen: scroll caret into view on text change

Tag both ListMultilineTextFieldItemComponents and, at the tail of
TextStyleEditContentComponent.View.update(...), read TextFieldComponent.
AnimationHint off the transition userData. On a .textChanged hint, locate
the editing field, compute the caret rect, walk up to the enclosing
ResizableSheetComponent scroll view, and adjust bounds.origin.y so the
caret sits ~24pt above the keyboard/bottom action area.

Scroll runs only on text edits (not on focus/selection changes) per spec.
Uses the direct-assign + additive-animate pattern from ComposePollScreen.
EOF
)"
```

Expected: commit succeeds. The diff is ~50 lines added across one .swift file (and possibly one line added to BUILD).

---

## Out-of-scope / follow-ups

None planned. The non-goals called out in the spec (scroll on focus change, scroll on selection change, scroll on keyboard show/hide independently of a text edit) are intentional omissions, not deferred work.

If manual smoke testing reveals that focus-gain keyboard appearance creates a bad UX (user taps a field near the bottom and the keyboard covers it until they type), consider adding back the `.textFocusChanged(isFocused: true)` case in the trigger block. That is a one-line change to the conditional in Task 3 Step 1 and does not require any design iteration.
