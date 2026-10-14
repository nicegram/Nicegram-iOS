#!/bin/bash
#
# Fixture-based tests for ci/lib/report.sh.
#
# The fixture log lines are verbatim bazel 8.4.2 output captured on 2026-08-27
# from a throwaway workspace -- including the singular "1 process:" form, which
# a naive parser written against the plural form silently misses -- plus
# verbatim bazel 9.2.0 lines from the 13.0 upstream merge's gate logs
# (2026-10-12), whose analysis line can end in ", N aspect applications".

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/report.sh
. "$HERE/../lib/report.sh"

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

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/warm.log" <<'LOG'
INFO: Analyzed target //Telegram:Telegram (412 packages loaded, 21877 targets configured).
INFO: Found 1 target...
INFO: Elapsed time: 128.451s, Critical Path: 42.10s
INFO: 12043 processes: 9877 disk cache hit, 2100 internal, 66 darwin-sandbox.
INFO: Build completed successfully, 12043 total actions
LOG

cat > "$tmp/singular.log" <<'LOG'
INFO: Analyzed target //:g (0 packages loaded, 2 targets configured).
INFO: Elapsed time: 0.079s, Critical Path: 0.00s
INFO: 1 process: 1 action cache hit, 1 internal.
INFO: Build completed successfully, 1 total action
LOG

cat > "$tmp/cold.log" <<'LOG'
INFO: Analyzed target //:g (6 packages loaded, 8 targets configured).
INFO: Elapsed time: 10.965s, Critical Path: 0.07s
INFO: 2 processes: 1 internal, 1 darwin-sandbox.
INFO: Build completed successfully, 2 total actions
LOG

cat > "$tmp/failed.log" <<'LOG'
ERROR: /some/path/BUILD:12:1: Compiling Swift module //submodules/Display failed
INFO: Elapsed time: 55.100s, Critical Path: 30.00s
LOG

