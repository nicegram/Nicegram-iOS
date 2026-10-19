#!/bin/bash
#
# Fixture-based tests for ci/lib/xcode-preflight.sh.
#
# The runtime fixtures are the iOS runtimes this machine had installed on
# 2026-10-12 (versions and builds copied from `xcrun simctl list runtimes -j`),
# first without 26.5 -- the set the 13.0 merge's project generation failed
# against -- and then with it. xcrun and xcode-select are stubbed on PATH for
# the whole-check cases, because a missing Metal Toolchain cannot be reproduced
# on a machine that has one.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/xcode-preflight.sh
. "$HERE/../lib/xcode-preflight.sh"

failures=0
check() { # $1=label  $2=expected  $3=actual
  if [ "$2" = "$3" ]; then
    echo "  ok   $1"
  else
    echo "  FAIL $1"
    echo "         expected: [$2]"
    echo "         actual:   [$3]"
    failures=$((failures + 1))
  fi
}
check_contains() { # $1=label  $2=needle  $3=haystack
  case "$3" in
    *"$2"*) echo "  ok   $1" ;;
    *)
      echo "  FAIL $1"
      echo "         expected to contain: [$2]"
      echo "         actual: [$3]"
      failures=$((failures + 1))
      ;;
  esac
}
check_lacks() { # $1=label  $2=needle  $3=haystack
  case "$3" in
    *"$2"*)
      echo "  FAIL $1"
      echo "         expected not to contain: [$2]"
      echo "         actual: [$3]"
      failures=$((failures + 1))
      ;;
    *) echo "  ok   $1" ;;
  esac
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

runtime() { # $1=platform $2=version $3=build [$4=isAvailable, default true]
  printf '{"platform": "%s", "version": "%s", "buildversion": "%s", "isAvailable": %s}' \
    "$1" "$2" "$3" "${4:-true}"
}
runtimes_json() { # $@=runtime objects
  local IFS=,
  printf '{"runtimes": [%s]}\n' "$*"
}

before="$(runtimes_json \
  "$(runtime iOS 16.4 20E247)" "$(runtime iOS 18.3.1 22D8075)" \
  "$(runtime iOS 26.0.1 23A8464)" "$(runtime iOS 26.2 23C54)" \
  "$(runtime iOS 26.4 23E244)" "$(runtime iOS 26.4.1 23E254a)" \
  "$(runtime watchOS 26.4 23T240b)")"
after="$(runtimes_json \
  "$(runtime iOS 26.4.1 23E254a)" "$(runtime iOS 26.5 23F77)" \
  "$(runtime watchOS 26.4 23T240b)")"

echo "test_no_runtime_for_the_sdk"
out="$(printf '%s' "$before" | ng_sim_runtime_for_sdk 26.5)"; status=$?
check "prints nothing" "" "$out"
check "exit code" "1" "$status"

echo "test_runtime_matches_on_major_minor_not_build"
# SDK 26.5 is build 23F81a; the runtime that fixed the 13.0 merge is 23F77.
check "26.5 SDK, 26.5 runtime" "26.5 (23F77)" "$(printf '%s' "$after" | ng_sim_runtime_for_sdk 26.5)"
check "26.4 SDK, 26.4.1 runtime" "26.4.1 (23E254a)" "$(printf '%s' "$after" | ng_sim_runtime_for_sdk 26.4)"

echo "test_other_platforms_and_unavailable_runtimes_do_not_count"
check "watchOS 26.4 is not an iOS runtime" "" \
  "$(runtimes_json "$(runtime watchOS 26.4 23T240b)" | ng_sim_runtime_for_sdk 26.4)"
check "unavailable runtime" "" \
  "$(runtimes_json "$(runtime iOS 26.5 23F77 false)" | ng_sim_runtime_for_sdk 26.5)"

# Stubs for the whole check. NG_TEST_RUNTIMES and NG_TEST_METAL choose what the
# fake xcrun reports; the missing-Metal text is the one the 13.0 merge's build
# printed, verbatim.
stub="$tmp/bin"
mkdir -p "$stub"
cat > "$stub/xcode-select" <<'STUB'
#!/bin/bash
echo /Applications/Xcode_Test.app/Contents/Developer
STUB
cat > "$stub/xcrun" <<'STUB'
#!/bin/bash
case "$*" in
  "--sdk iphonesimulator --show-sdk-version") echo 26.5 ;;
  "simctl list runtimes -j") cat "$NG_TEST_RUNTIMES" ;;
  "metal --version")
    if [ "$NG_TEST_METAL" = missing ]; then
      echo "error: cannot execute tool 'metal' due to missing Metal Toolchain; use: xcodebuild -downloadComponent MetalToolchain" >&2
      exit 1
    fi
    echo "Apple metal version 32023.883 (metalfe-32023.883)"
    ;;
  *) echo "unexpected xcrun $*" >&2; exit 64 ;;
esac
STUB
chmod +x "$stub/xcode-select" "$stub/xcrun"
printf '%s' "$before" > "$tmp/before.json"
printf '%s' "$after" > "$tmp/after.json"

preflight() { # $1=runtimes fixture  $2=metal state -> output; status in $pf_status
  pf_out="$(PATH="$stub:$PATH" NG_TEST_RUNTIMES="$1" NG_TEST_METAL="$2" ng_xcode_preflight 2>&1)"
  pf_status=$?
}

echo "test_preflight_passes_silently_when_both_are_installed"
preflight "$tmp/after.json" installed
check "exit code" "0" "$pf_status"
check "output" "" "$pf_out"

echo "test_preflight_names_the_runtime_fix"
preflight "$tmp/before.json" installed
check "exit code" "1" "$pf_status"
check_contains "names the SDK version" "26.5" "$pf_out"
check_contains "names the fix" "xcodebuild -downloadPlatform iOS" "$pf_out"
check_contains "fix runs against the selected Xcode" \
  "DEVELOPER_DIR=/Applications/Xcode_Test.app/Contents/Developer" "$pf_out"
check_lacks "does not blame Metal" "MetalToolchain" "$pf_out"

echo "test_preflight_names_the_metal_fix"
preflight "$tmp/after.json" missing
check "exit code" "1" "$pf_status"
check_contains "passes xcrun's own error through" "missing Metal Toolchain" "$pf_out"
check_contains "names the fix" "xcodebuild -downloadComponent MetalToolchain" "$pf_out"
check_lacks "does not blame the runtime" "downloadPlatform" "$pf_out"

echo "test_preflight_reports_both_at_once"
preflight "$tmp/before.json" missing
check "exit code" "1" "$pf_status"
check_contains "runtime fix" "xcodebuild -downloadPlatform iOS" "$pf_out"
check_contains "metal fix" "xcodebuild -downloadComponent MetalToolchain" "$pf_out"

if [ "$failures" -ne 0 ]; then
  echo "test-xcode-preflight: $failures failure(s)"
  exit 1
fi
echo "test-xcode-preflight: all passed"
