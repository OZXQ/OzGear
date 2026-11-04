OzGear = OzGear or {}
OzGear.Glow = OzGear.Glow or {}

local Glow = OzGear.Glow
local Data = OzGear.Data

-- Reusable texture allocation on button frame to prevent memory leaks in Lua 5.0
local function get_or_create_border(button)
    local border = button.ozgear_glow
    if not border then
        local cfg = Data and Data.GLOW_CONFIG
        border = button:CreateTexture(nil, "OVERLAY")
        border:SetTexture(cfg and cfg.texture or "Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode(cfg and cfg.blend_mode or "ADD")
        border:SetAlpha(cfg and cfg.alpha or 0.8)
        border:SetWidth(cfg and cfg.width or 70)
        border:SetHeight(cfg and cfg.height or 70)
        border:SetPoint("CENTER", button, "CENTER", 0, 0)
        button.ozgear_glow = border
        button.bc = border
    end
    return border
end

local function get_color(quality)
    if Data and Data.DURABILITY_COLORS and Data.DURABILITY_COLORS[quality] then
        local dc = Data.DURABILITY_COLORS[quality]
        return dc[1], dc[2], dc[3]
    elseif quality == 6 then
        return 0.9, 0.8, 0.502
    end
    if type(quality) == "number" and GetItemQualityColor then
        local r, g, b = GetItemQualityColor(quality)
        if r and g and b then
            return r, g, b
        end
    end
    local fallback = Data and Data.QUALITY_COLORS and Data.QUALITY_COLORS[quality]
    if fallback then
        return fallback[1], fallback[2], fallback[3]
    end
    return 1.0, 1.0, 1.0
end

local function get_character_quality(slot_id, alert_idx)
    local q = GetInventoryItemQuality and GetInventoryItemQuality("player", slot_id)
    if q == nil or q < 0 then
        local link = GetInventoryItemLink("player", slot_id)
        if link then
            local _, _, hex = string.find(link, "|cff(%x%x%x%x%x%x)|")
            if hex and Data and Data.HEX_TO_QUALITY and Data.HEX_TO_QUALITY[hex] then
                q = Data.HEX_TO_QUALITY[hex]
            end
        end
    end

    if q ~= nil then
        local cfg = OzGearDB and OzGearDB.glow
        local show_dura = (not cfg) or (cfg.show_durability ~= false)
        if show_dura then
            local broken_code = Data and Data.DURABILITY_BROKEN or 100
            local warning_code = Data and Data.DURABILITY_WARNING or 99
            if GetInventoryItemBroken and GetInventoryItemBroken("player", slot_id) then
                return broken_code
            elseif alert_idx and GetInventoryAlertStatus and GetInventoryAlertStatus(alert_idx) == 3 then
                return warning_code
            end
        end
    end

    return q
end

local function get_inspect_quality(unit, slot_id)
    local link = GetInventoryItemLink(unit, slot_id)
    if link then
        local _, _, hex = string.find(link, "|cff(%x%x%x%x%x%x)|")
        if hex and Data and Data.HEX_TO_QUALITY and Data.HEX_TO_QUALITY[hex] then
            return Data.HEX_TO_QUALITY[hex]
        end
    end

    local q = GetInventoryItemQuality and GetInventoryItemQuality(unit, slot_id)
    return q
end

function Glow:apply_border(button, quality)
    if not button then return end

    local cfg = OzGearDB and OzGearDB.glow
    local is_enabled = (not cfg) or (cfg.enabled ~= false)
    if not is_enabled or quality == nil then
        if button.ozgear_glow then
            button.ozgear_glow:Hide()
        end
        return
    end

    local threshold = (cfg and cfg.threshold) or 2
    local should_show = false

    -- Durability alerts bypass regular threshold filter
    if quality >= 99 then
        should_show = (not cfg) or (cfg.show_durability ~= false)
    elseif quality >= threshold then
        should_show = true
    end

    if should_show then
        local r, g, b = get_color(quality)
        if r and g and b then
            local border = get_or_create_border(button)
            border:SetVertexColor(r, g, b)
            border:Show()
            return
        end
    end

    if button.ozgear_glow then
        button.ozgear_glow:Hide()
    end
end

function Glow:update_all_character()
    if not CharacterFrame or not CharacterFrame:IsShown() then return end
    local char_slots = Data and Data.CHARACTER_SLOTS
    if not char_slots then return end

    for slot_id = 0, 19 do
        local slot_info = char_slots[slot_id]
        if slot_info then
            local btn = getglobal(slot_info.name)
            if btn then
                local q = get_character_quality(slot_id, slot_info.alert)
                self:apply_border(btn, q)
            end
        end
    end
end

function Glow:clear_all_character()
    local char_slots = Data and Data.CHARACTER_SLOTS
    if not char_slots then return end

    for slot_id = 0, 19 do
        local slot_info = char_slots[slot_id]
        if slot_info then
            local btn = getglobal(slot_info.name)
            if btn and btn.ozgear_glow then
                btn.ozgear_glow:Hide()
            end
        end
    end
end

function Glow:update_all_inspect()
    if not InspectFrame or not InspectFrame:IsShown() then return end
    local unit = InspectFrame.unit
    if not unit then return end
    local insp_slots = Data and Data.INSPECT_SLOTS
    if not insp_slots then return end

    for slot_id = 1, 19 do
        local slot_name = insp_slots[slot_id]
        if slot_name then
            local btn = getglobal(slot_name)
            if btn then
                local q = get_inspect_quality(unit, slot_id)
                self:apply_border(btn, q)
            end
        end
    end
end

function Glow:clear_all_inspect()
    local insp_slots = Data and Data.INSPECT_SLOTS
    if not insp_slots then return end

    for slot_id = 1, 19 do
        local slot_name = insp_slots[slot_id]
        if slot_name then
            local btn = getglobal(slot_name)
            if btn and btn.ozgear_glow then
                btn.ozgear_glow:Hide()
            end
        end
    end
end

-- InspectFrame is load-on-demand; hook once available
local inspect_hook = CreateFrame("Frame", "OzGearInspectGlowHook", UIParent)
local inspect_hooked = false

local function try_hook_inspect_ui()
    if inspect_hooked then return end
    if not InspectFrame then return end

    inspect_hook:SetParent(InspectFrame)
    inspect_hook:SetScript("OnShow", function()
        Glow:update_all_inspect()
    end)
    inspect_hook:SetScript("OnHide", function()
        Glow:clear_all_inspect()
    end)
    inspect_hook:SetScript("OnEvent", function()
        if event == "PLAYER_TARGET_CHANGED" then
            if InspectFrame:IsShown() then
                Glow:update_all_inspect()
            end
        elseif event == "UNIT_INVENTORY_CHANGED" then
            if InspectFrame:IsShown() and arg1 == InspectFrame.unit then
                Glow:update_all_inspect()
            end
        end
    end)
    inspect_hook:RegisterEvent("PLAYER_TARGET_CHANGED")
    inspect_hook:RegisterEvent("UNIT_INVENTORY_CHANGED")

    if InspectPaperDollFrame then
        local ipd_hook = CreateFrame("Frame", "OzGearInspectPDGlowHook", InspectPaperDollFrame)
        ipd_hook:SetScript("OnShow", function()
            Glow:update_all_inspect()
        end)
    end

    inspect_hooked = true
end

-- Child frame inherits CharacterFrame visibility: OnShow fires whenever CharacterFrame opens
local char_hook = CreateFrame("Frame", "OzGearCharGlowHook", CharacterFrame)
char_hook:SetScript("OnShow", function()
    Glow:update_all_character()
end)
char_hook:SetScript("OnEvent", function()
    if event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        Glow:update_all_character()
    elseif event == "UPDATE_INVENTORY_ALERTS" then
        Glow:update_all_character()
    end
end)
char_hook:RegisterEvent("UNIT_INVENTORY_CHANGED")
char_hook:RegisterEvent("UPDATE_INVENTORY_ALERTS")

-- PaperDollFrame child hook to catch tab switches back from Reputation/Skills/Honor tabs
if PaperDollFrame then
    local pd_hook = CreateFrame("Frame", "OzGearPaperDollGlowHook", PaperDollFrame)
    pd_hook:SetScript("OnShow", function()
        Glow:update_all_character()
    end)
end

-- Top-level listener for world entry and Load-On-Demand addon inspection
local main_event_frame = CreateFrame("Frame", "OzGearGlowMainFrame", UIParent)
main_event_frame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        try_hook_inspect_ui()
        if CharacterFrame and CharacterFrame:IsShown() then
            Glow:update_all_character()
        end
    elseif event == "ADDON_LOADED" then
        if arg1 == "Blizzard_InspectUI" then
            try_hook_inspect_ui()
        end
    end
end)

main_event_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
main_event_frame:RegisterEvent("ADDON_LOADED")
