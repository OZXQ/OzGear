OzGear = OzGear or {}
OzGear.StatsUI = OzGear.StatsUI or {}

local StatsUI = OzGear.StatsUI
local Scanner = OzGear.StatScanner
local Data = OzGear.Data

local LOCALE = GetLocale and GetLocale()
local L = {}
local function L_(k)
    return L[k] or k
end

if LOCALE == "zhCN" then
    L["iLvl"] = "装等"
    L["Avg iLvl"] = "平均装等"
    L["Primary Attributes"] = "基础属性"
    L["Physical & Ranged"] = "物理 / 远程"
    L["Spells & Healing"] = "法术与治疗"
    L["Defensive"] = "防御属性"
    L["Resistances"] = "抗性"
    L["Active Set Bonuses"] = "已激活套装效果"
    L["Strength"] = "力量"
    L["Agility"] = "敏捷"
    L["Stamina"] = "耐力"
    L["Intellect"] = "智力"
    L["Spirit"] = "精神"
    L["Armor"] = "护甲"
    L["Attack Power"] = "近战攻强"
    L["Ranged AP"] = "远程攻强"
    L["Critical Strike"] = "暴击几率"
    L["Ranged Crit"] = "远程暴击"
    L["Hit Chance"] = "物理命中"
    L["Spell Hit"] = "法术命中"
    L["Spell Damage"] = "法术伤害"
    L["Healing Power"] = "治疗效果"
    L["Spell Crit"] = "法术暴击"
    L["MP5"] = "5秒回蓝"
    L["HP5"] = "5秒回血"
    L["Defense Skill"] = "防御技能"
    L["Dodge"] = "躲闪几率"
    L["Parry"] = "招架几率"
    L["Block Chance"] = "格挡几率"
    L["Block Value"] = "格挡值"
    L["Haste"] = "急速"
    L["Armor Pen"] = "护甲穿透"
    L["Spell Pen"] = "法术穿透"
    L["Fire"] = "火焰"
    L["Nature"] = "自然"
    L["Frost"] = "冰霜"
    L["Shadow"] = "暗影"
    L["Arcane"] = "奥术"
    L["Querying..."] = "查询中..."
end

local char_badge = nil
local inspect_badge = nil
local inspect_ui_hooked = false

-- FontString created on demand and anchored to slot top-right corner
local function get_or_create_slot_text(slot_frame)
    if not slot_frame then return nil end
    if slot_frame.oz_ilvl then
        slot_frame.oz_ilvl:ClearAllPoints()
        slot_frame.oz_ilvl:SetPoint("TOPRIGHT", slot_frame, "TOPRIGHT", -2, -2)
        slot_frame.oz_ilvl:SetJustifyH("RIGHT")
        return slot_frame.oz_ilvl
    end

    local fs = slot_frame:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(GameFontHighlightSmall)
    fs:SetPoint("TOPRIGHT", slot_frame, "TOPRIGHT", -2, -2)
    fs:SetJustifyH("RIGHT")
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 1)
    slot_frame.oz_ilvl = fs
    return fs
end

-- Bottom-right badge on CharacterFrame anchored above the tabs; width is 2x slot icon size
local function create_char_badge()
    if char_badge then return char_badge end
    if not CharacterFrame then return nil end

    local parent = PaperDollFrame or CharacterFrame
    char_badge = CreateFrame("Button", "OzGearCharILvlBadge", parent)
    char_badge:SetWidth(60)
    char_badge:SetHeight(20)
    char_badge:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -38, 80)
    char_badge:SetFrameLevel(parent:GetFrameLevel() + 2)

    char_badge:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 12,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    char_badge:SetBackdropColor(0, 0, 0, 0.75)
    char_badge:SetBackdropBorderColor(0.8, 0.8, 0.8, 0.6)

    local txt = char_badge:CreateFontString("OzGearCharILvlBadgeText", "OVERLAY")
    txt:SetFontObject(GameFontNormalSmall)
    txt:SetPoint("CENTER", char_badge, "CENTER", 0, 0)
    char_badge.text = txt

    char_badge:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        StatsUI:render_stats_tooltip(GameTooltip, "player")
        GameTooltip:Show()
    end)

    char_badge:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return char_badge
