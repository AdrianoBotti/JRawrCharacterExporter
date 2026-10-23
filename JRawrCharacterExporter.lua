-- JRawr Character Exporter: builds the current character's Rawr-compatible XML and shows it in a copyable box.
--
-- WoW 3.3.5 addons cannot write arbitrary files, so this addon displays the XML in an edit box.
-- Use "Select All" (or click the box and press Ctrl+A), press Ctrl+C, then paste it into JRawr's
-- Import tab (Settings -> Import -> Character XML).
--
-- The active dual-spec specialization is exported (talents and glyphs). Glyph matching uses the
-- English glyph name from the item link, so the import is reliable on enUS clients.

local DATA = JRawrCharacterExporterData

local SLOT_ORDER = {
    { 1,  "Head" },
    { 2,  "Neck" },
    { 3,  "Shoulders" },
    { 15, "Back" },
    { 5,  "Chest" },
    { 4,  "Shirt" },
    { 19, "Tabard" },
    { 9,  "Wrist" },
    { 10, "Hands" },
    { 6,  "Waist" },
    { 7,  "Legs" },
    { 8,  "Feet" },
    { 11, "Finger1" },
    { 12, "Finger2" },
    { 13, "Trinket1" },
    { 14, "Trinket2" },
    { 16, "MainHand" },
    { 17, "OffHand" },
    { 18, "Ranged" },
    { 0,  "Projectile" },
}

local RACE_NAMES = {
    Human = "Human",
    Orc = "Orc",
    Dwarf = "Dwarf",
    NightElf = "NightElf",
    Scourge = "Undead",
    Undead = "Undead",
    Tauren = "Tauren",
    Gnome = "Gnome",
    Troll = "Troll",
    BloodElf = "BloodElf",
    Draenei = "Draenei",
}

local CLASSES = JRawrCharacterExporterClasses
local FORMS = JRawrCharacterExporterForms
if not CLASSES or not FORMS then
    error("JRawrCharacterExporterClasses is missing; reinstall the addon")
end

local REGION_NAMES = { [1] = "US", [2] = "KR", [3] = "EU", [4] = "TW", [5] = "CN" }

local PROFESSION_BY_SKILL_LINE = {
    [171] = "Alchemy",
    [164] = "Blacksmithing",
    [333] = "Enchanting",
    [202] = "Engineering",
    [182] = "Herbalism",
    [773] = "Inscription",
    [755] = "Jewelcrafting",
    [165] = "Leatherworking",
    [186] = "Mining",
    [393] = "Skinning",
    [197] = "Tailoring",
}

local PROFESSION_BY_NAME = {}
for _, name in pairs(PROFESSION_BY_SKILL_LINE) do
    PROFESSION_BY_NAME[string.lower(name)] = name
end

local function escapeXml(value)
    value = tostring(value or "")
    value = value:gsub("&", "&amp;")
    value = value:gsub("<", "&lt;")
    value = value:gsub(">", "&gt;")
    value = value:gsub('"', "&quot;")
    value = value:gsub("'", "&apos;")
    return value
end

-- item:itemId:enchantId:gem1:gem2:gem3:... on 3.3.5.
local function gemmedIdFromLink(link)
    if type(link) ~= "string" or link == "" then
        return nil
    end
    local itemId, enchantId, gem1, gem2, gem3 = string.match(
        link, "item:(%d+):(%-?%d*):(%-?%d*):(%-?%d*):(%-?%d*)")
    if not itemId then
        itemId = string.match(link, "item:(%d+)")
    end
    if not itemId then
        return nil
    end
    local function numberOrZero(value)
        local number = tonumber(value or 0) or 0
        if number < 0 then
            return 0
        end
        return number
    end
    local id = numberOrZero(itemId)
    if id <= 0 then
        return nil
    end
    return string.format("%d.%d.%d.%d.%d",
        id, numberOrZero(gem1), numberOrZero(gem2), numberOrZero(gem3),
        numberOrZero(enchantId))
end

