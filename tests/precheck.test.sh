#!/bin/sh
# Plain-shell tests for skills/review/scripts/precheck.sh (no model involved).
# Usage: sh tests/precheck.test.sh
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
SCRIPT="$HERE/../skills/review/scripts/precheck.sh"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/precheck-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT INT TERM
GIT=$(command -v git)
fails=0

expect() { # name, expected, actual
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: expected '$2', got '$3'"; fails=$((fails+1)); fi
}

# 1. not a repo (GIT_CEILING_DIRECTORIES stops discovery of any enclosing repo)
mkdir -p "$TMP/plain"
out=$(cd "$TMP/plain" && GIT_CEILING_DIRECTORIES="$TMP" sh "$SCRIPT"); code=$?
expect "non-git dir -> NOT_A_REPO" "PRECHECK=NOT_A_REPO" "$out"
expect "non-git dir exits 0" "0" "$code"

# 2. repo root
mkdir -p "$TMP/repo/sub/dir"
"$GIT" -C "$TMP/repo" init -q
out=$(cd "$TMP/repo" && sh "$SCRIPT"); code=$?
expect "repo root -> OK" "PRECHECK=OK" "$out"
expect "repo root exits 0" "0" "$code"

# 3. subdirectory of a repo
out=$(cd "$TMP/repo/sub/dir" && sh "$SCRIPT")
expect "repo subdir -> OK" "PRECHECK=OK" "$out"

# 4. git missing from PATH (only a dir with sh-builtins-free tools; command -v is a builtin)
mkdir -p "$TMP/emptybin"
out=$(cd "$TMP/repo" && PATH="$TMP/emptybin" /bin/sh "$SCRIPT"); code=$?
expect "no git on PATH -> NO_GIT_BINARY" "PRECHECK=NO_GIT_BINARY" "$out"
expect "no git exits 0" "0" "$code"

# 5. exactly one output line in every case
lines=$(cd "$TMP/repo" && sh "$SCRIPT" | wc -l | tr -d ' ')
expect "single output line" "1" "$lines"

# 6. inside .git directory (not a work tree)
out=$(cd "$TMP/repo/.git" && sh "$SCRIPT")
expect "inside .git -> NOT_A_REPO" "PRECHECK=NOT_A_REPO" "$out"

if [ "$fails" -eq 0 ]; then echo "OK: all precheck tests passed"; exit 0; fi
echo "FAIL: $fails precheck test(s) failed"; exit 1
