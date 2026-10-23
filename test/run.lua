-- Offline tests for JRawrCharacterExporter.lua.
--
--   lua5.1 test/run.lua
--   lua5.1 test/run.lua --write-samples
--
-- The harness stubs the WoW 3.3.5 API, loads the real addon, and checks the generated Rawr XML.
-- --write-samples regenerates test/samples/*.xml, which JRawrCharacterExporterAddonSamplesTest
-- loads through the Java character importer. The committed samples are the contract between the Lua
-- addon and the Java side.

local scriptPath = (arg and arg[0]) or "test/run.lua"
local scriptDir = scriptPath:match("^(.*)[/\\][^/\\]*$") or "."
local addonDir = scriptDir .. "/.."
local writeSamples = false
for _, value in ipairs(arg or {}) do
    if value == "--write-samples" then
        writeSamples = true
    end
end

---------------------------------------------------------------------------------------------------
-- WoW 3.3.5 API stub
---------------------------------------------------------------------------------------------------

local CLASS_NAMES = {
    WARRIOR = "Warrior",
    PALADIN = "Paladin",
    HUNTER = "Hunter",
    ROGUE = "Rogue",
    PRIEST = "Priest",
    DEATHKNIGHT = "DeathKnight",
    SHAMAN = "Shaman",
    MAGE = "Mage",
    WARLOCK = "Warlock",
    DRUID = "Druid",
}

local RACE_NAMES = {
    Human = "Human",
    Orc = "Orc",
    Dwarf = "Dwarf",
    NightElf = "NightElf",
    Scourge = "Undead",
    Tauren = "Tauren",
    Gnome = "Gnome",
    Troll = "Troll",
    BloodElf = "BloodElf",
    Draenei = "Draenei",
}

local TALENT_ELEMENTS = {
    WARRIOR = "WarriorTalents",
    PALADIN = "PaladinTalents",
    HUNTER = "HunterTalents",
    ROGUE = "RogueTalents",
    PRIEST = "PriestTalents",
    DEATHKNIGHT = "DeathKnightTalents",
    SHAMAN = "ShamanTalents",
    MAGE = "MageTalents",
    WARLOCK = "WarlockTalents",
    DRUID = "DruidTalents",
}

local printed = {}
local realPrint = print
print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    printed[#printed + 1] = table.concat(parts, " ")
end

local state

local function newState()
    return {
        name = "Testmage",
        realm = "TestRealm",
        region = 1,
        raceToken = "Human",
        raceName = "Human",
        classToken = "MAGE",
        className = "Mage",
        form = 0,
        tabs = 3,
        points = { 60, 0, 0 },
        talents = {},
        glyphSockets = {},
        glyphSocketCount = 6,
        talentGroup = 1,
        inventory = {},
        bags = {},
        itemEquipLoc = {},
        professions = {},
        professionInfo = {},
        professionInfoCalls = 0,
        professionZeroCalls = 0,
    }
end

local function resetPrinted()
    printed = {}
end

local function scenario(overrides)
    state = newState()
    for key, value in pairs(overrides or {}) do
        state[key] = value
    end
    if not state.className then
        state.className = CLASS_NAMES[state.classToken] or state.classToken
    end
    if not state.raceName then
        state.raceName = RACE_NAMES[state.raceToken] or state.raceToken
    end
    resetPrinted()
    return state
end

local function newWidget(kind, name)
    local widget = {
        kind = kind,
        scripts = {},
        hidden = kind == "Frame",
        width = 0,
        height = kind == "ScrollFrame" and 470 or 0,
        text = "",
        value = 0,
        min = 0,
        max = 0,
        scroll = 0,
    }

    function widget:SetWidth(value) self.width = value end
    function widget:SetHeight(value) self.height = value end
    function widget:GetHeight() return self.height end
    function widget:SetPoint() end
    function widget:SetFrameStrata() end
    function widget:SetMovable() end
    function widget:EnableMouse() end
    function widget:RegisterForDrag() end
    function widget:SetClampedToScreen() end
    function widget:SetBackdrop() end
    function widget:StartMoving() end
    function widget:StopMovingOrSizing() end
    function widget:SetScript(event, handler) self.scripts[event] = handler end
    function widget:Show()
        self.hidden = false
        if self.scripts.OnShow then
            self.scripts.OnShow(self)
        end
    end
    function widget:Hide()
        self.hidden = true
        if self.scripts.OnHide then
            self.scripts.OnHide(self)
        end
    end
    function widget:IsShown() return not self.hidden end
    function widget:SetText(value) self.text = value or "" end
    function widget:GetText() return self.text end
    function widget:SetMultiLine() end
    function widget:SetAutoFocus() end
    function widget:SetMaxLetters() end
    function widget:SetFontObject() end
    function widget:GetFont() return "Fonts\\FRIZQT__.TTF", 12, "" end
    function widget:SetJustifyH() end
    function widget:SetScrollChild() end
    function widget:EnableMouseWheel() end
    function widget:SetValueStep() end
    function widget:SetMinMaxValues(minimum, maximum)
        self.min = minimum
        self.max = maximum
        if self.value < self.min then
            self:SetValue(self.min)
        elseif self.value > self.max then
            self:SetValue(self.max)
        end
    end
    function widget:GetMinMaxValues() return self.min, self.max end
    function widget:SetValue(value)
        if value < self.min then value = self.min end
        if value > self.max then value = self.max end
        if self.value ~= value then
            self.value = value
            if self.scripts.OnValueChanged then
                self.scripts.OnValueChanged(self, value)
            end
        end
    end
    function widget:GetValue() return self.value end
    function widget:SetVerticalScroll(value)
        if self.scroll ~= value then
            self.scroll = value
            if self.scripts.OnVerticalScroll then
                self.scripts.OnVerticalScroll(self, value)
            end
        end
    end
    function widget:GetVerticalScroll() return self.scroll end
    function widget:SetFocus() end
    function widget:ClearFocus() end
    function widget:HighlightText() end
    function widget:SetCursorPosition() end
    function widget:CreateFontString(childName)
        return newWidget("FontString", childName)
    end

    if name then
        _G[name] = widget
    end
    return widget
end

function CreateFrame(kind, name)
    return newWidget(kind, name)
end

ChatFontNormal = "ChatFontNormal"
NUM_GLYPH_SLOTS = 6
UIParent = newWidget("Frame")
SlashCmdList = {}

function UnitName() return state.name end
function GetRealmName() return state.realm end
function GetCurrentRegion() return state.region end
function UnitRace() return state.raceName, state.raceToken end
function UnitClass() return state.className, state.classToken end
function GetShapeshiftForm() return state.form end
function GetNumTalentTabs() return state.tabs end
function GetTalentTabInfo(tab) return "Tree" .. tab, "icon", state.points[tab] or 0 end
function GetNumTalents(tab) return #(state.talents[tab] or {}) end
function GetTalentInfo(tab, index)
    local talent = state.talents[tab] and state.talents[tab][index]
    if not talent then
        return "Talent", "icon", 1, 1, 0, 5
    end
    return "Talent", "icon", talent[1], talent[2], talent[3], 5
end

-- 3.3.5 socket layout: 1 and 4 and 6 are major, 2, 3 and 5 are minor. The socket keeps its type
-- even when empty (Blizzard_GlyphUI.lua uses it to draw the ring).
local GLYPH_SOCKET_TYPES = { [1] = 1, [2] = 2, [3] = 2, [4] = 1, [5] = 2, [6] = 1 }

function GetNumGlyphSockets() return state.glyphSocketCount end
-- 3.3.5 signature: enabled, glyphType, glyphSpellID, icon. No link. "enabled" means the socket is
-- unlocked, not that a glyph is present (empty sockets are enabled for a level-80 character).
function GetGlyphSocketInfo(socket)
    local glyph = state.glyphSockets[socket]
    local glyphType = GLYPH_SOCKET_TYPES[socket] or 1
    if not glyph then
        return true, glyphType, nil, nil
    end
    return glyph.enabled ~= false, glyph.glyphType or glyphType, glyph.spellId, nil
end
-- 3.3.5: added in 3.1.0; returns "" for an empty (or locked) socket. The talentGroup argument
-- selects the active dual-spec glyph set.
function GetGlyphLink(socket, group)
    local glyph = state.glyphSockets[socket]
    if not glyph or glyph.enabled == false then
        return ""
    end
    if group == 2 and glyph.link2 then
        return glyph.link2
    end
    return glyph.link or ""
end
function GetActiveTalentGroup() return state.talentGroup end

function GetInventoryItemLink(_, slot) return state.inventory[slot] end
function GetContainerNumSlots(bag)
    local contents = state.bags[bag]
    return contents and #contents or 0
end
function GetContainerItemLink(bag, slot)
    local contents = state.bags[bag]
    return contents and contents[slot] or nil
end
function GetItemInfo(itemOrLink)
    local id
    if type(itemOrLink) == "number" then
        id = itemOrLink
    else
        id = tonumber(string.match(tostring(itemOrLink), "item:(%d+)"))
    end
    if not id then
        return nil
    end
    local equipLoc = state.itemEquipLoc[id]
    if equipLoc == false then
        return nil
    end
    return "Test item", nil, 4, 200, 80, "Armor", "Cloth", 1,
        equipLoc or "INVTYPE_HEAD", "Interface\\Icons\\inv_misc_questionmark", 1000, 4, 0
end
function GetProfessions()
    local professions = state.professions
    return professions[1], professions[2], professions[3], professions[4],
        professions[5], professions[6], professions[7]
end
function GetProfessionInfo(index)
    state.professionInfoCalls = state.professionInfoCalls + 1
    if index == 0 then
        state.professionZeroCalls = state.professionZeroCalls + 1
        return nil
    end
    local info = state.professionInfo[index]
    if not info then
        return nil
    end
    return info.name, "icon", 450, 450, 0, 0, info.skillLine
end

-- The real files; the data table must be global before the addon captures it.
dofile(addonDir .. "/JRawrCharacterExporterData.lua")
dofile(addonDir .. "/JRawrCharacterExporter.lua")

---------------------------------------------------------------------------------------------------
-- Test helpers
---------------------------------------------------------------------------------------------------

local assertions = 0
local failures = 0
local currentTest = "?"

local function check(condition, message)
    assertions = assertions + 1
    if not condition then
        failures = failures + 1
        realPrint("FAIL " .. currentTest .. ": " .. message)
    end
end

local function equal(actual, expected, label)
    check(actual == expected, string.format("%s: expected %q, got %q",
        label, tostring(expected), tostring(actual)))
end

local function contains(haystack, needle, label)
    check(type(haystack) == "string" and haystack:find(needle, 1, true) ~= nil,
        label .. ": missing " .. tostring(needle))
end

local function notContains(haystack, needle, label)
    check(type(haystack) == "string" and haystack:find(needle, 1, true) == nil,
        label .. ": unexpected " .. tostring(needle))
end

local function test(name, body)
    currentTest = name
    local ok, message = pcall(body)
    if not ok then
        failures = failures + 1
        realPrint("FAIL " .. name .. ": " .. tostring(message))
    end
end

local function tag(xml, name)
    return xml:match("<" .. name .. ">(.-)</" .. name .. ">")
end

local function hasTag(xml, name)
    return xml:find("<" .. name .. ">", 1, true) ~= nil
end

local function countChar(text, char)
    local count = 0
    for _ in text:gmatch(char) do
        count = count + 1
    end
    return count
end

local function showExport()
    local frame = _G.JRawrCharacterExporterFrame
    assert(frame, "JRawrCharacterExporterFrame was not created")
    frame.hidden = true
    frame:Show()
    return _G.JRawrCharacterExporterEditBox:GetText(), _G.JRawrCharacterExporterStatus:GetText()
end

local samples = {}
local function recordSample(name, xml)
    if writeSamples then
        samples[name] = xml
        return
    end
    local path = scriptDir .. "/samples/" .. name .. ".xml"
    local file = io.open(path, "rb")
    if not file then
        check(false, "missing sample " .. path .. " (run with --write-samples)")
        return
    end
    local expected = file:read("*a")
    file:close()
    equal(xml, expected, "sample " .. name .. " is current (run --write-samples)")
end

local function splitTalents(xml, element)
    local compact = tag(xml, element)
    assert(compact, "missing talent element " .. element)
    local talents, glyphs = compact:match("^([^%.]*)%.(.*)$")
    assert(talents, "malformed compact talent string: " .. compact)
    return talents, glyphs
end

local function itemLink(itemId, enchantId, gem1, gem2, gem3)
    return "|cffa335ee|Hitem:" .. itemId .. ":" .. (enchantId or 0) .. ":"
        .. (gem1 or 0) .. ":" .. (gem2 or 0) .. ":" .. (gem3 or 0)
        .. ":0:0:0:80|h[Test item]|h|r"
end

---------------------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------------------

test("mage full export", function()
    scenario({ points = { 60, 11, 0 }, region = 3 })
    state.talents = {
        [1] = { { 1, 1, 2 }, { 1, 2, 3 } },
        [2] = { { 2, 1, 5 } },
    }
    state.glyphSockets = {
        [1] = { enabled = true, link = "|cffa335ee|Hitem:42751:0:0:0|h[Glyph of Fireball]|h|r" },
        [4] = { enabled = true, link = "|cffa335ee|Hitem:42752:0:0:0|h[Glyph of Arcane Blast]|h|r" },
    }
    state.inventory = {
        [1] = itemLink(51281, 3820, 41285, 40133, 0),
        [16] = itemLink(12345, 0, 0, 0, 0),
    }
    state.professions = { 1, 2, 0, 0, 0, 0, 0 }
    state.professionInfo = {
        [1] = { name = "Enchanting", skillLine = 333 },
        [2] = { name = "Tailoring", skillLine = 197 },
    }

    local xml, status = showExport()
    equal(tag(xml, "Name"), "Testmage", "name")
    equal(tag(xml, "Realm"), "TestRealm", "realm")
    equal(tag(xml, "Region"), "EU", "region")
    equal(tag(xml, "Race"), "Human", "race")
    equal(tag(xml, "Class"), "Mage", "class")
    equal(tag(xml, "CurrentModel"), "Mage", "model")
    equal(tag(xml, "EnforceMetagemRequirements"), "true", "meta gem requirement")
    equal(tag(xml, "Head"), "51281.41285.40133.0.3820", "head gemmed id")
    equal(tag(xml, "MainHand"), "12345.0.0.0.0", "main hand gemmed id")
    equal(tag(xml, "PrimaryProfession"), "Enchanting", "primary profession")
    equal(tag(xml, "SecondaryProfession"), "Tailoring", "secondary profession")
    notContains(xml, "<Neck>", "empty neck")

    -- 0-based Rawr indices: (1,1)->0, (1,2)->1, tab 2 (2,1)->33. Glyph indices: 0 and 11.
    local talents, glyphs = splitTalents(xml, "MageTalents")
    equal(#talents, 86, "mage talent length")
    equal(#glyphs, 19, "mage glyph length")
    equal(talents:sub(1, 1), "2", "talent index 0 rank")
    equal(talents:sub(2, 2), "3", "talent index 1 rank")
    equal(talents:sub(34, 34), "5", "talent index 33 rank")
    equal(countChar(talents, "[1-9]"), 3, "talent ranks set")
    equal(glyphs:sub(1, 1), "1", "glyph index 0")
    equal(glyphs:sub(12, 12), "1", "glyph index 11")
    equal(countChar(glyphs, "1"), 2, "glyph flags set")
    equal(status, "2 slots, 2 available, 10 talent points, 2/3 major glyphs, model Mage", "status line")
    recordSample("mage_full", xml)
end)

test("item link variants", function()
    scenario()
    state.inventory = {
        [1] = "item:12345",
        [2] = "item:222:0:111:222:333",
        [3] = "item:333:444:0:0:0",
        [9] = "item:444:0:-1:0:0",
        [10] = "item:0:0:0:0:0",
        [11] = "not an item link",
    }
    local xml = showExport()
    equal(tag(xml, "Head"), "12345.0.0.0.0", "link without details")
    equal(tag(xml, "Neck"), "222.111.222.333.0", "gems without enchant")
    equal(tag(xml, "Shoulders"), "333.0.0.0.444", "enchant without gems")
    equal(tag(xml, "Wrist"), "444.0.0.0.0", "negative gem becomes 0")
    check(not hasTag(xml, "Hands"), "item id 0 must be skipped")
    check(not hasTag(xml, "Finger1"), "non-item text must be skipped")
end)

test("bags and bank contribute available equippable items", function()
    scenario()
    state.itemEquipLoc = {
        [10001] = "INVTYPE_HEAD",
        [10002] = "INVTYPE_CHEST",
        [10003] = "",
    }
    state.bags = {
        [0] = { itemLink(10001, 0, 0, 0, 0) },
        [1] = { itemLink(10002, 0, 111, 0, 0) },
        [5] = { itemLink(10003, 0, 0, 0, 0) },
        [6] = { itemLink(10001, 0, 0, 0, 0) },
    }
    local xml = showExport()
    contains(xml, "<AvailableItems>10001</AvailableItems>", "bag item is available")
    contains(xml, "<AvailableItems>10002.111.0.0.*</AvailableItems>", "bag gemming is available")
    notContains(xml, "<AvailableItems>10003", "non-equippable bag item is skipped")
    equal(select(2, xml:gsub("<AvailableItems>10001</AvailableItems>", "")), 1,
        "duplicate availability entry is collapsed")
end)

test("all inventory slots map to Rawr names", function()
    scenario()
    local slots = {
        { 1, "Head" }, { 2, "Neck" }, { 3, "Shoulders" }, { 15, "Back" },
        { 5, "Chest" }, { 4, "Shirt" }, { 19, "Tabard" }, { 9, "Wrist" },
        { 10, "Hands" }, { 6, "Waist" }, { 7, "Legs" }, { 8, "Feet" },
        { 11, "Finger1" }, { 12, "Finger2" }, { 13, "Trinket1" }, { 14, "Trinket2" },
        { 16, "MainHand" }, { 17, "OffHand" }, { 18, "Ranged" }, { 0, "Projectile" },
    }
    for _, slot in ipairs(slots) do
        state.inventory[slot[1]] = itemLink(10000 + slot[1])
    end
    local xml = showExport()
    for _, slot in ipairs(slots) do
        equal(tag(xml, slot[2]), (10000 + slot[1]) .. ".0.0.0.0", slot[2])
    end
    recordSample("all_slots", xml)
end)

test("metadata and text are XML-escaped", function()
    scenario({
        name = "A&B<C>\"D'",
        realm = "Réalm & Co",
        region = 5,
        raceToken = "Tauren",
        raceName = "Tauren",
        classToken = "DRUID",
        className = "Druid",
        form = 1,
        points = { 0, 60, 0 },
    })
    local xml = showExport()
    equal(tag(xml, "Name"), "A&amp;B&lt;C&gt;&quot;D&apos;", "escaped name")
    equal(tag(xml, "Realm"), "Réalm &amp; Co", "escaped realm")
    equal(tag(xml, "Region"), "CN", "region CN")
    equal(tag(xml, "Race"), "Tauren", "race")
    equal(tag(xml, "Class"), "Druid", "class")
    equal(tag(xml, "CurrentModel"), "Bear", "feral form model")
    recordSample("escaping", xml)
end)

test("professions: empty slots never call GetProfessionInfo(0)", function()
    scenario()
    state.professions = { 0, 0, 0, 0, 0, 0, 0 }
    local xml = showExport()
    equal(state.professionZeroCalls, 0, "GetProfessionInfo(0) calls")
    check(not hasTag(xml, "PrimaryProfession"), "empty primary profession")
    check(not hasTag(xml, "SecondaryProfession"), "empty secondary profession")
end)

test("professions: secondary skills are not Rawr professions", function()
    scenario()
    state.professions = { 0, 0, 1, 0, 0, 0, 0 }
    state.professionInfo = {
        [1] = { name = "Cooking", skillLine = 185 },
    }
    local xml = showExport()
    check(not hasTag(xml, "PrimaryProfession"), "cooking is not exported")
    check(not hasTag(xml, "SecondaryProfession"), "cooking is not exported as secondary")
end)

test("professions: two primary professions", function()
    scenario()
    state.professions = { 1, 2, 3, 0, 0, 0, 0 }
    state.professionInfo = {
        [1] = { name = "Jewelcrafting", skillLine = 755 },
        [2] = { name = "Blacksmithing", skillLine = 164 },
        [3] = { name = "Fishing", skillLine = 356 },
    }
    local xml = showExport()
    equal(tag(xml, "PrimaryProfession"), "Jewelcrafting", "primary")
    equal(tag(xml, "SecondaryProfession"), "Blacksmithing", "secondary profession slot")
    recordSample("professions", xml)
end)

test("unknown major glyph warns; unmodeled minor glyphs are ignored", function()
    scenario()
    state.glyphSockets = {
        [1] = { enabled = true, link = "|cffa335ee|Hitem:42751:0:0:0|h[Glyph of Fireball]|h|r" },
        [2] = { enabled = true, link = "|cffa335ee|Hitem:42752:0:0:0|h[Glyph of Arcane Brilliance]|h|r" },
        [4] = { enabled = true, link = "|cffa335ee|Hitem:99999:0:0:0|h[Glyph of Nonsense]|h|r" },
        [6] = { enabled = false, link = "|cffa335ee|Hitem:99998:0:0:0|h[Glyph of Disabled]|h|r" },
    }
    local xml, status = showExport()
    local _, glyphs = splitTalents(xml, "MageTalents")
    equal(glyphs:sub(1, 1), "1", "known major glyph")
    equal(countChar(glyphs, "1"), 1, "unknown/disabled glyphs stay unset")
    equal(status, "0 slots, 0 available, 0 talent points, 1/2 major glyphs, model Mage", "status")
    local warnings = table.concat(printed, "\n")
    contains(warnings, "major glyph not in the Rawr table: Glyph of Nonsense", "major warning")
    notContains(warnings, "Glyph of Arcane Brilliance", "unmodeled minor glyph warning")
    notContains(warnings, "Glyph of Disabled", "disabled socket warning")
end)

test("a client without GetGlyphLink warns instead of silently dropping glyphs", function()
    scenario()
    local saved = GetGlyphLink
    GetGlyphLink = nil
    local xml = showExport()
    GetGlyphLink = saved
    contains(table.concat(printed, "\n"), "GetGlyphLink is unavailable", "warning")
    local _, glyphs = splitTalents(xml, "MageTalents")
    equal(countChar(glyphs, "1"), 0, "no glyph flags without GetGlyphLink")
end)

test("glyphs follow the active dual-spec talent group", function()
    scenario({ talentGroup = 2 })
    state.glyphSockets = {
        [1] = {
            link = "|cffa335ee|Hitem:42751:0:0:0|h[Glyph of Fireball]|h|r",
            link2 = "|cffa335ee|Hitem:42753:0:0:0|h[Glyph of Frostbolt]|h|r",
        },
    }
    local xml, status = showExport()
    local _, glyphs = splitTalents(xml, "MageTalents")
    equal(glyphs:sub(1, 1), "0", "primary-spec glyph is not exported")
    equal(glyphs:sub(3, 3), "1", "active-spec glyph is exported")
    equal(countChar(glyphs, "1"), 1, "one glyph set")
    equal(status, "0 slots, 0 available, 0 talent points, 1/3 major glyphs, model Mage", "status")
end)

test("model inference for every class and spec", function()
    local cases = {
        { "WARRIOR", { 60, 0, 0 }, 0, "DPSWarr" },
        { "WARRIOR", { 0, 60, 0 }, 0, "DPSWarr" },
        { "WARRIOR", { 0, 0, 60 }, 0, "ProtWarr" },
        { "PALADIN", { 60, 0, 0 }, 0, "Healadin" },
        { "PALADIN", { 0, 60, 0 }, 0, "ProtPaladin" },
        { "PALADIN", { 0, 0, 60 }, 0, "Retribution" },
        { "PRIEST", { 60, 0, 0 }, 0, "HealPriest" },
        { "PRIEST", { 0, 60, 0 }, 0, "HealPriest" },
        { "PRIEST", { 0, 0, 60 }, 0, "ShadowPriest" },
        { "SHAMAN", { 60, 0, 0 }, 0, "Elemental" },
        { "SHAMAN", { 0, 60, 0 }, 0, "Enhance" },
        { "SHAMAN", { 0, 0, 60 }, 0, "RestoSham" },
        { "DEATHKNIGHT", { 60, 0, 0 }, 0, "TankDK" },
        { "DEATHKNIGHT", { 0, 60, 0 }, 0, "DPSDK" },
        { "DEATHKNIGHT", { 0, 0, 60 }, 0, "DPSDK" },
        { "DRUID", { 60, 0, 0 }, 0, "Moonkin" },
        { "DRUID", { 0, 0, 60 }, 0, "Tree" },
        { "DRUID", { 0, 60, 0 }, 0, "Cat" },
        { "DRUID", { 0, 60, 0 }, 1, "Bear" },
        { "DRUID", { 0, 60, 0 }, 3, "Cat" },
        { "HUNTER", { 60, 0, 0 }, 0, "Hunter" },
        { "ROGUE", { 60, 0, 0 }, 0, "Rogue" },
        { "MAGE", { 0, 0, 60 }, 0, "Mage" },
        { "WARLOCK", { 60, 0, 0 }, 0, "Warlock" },
    }
    local sampled = {}
    for _, case in ipairs(cases) do
        local token, points, form, model = case[1], case[2], case[3], case[4]
        scenario({
            classToken = token,
            className = CLASS_NAMES[token],
            points = points,
            form = form,
            name = "Test" .. CLASS_NAMES[token],
        })
        local xml = showExport()
        equal(tag(xml, "Class"), CLASS_NAMES[token], token .. " class")
        equal(tag(xml, "CurrentModel"), model, token .. " model for points "
            .. table.concat(points, "/") .. " form " .. form)
        local element = TALENT_ELEMENTS[token]
        local talents = splitTalents(xml, element)
        equal(#talents, JRawrCharacterExporterData[token].talentCount, token .. " talent length")
        if not sampled[token] then
            sampled[token] = true
            recordSample("class_" .. token, xml)
        end
    end
end)

test("tie between talent trees uses the first tree", function()
    scenario({ classToken = "WARRIOR", className = "Warrior", points = { 30, 30, 0 } })
    equal(tag(showExport(), "CurrentModel"), "DPSWarr", "first tree wins")
end)

test("unknown race or class shows an error instead of crashing", function()
    scenario({ classToken = "GOBLIN", className = nil })
    state.className = nil
    local xml, status = showExport()
    contains(xml, "JRawr Character Exporter error:", "error box")
    contains(xml, "unknown race/class token", "error text")
    equal(status, "Export failed.", "error status")

    scenario({ raceToken = "OGRE", raceName = nil })
    state.raceName = nil
    xml = showExport()
    contains(xml, "unknown race/class token", "unknown race error")
end)

test("missing generated data shows an error", function()
    scenario()
    local saved = JRawrCharacterExporterData.MAGE
    JRawrCharacterExporterData.MAGE = nil
    local xml = showExport()
    JRawrCharacterExporterData.MAGE = saved
    contains(xml, "no talent data for class MAGE", "missing data error")
end)

test("long exports grow the edit box so the scroll bar reaches the end", function()
    scenario({ classToken = "WARRIOR", className = "Warrior" })
    for slot = 0, 19 do
        state.inventory[slot] = itemLink(20000 + slot, slot, 0, 0, 0)
    end
    local xml = showExport()
    local lines = select(2, xml:gsub("\n", "")) + 1
    local height = _G.JRawrCharacterExporterEditBox:GetHeight()
    check(lines > 20, "long export has many lines")
    check(height >= lines * 12, "edit box tall enough for all lines")
    check(height > 470, "edit box grows past the viewport")
    local _, maximum = _G.JRawrCharacterExporterScrollBar:GetMinMaxValues()
    check(maximum > 0, "scroll range covers the overflow")
end)

test("slash commands toggle the export window", function()
    scenario()
    _G.JRawrCharacterExporterFrame:Hide()
    equal(SLASH_JRAWRCHARACTEREXPORTER1, "/jrawr", "slash command")
    equal(SLASH_JRAWRCHARACTEREXPORTER2, "/jrce", "short slash command")
    SlashCmdList["JRAWRCHARACTEREXPORTER"]()
    check(_G.JRawrCharacterExporterFrame:IsShown(), "first slash shows the window")
    contains(_G.JRawrCharacterExporterEditBox:GetText(), "<Character", "shown window has XML")
    SlashCmdList["JRAWRCHARACTEREXPORTER"]()
    check(not _G.JRawrCharacterExporterFrame:IsShown(), "second slash hides the window")
end)

test("/jrawr debug reports the real glyph socket state", function()
    scenario()
    _G.JRawrCharacterExporterFrame:Hide()
    state.glyphSockets = {
        [1] = { link = "|cffa335ee|Hitem:42751:0:0:0|h[Glyph of Fireball]|h|r" },
    }
    resetPrinted()
    SlashCmdList["JRAWRCHARACTEREXPORTER"]("debug")
    local text = table.concat(printed, "\n")
    contains(text, "glyph debug, talent group 1, 6 sockets", "debug header")
    contains(text, "1: enabled=true type=1", "major socket 1")
    contains(text, "name=[Glyph of Fireball] match=true", "matched glyph")
    contains(text, "2: enabled=true type=2", "minor empty socket")
    contains(text, "name=<empty> match=nil", "empty socket is not a glyph")
    check(not _G.JRawrCharacterExporterFrame:IsShown(), "debug does not toggle the window")
end)

test("export is deterministic", function()
    scenario()
    state.talents = { [1] = { { 1, 1, 5 } } }
    local first = showExport()
    local second = showExport()
    equal(first, second, "same input yields the same XML")
end)

test("generated talent/glyph tables are complete and consistent", function()
    local expected = {
        WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, PRIEST = true,
        DEATHKNIGHT = true, SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true,
    }
    for token in pairs(expected) do
        local info = JRawrCharacterExporterData[token]
        check(info ~= nil, "missing table for " .. token)
        if info then
            check(TALENT_ELEMENTS[token] ~= nil, "missing talent element for " .. token)
            local seenTalents, seenGlyphs = {}, {}
            for tab = 1, 3 do
                local grid = {}
                for key, index in pairs(info.talents[tab] or {}) do
                    check(tab >= 1 and tab <= 3, token .. " invalid tab " .. tab)
                    local row = math.floor(key / 10)
                    local column = key % 10
                    check(row >= 1 and row <= 11, token .. " bad row in key " .. key)
                    check(column >= 1 and column <= 4, token .. " bad column in key " .. key)
                    check(not grid[key], token .. " duplicate grid key " .. key .. " in tab " .. tab)
                    check(not seenTalents[index], token .. " duplicate talent index " .. index)
                    grid[key] = true
                    seenTalents[index] = true
                end
            end
            for index = 0, info.talentCount - 1 do
                check(seenTalents[index], token .. " missing talent index " .. index)
            end
            for index = 1, info.talentCount do
                check(seenTalents[index - 1], token .. " holes in talent indices")
            end
            check(not seenTalents[info.talentCount], token .. " talent index overflow")
            for name, index in pairs(info.glyphs) do
                check(name == name:lower(), token .. " glyph name not lower-case: " .. name)
                check(not seenGlyphs[index], token .. " duplicate glyph index " .. index)
                seenGlyphs[index] = true
            end
            for index = 0, info.glyphCount - 1 do
                check(seenGlyphs[index], token .. " missing glyph index " .. index)
            end
        end
    end
end)

---------------------------------------------------------------------------------------------------
-- Report and samples
---------------------------------------------------------------------------------------------------

if writeSamples then
    local count = 0
    for name, xml in pairs(samples) do
        local file = assert(io.open(scriptDir .. "/samples/" .. name .. ".xml", "wb"))
        file:write(xml)
        file:close()
        count = count + 1
    end
    realPrint("wrote " .. count .. " samples to " .. scriptDir .. "/samples")
end

if failures == 0 then
    realPrint(string.format("PASS %d assertions", assertions))
    os.exit(0)
else
    realPrint(string.format("FAIL %d of %d assertions", failures, assertions))
    os.exit(1)
end
