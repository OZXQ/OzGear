OzGear = OzGear or {}
OzGear.SetTracker = OzGear.SetTracker or {}

local SetTracker = OzGear.SetTracker
SetTracker.is_dirty = true
SetTracker.bag_cache = {}
SetTracker.spur_cache = {}

-- 1.12 bag container IDs map to inventory slot IDs: 1->20, 2->21, 3->22, 4->23
local BAG_INVENTORY_ID = { [1] = 20, [2] = 21, [3] = 22, [4] = 23 }

function SetTracker:mark_dirty()
    self.is_dirty = true
end

-- Parse item link into components using Lua 5.0 string.find
function SetTracker:parse_item_link(link)
    if not link or type(link) ~= "string" then return nil end

    -- 4-part SuperWoW format: item:itemId:enchantId:suffixId:uniqueId
    local _, _, item_id_4, enchant_id_4, suffix_id_4, unique_id_4, name_4 =
        string.find(link, "item:(%d+):(%d+):(%d+):(%d+).-%[(.-)%]")
    if item_id_4 then
        return tonumber(item_id_4), tonumber(enchant_id_4), tonumber(suffix_id_4), tonumber(unique_id_4), name_4
    end

    -- 1.12 standard format: item:itemId:enchantId:suffixId
    local _, _, item_id, enchant_id, suffix_id, name =
        string.find(link, "item:(%d+):?(%d*):?(%d*).-%[(.-)%]")
    if item_id then
        return tonumber(item_id), tonumber(enchant_id) or 0, tonumber(suffix_id) or 0, 0, name
    end

    -- Short format fallback: item:itemId
    local _, _, item_id_short, name_short = string.find(link, "item:(%d+).-%[(.-)%]")
    if item_id_short then
        return tonumber(item_id_short), 0, 0, 0, name_short
    end

    return nil
end

function SetTracker:get_equipped(slot_id)
    local link = GetInventoryItemLink("player", slot_id)
    if not link then
        return nil, nil, nil, nil
    end
    local item_id, enchant_id, _, _, name = self:parse_item_link(link)
    return link, item_id, name, enchant_id
end

function SetTracker:has_enchant_text(bag, slot, p1, p2, inv_slot)
    local scan_tooltip = OzGear.scan_tooltip
    if not scan_tooltip then return false end

    scan_tooltip:ClearLines()
    local ok = inv_slot and pcall(scan_tooltip.SetInventoryItem, scan_tooltip, "player", inv_slot)
        or (bag and slot and pcall(scan_tooltip.SetBagItem, scan_tooltip, bag, slot))
    if ok then
        local num_lines = scan_tooltip:NumLines()
        for i = 1, num_lines do
            local line = _G["OzGearScanTooltipTextLeft" .. i]
            local text = line and line:GetText()
            if text then
                if (p1 and string.find(text, p1, 1, true)) or (p2 and string.find(text, p2, 1, true)) then
                    return true
                end
            end
        end
    end
    return false
end

-- Event-driven single-pass bag scan, executed only when is_dirty is true
function SetTracker:scan_bags()
    if not self.is_dirty then return end

    self.bag_cache = {}
    for bag = 0, 4 do
        local num_slots = GetContainerNumSlots(bag)
        for slot = 1, num_slots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local item_id, enchant_id = self:parse_item_link(link)
                if item_id and not self.bag_cache[item_id] then
                    self.bag_cache[item_id] = { bag = bag, slot = slot, link = link }
                end

                -- Spurs detection with memoization to eliminate repeated tooltip parsing
                if enchant_id and enchant_id > 0 then
                    if enchant_id == 464 then
                        self.bag_cache[7969] = { bag = bag, slot = slot, link = link } -- Mithril Spurs
                    elseif self.spur_cache[enchant_id] == 61182 then
                        self.bag_cache[61182] = { bag = bag, slot = slot, link = link }
                    elseif self.spur_cache[enchant_id] == 7969 then
                        self.bag_cache[7969] = { bag = bag, slot = slot, link = link }
                    elseif self.spur_cache[enchant_id] == nil then
                        if self:has_enchant_text(bag, slot, "瑟银马刺", "Thorium Spurs") then
                            self.spur_cache[enchant_id] = 61182
                            self.bag_cache[61182] = { bag = bag, slot = slot, link = link }
                        elseif self:has_enchant_text(bag, slot, "秘银马刺", "Mithril Spurs") then
                            self.spur_cache[enchant_id] = 7969
                            self.bag_cache[7969] = { bag = bag, slot = slot, link = link }
                        else
                            self.spur_cache[enchant_id] = false
                        end
                    end
                end
            end
        end
    end
    self.is_dirty = false
