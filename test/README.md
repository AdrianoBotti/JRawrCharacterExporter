# JRawr Character Exporter offline tests

`run.lua` stubs the WoW 3.3.5 API, loads the real `JRawrCharacterExporterData.lua` +
`JRawrCharacterExporter.lua`, and checks the generated Rawr character XML. It covers:

- every class and spec mapping in `CurrentModel` (including druid forms and tree ties);
- the compact talent/glyph string (`(tab, tier, column)` indices, glyph names, unknown glyphs);
- all 20 inventory slots, gemmed-id variants (no link, bare id, gems, enchant, negative/zero ids);
- XML escaping, professions, missing/unknown class data and the error box;
- long exports growing the edit box so the scroll bar reaches the last line;
- the generated talent/glyph tables (index coverage, grid keys, lower-case unique glyph names).

Run it from the repository root with Lua 5.1:

```bash
test/run.sh
# or
LUA=/path/to/lua5.1 test/run.sh
```

## Samples

`--write-samples` regenerates `samples/*.xml` from the same scenarios:

```bash
test/run.sh --write-samples
```

The samples are committed and also vendored into JRawr, where
`JRawrCharacterExporterAddonSamplesTest` (in `rawr-data`) loads them through the same
`CharacterFixtureLoader` as the web Import tab. A normal harness run compares the generated XML
against the committed samples and fails when they are stale, so after an intentional addon output
change run `--write-samples` and inspect the diff: they are the contract between the Lua addon and
JRawr. Copy the regenerated samples into the JRawr repository as well.

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
manual run on a 3.3.5 client. The stubs follow the documented 3.3.5 signatures
(`GetTalentInfo`, `GetTalentTabInfo`, `GetProfessions`, `GetProfessionInfo`). In particular,
`GetGlyphSocketInfo(socket, group)` returns `enabled, glyphType, glyphSpellID, icon` and no link;
enabled means the socket is unlocked. Glyph presence/name comes from
`GetGlyphLink(socket, GetActiveTalentGroup())`, which is stubbed with `""` for empty sockets. The
stub uses the real 3.3.5 socket layout/types (1/4/6 major, 2/3/5 minor; type 1 major, 2 minor) and
the status/paths distinguish unmodeled minor glyphs from unknown major glyphs.
