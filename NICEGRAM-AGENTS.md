# nicegram-ios

A fork of **Telegram-iOS**, shipped as **Nicegram**. We periodically merge the
latest upstream Telegram into this repo, so **every change here must be written
to survive that merge with as few conflicts as possible.**

Most standalone feature work does **not** belong here — it lives in the sibling
Swift package **`nicegram-assistant-ios`**. This repo is for code that must
physically live inside the Telegram app.

## Relationship with nicegram-assistant-ios

The assistant is **vendored as a git submodule** at
`packages/nicegram-assistant-ios`, so its sources sit in this working
tree and local edits build immediately. Commits there belong to the assistant
repo and land through its own PR **before** this repo bumps the pointer. See
"Cross-repo feature workflow" below.

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

### The web domain

`Nicegram/NGWebDomains/web_domains.bzl` is the only place the Nicegram web
domain is written. `NICEGRAM_PRIMARY_DOMAIN` is what the app links to;
`NICEGRAM_ALL_DOMAINS` is every domain it claims, with auxiliary entries written
as prefixed forms of the primary so the domain itself is stated once.

Everything derives from it. `Telegram/BUILD` generates one `applinks:` line per
claimed domain into the associated-domains entitlement, and a `write_file` rule
generates the Swift constants behind `//Nicegram/NGWebDomains` — a module kept
dependency-free because `submodules/UrlWhitelist`, a leaf module with no deps at
all, needs the list.
The assistant never learns the domain at compile time: `AppDelegate` passes it
through `Env.webDomains` (and to the wallet as `appUniversalLinkDomain`), and
inside the assistant `WebDomains` owns link recognition while `NicegramLinks` —
read as `NGCore.links` — owns every hardcoded URL.

Two things to keep true. **Never write either domain anywhere else**, including
in a test: assertions build their expectations from a fake domain. And an
upstream merge that rewrites `Telegram/BUILD`'s
`associated_domains_fragment` must keep the `{nicegram_applinks}` interpolation
rather than reverting to literal `<string>applinks:…</string>` entries.

## Build

Bazel (`BUILD` files; some legacy `BUCK` remain), not hand-managed SPM/Xcode.
When you add a source file or dependency, update that module's build target. Do
not hand-edit generated files.

The build layer is `ci/fastlane`. Do not invoke `build-system/Make/Make.py`
directly — the fastlane lanes resolve the configuration, cache directory, and
codesigning repository for you, and a hand-written `Make.py` command will use the
wrong ones.

    cd ci && ./generate-project.sh                    # generate the Xcode project
    cd ci && ./verify-build.sh                        # compile check (arm64 device by default; --sim for the simulator)
    cd ci && ./build-to-testflight.sh "1.2.3 (456)"   # QA / TestFlight build

`verify-build.sh` and `generate-project.sh` both run `ci/bootstrap-submodules.sh`
first and abort if it fails. This matters because a freshly created worktree
starts with **every** submodule uninitialized — neither the "create worktree"
checkbox nor the harness's `EnterWorktree` tool runs `git submodule update
--init`, and no single harness hook covers every path that creates a
worktree — so without this, the first build fails ~30s into Bazel with a `No
MODULE.bazel, REPO.bazel, or WORKSPACE file found in .../rules_xcodeproj`
error that names neither "submodule" nor "worktree". The script is idempotent
and near-instant when nothing is missing (one `git submodule status` call);
when something is missing it prefers cloning from the main clone's own
gitdirs over the network (see "Starting a feature" below for why), and if it
still can't fully initialize everything — most likely
`packages/nicegram-assistant-ios`, which needs Bitbucket SSH access — it
prints exactly which paths failed and exits non-zero rather than letting the
build proceed into the confusing Bazel error above. `build-to-testflight.sh`
skips this step: it doesn't build locally, it just pushes the branch and
triggers the Bitbucket pipeline, which does its own recursive submodule
checkout.

All three wrappers then source `ci/_env.sh`, which sources
`ci/fastlane-env.sh` — **untracked** because it holds credentials, obtain it
from the shared env store, like the demo app's `Env.swift`. From a worktree,
where that untracked file does not exist, it falls back to the main clone's
copy automatically, so the same three commands work everywhere. (That
fallback depends on every wrapper starting with `#!/bin/bash`: under
`/bin/sh` — on macOS that's bash itself running in POSIX mode, reproduced
directly — a failed `.` on a missing file aborts the shell before the `||`
alternative runs, so the fallback would silently never fire.) `ci/_env.sh`
then re-derives `SOURCE_PATH` itself and re-exports it, derived from its
own file location rather than the caller's working directory
(`SOURCE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`), so it
resolves correctly however `_env.sh` is sourced, not only when the
caller happens to be sitting in `ci/`. This overrides whatever the
untracked `fastlane-env.sh` happened to set. That's deliberate: leaving the
guarantee "a build from a worktree builds that worktree" resting only on
the untracked file would make it depend on every teammate's local,
unversioned copy deriving the path the same way — one copy that
hardcodes a stale absolute path and a worktree build silently builds the
main clone instead, with no error. The Fastfile has its own separate
fallback, `SOURCE_PATH = ENV["SOURCE_PATH"] || File.expand_path("../..",
__dir__)` — a second, independent safety net for a lane invoked directly
without going through any wrapper, not the mechanism the guarantee above
actually rests on (`__dir__` evaluates to `"."` in fastlane's `eval`; the
fallback only lands on the repo root because fastlane wraps that eval in
`Dir.chdir(FastlaneFolder.path)`, i.e. `ci/fastlane`). CI sets
`SOURCE_PATH` directly as job env before invoking a lane, so
`ENV["SOURCE_PATH"]` wins there without ever touching `_env.sh`.

The target environment comes from `ng-env.txt` (`test` or `prod`), which
`resolve_telegram_configuration` reads to pick between
`TELEGRAM_CONFIGURATION_TEST` and `TELEGRAM_CONFIGURATION_PROD`.

Add `--continueOnError` to a `Make.py` call only if you are debugging the build
system itself; for normal work, use the wrappers.

`./verify-build.sh` is the supported way to answer "does this still compile" —
for any change, not just an upstream merge. It passes bazel's `--keep_going` so
one pass reports every broken module, and refuses to start while Xcode is
running — see "One build at a time" below. It builds **through
rules_xcodeproj's command-line API**, which is what makes it share cache with
an Xcode build, and there is no second build path. Read the script's own header
before changing it: it records what each step exists to prevent, including one
bazel behaviour that silently turns a naive version of this gate permanently
green.

**The destination is decided in exactly one place**, `ci/verify-build.sh`, in
this order: `--device`/`--sim` on the command line, then
`$NG_BUILD_DESTINATION` (`device`|`sim`), then `device`. Everything downstream —
the signing pre-flight, the target-id prefix, the report label — derives from
that single variable, and the `tg-merge` and `sync-from-develop` skills pass no
flag at all, so they inherit whatever it resolves to. Set
`NG_BUILD_DESTINATION` in the **untracked** `ci/fastlane-env.sh` if you build
the simulator in Xcode: the choice is genuinely per-machine, because the disk
cache is local and only ever needs to match what *you* build here. `ng-env.txt`
is the wrong home for it — that file is tracked, so it is project-wide. A value
that is not exactly `device` or `sim` is refused with exit 2 rather than quietly
treated as one of them.

### Build cache

Bazel's cache has four layers here, each with a different scope:

1. **Repository cache**, `/private/var/tmp/_bazel_$USER/cache` — fetched
   external dependencies. Global: shared by every workspace and every worktree
   on the machine.