end

function SetTracker:find_item(item_id)
    if not item_id then return nil, nil, nil end
    self:scan_bags()
    local cached = self.bag_cache[item_id]
    if cached then
        return cached.bag, cached.slot, cached.link
    end
    return nil, nil, nil
end

-- Dual-wield identity & exact link lookup
function SetTracker:find_link(target_link)
    if not target_link then return nil, nil, nil end

    local target_item_id, target_enchant = self:parse_item_link(target_link)
    local same_enchant_bag, same_enchant_slot, same_enchant_link = nil, nil, nil
    local same_id_bag, same_id_slot, same_id_link = nil, nil, nil

    for bag = 0, 4 do
        local num_slots = GetContainerNumSlots(bag)
        for slot = 1, num_slots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                if link == target_link then
                    return bag, slot, link
                end

                local item_id, enchant_id = self:parse_item_link(link)
                if item_id and item_id == target_item_id then
                    if enchant_id == target_enchant and not same_enchant_bag then
                        same_enchant_bag, same_enchant_slot, same_enchant_link = bag, slot, link
                    elseif not same_id_bag then
                        same_id_bag, same_id_slot, same_id_link = bag, slot, link
                    end
                end
            end
        end
    end

    local final_bag = same_enchant_bag or same_id_bag
    local final_slot = same_enchant_slot or same_id_slot
    local final_link = same_enchant_link or same_id_link
    return final_bag, final_slot, final_link
end

function SetTracker:is_equipped(slot_id, entry)
    local link, item_id, _, enchant_id = self:get_equipped(slot_id)
    if not link then return false end
    if entry.enchant then
        if entry.enchant_id and enchant_id == entry.enchant_id then return true end
        return self:has_enchant_text(nil, nil, entry.enchant, entry.enchant_en, slot_id)
    end
    return item_id == entry.id
end

-- Safely places cursor item into bag containers; restores to fallback slot if bags full
function SetTracker:put_cursor_in_bags(fallback_inv_slot)
    if not CursorHasItem() then return true end

    PutItemInBackpack()
    if not CursorHasItem() then return true end

    for bag = 1, 4 do
        local inv_id = BAG_INVENTORY_ID[bag]
        if inv_id then
            PutItemInBag(inv_id)
            if not CursorHasItem() then return true end
        end
    end

    for bag = 0, 4 do
        local num_slots = GetContainerNumSlots(bag)
        for slot = 1, num_slots do
            local texture = GetContainerItemInfo(bag, slot)
            if not texture then
                PickupContainerItem(bag, slot)
                if not CursorHasItem() then return true end
            end
        end
    end

    -- Return to original slot on failure to prevent cursor locks
    if CursorHasItem() and fallback_inv_slot then
        PickupInventoryItem(fallback_inv_slot)
        if CursorHasItem() then
            OzGear:print_msg("|cffff4444背包已满且无法放回原槽位，物品仍在光标上！|r")
        else
            OzGear:print_msg("|cffff4444背包已满，无法卸下装备！已放回原槽位。|r")
        end
        return false
    end

    return not CursorHasItem()
end

-- Atomic bag-to-inventory swap with fail-safe recovery
function SetTracker:safe_swap_bag_to_inv(bag, slot, inv_slot)
    if not bag or not slot or not inv_slot then return false end

    if CursorHasItem() then
        self:put_cursor_in_bags(inv_slot)
    end

    PickupContainerItem(bag, slot)
    if not CursorHasItem() then
        return false
    end

    PickupInventoryItem(inv_slot)
    if CursorHasItem() then
        PickupContainerItem(bag, slot)
    end

    if CursorHasItem() then
        self:put_cursor_in_bags(inv_slot)
    end

    self:mark_dirty()
    return not CursorHasItem()
end

-- Subscribe to EventBus bag updates
if OzGear.EventBus and OzGear.EventBus.register then
    OzGear.EventBus:register("TRIGGER_BAGS_UPDATED", function()
        SetTracker:mark_dirty()
    end)
end
