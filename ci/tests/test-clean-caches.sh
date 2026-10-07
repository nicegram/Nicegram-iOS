#!/bin/bash
#
# Argument handling of ci/clean-caches.sh.
#
# Every case here is one the script must refuse before it scans anything: the
# script walks this machine's real build stores, so a test must never hand it
# an argument list it would accept. A scope that resolved to empty would cover
# every orphan on the machine, which is exactly what --only exists to prevent.

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

if [ "$failures" -ne 0 ]; then
  echo "test-clean-caches: $failures failure(s)"
  exit 1
fi
echo "test-clean-caches: all passed"
