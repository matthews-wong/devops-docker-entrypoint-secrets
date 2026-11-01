#!/bin/sh
# Expand NAME_FILE=/path variables into NAME, then exec the command.
set -eu

die() {
    echo "entrypoint: $*" >&2
    exit 1
}

load_secret() {
    name=$1
    file=$(printenv "${name}_FILE")

    if [ -n "$(printenv "$name" || true)" ]; then
        die "both ${name} and ${name}_FILE are set; unset one of them"
    fi
    if [ ! -f "$file" ] || [ ! -r "$file" ]; then
        die "${name}_FILE points to ${file}, which is not a readable file"
    fi

    # Command substitution strips trailing newlines, as most secret tooling expects.
    value=$(cat "$file")
    export "${name}=${value}"
    unset "${name}_FILE"
}

[ $# -gt 0 ] || die "no command given"

for name in $(env | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)_FILE=.*/\1/p'); do
    load_secret "$name"
done

exec "$@"
