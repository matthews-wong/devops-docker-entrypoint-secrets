#!/bin/sh
# Plain sh tests; no container runtime needed.
# shellcheck disable=SC2016  # the sh -c snippets must expand in the child, not here
set -eu

ENTRYPOINT="$(cd "$(dirname "$0")/.." && pwd)/entrypoint.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
FAILED=0

check() {
    desc=$1 expected=$2 actual=$3
    if [ "$expected" = "$actual" ]; then
        echo "ok   - $desc"
    else
        echo "FAIL - $desc: expected '$expected', got '$actual'"
        FAILED=1
    fi
}

printf 'hunter2\n' > "$WORK/pw"
printf 'a b\nc\n\n' > "$WORK/multi"

out=$(env DB_PASSWORD_FILE="$WORK/pw" "$ENTRYPOINT" sh -c 'printf %s "$DB_PASSWORD"')
check "reads file into variable" "hunter2" "$out"

out=$(env DB_PASSWORD_FILE="$WORK/pw" "$ENTRYPOINT" sh -c 'printf %s "${DB_PASSWORD_FILE-unset}"')
check "drops the _FILE variable" "unset" "$out"

out=$(env TOKEN_FILE="$WORK/multi" "$ENTRYPOINT" sh -c 'printf %s "$TOKEN"')
check "keeps inner newlines, strips trailing ones" "$(printf 'a b\nc')" "$out"

out=$(env A_FILE="$WORK/pw" B_FILE="$WORK/multi" "$ENTRYPOINT" sh -c 'printf %s "$A|$B"')
check "handles several variables" "hunter2|$(printf 'a b\nc')" "$out"

out=$(env PLAIN=1 "$ENTRYPOINT" sh -c 'printf %s "$PLAIN"')
check "passes through when no _FILE is set" "1" "$out"

if err=$(env DB_PASSWORD_FILE="$WORK/missing" "$ENTRYPOINT" true 2>&1); then rc=0; else rc=$?; fi
check "missing file exits 1" "1" "$rc"
case $err in
    *"DB_PASSWORD_FILE points to $WORK/missing"*) check "missing file error names variable and path" 1 1 ;;
    *) check "missing file error names variable and path" "named" "$err" ;;
esac

if err=$(env DB_PASSWORD=x DB_PASSWORD_FILE="$WORK/pw" "$ENTRYPOINT" true 2>&1); then rc=0; else rc=$?; fi
check "conflicting NAME and NAME_FILE exits 1" "1" "$rc"
case $err in
    *hunter2*) check "error does not leak the secret" "no leak" "$err" ;;
    *) check "error does not leak the secret" 1 1 ;;
esac

if "$ENTRYPOINT" >/dev/null 2>&1; then rc=0; else rc=$?; fi
check "no command exits 1" "1" "$rc"

exit "$FAILED"
