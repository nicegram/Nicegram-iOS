#!/bin/bash
#
# Nicegram Build cache
# Reports every build-state store on this machine and, with --yes, deletes the
# ones classified `orphan` -- their recorded checkout path is no longer
# reachable on disk (see ci/lib/orphans.sh for exactly what "recorded" means
# per store kind; for DerivedData it is the *generated*, gitignored
# Telegram.xcodeproj path, not the worktree directory itself, so a live
# worktree that has never run ci/generate-project.sh has no such path yet and
# also classifies `orphan`).
#
# Why this exists: creating a git worktree gives Bazel a new workspace path,
# and therefore a brand-new output base (12-70 GB each), and gives Xcode a new
# DerivedData directory (up to 18 GB each). Deleting the worktree removes
# neither. As measured on 2026-08-27: 155 GB of output bases with 54 GB
# orphaned, and 111 GB of DerivedData with 49 GB orphaned.
#
# IF THIS REPORTS `live` FOR A WORKTREE YOU JUST DELETED, the recorded path
# still exists, and there are two mundane reasons for that -- both measured
# 2026-08-28:
#
#   1. Its bazel servers are still running. They idle for --max_idle_secs=10800
#      (3 hours), there are two per worktree (the outer one and
#      rules_xcodeproj's nested one), and an idle server RECREATES its
#      --workspace_directory. Kill them first:
#        pkill -f -- "--workspace_directory=<abs worktree path>( |\$)"
#      The `( |$)` anchor matters: `pkill -f` matches substrings, so without it
#      the pattern also matches any worktree whose path merely starts with
#      that one, and kills its servers mid-build.
#   2. `git worktree remove --force` can leave gitignored build output behind
#      (observed: Telegram/Telegram.xcodeproj/project.xcworkspace, 16 KB), and
#      that is enough to keep the path alive. `rm -rf` the directory after
#      removing the worktree.
#
# The classification itself is not at fault in either case -- the path really
# does exist. Nothing here guesses, so nothing here can work around it.
#
# Safety: prints the whole table first; deletes only entries classified `orphan`
# by ci/lib/orphans.sh (never `unknown`); requires an explicit --yes. The
# classification is tested in ci/tests/test-orphans.sh. Immediately before each
# delete, the classification is re-checked (not just assumed from the report
# printed a moment earlier), and a directory rm -rf cannot fully remove is
# reported rather than silently left partially deleted -- the script exits
# non-zero at the end if that happens, so a partial prune is never reported as
# success.
#
# --only <path> narrows what --yes may delete to orphans recorded at or under
# that path, leaving every other orphan reported and kept. It exists so that
# merge-to-develop can prune the worktree it just removed without asking: an
# unscoped prune also deletes stores whose checkout is only temporarily absent
# -- build-to-testflight's persistent .claude/worktrees/testflight-build is
# recreated at the same path, so its output base is meant to survive between
# builds -- and stores of other projects on this machine.
#
# Not touched here: the Bazel disk cache and repository cache. The disk cache is
# bounded by Bazel's own GC (see ci/nicegram.bazelrc); wiping it by hand throws
# away the cross-worktree reuse this whole effort exists to get.
#

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/orphans.sh
. "$HERE/lib/orphans.sh"

DO_DELETE=0
SCOPE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --yes) DO_DELETE=1 ;;
    --only)
      if [ $# -lt 2 ]; then
        echo "clean-caches: --only needs a path" >&2
        exit 2
      fi
      SCOPE="$2"
      while [ "$SCOPE" != "${SCOPE%/}" ]; do SCOPE="${SCOPE%/}"; done
      case "$SCOPE" in
        /?*) ;;
        *)
          echo "clean-caches: --only needs an absolute path below /, got: $2" >&2
          exit 2
          ;;
      esac
      shift
      ;;
    -h|--help)
      echo "usage: ci/clean-caches.sh [--yes] [--only <path>]"
      echo "  (no args)      report only -- nothing is deleted"
      echo "  --yes          delete every store classified orphan (see the report above)"
      echo "  --only <path>  count and delete only orphans recorded at or under <path>;"
      echo "                 other orphans are reported and kept"
      exit 0
      ;;
    *)
      echo "clean-caches: unknown argument: $1" >&2
      exit 2
      ;;
  esac
  shift
done

# Bazel 9 moved the default output user root from /private/var/tmp to
# ~/Library/Caches/bazel (observed 2026-10-12, 9.2.0). Both are scanned, so the
# output bases that 8.x left under the old root stay reclaimable.
BAZEL_ROOTS=("$HOME/Library/Caches/bazel/_bazel_$USER" "/private/var/tmp/_bazel_$USER")
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"

# macOS ships bash 3.2 as /bin/bash, where "${arr[@]}" on an EMPTY array is an
# unbound-variable error under `set -u`. Every expansion below therefore uses
# the ${arr[@]+"${arr[@]}"} guard rather than assuming bash 4 semantics.
orphans=()
total_orphan_kb=0
kept_count=0
kept_kb=0

