# JRawr Character Exporter

[![test](https://github.com/AdrianoBotti/JRawrCharacterExporter/actions/workflows/test.yml/badge.svg)](https://github.com/AdrianoBotti/JRawrCharacterExporter/actions/workflows/test.yml)

A World of Warcraft 3.3.5 (Wrath of the Lich King) addon that exports the current character as Rawr
character XML. The XML is shown in a copyable box and can be pasted into JRawr or the original
WotLK Rawr tool.

## Features

The addon exports the active dual-spec specialization: talents and glyphs, plus equipped gear
(item id, gems and enchant), the per-character optimizer availability pool (equipped items plus
equippable items found in the backpack, bags and bank), race, class, realm/region and
primary/secondary professions.

## Requirements

- World of Warcraft 3.3.5a.
- JRawr or the original WotLK 3.3.5a Rawr tool for importing the XML.
- Optional for development: Lua 5.1, `luacheck` and Python 3.

## Installation

Download the latest release zip and extract `JRawrCharacterExporter` into:

```
World of Warcraft/Interface/AddOns/JRawrCharacterExporter/
```

Or copy this folder there directly. It must contain `JRawrCharacterExporter.toc`,
`JRawrCharacterExporterClasses.lua`, `JRawrCharacterExporterData.lua` and
`JRawrCharacterExporter.lua`.

## Usage

1. Open your bank once before exporting if you want bank items in the optimizer pool. Carried
   bags are read directly, but the game does not expose bank container contents until the bank
   frame has been opened.
2. Type `/jrawr` (or `/jrce`) in game.
3. Click **Select All** (or click the box and press Ctrl+A), then press **Ctrl+C**.
4. Open JRawr, go to **File → Import**, paste into the **Character XML** box and import. The same
   XML can be loaded by the original WotLK Rawr tool.

## Compatibility

The exported XML uses the original Rawr character schema, not a JRawr-specific format. It is
expected to work with the original WotLK 3.3.5a Rawr tool as well as JRawr; the output was loaded
successfully with the original Rawr engine. Optional elements the addon does not emit, such as
active buffs, boss options and calculation options, are defaulted by Rawr. As with any Rawr
character file, equipped item ids must exist in Rawr's item cache. This targets the 3.3.5-era
schema.

## Status line and warnings

The window shows how many slots and available items were exported, the talent points and **major**
glyphs, and which Rawr model was inferred. Rawr's tables include major glyphs (and minor glyphs for
some classes); an unmodeled minor glyph is ignored silently, while an unknown major glyph gets a
chat warning (for example on a non-English client). The XML is still produced with the unset glyph
left unchanged. If the XML is longer than the visible box, the edit box grows so the scroll bar
reaches the last line.

## Glyph debugging

If glyphs do not show up, `/jrawr debug` (or `/jrce debug`) prints the client's glyph sockets
(enabled/type/spell), the link name returned by `GetGlyphLink`, the spell name from `GetSpellInfo`
and whether either name matched the Rawr table. On 3.3.5 `GetGlyphSocketInfo` does not return a
link and `enabled` only means the socket is unlocked, so the addon uses
`GetGlyphLink(socket, GetActiveTalentGroup())` for the active dual-spec set. If `GetGlyphLink` is
unavailable, it falls back to the spell name from the glyph spell ID. Glyph type 1 is major and 2
is minor (from `Blizzard_GlyphUI.lua`); the status counts major glyphs only, but minor glyphs
present in Rawr's table are still exported.

## Notes and limitations

- WoW 3.3.5 addons cannot write arbitrary files. The XML is shown in game and copied through the
  clipboard; it is not written to disk.
- Bag/bank items are included when the client has item information cached; non-equippable items,
  bags and quivers are skipped. Equipped items are always included, and an equipped quiver/ammo
  pouch is exported as `<ProjectileBag>`.
- Bank contents require the bank to be open at least once; the addon cannot open it for you.
  Guild bank and mail contents are not scanned.
- The `CurrentModel` is inferred from the active spec (e.g. Protection warrior -> `ProtWarr`,
  Feral druid -> `Bear`/`Cat` from the current form). Change it in JRawr if the guess is wrong.
- Glyphs are matched by their English glyph name from the item link, with the glyph spell name as
  a fallback (both are localized, so this remains an enUS-reliable path). Talents use the game's
  tier/column positions and are locale-independent.
- If the character has no talent points in any tree, a sensible class default model is used.

## Development

`JRawrCharacterExporterData.lua` is generated from the talent/glyph annotations in the JRawr
repository. From a JRawr checkout, with this repository next to it:

```bash
python3 tools/addon-data-gen/generate.py --addon-dir ../JRawrCharacterExporter
python3 tools/addon-data-gen/generate.py --check --addon-dir ../JRawrCharacterExporter
```

The XML output samples under `test/output_samples/` are also vendored into JRawr's `rawr-data`
tests, so an intentional output change must regenerate them here and update the copies in JRawr.

`JRawrCharacterExporterClasses.lua` is shared by the addon and the harness; the addon loads it
before the generated data table. `check.sh` runs `luacheck` if available, then the Lua suite and
`git diff --check`.

### Tests

`test/run.sh` (Lua 5.1) stubs the 3.3.5 API and runs the addon against every class/spec, all
inventory slots, item-link variants, escaping, professions, unknown glyphs, error paths and long
exports; a normal run also checks the committed output samples are current. `./check.sh` also runs
`luacheck` when it is installed. See `test/README.md` and `docs/IN_GAME_TEST.md`.

```bash
./check.sh
test/run.sh
test/run.sh --write-samples
```

Use `--write-samples` only for an intentional XML change; inspect the diff before committing it.

## Contributing

Contributions are welcome. If you find a bug or have an improvement, open an issue at
https://github.com/AdrianoBotti/JRawrCharacterExporter/issues. Pull requests are welcome too;
please keep the addon compatible with WoW 3.3.5a and original Rawr, run `./check.sh`, and add or
update tests and output samples for behavior changes.

See [CONTRIBUTING.md](CONTRIBUTING.md) for issue details, the test workflow and the pull-request
checklist.

## Acknowledgements

This addon is part of the JRawr project and builds on the character XML format and talent data of
the original Rawr project. See `NOTICE` for attribution.

## License

Apache License 2.0. See `LICENSE` and `NOTICE`.

## AI-generated code disclaimer

This addon was developed with substantial AI assistance. The initial implementation and the
subsequent refactors were generated by an LLM coding agent (opencode, DeepSeek Flash) under human
direction. The LLM wrote the Lua addon and XML generation, the talent/glyph mapping integration,
the offline Lua test harness, the `luacheck`/CI/release workflows and most of the documentation,
and performed the code review and quality pass.

The maintainer provided the project idea and WoW 3.3.5 requirements, defined the expected behavior
(active spec, gear/gems/enchants, professions, availability pool, model inference and original
Rawr compatibility), chose the repository structure and `JRawrCharacterExporter` name, reviewed the
generated output, and directed the test, reliability and documentation work. Human review and
in-game validation remain the responsibility of the maintainer; see `docs/IN_GAME_TEST.md`.
