#!/bin/bash
#
# Fixture-based tests for ci/bootstrap-submodules.sh.
#
# The property under test: every submodule the script initializes ends at its
# pinned commit, or the script fails. On 2026-10-08 it cloned the assistant
# from a main-clone gitdir that had not fetched the pin yet, was left at that
# gitdir's own HEAD, and exited 0. The failure lives entirely in git's own
# behaviour, so the fixtures are real repositories rather than stubs.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../bootstrap-submodules.sh"

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

# Resolved, so that paths git records and paths built here compare equal.
tmp="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT

unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$tmp/gitconfig"
git config -f "$GIT_CONFIG_GLOBAL" user.name test
git config -f "$GIT_CONFIG_GLOBAL" user.email test@example.com
git config -f "$GIT_CONFIG_GLOBAL" init.defaultBranch main
# A fixture's remotes are file paths, which git refuses for submodules by
# default; production remotes are ssh or https and never need this.
git config -f "$GIT_CONFIG_GLOBAL" protocol.file.allow always

# Builds $tmp/$1: a superproject with two submodules, a main clone of it, and
# a worktree of that main clone with both submodules uninitialized.
#   deps/other  one commit, in the main clone's gitdir; always bootstraps.
#   $2          commits A and B; the superproject pins B, the main clone's
#               checkout stays at A. $3 says where B is:
#                 in-main   also fetched into the main clone's gitdir
#                 pushed    on the submodule's origin only
#                 unpushed  on neither
make_fixture() {
  local root="$tmp/$1" path="$2" where="$3"
  mkdir -p "$root"
  git init -q --bare "$root/other.git"
  git init -q --bare "$root/sub.git"
  git clone -q "$root/other.git" "$root/otherwork" 2>/dev/null
  (cd "$root/otherwork" && echo O > f && git add f && git commit -qm O && git push -q origin main)
  git clone -q "$root/sub.git" "$root/subwork" 2>/dev/null
  (cd "$root/subwork" && echo A > f && git add f && git commit -qm A && git push -q origin main)

  git init -q "$root/super"
  (cd "$root/super" \
    && git submodule add -q "$root/other.git" deps/other \
    && git submodule add -q "$root/sub.git" "$path" \
    && git commit -qm "add submodules")
  git clone -q "$root/super" "$root/main"
  (cd "$root/main" && git submodule update --init -q)

  (cd "$root/subwork" && echo B > f && git commit -qam B)
  if [ "$where" != unpushed ]; then
    (cd "$root/subwork" && git push -q origin main)
  fi
  (cd "$root/super/$path" && git fetch -q "$root/subwork" main && git checkout -q FETCH_HEAD)
  (cd "$root/super" && git add "$path" && git commit -qm "pin B")
  # --no-recurse-submodules: otherwise the pull fetches the new pin into the
  # main clone's gitdir on demand, and the fixture stops being the incident.
  (cd "$root/main" && git pull -q --ff-only --no-recurse-submodules)
  if [ "$where" = in-main ]; then
    (cd "$root/main" && git submodule update -q)
  fi
  git -C "$root/main" worktree add -q --detach "$root/main/wt" HEAD
}

run_bootstrap() { # $1=worktree; sets out and rc
  out="$(cd "$1" && bash "$SCRIPT" 2>&1)"
  rc=$?
}

state_of() { # $1=checkout  $2=submodule path
  case "$(git -C "$1" submodule status -- "$2")" in
    " "*) echo at-pin ;;
    "+"*) echo differs ;;
    "-"*) echo uninitialized ;;
    *)    echo other ;;
  esac
}

short() { git -C "$1" rev-parse --short "$2"; }

echo "test_pin_in_main_clone_gitdir"
make_fixture baseline "deps/my sub" in-main
wt="$tmp/baseline/main/wt"
run_bootstrap "$wt"
check "exit status" "0" "$rc"
check "submodule at its pin" "at-pin" "$(state_of "$wt" "deps/my sub")"
check "pinned content checked out" "B" "$(cat "$wt/deps/my sub/f" 2>/dev/null)"
check "other submodule at its pin" "at-pin" "$(state_of "$wt" deps/other)"
check_lacks "no network retry" "fetching from origin" "$out"

