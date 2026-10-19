#!/bin/bash
#
# Nicegram Build cache
# Turns a captured bazel build log into a short, comparable summary.
#
# Why: before this, no flow recorded how long it took or how much it reused, so
# "the release build took 20 minutes" could not be attributed to anything. Every
# claim about cache behaviour in docs/superpowers/specs/2026-08-27-build-cache-audit-design.md
# is meant to be reproducible from these numbers.
#
# The patterns below are verbatim bazel 8.4.2 output, captured 2026-08-27:
#
#   INFO: Analyzed target //Telegram:Telegram (412 packages loaded, 21877 targets configured).
#   INFO: Elapsed time: 128.451s, Critical Path: 42.10s
#   INFO: 12043 processes: 9877 disk cache hit, 2100 internal, 66 darwin-sandbox.
#   INFO: 1 process: 1 action cache hit, 1 internal.
#
# Note "1 process:" versus "12043 processes:" -- bazel switches to the singular,
# so every pattern here accepts both.
#
# Re-verified against bazel 9.2.0, the 13.0 merge's gate logs of 2026-10-12.
# Two shapes are new, both covered by ci/tests/test-report.sh:
#
#   INFO: Analyzed target @@rules_xcodeproj++...:Telegram_xcodeproj (1463 packages loaded, 193415 targets configured, 39414 aspect applications).
#   INFO: 1567 processes: 6431 action cache hit, 2 internal, 1369 local, 196 worker.
#
# The second is new in meaning only: action cache hits are no longer part of
# the process count, which the parsing below never assumed.
#
# There is deliberately no "did this build reconfigure?" field here, and not
# because bazel stays quiet about it: 8.4.2 and 9.2.0 both print
#   WARNING: Build options --//Telegram:disableStripping, ... have changed,
#   discarding analysis cache
# whenever a configuration-affecting flag changes against a warm server. (An
# earlier draft of this comment claimed the opposite; it was measured on a cold
# server, where there is no prior analysis to discard.) Reading that line
# correctly needs scoping this file cannot apply -- a wrapper's log holds an
# OUTER bazel invocation that legitimately reconfigures on every run plus the
# nested ones that matter. ci/verify-build.sh's ng_inner_divergence does that
# scoping and owns the check; what this file reports instead is the "targets
# configured" count, which shows the re-analysis cost either way.
#
# `disk cache hit` counts work fetched from --disk_cache (cross-worktree,
# cross-flow reuse -- what this effort is trying to create). `action cache hit`
# counts work already valid in this output base (ordinary incrementality).
# They mean different things and are reported separately.
#
# What every ci/ wrapper actually captures is not this raw output, though --
# it's `fastlane ... | tee log`, and fastlane relays each bazel line wrapped in
# a "[HH:MM:SS]: " timestamp, a "▸ " marker, and an ANSI SGR colour escape.
# ng_report_field normalizes that dressing away (see _ng_report_normalize)
# before matching the patterns above, so both shapes parse; the fastlane
# shape is covered by its own fixture in ci/tests/test-report.sh.
#
# This file is sourced, not executed. Its tests are ci/tests/test-report.sh.
#

# Strips fastlane's line dressing so the ^INFO:/^ERROR: patterns below match a
# log captured through `fastlane ... | tee log` (every ci/ wrapper) the same
# way they already match a raw `bazel build` log (every pre-fastlane fixture
# below). fastlane relays each bazel line prefixed with a "[HH:MM:SS]: "
# timestamp and a "▸ " marker, and wrapped in an ANSI SGR colour escape --
# verbatim, one real captured line:
#
#   [14:59:26]: ▸ <ESC>[35mINFO: Elapsed time: 12.169s, Critical Path: 0.04s<ESC>[0m
#
# BSD sed does not understand a backslash \x1b escape, so the ESC byte is
# built with `printf` rather than written into the pattern directly. A line
# with none of this dressing (i.e. every existing fixture, and a direct
# `bazel build` invocation) matches none of the three substitutions below and
# passes through unchanged -- this is a no-op on genuine bazel output.
_ng_report_normalize() { # $1=log path
  local esc marker
  esc="$(printf '\033')"
  marker="$(printf '\xe2\x96\xb8')"  # ▸, U+25B8
  sed -E \
    -e "s/^\[[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\]: //" \
    -e "s/^${marker} //" \
    -e "s/${esc}\[[0-9;]*m//g" \
    "$1" 2>/dev/null
}