end

-- Bottom-right badge on InspectFrame anchored above the tabs; width is 2x slot icon size
local function create_inspect_badge()
    if inspect_badge then return inspect_badge end
    if not InspectFrame then return nil end

    local parent = InspectPaperDollFrame or InspectFrame
    inspect_badge = CreateFrame("Button", "OzGearInspectILvlBadge", parent)
    inspect_badge:SetWidth(60)
    inspect_badge:SetHeight(20)
    inspect_badge:SetPoint("BOTTOMRIGHT", InspectFrame, "BOTTOMRIGHT", -38, 80)
    inspect_badge:SetFrameLevel(parent:GetFrameLevel() + 2)

    inspect_badge:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 12,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    inspect_badge:SetBackdropColor(0, 0, 0, 0.75)
    inspect_badge:SetBackdropBorderColor(0.8, 0.8, 0.8, 0.6)

    local txt = inspect_badge:CreateFontString("OzGearInspectILvlBadgeText", "OVERLAY")
    txt:SetFontObject(GameFontNormalSmall)
    txt:SetPoint("CENTER", inspect_badge, "CENTER", 0, 0)
    inspect_badge.text = txt

    inspect_badge:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        local unit = (InspectFrame and InspectFrame.unit) or "target"
        StatsUI:render_stats_tooltip(GameTooltip, unit)
        GameTooltip:Show()
    end)

    inspect_badge:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return inspect_badge
end

