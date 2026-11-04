OzGear = OzGear or {}
OzGear.WorkHorse = OzGear.WorkHorse or {}

local DualWieldHorse = {}
DualWieldHorse.name = "DualWield"

-- 3-step atomic cursor swap between MainHand (16) and OffHand (17)
-- Requires zero bag space and cleanly handles dual weapons with the exact same name or ID
function DualWieldHorse:swap_weapons(tracker)
    if CursorHasItem() then
        tracker:put_cursor_in_bags(16)
    end

    local mh_link = GetInventoryItemLink("player", 16)
    local oh_link = GetInventoryItemLink("player", 17)

    if not mh_link and not oh_link then
        OzGear:debug_msg("DualWield: Both weapon slots are empty.")
        return false
    end

    local orig_mh = mh_link
    local orig_oh = oh_link

    PickupInventoryItem(16)
    if CursorHasItem() then
        PickupInventoryItem(17)
        if CursorHasItem() then
            PickupInventoryItem(16)
        end
    else
        PickupInventoryItem(17)
        if CursorHasItem() then
            PickupInventoryItem(16)
        end
    end

    if CursorHasItem() then
        tracker:put_cursor_in_bags(16)
    end

    local new_mh = GetInventoryItemLink("player", 16)
    local new_oh = GetInventoryItemLink("player", 17)
    if new_mh == orig_oh and new_oh == orig_mh then
        OzGear:debug_msg("DualWield: Swap successful.")
        tracker:mark_dirty()
        return true
    else
        OzGear:debug_msg("DualWield: Partial or blocked swap.")
        tracker:mark_dirty()
        return false
    end
end

OzGear.WorkHorse:register_horse("DualWield", DualWieldHorse)
