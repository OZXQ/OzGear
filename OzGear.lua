--[[
    OzGear.lua
    Main Addon Facade, Namespace Entry Point, and Slash Command Router.
]] --

OzGear = OzGear or {}
OzGear.version = "0.2.0"
OzGear.env = OzGear.env or {}
OzGear.is_inited = false

-- Initialize environment capabilities and character state
function OzGear:init_env()
    self.env = self.env or {}
    local env = self.env

    -- SuperWoW 2.0+ detection using Lua 5.0 string.find
    local is_super_wow = false
    if SUPERWOW_VERSION then
        local _, _, major, minor = string.find(tostring(SUPERWOW_VERSION), "(%d+)%.?(%d*)")
        local ver = tonumber(major or 0) + (tonumber(minor or 0) / 10)
        if ver >= 2.0 then
            is_super_wow = true
        end
    end
    env.is_super_wow_20 = is_super_wow

    -- Static character traits
    local _, race = UnitRace("player")
    env.is_tauren = (race == "Tauren")

    local _, class = UnitClass("player")
    env.player_class = class or ""
    env.is_rogue = (class == "ROGUE")

    -- Initial runtime flags
    env.in_combat = (UnitAffectingCombat and UnitAffectingCombat("player")) and true or false
    if env.is_swimming == nil then env.is_swimming = false end
    if env.is_riding == nil then env.is_riding = false end
    if env.is_plainrunning == nil then env.is_plainrunning = false end
    local in_dungeon, team_type = IsInInstance()
    if in_dungeon then env.is_dungeon = true else env.is_dungeon = false end
    if team_type == "raid" then env.is_raid = true else env.is_raid = false end

    -- Initialize persistent SavedVariables configuration
    if not OzGearDB then OzGearDB = {} end
    if OzGearDB.glow == nil then
        OzGearDB.glow = {
            enabled = true,
            threshold = 2,
            show_durability = true,
        }
    else
        if OzGearDB.glow.enabled == nil then OzGearDB.glow.enabled = true end
        if OzGearDB.glow.threshold == nil then OzGearDB.glow.threshold = 2 end
        if OzGearDB.glow.show_durability == nil then OzGearDB.glow.show_durability = true end
    end

    self.is_inited = true
end

-- Shared hidden tooltip for buff and item enchantment scans
local scan_tooltip = getglobal and getglobal("OzGearScanTooltip") or (_G and _G["OzGearScanTooltip"])
if not scan_tooltip then
    scan_tooltip = CreateFrame("GameTooltip", "OzGearScanTooltip", UIParent, "GameTooltipTemplate")
    scan_tooltip:SetOwner(UIParent, "ANCHOR_NONE")
end
OzGear.scan_tooltip = scan_tooltip

