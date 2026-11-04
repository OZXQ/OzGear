--[[
  GBDSwitcher v0.1 - Architecture Refactor
  SOLID, DRY, KISS principles applied.
]]--

local VERSION = "0.1"

-- ============================================================================
-- Namespaces
-- ============================================================================
GBDS = {}
GBDS.DB = {}
GBDS.Gear = {}
GBDS.Bars = {}
GBDS.UI = {}
GBDS.Event = {}
GBDS.Slash = {}

GBDS.CONST = {
    MAX_ACTIONS = 144,
    MAX_INV_SLOT = 19,
    MAX_SPECS = 10,
    MAX_GBD = 4,
}

local C = {
    T = "|cff00FF96",  -- title green
    I = "|cffAAD4FF",  -- info blue
    W = "|cffFFCC00",  -- warning yellow
    E = "|cffFF4444",  -- error red
    O = "|cff55FF55",  -- ok green
    S = "|cffFFAA00",  -- spec orange
    R = "|r",
}

-- Print Utils
GBDS.msg = function(text) DEFAULT_CHAT_FRAME:AddMessage(C.T.."[GBDS]"..C.R.." "..text) end
GBDS.dbg = function(text) if GBDS.DB.Get().debug then DEFAULT_CHAT_FRAME:AddMessage(C.T.."[GBDS-DBG]"..C.R.." "..text) end end
GBDS.tcount = function(t) local c = 0; if t then for _ in pairs(t) do c = c + 1 end end; return c; end

-- ============================================================================
-- Localization
-- ============================================================================
local L = {}
local locale = GetLocale()
if locale == "zhCN" then
    L.TITLE       = "GBDSwitcher v"..VERSION.." - 切换器"
    L.DELAY       = "延迟:"
    L.ENABLED     = "启用"
    L.CLOSE       = "关闭"
    L.EMPTY       = "(空)"
    L.GEAR_SAVED  = "槽位 %d 装备已保存 (%d 件)"
    L.BARS_SAVED  = "槽位 %d 按键已保存 (%d 个)"
    L.GEAR_LOAD   = "正在加载装备槽位 %d..."
    L.BARS_LOAD   = "将在 %ds 后加载按键 %d..."
    L.BARS_DONE   = "槽位 %d 按键已加载"
    L.SPEC_DETECT = "检测到 GBD 天赋 %d"
    L.NO_DATA     = "槽位 %d 没有保存数据"
    L.STATUS_FMT  = "G:%d B:%d"

    L.GBD_NAME    = "地精洗脑装置"
    L.GBD_SAVE    = "保存"
    L.GBD_SPEC    = "^启用第(%d)天赋"
else
    L.TITLE       = "GBDSwitcher v"..VERSION
    L.DELAY       = "Delay:"
    L.ENABLED     = "Enabled"
    L.CLOSE       = "Close"
    L.EMPTY       = "(empty)"
    L.GEAR_SAVED  = "Slot %d gear saved (%d items)"
    L.BARS_SAVED  = "Slot %d bars saved (%d actions)"
    L.GEAR_LOAD   = "Loading slot %d gear..."
    L.BARS_LOAD   = "Loading slot %d bars in %ds..."
    L.BARS_DONE   = "Slot %d bars loaded"
    L.SPEC_DETECT = "GBD Spec %d detected"
    L.NO_DATA     = "Slot %d has no saved data"
    L.STATUS_FMT  = "G:%d B:%d"

    L.GBD_NAME    = "Goblin Brainwashing Device"
    L.GBD_SAVE    = "Save"
    L.GBD_SPEC    = "Activate (%d+).. Specialization"
end

-- ============================================================================
-- GBDS.DB : Data Management
-- ============================================================================
local activeDB = nil

function GBDS.DB.Init()
    if not GBDSwitcher_DB then GBDSwitcher_DB = {} end
    activeDB = GBDSwitcher_DB

    -- Apply Defaults
    if activeDB.specs == nil then activeDB.specs = {} end
    if activeDB.delay == nil then activeDB.delay = 2 end
    if activeDB.enabled == nil then activeDB.enabled = true end
    if activeDB.debug == nil then activeDB.debug = false end
end

function GBDS.DB.Get()
    return activeDB
end

function GBDS.DB.GetSpec(n)
    if not activeDB or not activeDB.specs then return nil end
    return activeDB.specs[n]
end