2. **The output base**, `/private/var/tmp/_bazel_$USER/<md5-of-workspace-path>/`
   — execroot, the `bazel-out` tree, the action cache, the analysis graph.
   Bazel names this directory by hashing the workspace's filesystem path, so
   it is **per workspace path — one per worktree**; a worktree shares none of
   another worktree's output base.
3. **The disk cache**, `~/work/nicegram-bazel-cache` (`BAZEL_LOCAL_CACHE`,
   reaching bazel through `Make.py`'s command line and through the generated
   `xcodeproj.bazelrc`). Content-addressed, keyed by action key, and **the only
   layer that bridges worktrees**. Bounded — see below.
4. **The rules_xcodeproj nested output base**, at
   `<output_base>/rules_xcodeproj.noindex/build_output_base` — a second,
   separate bazel server that `rules_xcodeproj` runs inside the outer output
   base. Both an Xcode build and `ci/verify-build.sh` build here; the outer base
   only holds the small `xcodeproj` *runner* target (measured: 8 packages, 2.6s
   from a cold server, and a `bazel clean` that removed 34G from the outer base
   cost the gate nothing). Anything that builds plain target labels — the
   `compile_check` lane, `Make.py build` — lands in the outer base instead,
   which is exactly why it shares nothing.

What actually shares with what, as measured:

- **CLI ↔ CLI, across worktrees: excellent.** A cold worktree with no output
  base at all completed a full simulator app compile in 179s, with 5,857 of
  7,490 actions (78%) served from the disk cache. A fresh worktree is not a
  full rebuild.
- **Xcode ↔ a plain label build: nothing, and no flag can fix it.** A device
  gate run immediately after a successful Xcode device build of the same code
  got zero disk-cache hits and took 1,114s. Flag alignment was carried all the
  way to completion — the two flows' swiftc command lines for
  `submodules/Display` became byte-identical — and it bought nothing: output
  paths are part of every action key, and the two configuration directories
  differ (`ST-a7beea3c269e` for a label build vs. `ST-9cbb67e27a8f` for Xcode),
  with zero overlap across all seven min-version configurations, unchanged by
  the alignment. The `-ST-` suffix is derived from the Starlark **transition
  path**, not from flags. (Their **exec** configurations do overlap, which is
  why a post-alignment run still showed ~145 disk-cache hits: host-tool
  actions, not app code.) The full trail is in `ci/nicegram.bazelrc`'s `ng_dev`
  comment.
- **Xcode ↔ `ci/verify-build.sh`: shared, since 2026-08-28.** The gate runs
  bazel *through* the generator label with rules_xcodeproj's command-line API,
  so it lands on the same transition path, the same output base and the same
  action keys. Measured on the same worktree and the same commit: the device
  gate went from **1,114s with zero cache hits** to **6s with every action a
  cache hit**, and a run of the whole project through the API took 8,750
  action-cache hits straight out of Xcode's own base. `ci/verify-build.sh`'s
  header carries the full measurement set and the three traps involved.
- **And it is bidirectional**, measured as a controlled pair on 2026-08-28 so
  that "it was all built already" cannot explain it. Each round changed one
  source file, so exactly one Swift module needed compiling, and the round's
  *first* builder is what proves the work was real:

  | round | compiled the change | then built | actions the follower executed |
  |---|---|---|---|
  | 1 | the gate — 1 worker action | Xcode | **0** (157 processes, every one a cache hit) |
  | 2 | Xcode — 1 worker action | the gate | **0** (1 process, 7,648 action-cache hits) |

  Xcode's follow-up build reported `** BUILD SUCCEEDED **` in 24.0s with a
  3.96s bazel phase and no `local` or `worker` term in its process summary at
  all. (Its log does print `INFO: From Compiling Swift module …:` lines — 27 of
  them — but those are bazel replaying a *cached* action's stderr, not
  executions, and none of them names the module that changed.)

- **A release build shares nothing with a debug one**, because `-c opt` with
  whole-module optimisation and `-Osize` produces different object code than
  `-c dbg`.
- **Simulator vs. device is a genuine full rebuild** — different CPU
  (`sim_arm64` vs. `arm64`). "Any iOS Device (arm64)" and a real device *are*
  the same configuration, which is why those two do share.

**How the API route works, and what it needs.** rules_xcodeproj's
`docs/usage.md` states the problem in the same terms this audit measured it: the
`xcodeproj` rule applies a configuration transition, so "building targets by
specifying their labels will build potentially different versions of those
targets, and minimally versions that have different cache keys." The answer is
to run bazel *through* the generator so it inherits the same output base,
configs and transition:

    ./build-input/bazel-8.4.2-darwin-arm64 run //Telegram:Telegram_xcodeproj -- \
        --generator_output_groups=<group> 'build --keep_going'

Two corrections to what an earlier pass of this document claimed here, both
measured:

- It does **not** require a generated project. The runner script creates the
  generator package itself at run time; verified by moving
  `Telegram/Telegram.xcodeproj` away and running the API anyway (exit 0, 1.6s).
  It *does* require `xcodeproj.bazelrc` and
  `build-input/configuration-repository`, both written by `Make.py` —
  `ci/verify-build.sh` ensures each of them.
- `--generator_output_groups=all_targets`, the form the docs lead with, is the
  wrong scope for a compile gate. `Telegram/BUILD` declares Xcode
  configurations Debug **and** Release and target environments device **and**
  simulator, so `all_targets` is four full app builds plus the UI test suite:
  measured at 26,880 actions and 1,900s. The gate asks for one configuration's
  app product through the per-target `bp <target-id>` group instead — 4,528
  actions — which is the same group rules_xcodeproj's own Xcode scripts drive.

`--experimental_output_paths=strip` (bazel's generic path-mapping feature) is
*not* an alternative: no vendored rule declares the `supports-path-mapping`
execution requirement, so Swift compiles ignore it.

`ci/verify-build.sh` defaults to the **device** configuration, because an
Xcode build on a real device now shares its cache: after one, the gate is
nearly free, while a simulator default would compile a whole second
configuration for every change. Because a device build signs the app and its
six extensions, that path also runs a signing pre-flight that hashes each
certificate the resolved provisioning profiles require and compares it against
the installed identities, catching a codesigning failure before a long build
instead of after. `tg-merge` and `sync-from-develop` use that same device
default deliberately: they run on this machine, so the device configuration is
the one whose disk-cache entries the human's own Xcode builds keep populating,
and a simulator gate would share with nothing anyone here builds. The price is
that an unattended run depends on the team development certificate; the
pre-flight is what makes that acceptable, since it fails in seconds and names
the fix instead of failing at the end of a long build.

**What "device needs a signature" actually means**, since simulator-vs-device
otherwise looks like nothing but a different CPU. For compilation that is all it
is. The difference is the last step: a device build *bundles and codesigns* the
app and its six extensions, because iOS will not install unsigned code, while a
simulator build is fake-signed and needs no certificate and no profile at all.
This fork sets `telegram_use_xcode_managed_codesigning = False`, so bazel signs
with the `match` profiles from the codesigning repository, and each of those
profiles names **one specific certificate** — which is why "some Apple
Development identity is installed" proves nothing (verified on 2026-08-27: two
personal-team identities were installed and the build still failed at
`IntentsExtension`). It is the same requirement an Xcode build for "Any iOS
Device (arm64)" already satisfies, so if that works, the gate works. Install it
with `cd ci && ./nicegram-match.sh development`; the certificate in use here
expires 2027-04-01.

