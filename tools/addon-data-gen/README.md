# addon-data-gen

Generates `JRawrCharacterExporterData.lua` from the talent/glyph annotations in the JRawr
repository.

From this repository root, with a JRawr checkout next to it:

```bash
python3 tools/addon-data-gen/generate.py
python3 tools/addon-data-gen/generate.py --check
python3 tools/addon-data-gen/generate.py --jrawr-dir /path/to/JRawr
```

The JRawr checkout is expected next to this repository by default; override it with `--jrawr-dir`
or the `JRAWR_DIR` environment variable. The generated table maps the game's
`(tab, tier, column)` talent positions and English glyph names to the compact talent/glyph indices
stored in Rawr character XML. It is committed so the addon can be installed without running
Python; regenerate it when the JRawr talent tables change.

The generator validates that every talent and glyph annotation has a unique index covering
`0..count-1`, that grid positions are unique per tab and valid, and that glyph names are unique and
lower-case. `--check` fails (exit code 1) when the committed `JRawrCharacterExporterData.lua` is
stale.
