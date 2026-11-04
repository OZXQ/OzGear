--[[
    Scanner.lua
    Character stats and item level calculation engine.
]]

OzGear = OzGear or {}
OzGear.StatScanner = OzGear.StatScanner or {}
local Scanner = OzGear.StatScanner
local Data = OzGear.Data

Scanner.cache = {}
Scanner.pending_links = {}

local function add_stat(stats, key, val)
    if not key or not val then return end
    local num = tonumber(val) or 0
    if num == 0 then return end

    if type(key) == "table" then
        local count = table.getn(key)
        for i = 1, count do
            local k = key[i]
            stats[k] = (stats[k] or 0) + num
        end
    else
        stats[key] = (stats[key] or 0) + num
    end
end

-- S_ItemTip / ItemScore quality scale calculation
local function calculate_item_score(rarity, ilvl)
    if not rarity or not ilvl or ilvl <= 0 then return 0 end
    local scales = Data and Data.QUALITY_SCALE
    local quality_scale = (scales and scales[rarity]) or 1.0
    return ilvl * quality_scale
end

-- Full-width Chinese punctuation must be normalized before matching regex patterns
local function normalize_text(text)
    if not text then return "" end
    text = string.gsub(text, "：", ":")
    text = string.gsub(text, "％", "%%")
    text = string.gsub(text, "。", ".")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function should_ignore_line(line)
    local ignore_list = OzGear.ScannerData and OzGear.ScannerData.IGNORE_SUBSTRINGS
    if not ignore_list then return false end
    local count = table.getn(ignore_list)
    for i = 1, count do
        if string.find(line, ignore_list[i], 1, true) then
            return true
        end
    end
    return false
end

function Scanner:get_item_level(item_id, link, quality, min_level)
    if not item_id or item_id == 0 then return 0 end

    -- SuperWoW injects C++ functions that read client DBC memory in 0ms
    if GetItemLevel then
        local ilvl = GetItemLevel(item_id)
        if ilvl and ilvl > 0 then
            return ilvl
        end
    end

    if GetItemStats then
        local ok, stats = pcall(GetItemStats, item_id, true)
        if ok and stats and stats.itemLevel and stats.itemLevel > 0 then
            return stats.itemLevel
        end
    end

    local catalog = OzGear.ScannerData and OzGear.ScannerData.ITEM_LEVEL_CATALOG
    if catalog and catalog[item_id] then
        return catalog[item_id]
    end

    -- Trigger server query packet CMSG_ITEM_QUERY_SINGLE if uncached
    local item_name = GetItemInfo(item_id)
    if not item_name and link then
        if OzGear.scan_tooltip then
            local _, _, clean_link = string.find(link, "(item:[%d%-:]+)")
            if clean_link then
                OzGear.scan_tooltip:ClearLines()
                pcall(OzGear.scan_tooltip.SetHyperlink, OzGear.scan_tooltip, clean_link)
            end
        end
        self.pending_links[link] = true
    end

    -- Temporary heuristic fallback from link quality hex code while awaiting server reply
    if not quality or quality < 0 then
        if link then
            if string.find(link, "cffa335ee") then
                quality = 4
            elseif string.find(link, "cff0070dd") then
                quality = 3
            elseif string.find(link, "cff1eff00") then
                quality = 2
            elseif string.find(link, "cffff8000") then
                quality = 5
            else
                quality = 1
            end
        else
            quality = 1
        end
    end

    quality = tonumber(quality) or 1
    local req = tonumber(min_level) or 50
    if quality == 5 then
        return 80
    elseif quality == 4 then
        return (req >= 60) and 66 or (req + 10)
    elseif quality == 3 then
        return (req >= 60) and 58 or (req + 5)
    elseif quality == 2 then
        return (req > 0) and req or 35
    else
        return (req > 0) and req or 1
    end
end

function Scanner:scan_passive_line(line, target_stats)
    if not line or line == "" then return false end
    local patterns = OzGear.ScannerData and OzGear.ScannerData.EQUIP_PATTERNS
    if not patterns then return false end

    local count = table.getn(patterns)
    for i = 1, count do
        local p = patterns[i]
        local _, _, val = string.find(line, p.pattern)
        if val then
            local num = p.value or val
            add_stat(target_stats, p.effect, num)
            return true
        end
    end
    return false
end