-- Availability entries mirror the original Rawr Character Profiler import: an item with no
-- gems/enchant becomes a bare id, missing gems become wildcards, and a missing enchant becomes
-- "*". Exact gems/enchants stay exact.
local function availabilityEntry(gemmedId)
    local id, gem1, gem2, gem3, enchant = string.match(
        gemmedId, "^(%d+)%.(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    if not id then
        return gemmedId
    end
    local noGems = gem1 == "0" and gem2 == "0" and gem3 == "0"
    if noGems and enchant == "0" then
        return id
    end
    if noGems then
        gem1, gem2, gem3 = "*", "*", "*"
    end
    if enchant == "0" then
        enchant = "*"
    end
    return id .. "." .. gem1 .. "." .. gem2 .. "." .. gem3 .. "." .. enchant
end

-- Tooltip/equip-location cache for bag items. Unknown items are kept (the optimizer will filter
-- by slot); bags, quivers and non-equippable items are skipped.
local itemEquipLocCache = {}

local function itemEquipLoc(itemId)
    local cached = itemEquipLocCache[itemId]
    if cached ~= nil then
        return cached
    end
    if not GetItemInfo then
        return nil
    end
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemId)
    if equipLoc ~= nil then
        itemEquipLocCache[itemId] = equipLoc
    end
    return equipLoc
end

local function isEquippableItem(itemId)
    local equipLoc = itemEquipLoc(itemId)
    if equipLoc == nil then
        return true
    end
    if equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP"
            or equipLoc == "INVTYPE_BAG" or equipLoc == "INVTYPE_QUIVER" then
        return false
    end
    return true
end

-- Projectile bags (quivers/ammo pouches) sit in inventory slots 20..23, not in the normal
-- equipment slots. Rawr has a ProjectileBag slot for them.
local function equippedProjectileBag()
    if not GetInventoryItemLink then
        return nil
    end
    for slot = 20, 23 do
        local gemmedId = gemmedIdFromLink(GetInventoryItemLink("player", slot))
        if gemmedId then
            local itemId = tonumber(string.match(gemmedId, "^(%d+)"))
            if itemId and itemEquipLoc(itemId) == "INVTYPE_QUIVER" then
                return gemmedId
            end
        end
    end
    return nil
end

