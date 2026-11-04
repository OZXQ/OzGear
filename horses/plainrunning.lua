OzGear = OzGear or {}
OzGear.WorkHorse = OzGear.WorkHorse or {}

local PlainrunningHorse = {}
PlainrunningHorse.name = "Plainrunning"
PlainrunningHorse.priority = 20

function PlainrunningHorse:apply(work_horse, tracker, data)
    local slot_groups = data and data.PLAINRUNNING_SLOTS
    if not slot_groups then return end

    tracker:scan_bags()

    for i = 1, table.getn(slot_groups) do
        local group = slot_groups[i]
        local slot_id = group.slot
        local top_item = group.items[1]

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
                    if group.is_two_hand then
                        local oh_link = GetInventoryItemLink("player", 17)
                        if oh_link and work_horse.snapshot[17] == nil then
                            work_horse.snapshot[17] = oh_link
                        end
                    end

                    local current_link = GetInventoryItemLink("player", slot_id)
                    if tracker:safe_swap_bag_to_inv(bag, slot, slot_id) then
                        if work_horse.snapshot[slot_id] == nil then
                            work_horse.snapshot[slot_id] = current_link or work_horse.EMPTY_SLOT
                        end
                        work_horse.equipped_special[slot_id] = item.id
                        OzGear:debug_msg("Plainrunning: equipped " .. item.name .. " to slot " .. slot_id)
                    end
                    break
                end
            end
        end
    end
end

OzGear.WorkHorse:register_horse("Plainrunning", PlainrunningHorse)
