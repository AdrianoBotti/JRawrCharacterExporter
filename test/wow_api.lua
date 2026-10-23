-- Offline WoW 3.3.5 API stub and fixture state for JRawrCharacterExporter tests.
--
-- This file defines the fake client APIs, fake widgets and the scenario state. It is loaded
-- before the addon and the test cases. It has no dependency on the addon itself.

local printed = {}
local realPrint = print
print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    printed[#printed + 1] = table.concat(parts, " ")
end

local state = {}

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
        formIcon5 = "Interface\\Icons\\Spell_Nature_ForceOfNature",
        tabs = 3,
        points = { 60, 0, 0 },
        talents = {},
        glyphSockets = {},
        glyphSocketCount = 6,
        talentGroup = 1,
        inventory = {},
        bags = {},
        itemEquipLoc = {},
        itemInfoCalls = 0,
        spellNames = {},
        skillLines = {},
    }
end

local function resetPrinted()
    for i = #printed, 1, -1 do
        printed[i] = nil
    end
end

local function scenario(overrides)
    local base = newState()
    for key in pairs(state) do
        state[key] = nil
    end
    for key, value in pairs(base) do
        state[key] = value
    end
    for key, value in pairs(overrides or {}) do
        if base[key] == nil then
            error("scenario: unknown key " .. tostring(key))
        end
        state[key] = value
    end
    if not state.className then
        state.className = state.classToken
    end
    if not state.raceName then
        state.raceName = state.raceToken
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

local FORM_ICONS = {
    [24858] = "Interface\\Icons\\Spell_Nature_ForceOfNature",
    [33891] = "Interface\\Icons\\Ability_Druid_TreeofLife",
}

function UnitName() return state.name end
function GetRealmName() return state.realm end
function GetCurrentRegion() return state.region end
function UnitRace() return state.raceName, state.raceToken end
function UnitClass() return state.className, state.classToken end
function GetShapeshiftForm() return state.form end
function GetShapeshiftFormInfo(index)
    if index == 5 then
        return state.formIcon5, "Form 5", true, false
    end
    return nil
end
function GetSpellInfo(spellId)
    local name = state.spellNames[spellId]
    if name then
        return name, "", "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    local icon = FORM_ICONS[spellId]
    if icon then
        return "Spell " .. tostring(spellId), "", icon
    end
    return nil
end
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
    state.itemInfoCalls = state.itemInfoCalls + 1
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
function GetNumSkillLines()
    return #state.skillLines
end
function GetSkillLineInfo(index)
    local line = state.skillLines[index]
    if not line then
        return nil
    end
    return line.name, line.isHeader or false, true, line.rank or 450,
        0, 0, line.maxRank or 450, false, 0, 0, 1, 1, ""
end

local function showExport()
    local frame = _G.JRawrCharacterExporterFrame
    assert(frame, "JRawrCharacterExporterFrame was not created")
    frame.hidden = true
    frame:Show()
    return _G.JRawrCharacterExporterEditBox:GetText(),
        _G.JRawrCharacterExporterStatus:GetText()
end

scenario()

return {
    state = state,
    printed = printed,
    realPrint = realPrint,
    scenario = scenario,
    resetPrinted = resetPrinted,
    showExport = showExport,
}
