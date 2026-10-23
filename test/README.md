# JRawr Character Exporter offline tests

`test/wow_api.lua` stubs the WoW 3.3.5 API and fixture state. `test/run.lua` loads the real
`JRawrCharacterExporterClasses.lua`, `JRawrCharacterExporterData.lua` and
`JRawrCharacterExporter.lua`, then checks the generated Rawr character XML. It covers:

- every class and spec mapping in `CurrentModel` (including druid forms and tree ties);
- zero-talent-point fallbacks and the Druid form-5 Moonkin/Tree distinction;
- the compact talent/glyph string (`(tab, tier, column)` indices, glyph names, unknown glyphs,
  and the glyph-spell-ID fallback);
- all 20 inventory slots, the equipped projectile bag, gemmed-id variants and partial gemming;
- bags, bank, item-info caching and unknown item info;
- XML escaping, professions, missing APIs, error paths and the error box;
- long exports growing the edit box so the scroll bar reaches the last line;
- the generated talent/glyph tables (index coverage, grid keys, lower-case unique glyph names).

Run the checks from the repository root with Lua 5.1:

```bash
./check.sh
test/run.sh
# or
LUA=/path/to/lua5.1 test/run.sh
```

`check.sh` runs `luacheck` when it is installed, then the Lua suite and `git diff --check`. On
Ubuntu, install the tools with:

```bash
sudo apt-get install lua5.1 lua-check
```

## Samples

`--write-samples` regenerates `output_samples/*.xml` from the same scenarios:

```bash
test/run.sh --write-samples
```

The output samples are committed and also vendored into JRawr, where
`JRawrCharacterExporterAddonSamplesTest` (in `rawr-data`) loads them through the same
`CharacterFixtureLoader` as the web Import tab. A normal harness run compares the generated XML
against the committed output samples and fails when they are stale, so after an intentional addon
output change run `--write-samples` and inspect the diff: they are the contract between the Lua
addon and JRawr. Copy the regenerated output samples into the JRawr repository as well.

## Data table

`JRawrCharacterExporterData.lua` is generated from the talent/glyph annotations in the JRawr
repository; verify it is current (and that every talent/glyph annotation is covered exactly once)
from a JRawr checkout with:

```bash
python3 tools/addon-data-gen/generate.py --check --addon-dir ../JRawrCharacterExporter
```

## Limit

This is an offline API-level test, not an in-game test. It cannot catch API differences in a
specific client build, taint, secure-code restrictions, or the copy/paste UI; those still need one
manual run on a 3.3.5 client. See `docs/IN_GAME_TEST.md`.

The stubs are the harness's model of the client. They follow the documented 3.3.5 signatures
(`GetTalentInfo`, `GetTalentTabInfo`, `GetNumSkillLines`, `GetSkillLineInfo`). In particular,
`GetGlyphSocketInfo(socket, group)` returns `enabled, glyphType, glyphSpellID, icon` and no link;
enabled means the socket is unlocked. Glyph presence/name comes from
`GetGlyphLink(socket, GetActiveTalentGroup())` (stubbed with `""` for empty sockets), with
`GetSpellInfo(glyphSpellID)` as the fallback. The stub uses the real 3.3.5 socket layout/types
(1/4/6 major, 2/3/5 minor; type 1 major, 2 minor) and the status/paths distinguish unmodeled minor
glyphs from unknown major glyphs.