**The operational trap, and what it now costs.** `xcodeproj.bazelrc` is written
by `get_project_generation_arguments()` **at generation time**, so changing
`ng_dev` (or anything else in `Make.py`'s `common_debug_args`, or
`ProjectGeneration.py`'s own two `--features` lines) without regenerating leaves
that file describing the previous configuration. Both flows read the same file,
so they stay consistent *with each other* and keep sharing; what goes stale is
the match between the configuration they build and the one `Make.py` would
produce today. Regenerate (`cd ci && ./generate-project.sh`) after any such
change.

**The gate now tells you when it stopped sharing.** A build that reuses nothing
still succeeds — the only symptom is that it took twenty minutes instead of
thirty seconds, which is easy to blame on something else. So after the build the
gate looks for bazel's own `Build options ... have changed, discarding analysis
cache` line and, if it finds one, prints a loud warning naming the options.
Getting that check right needed two scoping rules, both learned by getting them
wrong: it must ignore the **outer** base (which legitimately reconfigures twice
on every run, because `resolve_config`'s aquery and the plain `bazel run`
alternate two option sets there), and it must look at **both** inner
invocations, because the reconfiguration surfaces in whichever runs first — the
target-ids step — and the build a second later sees matching options and says
nothing. Verified to stay silent on a warm repeat, on alternating
`--device`/`--sim`, after a real Xcode build, after an Xcode Index Build, and on
a cold fresh worktree; verified to fire on a deliberately diverged
configuration.

**And the sharp edge underneath it:** if `xcodeproj.bazelrc` is *missing*, bazel
says so plainly — `Build options --//Telegram:disableStripping,
--@@rules_swift+//swift:copt, --define, and 1 more have changed, discarding
analysis cache` — and rebuilds 124,829 targets in a different configuration,
**while the target ids, and therefore the `bp <id>` output-group name, come out
byte-identical.** The `-ST-` hash tracks the transition path, not the flags. So
the id is not a witness that the configuration matches: nothing downstream can
detect the missing file, which is why `ci/verify-build.sh` guarantees it exists
before it starts.

**Reclaiming disk:** `ci/clean-caches.sh` reports every Bazel output base and
Xcode DerivedData directory on the machine and, with `--yes`, deletes the ones
whose checkout no longer exists. Deleting a worktree removes neither on its
own — and deleting a worktree does not, by itself, make its caches
reclaimable. Two things keep the recorded path alive, both measured
2026-08-28: its **bazel servers idle for three hours** (two per worktree, the
outer one and rules_xcodeproj's nested one) and an idle server **recreates its
`--workspace_directory`**; and `git worktree remove --force` can leave
gitignored build output behind (observed: 16 KB of
`Telegram/Telegram.xcodeproj/project.xcworkspace`), which is enough on its own.
Either one makes the report say `live`, i.e. "Nothing to reclaim" — which reads
like a clean machine. The script's own header carries the two commands that fix
it, and the `merge-to-develop` skill runs them. On 2026-08-27, five worktrees' output bases measured 12G, 18G, 24G, 41G,
and 60G, and a DerivedData directory reached 18G — but those are dated
observations, not a ceiling: this worktree's own output base later grew to
70G the same day. An output base has no upper bound; it grows as more
configurations get built inside it, and nothing removes it until the worktree
is deleted and `ci/clean-caches.sh --yes` is run. On this machine, that script
reclaimed 80 GB from six orphaned stores, and on 2026-08-28 another 71 GiB of
`df` free space from three (a run the report predicted at 80.8 GiB — `du`
counts what the files claim, APFS frees what is no longer shared, so expect the
figure to be optimistic). That isn't the whole story, though:
a single day of this audit's builds *consumed* about 100 GB, because every
configuration built (sim debug, device debug, and the Xcode nested base's
copies of both) keeps its own `bazel-out` tree. All of these numbers are
dated observations, not maximums, and a reader needs them together — pruning
orphans is necessary but building still costs real, growing disk.

**The disk cache is bounded**, not unbounded: `ci/nicegram.bazelrc` sets
`--experimental_disk_cache_gc_max_size=100G` and
`--experimental_disk_cache_gc_max_age=45d`. Collection runs in the bazel
server, but only once it has sat **idle** for 5 minutes
(`--experimental_disk_cache_gc_idle_delay`'s default), so it happens between
builds, never during one — a machine that never leaves a server idle will not
collect. `ci/clean-caches.sh`'s report prints the disk cache's current size so
that's at least visible.

**Where bazel flags come from**, in the order they're read. Exactly one of the
five is ours (`Make.py` is upstream's structure with one marked fork edit, not
ours):

1. `.bazelrc` — upstream's own file.
2. `ci/nicegram.bazelrc` — **ours**, reached from `.bazelrc` through one
   `try-import` at the end. Deprecation demotion, the disk-cache GC bounds,
   and `ng_dev`.
3. `Make.py`'s Python argument lists (`common_debug_args`,
   `common_release_args`, `configuration_args`) — upstream's structure, with
   one fork edit: the two Swift `copt` values in `common_debug_args` lost
   their surrounding quotes and gained `--config=ng_dev`, both for action-key
   alignment (see `ci/nicegram.bazelrc`).
4. The generated `xcodeproj.bazelrc` — written by `ProjectGeneration.py` from
   `get_project_generation_arguments()` at project-generation time (see the
   operational trap above).
5. rules_xcodeproj's own rc, from the runner's runfiles — it is what
   `try-import`s the generated `xcodeproj.bazelrc` above.

There used to be a sixth, `user.bazelrc`, generated per machine by
`ci/write-user-bazelrc.sh` to give a hand-run `bazel` the disk cache. It was
removed on 2026-08-28: sourcekit-bsp is not configured on this machine (no
`buildServer.json` or `.bsp` anywhere), `tgcalls_cli` has never been built, and
the disk cache reaches every flow that exists through `Make.py`'s command line
and the generated `xcodeproj.bazelrc`. If you do start running `bazel` by hand
and want the cache, pass `--disk_cache=$HOME/work/nicegram-bazel-cache`
yourself, or bring the script back from git history.

**Upstream dead ends we deliberately leave alone** — each costs nothing at
runtime, and removing it would only create merge-conflict surface for no
benefit:

- `.bazelrc`'s `build:dbg --features=swift.emit_swiftsourceinfo` never
  applies, because nothing in this fork passes `--config=dbg` (`-c dbg` is
  `--compilation_mode`, a different flag). `build:ng_dev` in
  `ci/nicegram.bazelrc` carries that same intent for the dev flows instead.
- `Make.py`'s `additional_args` / `add_additional_args` — stored on the
  command-line-builder object, never read by any `invoke_*` method.
- `Make.py`'s `--profileSwift` flag expands to `--config=swift_profile`, which
  no bazelrc in this repo defines, so the switch fails loudly if used. We
  don't define that config ourselves because upstream's intended semantics for
  it are unknown.

**Housekeeping, not caching:** a stale `nicegram-codesigning` keychain may
still exist on machines that ran the pre-audit lanes; it's unreferenced now and
safe to delete by hand. Every `.sh` file under `ci/` now carries
`#!/bin/bash` — on the sourced ones (`_env.sh`, `lib/*.sh`) purely as a dialect
marker for editors and `shellcheck`, since their **644 mode**, not the absence
of a shebang, is what stops them being executed. And the three scripts a human
runs by hand — `verify-build.sh`, `generate-project.sh`, `nicegram-match.sh` —
`cd` to `ci/` themselves, so none of them depends on the reader having noticed a
`cd ci &&` in a doc first.

### The `ci/` tooling

These live under `ci/` alongside the fastlane lanes but are plain bash, so
fastlane's own doc generation never lists them. They are documented here and
**not** in `ci/fastlane/README.md`: that file is regenerated from the lane list
every time any fastlane lane runs, so anything hand-written in it is silently
erased — as happened once already.

- **`ci/clean-caches.sh [--yes]`** — reports every Bazel output base
  (`/private/var/tmp/_bazel_$USER/*`) and Xcode DerivedData directory on the
  machine with its size and whether it is orphaned, and with `--yes` deletes
  the orphans. With no arguments it only reports; nothing is deleted. Run it
  after deleting a worktree — that is the case it exists for, since removing a
  worktree leaves both its output base and its DerivedData behind. Note it
  classifies DerivedData by the `WorkspacePath` Xcode records, which names the
  *generated* `<worktree>/Telegram/Telegram.xcodeproj`; a live worktree that has
  never run `ci/generate-project.sh` therefore reads as orphaned. The
  consequence is mild (DerivedData is rebuildable) but check the table before
  passing `--yes`.
- **Build logs are not kept.** Both wrappers capture their bazel output to a
  scratch directory under `$TMPDIR` and delete it on the way out (`trap ... EXIT`,
  plus `INT`/`TERM` so a Ctrl-C cleans up too). They capture at all only because
  the gate *greps* its own output — the target-ids path out of `--show_result`,
  the positive output-group assertion, the report, the divergence check — and
  every one of those reads happens inside the run. Nothing outside a run ever
  read those files: `tee` puts every line on stdout, so an interactive run has
  the whole thing in the terminal, and `tg-merge` / `sync-from-develop`
  redirect the gate into their own scratch file and read that. An earlier pass
  wrote three timestamped files per run into `ci/working_dir/logs/` and kept
  them forever — one of the three was never read by anything at all. If you want
  a copy, redirect: `./verify-build.sh > run.log 2>&1`.
- **`ci/evict-swiftpm-build.sh`** and **`ci/lib/swiftpm-build.sh`** — move
  `packages/nicegram-assistant-ios/.build` out of the package, permanently, to
  `../.swiftpm-scratch/<checkout>`. `verify-build.sh` and `generate-project.sh`
  do this themselves before touching bazel; the standalone script is for the
  **Xcode** case, which nothing can hook — Xcode runs bazel itself through the
  generated project. Without it, any bazel run fails during analysis with
  `ERROR: Cycle detected but could not be properly displayed due to an internal
  problem. Please file an issue.` That is not a bazel bug:
  `rules_swift_package_manager` digests the whole package tree, `.build`
  included, and SwiftPM's checkouts symlink to their own ancestors (the one
  bazel names is `GRDB.swift/Tests/CustomSQLite/GRDB -> ../..`). It is hard to
  read because the message blames bazel, the cycle report names `.build` but
  never the symlink, and it only appears after someone runs SwiftPM in that
  package — so a clean checkout is fine and it looks intermittent.

  **The resting state must be "outside".** SwiftPM re-creates `.build` every
  time it runs there (`swift test`, the Demo app,
  `Scripts/generate_resources.sh`), so after any of those, evict again before
  building. Four things that do **not** work, all measured: `.bazelignore`
  governs package loading, not a repository rule's digest; renaming `.build` in
  place just makes bazel walk the new name; `--scratch-path` relocates
  checkouts and products but binary targets are still read from
  `<package>/.build/artifacts`, so resource generation dies with `error:
  XCFramework Info.plist not found`; and **moving it aside for a run and
  restoring it afterwards is worse than nothing** — it cannot help Xcode, and
  putting the directory back re-arms the trap for the next Xcode build. That
  last one was shipped here and had to be replaced; `ci/tests/test-swiftpm-build.sh`
  now fails if anyone reintroduces it.