function StatsUI:render_stats_tooltip(tip, unit)
    if not tip or not Scanner then return end
    unit = unit or "player"

    local scan = Scanner:scan_unit(unit)
    if not scan then return end

    local unit_name = UnitName(unit) or (unit == "player" and "Player" or "Target")
    local unit_level = UnitLevel(unit) or 60

    tip:ClearLines()
    tip:AddDoubleLine(
        string.format("|cffffffff%s|r (Lv %d)", unit_name, unit_level),
        string.format("|cffffd100%s:|r |cffffffff%.1f|r", L_("Avg iLvl"), scan.avg_ilvl),
        1, 1, 1, 1, 0.82, 0
    )
    tip:AddLine(" ")

    local stats = scan.stats

    local stat_str = stats.STR or 0
    local stat_agi = stats.AGI or 0
    local stat_sta = stats.STA or 0
    local stat_int = stats.INT or 0
    local stat_spi = stats.SPI or 0
    local stat_arm = stats.ARMOR or 0
    if (stat_str + stat_agi + stat_sta + stat_int + stat_spi + stat_arm) > 0 then
        tip:AddLine("|cffffd100" .. L_("Primary Attributes") .. ":|r")
        if stat_str > 0 or stat_agi > 0 then
            tip:AddDoubleLine(
                stat_str > 0 and string.format("  %s: |cffffffff+%d|r", L_("Strength"), stat_str) or "",
                stat_agi > 0 and string.format("%s: |cffffffff+%d|r  ", L_("Agility"), stat_agi) or "",
                0.8, 0.8, 0.8, 0.8, 0.8, 0.8
            )
        end
        if stat_sta > 0 or stat_arm > 0 then
            tip:AddDoubleLine(
                stat_sta > 0 and string.format("  %s: |cffffffff+%d|r", L_("Stamina"), stat_sta) or "",
                stat_arm > 0 and string.format("%s: |cffffffff+%d|r  ", L_("Armor"), stat_arm) or "",
                0.8, 0.8, 0.8, 0.8, 0.8, 0.8
            )
        end
        if stat_int > 0 or stat_spi > 0 then
            tip:AddDoubleLine(
                stat_int > 0 and string.format("  %s: |cffffffff+%d|r", L_("Intellect"), stat_int) or "",
                stat_spi > 0 and string.format("%s: |cffffffff+%d|r  ", L_("Spirit"), stat_spi) or "",
                0.8, 0.8, 0.8, 0.8, 0.8, 0.8
            )
        end
    end

    local attack_power = stats.ATTACKPOWER or 0
    local ranged_ap = stats.RANGEDATTACKPOWER or 0
    local crit = stats.CRIT or 0
    local ranged_crit = stats.RANGEDCRIT or 0
    local hit = stats.TOHIT or 0
    local haste = stats.HASTE or 0
    local armor_pen = stats.ARMORPENETRATION or 0
    if (attack_power + ranged_ap + crit + ranged_crit + hit + haste + armor_pen) > 0 then
        tip:AddLine(" ")
        tip:AddLine("|cffffd100" .. L_("Physical & Ranged") .. ":|r")
        if attack_power > 0 or ranged_ap > 0 then
            tip:AddDoubleLine(
                attack_power > 0 and string.format("  %s: |cffffffff+%d|r", L_("Attack Power"), attack_power) or "",
                ranged_ap > 0 and string.format("%s: |cffffffff+%d|r  ", L_("Ranged AP"), ranged_ap) or "",
                0.8, 0.8, 0.8, 0.8, 0.8, 0.8
            )
        end
        if crit > 0 or ranged_crit > 0 then
            tip:AddDoubleLine(
                crit > 0 and string.format("  %s: |cffffffff+%d%%|r", L_("Critical Strike"), crit) or "",
                ranged_crit > 0 and string.format("%s: |cffffffff+%d%%|r  ", L_("Ranged Crit"), ranged_crit) or "",
                0.8, 0.8, 0.8, 0.8, 0.8, 0.8
            )
        end
        if hit > 0 or haste > 0 then
            tip:AddDoubleLine(
                hit > 0 and string.format("  %s: |cffffffff+%d%%|r", L_("Hit Chance"), hit) or "",
                haste > 0 and string.format("%s: |cffffffff+%d%%|r  ", L_("Haste"), haste) or "",
                0.8, 0.8, 0.8, 0.8, 0.8, 0.8
            )
        end
        if armor_pen > 0 then
            tip:AddLine(string.format("  %s: |cffffffff+%d|r", L_("Armor Pen"), armor_pen), 0.8, 0.8, 0.8)
        end
    end

    local spell_dmg = stats.DMG or 0
    local heal = stats.HEAL or 0
    local spell_crit = stats.SPELLCRIT or 0
    local spell_hit = stats.SPELLTOHIT or 0
    local mp5 = stats.MANAREG or 0
    local spell_pen = stats.SPELLPENETRATION or 0
    if (spell_dmg + heal + spell_crit + spell_hit + mp5 + spell_pen) > 0 then
        tip:AddLine(" ")
        tip:AddLine("|cffffd100" .. L_("Spells & Healing") .. ":|r")
        if spell_dmg > 0 or heal > 0 then
            tip:AddDoubleLine(
                spell_dmg > 0 and string.format("  %s: |cffffffff+%d|r", L_("Spell Damage"), spell_dmg) or "",
                heal > 0 and string.format("%s: |cffffffff+%d|r  ", L_("Healing Power"), heal) or "",
                0.8, 0.8, 0.8, 0.8, 0.8, 0.8
            )
        end
        if spell_crit > 0 or spell_hit > 0 then
            tip:AddDoubleLine(
                spell_crit > 0 and string.format("  %s: |cffffffff+%d%%|r", L_("Spell Crit"), spell_crit) or "",
                spell_hit > 0 and string.format("%s: |cffffffff+%d%%|r  ", L_("Spell Hit"), spell_hit) or "",
                0.8, 0.8, 0.8, 0.8, 0.8, 0.8
            )
        end
        if mp5 > 0 or spell_pen > 0 then
            tip:AddDoubleLine(
                mp5 > 0 and string.format("  %s: |cffffffff+%d|r", L_("MP5"), mp5) or "",
                spell_pen > 0 and string.format("%s: |cffffffff+%d|r  ", L_("Spell Pen"), spell_pen) or "",
                0.8, 0.8, 0.8, 0.8, 0.8, 0.8
            )
        end
    end

    local defense = stats.DEFENSE or 0
    local dodge = stats.DODGE or 0
    local parry = stats.PARRY or 0
    local block = stats.TOBLOCK or 0
    local block_val = stats.BLOCK or 0
    local hp5 = stats.HEALTHREG or 0
    if (defense + dodge + parry + block + block_val + hp5) > 0 then
        tip:AddLine(" ")
        tip:AddLine("|cffffd100" .. L_("Defensive") .. ":|r")
        if defense > 0 or dodge > 0 then
            tip:AddDoubleLine(
                defense > 0 and string.format("  %s: |cffffffff+%d|r", L_("Defense Skill"), defense) or "",
                dodge > 0 and string.format("%s: |cffffffff+%d%%|r  ", L_("Dodge"), dodge) or "",
                0.8, 0.8, 0.8, 0.8, 0.8, 0.8
            )
        end
        if parry > 0 or block > 0 then
            tip:AddDoubleLine(
                parry > 0 and string.format("  %s: |cffffffff+%d%%|r", L_("Parry"), parry) or "",
                block > 0 and string.format("%s: |cffffffff+%d%%|r  ", L_("Block Chance"), block) or "",
                0.8, 0.8, 0.8, 0.8, 0.8, 0.8
            )
        end
        if block_val > 0 or hp5 > 0 then
            tip:AddDoubleLine(
                block_val > 0 and string.format("  %s: |cffffffff+%d|r", L_("Block Value"), block_val) or "",
                hp5 > 0 and string.format("%s: |cffffffff+%d|r  ", L_("HP5"), hp5) or "",
                0.8, 0.8, 0.8, 0.8, 0.8, 0.8
            )
        end
    end

    local fire_res = stats.FIRERES or 0
    local nature_res = stats.NATURERES or 0
    local frost_res = stats.FROSTRES or 0
    local shadow_res = stats.SHADOWRES or 0
    local arcane_res = stats.ARCANERES or 0
    if (fire_res + nature_res + frost_res + shadow_res + arcane_res) > 0 then
        tip:AddLine(" ")
        tip:AddLine("|cffffd100" .. L_("Resistances") .. ":|r")
        tip:AddDoubleLine(
            string.format("  %s: +%d  %s: +%d  %s: +%d", L_("Fire"), fire_res, L_("Nature"), nature_res, L_("Frost"),
                frost_res),
            string.format("%s: +%d  %s: +%d  ", L_("Shadow"), shadow_res, L_("Arcane"), arcane_res),
            0.8, 0.8, 0.8, 0.8, 0.8, 0.8
        )
    end

    local has_set = false
    for set_name, bonuses in pairs(scan.active_sets) do
        if not has_set then
            tip:AddLine(" ")
            tip:AddLine("|cffffd100" .. L_("Active Set Bonuses") .. ":|r")
            has_set = true
        end
        tip:AddLine(string.format("  |cff00ff00%s|r", set_name))
        for th, bonus_line in pairs(bonuses) do
            tip:AddLine(string.format("    (%d) |cffffffff%s|r", th, bonus_line), 0.7, 0.7, 0.7)
        end
    end
