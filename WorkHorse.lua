OzGear = OzGear or {}
OzGear.WorkHorse = OzGear.WorkHorse or {}

local WorkHorse = OzGear.WorkHorse

WorkHorse.horses = {}
WorkHorse.active_horse = nil
WorkHorse.snapshot = {}
WorkHorse.equipped_special = {}
WorkHorse.combat_queue = nil
WorkHorse.EMPTY_SLOT = "__EMPTY__"

-- Trinket slot candidate scoring weights
local SCORE_EMPTY   = 100
local SCORE_PASSIVE = 50
local SCORE_ON_USE  = 10

function WorkHorse:register_horse(name, horse_module)
    if not name or not horse_module then return end
    self.horses[name] = horse_module
end

-- Checks if equipped item has an active on-use cooldown effect
function WorkHorse:is_on_use_item(slot_id)
    local scan_tooltip = OzGear.scan_tooltip
    if not scan_tooltip then return false end

    local link = GetInventoryItemLink("player", slot_id)
    if not link then return false end

    scan_tooltip:ClearLines()
    local ok = pcall(scan_tooltip.SetInventoryItem, scan_tooltip, "player", slot_id)
    if ok then
        local num_lines = scan_tooltip:NumLines()
        for i = 1, num_lines do
            local line = _G["OzGearScanTooltipTextLeft" .. i]
            local text = line and line:GetText()
            if text then
                if string.find(text, "使用：", 1, true)
                    or string.find(text, "使用:", 1, true)
                    or string.find(text, "Use:", 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

-- Smart multi-trinket candidate allocation (Candidate slots: {14, 13})
function WorkHorse:apply_trinket_group(group, tracker)
    local candidate_slots = group.candidate_slots or { 14, 13 }
    tracker:scan_bags()

    -- 1. Identify currently equipped trinkets in candidate slots
    local equipped_item_slots = {}
    for i = 1, table.getn(candidate_slots) do
        local slot_id = candidate_slots[i]
        local _, item_id = tracker:get_equipped(slot_id)
        if item_id then
            equipped_item_slots[item_id] = slot_id
        end
    end

    -- 2. Pick top 2 priority items owned by the player
    local target_trinkets = {}
    for i = 1, table.getn(group.items) do
        local item = group.items[i]
        if equipped_item_slots[item.id] then
            table.insert(target_trinkets, {
                item = item,
                is_equipped = true,
                slot_id = equipped_item_slots[item.id],
            })
            if table.getn(target_trinkets) >= 2 then break end
        else
            local bag, slot = tracker:find_item(item.id)
            if bag and slot then
                table.insert(target_trinkets, {
                    item = item,
                    is_equipped = false,
                    bag = bag,
                    slot = slot,
                })
                if table.getn(target_trinkets) >= 2 then break end
            end
        end
    end

    if table.getn(target_trinkets) == 0 then return end

    -- 3. Check if all target trinkets are already equipped
    local all_equipped = true
    for i = 1, table.getn(target_trinkets) do
        if not target_trinkets[i].is_equipped then
            all_equipped = false
            break
        end
    end

    if all_equipped then
        for i = 1, table.getn(target_trinkets) do
            self.equipped_special[target_trinkets[i].slot_id] = target_trinkets[i].item.id
        end
        return
    end

    -- 4. Find free candidate slots
    local protected_slots = {}
    for i = 1, table.getn(target_trinkets) do
        local t = target_trinkets[i]
        if t.is_equipped then
            protected_slots[t.slot_id] = true
            self.equipped_special[t.slot_id] = t.item.id
        end
    end

    local free_slots = {}
    for i = 1, table.getn(candidate_slots) do
        local slot_id = candidate_slots[i]
        if not protected_slots[slot_id] then
            table.insert(free_slots, slot_id)
        end
    end

    -- 5. Score available slots (prefer empty > passive > on-use)
    local slot_scores = {}
    for i = 1, table.getn(free_slots) do
        local slot_id = free_slots[i]
        local current_link = GetInventoryItemLink("player", slot_id)
        local score = 0
        if not current_link then
            score = SCORE_EMPTY
        elseif self.equipped_special[slot_id] then
            score = SCORE_EMPTY
        elseif not self:is_on_use_item(slot_id) then
            score = SCORE_PASSIVE
        else
            score = SCORE_ON_USE
        end
        slot_scores[slot_id] = score
    end

    if table.getn(free_slots) == 2 then
        if (slot_scores[free_slots[2]] > slot_scores[free_slots[1]]) or
           (slot_scores[free_slots[2]] == slot_scores[free_slots[1]] and free_slots[2] > free_slots[1]) then
            local temp = free_slots[1]
            free_slots[1] = free_slots[2]
            free_slots[2] = temp
        end
    end

    -- 6. Equip unequipped targets into best available slot
    local free_index = 1
    for i = 1, table.getn(target_trinkets) do
        local t = target_trinkets[i]
        if not t.is_equipped and free_index <= table.getn(free_slots) then
            local target_slot = free_slots[free_index]
            free_index = free_index + 1

            local current_link = GetInventoryItemLink("player", target_slot)
            if tracker:safe_swap_bag_to_inv(t.bag, t.slot, target_slot) then
                if self.snapshot[target_slot] == nil then
                    self.snapshot[target_slot] = current_link or self.EMPTY_SLOT
                end
                self.equipped_special[target_slot] = t.item.id
                OzGear:debug_msg("Equipped " .. t.item.name .. " to trinket slot " .. target_slot)
            end
        end
    end
end

-- Evaluates state priority and triggers appropriate horse or rollback
function WorkHorse:evaluate_rules()
    local env = OzGear.env
    if not env then return end

    -- Safe-mode: party/raid instances suppress all automatic gear switches
    if env.is_dungeon or env.is_raid then
        if self.active_horse then
            self:restore_gear()
        end
        return
    end

    -- Combat guard: non-weapon switches are deferred
    if env.in_combat then
        return
    end

    -- Priority order: Swimming > Riding > Plainsrunning > Normal
    local desired_horse = nil
    if env.is_swimming and self.horses["Swimming"] then
        desired_horse = "Swimming"
    elseif env.is_riding and self.horses["Riding"] then
        desired_horse = "Riding"
    elseif env.is_plainrunning and env.is_tauren and self.horses["Plainrunning"] then
        desired_horse = "Plainrunning"
    end

    if desired_horse ~= self.active_horse then
        OzGear:debug_msg("Transition: [" .. tostring(self.active_horse or "Normal") .. "] -> [" .. tostring(desired_horse or "Normal") .. "]")
        if self.active_horse then
            self:restore_gear()
        end
        if desired_horse then
            self:apply_horse(desired_horse)
        end
    end
end

function WorkHorse:apply_horse(horse_name)
    local env = OzGear.env
    if env and env.in_combat then
        self.combat_queue = { action = "APPLY", horse = horse_name }
        return
    end

    local horse = self.horses[horse_name]
    if not horse then return end

    horse:apply(self, OzGear.SetTracker, OzGear.Data)
    self.active_horse = horse_name
end

-- Resilient restore: only successfully swapped slots are evicted from snapshot
function WorkHorse:restore_gear()
    local env = OzGear.env
    if env and env.in_combat then
        self.combat_queue = { action = "RESTORE" }
        return
    end

    local tracker = OzGear.SetTracker
    local slots_to_evict = {}
    local failures = 0

    for slot_id, original_link in pairs(self.snapshot) do
        local slot_restored = false

        if original_link == self.EMPTY_SLOT then
            local current_link = GetInventoryItemLink("player", slot_id)
            if current_link then
                PickupInventoryItem(slot_id)
                if tracker:put_cursor_in_bags(slot_id) then
                    slot_restored = true
                else
                    failures = failures + 1
                end
            else
                slot_restored = true
            end
        else
            local current_link = GetInventoryItemLink("player", slot_id)
            if current_link == original_link then
                slot_restored = true
            else
                local bag, slot = tracker:find_link(original_link)
                if bag and slot then
                    if tracker:safe_swap_bag_to_inv(bag, slot, slot_id) then
                        slot_restored = true
                    else
                        failures = failures + 1
                    end
                else
                    failures = failures + 1
                end
            end
        end

        if slot_restored then
            table.insert(slots_to_evict, slot_id)
        end
    end

    for i = 1, table.getn(slots_to_evict) do
        local slot_id = slots_to_evict[i]
        self.snapshot[slot_id] = nil
        self.equipped_special[slot_id] = nil
    end

    tracker:mark_dirty()

    if failures == 0 and next(self.snapshot) == nil then
        self.active_horse = nil
        OzGear:debug_msg("Gear restoration complete.")
    end
end

function WorkHorse:process_combat_queue()
    if not self.combat_queue then return end
    local task = self.combat_queue
    self.combat_queue = nil

    if task.action == "APPLY" then
        self:apply_horse(task.horse)
    elseif task.action == "RESTORE" then
        self:restore_gear()
    end
end

-- Wire EventBus triggers to WorkHorse rule evaluator
if OzGear.EventBus and OzGear.EventBus.register then
    OzGear.EventBus:register("TRIGGER_RIDE_CHANGE", function(is_riding)
        WorkHorse:evaluate_rules()
    end)

    OzGear.EventBus:register("TRIGGER_SWIM_CHANGE", function(is_swimming)
        WorkHorse:evaluate_rules()
    end)

    OzGear.EventBus:register("TRIGGER_PLAINRUN_CHANGE", function(is_plainrun)
        WorkHorse:evaluate_rules()
    end)

    OzGear.EventBus:register("TRIGGER_ZONE_CHANGED", function(in_dungeon)
        WorkHorse:evaluate_rules()
    end)

    OzGear.EventBus:register("TRIGGER_COMBAT_CHANGE", function(in_combat)
        if not in_combat then
            WorkHorse:process_combat_queue()
            WorkHorse:evaluate_rules()
        end
    end)
end
