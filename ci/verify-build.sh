#!/bin/bash
#
# Local compile gate. Used by hand and by the tg-merge / sync-from-develop
# skills, so it must work headless, with or without Xcode running, and with no
# Xcode project checked out.
#
# Keep the #!/bin/bash line: ci/_env.sh's worktree credential fallback depends
# on it (under /bin/sh a failed `.` on a missing file kills the shell before the
# `||` alternative can run).
#
# Nicegram Build cache
# This gate runs bazel THROUGH rules_xcodeproj's command-line API rather than
# invoking `bazel build Telegram/Telegram` itself, so that its actions have the
# same cache keys as an Xcode build and the two flows share work. Measured
# 2026-08-28, same worktree, same code:
#
#   before (Make.py build, device):  1114s, 0 cache hits after a successful
#                                   Xcode device build of the same commit
#   after  (this API path, device):     6s, every action a cache hit
#
# The reason the old path could never share is structural and was measured to
# death in the previous pass: the `xcodeproj` rule reaches its configuration
# through a Starlark transition, so its bazel-out directory carries a different
# `-ST-<hash>` suffix (`ST-9cbb67e27a8f`) than a plain label build
# (`ST-a7beea3c269e`); output paths are part of every action key, so nothing
# matched no matter how the flags were aligned. See ci/nicegram.bazelrc's
# ng_dev comment for that trail. rules_xcodeproj documents this and provides
# this API as the answer (build-system/bazel-rules/rules_xcodeproj/docs/usage.md,
# "Command-line API").
#
# Three non-obvious things about the API, each verified by measurement:
#
#  1. It does NOT need a generated `.xcodeproj`. The runner script creates the
#     generator package itself at run time (templates/runner.sh:124-131);
#     the installed project is only used by the generation branch. Verified by
#     moving Telegram/Telegram.xcodeproj away and running this path: exit 0.
#     It DOES need `xcodeproj.bazelrc` (below) and
#     build-input/configuration-repository.
#
#  2. `--generator_output_groups=all_targets`, the form the docs lead with, is
#     the wrong scope for a compile gate: Telegram/BUILD declares Xcode
#     configurations Debug AND Release and target environments device AND
#     simulator, so `all_targets` is four full app builds plus the UI test
#     suite. Measured: 26,880 actions, 1900s, with 1129 log references to
#     `bazel-out/ios_arm64-opt-...`. This gate asks for one configuration's app
#     product instead, through the per-target `bp <target-id>` output group --
#     the same group rules_xcodeproj's own Xcode scripts drive (see
#     bazel_integration_files/generate_index_build_bazel_dependencies.sh).
#     Measured: 4,528 actions for the Debug device app. That group is not
#     perfectly one configuration -- alongside the requested configuration's
#     products it carries a dozen rules_xcodeproj-generated Info.plists in each
#     of the other three, which is why --show_result prints paths under
#     `-opt-` and `ios_sim_arm64` directories even on a device run. Those are
#     plist-writing actions, not compiles: the whole run is ~146 processes
#     against 26,880 for all_targets.
#
#  3. A `bp <target-id>` group name that does not exist is NOT an error: bazel
#     exits 0 and prints "Build completed successfully, 1 total action" having
#     built nothing. Verified with a deliberately bogus id. So this script
#     derives the id from the target-ids file the build itself produces, and
#     then asserts, positively, that the build reported outputs under the
#     expected configuration directory. Without that assertion a rules_xcodeproj
#     upgrade that renamed the group would turn this gate permanently green.
#

cd "$(dirname "$0")" || exit 1