end

function StatsUI:update_character()
    if not CharacterFrame or not CharacterFrame:IsShown() then return end
    if PaperDollFrame and not PaperDollFrame:IsShown() then
        if char_badge then char_badge:Hide() end
        return
    end

    local cfg = OzGearDB and OzGearDB.stats
    local is_enabled = (not cfg) or (cfg.enabled ~= false)
    if not is_enabled then
        if char_badge then char_badge:Hide() end
        self:clear_character_slots()
        return
    end

    local badge = create_char_badge()
    if badge then
        badge:Show()
    end

    local scan = Scanner:scan_unit("player")
    if not scan then return end

    if badge and badge.text then
        if scan.is_complete or scan.avg_ilvl > 0 then
            badge.text:SetText(string.format("|cffffd100%s:|r |cffffffff%.1f|r", L_("iLvl"), scan.avg_ilvl))
        else
            badge.text:SetText(string.format("|cffffd100%s:|r |cffffaaaa...|r", L_("iLvl")))
        end
    end

    local show_slots = (not cfg) or (cfg.show_slot_ilvl ~= false)
    local equip_slots = (Data and Data.COMBAT_EQUIP_SLOTS) or Scanner.EQUIP_SLOTS
    local char_slots = Data and Data.CHARACTER_SLOTS
    local slot_count = table.getn(equip_slots)

    for i = 1, slot_count do
        local slot_id = equip_slots[i]
        local slot_info = char_slots and char_slots[slot_id]
        local slot_frame = slot_info and getglobal(slot_info.name)

        if slot_frame then
            local fs = get_or_create_slot_text(slot_frame)
            if fs then
                if show_slots then
                    local ilvl = scan.slot_ilvls[slot_id] or 0
                    local quality = scan.slot_qualities[slot_id] or 1
                    if ilvl and ilvl > 0 then
                        local r, g, b = GetItemQualityColor(quality)
                        fs:SetTextColor(r, g, b, 1)
                        fs:SetText(tostring(ilvl))
                        fs:Show()
                    else
                        fs:Hide()
                    end
                else
                    fs:Hide()
                end
            end
        end
    end
