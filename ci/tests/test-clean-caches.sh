#!/bin/bash
#
# Argument handling and store roots of ci/clean-caches.sh.
#
# The argument cases are ones the script must refuse before it scans anything:
# run as is, the script walks this machine's real build stores, so those cases
# never hand it an argument list it would accept. A scope that resolved to empty
# would cover every orphan on the machine, which is exactly what --only exists
# to prevent.
#
# The root cases run it under a fake HOME and USER, which every root it scans is
# derived from, so it sees fixtures only. The Bazel 8 root is the one fixture
# outside $tmp: /private/var/tmp/_bazel_<fake user>, removed on exit.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../clean-caches.sh"

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

refuses() { # $1=label  $2=expected stderr substring  $3...=arguments
  local label="$1" want="$2" err status
  shift 2
  err="$(bash "$SCRIPT" "$@" 2>&1 >/dev/null)"
  status=$?
  check "$label exits 2" "2" "$status"
  case "$err" in
    *"$want"*) echo "  ok   $label names the problem" ;;
    *) echo "  FAIL $label names the problem"
       echo "         wanted: [$want]"
       echo "         got:    [$err]"
       failures=$((failures + 1)) ;;
  esac
}

echo "test_only_without_a_path_is_refused"
refuses "--only alone" "--only needs a path" --only

echo "test_only_with_a_relative_path_is_refused"
refuses "--only relative" "--only needs an absolute path" --only .claude/worktrees/foo

echo "test_only_with_the_root_is_refused"
refuses "--only /" "--only needs an absolute path" --only /
refuses "--only //" "--only needs an absolute path" --only //

echo "test_help_documents_only"
case "$(bash "$SCRIPT" --help)" in
  *"--only <path>"*) echo "  ok   help names --only <path>" ;;
  *) echo "  FAIL help names --only <path>"; failures=$((failures + 1)) ;;
esac

contains() { # $1=label  $2=needle  $3=haystack
  case "$3" in
    *"$2"*) echo "  ok   $1" ;;
    *) echo "  FAIL $1"
       echo "         wanted: [$2]"
       echo "         in:     [$3]"
       failures=$((failures + 1)) ;;
  esac
}

tmp="$(cd "$(mktemp -d)" && pwd -P)"
fake_user="ngtest$$"
root9="$tmp/home/Library/Caches/bazel/_bazel_$fake_user"
root8="/private/var/tmp/_bazel_$fake_user"
trap 'rm -rf "$tmp" "$root8"' EXIT

output_base() { # $1=root  $2=hash  $3=recorded workspace
  mkdir -p "$1/$2/execroot"
  printf '%s\n' "$3" > "$1/$2/DO_NOT_BUILD_HERE"
}
mkdir -p "$tmp/live" "$root9/install" "$root9/cache/repos" "$root8/install"
output_base "$root9" 9000000000000000000000000000000a "$tmp/gone/ws9"
output_base "$root9" 9000000000000000000000000000000b "$tmp/live"
output_base "$root8" 8000000000000000000000000000000a "$tmp/gone/ws8"

run() { # $@=arguments
  env -u BAZEL_LOCAL_CACHE HOME="$tmp/home" USER="$fake_user" bash "$SCRIPT" "$@" 2>&1
}

echo "test_reports_both_bazel_roots"
out="$(run)"
contains "Bazel 9 root scanned" "Bazel output bases ($root9)" "$out"
contains "Bazel 8 root scanned" "Bazel output bases ($root8)" "$out"
contains "orphans in both roots counted" "across 2 orphaned store(s)" "$out"
check "report deletes nothing (9)" "yes" "$([ -d "$root9/9000000000000000000000000000000a" ] && echo yes)"
check "report deletes nothing (8)" "yes" "$([ -d "$root8/8000000000000000000000000000000a" ] && echo yes)"

echo "test_reclaims_orphans_in_both_roots"
out="$(run --yes --only "$tmp/gone")"
status=$?
check "exit code" "0" "$status"
check "Bazel 9 orphan deleted" "no" "$([ -e "$root9/9000000000000000000000000000000a" ] && echo yes || echo no)"
check "Bazel 8 orphan deleted" "no" "$([ -e "$root8/8000000000000000000000000000000a" ] && echo yes || echo no)"
check "live output base kept" "yes" "$([ -d "$root9/9000000000000000000000000000000b" ] && echo yes)"
check "unclassifiable install/ kept" "yes" "$([ -d "$root9/install" ] && [ -d "$root8/install" ] && echo yes)"

if [ "$failures" -ne 0 ]; then
  echo "test-clean-caches: $failures failure(s)"
  exit 1
fi
echo "test-clean-caches: all passed"
