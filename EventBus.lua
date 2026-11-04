OzGear = OzGear or {}
OzGear.EventBus = OzGear.EventBus or {}

local EventBus = OzGear.EventBus
EventBus.listeners = {}

-- Cached texture classification to eliminate repeated tooltip churn on legacy clients
local buff_mount_cache = {}

-- Static debounce and polling metrics
local CHECK_INTERVAL = 0.2
local DEBOUNCE_DELAY = 0.3
local update_timer = 0
local pending_swim = false
local pending_swim_time = 0

function EventBus:register(event_name, handler)
    if not event_name or type(handler) ~= "function" then return end
    self.listeners[event_name] = self.listeners[event_name] or {}
    table.insert(self.listeners[event_name], handler)
end

function EventBus:emit(event_name, a1, a2, a3, a4)
    local list = self.listeners[event_name]
    if not list then return end
    for i = 1, table.getn(list) do
        list[i](a1, a2, a3, a4)
    end
end

function EventBus:check_instance_state()
    local env = OzGear.env
    if not env then return end

    local was_dungeon = env.is_dungeon
    local was_raid = env.is_raid

    if type(IsInInstance) == "function" then
        local in_instance, instance_type = IsInInstance()
        env.is_dungeon = (in_instance and instance_type == "party") and true or false
        env.is_raid = (in_instance and instance_type == "raid") and true or false
    else
        env.is_dungeon = false
        env.is_raid = false
    end

    if was_dungeon ~= env.is_dungeon or was_raid ~= env.is_raid then
        self:emit("TRIGGER_ZONE_CHANGED", env.is_dungeon or env.is_raid)
    end
end

-- Native or cached mount detection with zero continuous tooltip churn
function EventBus:check_mounted_state()
    local env = OzGear.env
    if not env or env.in_combat or env.is_dungeon or env.is_raid then
        return false
    end

    -- 1. Native engine API if SuperWoW 2.0+
    if env.is_super_wow_20 then
        if type(IsMounted) == "function" then
            return IsMounted() and true or false
        end
        if type(UnitIsMounted) == "function" then
            return UnitIsMounted("player") and true or false
        end
    end

    -- 2. Legacy fallback: fast buff texture scan
    for i = 1, 24 do
        local buff = UnitBuff("player", i)
        if not buff then break end

        local cached = buff_mount_cache[buff]
        if cached ~= nil then
            if cached then return true end
        else
            -- Plain substring inspection to prevent multibyte corruption
            local is_aspect = (string.find(buff, "whitetiger", 1, true) ~= nil)
                or (string.find(buff, "pinktiger", 1, true) ~= nil)
                or (string.find(buff, "jungletiger", 1, true) ~= nil)

            if not is_aspect then
                if string.find(buff, "inv_pet_speedy", 1, true)
                    or (string.find(buff, "Mount_", 1, true) and not string.find(buff, "Spell_Nature_Swiftness", 1, true))
                    or string.find(buff, "QirajiCrystal_", 1, true) then
                    buff_mount_cache[buff] = true
                    return true
                end
            end

            -- Disambiguate Paladin/Warlock charger via tooltip once on aura change
            local scan_tooltip = OzGear.scan_tooltip
            if scan_tooltip then
                scan_tooltip:ClearLines()
                local ok = pcall(scan_tooltip.SetUnitBuff, scan_tooltip, "player", i)
                if ok then
                    local line2 = _G["OzGearScanTooltipTextLeft2"]
                    local text2 = line2 and line2:GetText()
                    if text2 and (string.find(text2, "^提高速度") or string.find(text2, "^Increases speed")) then
                        buff_mount_cache[buff] = true
                        return true
                    end
                end
            end
            buff_mount_cache[buff] = false
        end
    end

    return false
end