# Nicegram Build cache
# Defaults to the DEVICE configuration. That default was flipped back from the
# simulator on 2026-08-28, when the cache sharing above became real: an Xcode
# build on a real device and this gate now request the same configuration, so
# the gate is nearly free after one, and a simulator default would instead
# compile a whole second configuration for every change. tg-merge and
# sync-from-develop deliberately do NOT pass --sim either: they run on the same
# machine, so the device configuration is the one whose disk-cache entries the
# human's own Xcode builds keep populating -- a simulator gate would share with
# nothing anybody here builds.
#
# The cost of that is real and accepted: a device build signs the app and its
# six extensions, so an unattended run depends on the team development
# certificate. The pre-flight below is what makes it acceptable -- it fails in
# seconds, before any compilation, and names the fix.
#
# Parsed here, before bootstrap-submodules.sh, so --help and an unknown
# argument exit immediately without waiting on submodule init or starting
# any build.
CONFIGURATION=""
for arg in "$@"; do
  case "$arg" in
    --device) CONFIGURATION="device" ;;
    --sim)    CONFIGURATION="sim" ;;
    -h|--help)
      echo "usage: ci/verify-build.sh [--device|--sim]"
      echo "  --device  compile for arm64 device -- shares cache with an Xcode"
      echo "            build on a real device, and runs the signing pre-flight,"
      echo "            since a device build signs the app"
      echo "  --sim     compile for the arm64 simulator (no signing)"
      echo ""
      echo "  With no flag the destination comes from NG_BUILD_DESTINATION"
      echo "  (device|sim), and from 'device' if that is unset too. Set it in"
      echo "  the untracked ci/fastlane-env.sh to change it for every caller,"
      echo "  including the tg-merge and sync-from-develop skills."
      exit 0
      ;;
    *)
      echo "verify-build: unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done
#

# No Xcode guard, deliberately. Output bases are per worktree, so Xcode on
# another checkout shares no bazel server with this run. Xcode on this checkout
# makes bazel print "Another command (pid=N) is running. Waiting for it to
# complete on the server" and wait its turn.

./bootstrap-submodules.sh || exit 1
. ./_env.sh

# Nicegram Build cache
# THE one place the destination is decided, in this precedence order:
#
#   1. --device / --sim on the command line
#   2. $NG_BUILD_DESTINATION
#   3. device
#
# Everything downstream derives from $CONFIGURATION alone -- the signing
# pre-flight, the target-id prefix, and the report label -- so there is no
# second copy of the default anywhere, and callers that want the default (the
# tg-merge and sync-from-develop skills pass no flag at all) inherit it.
#
# Put NG_BUILD_DESTINATION in the untracked ci/fastlane-env.sh: that is the
# per-machine mechanism this repo already has, and the choice IS per-machine --
# the disk cache is local, so it only ever needs to match what you build in
# Xcode on this machine. A colleague who runs the app in the Simulator sets it
# once and every caller follows; ng-env.txt is the wrong home for it, being
# tracked and therefore project-wide.
#
# Resolved HERE rather than at argument-parsing time because `. ./_env.sh` is
# what sources ci/fastlane-env.sh, and that is the line above. Argument parsing
# deliberately stays before bootstrap-submodules.sh so --help and a typo still
# answer instantly.
#
# The value is validated rather than treated as a two-way branch. Without this,
# NG_BUILD_DESTINATION=simulator -- a plausible typo -- would fall through every
# `= "device"` test and silently build the simulator while the operator believed
# otherwise. That is the same class of quiet-wrong-default this whole branch has
# been hunting.
if [ -z "$CONFIGURATION" ]; then
  CONFIGURATION="${NG_BUILD_DESTINATION:-device}"
fi
case "$CONFIGURATION" in
  device|sim) ;;
  *)
    echo "verify-build: NG_BUILD_DESTINATION must be exactly 'device' or 'sim'," >&2
    echo "verify-build: got: '$CONFIGURATION'" >&2
    exit 2
    ;;
esac
#

# The Simulator runtime and the Metal Toolchain: both destinations need them,
# and without them the build fails minutes in rather than here, in seconds.
# After `. ./_env.sh`, in case this machine's fastlane-env.sh exports
# DEVELOPER_DIR.
# shellcheck source=lib/xcode-preflight.sh
. ./lib/xcode-preflight.sh
ng_xcode_preflight || exit 1