echo "test_pin_missing_from_main_clone_gitdir_is_fetched"
make_fixture incident "deps/my sub" pushed
wt="$tmp/incident/main/wt"
run_bootstrap "$wt"
check "exit status" "0" "$rc"
check "submodule at its pin" "at-pin" "$(state_of "$wt" "deps/my sub")"
check "pinned content checked out" "B" "$(cat "$wt/deps/my sub/f" 2>/dev/null)"
check "other submodule at its pin" "at-pin" "$(state_of "$wt" deps/other)"
check_contains "says it fetched" "deps/my sub -> pinned commit missing from local gitdir" "$out"
check "origin is the real url" "$tmp/incident/sub.git" \
  "$(git -C "$wt/deps/my sub" remote get-url origin)"

echo "test_unreachable_pin_fails_and_resets_the_checkout"
make_fixture unreachable "deps/my sub" unpushed
wt="$tmp/unreachable/main/wt"
a="$(short "$tmp/unreachable/subwork" HEAD~1)"
b="$(short "$tmp/unreachable/subwork" HEAD)"
run_bootstrap "$wt"
check "exit status" "1" "$rc"
check_contains "names the path and both commits" \
  "deps/my sub: checked out $a, pinned $b" "$out"
check "reset to uninitialized" "uninitialized" "$(state_of "$wt" "deps/my sub")"
check "checkout emptied" "" "$(ls -A "$wt/deps/my sub")"
check "other submodule untouched by the reset" "at-pin" "$(state_of "$wt" deps/other)"
check "main clone's checkout untouched" "$a" "$(short "$tmp/unreachable/main/deps/my sub" HEAD)"
check "main clone's url untouched" "$tmp/unreachable/sub.git" \
  "$(git -C "$tmp/unreachable/main" config "submodule.deps/my sub.url")"

echo "test_rerun_after_fixing_reaches_the_pin"
(cd "$tmp/unreachable/subwork" && git push -q origin main)
run_bootstrap "$wt"
check "exit status" "0" "$rc"
check "submodule at its pin" "at-pin" "$(state_of "$wt" "deps/my sub")"
check "pinned content checked out" "B" "$(cat "$wt/deps/my sub/f" 2>/dev/null)"

echo "test_assistant_failure_keeps_the_ssh_hint"
make_fixture hint packages/nicegram-assistant-ios unpushed
run_bootstrap "$tmp/hint/main/wt"
check "exit status" "1" "$rc"
check_contains "ssh hint" "ssh -T git@bitbucket.org" "$out"

echo "test_stray_files_in_an_uninitialized_path_survive"
make_fixture stray "deps/my sub" in-main
wt="$tmp/stray/main/wt"
echo mine > "$wt/deps/my sub/keep.txt"
run_bootstrap "$wt"
check "exit status" "1" "$rc"
check_contains "reported as uninitialized" "deps/my sub: uninitialized" "$out"
check "still uninitialized" "uninitialized" "$(state_of "$wt" "deps/my sub")"
check "stray file survives" "mine" "$(cat "$wt/deps/my sub/keep.txt" 2>/dev/null)"
# git -C on a directory without its own .git walks up to the superproject, so
# a retry here would fetch the wrong repository.
check_lacks "no retry on an unpopulated path" "fetching from origin" "$out"

echo "test_untouched_submodule_off_its_pin_is_not_checked"
make_fixture untouched "deps/my sub" in-main
wt="$tmp/untouched/main/wt"
git -C "$wt" submodule update --init -q -- "deps/my sub"
git -C "$wt/deps/my sub" commit -q --allow-empty -m "feature work"
ahead="$(short "$wt/deps/my sub" HEAD)"
run_bootstrap "$wt"
check "exit status" "0" "$rc"
check "the bootstrapped one is at its pin" "at-pin" "$(state_of "$wt" deps/other)"
check "the untouched one still differs" "differs" "$(state_of "$wt" "deps/my sub")"
check "the untouched one kept its commit" "$ahead" "$(short "$wt/deps/my sub" HEAD)"

if [ "$failures" -ne 0 ]; then
  echo "test-bootstrap-submodules: $failures failure(s)"
  exit 1
fi
echo "test-bootstrap-submodules: all passed"
