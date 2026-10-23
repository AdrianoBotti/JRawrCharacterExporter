#!/bin/sh
# Runs the offline JRawr Character Exporter tests. Requires a Lua 5.1 interpreter (the WoW 3.3.5 dialect).
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
lua=${LUA:-lua5.1}

if ! command -v "$lua" >/dev/null 2>&1; then
    echo "JRawr Character Exporter tests: '$lua' not found (set LUA=/path/to/lua5.1)" >&2
    exit 2
fi

exec "$lua" "$here/run.lua" "$@"