-- Centralized logging
function OzGear:print_msg(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff96[OzGear]|r " .. tostring(msg))
    end
end

function OzGear:debug_msg(msg)
    if OzGearDB and OzGearDB.debug and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff888888[OzGear-Debug]|r " .. tostring(msg))
    end
end

-- Key binding global headers
BINDING_HEADER_OZGEAR = "OzGear"
BINDING_NAME_OZGEAR_SWAP = "Swap Weapons"
BINDING_NAME_OZGEAR_SWIM = "Toggle Swim Gear"
BINDING_NAME_OZGEAR_RESTORE = "Restore Normal Gear"

-- Facade action helpers
function OzGear:swap_weapons()
    local dw = self.WorkHorse and self.WorkHorse.horses and self.WorkHorse.horses["DualWield"]
    if dw then
        return dw:swap_weapons(self.SetTracker)
    end
    return false
end

function OzGear:toggle_swim()
    local wh = self.WorkHorse
    if not wh then return end

    if wh.active_horse == "Swimming" then
        self:print_msg("Swimming gear cleared. Restoring original gear...")
        wh:restore_gear()
    else
        self:print_msg("Manual trigger: Applying swimming gear.")
        wh:apply_horse("Swimming")
    end
end

function OzGear:restore()
    self:print_msg("Manual trigger: Restoring gear.")
    if self.WorkHorse then
        self.WorkHorse:restore_gear()
    end
end

-- Slash commands router
SLASH_OZGEAR1 = "/ozgear"
SLASH_OZGEAR2 = "/ozg"

SlashCmdList["OZGEAR"] = function(msg)
    if not OzGear.is_inited then OzGear:init_env() end
    msg = msg or ""
    local _, _, cmd = string.find(msg, "(%a+)")
    cmd = cmd or ""

    if cmd == "swap" then
        local ok = OzGear:swap_weapons()
        if ok and OzGearDB and OzGearDB.debug then
            OzGear:print_msg("Weapons swapped.")
        end
    elseif cmd == "debug" then
        if not OzGearDB then OzGearDB = { debug = false } end
        OzGearDB.debug = not OzGearDB.debug
        OzGear:print_msg("Debug mode: " .. (OzGearDB.debug and "|cff00ff00ON|r" or "|cffff4444OFF|r"))
    elseif cmd == "status" then
        OzGear:print_msg("--- OzGear Status ---")
        OzGear:print_msg("Version: " .. OzGear.version)

        local env = OzGear.env
        if env then
            OzGear:print_msg("SuperWoW 2.0+: " ..
                (env.is_super_wow_20 and "|cff00ff00YES (Native API active)|r" or "|cffffaa00NO (Legacy mode)|r"))
            OzGear:print_msg("In Combat: " .. (env.in_combat and "|cffff4444YES|r" or "|cff00ff00NO|r"))
            OzGear:print_msg("In Instance: " ..
                ((env.is_dungeon or env.is_raid) and "|cffff4444YES (Auto-detect disabled)|r" or "|cff00ff00NO|r"))
            OzGear:print_msg("Riding: " .. (env.is_riding and "|cff00ff00YES|r" or "|cffff4444NO|r"))
            OzGear:print_msg("Swimming: " ..
                (env.is_swimming and "|cff00ff00YES|r" or (env.is_super_wow_20 and "|cffff4444NO|r" or "|cff888888DISABLED (Requires SuperWoW 2.0+)|r")))
            if env.is_tauren then
                OzGear:print_msg("Plainsrunning: " .. (env.is_plainrunning and "|cff00ff00YES|r" or "|cffff4444NO|r"))
            end
        end

        local wh = OzGear.WorkHorse
        if wh then
            OzGear:print_msg("Active Horse: " .. tostring(wh.active_horse or "Normal"))
            local snap_count = 0
            for slot_id, link in pairs(wh.snapshot) do
                snap_count = snap_count + 1
                OzGear:print_msg(string.format("  Slot %d backup: %s", slot_id, tostring(link or "Empty")))
            end
            if snap_count == 0 then
                OzGear:print_msg("  Snapshot: Empty")
            end
        end

        if OzGear.SetTracker then
            OzGear:print_msg("Bag Cache: " .. (OzGear.SetTracker.is_dirty and "|cffffff00Dirty|r" or "|cff00ff00Clean|r"))
        end

        local cfg = OzGearDB and OzGearDB.glow
        local is_glow_on = (not cfg) or (cfg.enabled ~= false)
        if is_glow_on then
            local th = (cfg and cfg.threshold) or 2
            local qnames = OzGear.Data and OzGear.Data.QUALITY_NAMES
            local th_name = (qnames and qnames[th]) or (tostring(th) .. "+")
            local dura_txt = ((not cfg) or cfg.show_durability ~= false) and "|cff00ff00ON|r" or "|cffff4444OFF|r"
            OzGear:print_msg(string.format("Glowing Gear: |cff00ff00ON|r (Threshold: %s, Durability Warning: %s)", th_name, dura_txt))
        else
            OzGear:print_msg("Glowing Gear: |cffff4444OFF|r")
        end
    elseif cmd == "glow" then
        if not OzGearDB then OzGearDB = {} end
        if not OzGearDB.glow then
            OzGearDB.glow = { enabled = true, threshold = 2, show_durability = true }
        end

        local _, _, _, sub_cmd, sub_val = string.find(msg, "(%a+)%s*([%a%d]*)%s*([%a%d]*)")
        sub_cmd = sub_cmd or ""
        sub_val = sub_val or ""

        if sub_cmd == "on" then
            OzGearDB.glow.enabled = true
            if OzGear.Glow then OzGear.Glow:update_all_character() end
            OzGear:print_msg("Glowing gear: |cff00ff00ENABLED|r")
        elseif sub_cmd == "off" then
            OzGearDB.glow.enabled = false
            if OzGear.Glow then
                OzGear.Glow:clear_all_character()
                OzGear.Glow:clear_all_inspect()
            end
            OzGear:print_msg("Glowing gear: |cffff4444DISABLED|r")
        elseif sub_cmd == "dura" then
            OzGearDB.glow.show_durability = not OzGearDB.glow.show_durability
            if OzGear.Glow then OzGear.Glow:update_all_character() end
            OzGear:print_msg("Glow durability warnings: " .. (OzGearDB.glow.show_durability and "|cff00ff00ON|r" or "|cffff4444OFF|r"))
        elseif sub_cmd == "threshold" or sub_cmd == "th" then
            local val = tonumber(sub_val)
            if val and val >= 0 and val <= 5 then
                OzGearDB.glow.threshold = val
                local qnames = OzGear.Data and OzGear.Data.QUALITY_NAMES
                local name = (qnames and qnames[val]) or tostring(val)
                if OzGear.Glow then OzGear.Glow:update_all_character() end
                OzGear:print_msg("Glow threshold set to: " .. name)
            else
                OzGear:print_msg("Usage: /ozg glow threshold <0-5> (0=Poor, 1=Common, 2=Uncommon, 3=Rare, 4=Epic, 5=Legendary)")
            end
        else
            OzGearDB.glow.enabled = not OzGearDB.glow.enabled
            if OzGearDB.glow.enabled then
                if OzGear.Glow then OzGear.Glow:update_all_character() end
                OzGear:print_msg("Glowing gear: |cff00ff00ENABLED|r")
            else
                if OzGear.Glow then
                    OzGear.Glow:clear_all_character()
                    OzGear.Glow:clear_all_inspect()
                end
                OzGear:print_msg("Glowing gear: |cffff4444DISABLED|r")
            end
        end
    elseif cmd == "swim" then
        OzGear:toggle_swim()
    elseif cmd == "ride" then
        OzGear:print_msg("Manual trigger: Applying riding gear.")
        if OzGear.WorkHorse then
            OzGear.WorkHorse:apply_horse("Riding")
        end
    elseif cmd == "restore" then
        OzGear:restore()
    else
        OzGear:print_msg("Commands:")
        OzGear:print_msg("  |cffffff00/ozg swap|r - In-place swap equipped MainHand and OffHand weapons")
        OzGear:print_msg("  |cffffff00/ozg status|r - Display current state and snapshotted gear")
        OzGear:print_msg("  |cffffff00/ozg glow [on|off|th <0-5>|dura]|r - Manage character & inspect glowing gear")
        OzGear:print_msg("  |cffffff00/ozg debug|r - Toggle debug log output")
        OzGear:print_msg("  |cffffff00/ozg swim|r - Toggle swimming gear on/off")
        OzGear:print_msg("  |cffffff00/ozg ride|r - Force equip riding gear")
        OzGear:print_msg("  |cffffff00/ozg restore|r - Force restore original gear")
    end
end
