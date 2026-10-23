-- Shared class metadata for JRawrCharacterExporter.
--
-- This file is loaded before JRawrCharacterExporterData.lua and
-- JRawrCharacterExporter.lua (both in game and in the offline test harness).

-- 3.3.5 GetShapeshiftForm IDs: 1 Bear, 2 Aquatic, 3 Cat, 4 Travel, 5 Moonkin/Tree.
local FORMS = {
    BEAR = 1,
    CAT = 3,
    MOONKIN = 5,
}

-- One table per class: the Rawr class name, the XML talent element and the model inference.
-- Single-model classes use `single`; multi-model classes use `trees` (tab 1..3) and a
-- `fallback` for characters with no talent points. `forms` marks Druid, whose feral specs use
-- the active shapeshift form.
local CLASSES = {
    WARRIOR = {
        name = "Warrior",
        talentElement = "WarriorTalents",
        trees = { "DPSWarr", "DPSWarr", "ProtWarr" },
        fallback = "DPSWarr",
    },
    PALADIN = {
        name = "Paladin",
        talentElement = "PaladinTalents",
        trees = { "Healadin", "ProtPaladin", "Retribution" },
        fallback = "Retribution",
    },
    HUNTER = {
        name = "Hunter",
        talentElement = "HunterTalents",
        single = "Hunter",
    },
    ROGUE = {
        name = "Rogue",
        talentElement = "RogueTalents",
        single = "Rogue",
    },
    PRIEST = {
        name = "Priest",
        talentElement = "PriestTalents",
        trees = { "HealPriest", "HealPriest", "ShadowPriest" },
        fallback = "HealPriest",
    },
    DEATHKNIGHT = {
        name = "DeathKnight",
        talentElement = "DeathKnightTalents",
        trees = { "TankDK", "DPSDK", "DPSDK" },
        fallback = "DPSDK",
    },
    SHAMAN = {
        name = "Shaman",
        talentElement = "ShamanTalents",
        trees = { "Elemental", "Enhance", "RestoSham" },
        fallback = "Elemental",
    },
    MAGE = {
        name = "Mage",
        talentElement = "MageTalents",
        single = "Mage",
    },
    WARLOCK = {
        name = "Warlock",
        talentElement = "WarlockTalents",
        single = "Warlock",
    },
    DRUID = {
        name = "Druid",
        talentElement = "DruidTalents",
        trees = { "Moonkin", "Cat", "Tree" },
        fallback = "Cat",
        forms = true,
    },
}

for token, info in pairs(CLASSES) do
    if not info.name or not info.talentElement then
        error("JRawrCharacterExporter: incomplete class data for " .. token)
    end
    if not (info.single or (info.trees and info.fallback)) then
        error("JRawrCharacterExporter: missing model mapping for " .. token)
    end
end

JRawrCharacterExporterClasses = CLASSES
JRawrCharacterExporterForms = FORMS