# Nicegram Build cache
# A device build signs the app and its six extensions, so it needs a
# development identity in a keychain. Check now: without this the failure lands
# at the very end of a ~20-minute build, after all the compilation is done.
#
# The obvious check --
#   security find-identity -v -p codesigning | grep -q "Apple Development"
# -- is WORTHLESS here, and was verified so on 2026-08-27: this machine had two
# "Apple Development" identities (personal-team certs) while the device build
# failed with `Unable to find an identity on the system matching the ones in
# .../Intents.mobileprovision`. The profiles resolved from the codesigning
# repository name ONE specific certificate each, and having some unrelated
# development cert installed proves nothing. A check that reports green and lets
# the build fail twenty minutes later is worse than no check at all.
#
# So compare against what the RESOLVED PROFILES actually require: hash each
# DeveloperCertificates entry in the provisioning profiles Make.py wrote, and
# require at least one of those SHA-1s to appear in the installed identities.
#
# Placed here (after `. ./_env.sh`, not before bootstrap-submodules.sh) because
# it needs $SOURCE_PATH, which _env.sh is what defines: inserting it any
# earlier would resolve prov_dir against an empty SOURCE_PATH (silently
# becoming "/build-input/...", i.e. the filesystem root) and the check would
# always take the "never resolved yet" branch, regardless of whether profiles
# actually exist -- exactly the "reports green, proves nothing" failure this
# check exists to avoid. Still runs well before the build starts.
#
# Ordering caveat, worth knowing rather than restructuring for: this runs
# BEFORE the `resolve_config` step below, which deletes and re-fetches the
# provisioning directory. So on the first run in a fresh checkout it takes the
# "no profiles yet" branch and only warns, and if a freshly fetched profile
# ever started requiring a certificate the previous one did not, this check
# would have read the old requirement. It is deliberately placed here anyway:
# what it tests is which CERTIFICATE is installed, which no step of this script
# changes, and the check sits on the one path there is.
if [ "$CONFIGURATION" = "device" ]; then
  prov_dir="$SOURCE_PATH/build-input/configuration-repository/provisioning"
  if [ ! -d "$prov_dir" ] || [ -z "$(ls "$prov_dir"/*.mobileprovision 2>/dev/null)" ]; then
    # Case 1: no profiles present at all. Never resolved on this checkout yet,
    # so there is nothing to compare against. Warn rather than block: Make.py
    # resolves the profiles itself and a first run is legitimately in this
    # state.
    echo "note: no resolved provisioning profiles yet; skipping the signing pre-flight."
  else
    required="$(for f in "$prov_dir"/*.mobileprovision; do
      security cms -D -i "$f" 2>/dev/null | python3 -c '
import sys, plistlib, hashlib
try:
    d = plistlib.loads(sys.stdin.buffer.read())
except Exception:
    sys.exit(0)
for c in d.get("DeveloperCertificates", []):
    print(hashlib.sha1(c).hexdigest().upper())
'
    done | sort -u)"
    if [ -z "$required" ]; then
      # Case 2: profiles are present but nothing could be extracted from any
      # of them. Distinct from case 1 above -- this only fires when
      # .mobileprovision files exist but `security cms -D` failed to decode
      # every single one. That fails closed, most commonly from an expired
      # Apple WWDR intermediate certificate, but also from a corrupted or
      # truncated profile. This must never fall through silently: the whole
      # point of this pre-flight is catching a signing failure before a
      # twenty-minute build instead of after, and a check that says nothing
      # here removes exactly the suspicion that would otherwise send someone
      # to look at signing first. Not a hard failure -- the build may still
      # succeed -- so warn loudly and continue rather than block.
      echo "WARNING: provisioning profiles were found but none could be decoded,"
      echo "so the certificate requirement could not be determined. A common"
      echo "cause is an expired Apple WWDR intermediate certificate. The build"
      echo "may still fail at codesigning."
    else
      # Case 3: profiles decoded and named at least one required certificate --
      # the only case where the comparison against installed identities means
      # anything.
      installed="$(security find-identity -v -p codesigning 2>/dev/null \
        | sed -nE 's/^[[:space:]]*[0-9]+\) ([0-9A-F]{40}) .*/\1/p' | sort -u)"
      if [ -z "$(comm -12 <(echo "$required") <(echo "$installed"))" ]; then
        echo "ERROR: none of the certificates required by the resolved provisioning"
        echo "profiles is installed, so a device build will fail at codesigning."
        echo "Install the team development certificate:"
        echo "  cd ci && ./nicegram-match.sh development"
        echo "or run the simulator gate, which does not sign:"
        echo "  ci/verify-build.sh --sim"
        exit 1
      fi
    fi
  fi
fi
#


# shellcheck source=lib/report.sh
. ./lib/report.sh

# shellcheck source=lib/swiftpm-build.sh
. ./lib/swiftpm-build.sh

