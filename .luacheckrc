std = "lua51"
max_line_length = false

-- WoW 3.3.5 API, addon globals and the test harness's fakes. The harness intentionally defines
-- the API functions as globals, so they are writable here.
globals = {
    "ChatFontNormal",
    "CreateFrame",
    "GLYPHTYPE_MAJOR",
    "GLYPHTYPE_MINOR",
    "GetActiveTalentGroup",
    "GetContainerItemLink",
    "GetContainerNumSlots",
    "GetCurrentRegion",
    "GetGlyphLink",
    "GetGlyphSocketInfo",
    "GetInventoryItemLink",
    "GetItemInfo",
    "GetNumGlyphSockets",
    "GetNumTalentTabs",
    "GetNumTalents",
    "GetProfessionInfo",
    "GetProfessions",
    "GetRealmName",
    "GetShapeshiftForm",
    "GetShapeshiftFormInfo",
    "GetSpellInfo",
    "GetTalentInfo",
    "GetTalentTabInfo",
    "JRawrCharacterExporterClasses",
    "JRawrCharacterExporterData",
    "JRawrCharacterExporterForms",
    "NUM_BAG_SLOTS",
    "NUM_BANKBAGSLOTS",
    "NUM_GLYPH_SLOTS",
    "print",
    "SLASH_JRAWRCHARACTEREXPORTER1",
    "SLASH_JRAWRCHARACTEREXPORTER2",
    "SlashCmdList",
    "UIParent",
    "UnitClass",
    "UnitName",
    "UnitRace",
}

files["test/wow_api.lua"] = {
    ignore = { "212" },
}
