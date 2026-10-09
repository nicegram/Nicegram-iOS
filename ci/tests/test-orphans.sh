#!/bin/bash
#
# Fixture-based tests for ci/lib/orphans.sh.
#
# The orphan rule is the load-bearing safety property of ci/clean-caches.sh --
# a wrong answer here deletes tens of GB of a live worktree's build state. So it
# is tested against real fixture directories rather than trusted by inspection.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/orphans.sh
. "$HERE/../lib/orphans.sh"

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

# A directory that exists, to stand in for a live worktree checkout. Create
# the nested .xcodeproj path up front too: a DerivedData WorkspacePath names
# the .xcodeproj *inside* the checkout, not the checkout root -- unlike
# Bazel's DO_NOT_BUILD_HERE, which records the root itself. ng_orphan_status
# has to tolerate that asymmetry, and the dd_live fixture below is what pins
# it down.
mkdir -p "$tmp/live-worktree/Telegram/Telegram.xcodeproj"
gone="$tmp/deleted-worktree"   # deliberately never created

# --- output base fixtures: bazel records the workspace in DO_NOT_BUILD_HERE ---
mkdir -p "$tmp/ob_live" "$tmp/ob_orphan" "$tmp/ob_bare"
printf '%s' "$tmp/live-worktree" > "$tmp/ob_live/DO_NOT_BUILD_HERE"
printf '%s' "$gone"              > "$tmp/ob_orphan/DO_NOT_BUILD_HERE"
# ob_bare has no marker file at all (e.g. bazel's own install/ or cache/ dirs)

# --- DerivedData fixtures: Xcode records the workspace in info.plist ---
mk_dd() { # $1=dir  $2=workspace path
  mkdir -p "$1"
  cat > "$1/info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>WorkspacePath</key>
	<string>$2</string>
</dict>
</plist>
PLIST
}
mk_dd "$tmp/dd_live"   "$tmp/live-worktree/Telegram/Telegram.xcodeproj"
mk_dd "$tmp/dd_orphan" "$gone/Telegram/Telegram.xcodeproj"
mkdir -p "$tmp/dd_bare"   # e.g. ModuleCache.noindex, which has no info.plist

# Compare the two fields separately rather than embedding a literal tab in the
# expected string -- a tab inside source an editor may normalise is a fragile
# thing to rest a safety test on.
status_of() { ng_orphan_status "$1" "$2" | cut -f1; }
path_of()   { ng_orphan_status "$1" "$2" | cut -f2; }

echo "test_output_base_classification"
check "live output base status"   "live"    "$(status_of output_base "$tmp/ob_live")"
check "live output base path"     "$tmp/live-worktree" "$(path_of output_base "$tmp/ob_live")"
check "orphan output base status" "orphan"  "$(status_of output_base "$tmp/ob_orphan")"
check "orphan output base path"   "$gone"   "$(path_of output_base "$tmp/ob_orphan")"
check "bare output base status"   "unknown" "$(status_of output_base "$tmp/ob_bare")"
check "bare output base path"     ""        "$(path_of output_base "$tmp/ob_bare")"

echo "test_derived_data_classification"
check "live DerivedData status"   "live"    "$(status_of derived_data "$tmp/dd_live")"
check "live DerivedData path"     "$tmp/live-worktree/Telegram/Telegram.xcodeproj" "$(path_of derived_data "$tmp/dd_live")"
check "orphan DerivedData status" "orphan"  "$(status_of derived_data "$tmp/dd_orphan")"
check "bare DerivedData status"   "unknown" "$(status_of derived_data "$tmp/dd_bare")"

echo "test_unknown_kind_is_never_orphan"
check "unrecognised kind"  "unknown" "$(status_of something_else "$tmp/ob_live")"

echo "test_missing_directory_is_unknown_not_orphan"
check "nonexistent dir"    "unknown" "$(status_of output_base "$tmp/does-not-exist")"

echo "test_paths_with_spaces_survive"
mkdir -p "$tmp/a live worktree with spaces"
mkdir -p "$tmp/ob_spaces"
printf '%s' "$tmp/a live worktree with spaces" > "$tmp/ob_spaces/DO_NOT_BUILD_HERE"
check "spaces in path"     "$tmp/a live worktree with spaces" "$(path_of output_base "$tmp/ob_spaces")"

echo "test_trailing_newline_in_marker_is_tolerated"
mkdir -p "$tmp/ob_newline"
printf '%s\n' "$tmp/live-worktree" > "$tmp/ob_newline/DO_NOT_BUILD_HERE"
check "trailing newline"   "$tmp/live-worktree" "$(path_of output_base "$tmp/ob_newline")"

# The scope rule is what lets merge-to-develop delete without asking: it must
# cover the removed worktree's stores and nothing else on the machine.
in_scope() { ng_orphan_in_scope "$1" "$2" && echo yes || echo no; }

echo "test_scope_covers_the_path_itself"
check "output base records the root" "yes" "$(in_scope /w/.claude/worktrees/foo /w/.claude/worktrees/foo)"

echo "test_scope_covers_paths_inside_it"
check "DerivedData records the xcodeproj" "yes" \
  "$(in_scope /w/.claude/worktrees/foo/Telegram/Telegram.xcodeproj /w/.claude/worktrees/foo)"

echo "test_scope_does_not_cover_a_sibling_sharing_its_prefix"
check "foo does not cover foo-bar" "no" "$(in_scope /w/.claude/worktrees/foo-bar /w/.claude/worktrees/foo)"
check "foo does not cover inside foo-bar" "no" \
  "$(in_scope /w/.claude/worktrees/foo-bar/Telegram/Telegram.xcodeproj /w/.claude/worktrees/foo)"

echo "test_scope_does_not_cover_its_parent"
check "worktree does not cover the main clone" "no" "$(in_scope /w /w/.claude/worktrees/foo)"

echo "test_empty_or_relative_scope_covers_nothing"
check "empty scope"    "no" "$(in_scope /w/.claude/worktrees/foo "")"
check "relative scope" "no" "$(in_scope worktrees/foo worktrees/foo)"

echo "test_scope_with_spaces"
check "spaces in scope" "yes" "$(in_scope "/w/a b/c d/x" "/w/a b/c d")"

if [ "$failures" -ne 0 ]; then
  echo "test-orphans: $failures failure(s)"
  exit 1
fi
echo "test-orphans: all passed"