end

function StatsUI:clear_character_slots()
    local equip_slots = (Data and Data.COMBAT_EQUIP_SLOTS) or Scanner.EQUIP_SLOTS
    local char_slots = Data and Data.CHARACTER_SLOTS
    local slot_count = table.getn(equip_slots)
    for i = 1, slot_count do
        local slot_id = equip_slots[i]
        local slot_info = char_slots and char_slots[slot_id]
        local slot_frame = slot_info and getglobal(slot_info.name)
        if slot_frame and slot_frame.oz_ilvl then
            slot_frame.oz_ilvl:Hide()
        end
    end
end

function StatsUI:update_inspect()
    if not InspectFrame or not InspectFrame:IsShown() then return end
    if InspectPaperDollFrame and not InspectPaperDollFrame:IsShown() then
        if inspect_badge then inspect_badge:Hide() end
        return
    end

    local cfg = OzGearDB and OzGearDB.stats
    local is_enabled = (not cfg) or (cfg.enabled ~= false)
    if not is_enabled then
        if inspect_badge then inspect_badge:Hide() end
        self:clear_inspect_slots()
        return
    end

    local badge = create_inspect_badge()
    if badge then
        badge:Show()
    end

    local unit = InspectFrame.unit or "target"
    local scan = Scanner:scan_unit(unit)
    if not scan then return end

    if badge and badge.text then
        if scan.is_complete or scan.avg_ilvl > 0 then
            badge.text:SetText(string.format("|cffffd100%s:|r |cffffffff%.1f|r", L_("iLvl"), scan.avg_ilvl))
        else
            badge.text:SetText(string.format("|cffffd100%s:|r |cffffaaaa...|r", L_("iLvl")))
        end
    end

    local show_slots = (not cfg) or (cfg.show_slot_ilvl ~= false)
    local equip_slots = (Data and Data.COMBAT_EQUIP_SLOTS) or Scanner.EQUIP_SLOTS
    local insp_slots = Data and Data.INSPECT_SLOTS
    local slot_count = table.getn(equip_slots)

    for i = 1, slot_count do
        local slot_id = equip_slots[i]
        local slot_name = insp_slots and insp_slots[slot_id]
        local slot_frame = slot_name and getglobal(slot_name)

        if slot_frame then
            local fs = get_or_create_slot_text(slot_frame)
            if fs then
                if show_slots then
                    local ilvl = scan.slot_ilvls[slot_id] or 0
                    local quality = scan.slot_qualities[slot_id] or 1
                    if ilvl and ilvl > 0 then
                        local r, g, b = GetItemQualityColor(quality)
                        fs:SetTextColor(r, g, b, 1)
                        fs:SetText(tostring(ilvl))
                        fs:Show()
                    else
                        fs:Hide()
                    end
                else
                    fs:Hide()
                end
            end
        end
    end
end

function StatsUI:clear_inspect_slots()
    local equip_slots = (Data and Data.COMBAT_EQUIP_SLOTS) or Scanner.EQUIP_SLOTS
    local insp_slots = Data and Data.INSPECT_SLOTS
    local slot_count = table.getn(equip_slots)
    for i = 1, slot_count do
        local slot_id = equip_slots[i]
        local slot_name = insp_slots and insp_slots[slot_id]
        local slot_frame = slot_name and getglobal(slot_name)
        if slot_frame and slot_frame.oz_ilvl then
            slot_frame.oz_ilvl:Hide()
        end
    end
