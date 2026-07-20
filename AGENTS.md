# nicegram-ios

A fork of **Telegram-iOS**, shipped as **Nicegram**. We periodically merge the
latest upstream Telegram into this repo, so **every change here must be written
to survive that merge with as few conflicts as possible.**

Most standalone feature work does **not** belong here — it lives in the sibling
Swift package **`nicegram-assistant-ios`**. This repo is for code that must
physically live inside the Telegram app.

## Relationship with nicegram-assistant-ios

Two independent directions — don't conflate them:

- **Calling assistant features (host → assistant):** the Telegram shell invokes
  assistant code **directly** (import the assistant module and call it / its
  `Presenter`). Host-side dependencies are wired into the assistant once at
  launch via `NGEntryPoint.onAppLaunch(...)`.
- **`TelegramBridge` (assistant → host):** the abstraction the assistant uses to
  reach Telegram/host capabilities. **nicegram-ios provides the bridge
  implementations** (typically in `NGUtils`), injected through `NGEntryPoint`. It
  is dependency-injection *into* the assistant — NOT how the host calls assistant
  features.

## Two kinds of change in this repo

1. **Full features inside Telegram** — code that genuinely needs Telegram
   internals (chat UI, `Postbox`, `AccountContext`, navigation, ...).
2. **Call-sites into `nicegram-assistant-ios`** — thin hooks that invoke assistant
   features from the Telegram shell.

## Prime directive: minimize upstream-merge conflicts

Whatever the change, choose the **highest** applicable option:

1. **Keep it out of Telegram code.** Put it in `nicegram-assistant-ios`, or in a
   brand-new **separate file** here (a new file never conflicts on merge). Bridge
   Telegram dependencies through `TelegramBridge`.
2. **Add new code to an existing Telegram file**, wrapped in Nicegram markers.
3. **Modify an existing Telegram line** — last resort, with a marker above it.

Never leave an unmarked edit in Telegram code — the marker is what lets us
re-apply and audit our changes at the next merge. Exact marker syntax and the
`Signal` bridges live in the `telegram-interop` rule.

## Where our code lives

- **`Nicegram/`** — our in-repo `NG*` modules (mainly `NGUtils`). See the
  `nicegram-modules` rule.
- **`submodules/**/Nicegram/`** — whole new Nicegram files inside a Telegram
  submodule.
- **Marked blocks/lines across `submodules/**`** — inline integration.

## Build system

Bazel (`BUILD` files; some legacy `BUCK` remain), not hand-managed SPM/Xcode.
When you add a source file or dependency, update that module's build target. Do
not hand-edit generated files.

## Detailed conventions (`.cursor/rules/`, auto-attached by path)

- `telegram-interop.mdc` — editing `submodules/**`: marker syntax + SSignalKit
  bridges.
- `nicegram-modules.mdc` — `Nicegram/**` modules, `NGUtils`, resources.
- `swift-conventions.mdc` — Swift style for our code.