# Prints one field from a bazel log, or "?" when it is not present.
# Fields: elapsed processes disk_cache_hits action_cache_hits
#         packages_loaded targets_configured error_lines
ng_report_field() { # $1=log path  $2=field
  local log="$1" field="$2" normalized="" procline="" v=""

  if [ ! -f "$log" ]; then
    echo "?"
    return 0
  fi

  # One normalization pass per call, held in memory (no temp file); every
  # extraction below reads from this instead of the raw log.
  normalized="$(_ng_report_normalize "$log")"

  # The process summary, e.g. "9877 disk cache hit, 2100 internal, 66 darwin-sandbox"
  procline="$(printf '%s\n' "$normalized" | sed -nE 's/^INFO: [0-9]+ processe?s?: (.*)$/\1/p' | tail -1)"

  case "$field" in
    elapsed)
      v="$(printf '%s\n' "$normalized" | sed -nE 's/^INFO: Elapsed time: ([0-9.]+)s.*/\1/p' | tail -1)"
      ;;
    processes)
      v="$(printf '%s\n' "$normalized" | sed -nE 's/^INFO: ([0-9]+) processe?s?:.*/\1/p' | tail -1)"
      ;;
    disk_cache_hits)
      # Absent from the line entirely when there were none, which must read 0
      # rather than "?" -- "no hits" is a measurement, not a missing field.
      #
      # Deliberately not `sed -nE 's/.*[^0-9]?([0-9]+) disk cache hit.*/\1/p'`:
      # on this machine's /bin/bash `sed` (BSD sed, no GNU --version), a bare
      # `s///p` only replaces the matched span, and the leading unanchored
      # `.*` is greedy-but-minimal-backtrack -- it eats into the digit run
      # itself, e.g. "9877 disk cache hit" wrongly captures "7", not "9877"
      # (verified directly against this sed). `grep -oE` has no ambient `.*`
      # to backtrack into, so it extracts the full run correctly regardless
      # of position in the comma-separated list.
      [ -n "$procline" ] || { echo "?"; return 0; }
      v="$(printf '%s' "$procline" | grep -oE '[0-9]+ disk cache hit' | grep -oE '^[0-9]+' | tail -1)"
      [ -n "$v" ] || v=0
      ;;
    action_cache_hits)
      [ -n "$procline" ] || { echo "?"; return 0; }
      v="$(printf '%s' "$procline" | grep -oE '[0-9]+ action cache hit' | grep -oE '^[0-9]+' | tail -1)"
      [ -n "$v" ] || v=0
      ;;
    packages_loaded)
      v="$(printf '%s\n' "$normalized" | sed -nE 's/^INFO: Analyzed targets?.*\(([0-9]+) packages? loaded.*/\1/p' | tail -1)"
      ;;
    targets_configured)
      # `[,)]`, not `\)`: 9.2.0 can follow the count with ", N aspect
      # applications". A pattern that rejects the line silently falls back to an
      # earlier line's count, so the two analysis fields disagree.
      v="$(printf '%s\n' "$normalized" | sed -nE 's/^INFO: Analyzed targets?.*, ([0-9]+) targets? configured[,)].*/\1/p' | tail -1)"
      ;;
    error_lines)
      v="$(printf '%s\n' "$normalized" | grep -c '^ERROR: ')"
      ;;
    *)
      v=""
      ;;
  esac

  [ -n "$v" ] && echo "$v" || echo "?"
}

# Prints the human-readable summary block.
ng_report_from_log() { # $1=flow label  $2=log path  [$3=output base]
  local flow="$1" log="$2" base="${3:-}" size=""

  echo ""
  echo "── build report: $flow ─────────────────────────────"
  printf '   wall clock          %ss\n'  "$(ng_report_field "$log" elapsed)"
  printf '   processes           %s\n'   "$(ng_report_field "$log" processes)"
  printf '   disk cache hits     %s   (cross-worktree / cross-flow reuse)\n' \
                                          "$(ng_report_field "$log" disk_cache_hits)"
  printf '   action cache hits   %s   (incremental within this output base)\n' \
                                          "$(ng_report_field "$log" action_cache_hits)"
  printf '   analysis            %s packages, %s targets configured\n' \
      "$(ng_report_field "$log" packages_loaded)" "$(ng_report_field "$log" targets_configured)"
  printf '   ERROR lines         %s\n'   "$(ng_report_field "$log" error_lines)"
  if [ -n "$base" ] && [ -d "$base" ]; then
    size="$(du -sh "$base" 2>/dev/null | cut -f1)"
    printf '   output base         %s (%s)\n' "$base" "${size:-?}"
  fi
  # Deliberately does NOT print $log. The wrappers parse a scratch file that is
  # deleted as they exit, so naming it would point at a path that no longer
  # exists by the time anyone reads the line. Every line of that file has
  # already gone to stdout via `tee`.
  echo "────────────────────────────────────────────────────"
}

# Prints the CLI output base for a workspace, derived from bazel's own
# `bazel-out` convenience symlink -- which points at
# <output_base>/execroot/_main/bazel-out. Free, and needs no bazel invocation
# (`bazel info output_base` would work but has to find and start a server).
#
# Returns 1 and prints nothing when there is no symlink, which is the normal
# state before a workspace's first CLI build.
#
# This is the OUTER base. It is NOT where an Xcode build or ci/verify-build.sh's
# default path builds -- both build in the nested base below, and neither
# updates this symlink (they run with
# --experimental_convenience_symlinks=ignore). Reporting this base for one of
# those flows understates what the build actually wrote; use
# ng_bazel_nested_output_base, or a path the run itself printed.
ng_bazel_output_base() { # [$1=workspace root, default $SOURCE_PATH]
  local link="${1:-${SOURCE_PATH:-.}}/bazel-out" target=""
  [ -L "$link" ] || return 1
  target="$(readlink "$link")"
  printf '%s' "${target%/execroot/*}"
}

# Prints the rules_xcodeproj NESTED output base -- the one an Xcode build,
# project generation, and ci/verify-build.sh's default path all build in.
#
# The path is fixed relative to the outer base: rules_xcodeproj's runner passes
# `--output_base <outer>/rules_xcodeproj.noindex/build_output_base` (see
# build-system/bazel-rules/rules_xcodeproj/xcodeproj/internal/templates/runner.sh).
# So this only needs the outer base, and inherits its one precondition: the
# `bazel-out` symlink must exist, i.e. some outer invocation has run in this
# workspace. Returns 1 and prints nothing otherwise.
ng_bazel_nested_output_base() { # [$1=workspace root, default $SOURCE_PATH]
  local outer=""
  outer="$(ng_bazel_output_base "${1:-${SOURCE_PATH:-.}}")" || return 1
  [ -n "$outer" ] || return 1
  printf '%s/rules_xcodeproj.noindex/build_output_base' "$outer"
}
