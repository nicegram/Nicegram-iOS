#!/bin/bash
#
# On a work account the app never shows or sends the account's own phone
# number. Each place that would carries a marked guard in Telegram code, and
# .claude/skills/tg-merge/scripts/work-account-phone.py checks that every one is
# still there. This test asserts each site against the real tree, one assertion
# per site, then proves on a fixture copy that the check fails when a guard, an
# alert or a whole block is lost, or a block appears where the list does not
# name one.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
SCRIPT="$ROOT/.claude/skills/tg-merge/scripts/work-account-phone.py"

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
contains() { # $1=label  $2=needle  $3=haystack
  if printf '%s\n' "$3" | grep -qF -- "$2"; then
    echo "  ok   $1"
  else
    echo "  FAIL $1"
    echo "         missing: [$2]"
    failures=$((failures + 1))
  fi
}

sites_and_paths() { # prints "site<TAB>path" per listed file
  python3 -I - "$SCRIPT" <<'EOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("wap", sys.argv[1])
wap = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wap)
for site, (_, paths) in wap.SITES.items():
    for path in paths:
        print(f"{site}\t{path}")
for site, paths in wap.DATA_SITES.items():
    for path in paths:
        print(f"{site}\t{path}")
EOF
}

# --- the real tree, one assertion per site ---

real="$(cd "$ROOT" && python3 "$SCRIPT" check)"
real_status=$?
check "real tree: check exits 0" "0" "$real_status"
for site in $(sites_and_paths | cut -f1 | sort -u); do
  contains "real tree: $site guarded" "ok   $site" "$real"
done

# --- a fixture copy, broken one way at a time ---

FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT

make_fixture() {
  rm -rf "$FIXTURE/tree"
  mkdir -p "$FIXTURE/tree"
  sites_and_paths | cut -f2 | sort -u | while IFS= read -r path; do
    mkdir -p "$FIXTURE/tree/$(dirname "$path")"
    cp "$ROOT/$path" "$FIXTURE/tree/$path"
  done
  git -C "$FIXTURE/tree" init -q
  git -C "$FIXTURE/tree" add -A
}

run_fixture() {
  git -C "$FIXTURE/tree" add -A
  (cd "$FIXTURE/tree" && python3 "$SCRIPT" check)
}

# Deletes the first line matching $2 that follows the tag of site $3 in file $1.
drop_after_tag() {
  python3 -I - "$FIXTURE/tree/$1" "$2" "// Nicegram Business, work-account phone: $3" <<'EOF'
import sys
path, needle, tag = sys.argv[1:]
lines = open(path, encoding="utf-8").read().split("\n")
start = next(i for i, l in enumerate(lines) if l.strip().startswith(tag))
hit = next(i for i in range(start, len(lines)) if needle in lines[i])
del lines[hit]
open(path, "w", encoding="utf-8").write("\n".join(lines))
EOF
}

HEADER="submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoHeaderNode.swift"
CHAT="submodules/TelegramUI/Sources/ChatController.swift"
LOGOUT="submodules/SettingsUI/Sources/LogoutOptionsController.swift"

make_fixture
out="$(run_fixture)"; status=$?
check "fixture: unbroken copy passes" "0" "$status"

make_fixture
drop_after_tag "$HEADER" "restrictsAccountControl()" "settings-header"
out="$(run_fixture)"; status=$?
check "fixture: lost guard fails" "1" "$status"
contains "fixture: lost guard names its site" "FAIL settings-header" "$out"

make_fixture
drop_after_tag "$CHAT" "accountControlAlert(" "bot-share-contact"
out="$(run_fixture)"; status=$?
check "fixture: lost alert fails" "1" "$status"
contains "fixture: lost alert names its site" "bot-share-contact: $CHAT: no block shows the work-account alert" "$out"

make_fixture
drop_after_tag "$LOGOUT" "work-account phone: change-number" "change-number"
out="$(run_fixture)"; status=$?
check "fixture: lost block fails" "1" "$status"
contains "fixture: lost block names its file" "change-number: $LOGOUT: 0 block(s), expected 1" "$out"

