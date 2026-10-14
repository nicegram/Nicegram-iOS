#!/bin/bash
#
# Initializes any uninitialized git submodules before a build runs.
#
# Why this exists: creating a git worktree (the "create worktree" checkbox,
# or the harness's EnterWorktree flow used by NICEGRAM-AGENTS.md) checks out
# the branch but never runs `git submodule update --init`. Left alone, the
# first Bazel build fails ~30s in with:
#   No MODULE.bazel, REPO.bazel, or WORKSPACE file found in .../rules_xcodeproj
# which names neither "submodule" nor "worktree" -- a confusing error for
# something that takes one command to fix. There is no harness hook that
# covers every path that creates a worktree, so the fix lives at point of
# use: every ci/ wrapper calls this script before it does anything else.
#
# Fast path (the overwhelmingly common case: everything already
# initialized): exactly one `git submodule status` call, silent, exit 0.
#
# Slow path: for each uninitialized submodule, prefer cloning from the
# main clone's own gitdir -- hardlinked, seconds, no network -- over a full
# network clone (which can be ~550MB across all submodules). This requires
# `-c protocol.file.allow=always` because git blocks file-protocol submodule
# transports by default (CVE-2022-39253 mitigation).
#
# That gitdir holds only what the main clone has fetched, so it can lack a
# pin pushed from another worktree. git then exits 128 and leaves the clone
# at the gitdir's own HEAD with an empty working tree, so a local clone that
# missed its pin fetches it from the real url.
#
# A run fails unless every submodule it initialized ends at its pinned
# commit, and one that does not is emptied so the next run retries it
# instead of taking the fast path. Submodules a run did not initialize are
# never checked, here or on the fast path: one off its pin is the normal
# state during feature work, and build-to-testflight checks the assistant
# out away from the host's pin on purpose.
#
# Do NOT construct "$MAIN/.git/modules/<path>" by hand: it is wrong for at
# least one submodule. packages/nicegram-assistant-ios stores its gitdir at
# .git/modules/Nicegram/packages/nicegram-assistant-ios (a legacy path with
# an extra "Nicegram/" segment). Ask git for the real gitdir instead, via
# `git -C "$MAIN/<path>" rev-parse --absolute-git-dir`.
#
# Safe to run from the repo root or from ci/ -- it resolves the repo's own
# top-level directory before doing anything else.

cd "$(git rev-parse --show-toplevel)" || exit 1

# List of submodule paths that `git submodule status` marks uninitialized
# (those lines are prefixed with "-", as "-<sha> <path>"). Strip that
# fixed prefix with sed instead of splitting the line on whitespace with
# awk's $2: this repo has 1661 tracked paths containing spaces, and a
# whitespace split silently truncates any of those to its first word.
list_uninitialized() {
  git submodule status | sed -n 's/^-[0-9a-fA-F]* //p'
}

# " " at the pinned commit, "+" checked out elsewhere, "-" uninitialized,
# "U" in a merge conflict. Status compares with the index's gitlink, which is
# what `submodule update` checks out; `git ls-tree HEAD` would misread a
# staged one.
status_prefix() {
  git submodule status -- "$1" | cut -c1
}

missing="$(list_uninitialized)"
if [ -z "$missing" ]; then
  # Fast path: nothing to do.
  exit 0
fi

count="$(echo "$missing" | grep -c .)"
echo "bootstrap-submodules: $count submodule(s) uninitialized, bootstrapping..."

# The main clone -- the checkout this worktree (if it is one) branched
# from. Resolved to an absolute path (not left as whatever
# --git-common-dir happens to return, which is "." when run from the
# repo root of the main clone itself -- that would otherwise show up
# verbatim in the "not populated in main clone at ." message below). In
# the main clone itself this resolves to the repo root, making the
# lookup below a harmless no-op (it will just fall back to network, same
# as if there were no main clone to borrow from).
MAIN="$(cd "$(dirname "$(git rev-parse --git-common-dir)")" && pwd)"

echo "$missing" | while IFS= read -r path; do
  [ -n "$path" ] || continue

  # Require an actual .git entry (file or dir), not just an existing
  # directory: an empty/placeholder dir would make `-C ... rev-parse` walk
  # up and misreport the *enclosing* repo's own gitdir as a false match.
  gitdir=""
  if [ -e "$MAIN/$path/.git" ]; then
    gitdir="$(git -C "$MAIN/$path" rev-parse --absolute-git-dir 2>/dev/null)"
  fi

  if [ -n "$gitdir" ]; then
    echo "  $path -> local gitdir ($gitdir), no network"
    git -c protocol.file.allow=always -c "submodule.$path.url=$gitdir" submodule update --init -- "$path"
  else
    echo "  $path -> network clone (not populated in main clone at $MAIN)"
    git submodule update --init -- "$path"
  fi

  # Repoint just this submodule's configured url back at its real
  # .gitmodules url. Scoped to this one path, not a bare `git submodule
  # sync`: a worktree SHARES .git/config with the main clone, and an
  # unscoped sync rewrites submodule.<name>.url for every submodule in
  # it, clobbering any deliberate local URL override on one this loop
  # never touched. Needed after the local-gitdir branch above, whose -c
  # override was only ever a per-invocation config value, never
  # persisted; a harmless no-op after the network branch, which already
  # wrote the right url itself.
  git submodule sync -- "$path" >/dev/null

  # After the sync, which is what points origin at the real url. Only for a
  # clone that exists ("+"): on a "-" path `git -C` would walk up and fetch
  # the superproject instead. A network clone already came from that url.
  if [ -n "$gitdir" ] && [ "$(status_prefix "$path")" = "+" ]; then
    echo "  $path -> pinned commit missing from local gitdir, fetching from origin"
    git -C "$path" fetch origin
    git submodule update -- "$path"
  fi
done

not_at_pin="$(echo "$missing" | while IFS= read -r path; do
  [ -n "$path" ] && [ "$(status_prefix "$path")" != " " ] && echo "$path"
done)"
if [ -n "$not_at_pin" ]; then
  echo "" >&2
  echo "bootstrap-submodules: FAILED -- not at the pinned commit:" >&2
  echo "$not_at_pin" | while IFS= read -r path; do
    pin="$(git rev-parse --short ":$path")"
    if [ "$(status_prefix "$path")" = "-" ]; then
      echo "  - $path: uninitialized, pinned $pin" >&2
    else
      echo "  - $path: checked out $(git -C "$path" rev-parse --short HEAD), pinned $pin" >&2
      # Usually just this run's clone, but not always: git also reattaches a
      # module gitdir an earlier reset kept, or re-activates a submodule set
      # inactive by hand, into a directory that is not empty, and that content
      # goes too. Skipping such a path would leave it at "+" for the next run's
      # fast path to pass. A "-" path is left alone: it may hold files git
      # refused to clone over, and the next run retries it anyway.
      rm -rf "$path" && mkdir -p "$path"
    fi
  done
  if echo "$not_at_pin" | grep -qx 'packages/nicegram-assistant-ios'; then
    echo "" >&2
    echo "packages/nicegram-assistant-ios is a private Bitbucket repo" >&2
    echo "(git@bitbucket.org:mobyrix/nicegram-assistant-ios.git). It needs your" >&2
    echo "SSH key registered with Bitbucket and reachable via ssh-agent. Check with:" >&2
    echo "  ssh -T git@bitbucket.org" >&2
  fi
  echo "" >&2
  echo "Fix access/network for the path(s) above, then re-run the build --" >&2
  echo "or run the manual loop in NICEGRAM-AGENTS.md (\"Starting a feature\")." >&2
  exit 1
fi

exit 0