function GBDS.DB.EnsureSpec(n)
    if not activeDB.specs[n] then
        activeDB.specs[n] = { name = (n <= GBDS.CONST.MAX_GBD and "Spec "..n or "Custom "..n), gear = {}, bars = {} }
    end
    return activeDB.specs[n]
end

function GBDS.DB.SaveCustomName(n)
    if not n or n <= GBDS.CONST.MAX_GBD then return end
    local spec = GBDS.DB.EnsureSpec(n)
    local editBox = getglobal("GBDS_Row"..n.."Name")
    if editBox then
        local newName = editBox:GetText()
        if newName and newName ~= "" then
            spec.name = newName
        else
            spec.name = "Custom "..n
            editBox:SetText(spec.name)
        end
        -- Update only the status text, avoid full Refresh which resets EditBox
        local st = getglobal("GBDS_Row"..n.."Status")
        if st then
            local gearCount = GBDS.tcount(spec.gear)
            local barsCount = GBDS.tcount(spec.bars)
            if gearCount > 0 or barsCount > 0 then
                st:SetText(string.format(L.STATUS_FMT, gearCount, barsCount))
                st:SetTextColor(0.5, 1, 0.5)
            else
                st:SetText(L.EMPTY); st:SetTextColor(0.5, 0.5, 0.5)
            end
        end
    end
end

-- ============================================================================
-- GBDS.Gear : Inventory Operations
-- ============================================================================
function GBDS.Gear.Save(specNum)
    if not activeDB then return end
    local spec = GBDS.DB.EnsureSpec(specNum)
    spec.gear = {}
    local count = 0

    for slot = 0, GBDS.CONST.MAX_INV_SLOT do
        local link = GetInventoryItemLink("player", slot)
        if link then
            spec.gear[slot] = link
            count = count + 1
        end
    end

    GBDS.msg(C.O..string.format(L.GEAR_SAVED, specNum, count)..C.R)
    GBDS.UI.Refresh()
end

local function findItemInBags(targetLink)
    local _, _, targetName = string.find(targetLink, "%[(.-)%]")
    if not targetName then return nil, nil end

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local bagLink = GetContainerItemLink(bag, slot)
            if bagLink then
                local _, _, bagName = string.find(bagLink, "%[(.-)%]")
                if bagName and bagName == targetName then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

local function isItemEquipped(slot, targetLink)
    local currentLink = GetInventoryItemLink("player", slot)
    if not currentLink or not targetLink then return false end
    local _, _, curName = string.find(currentLink, "%[(.-)%]")
    local _, _, tarName = string.find(targetLink, "%[(.-)%]")
    return curName and tarName and curName == tarName
end

function GBDS.Gear.Load(specNum)
    local spec = GBDS.DB.GetSpec(specNum)
    if not spec or not spec.gear or GBDS.tcount(spec.gear) == 0 then
        GBDS.msg(C.W.."Slot "..specNum.." has no gear saved."..C.R)
        return
    end

    GBDS.msg(C.I..string.format(L.GEAR_LOAD, specNum)..C.R)

    for slot = 0, GBDS.CONST.MAX_INV_SLOT do
        local targetLink = spec.gear[slot]
        if targetLink and not isItemEquipped(slot, targetLink) then
            local bag, bagSlot = findItemInBags(targetLink)
            if bag and bagSlot then
                PickupContainerItem(bag, bagSlot)
                PickupInventoryItem(slot)
                GBDS.dbg("Swapped slot "..slot..": found in bag "..bag.." slot "..bagSlot)
            end
        end
    end
end

-- ============================================================================
-- GBDS.Bars : Action Bar Operations
-- ============================================================================
function GBDS.Bars.Save(specNum)
    if not activeDB then return end
    local spec = GBDS.DB.EnsureSpec(specNum)
    spec.bars = {}
    local count = 0

    GBDS_Tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    local scStatus = GetCVar("autoSelfCast")
    SetCVar("autoSelfCast", 0)

    for i = 1, GBDS.CONST.MAX_ACTIONS do
        if HasAction(i) then
            local macroName = GetActionText(i)
            if macroName then
                spec.bars[i] = { macro = macroName }
                count = count + 1
            else
                GBDS_Tooltip:ClearLines()
                GBDS_Tooltip:SetAction(i)

                PickupAction(i)
                local isSpell = CursorHasSpell()
                PlaceAction(i)

                if isSpell then
                    local spellName, rank
                    if GBDS_TooltipTextLeft1:IsShown() then spellName = GBDS_TooltipTextLeft1:GetText() end
                    if GBDS_TooltipTextRight1:IsShown() then rank = GBDS_TooltipTextRight1:GetText() end
                    spec.bars[i] = { spell = spellName, rank = rank }
                    count = count + 1
                else
                    local itemName
                    if GBDS_TooltipTextLeft1:IsShown() then itemName = GBDS_TooltipTextLeft1:GetText() end
                    spec.bars[i] = { item = itemName }
                    count = count + 1
                end
            end
        end
    end

    SetCVar("autoSelfCast", scStatus)
    GBDS.msg(C.O..string.format(L.BARS_SAVED, specNum, count)..C.R)
    GBDS.UI.Refresh()