- **`ci/tests/run-all.sh`** — runs every `ci/tests/test-*.sh` and exits
  non-zero if any fails. No framework and nothing to install: plain bash
  asserting against fixture directories and fixture log files.
- **`make_py_prefix`** (a Fastfile helper, not a lane) — the one place that
  assembles the `python3 build-system/Make/Make.py` invocation prefix
  (`--bazel`, `--bazelUserRoot`, `--cacheDir`, `--cacheHost`). `build_bazel`,
  `generate_project` and `compile_check` all call it, so the three lanes cannot
  drift apart on which bazel binary or cache directory they point at — which
  they had already done before it existed.
- **The `resolve_config` lane** resolves `build-input/configuration-repository`
  — the local bazel module holding `variables.bzl` and the provisioning
  profiles — without building anything and without generating a project, via
  the one `Make.py` subcommand (`query`) that resolves the configuration and
  then does something cheap. `ci/verify-build.sh` runs it first (~11s) because
  its API path no longer goes through `Make.py build`, and without it a flipped
  `ng-env.txt` would keep building the previous environment while looking
  perfectly healthy.
- **The `compile_check` lane** has **no caller in this repo** and is kept for
  hand invocation only, like `ci/nicegram-match.sh` — do not delete it because
  a grep says it is dead. `ci/verify-build.sh` stopped using it on 2026-08-28:
  it builds plain target labels, so it cannot share cache with Xcode by
  construction. Reach for it only to answer "is the API path itself broken, or
  is my code broken?", and expect a full rebuild of whatever configuration it
  builds, since nothing else populates it:
  `cd ci && fastlane compile_check configuration:debug_arm64`. There is
  deliberately **no `--make-py` flag** on the gate any more: a blessed one-flag
  fallback invites reaching for it instead of fixing the shared cache, which is
  the thing actually worth keeping working.

### One build at a time

`ci/verify-build.sh` refuses to start while Xcode is running (`pgrep -x
Xcode`). Since 2026-08-28 the guard is about **predictability, not safety**, and
the distinction is measured. Two bazel clients on one output base are perfectly
safe: on a throwaway workspace, a second client hitting a busy server printed

    Another command (pid=N) is running. Waiting for it to complete on the
    server (server_pid=M)...

then waited 25s for the first to finish and exited 0. Nothing is corrupted. But
the gate and Xcode now share that one base and one server, and Xcode re-runs a
background **Index Build** on its own whenever a project is open — observed
directly: opening Xcode mid-session produced thousands of fresh `.o`,
`.swiftconstvalues` and indexstore writes in the nested base's simulator debug
configuration with no build requested by hand. So without the guard the gate
would sometimes sit on that one waiting line for an unbounded time and read as
hung. Refusing with an explanation is better than that.

The mechanism this rule *used* to be justified by — a shared global module
cache via `--features=swift.use_global_module_cache` in `xcodeproj.bazelrc` —
is **provably wrong**: rules_swift passes `-module-cache-path
<bin_dir>/_swift_module_cache`, which is execroot-relative, and at the time the
two flows ran in different output bases entirely, so they never shared that
path.

The claimed effect didn't reproduce either. An Xcode simulator build and a CLI
device build were run concurrently, both doing real Swift compilation,
monitored every 20s for 12 minutes. **Both succeeded:** the CLI build exited 0
in 845.1s (902 processes); Xcode reported `** BUILD SUCCEEDED **` in 943.0s
(2,935 processes). Peak swap across the run was 5040.56 MB, and it *fell* to
4999.69 MB by the end — no thrashing. Only 5 of the 36 samples showed any
compiler momentarily at 0% CPU, and none of those was a sustained stall.
Concurrency cost about 1.4x wall clock (845s concurrent vs. 606s for the same
CLI build run alone) — ordinary resource contention, not a wedge.

