#!/bin/bash
#
# Generates the Xcode project without touching Xcode: the generate_project lane
# passes --headless, without which upstream's Make.py runs `killall Xcode` and
# opens the project. ci/verify-build.sh runs this on its first run in every
# fresh worktree.
#
# --open then opens this checkout's project, for a human. It closes nothing; if
# Xcode already has the project open, Xcode reloads it.
#
# Keep the #!/bin/bash line -- see the comment in ci/verify-build.sh.

cd "$(dirname "$0")" || exit 1

# Parsed before bootstrap-submodules.sh so --help and a typo answer at once.
OPEN_PROJECT=0
for arg in "$@"; do
  case "$arg" in
    --open) OPEN_PROJECT=1 ;;
    -h|--help)
      echo "usage: ci/generate-project.sh [--open]"
      echo "  Generates Telegram/Telegram.xcodeproj without closing or opening Xcode."
      echo "  --open  then open it in Xcode (closes nothing)"
      exit 0
      ;;
    *)
      echo "generate-project: unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

./bootstrap-submodules.sh || exit 1
. ./_env.sh

# shellcheck source=lib/report.sh
. ./lib/report.sh

# shellcheck source=lib/swiftpm-build.sh
. ./lib/swiftpm-build.sh

# Scratch for this run only -- see the same block in ci/verify-build.sh for why
# nothing here is worth keeping. `tee` still puts every line on stdout; the file
# exists solely so ng_report_from_log can parse it a few lines below.
ng_scratch="$(mktemp -d "${TMPDIR:-/tmp}/generate-project.XXXXXX")" || exit 1
trap 'rm -rf "$ng_scratch"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Must happen before any bazel invocation -- see ci/lib/swiftpm-build.sh for
# what a stray .build does to analysis. It is evicted, not borrowed: putting it
# back would re-arm the trap for the next Xcode build, which runs bazel itself.
ng_evict_swiftpm_build || { echo "could not move .build out of the package" >&2; exit 1; }
log="$ng_scratch/generate_project.log"

set -o pipefail
fastlane generate_project 2>&1 | tee "$log"
status=$?

# Generation runs inside the nested base (rules_xcodeproj's runner points it
# there), so the outer base is the wrong one to report.
ng_report_from_log generate_project "$log" "$(ng_bazel_nested_output_base "$SOURCE_PATH")"

if [ "$status" -eq 0 ] && [ "$OPEN_PROJECT" -eq 1 ]; then
  open "$SOURCE_PATH/Telegram/Telegram.xcodeproj" || status=$?
fi

exit "$status"