# Nicegram Build cache
# Scratch for this run only, deleted on the way out.
#
# Two of the steps below have to capture their output to a file, because this
# script greps it: the target-ids path out of `--show_result`, the positive
# output-group assertion, the report, and the divergence check all read a file
# rather than a stream. But every one of those reads happens *inside* this run,
# so nothing has to survive it. It used to write three timestamped files per run
# into ci/working_dir/logs/ and keep them forever; one of the three was never
# read by anything at all, and the directory had no bound.
#
# Nothing is lost by deleting them. `tee` still puts every line on stdout, so an
# interactive run has the whole thing in the terminal, and the two skills that
# drive this gate redirect it to their own scratch file
# (`./verify-build.sh > "$SCRATCH/build.log"`) and read that. The closing report
# block carries the numbers.
#
# INT/TERM exit rather than being ignored, so the EXIT trap fires and a run cut
# short by Ctrl-C cleans up after itself too. If the shell is killed outright,
# what is left is one directory under $TMPDIR, which macOS reaps on its own.
ng_scratch="$(mktemp -d "${TMPDIR:-/tmp}/verify-build.XXXXXX")" || exit 1
trap 'rm -rf "$ng_scratch"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Must happen before any bazel invocation -- see ci/lib/swiftpm-build.sh for
# what a stray .build does to analysis. It is evicted, not borrowed: putting it
# back would re-arm the trap for the next Xcode build, which runs bazel itself.
ng_evict_swiftpm_build || { echo "could not move .build out of the package" >&2; exit 1; }
#

set -o pipefail

# Step 1 -- resolve build-input/configuration-repository. Nothing else in this
# path does: the API build reads that directory as a bazel module but never
# regenerates it, so without this a flipped ng-env.txt would keep building the
# previous environment and a device build would sign with whatever profiles
# were fetched last. ~11s measured.
fastlane resolve_config 2>&1
status=$?
if [ "$status" -ne 0 ]; then
  echo "verify-build: resolve_config failed (exit $status); not starting a build." >&2
  exit "$status"
fi

# Step 2 -- xcodeproj.bazelrc must exist. It carries the flags that make this
# gate's configuration equal to Xcode's (`--config=ng_dev`,
# `--define=buildNumber=55555`, `--//Telegram:disableStripping`, the two Swift
# `copt`s, and the two `swift.*` features), and only ProjectGeneration.py writes
# it. Without it bazel reports
#   "Build options --//Telegram:disableStripping, --@@rules_swift+//swift:copt,
#    --define, and 1 more have changed, discarding analysis cache"
# and builds a DIFFERENT configuration -- while the target ids, and so the
# `bp <id>` group name, come out byte-identical, because the `-ST-` hash tracks
# the transition path and not the flags. Measured 2026-08-28. So absence has to
# be handled here; it cannot be detected downstream.
#
# Generation is the supported way to write it. It stays headless for two
# reasons: the generate_project lane passes --headless (without it, Make.py
# would run `killall Xcode` and open the project here, on every fresh
# worktree), and --no-open skips the script's own `open`. Measured 52.7s warm,
# and the rc it produced was byte-identical to the one already there.
if [ ! -f "$SOURCE_PATH/xcodeproj.bazelrc" ]; then
  echo "verify-build: no xcodeproj.bazelrc yet -- generating the Xcode project"
  echo "verify-build: once to create it (this is what pins this gate's bazel"
  echo "verify-build: configuration to Xcode's)."
  ./generate-project.sh --no-open 2>&1
  status=$?
  if [ "$status" -ne 0 ]; then
    echo "verify-build: project generation failed (exit $status)." >&2
    exit "$status"
  fi
  if [ ! -f "$SOURCE_PATH/xcodeproj.bazelrc" ]; then
    echo "verify-build: generation reported success but wrote no xcodeproj.bazelrc." >&2
    exit 1
  fi
fi

# Step 3 -- the bazel binary. Read it from the configuration repository rather
# than globbing build-input/: this is the same value Telegram/BUILD passes to
# the `xcodeproj` rule as `bazel_path`, so the runner script and this script
# cannot disagree about which bazel they mean.
variables_bzl="$SOURCE_PATH/build-input/configuration-repository/variables.bzl"
BAZEL="$(sed -nE 's/^telegram_bazel_path = "(.*)"$/\1/p' "$variables_bzl" 2>/dev/null)"
if [ -z "$BAZEL" ] || [ ! -x "$BAZEL" ]; then
  echo "verify-build: could not read an executable telegram_bazel_path from" >&2
  echo "  $variables_bzl" >&2
  exit 1
