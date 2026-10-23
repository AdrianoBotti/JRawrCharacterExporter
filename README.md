# JRawr Character Exporter (WoW 3.3.5 addon)

Builds the current character's Rawr character XML and shows it in a copyable, scrollable box for
pasting into JRawr's Import tab.

## Install

Copy this folder to:

```
World of Warcraft/Interface/AddOns/JRawrCharacterExporter/
```

(It must contain `JRawrCharacterExporter.toc`, `JRawrCharacterExporterData.lua` and
`JRawrCharacterExporter.lua`.)

## Use

1. Open your bank once before exporting if you want bank items in the optimizer pool. Carried
   bags are read directly, but the game does not expose bank container contents until the bank
   frame has been opened.
2. Type `/jrawr` (or `/jrce`) in game.
3. Click **Select All** (or click the box and press Ctrl+A), then press **Ctrl+C**.
4. Open JRawr, go to **File → Import**, paste into the **Character XML** box and import.

The addon exports the active dual-spec specialization: talents and glyphs, plus equipped gear
(item id, gems and enchant), the per-character optimizer availability pool (equipped items plus
equippable items found in the backpack, bags and bank), race, class, realm/region and
primary/secondary professions.

## Status line and warnings

The window shows how many slots and available items were exported, the talent points and **major**
glyphs, and which Rawr model was inferred. Rawr's tables include major glyphs (and minor glyphs for
some classes); an unmodeled minor glyph is ignored silently, while an unknown major glyph gets a
chat warning (for example on a non-English client). The XML is still produced with the unset glyph
left unchanged. If the XML is longer than the visible box, the edit box grows so the scroll bar
reaches the last line.

## Glyph debugging

If glyphs do not show up, `/jrawr debug` (or `/jrce debug`) prints the client's glyph sockets
(enabled/type/spell), the link name returned by `GetGlyphLink` and whether that name matched the
Rawr table. On 3.3.5 `GetGlyphSocketInfo` does not return a link and `enabled` only means the
socket is unlocked, so the addon uses `GetGlyphLink(socket, GetActiveTalentGroup())` for the active
dual-spec set. Glyph type 1 is major and 2 is minor (from `Blizzard_GlyphUI.lua`); the status counts
major glyphs only, but minor glyphs present in Rawr's table are still exported.

## Tests

`test/run.sh` (Lua 5.1) stubs the 3.3.5 API and runs the addon against every class/spec, all
inventory slots, item-link variants, escaping, professions, unknown glyphs, error paths and long
exports; a normal run also checks the committed XML samples are current. See `test/README.md`.

```bash
test/run.sh
test/run.sh --write-samples
```

## Notes and limits

- WoW 3.3.5 addons cannot write arbitrary files. The XML is shown in game and copied through the
  clipboard; it is not written to disk.
- Bag/bank items are included when the client has item information cached; non-equippable items,
  bags and quivers are skipped. Equipped items are always included.
- Bank contents require the bank to be open at least once; the addon cannot open it for you.
  Guild bank and mail contents are not scanned.
- The `CurrentModel` is inferred from the active spec (e.g. Protection warrior -> `ProtWarr`,
  Feral druid -> `Bear`/`Cat` from the current form). Change it in JRawr if the guess is wrong.
- Glyphs are matched by their English glyph name from the item link, so glyph import is reliable on
  enUS clients. Talents use the game's tier/column positions and are locale-independent.
- If the character has no talent points in any tree, a sensible class default model is used.

## Development

`JRawrCharacterExporterData.lua` is generated from the talent/glyph annotations in the JRawr
repository. From a JRawr checkout, with this repository next to it:

```bash
python3 tools/addon-data-gen/generate.py --addon-dir ../JRawrCharacterExporter
python3 tools/addon-data-gen/generate.py --check --addon-dir ../JRawrCharacterExporter
```

The offline XML samples under `test/samples/` are also vendored into JRawr's `rawr-data` tests, so
an intentional output change must regenerate them here and update the copies in JRawr.

## License

Apache License 2.0. See `LICENSE` and `NOTICE`.
