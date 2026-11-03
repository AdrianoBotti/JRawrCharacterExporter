#!/bin/sh
# Imports the committed Lua test samples through JRawr's real character importer.
#
# The compatibility test lives in this repository but is compiled by JRawr's Gradle test
# source set, so it uses JRawr's dependencies and the same CharacterFixtureLoader as the
# application import. JRawr is never modified permanently: the copied test is removed on exit.
#
# Usage:
#   JRAWR_DIR=/path/to/JRawr tools/check-jrawr-import.sh
#
# The default JRawr location is ../JRawr. Java 25 is required (JRawr's toolchain).

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
jrawr=${JRAWR_DIR:-"$here/../JRawr"}
gradlew="$jrawr/jrawr/gradlew"
destdir="$jrawr/jrawr/rawr-data/src/test/java/rawr/addoncompat"
dest="$destdir/JRawrCharacterExporterImportTest.java"

if [ ! -f "$gradlew" ]; then
    echo "check-jrawr-import: JRawr not found at $jrawr (set JRAWR_DIR)" >&2
    exit 2
fi

if [ -e "$dest" ]; then
    echo "check-jrawr-import: refusing to overwrite $dest" >&2
    exit 2
fi

cleanup() {
    rm -f "$dest"
    rmdir "$destdir" 2>/dev/null || true
    rmdir "$(dirname "$destdir")" 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "$destdir"
cp "$here/tools/jrawr-import-check/JRawrCharacterExporterImportTest.java" "$dest"

JRAWR_ADDON_SAMPLES="$here/test/output_samples" \
    sh "$gradlew" -p "$jrawr/jrawr" :rawr-data:test \
        --tests rawr.addoncompat.JRawrCharacterExporterImportTest \
        --rerun-tasks --no-daemon --console=plain