end

local function buildLookups()
    local spellIds = {}
    for tab = 1, MAX_SKILLLINE_TABS do
        local name, _, offset, numSpells = GetSpellTabInfo(tab)
        if not name then break end
        for s = offset + 1, offset + numSpells do
            local spellName, spellRank = GetSpellName(s, BOOKTYPE_SPELL)
            if spellRank and spellRank ~= "" then
                spellIds[spellName.." "..spellRank] = s
            end
            spellIds[spellName] = s  -- fallback
        end
    end

    local equipped = {}
    for i = 1, GBDS.CONST.MAX_INV_SLOT do
        GBDS_Tooltip:ClearLines()
        if GBDS_Tooltip:SetInventoryItem("player", i) and GBDS_TooltipTextLeft1:IsShown() then
            equipped[GBDS_TooltipTextLeft1:GetText()] = i
        end
    end

    local bags = {}
    for i = 0, NUM_BAG_SLOTS do
        for j = 1, GetContainerNumSlots(i) do
            if GetContainerItemInfo(i, j) then
                GBDS_Tooltip:ClearLines()
                GBDS_Tooltip:SetBagItem(i, j)
                if GBDS_TooltipTextLeft1:IsShown() then
                    bags[GBDS_TooltipTextLeft1:GetText()] = { bag = i, slot = j }
                end
            end
        end
    end

    return spellIds, equipped, bags
end

function GBDS.Bars.Load(specNum)
    local spec = GBDS.DB.GetSpec(specNum)
    if not spec or not spec.bars or GBDS.tcount(spec.bars) == 0 then
        GBDS.msg(C.W.."Slot "..specNum.." has no bars saved."..C.R)
        return
    end

    local scStatus = GetCVar("autoSelfCast")
    SetCVar("autoSelfCast", 0)
    GBDS_Tooltip:SetOwner(UIParent, "ANCHOR_NONE")

    local spellIds, equipped, bagItems = buildLookups()

    for i = 1, GBDS.CONST.MAX_ACTIONS do
        local entry = spec.bars[i]
        if entry then
            if entry.spell then
                local key = entry.spell .. (entry.rank and (" "..entry.rank) or "")
                local spellID = spellIds[key] or spellIds[entry.spell]
                if spellID then
                    PickupSpell(spellID, BOOKTYPE_SPELL); PlaceAction(i)
                else
                    PickupAction(i); ClearCursor()
                end
            elseif entry.item then
                if equipped[entry.item] then
                    PickupInventoryItem(equipped[entry.item]); PlaceAction(i)
                elseif bagItems[entry.item] then
                    PickupContainerItem(bagItems[entry.item].bag, bagItems[entry.item].slot); PlaceAction(i)
                end
            elseif entry.macro then
                local macroIdx = GetMacroIndexByName(entry.macro)
                if macroIdx and macroIdx > 0 then
                    PickupMacro(macroIdx); PlaceAction(i)
                end
            else
                PickupAction(i); ClearCursor()
            end
        else
            PickupAction(i); ClearCursor()
        end
        ClearCursor()
    end

    SetCVar("autoSelfCast", scStatus)
    GBDS.msg(C.O..string.format(L.BARS_DONE, specNum)..C.R)
end

-- ============================================================================
-- GBDS.Event : Listeners, Hooks & Timers
-- ============================================================================
local pendingSpec = nil
local pendingTime = 0

local timerFrame = CreateFrame("Frame", "GBDS_TimerFrame", UIParent)
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function()
    pendingTime = pendingTime - arg1
    if pendingTime <= 0 then
        timerFrame:Hide()
        if pendingSpec then
            GBDS.Bars.Load(pendingSpec)
            pendingSpec = nil
        end
    end
end)