end

-- InspectFrame is load-on-demand; child hooks inherit visibility without global polling
local function try_hook_inspect_ui()
    if inspect_ui_hooked then return end
    if not InspectFrame then return end

    local insp_hook = CreateFrame("Frame", "OzGearInspectStatsHook", InspectFrame)
    insp_hook:SetScript("OnShow", function()
        StatsUI:update_inspect()
    end)
    insp_hook:SetScript("OnHide", function()
        StatsUI:clear_inspect_slots()
    end)
    insp_hook:SetScript("OnEvent", function()
        if event == "PLAYER_TARGET_CHANGED" then
            if InspectFrame:IsShown() then
                StatsUI:update_inspect()
            end
        elseif event == "UNIT_INVENTORY_CHANGED" then
            if InspectFrame:IsShown() and arg1 == InspectFrame.unit then
                StatsUI:update_inspect()
            end
        end
    end)
    insp_hook:RegisterEvent("PLAYER_TARGET_CHANGED")
    insp_hook:RegisterEvent("UNIT_INVENTORY_CHANGED")

    if InspectPaperDollFrame then
        local ipd_hook = CreateFrame("Frame", "OzGearInspectPDStatsHook", InspectPaperDollFrame)
        ipd_hook:SetScript("OnShow", function()
            StatsUI:update_inspect()
        end)
    end

    inspect_ui_hooked = true
end

-- Child hook fires OnShow whenever CharacterFrame opens or regains focus
local char_ui_hook = CreateFrame("Frame", "OzGearCharStatsHook", CharacterFrame)
char_ui_hook:SetScript("OnShow", function()
    StatsUI:update_character()
end)
char_ui_hook:SetScript("OnEvent", function()
    if event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        StatsUI:update_character()
    end
end)
char_ui_hook:RegisterEvent("UNIT_INVENTORY_CHANGED")

-- PaperDollFrame child hook fires when switching back from Reputation/Skills/Honor tabs
if PaperDollFrame then
    local pd_ui_hook = CreateFrame("Frame", "OzGearPaperDollStatsHook", PaperDollFrame)
    pd_ui_hook:SetScript("OnShow", function()
        StatsUI:update_character()
    end)
end

local main_stats_frame = CreateFrame("Frame", "OzGearStatsMainFrame", UIParent)
local poll_timer = 0

main_stats_frame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        try_hook_inspect_ui()
        if CharacterFrame and CharacterFrame:IsShown() then
            StatsUI:update_character()
        end
    elseif event == "ADDON_LOADED" then
        if arg1 == "Blizzard_InspectUI" then
            try_hook_inspect_ui()
        end
    elseif event == "ITEM_TEXT_READY" then
        if CharacterFrame and CharacterFrame:IsShown() then
            StatsUI:update_character()
        end
        if InspectFrame and InspectFrame:IsShown() then
            StatsUI:update_inspect()
        end
    end
end)

-- Re-renders automatically when server replies arrive for uncached item queries
main_stats_frame:SetScript("OnUpdate", function()
    local char_shown = CharacterFrame and CharacterFrame:IsShown()
    local insp_shown = InspectFrame and InspectFrame:IsShown()
    if not char_shown and not insp_shown then return end

    local has_pending = false
    for _, _ in pairs(Scanner.pending_links) do
        has_pending = true
        break
    end

    if not has_pending then return end

    local elapsed = arg1 or 0
    poll_timer = poll_timer + elapsed
    if poll_timer >= 0.5 then
        poll_timer = 0
        local resolved_any = false
        for link, _ in pairs(Scanner.pending_links) do
            local _, _, item_id = string.find(link, "item:(%d+)")
            item_id = tonumber(item_id or 0)
            if item_id and GetItemInfo(item_id) then
                Scanner:on_item_queried(link)
                resolved_any = true
            end
        end

        if resolved_any then
            if char_shown then StatsUI:update_character() end
            if insp_shown then StatsUI:update_inspect() end
        end
    end
end)

main_stats_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
main_stats_frame:RegisterEvent("ADDON_LOADED")
main_stats_frame:RegisterEvent("ITEM_TEXT_READY")
