# Contributing

Thanks for taking the time to improve JRawr Character Exporter. Bug reports, compatibility notes,
documentation fixes and pull requests are all welcome.

## Reporting issues

Open an issue at <https://github.com/AdrianoBotti/JRawrCharacterExporter/issues>. Before opening a
new one, search the existing issues.

Please include:

- addon version from `JRawrCharacterExporter.toc`;
- WoW client version and locale;
- steps to reproduce;
- what you expected and what happened;
- for glyph problems, the output of `/jrawr debug` (or `/jrce debug`);
- a minimal character XML export if it helps, with personal names/realm removed.

Do not paste account credentials or other private information.

## Pull requests

1. Fork the repository and create a focused branch.
2. Keep the addon compatible with WoW 3.3.5a and the original WotLK Rawr character XML.
3. Add or update a Lua test for behavior changes. Run `./check.sh`.
4. If the XML output changes intentionally, run `test/run.sh --write-samples`, inspect the diff,
   and copy the updated `test/output_samples/*.xml` files into JRawr's
   `jrawr/rawr-data/src/test/resources/jrawr-character-exporter-samples/` directory.
5. Update the README, `test/README.md` or `docs/IN_GAME_TEST.md` when behavior or testing changes.
6. Do not hand-edit generated files such as `JRawrCharacterExporterData.lua`; regenerate them from
   the JRawr talent annotations instead.
7. In the pull request, describe the problem, the change and the checks you ran.

## Development checks

Requirements: Lua 5.1, optionally `luacheck` and Python 3.

```bash
./check.sh
test/run.sh
```

`check.sh` runs `luacheck` when available, the Lua suite and `git diff --check`.

## Scope and compatibility

- Target the WoW 3.3.5a client and its Lua 5.1 dialect.
- Do not add runtime dependencies; the addon must remain self-contained.
- Keep the XML compatible with both JRawr and the original WotLK Rawr tool.
- One in-game test is still required for client API or UI changes; see `docs/IN_GAME_TEST.md`.

## License

By contributing, you agree that your contributions are licensed under the Apache License 2.0 used
by this repository.