So: **the old mechanism is disproved and the wedge itself did not reproduce
under the conditions it was said to occur in. The true cause of any wedge, if
one exists under conditions that measurement didn't hit, is unknown.** None of
that argues against the guard — it now prevents a real, mundane thing (two
clients contending for one bazel server, plus roughly double the peak memory
demand). Do not re-assert the module-cache explanation as fact; if a wedge does
turn up, treat the cause as open.

Diagnosing a suspected wedge — check all three:

    ps -eo pid,etime,%cpu,command | grep -E "[s]wift-frontend|[s]wiftc"
    find -L /private/var/tmp/_bazel_*/ -mmin -1 -type f | head
    # and whether progress lines are still advancing in the build output

The `find` used to read `-newermt '-60 seconds'`. `-mmin -1` is used instead
because it is portable, not because `-newermt` is broken: **an earlier version
of this document claimed `-newermt` silently matches zero files on macOS, and
that is false** — `/usr/bin/find` on macOS 26.4.1 accepts `-newermt '-60
seconds'` and discriminates correctly (verified against a fresh file and one
dated 2026-01-01: only the fresh one matched). What actually fails is `find`
inside Claude Code's Bash tool, where `find` is a shell function shimming to
`bfs`, and `bfs` rejects the relative form with a loud `Invalid timestamp`
error. The lesson generalises: a utility's behaviour measured through that tool
is not necessarily the system utility's behaviour, so a claim about "macOS"
needs `/usr/bin/`-qualified evidence. Note also that this `find` runs over an
output base that easily reaches the tens of GB (see "Reclaiming disk" above),
so it takes minutes either way; watching a build log's byte count grow is the
faster progress signal in practice.

Several compilers at 0.0% CPU with growing elapsed time, no writes for
minutes, and a stalled log together are the actual signal to act on. Recovery:
kill the stuck `swift-frontend` processes, then the bazel server, then re-run
the build alone.

## The feature lifecycle

A feature moves through the same sequence of stages regardless of size, each
one owned by a single skill and producing a fixed set of artifacts:

| stage | skill | artifacts |
|---|---|---|
| start | `start-feature` | worktree + branch in both repos, change record stub, spec, plan whose last task completes the change record, ticket → IN PROGRESS |
| implement | `superpowers:executing-plans` | code, `docs/changes/<date>-<slug>.md` |
| refresh | `sync-from-develop` | merge commits in both repos |
| ship to QA | `build-to-testflight` | `build/{N}`, a TestFlight build, a change-record comment on each ticket, tickets → READY FOR QA, a Confluence row |
| bug round | `fix-qa-bugs` | fix commits on the feature branch, a change-record delta, bug linked and → DEV COMPLETED |
| land | `merge-to-develop` | squash on develop in both repos, the change record re-posted at the freeze point, branches and worktree removed |
| upstream | `tg-merge` | its own branch + worktree, and a `docs/changes` record it writes but does not deliver |
| crashes | `triage-crashes` → `diagnose-crash` | records in `docs/crashes/`; an approved fix then enters this table at "start" |

Ship to QA and bug round form a loop, not a line: a build surfaces bugs, a bug
round fixes them, the next build ships the fixes, and QA may bounce it back
again. Only `merge-to-develop` exits that loop — nothing else marks a feature
done, so don't treat a green TestFlight build as the finish line by itself.

**An upstream merge joins that loop; it does not skip it.** `tg-merge` writes
the change record and stops — it posts nothing to Jira and edits no
description — so its branch then goes through **`build-to-testflight`** like
any other feature, which is what posts the record's orientation and its links
as a comment, transitions the ticket and records the Confluence row. To that
skill a `tg-merge` branch looks exactly like a feature branch, with slug
`tg-merge-<VERSION>`. One wrinkle: its commits deliberately carry no `Task:`
trailer, so trailer-based key detection finds nothing and asks — answer with
the key on the change record's own `Tickets:` line. Only after that build does
`merge-to-develop` land it. Handing `tg-merge` straight to `merge-to-develop`
would route around the only skill that delivers the change record, leaving it
written and unread.

## Crashes

Production crashes are triaged through two skills and one registry, so that the
analysis accumulates instead of being redone. `triage-crashes` runs a round —
verify what we shipped, pick the live version, rank and triage its top crashes;
`diagnose-crash` takes one crash in its own session and finds the root cause.
Several diagnoses run in parallel.

**`docs/crashes/` is the single source of truth** — one markdown file per
Crashlytics issue, keyed by issue id, with a flat frontmatter header over mostly
prose. `README.md` there is generated and must never be hand-edited; on a
conflict, discard both sides and regenerate. The tree is stripped from the
public mirror.

**A diagnosis never writes app code.** It reports, drafts a patch, and stops for
a human decision. An approved fix is an ordinary feature via `start-feature`,
one per crash — which is why the lifecycle table above has a row for this. Two
rules bind every diagnosis: never remove a `fatalError` or `assert` to make a
crash go away (that trades a visible crash for silent data corruption), and
"upstream race — do not touch it" counts as a successful diagnosis, because a
session under pressure to produce a patch will patch someone else's engine on a
theory.

The status chain has one owner per transition: `triage-crashes` opens a record,
`diagnose-crash` decides it, a fix feature's **first** plan task sets `fixing`,
`merge-to-develop` sets `shipped` when it lands, and the next round's verify
pass closes it as `verified` or reopens it as `regressed`. `tg-merge` also reads
the registry, reporting where an upstream change touches an open crash's files.

## Cross-repo feature workflow

`nicegram-assistant-ios` is vendored as a git submodule at
`packages/nicegram-assistant-ios` and consumed as a local SwiftPM path
package, so **assistant edits reach the build with no push and no re-pin**.

A feature spanning both repos uses **one worktree and two same-named branches**:

    .claude/worktrees/<slug>/                     branch feat/<slug>
      packages/nicegram-assistant-ios/            branch feat/<slug>

### Starting a feature

**Use the `start-feature` skill.** It runs
`.claude/scripts/new-feature-worktree.sh <slug>`, which creates that pair of
worktree and branches in one step and prints the worktree path on stdout (all
git chatter goes to stderr, so `WT="$(…)"` captures the path alone).

