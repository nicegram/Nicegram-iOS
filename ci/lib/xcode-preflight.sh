#!/bin/bash
#
# Two Xcode components the build needs but only reaches minutes in. Both were
# missing from a freshly installed Xcode 26.6 during the 13.0 upstream merge:
#
#   - An iOS Simulator runtime for the iphonesimulator SDK. actool needs one to
#     compile asset catalogs even for a device build, so project generation died
#     seven minutes in with
#       error: No simulator runtime version from ["20E247", "22D8075",
#       "23A8464", "23C54", "23E244", "23E254a"] available to use with
#       iphonesimulator SDK version 23F81a
#   - The Metal Toolchain, a separate download since Xcode 26. 27 Metal
#     compiles failed with
#       error: cannot execute tool 'metal' due to missing Metal Toolchain; use:
#       xcodebuild -downloadComponent MetalToolchain
#
# Both checks go through xcrun, which resolves DEVELOPER_DIR and then
# xcode-select exactly as Make.py and bazel do, so they probe the Xcode the
# build will use.
#
# This file is sourced, not executed. Its tests are ci/tests/test-xcode-preflight.sh.
#

# Prints "<version> (<build>)" of an installed iOS Simulator runtime that serves
# the given iphonesimulator SDK version, or returns 1. A runtime serves an SDK of
# the same major.minor, whatever the builds: the failure above listed every
# installed runtime but 26.5 against SDK 26.5 (build 23F81a), and installing
# runtime 26.5 (build 23F77) fixed it.
ng_sim_runtime_for_sdk() { # $1=SDK version  stdin=`xcrun simctl list runtimes -j`
  python3 -c '
import json, sys
want = sys.argv[1].split(".")[:2]
for r in json.load(sys.stdin).get("runtimes", []):
    if (r.get("platform") == "iOS" and r.get("isAvailable")
            and r.get("version", "").split(".")[:2] == want):
        print("%s (%s)" % (r["version"], r.get("buildversion", "?")))
        sys.exit(0)
sys.exit(1)
' "$1"
}

# Prints each missing component with the command that installs it, and returns
# 1 if anything is missing. Silent on success.
ng_xcode_preflight() {
  local developer_dir sdk runtimes metal_err failed=0
  developer_dir="$(xcode-select -p 2>/dev/null)"

  sdk="$(xcrun --sdk iphonesimulator --show-sdk-version 2>/dev/null)"
  if [ -z "$sdk" ]; then
    echo "ERROR: the selected Xcode ($developer_dir) has no iphonesimulator SDK." >&2
    return 1
  fi
  # simctl's own stderr is left visible: if CoreSimulator itself is broken, the
  # "no runtime" verdict below would otherwise hide the real cause.
  runtimes="$(xcrun simctl list runtimes -j)"
  if ! printf '%s' "$runtimes" | ng_sim_runtime_for_sdk "$sdk" >/dev/null 2>&1; then
    echo "ERROR: no iOS $sdk Simulator runtime is installed for the selected Xcode," >&2
    echo "and actool needs one to compile asset catalogs, device builds included." >&2
    echo "Install it (about 8.5 GB):" >&2
    echo "  DEVELOPER_DIR=$developer_dir xcodebuild -downloadPlatform iOS" >&2
    failed=1
  fi

  if ! metal_err="$(xcrun metal --version 2>&1 >/dev/null)"; then
    echo "ERROR: the selected Xcode cannot run the Metal compiler:" >&2
    echo "  $metal_err" >&2
    echo "Install the Metal Toolchain (about 700 MB):" >&2
    echo "  DEVELOPER_DIR=$developer_dir xcodebuild -downloadComponent MetalToolchain" >&2
    failed=1
  fi

  return "$failed"
}