report_group() { # $1=kind  $2=parent dir  $3=human label
  local kind="$1" parent="$2" label="$3" dir status recorded size kb
  echo ""
  echo "== $label"
  if [ ! -d "$parent" ]; then
    echo "   (none -- $parent does not exist)"
    return 0
  fi
  for dir in "$parent"/*/; do
    [ -d "$dir" ] || continue
    dir="${dir%/}"
    IFS=$'\t' read -r status recorded <<< "$(ng_orphan_status "$kind" "$dir")"
    size="$(du -sh "$dir" 2>/dev/null | cut -f1)"
    printf '   %-8s %-7s %s\n' "${size:-?}" "$status" "$(basename "$dir")"
    if [ -n "$recorded" ]; then
      printf '                     -> %s\n' "$recorded"
    fi
    if [ "$status" = "orphan" ]; then
      kb="$(du -sk "$dir" 2>/dev/null | cut -f1)"
      if [ -z "$SCOPE" ] || ng_orphan_in_scope "$recorded" "$SCOPE"; then
        orphans+=("$dir")
        total_orphan_kb=$((total_orphan_kb + ${kb:-0}))
      else
        kept_count=$((kept_count + 1))
        kept_kb=$((kept_kb + ${kb:-0}))
      fi
    fi
  done
}

echo "Build state on this machine"
for root in "${BAZEL_ROOTS[@]}"; do
  report_group output_base "$root" "Bazel output bases ($root)"
done
report_group derived_data "$DERIVED_DATA" "Xcode DerivedData ($DERIVED_DATA)"

echo ""
echo "== Bounded elsewhere, not pruned here"
for p in "${BAZEL_LOCAL_CACHE:-$HOME/work/nicegram-bazel-cache}" "${BAZEL_ROOTS[0]}/cache" "${BAZEL_ROOTS[1]}/cache" "$HOME/Library/Caches/org.swift.swiftpm"; do
  [ -d "$p" ] && printf '   %-8s %s\n' "$(du -sh "$p" 2>/dev/null | cut -f1)" "$p"
done

# GiB, not GB: the totals come from `du -sk` (KiB) and this divides by 1024^2.
# It used to print "GB", which understated nothing but named the wrong unit --
# and the sizes in the table above come from `du -sh`, which is also GiB, so the
# whole report is consistent in GiB now that the label says so.
#
# Expect the free space you actually get back to be somewhat less than this.
# Measured 2026-08-28: a prune this reported as 80.8 GiB moved `df` by 71 GiB.
# `du` counts what the files claim; APFS frees what is no longer shared, and on
# a machine where anything else is writing (an open Xcode indexes in the
# background) the two are taken at different moments.
gib() { echo "$1" | awk '{printf "%.1f GiB", $1/1048576}'; }

echo ""
if [ -n "$SCOPE" ]; then
  # Without a human reading the table, this line is the only thing that turns
  # "the removed worktree's stores still read live" from a silent no-op into
  # something visible.
  if [ -e "$SCOPE" ]; then
    echo "WARNING: $SCOPE still exists, so nothing recorded under it can classify orphan -- see this script's header for the two usual reasons."
  fi
  if [ "$kept_count" -gt 0 ]; then
    printf 'Kept, outside --only: %s across %d orphaned store(s) -- run ci/clean-caches.sh to review them.\n' \
      "$(gib "$kept_kb")" "$kept_count"
  fi
fi

if [ "${#orphans[@]}" -eq 0 ]; then
  if [ -n "$SCOPE" ]; then
    echo "Nothing to reclaim under $SCOPE."
  else
    echo "Nothing to reclaim -- every store belongs to a checkout that still exists."
  fi
  exit 0
fi

printf 'Reclaimable: %s across %d orphaned store(s)\n' "$(gib "$total_orphan_kb")" "${#orphans[@]}"

if [ "$DO_DELETE" -ne 1 ]; then
  echo "Re-run with --yes to delete them. Nothing was deleted."
  exit 0
fi

delete_failures=0
for dir in ${orphans[@]+"${orphans[@]}"}; do
  # Belt and braces: refuse anything that is not under one of the roots we
  # manage, and -- cheaply -- re-confirm the classification right before
  # deleting rather than trusting the report printed a moment earlier.
  kind=""
  for root in "${BAZEL_ROOTS[@]}"; do
    case "$dir" in "$root"/*) kind=output_base ;; esac
  done
  case "$dir" in "$DERIVED_DATA"/*) kind=derived_data ;; esac
  if [ -z "$kind" ]; then
    echo "refusing to delete outside managed roots: $dir" >&2
    exit 1
  fi
  recheck="$(ng_orphan_status "$kind" "$dir" | cut -f1)"
  if [ "$recheck" != "orphan" ]; then
    echo "skipping $dir: reclassified as $recheck since the report above was printed" >&2
    continue
  fi

  echo "deleting $dir"
  # Bazel creates .indexstore output directories read-only -- a consequence of
  # swift.index_while_building, which this repo's xcodeproj.bazelrc enables --
  # and rm -rf cannot descend into a directory it lacks write permission on.
  # `bazel clean` chmods the tree before removing it for exactly this reason;
  # do the same here. Do not drop this chmod: without it, rm -rf on such a
  # tree fails partway through, silently deletes DO_NOT_BUILD_HERE before
  # failing on the deeper read-only dirs, and leaves the remainder permanently
  # undetectable to ng_orphan_status (its marker is gone, so it reads
  # `unknown` forever after). chmod -R can itself fail on odd entries -- that
  # must not abort the run, but must not be swallowed either.
  if ! chmod -R u+w "$dir" 2>/dev/null; then
    echo "warning: chmod -R u+w did not fully succeed on $dir -- attempting delete anyway" >&2
  fi

  if rm -rf "$dir"; then
    :
  else
    echo "FAILED to fully delete $dir -- it is now partially deleted and may no longer be classifiable (a re-run may report it as unknown, not orphan)" >&2
    delete_failures=$((delete_failures + 1))
  fi
done

if [ "$delete_failures" -ne 0 ]; then
  echo ""
  echo "clean-caches: $delete_failures director(ies) could not be fully deleted -- see FAILED lines above" >&2
  exit 1
fi
echo "Done."