function GBDS.Event.TriggerAutoSwitch(specNum)
    if not activeDB or not activeDB.enabled then return end

    local spec = GBDS.DB.GetSpec(specNum)
    if not spec then
        GBDS.msg(C.W..string.format(L.NO_DATA, specNum)..C.R)
        return
    end

    GBDS.msg(C.I..string.format(L.SPEC_DETECT, specNum)..C.R)

    -- 1. Load gear immediately
    if GBDS.tcount(spec.gear) > 0 then GBDS.Gear.Load(specNum) end

    -- 2. Schedule bars loading
    if GBDS.tcount(spec.bars) > 0 then
        local delay = activeDB.delay or 2
        GBDS.msg(C.I..string.format(L.BARS_LOAD, delay, specNum)..C.R)
        pendingSpec = specNum
        pendingTime = delay
        timerFrame:Show()
    end
end

local function HookGBD()
    local origGossipClick = GossipTitleButton_OnClick
    GossipTitleButton_OnClick = function()
        if origGossipClick then origGossipClick() end

        if not activeDB or not activeDB.enabled then return end
        if not this or this.type == "Available" or this.type == "Active" then return end

        if GossipFrameNpcNameText:GetText() ~= L.GBD_NAME then return end
        local actionText = this:GetText()
        if not actionText or string.find(actionText, L.GBD_SAVE, 1, true) then return end

        local _, _, specNum = string.find(actionText, L.GBD_SPEC)

        if not specNum then
            local name = UnitName("player")
            if GNS_SpecNames and GNS_SpecNames[name] then
                local _, _, specName = string.find(actionText, "^Activate%s*(.+) %([%d/]+%)$")
                if specName then
                    for i = 1, GBDS.CONST.MAX_GBD do
                        if specName == GNS_SpecNames[name][i] then
                            specNum = i; break
                        end
                    end
                end
            end
        end

        if specNum then
            specNum = tonumber(specNum)
            GBDS.dbg("GBD Spec Hooked: "..tostring(specNum))
            GBDS.Event.TriggerAutoSwitch(specNum)
        end
    end
end