fi

# Step 4 -- discover this configuration's target id. Never hardcode it: it is
# "<label> <bazel-out directory name>", and that directory name carries the
# `-ST-<hash>` suffix, which changes whenever the transition path does.
if [ "$CONFIGURATION" = "device" ]; then
  id_prefix="ios_arm64-dbg-"
else
  id_prefix="ios_sim_arm64-dbg-"
fi

ids_log="$ng_scratch/ids.log"
"$BAZEL" run //Telegram:Telegram_xcodeproj -- \
  --generator_output_groups=target_ids_list 'build --show_result=1' 2>&1 \
  | tee "$ids_log"
status=$?
if [ "$status" -ne 0 ]; then
  echo "verify-build: could not build the target-ids list (exit $status)." >&2
  exit "$status"
fi

ids_file="$(grep -oE '/[^[:space:]]*_target_ids$' "$ids_log" | tail -1)"
if [ -z "$ids_file" ] || [ ! -f "$ids_file" ]; then
  echo "verify-build: --show_result printed no target-ids file path." >&2
  echo "verify-build: rules_xcodeproj's output shape may have changed; see the" >&2
  echo "verify-build: header." >&2
  exit 1
fi

# The app target appears once per Xcode configuration x target environment, so
# this prefix must match exactly one line. `ios_arm64` is not a prefix of
# `ios_sim_arm64`, so the two spellings cannot cross-match.
target_id="$(grep -E "^@@//Telegram:Telegram ${id_prefix}" "$ids_file")"
match_count="$(printf '%s' "$target_id" | grep -c . )"
if [ "$match_count" -ne 1 ]; then
  echo "verify-build: expected exactly one @@//Telegram:Telegram target id" >&2
  echo "verify-build: starting '$id_prefix', found $match_count in" >&2
  echo "  $ids_file" >&2
  printf '%s\n' "$target_id" >&2
  exit 1
fi
config_dir="${target_id#* }"

echo "verify-build: building $target_id"

# Step 5 -- the build. `--keep_going` is what makes one pass report every broken
# module instead of stopping at the first; it reaches the inner bazel as a
# command argument (verified in the runner's own echoed command line).
build_log="$ng_scratch/build.log"
"$BAZEL" run //Telegram:Telegram_xcodeproj -- \
  --generator_output_groups="bp $target_id" 'build --keep_going --show_result=1' 2>&1 \
  | tee "$build_log"
status=$?

# Step 6 -- the positive assertion. An output group name that does not exist is
# not an error to bazel: it exits 0 with "Build completed successfully, 1 total
# action" and prints "up-to-date (nothing to build)". Verified with a bogus id
# on 2026-08-28. So a zero exit is not enough evidence that anything was built:
# require the build to have reported at least one output under the very
# configuration directory this run asked for.
if [ "$status" -eq 0 ]; then
  if grep -qF "up-to-date (nothing to build)" "$build_log" \
     || ! grep -qF "/bazel-out/$config_dir/" "$build_log"; then
    echo "ERROR: the build exited 0 but reported no outputs under" >&2
    echo "  bazel-out/$config_dir/" >&2
    echo "so it did not build what was asked for. This is what a renamed or" >&2
    echo "missing output group looks like -- bazel does not treat an unknown" >&2
    echo "output group as an error. See this script's header: the group name is" >&2
    echo "the one rules_xcodeproj's own Xcode scripts use, so a bump of that" >&2
    echo "submodule is the first thing to check." >&2
    status=1
  fi
fi

# The output base to report is the NESTED one -- rules_xcodeproj builds in
# <outer output base>/rules_xcodeproj.noindex/build_output_base, and it runs
# with --experimental_convenience_symlinks=ignore, so ng_bazel_output_base
# (which reads the bazel-out symlink) would name the outer base and understate
# what this build actually wrote. Derive it from a real path this run printed.
nested_base="${ids_file%%/execroot/*}"

