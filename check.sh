#!/bin/sh
# Runs the static checks and offline Lua tests.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$here"

if command -v luacheck >/dev/null 2>&1; then
    luacheck .
else
    echo "check.sh: luacheck not found; skipping static analysis" >&2
fi

LUA=${LUA:-lua5.1} test/run.sh

if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git diff --check
fi