-- ============================================================================
-- GBDS.UI : Dynamic GUI Generation & Update
-- ============================================================================
function GBDS.UI.InitRows()
    local parent = getglobal("GBDSwitcher_ListPanel")
    local yOffset = 0

    for i = 1, GBDS.CONST.MAX_SPECS do
        -- Section Headers
        if i == 1 then
            local t1 = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            t1:SetPoint("TOPLEFT", 10, yOffset)
            t1:SetText("-- GBD Auto-Switch --"); t1:SetTextColor(1, 0.82, 0)
            yOffset = yOffset - 25
        elseif i == 5 then
            local sep = parent:CreateTexture(nil, "ARTWORK")
            sep:SetTexture(0.5, 0.5, 0.5, 0.7); sep:SetWidth(330); sep:SetHeight(1)
            sep:SetPoint("TOPLEFT", 10, yOffset - 5)
            yOffset = yOffset - 15

            local t2 = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            t2:SetPoint("TOPLEFT", 10, yOffset)
            t2:SetText("-- Custom Profiles --"); t2:SetTextColor(0.6, 0.8, 1)
            yOffset = yOffset - 25
        end

        local row = CreateFrame("Frame", "GBDS_Row"..i, parent)
        row:SetWidth(330); row:SetHeight(26)
        row:SetPoint("TOPLEFT", 10, yOffset)

        -- Row Background
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetTexture(1, 1, 1, 0.05)

        -- Status Text
        local st = row:CreateFontString("GBDS_Row"..i.."Status", "ARTWORK", "GameFontHighlightSmall")
        st:SetWidth(80); st:SetHeight(16)
        st:SetPoint("LEFT", 110, 0)
        st:SetTextColor(0.5, 0.5, 0.5)

        if i <= GBDS.CONST.MAX_GBD then
            -- Label
            local lb = row:CreateFontString("GBDS_Row"..i.."Label", "ARTWORK", "GameFontHighlight")
            lb:SetWidth(80); lb:SetHeight(20)
            lb:SetPoint("LEFT", 8, 0)
            lb:SetText("Spec "..i)

            -- Buttons
            local btnSG = CreateFrame("Button", "GBDS_Row"..i.."SaveGear", row, "UIPanelButtonTemplate")
            btnSG:SetWidth(45); btnSG:SetHeight(18); btnSG:SetPoint("LEFT", 220, 0)
            btnSG.id = i
            btnSG:SetText("Save G"); btnSG:SetScript("OnClick", function() GBDS.Gear.Save(this.id) end)

            local btnSB = CreateFrame("Button", "GBDS_Row"..i.."SaveBars", row, "UIPanelButtonTemplate")
            btnSB:SetWidth(45); btnSB:SetHeight(18); btnSB:SetPoint("LEFT", btnSG, "RIGHT", 4, 0)
            btnSB.id = i
            btnSB:SetText("Save B"); btnSB:SetScript("OnClick", function() GBDS.Bars.Save(this.id) end)
        else
            -- EditBox using standard InputBoxTemplate to natively handle clicks correctly
            local eb = CreateFrame("EditBox", "GBDS_Row"..i.."Name", row, "InputBoxTemplate")
            eb:SetWidth(80); eb:SetHeight(16)
            eb:SetPoint("LEFT", 12, 0)
            eb:SetAutoFocus(false)
            eb.specId = i
            eb:SetScript("OnEscapePressed", function()
                -- Revert to saved name on Escape
                local spec = GBDS.DB.GetSpec(this.specId)
                this:SetText(spec and spec.name or "Custom "..this.specId)
                this:ClearFocus()
            end)
            eb:SetScript("OnEnterPressed", function()
                GBDS.DB.SaveCustomName(this.specId)
                this:ClearFocus()
            end)
            eb:SetScript("OnEditFocusLost", function()
                -- Auto-save when clicking away
                GBDS.DB.SaveCustomName(this.specId)
            end)
            
            -- Tooltip hint for saving custom names
            eb:SetScript("OnEnter", function() 
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText("Type name, press Enter or click away to save")
                GameTooltip:Show()
            end)
            eb:SetScript("OnLeave", function() GameTooltip:Hide() end)

            -- Condensed Buttons
            local btnSG = CreateFrame("Button", "GBDS_Row"..i.."SaveGear", row, "UIPanelButtonTemplate")
            btnSG:SetWidth(28); btnSG:SetHeight(18); btnSG:SetPoint("LEFT", 195, 0)
            btnSG.id = i
            btnSG:SetText("G"); btnSG:SetScript("OnClick", function() GBDS.Gear.Save(this.id) end)

            local btnSB = CreateFrame("Button", "GBDS_Row"..i.."SaveBars", row, "UIPanelButtonTemplate")
            btnSB:SetWidth(28); btnSB:SetHeight(18); btnSB:SetPoint("LEFT", btnSG, "RIGHT", 2, 0)
            btnSB.id = i
            btnSB:SetText("B"); btnSB:SetScript("OnClick", function() GBDS.Bars.Save(this.id) end)

            local btnLG = CreateFrame("Button", "GBDS_Row"..i.."LoadGear", row, "UIPanelButtonTemplate")
            btnLG:SetWidth(28); btnLG:SetHeight(18); btnLG:SetPoint("LEFT", btnSB, "RIGHT", 8, 0)
            btnLG.id = i
            btnLG:SetText("LG"); btnLG:SetScript("OnClick", function() GBDS.Gear.Load(this.id) end)

            local btnLB = CreateFrame("Button", "GBDS_Row"..i.."LoadBars", row, "UIPanelButtonTemplate")
            btnLB:SetWidth(28); btnLB:SetHeight(18); btnLB:SetPoint("LEFT", btnLG, "RIGHT", 2, 0)
            btnLB.id = i
            btnLB:SetText("LB"); btnLB:SetScript("OnClick", function() GBDS.Bars.Load(this.id) end)
        end

        yOffset = yOffset - 28
    end
end

function GBDS.UI.Refresh()
    if not activeDB then return end

    GBDS_Title:SetText(L.TITLE)
    GBDS_DelayLabel:SetText(L.DELAY)
    GBDS_CloseBtn:SetText(L.CLOSE)

    GBDS_DelaySlider:SetValue(activeDB.delay)
    GBDS_DelayValue:SetText(string.format("%.1fs", activeDB.delay))
    
    GBDS_EnableCheck:SetChecked(activeDB.enabled)
    if GBDS_EnableCheckText then GBDS_EnableCheckText:SetText(L.ENABLED) end

    for i = 1, GBDS.CONST.MAX_SPECS do
        local spec = GBDS.DB.GetSpec(i)
        
        -- Sync Names
        if i > GBDS.CONST.MAX_GBD then
            local eb = getglobal("GBDS_Row"..i.."Name")
            if eb then eb:SetText(spec and spec.name or "Custom "..i) end
        end

        -- Sync Status
        local st = getglobal("GBDS_Row"..i.."Status")
        if st then
            if spec then
                local gearCount = GBDS.tcount(spec.gear)
                local barsCount = GBDS.tcount(spec.bars)
                if gearCount > 0 or barsCount > 0 then
                    st:SetText(string.format(L.STATUS_FMT, gearCount, barsCount))
                    st:SetTextColor(0.5, 1, 0.5)
                else
                    st:SetText(L.EMPTY); st:SetTextColor(0.5, 0.5, 0.5)
                end
            else
                st:SetText(L.EMPTY); st:SetTextColor(0.5, 0.5, 0.5)
            end
        end
    end