function Scanner:scan_direct_token(token, val, target_stats)
    if not token or not val then return false end
    token = string.gsub(token, "^%s+", "")
    token = string.gsub(token, "%s+$", "")
    token = string.gsub(token, "%.$", "")

    local tokens = OzGear.ScannerData and OzGear.ScannerData.TOKEN_LOOKUP
    if tokens and tokens[token] then
        add_stat(target_stats, tokens[token], val)
        return true
    end
    return false
end

function Scanner:scan_line(line, parsed)
    if not line or line == "" then return false end

    if should_ignore_line(line) then
        return false
    end

    line = normalize_text(line)

    local fixed = OzGear.ScannerData and OzGear.ScannerData.FIXED_PATTERNS
    if fixed then
        local fixed_count = table.getn(fixed)
        for i = 1, fixed_count do
            local f = fixed[i]
            if string.find(line, f.pattern) then
                for k, v in pairs(f.stats) do
                    add_stat(parsed.stats, k, v)
                end
                return true
            end
        end
    end

    local _, _, set_name, set_count = string.find(line, "^(.-)%s*%(%d+/(%d+)%)")
    if set_name and set_count then
        parsed.set_name = set_name
        parsed.set_total = tonumber(set_count) or 0
        return true
    end

    local _, _, threshold, set_line = string.find(line, "^%((%d+)%)%s*.-[:：]%s*(.*)$")
    if threshold and set_line then
        local th = tonumber(threshold)
        if th and th > 0 then
            parsed.set_bonuses[th] = parsed.set_bonuses[th] or { stats = {}, line = set_line }
            self:scan_passive_line(set_line, parsed.set_bonuses[th].stats)
            return true
        end
    end

    local _, _, equip_line = string.find(line, "^[Ee][Qq][Uu][Ii][Pp]%s*[:：]%s*(.*)$")
    if not equip_line then
        _, _, equip_line = string.find(line, "^装备%s*[:：]%s*(.*)$")
    end
    if equip_line then
        return self:scan_passive_line(equip_line, parsed.stats)
    end

    if string.find(line, "^%+") then
        local remainder = line
        local found_any = false
        while remainder and remainder ~= "" do
            local pos = string.find(remainder, "/", 1, true)
            local seg = remainder
            if pos then
                seg = string.sub(remainder, 1, pos - 1)
                remainder = string.sub(remainder, pos + 1)
            else
                remainder = ""
            end

            local _, _, val, token = string.find(seg, "^%+(%d+)%%?%s*(.*)$")
            if not val then
                _, _, token, val = string.find(seg, "^(.*)%+(%d+)%%?$")
            end
            if val and token then
                if self:scan_direct_token(token, val, parsed.stats) then
                    found_any = true
                end
            end
        end
        if found_any then return true end
    end

    local _, _, armor_val = string.find(line, "^(%d+)%s*点?护甲")
    if not armor_val then
        _, _, armor_val = string.find(line, "^(%d+)%s*Armor")
    end
    if armor_val then
        add_stat(parsed.stats, "ARMOR", armor_val)
        return true
    end

    return self:scan_passive_line(line, parsed.stats)
end

function Scanner:parse_item_link(link, unit, slot_id)
    if not link or link == "" then return nil end

    if self.cache[link] then
        return self.cache[link]
    end

    local _, _, item_id, enchant_id = string.find(link, "item:(%d+):(%d+)")
    if not item_id then
        _, _, item_id = string.find(link, "item:(%d+)")
    end
    item_id = tonumber(item_id or 0)
    enchant_id = tonumber(enchant_id or 0)
    if not item_id or item_id == 0 then return nil end

    local item_name, _, quality, min_level, _, _, _, equip_slot = GetItemInfo(item_id)
    quality = tonumber(quality) or 1
    min_level = tonumber(min_level) or 0
    local ilvl = self:get_item_level(item_id, link, quality, min_level)

    local parsed = {
        link = link,
        item_id = item_id,
        enchant_id = enchant_id,
        ilvl = ilvl,
        quality = quality or 1,
        equip_slot = equip_slot or "",
        stats = {},
        set_name = nil,
        set_total = 0,
        set_bonuses = {},
    }

    if enchant_id and enchant_id > 0 then
        local enchant_map = OzGear.ScannerData and OzGear.ScannerData.ENCHANT_LOOKUP
        if enchant_map and enchant_map[enchant_id] then
            for stat_key, stat_val in pairs(enchant_map[enchant_id]) do
                add_stat(parsed.stats, stat_key, stat_val)
            end
        end
    end

    local tip = OzGear.scan_tooltip
    if tip then
        tip:ClearLines()
        local loaded = false
        if unit and slot_id then
            local ok = pcall(tip.SetInventoryItem, tip, unit, slot_id)
            if ok and tip:NumLines() and tip:NumLines() > 0 then
                loaded = true
            end
        end

        if not loaded then
            local _, _, clean_link = string.find(link, "(item:[%d%-:]+)")
            if clean_link then
                pcall(tip.SetHyperlink, tip, clean_link)
            end
        end

        local num_lines = tip:NumLines()
        if num_lines and num_lines > 1 then
            for i = 2, num_lines do
                local left = getglobal("OzGearScanTooltipTextLeft" .. i)
                local text = left and left:GetText()
                if text and text ~= "" then
                    self:scan_line(text, parsed)
                end
            end
        end
    end

    self.cache[link] = parsed
    return parsed