SEARCH="submodules/SettingsUI/Sources/Search/SettingsSearchableItems.swift"
make_fixture
drop_after_tag "$SEARCH" "withAccountControlCheck(" "settings-search"
out="$(run_fixture)"; status=$?
check "fixture: lost search guard fails" "1" "$status"
contains "fixture: lost search guard names its site" "FAIL settings-search" "$out"

make_fixture
mkdir -p "$FIXTURE/tree/submodules/Stray/Sources"
printf '%s\n' "// Nicegram Business, work-account phone: copy-phone" "if context.nicegramBusiness.restrictsAccountControl() {" > "$FIXTURE/tree/submodules/Stray/Sources/Stray.swift"
out="$(run_fixture)"; status=$?
check "fixture: unlisted block fails" "1" "$status"
contains "fixture: unlisted block named" "submodules/Stray/Sources/Stray.swift:1: block 'copy-phone' is not in SITES" "$out"

OWN_QR="submodules/TelegramUI/Sources/SharedAccountContext.swift"
OPEN_URL="submodules/TelegramUI/Sources/OpenResolvedUrl.swift"
SHARE_OPEN="Nicegram/NGDataSharing/Sources/ShareChatOnOpening/ShareChatOnOpening.swift"
DATA_TAG_TEXT="work-account data sharing"

drop_after_data_tag() { # $1=file $2=needle $3=site
  python3 -I - "$FIXTURE/tree/$1" "$2" "// Nicegram Business, $DATA_TAG_TEXT: $3" <<'EOF2'
import sys
path, needle, tag = sys.argv[1:]
lines = open(path, encoding="utf-8").read().split("\n")
start = next(i for i, l in enumerate(lines) if l.strip().startswith(tag))
hit = next(i for i in range(start, len(lines)) if needle in lines[i])
del lines[hit]
open(path, "w", encoding="utf-8").write("\n".join(lines))
EOF2
}

make_fixture
drop_after_tag "$OWN_QR" "restrictsAccountControl()" "own-qr"
out="$(run_fixture)"; status=$?
check "fixture: lost own-qr guard fails" "1" "$status"
contains "fixture: lost own-qr guard names its site" "FAIL own-qr" "$out"

make_fixture
drop_after_tag "$OPEN_URL" "accountControlAlert(" "privacy-phone-number"
out="$(run_fixture)"; status=$?
check "fixture: lost phone_privacy alert fails" "1" "$status"
contains "fixture: lost phone_privacy alert named" "privacy-phone-number: $OPEN_URL: no block shows the work-account alert" "$out"

make_fixture
drop_after_data_tag "$SHARE_OPEN" "restrictsAccountControl()" "share-on-opening"
out="$(run_fixture)"; status=$?
check "fixture: lost data-sharing guard fails" "1" "$status"
contains "fixture: lost data-sharing guard names its site" "FAIL share-on-opening" "$out"

SHARE_STICKERS="Nicegram/NGDataSharing/Sources/ShareStickers/ShareStickers.swift"
make_fixture
drop_after_data_tag "$SHARE_STICKERS" "restrictsAccountControl()" "share-stickers"
out="$(run_fixture)"; status=$?
check "fixture: lost stickers guard fails" "1" "$status"
contains "fixture: lost stickers guard names its site" "FAIL share-stickers" "$out"

make_fixture
printf '%s\n' "// Nicegram Business, $DATA_TAG_TEXT: parse-users" "guard !context.nicegramBusiness.restrictsAccountControl() else { return }" > "$FIXTURE/tree/submodules/Stray.swift"
out="$(run_fixture)"; status=$?
check "fixture: unlisted data-sharing block fails" "1" "$status"
contains "fixture: unlisted data-sharing block named" "submodules/Stray.swift:1: block 'parse-users' is not in DATA_SITES" "$out"

if [ "$failures" -ne 0 ]; then
  echo "test-work-account-phone: $failures failure(s)"
  exit 1
fi
echo "test-work-account-phone: all passed"