ng_report_from_log "verify-build $CONFIGURATION" "$build_log" "$nested_base"

# Nicegram Build cache
# Did this run actually share with Xcode, or did it quietly build a
# configuration of its own? A zero exit does not answer that: the build can
# succeed perfectly while reusing nothing, and the only visible symptom would be
# that it took twenty minutes instead of thirty seconds -- easy to blame on
# something else.
#
# bazel does announce it, though. When the option set differs from whatever last
# built in this output base it prints "Build options ... have changed, discarding
# analysis cache" and names them. That is exactly what a missing or changed
# xcodeproj.bazelrc looks like (measured 2026-08-28: removing the file produced
# `--//Telegram:disableStripping, --@@rules_swift+//swift:copt, --define, and 1
# more have changed` -- while the target ids stayed byte-identical, so nothing
# else downstream could have noticed).
#
# Two scoping rules, both learned by getting them wrong first.
#
# It must be scoped to the INNER invocation of each step, i.e. everything after
# that log's last "Running command line: ...-runner.sh" line. The OUTER base
# legitimately discards its analysis twice on every single run, because
# `resolve_config`'s aquery (-c dbg --ios_multi_cpus=sim_arm64 --define=...) and
# the plain `bazel run` alternate two different option sets there. That is cheap
# (the outer base analyses 8 packages) and meaningless; unscoped, this check
# would fire every time and be ignored within a week.
#
# And it must look at BOTH steps, not just the build. The divergence surfaces in
# whichever inner invocation runs FIRST, which is the target-ids step -- that one
# absorbs the reconfiguration, and the build step a second later sees matching
# options and says nothing. Checked only the build log at first and watched a
# deliberately diverged run come out clean.
#
# Verified to stay silent on: a warm repeat run, alternating --device/--sim, a
# real Xcode build followed by the gate, an Xcode Index Build (--config=indexbuild
# in the same base) followed by the gate, and a cold fresh worktree. Zero inner
# discards in all five.
#
# Re-verified on bazel 9.2.0 against the 13.0 merge's eight gate logs, plus one
# from a fresh worktree of that branch (2026-10-12). The line now ends
# `discarding analysis cache (this can be expensive, see
# https://bazel.build/advanced/performance/iteration-speed).`, a single flag
# reads `Build option --X has changed`, and the inner anchor reads
# `INFO: Running command line: ../bazel-bin/Telegram/Telegram_xcodeproj-runner.sh
# <args omitted>` -- all three still match. Across the merge's eight it fired
# once, on the run right after ci/nicegram.bazelrc dropped its deprecation
# demotion (`--@@rules_swift+//swift:copt and --per_file_copt have changed`, in
# the target-ids step), and stayed silent on the five runs after it.
#
# A warning, not a failure: a discard is legitimate the first time after someone
# changes ng_dev or Make.py's flag lists, and the build itself is still valid.
ng_inner_divergence() { # $1=log -- prints bazel's line if THIS log's inner invocation reconfigured
  local start=""
  start="$(grep -n 'INFO: Running command line: .*Telegram_xcodeproj-runner\.sh' "$1" \
    | tail -1 | cut -d: -f1)"
  [ -n "$start" ] || return 0
  tail -n "+$((start + 1))" "$1" | grep -m1 'discarding analysis cache'
}

divergence="$( { ng_inner_divergence "$ids_log"; ng_inner_divergence "$build_log"; } | head -1 )"
if [ -n "$divergence" ]; then
  echo ""
  echo "!! ================================================================"
  echo "!! WARNING: this build did NOT reuse Xcode's cache."
  echo "!!"
  echo "!! bazel reconfigured the build because its options differ from"
  echo "!! whatever last built in this output base:"
  echo "!!"
  echo "!!   $divergence"
  echo "!!"
  echo "!! The build above is valid -- but it compiled its own configuration,"
  echo "!! and Xcode's next build will have to redo this one's work. If this"
  echo "!! is the first run after changing ng_dev, Make.py's flag lists, or"
  echo "!! ng-env.txt, that is expected once. Regenerate the project so both"
  echo "!! flows agree again:"
  echo "!!   cd ci && ./generate-project.sh --no-open"
  echo "!! If it keeps happening, the two flows have drifted apart for real."
  echo "!! ================================================================"
fi

exit "$status"