**The branch name is load-bearing — the rest of the toolchain keys on it.**
`build-to-testflight` resolves `origin/feat/<slug>` for every feature it
builds and locates each feature's assistant checkout by that same ref;
`fix-qa-bugs` finds a feature's worktree with `git branch --list
'feat/<slug>'`; `merge-to-develop` cites this very section for the worktree
slug it removes. A worktree created any other way does not get that name:
the harness's `EnterWorktree` tool names the host branch
`claude/<slug>-<hash>`.

That is not hypothetical. Measured on this machine on 2026-09-01 —
`git worktree list` reported host branches `develop`,
`claude/testflight-build-skill-c6db7e` and
`claude/speech-to-text-refactor-93dba0`, while all four `feat/*` branches
(`ai-chat`, `ai-context`, `auto-telegram-login`,
`core-remote-config-firebase-migration`) were held by no worktree at all.
**Both live features were in the `claude/*` state.** Their *assistant*
branches are still named `feat/<slug>`, which is exactly why
`build-to-testflight` keys its assistant search on the assistant branch
rather than the host one.

So create feature worktrees with `start-feature`. A feature that already sits
on a `claude/*` host branch is not broken — `fix-qa-bugs` §2 and
`build-to-testflight`'s Phase 0, under "Getting the branch wrong halts under
two different letters", each say what to do — but say so as an input rather
than letting a skill infer a host branch name that does not exist.

**Creating and entering the worktree is one shared procedure**,
`.claude/reference/entering-a-worktree.md` — the script above, then
`EnterWorktree` and `change_directory`, then an assert that the move happened.
`start-feature` and `tg-merge` both follow it, so change the flow there rather
than in either skill.

Two of its consequences reach the rest of this document. An entered worktree
**clamps git to itself**: redirecting git at the main clone is refused, and so
is any `-C` whose argument is a shell variable, even one pointing inside the
worktree — the check is static and reads the command text, and shell state does
not survive between Bash calls. And `EnterWorktree` does not move the **file
viewer**, which is why the procedure also calls `change_directory`; without that
second call every file link written during feature work comes back "Couldn't
find this file".

So: **`start-feature`, `superpowers:executing-plans`, `sync-from-develop` and
`merge-to-develop` run inside the feature worktree; `build-to-testflight` and
`fix-qa-bugs` run from the main clone, in a session that has not entered one.**
Those two are written throughout in the variable `-C` form — deliberately, so
that a failed `cd` cannot silently leave a command operating on the wrong
repository — and that form does not survive the clamp. The worktree skills are
the opposite: bare git from the working directory, the one shape the clamp
permits. `merge-to-develop` is the awkward one — it has to land from the
worktree, because its landing procedure diffs and pushes `HEAD`, and then leave
with `ExitWorktree` before cleanup, because the removal deletes the directory
the shell was standing in.

**Each of those skills now opens with its own `## Where this runs` section**,
naming the position and carrying a probe that halts rather than guessing. That
section, not this paragraph, is what a skill is executed against; this one only
says how the set fits together.

Everything below this line is **background**: what the script already does and
why each step is shaped that way. None of it needs running by hand.

**The base ref is asserted, not trusted.** The script passes `HEAD` explicitly
to `git worktree add -b`, so it does not depend on `.claude/settings.json`'s
`worktree.baseRef: head` — that key governs `EnterWorktree` (the Claude Code
changelog shows it shipping in v2.1.133 with values `fresh` | `head`, and the
CLI installed here is newer). What the assertion catches is a different, real
failure: the main clone sitting on the wrong branch when the worktree was
created.

    git -C "$MAIN" log --oneline -1 develop     # want
    git -C "$WT"   log --oneline -1             # got

On a mismatch the script exits 1 and tells you to branch the worktree onto
`develop` before continuing.

**Submodules are cloned from the main clone's own gitdirs, not the network** —
measured at ~4 s for all 14, versus refetching ~550 MB. That needs
`protocol.file.allow=always`: git blocks file-protocol submodule transports by
default (CVE-2022-39253) and otherwise fails with `fatal: transport 'file' not
allowed`.

Three guards in that loop each exist because their absence has a silent
failure mode, and they are the same three `ci/bootstrap-submodules.sh` carries:

- **Ask git for each gitdir; don't construct `$MAIN/.git/modules/<path>`.**
  That construction is wrong for at least one submodule —
  `packages/nicegram-assistant-ios` stores its gitdir at the legacy path
  `.git/modules/Nicegram/packages/nicegram-assistant-ios`. And **guard the
  lookup**: `git -C <dir> rev-parse --absolute-git-dir` walks *up* to the
  enclosing repo and returns *its* gitdir with exit 0 when `<dir>` exists but
  isn't itself a repository — confirmed empirically with an empty directory
  inside a throwaway repo. Without an `[ -e "$MAIN/$p/.git" ]` test first, the
  loop clones the *superproject* into the submodule's path, fails confusingly,
  and leaves a non-empty directory that blocks a retry.
- **`git submodule sync` is scoped to the one path** it initializes. An
  unscoped sync rewrites `submodule.<name>.url` for *every* submodule in
  `.git/config` — which a worktree **shares with the main clone** — clobbering
  any deliberate local URL override.
- **`git submodule status` is parsed with `sed`, not `awk '{print $2}'`.**
  Whitespace field-splitting silently truncates any submodule path containing
  a space at its first word; this repo has 1661 tracked paths with spaces.

Nothing else is needed: `Make.py` regenerates `build-input/`,
`build-input/configuration-repository`, and `xcodeproj.bazelrc` itself.

**Bootstrapping is not a build prerequisite either.** `ci/verify-build.sh` and
`ci/generate-project.sh` both run `ci/bootstrap-submodules.sh` before anything
else and initialize whatever is missing — see "Build" above for why that
exists. It brings submodules to their currently pinned commit; it does not
create branches, which is the part `new-feature-worktree.sh` still owns.

Builds from the worktree need `TELEGRAM_CODESIGNING_GIT_PASSWORD`; `ci/fastlane-env.sh`
is untracked and absent in a fresh worktree, but the `ci/` wrappers fall back to the
main clone's copy automatically — see "Build" above. No manual sourcing needed.

### Conventions

- Branch names are `feat/<slug>` in **both** repos, with no ticket key. The
  ticket goes only in the commit trailer (`Task: NCG-XXXX`).
- One spec and one plan, both in this repo under `docs/superpowers/`, with plan
  tasks tagged `[ios]` / `[assistant]`.
- Worktrees live under `.claude/worktrees/`, which is listed in `.bazelignore`
  (a nested worktree copies the root BUILD files and Bazel would otherwise
  discover it as a package) and covered by `.gitignore`'s pre-existing blanket
  `/.claude/*` rule — it has no entry of its own.
- **When the assistant gains a new dependency**, re-resolve this repo's
  `Package.resolved` (`swift package resolve`) and commit it with the feature.
  This is the only case left that touches `Package.resolved`; ordinary code edits
  never do.
- **Merge-watch files** — an upstream merge can clobber either of these; check
  both after every upstream merge:
  - `.gitmodules` — carries a `# MARK:` comment marking the private submodule
    stanza; re-add the stanza if a merge drops it. Note that any future
    `git submodule add` / `git submodule deinit` rewrites this file from
    scratch and silently drops the `# MARK:` comments, so re-mark it by hand
    afterward.
  - `Package.swift` — must stay `.package(path: "packages/nicegram-assistant-ios")`;
    never let a merge revert it back to a remote git URL dependency.
  - `Telegram/BUILD`'s `associated_domains_fragment` — must keep generating its
    `applinks` entries from `NICEGRAM_ALL_DOMAINS`; see "The web domain" above.
  - `docs/tg-merge/state.json` — the merge skill's only record of the last
    merged upstream commit. Never hand-edit the sha to make a check pass; a
    wrong base silently produces a plausible merge against the wrong upstream.
    Both this file and `docs/tg-merge/reports/` are stripped from the public
    mirror by `bitbucket-pipelines.yml`.
  - `bitbucket-pipelines.yml`'s strip lists — `docs/crashes` must stay in
    **both** of them (the `rm -rf` and the staged-path guard), exactly like the
    four trees beside it. `ci/tests/test-mirror-strip.sh` catches a tree dropped
    from one list but not a tree dropped from both, which is what an upstream
    merge that rewrites this file would do.

### Building for QA

    cd ci && ./build-to-testflight.sh "<version> (<build>)"

**Preconditions, in this order:**

1. The assistant feature branch is **pushed** (not merged — the branch stays open).
2. The host's submodule pointer is **committed** at that pushed commit.

The script pushes the current host branch, then triggers the Bitbucket
`push-to-github-repo` pipeline on it, which mirrors to GitHub `beta`, where
`.github/workflows/beta.yml` checks out with `submodules: 'recursive'` and builds.
An assistant commit that exists only locally fails at that checkout, so both
preconditions are about making the SHA fetchable — not about merging.

The mirror step also strips five trees before pushing — `.claude/`,
`docs/superpowers/`, `docs/tg-merge/`, `docs/changes/` and `docs/crashes/` — so
fork-internal tooling, process docs, the upstream-merge state, the change
records and the crash registry never reach the public GitHub repo; all five stay
fully tracked in Bitbucket. Keep
this list in step with `bitbucket-pipelines.yml`, which names each tree
**twice**: once in the `rm -rf` and once in the staged-path assertion right
after it. `ci/tests/test-mirror-strip.sh` asserts the two lists cannot drift
apart, so a tree added to one and not the other fails the suite rather than
leaking quietly. It also asserts the old `docs/qa` name survives nowhere in
that file, which is what covers the third mention — the comment explaining
why the tree is stripped, which no list-parsing check can see.

`docs/changes/` is stripped for the same reason as the rest: change records
describe gating and remote-config behaviour in terms only the team should read.
`docs/crashes/` is the newest member — the crash registry states crash volumes,
affected-user counts, and our written judgement that specific upstream Telegram
bugs are abandoned, which reads differently in public than inside the team.

This only stops **future** disclosure —
`docs/superpowers/` predates this exclusion, so if the mirror was pushed while
those files existed, that content may already be public, and the next mirror
push will simply record their deletion. (The private submodule's URL still
appears in the mirror's `.gitmodules` by necessity, since the release build
needs it to resolve; that is unchanged and already documented above.) Any new
fork-internal-only tree added later needs the same `rm -rf` plus a staged-path
assertion in `bitbucket-pipelines.yml` — otherwise it quietly starts shipping
to the public mirror. This paragraph is what an upstream merge is resolved
against, so a tree missing from it here is a tree that gets dropped there.

### Landing a feature

Use the `merge-to-develop` skill. It merges the assistant first, then bumps and
merges the host, verifying before each branch deletion that the merged `develop`
tree matches the branch being deleted.

The order is not a preference: the host records a submodule SHA, so a host PR
merged while pointing at an unmerged assistant commit leaves `develop`
referencing a commit nobody else can resolve.

### Verifying

- Full app: `cd ci && ./generate-project.sh` in the worktree, then Xcode.
  (An earlier version of this document said project generation runs `killall
  Xcode`. It does not: `grep -rln "killall Xcode"` over every `*.sh`, `*.swift`,
  `*.py` and `*.bzl` in this repo finds exactly one hit — that claim's own
  comment — and rules_xcodeproj's installer neither kills nor opens Xcode.
  Generation is headless, which is why `ci/verify-build.sh` can run it itself
  when `xcodeproj.bazelrc` is missing.)
- Assistant only: the `Demo/` app inside the submodule — a plain SwiftPM build,
  no Bazel. See its `README.md`.

## Delegating to subagents

The rules in `.claude/rules/` auto-attach by path for *your* session. A subagent
you dispatch does not inherit your context, so whatever you paste into its
prompt becomes its entire rulebook.

**Never hand a subagent a hand-written summary of these conventions.** A
summary silently replaces the real rules with your recollection of them, and
the subagent has no way to know something is missing. Instead, name the files:

> Binding conventions: read `packages/nicegram-assistant-ios/.claude/rules/swift-conventions.md`
> and `module-structure.md` before writing code. The constraints below are
> supplementary to those files, never a replacement.

The same applies to reviewers — a reviewer never asked to check against
`swift-conventions.md` will not check against it. Give every reviewer the rules
files that match the paths in its diff as a named check.

**Consistency with the surrounding code never outranks a written convention —
in either direction.** Do not triage a reviewer's finding away as "pre-existing
pattern", and do not *introduce* a violation because the neighbouring files
already have it. If the neighbours are wrong, follow the rule and say so.

Both directions have already failed once. Dismissing a finding as pre-existing
let a hand-written initializer ship in a package whose rules say to use
`@MemberwiseInit`. In the other direction, an implementer added a redundant
`@available(iOS 15.0, *)` "to match the four sibling formatters", disclosed it
honestly as a judgment call — and the task reviewer **approved** it, because the
siblings really did look like that. 471 files in the package carry the same
redundant attribute. A majority is not a convention.

## A plan is where conventions are won or lost

`.claude/rules/` attach by the path of a file in context. A spec or a plan is
markdown, so **no Swift rule ever attaches while you write one** — and a plan is
exactly where type shape, field order, initializers and DI wiring get decided.
Every implementer then transcribes it verbatim.

This is not hypothetical. The `CoreRemoteConfig` migration plan specified a
hand-written `init`, non-alphabetical stored properties, a computed `var` on a
class whose other members were functions, a service constructing its own
`HttpClient` instead of receiving it from the container, and redundant
transitive dependencies. Every one reached the code, and the human caught all of
them in review. Note that `module-structure.md` — which is always loaded — says
"Build initializers with `@MemberwiseInit`" and was in context the whole time.
**Presence in context is not application.** The check has to be deliberate.

The same gate then missed again on the speech-to-text design: the naming rule it
violated lives in `packages/nicegram-assistant-ios/AGENTS.md`, not in
`.claude/rules/`, and the names were decided in a module-layout tree rather than
a code block — hence the two widenings below.

So, before a spec or plan is shown to the human — whenever it contains code
blocks **or names any type, file or module**:

1. List the paths the plan will create or modify.
2. Read every `.claude/rules/*.md` whose `paths:` match them, in both repos,
   plus the always-on ones, **plus both repos' `AGENTS.md` and `CLAUDE.md` —
   conventions live there too, not only in `.claude/rules/`.**
3. Go rule by rule through the files you just read, checking the plan against
   each — not dimension by dimension from a remembered list. Naming, field order,
   initializers, access modifiers, DI wiring, dependency declarations and error
   handling are examples, not the set: both rules missed on the speech-to-text
   design (`Polymorphism`, "keep a type's public surface uniform") were in a file
   already read but absent from an earlier version of this list.
4. Then ask what the rule-by-rule pass cannot: **for every type the plan invents,
   does the codebase already provide the shape it should take?** A hand-written
   storage type breaks no style rule and is still wrong where `data-layer.md`
   names `UDRepository` and `{Name}Repository`. `public` is the same trap: it is
   correct only with a consumer outside the package — a fact about the tree, not
   about the block.
5. Then dispatch a **plan conventions reviewer**: a subagent given the plan and
   those rules files, asked 3 and 4 as a named checklist rather than open prose —
   which code blocks *or names* violate these? Self-review does not catch your
   own blind spots — the self-review on that same plan passed while all eight
   violations sat in it.

**This gate has failed four times, each differently** — not run because a rule
could not attach, not run at all, run but scoped to style while a hand-rolled
`UserDefaults` store and 77 unjustified `public` symbols passed, and run against
`.claude/rules/` alone while the naming rule it needed sat in `AGENTS.md`. If it
fails again, mechanise the checklist instead of rewording it.

**A plan carries its inputs; it does not tell the implementer to go and get
them.** This is a separate axis from the gate above, which checks conventions —
design values are inputs, so it would not have caught this even had it run. The
`remove-crypto-wallet-ui` plan said "spacing, padding, corner radii and exact
shades come from the Figma frames — open the named frame rather than inventing
them", in a preamble bullet, above tasks whose code blocks already held invented
numbers. Nobody opened the frame: an implementer executes tasks, and a sentence
that names no tool, produces no artifact and fails nothing when skipped is not a
task. If a value is needed to write the code, the planning session fetches it and
writes it in. For a design, that is `read-figma-design`'s extraction: every UI
task cites the frames it implements and carries every visual value in its code,
and the skill's design-inputs check fails a plan that defers one to "take it from
Figma".

**Every feature plan ends with a change-record task.** The document is
`docs/changes/YYYY-MM-DD-<slug>.md`, in English, following
`docs/changes/TEMPLATE.md`, and it is written during implementation — not at
planning time — because it describes what was actually built. `start-feature`
may already have created it as a stub when a ticket key or a design artifact was
given — or `read-figma-design` may have, when a design arrived later — in which
case the task **completes** that file rather than creating one; either way it
ends with this feature's key, when there is one, in the `## Delivery` table's
`pending` row, and with the template's instruction comment deleted — a record
that still carries it halts the next build under halt (l). It carries a
`Tickets:` header line naming a real ticket, or none at all when there is no
ticket — never a placeholder — keeps an existing `## Design` section byte for
byte, and meets the five obligations `start-feature` states in
full: orientation, sufficiency for both another platform and the full test
spectrum, reachability (the gates in evaluation order), known-and-intentional
behaviour, and reference-don't-duplicate. This requirement lives here, and in
`start-feature`, deliberately: a `.claude/rules/` file keyed on
`docs/changes/**` would never attach while a plan is being written, which is
the same failure this section already documents.

## Designs (Figma)

A **design artifact** is whatever Figma links are handed over for a feature — a
page, a section, a frame, several of them — at any stage, including after the
logic has shipped. It is recorded in the feature's change record under
`## Design` the moment it arrives, so no later session has to ask for it again.

The `read-figma-design` skill owns everything from there: intake and recording,
extraction with read-only scripts, the design-inputs check on a plan, the
fidelity check on code, and what to do when a Figma call fails. The mapping from
Figma names to our code — colours, text styles, icons, geometry — lives beside
that code, in `packages/nicegram-assistant-ios/.claude/reference/figma-to-code.md`.
A prompt hook names the skill whenever a message carries a Figma link.

Two rules bind all new and changed UI code, with a design or without one:
**design system only** — text styles and colours the design system defines,
nothing else — and **no value without a source** — nothing by eye, nothing from a
screenshot. Both are written out in the package's `swiftui-views.md`.

**With no design yet** — logic first, the design as a later iteration — the UI
uses only existing components and design-system tokens and styles, and any new
visual value is a human decision recorded in the spec as "interim, no design". No
link exists then, so the skill never loads; this paragraph is what carries the
rule.

## Newer APIs beat older deployment targets

When a newer system API makes the code clearly simpler, use it and mark that
feature `@available(iOS N, *)`, gating its entry point so older versions simply
do not see it. Clean, simple code outranks reaching older iOS versions. Do not
quietly hand-roll an uglier shape to preserve a floor.

Propose the trade-off and get agreement first — except `UIHostingConfiguration`
(iOS 16), which is pre-approved and is the prescribed UIKit-interop shape in
`presentation-layer.md`.

## Plans are test-first where tests are worth having

`packages/nicegram-assistant-ios` has a test target and a ~10-40s test loop, so
"this repo has no test framework" is no longer a reason to skip TDD. It was the
standing, never-negotiated excuse through the whole `CoreRemoteConfig`
migration, and it expired.

A plan task touching **pure logic** — a use case, parsing or mapping, a cache,
value resolution — states its test first and its implementation second, so the
implementer can watch it fail before making it pass. A task touching UI, DI
wiring, a `TelegramBridge` or network transport does not: a test there asserts a
mock and proves nothing, and the review rubric counts one as a defect.

See "Testing" in `packages/nicegram-assistant-ios/AGENTS.md` for the framework,
the run command, and the two ways a test run can look green without having run.

**Tests go in `packages/nicegram-assistant-ios` only.** This repository gets no
test target. `Tests/AllTests` already fails to build (it references a dangling
`//submodules/TgVoipWebrtc:TgCallsTests`), nothing runs app-side tests routinely,
and a plan that adds one here is adding infrastructure with no consumer. Host
changes are verified by `ci/verify-build.sh` and by reading the build's own
output — a generated entitlement, a generated source.

## Simplicity outranks completeness

Prefer the simple, clean implementation. When a requirement can only be met by
building something intricate — a bespoke mechanism, a workaround for a platform
limit, state threaded through several layers — **stop and propose the
trade-off** rather than building it quietly. We are often willing to give up the
requirement to keep the code simple: a reduced version of the affordance, the
affordance only where it is cheap to provide, or not shipping it at all.

Gating a feature behind `@available(iOS N, *)` because the newer API is the
clean one is a standard instance of this, and so is showing a nicety only on the
OS versions where it costs nothing.

"The design says so" does not exempt a requirement from that conversation. A
mockup is a proposal about what the user sees, not a budget for how much
machinery we build to show it.

## Learning from review feedback

When the human gives feedback on a spec, a plan, or code, they may ask you to
**invoke the `learn-from-feedback` skill**. It applies the corrections and then
repairs whatever let each one through, so the same correction is not needed
twice.

**Only invoke it when asked.** Not all feedback should change the instructions —
corrections during brainstorming are the design converging, not a rule failing.
The human decides. The skill never commits an instruction change without
showing it for approval first.

## Comments in our code

Comment only what the code cannot say — a non-obvious constraint, or a decision
a reader would otherwise undo. Do not restate the code, and do not doc-comment a
member whose name already says it. This holds for **every file we write**, in
both repositories and whatever the language: Swift, `BUILD`, `.bzl`, the
Fastfile, shell.

It **overrides** `CLAUDE.md`'s "Document public APIs with comments", which is
upstream Telegram's convention and stays in force for upstream code. Do not
restyle upstream comments — and the `// Nicegram …` markers are not commentary,
they are required by `telegram-interop` and stay whatever this says.

It lives here, not in a `.claude/rules/` file, because no such file can reach
it: rules attach by path, and `Telegram/BUILD`, `Nicegram/**/*.bzl` and `ci/**`
match none of them — which is where the worst of it accumulated.

## Detailed conventions (`.claude/rules/`, auto-attached by path)

- `telegram-interop.md` — editing `submodules/**`: marker syntax + SSignalKit
  bridges.
- `nicegram-modules.md` — `Nicegram/**` modules, `NGUtils`, resources.
- `swift-conventions.md` — Swift style for our code.
- `assistant-package.md` — `packages/**` — vendored submodule, read
  the assistant's own rules.

`CLAUDE.md` at the repo root is upstream Telegram's own file, not ours — except
for three fork-owned spots: its marked "Nicegram branding overrides" subsection
(hand-maintained, preserved across every upstream merge), the two-line import at
the top that pulls this file in, and the `<!-- Nicegram: … -->` build-values
marker comment near the top of the file, flagging that its Build section's
values are upstream's, not this fork's. Aside from those fork-owned spots,
`CLAUDE.md` stays the authority on the embedded watch app, the Postbox →
TelegramEngine refactor, and the tgcalls testbench — but its Build section's
cache dir, config path,
codesigning repo, and password source are upstream's own values and don't work
here; see "Build" above for the ones that do. This file covers what the fork
adds.