end

function Scanner:scan_unit(unit)
    unit = unit or "player"

    local result = {
        unit = unit,
        avg_ilvl = 0,
        total_ilvl = 0,
        equipped_count = 0,
        slot_ilvls = {},
        slot_links = {},
        slot_qualities = {},
        stats = {},
        active_sets = {},
        is_complete = true,
    }

    local set_counts = {}
    local set_definitions = {}
    local _, class = UnitClass(unit)
    local is_hunter = (class == "HUNTER")
    local total_score = 0
    local slot_coefficients = (Data and Data.SLOT_COEFFICIENTS) or {}

    local equip_slots = (Data and Data.COMBAT_EQUIP_SLOTS) or {
        1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
    }
    local slot_count = table.getn(equip_slots)

    for s = 1, slot_count do
        local slot_id = equip_slots[s]
        local link = GetInventoryItemLink(unit, slot_id)

        if link then
            result.slot_links[slot_id] = link
            local parsed = self:parse_item_link(link, unit, slot_id)

            if parsed then
                local ilvl = parsed.ilvl or 0
                result.slot_ilvls[slot_id] = ilvl
                result.slot_qualities[slot_id] = parsed.quality

                local coef = slot_coefficients[slot_id] or 1
                if slot_id == 16 then
                    if parsed.equip_slot == "INVTYPE_2HWEAPON" then
                        coef = is_hunter and 1 or 2.6836
                    else
                        coef = is_hunter and 0.5 or 1.6836
                    end
                elseif slot_id == 17 then
                    coef = is_hunter and 0.5 or 1
                elseif slot_id == 18 then
                    coef = is_hunter and 2 or 0.3164
                end

                local item_score = calculate_item_score(parsed.quality, ilvl)
                if item_score and item_score > 0 then
                    total_score = total_score + (item_score * coef)
                end

                result.total_ilvl = result.total_ilvl + ilvl
                result.equipped_count = result.equipped_count + 1

                for stat_key, stat_val in pairs(parsed.stats) do
                    add_stat(result.stats, stat_key, stat_val)
                end

                if parsed.set_name then
                    local s_name = parsed.set_name
                    set_counts[s_name] = (set_counts[s_name] or 0) + 1
                    if not set_definitions[s_name] then
                        set_definitions[s_name] = parsed.set_bonuses
                    else
                        for th, bonus_data in pairs(parsed.set_bonuses) do
                            if not set_definitions[s_name][th] then
                                set_definitions[s_name][th] = bonus_data
                            end
                        end
                    end
                end
            end
        else
            result.slot_ilvls[slot_id] = 0
            result.slot_qualities[slot_id] = 0
        end
    end

    -- S_ItemTip / ItemScore weighted average formula
    local divisor = 17
    result.avg_ilvl = tonumber(string.format("%0.1f", (total_score / divisor) * 1.355)) or 0

    for s_name, count in pairs(set_counts) do
        local bonuses = set_definitions[s_name]
        if bonuses then
            for th, bonus_data in pairs(bonuses) do
                if count >= th then
                    for stat_key, stat_val in pairs(bonus_data.stats) do
                        add_stat(result.stats, stat_key, stat_val)
                    end
                    result.active_sets[s_name] = result.active_sets[s_name] or {}
                    result.active_sets[s_name][th] = bonus_data.line or ""
                end
            end
        end
    end

    for link_key, _ in pairs(self.pending_links) do
        if not self.cache[link_key] or not GetItemInfo(self.cache[link_key].item_id) then
            result.is_complete = false
            break
        end
    end

    return result
end

function Scanner:on_item_queried(link)
    if link and self.pending_links[link] then
        self.pending_links[link] = nil
        self.cache[link] = nil
        self:parse_item_link(link)
        return true
    end
    return false
end