end

function GBDS.UI.OnDelayChanged()
    if not activeDB then return end
    local val = math.floor(GBDS_DelaySlider:GetValue() * 2 + 0.5) / 2
    activeDB.delay = val
    GBDS_DelayValue:SetText(string.format("%.1fs", val))
end

function GBDS.UI.OnEnableToggle()
    if not activeDB then return end
    activeDB.enabled = (GBDS_EnableCheck:GetChecked() and true or false)
end

function GBDS.UI.ToggleConfig()
    if GBDSwitcher_ConfigFrame:IsVisible() then
        GBDSwitcher_ConfigFrame:Hide()
    else
        GBDSwitcher_ConfigFrame:Show()
    end
end

-- ============================================================================
-- GBDS.Slash : Commands
-- ============================================================================
function GBDS.Slash.Handle(input)
    if not activeDB then return end
    if not input or input == "" then GBDS.UI.ToggleConfig(); return end

    local _, _, cmd, rest = string.find(input, "^(%S+)%s*(.*)")
    cmd = string.lower(cmd or "")

    local n = tonumber(rest)
    if cmd == "save" and n then GBDS.Gear.Save(n); GBDS.Bars.Save(n)
    elseif cmd == "savegear" and n then GBDS.Gear.Save(n)
    elseif cmd == "savebars" and n then GBDS.Bars.Save(n)
    elseif cmd == "load" and n then
        if n <= GBDS.CONST.MAX_GBD then GBDS.Event.TriggerAutoSwitch(n)
        else GBDS.Gear.Load(n); GBDS.Bars.Load(n) end
    elseif cmd == "delay" and n then activeDB.delay = n; GBDS.msg(C.O.."Delay set to "..n.."s"..C.R)
    elseif cmd == "toggle" then activeDB.enabled = not activeDB.enabled; GBDS.msg((activeDB.enabled and C.O.."ENABLED" or C.E.."DISABLED")..C.R)
    elseif cmd == "debug" then activeDB.debug = not activeDB.debug; GBDS.msg((activeDB.debug and C.O.."DEBUG ON" or C.I.."DEBUG OFF")..C.R)
    elseif cmd == "list" then
        for i = 1, GBDS.CONST.MAX_SPECS do
            local sp = GBDS.DB.GetSpec(i)
            if sp then
                local lab = i <= GBDS.CONST.MAX_GBD and ("Spec "..i) or (sp.name or "Custom "..i)
                GBDS.msg("  "..C.S..i..C.R.." ["..lab.."] "..C.I.."Gear:"..GBDS.tcount(sp.gear).." Bars:"..GBDS.tcount(sp.bars)..C.R)
            else
                GBDS.msg("  "..C.S..i..C.R.." "..C.W..L.EMPTY..C.R)
            end
        end
    else
        GBDS.msg(C.I.."/gbds save <1-10> | load <1-10> | savegear | savebars | delay | toggle | debug | list"..C.R)
    end
end

-- ============================================================================
-- Main Init
-- ============================================================================
local mainEventFrame = CreateFrame("Frame")
mainEventFrame:RegisterEvent("VARIABLES_LOADED")
mainEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
local initialized = false

mainEventFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        GBDS.DB.Init()
        GBDS.UI.InitRows()

        SlashCmdList["GBDSWITCHER"] = GBDS.Slash.Handle
        SLASH_GBDSWITCHER1 = "/gbds"
        table.insert(UISpecialFrames, "GBDSwitcher_ConfigFrame")

    elseif event == "PLAYER_ENTERING_WORLD" and not initialized then
        initialized = true
        HookGBD()
        GBDS.msg(C.I.."v"..VERSION.." loaded. "..C.W.."/gbds"..C.I.." for config."..C.R)
    end
end)
