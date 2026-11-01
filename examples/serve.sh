#!/bin/sh
# Demo workload: refuses to start without the secret, then serves a static page.
set -eu

: "${APP_PASSWORD:?APP_PASSWORD or APP_PASSWORD_FILE must be set}"

root=$(mktemp -d)
echo "ok" > "$root/index.html"
exec httpd -f -p 8080 -h "$root"
