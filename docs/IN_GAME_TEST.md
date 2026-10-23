# In-game test checklist (WoW 3.3.5a)

The Lua suite runs outside the client and cannot prove client API behavior. Run this checklist once
per addon release on a real 3.3.5a client.

1. Install `JRawrCharacterExporter` under `Interface/AddOns/`.
2. Log in and type `/jrawr`; the window opens and `/jrce` does the same.
3. Copy the XML into JRawr (File → Import) and into the original WotLK Rawr tool.
4. Check the imported name, realm, race, class, current model, professions and equipped items.
5. Test both dual-spec talent groups; talents and glyphs must follow the active group.
6. Test Druid forms: caster, Bear, Cat, travel, Moonkin and Tree of Life. Check form 5 maps to
   Moonkin or Tree correctly.
7. Open the bank, then refresh; bag and bank items should appear in the optimizer pool.
8. Equip a quiver/ammo pouch on a hunter; `<ProjectileBag>` should be present.
9. Test a non-enUS client or document the known glyph-name limitation. `/jrawr debug` must print
   the socket, link name, spell name and match result.
10. Test an empty character and a character with no talent points.
11. Confirm the status line counts slots, available items, talent points and major glyphs.
12. Check that long XML scrolls to the last line and that Select All + Ctrl+C copies everything.