local function addAvailability(available, seen, gemmedId)
    local entry = availabilityEntry(gemmedId)
    if entry and not seen[entry] then
        seen[entry] = true
        available[#available + 1] = entry
    end
end

local function scanBag(available, seen, bag)
    if not GetContainerNumSlots or not GetContainerItemLink then
        return
    end
    local slots = GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
        local gemmedId = gemmedIdFromLink(GetContainerItemLink(bag, slot))
        if gemmedId then
            local itemId = tonumber(string.match(gemmedId, "^(%d+)"))
            if itemId and isEquippableItem(itemId) then
                addAvailability(available, seen, gemmedId)
            end
        end
    end
end

local function scanPossessions(available, seen)
    local bags = NUM_BAG_SLOTS or 4
    for bag = 0, bags do
        scanBag(available, seen, bag)
    end
    local bankBags = NUM_BANKBAGSLOTS or 7
    for index = 0, bankBags - 1 do
        scanBag(available, seen, 5 + index)
    end
    -- The bank frame itself (if the client exposes it as container -1).
    scanBag(available, seen, -1)
end

local function bestTalentTree()
    local tabs = GetNumTalentTabs and GetNumTalentTabs() or 3
    local bestTab = 1
    local bestPoints = -1
    for tab = 1, tabs do
        local points = tonumber(select(3, GetTalentTabInfo(tab))) or 0
        if points > bestPoints then
            bestPoints = points
            bestTab = tab
        end
    end
    return bestTab, bestPoints
end

local MOONKIN_FORM_SPELL = 24858
local TREE_OF_LIFE_FORM_SPELL = 33891

local function druidFormModel()
    local form = GetShapeshiftForm and GetShapeshiftForm() or 0
    if form == FORMS.BEAR then
        return "Bear"
    end
    if form == FORMS.CAT then
        return "Cat"
    end
    if form == FORMS.MOONKIN then
        -- Form 5 is Moonkin or Tree of Life. Compare both the icon and (for clients that
        -- return the name first) the localized spell name.
        local formA, formB
        if GetShapeshiftFormInfo then
            formA, formB = GetShapeshiftFormInfo(FORMS.MOONKIN)
        end
        local moonkinName, moonkinIcon, treeName, treeIcon
        if GetSpellInfo then
            local function nameAndIcon(spellId)
                local name, _, icon = GetSpellInfo(spellId)
                return name, icon
            end
            moonkinName, moonkinIcon = nameAndIcon(MOONKIN_FORM_SPELL)
            treeName, treeIcon = nameAndIcon(TREE_OF_LIFE_FORM_SPELL)
        end
        local function matches(name, icon)
            return formA == name or formB == name or formA == icon or formB == icon
        end
        if matches(moonkinName, moonkinIcon) then
            return "Moonkin"
        end
        if matches(treeName, treeIcon) then
            return "Tree"
        end
        return "Moonkin"
    end
    return "Cat"
end

local function inferModel(classToken)
    local info = CLASSES[classToken]
    if not info then
        error("unsupported class: " .. tostring(classToken))
    end
    if info.single then
        return info.single
    end

    local tree, points = bestTalentTree()
    if points <= 0 then
        return info.fallback
    end

    if info.forms then
        if tree == 1 then
            return info.trees[1]
        elseif tree == 3 then
            return info.trees[3]
        end
        return druidFormModel()
    end

    return info.trees[tree] or info.fallback
end

-- Returns the compact talent/glyph string plus the talent-point and major-glyph counts used by the
-- status line. Unknown major glyph names are reported through warnings instead of disappearing.
local function buildTalentString(classToken, warnings)
    local info = DATA and DATA[classToken]
    if not info then
        return nil
    end
    local talentChars = {}
    for i = 1, info.talentCount do
        talentChars[i] = "0"
    end
    local talentPoints = 0
    local tabs = GetNumTalentTabs and GetNumTalentTabs() or 3
    for tab = 1, tabs do
        local map = info.talents[tab]
        if map then
            local count = GetNumTalents(tab)
            for index = 1, count do
                local _, _, tier, column, rank = GetTalentInfo(tab, index)
                local rawIndex = map[tier * 10 + column]
                if rawIndex then
                    local points = tonumber(rank) or 0
                    talentChars[rawIndex + 1] = tostring(points)
                    talentPoints = talentPoints + points
                end
            end
        end
    end

    local glyphChars = {}
    for i = 1, info.glyphCount do
        glyphChars[i] = "0"
    end
    -- 3.3.5: GetGlyphSocketInfo returns enabled, glyphType, glyphSpellID, icon; it does NOT return
    -- a link, and "enabled" only means the socket is unlocked. GetGlyphLink is the API that tells us
    -- whether a glyph is actually socketed (nil/empty string when it is not). Glyph types are 1
    -- (major) and 2 (minor) in 3.3.5 (Blizzard_GlyphUI.lua).
    local majorType = GLYPHTYPE_MAJOR or 1
    local minorType = GLYPHTYPE_MINOR or 2
    local sockets = (GetNumGlyphSockets and GetNumGlyphSockets()) or NUM_GLYPH_SLOTS or 6
    local group = GetActiveTalentGroup and GetActiveTalentGroup() or nil
    local majorSlots, majorMatched = 0, 0
    if sockets > 0 and not GetGlyphLink and not GetSpellInfo and warnings then
        warnings[#warnings + 1] = "GetGlyphLink and GetSpellInfo are unavailable; glyphs cannot be exported"
    elseif sockets > 0 and not GetGlyphLink and warnings then
        warnings[#warnings + 1] = "GetGlyphLink is unavailable; using glyph spell IDs"
    end
    for socket = 1, sockets do
        local enabled, glyphType, glyphSpellID
        if GetGlyphSocketInfo then
            enabled, glyphType, glyphSpellID = GetGlyphSocketInfo(socket, group)
        else
            enabled = true
        end
        -- Missing glyphType (non-standard client) is treated as major so nothing is silently lost.
        if glyphType == nil then
            glyphType = majorType
        end
        local isMajor = glyphType ~= minorType
        if isMajor and enabled ~= false then
            majorSlots = majorSlots + 1
        end
        local link = GetGlyphLink and GetGlyphLink(socket, group) or nil
        local name
        if type(link) == "string" and link ~= "" then
            name = string.match(link, "%[(.-)%]")
        end
        if not name and glyphSpellID and GetSpellInfo then
            name = select(1, GetSpellInfo(glyphSpellID))
        end
        if name then
            local rawIndex = info.glyphs[string.lower(name)]
            if rawIndex then
                glyphChars[rawIndex + 1] = "1"
                if isMajor then
                    majorMatched = majorMatched + 1
                end
            elseif warnings and isMajor then
                -- Rawr's tables include only some minor glyphs; an unmodeled minor glyph is
                -- expected, but an unknown major glyph usually means a locale/name mismatch.
                warnings[#warnings + 1] = "major glyph not in the Rawr table: " .. tostring(name)
            end
        end
    end
    return table.concat(talentChars) .. "." .. table.concat(glyphChars),
        talentPoints, majorMatched, majorSlots
end

local function professionName(index)
    -- GetProfessions returns 0 for an empty profession slot; index 0 is not a valid argument to
    -- GetProfessionInfo (it can return nil or raise, depending on the client).
    if not index or index == 0 or not GetProfessionInfo then
        return nil
    end
    local name, _, _, _, _, _, skillLine = GetProfessionInfo(index)
    if skillLine and PROFESSION_BY_SKILL_LINE[skillLine] then
        return PROFESSION_BY_SKILL_LINE[skillLine]
    end
    if name then
        return PROFESSION_BY_NAME[string.lower(name)]
    end
    return nil
end

local function addProfessions(parts)
    if not GetProfessions then
        return
    end
    local p1, p2, p3, p4, p5, p6, p7 = GetProfessions()
    local candidates = { p1, p2, p3, p4, p5, p6, p7 }
    local found = {}
    for i = 1, 7 do
        local name = professionName(candidates[i])
        if name and not found[name] then
            found[#found + 1] = name
        end
    end
    if found[1] then
        parts[#parts + 1] = "  <PrimaryProfession>" .. escapeXml(found[1]) .. "</PrimaryProfession>"
    end
    if found[2] then
        parts[#parts + 1] = "  <SecondaryProfession>" .. escapeXml(found[2]) .. "</SecondaryProfession>"
    end
end

-- Returns the XML, a one-line summary for the UI and a list of non-fatal warnings.
local function buildExport()
    if not DATA then
        error("JRawrCharacterExporterData is missing; reinstall the addon")
    end
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or ""
    local raceToken = select(2, UnitRace("player")) or ""
    local classToken = select(2, UnitClass("player")) or ""
    local regionId = (GetCurrentRegion and GetCurrentRegion()) or 1
    local race = RACE_NAMES[raceToken]
    local classInfo = CLASSES[classToken]

    if not race or not classInfo then
        error("unknown race/class token: " .. tostring(raceToken) .. "/" .. tostring(classToken))
    end
    local className = classInfo.name

    local warnings = {}
    local talentString, talentPoints, majorMatched, majorSlots =
        buildTalentString(classToken, warnings)
    local talentElement = classInfo.talentElement
    if not talentString or not talentElement then
        error("no talent data for class " .. tostring(classToken))
    end

    local model = inferModel(classToken)
    local parts = {}
    parts[#parts + 1] = "  <Name>" .. escapeXml(name) .. "</Name>"
    parts[#parts + 1] = "  <Realm>" .. escapeXml(realm) .. "</Realm>"
    parts[#parts + 1] = "  <Region>" .. escapeXml(REGION_NAMES[regionId] or "US") .. "</Region>"
    parts[#parts + 1] = "  <Race>" .. escapeXml(race) .. "</Race>"
    parts[#parts + 1] = "  <Class>" .. escapeXml(className) .. "</Class>"
    parts[#parts + 1] = "  <CurrentModel>" .. escapeXml(model) .. "</CurrentModel>"
    parts[#parts + 1] = "  <EnforceMetagemRequirements>true</EnforceMetagemRequirements>"

    local slotCount = 0
    local available, seen = {}, {}
    for _, slot in ipairs(SLOT_ORDER) do
        local link = GetInventoryItemLink("player", slot[1])
        local gemmedId = gemmedIdFromLink(link)
        if gemmedId then
            parts[#parts + 1] = "  <" .. slot[2] .. ">" .. gemmedId .. "</" .. slot[2] .. ">"
            addAvailability(available, seen, gemmedId)
            slotCount = slotCount + 1
        end
    end
    local projectileBag = equippedProjectileBag()
    if projectileBag then
        parts[#parts + 1] = "  <ProjectileBag>" .. projectileBag .. "</ProjectileBag>"
        addAvailability(available, seen, projectileBag)
        slotCount = slotCount + 1
    end
    scanPossessions(available, seen)
    for _, entry in ipairs(available) do
        parts[#parts + 1] = "  <AvailableItems>" .. escapeXml(entry) .. "</AvailableItems>"
    end

    parts[#parts + 1] = "  <" .. talentElement .. ">" .. escapeXml(talentString) .. "</" .. talentElement .. ">"
    addProfessions(parts)

    local xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
        .. "<Character xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" "
        .. "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n"
        .. table.concat(parts, "\n")
        .. "\n</Character>\n"
    local summary = string.format("%d slots, %d available, %d talent points, %d/%d major glyphs, model %s",
        slotCount, #available, talentPoints, majorMatched, majorSlots, model)
    return xml, summary, warnings
end

local frame = CreateFrame("Frame", "JRawrCharacterExporterFrame", UIParent)
frame:SetWidth(780)
frame:SetHeight(580)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetClampedToScreen(true)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
})
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", 0, -16)
title:SetText("JRawr Character Exporter")

local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
instructions:SetPoint("TOP", 0, -34)
instructions:SetText("Open the bank first for bank items. Select All (Ctrl+A), Ctrl+C, then paste into JRawr Import.")

local status = frame:CreateFontString("JRawrCharacterExporterStatus", "OVERLAY", "GameFontHighlightSmall")
status:SetPoint("BOTTOMLEFT", 16, 46)
status:SetPoint("BOTTOMRIGHT", -16, 46)
status:SetText("")

local maxScroll = 0

local scrollFrame = CreateFrame("ScrollFrame", "JRawrCharacterExporterScrollFrame", frame)
scrollFrame:SetPoint("TOPLEFT", 16, -54)
scrollFrame:SetPoint("BOTTOMRIGHT", -32, 54)
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(_, delta)
    local scrollBar = _G["JRawrCharacterExporterScrollBar"]
    local value = scrollBar:GetValue() - (delta * 40)
    if value < 0 then value = 0 end
    if value > maxScroll then value = maxScroll end
    scrollBar:SetValue(value)
end)

local editBox = CreateFrame("EditBox", "JRawrCharacterExporterEditBox", scrollFrame)
editBox:SetMultiLine(true)
editBox:SetAutoFocus(false)
editBox:SetMaxLetters(0)
editBox:SetWidth(700)
editBox:SetHeight(3000)
editBox:SetFontObject(ChatFontNormal)
editBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    frame:Hide()
end)
scrollFrame:SetScrollChild(editBox)

local scrollBar = CreateFrame("Slider", "JRawrCharacterExporterScrollBar", frame, "UIPanelScrollBarTemplate")
scrollBar:SetPoint("TOPRIGHT", -12, -54)
scrollBar:SetPoint("BOTTOMRIGHT", -12, 54)
scrollBar:SetValueStep(1)
scrollBar:SetScript("OnValueChanged", function(_, value)
    scrollFrame:SetVerticalScroll(value)
end)
scrollFrame:SetScript("OnVerticalScroll", function(_, offset)
    scrollBar:SetValue(offset)
end)

local function refresh()
    local ok, xml, summary, warnings = pcall(buildExport)
    if not ok then
        editBox:SetText("JRawr Character Exporter error:\n" .. tostring(xml))
        status:SetText("Export failed.")
    else
        editBox:SetText(xml)
        status:SetText(summary)
        for i = 1, math.min(#warnings, 5) do
            print("|cffffcc00JRawr Character Exporter warning|r: " .. warnings[i])
        end
        if #warnings > 5 then
            print("|cffffcc00JRawr Character Exporter warning|r: " .. (#warnings - 5) .. " more glyph warnings")
        end
    end

    local lineCount = 1
    for _ in string.gmatch(editBox:GetText() or "", "\n") do
        lineCount = lineCount + 1
    end
    local _, fontSize = editBox:GetFont()
    local lineHeight = (fontSize or 12) + 4
    local viewHeight = scrollFrame:GetHeight()
    if not viewHeight or viewHeight <= 0 then
        viewHeight = 470
    end
    editBox:SetHeight(math.max(viewHeight, lineCount * lineHeight + 8))

    editBox:SetCursorPosition(0)
    maxScroll = math.max(0, editBox:GetHeight() - scrollFrame:GetHeight())
    scrollBar:SetMinMaxValues(0, maxScroll)
    scrollBar:SetValue(0)
    editBox:SetFocus()
    editBox:HighlightText()
end

local selectAllButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
selectAllButton:SetWidth(120)
selectAllButton:SetHeight(24)
selectAllButton:SetPoint("BOTTOMLEFT", 16, 18)
selectAllButton:SetText("Select All")
selectAllButton:SetScript("OnClick", function()
    editBox:SetFocus()
    editBox:HighlightText()
end)

local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
refreshButton:SetWidth(100)
refreshButton:SetHeight(24)
refreshButton:SetPoint("BOTTOM", 0, 18)
refreshButton:SetText("Refresh")
refreshButton:SetScript("OnClick", function()
    refresh()
end)

local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
closeButton:SetWidth(100)
closeButton:SetHeight(24)
closeButton:SetPoint("BOTTOMRIGHT", -16, 18)
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function()
    frame:Hide()
end)

frame:SetScript("OnShow", function()
    refresh()
    print("|cff33ff99JRawr Character Exporter|r: select all, press Ctrl+C, then paste into JRawr's Import tab.")
end)

-- /jrawr debug (or /jrce debug) prints what the client reports for each glyph socket and whether
-- the link or spell name is in the generated Rawr table. Useful when glyphs do not import.
local function printGlyphDebug()
    local group = GetActiveTalentGroup and GetActiveTalentGroup() or nil
    local sockets = (GetNumGlyphSockets and GetNumGlyphSockets()) or NUM_GLYPH_SLOTS or 6
    local info = DATA and DATA[select(2, UnitClass("player"))]
    print("|cff33ff99JRawr Character Exporter|r: glyph debug, talent group " .. tostring(group)
        .. ", " .. sockets .. " sockets")
    for socket = 1, sockets do
        local enabled, glyphType, glyphSpellID
        if GetGlyphSocketInfo then
            enabled, glyphType, glyphSpellID = GetGlyphSocketInfo(socket, group)
        end
        local link = GetGlyphLink and GetGlyphLink(socket, group) or ""
        if type(link) ~= "string" then link = "" end
        local name = link ~= "" and string.match(link, "%[(.-)%]") or nil
        if not name and glyphSpellID and GetSpellInfo then
            name = select(1, GetSpellInfo(glyphSpellID))
        end
        local matched = name and info and info.glyphs[string.lower(name)] ~= nil
        print(string.format("  %d: enabled=%s type=%s spell=%s name=%s match=%s",
            socket, tostring(enabled), tostring(glyphType), tostring(glyphSpellID),
            name and ("[" .. name .. "]") or "<empty>", tostring(matched)))
    end
end

SLASH_JRAWRCHARACTEREXPORTER1 = "/jrawr"
SLASH_JRAWRCHARACTEREXPORTER2 = "/jrce"
SlashCmdList["JRAWRCHARACTEREXPORTER"] = function(message)
    if message and string.lower(message):match("^%s*debug") then
        printGlyphDebug()
        return
    end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