-- Swimming detection: native physics only. Feature is cleanly dropped on legacy clients.
function EventBus:check_swimming_state()
    local env = OzGear.env
    if not env or not env.is_super_wow_20 or env.in_combat or env.is_dungeon or env.is_raid or env.is_riding then
        return false
    end

    if type(IsSwimming) == "function" then
        local res = IsSwimming()
        return (res and res ~= 0) and true or false
    end
    if type(UnitIsSwimming) == "function" then
        local res = UnitIsSwimming("player")
        return (res and res ~= 0) and true or false
    end

    return false
end

-- Plainsrunning detection for Tauren
function EventBus:check_plainrunning_state()
    local env = OzGear.env
    if not env or not env.is_tauren or env.in_combat or env.is_dungeon or env.is_raid or env.is_riding then
        return false
    end

    for i = 1, 24 do
        local buff = UnitBuff("player", i)
        if not buff then break end
        if string.find(buff, "Spell_Nature_Swiftness", 1, true) then
            return true
        end
    end

    return false
end

function EventBus:update_auras()
    local env = OzGear.env
    if not env then return end

    local new_riding = self:check_mounted_state()
    if new_riding ~= env.is_riding then
        env.is_riding = new_riding
        self:emit("TRIGGER_RIDE_CHANGE", new_riding)
    end

    if env.is_tauren then
        local new_plainrun = self:check_plainrunning_state()
        if new_plainrun ~= env.is_plainrunning then
            env.is_plainrunning = new_plainrun
            self:emit("TRIGGER_PLAINRUN_CHANGE", new_plainrun)
        end
    end
end

-- Central event dispatcher frame
local event_frame = CreateFrame("Frame", "OzGearEventBusFrame", UIParent)

event_frame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        if not OzGear.is_inited then OzGear:init_env() end
        EventBus:check_instance_state()
        EventBus:update_auras()
        EventBus:emit("TRIGGER_BAGS_UPDATED")
    elseif event == "BAG_UPDATE" then
        EventBus:emit("TRIGGER_BAGS_UPDATED")
    elseif event == "PLAYER_AURAS_CHANGED" then
        EventBus:update_auras()
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
        EventBus:check_instance_state()
    elseif event == "PLAYER_REGEN_DISABLED" then
        if OzGear.env then
            OzGear.env.in_combat = true
        end
        EventBus:emit("TRIGGER_COMBAT_CHANGE", true)
    elseif event == "PLAYER_REGEN_ENABLED" then
        if OzGear.env then
            OzGear.env.in_combat = false
        end
        EventBus:emit("TRIGGER_COMBAT_CHANGE", false)
        EventBus:update_auras()
    end
end)

event_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
event_frame:RegisterEvent("BAG_UPDATE")
event_frame:RegisterEvent("PLAYER_AURAS_CHANGED")
event_frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
event_frame:RegisterEvent("ZONE_CHANGED")
event_frame:RegisterEvent("PLAYER_REGEN_DISABLED")
event_frame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Physics and debounce tick loop (zero tooltip scanning)
event_frame:SetScript("OnUpdate", function()
    local elapsed = arg1 or 0
    update_timer = update_timer + elapsed
    if update_timer < CHECK_INTERVAL then return end

    local dt = update_timer
    update_timer = 0

    local env = OzGear.env
    if not env then return end

    -- Native swimming check with debounce (SuperWoW 2.0+ only)
    if env.is_super_wow_20 and not env.in_combat and not env.is_dungeon and not env.is_raid then
        local raw_swim = EventBus:check_swimming_state()
        if raw_swim ~= env.is_swimming then
            if raw_swim == pending_swim then
                pending_swim_time = pending_swim_time + dt
                if pending_swim_time >= DEBOUNCE_DELAY then
                    env.is_swimming = raw_swim
                    pending_swim_time = 0
                    EventBus:emit("TRIGGER_SWIM_CHANGE", raw_swim)
                end
            else
                pending_swim = raw_swim
                pending_swim_time = 0
            end
        else
            pending_swim = raw_swim
            pending_swim_time = 0
        end
    end
end)
