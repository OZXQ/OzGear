OzGear = OzGear or {}
OzGear.WorkHorse = OzGear.WorkHorse or {}

local RidingHorse = {}
RidingHorse.name = "Riding"
RidingHorse.priority = 20

function RidingHorse:apply(work_horse, tracker, data)
    local slot_groups = data and data.RIDING_SLOTS
    if not slot_groups then return end

    tracker:scan_bags()

    for i = 1, table.getn(slot_groups) do
        local group = slot_groups[i]
        if group.is_trinket then
            work_horse:apply_trinket_group(group, tracker)
        else
            local slot_id = group.slot
            local top_item = group.items[1]

            -- Early exit if already wearing top priority boots/spurs
            if tracker:is_equipped(slot_id, top_item) then
                work_horse.equipped_special[slot_id] = top_item.id
            else
                for j = 1, table.getn(group.items) do
                    local item = group.items[j]
                    if tracker:is_equipped(slot_id, item) then
                        work_horse.equipped_special[slot_id] = item.id
                        break
                    end

                    local bag, slot = tracker:find_item(item.id)
                    if bag and slot then
                        local current_link = GetInventoryItemLink("player", slot_id)
                        if tracker:safe_swap_bag_to_inv(bag, slot, slot_id) then
                            if work_horse.snapshot[slot_id] == nil then
                                work_horse.snapshot[slot_id] = current_link or work_horse.EMPTY_SLOT
                            end
                            work_horse.equipped_special[slot_id] = item.id
                            OzGear:debug_msg("Riding: equipped " .. item.name .. " to slot " .. slot_id)
                        end
                        break
                    end
                end
            end
        end
    end
end

OzGear.WorkHorse:register_horse("Riding", RidingHorse)
