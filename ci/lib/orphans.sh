#!/bin/bash
#
# Nicegram Build cache
# Orphan detection for build-state directories.
#
# Both Bazel and Xcode record, inside each state directory, the absolute path of
# the checkout it belongs to. If that path no longer exists, the state is
# unreachable garbage -- no heuristic and no name-mangling guess involved:
#
#   Bazel output base   ->  <dir>/DO_NOT_BUILD_HERE   contains the workspace root
#   Xcode DerivedData   ->  <dir>/info.plist          WorkspacePath key
#
# Deliberately conservative: anything we cannot positively classify comes back
# `unknown`, and callers must never delete `unknown`. That covers Bazel's own
# install/ and cache/ directories and Xcode's ModuleCache.noindex /
# SDKStatCaches.noindex, none of which carry a marker.
#
# This file is sourced, not executed. Its tests are ci/tests/test-orphans.sh.
#

# Prints the workspace path recorded inside a build-state directory, or nothing.
# Returns 1 when there is no marker to read.
ng_orphan_recorded_path() { # $1=kind  $2=dir
  local kind="$1" dir="$2" marker=""

  [ -d "$dir" ] || return 1

  case "$kind" in
    output_base)
      marker="$dir/DO_NOT_BUILD_HERE"
      [ -f "$marker" ] || return 1
      # `tr -d` strips the trailing newline bazel may or may not write. Do not
      # use `$(cat)` alone and rely on command substitution stripping it -- that
      # works, but it also silently strips a path that legitimately ends in
      # whitespace, and being explicit documents the intent.
      tr -d '\n' < "$marker"
      ;;
    derived_data)
      marker="$dir/info.plist"
      [ -f "$marker" ] || return 1
      /usr/bin/plutil -extract WorkspacePath raw "$marker" 2>/dev/null || return 1
      ;;
    *)
      return 1
      ;;
  esac
}

# Prints "<status>\t<recorded_path>" where status is live | orphan | unknown.
# recorded_path is empty when status is unknown. Always returns 0.
ng_orphan_status() { # $1=kind  $2=dir
  local recorded=""

  if ! recorded="$(ng_orphan_recorded_path "$1" "$2")" || [ -z "$recorded" ]; then
    printf 'unknown\t\n'
    return 0
  fi

  if [ -e "$recorded" ]; then
    printf 'live\t%s\n' "$recorded"
  else
    printf 'orphan\t%s\n' "$recorded"
  fi
}

# Succeeds when a recorded path is the scope itself or lies inside it. A sibling
# that merely shares the prefix is outside (/w/foo does not cover /w/foo-bar),
# and an empty or relative scope covers nothing -- an empty one would otherwise
# cover every absolute path on the machine.
ng_orphan_in_scope() { # $1=recorded path  $2=absolute scope, no trailing slash
  local recorded="$1" scope="$2"

  case "$scope" in
    /?*) ;;
    *) return 1 ;;
  esac
  case "$recorded" in
    "$scope"|"$scope"/*) return 0 ;;
  esac
  return 1
}