# Real fastlane-wrapped bazel output, transcribed byte-for-byte from an actual
# ci/generate-project.sh capture: a "[HH:MM:SS]: " timestamp, a "▸ " marker,
# and an ANSI SGR colour escape around the INFO: text. This is what every ci/
# wrapper actually captures (`fastlane ... | tee log`), not the raw bazel
# output above -- ng_report_field must parse both shapes the same way. The
# ESC byte is built with `printf`, not written as a literal escape in this
# quoted heredoc, since a quoted heredoc does no backslash interpretation.
esc="$(printf '\033')"
marker="$(printf '\xe2\x96\xb8')"  # ▸, U+25B8
cat > "$tmp/fastlane.log" <<LOG
[14:59:26]: ${marker} ${esc}[35mINFO: Elapsed time: 12.169s, Critical Path: 0.04s${esc}[0m
[15:00:42]: ${marker} ${esc}[35mINFO: 4361 processes: 2805 disk cache hit, 225 internal, 1331 local.${esc}[0m
[15:00:42]: ${marker} ${esc}[35mINFO: Analyzed target //Telegram:Telegram (956 packages loaded, 48876 targets configured).${esc}[0m
LOG

# bazel 9.2.0, ci/generate-project.sh: the outer `bazel run` analyses the runner
# (no aspects), then the inner generator analysis reports aspect applications.
# Both numbers must come from that last line, not one from each.
cat > "$tmp/bazel9-generate.log" <<LOG
[13:54:39]: ${marker} ${esc}[35mINFO: Analyzed target //Telegram:Telegram_xcodeproj (3 packages loaded, 12 targets configured).${esc}[0m
[13:54:40]: ${marker} ${esc}[35mINFO: 11 processes: 10 internal, 1 local.${esc}[0m
[14:01:46]: ${marker} ${esc}[35mINFO: Analyzed target @@rules_xcodeproj++rules_repos+rules_xcodeproj_generated//generator/Telegram/Telegram_xcodeproj:Telegram_xcodeproj (1463 packages loaded, 193415 targets configured, 39414 aspect applications).${esc}[0m
[14:01:52]: ${marker} ${esc}[35mINFO: Elapsed time: 431.979s, Critical Path: 6.58s${esc}[0m
[14:01:52]: ${marker} ${esc}[35mINFO: 439 processes: 402 internal, 37 local.${esc}[0m
LOG

# bazel 9.2.0, ci/verify-build.sh's build step (raw, not fastlane-wrapped): the
# action cache hits are no longer part of the process count.
cat > "$tmp/bazel9-build.log" <<'LOG'
INFO: Elapsed time: 222.082s, Critical Path: 196.46s
INFO: 1567 processes: 6431 action cache hit, 2 internal, 1369 local, 196 worker.
LOG

# bazel 9.2.0, a fresh worktree's project generation fed from the disk cache.
cat > "$tmp/bazel9-disk.log" <<LOG
[15:42:08]: ${marker} ${esc}[35mINFO: 6018 processes: 5612 disk cache hit, 401 internal, 5 local.${esc}[0m
LOG

# bazel 8.4.2, the gate's build step after the target-ids step had analysed
# everything: the singular "target configured".
cat > "$tmp/singular-target.log" <<'LOG'
INFO: Analyzed target @@rules_xcodeproj++rules_repos+rules_xcodeproj_generated//generator/Telegram/Telegram_xcodeproj:Telegram_xcodeproj (6 packages loaded, 9939 targets configured).
INFO: Analyzed target @@rules_xcodeproj++rules_repos+rules_xcodeproj_generated//generator/Telegram/Telegram_xcodeproj:Telegram_xcodeproj (1 packages loaded, 1 target configured).
LOG

echo "test_warm_build_fields"
check "elapsed"        "128.451" "$(ng_report_field "$tmp/warm.log" elapsed)"
check "disk hits"      "9877"    "$(ng_report_field "$tmp/warm.log" disk_cache_hits)"
check "action hits"    "0"       "$(ng_report_field "$tmp/warm.log" action_cache_hits)"
check "processes"      "12043"   "$(ng_report_field "$tmp/warm.log" processes)"
check "pkgs loaded"    "412"     "$(ng_report_field "$tmp/warm.log" packages_loaded)"
check "targets cfg"    "21877"   "$(ng_report_field "$tmp/warm.log" targets_configured)"

echo "test_fastlane_wrapped_output_is_normalized"
check "fastlane elapsed"     "12.169" "$(ng_report_field "$tmp/fastlane.log" elapsed)"
check "fastlane processes"   "4361"   "$(ng_report_field "$tmp/fastlane.log" processes)"
check "fastlane disk hits"   "2805"   "$(ng_report_field "$tmp/fastlane.log" disk_cache_hits)"
check "fastlane action hits" "0"      "$(ng_report_field "$tmp/fastlane.log" action_cache_hits)"
check "fastlane pkgs loaded" "956"    "$(ng_report_field "$tmp/fastlane.log" packages_loaded)"
check "fastlane targets cfg" "48876"  "$(ng_report_field "$tmp/fastlane.log" targets_configured)"

echo "test_bazel9_analysis_with_aspect_applications"
check "bazel9 pkgs loaded" "1463"   "$(ng_report_field "$tmp/bazel9-generate.log" packages_loaded)"
check "bazel9 targets cfg" "193415" "$(ng_report_field "$tmp/bazel9-generate.log" targets_configured)"
check "bazel9 processes"   "439"    "$(ng_report_field "$tmp/bazel9-generate.log" processes)"
check "bazel9 elapsed"     "431.979" "$(ng_report_field "$tmp/bazel9-generate.log" elapsed)"

echo "test_bazel9_cache_counters"
check "bazel9 processes"   "1567" "$(ng_report_field "$tmp/bazel9-build.log" processes)"
check "bazel9 action hits" "6431" "$(ng_report_field "$tmp/bazel9-build.log" action_cache_hits)"
check "bazel9 disk hits"   "0"    "$(ng_report_field "$tmp/bazel9-build.log" disk_cache_hits)"
check "bazel9 disk hits, fed" "5612" "$(ng_report_field "$tmp/bazel9-disk.log" disk_cache_hits)"

echo "test_singular_target_configured_is_parsed"
check "singular pkgs loaded" "1" "$(ng_report_field "$tmp/singular-target.log" packages_loaded)"
check "singular targets cfg" "1" "$(ng_report_field "$tmp/singular-target.log" targets_configured)"

echo "test_singular_process_line_is_parsed"
check "singular procs" "1" "$(ng_report_field "$tmp/singular.log" processes)"
check "singular action hits" "1" "$(ng_report_field "$tmp/singular.log" action_cache_hits)"
check "singular disk hits"   "0" "$(ng_report_field "$tmp/singular.log" disk_cache_hits)"

echo "test_cold_build_has_no_cache_hits"
check "cold disk hits"   "0" "$(ng_report_field "$tmp/cold.log" disk_cache_hits)"
check "cold action hits" "0" "$(ng_report_field "$tmp/cold.log" action_cache_hits)"
check "cold procs"       "2" "$(ng_report_field "$tmp/cold.log" processes)"

echo "test_failed_build_reports_what_it_has"
check "failed elapsed" "55.100" "$(ng_report_field "$tmp/failed.log" elapsed)"
check "failed procs"   "?"      "$(ng_report_field "$tmp/failed.log" processes)"
check "failed errors"  "1"      "$(ng_report_field "$tmp/failed.log" error_lines)"

echo "test_missing_log_does_not_crash"
check "missing log" "?" "$(ng_report_field "$tmp/nope.log" elapsed)"

echo "test_summary_block_names_the_flow_but_not_the_log_path"
out="$(ng_report_from_log compile_check "$tmp/warm.log")"
case "$out" in
  *compile_check*) echo "  ok   summary names the flow" ;;
  *) echo "  FAIL summary names the flow"; failures=$((failures + 1)) ;;
esac
# It must NOT name the log. Both wrappers parse a scratch file they delete as
# they exit, so printing the path would hand the reader a path that is already
# gone -- worse than printing nothing, because it looks actionable.
case "$out" in
  *"$tmp/warm.log"*) echo "  FAIL summary leaks a log path that will not exist"; failures=$((failures + 1)) ;;
  *) echo "  ok   summary omits the log path" ;;
esac
case "$out" in
  *9877*) echo "  ok   summary shows disk cache hits" ;;
  *) echo "  FAIL summary shows disk cache hits"; failures=$((failures + 1)) ;;
esac

echo "test_output_base_from_convenience_symlink"
mkdir -p "$tmp/ws" "$tmp/ob/execroot/_main/bazel-out"
ln -s "$tmp/ob/execroot/_main/bazel-out" "$tmp/ws/bazel-out"
check "derived from symlink" "$tmp/ob" "$(ng_bazel_output_base "$tmp/ws")"

echo "test_output_base_absent_symlink_is_silent"
mkdir -p "$tmp/ws_nolink"
check "no symlink" "" "$(ng_bazel_output_base "$tmp/ws_nolink")"
ng_bazel_output_base "$tmp/ws_nolink" >/dev/null 2>&1; check "no symlink exit code" "1" "$?"

echo "test_nested_output_base_from_outer"
check "nested derived from symlink" \
  "$tmp/ob/rules_xcodeproj.noindex/build_output_base" \
  "$(ng_bazel_nested_output_base "$tmp/ws")"

echo "test_nested_output_base_absent_symlink_is_silent"
check "nested, no symlink" "" "$(ng_bazel_nested_output_base "$tmp/ws_nolink")"
ng_bazel_nested_output_base "$tmp/ws_nolink" >/dev/null 2>&1
check "nested, no symlink exit code" "1" "$?"

if [ "$failures" -ne 0 ]; then
  echo "test-report: $failures failure(s)"
  exit 1
fi
echo "test-report: all passed"
