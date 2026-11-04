OzGear = OzGear or {}
OzGear.Data = OzGear.Data or {}

local Data = OzGear.Data

-- WoW 1.12 standard equipment inventory slot IDs
Data.SLOTS = {
    HEAD      = 1,
    NECK      = 2,
    SHOULDER  = 3,
    SHIRT     = 4,
    CHEST     = 5,
    WAIST     = 6,
    LEGS      = 7,
    FEET      = 8,
    WRIST     = 9,
    HANDS     = 10,
    FINGER1   = 11,
    FINGER2   = 12,
    TRINKET1  = 13,
    TRINKET2  = 14,
    BACK      = 15,
    MAIN_HAND = 16,
    OFF_HAND  = 17,
    RANGED    = 18,
    TABARD    = 19,
}

-- 16 combat equipment slots (excluding Shirt 4 and Tabard 19)
Data.COMBAT_EQUIP_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }

-- S_ItemTip / ItemScore weighted average slot coefficients
Data.SLOT_COEFFICIENTS = {
    [1]  = 1,
    [2]  = 0.5625,
    [3]  = 0.75,
    [5]  = 1,
    [6]  = 0.5625,
    [7]  = 0.75,
    [8]  = 0.75,
    [9]  = 0.75,
    [10] = 0.75,
    [11] = 0.5625,
    [12] = 0.5625,
    [13] = 0.5625,
    [14] = 0.5625,
    [15] = 0.5625,
    [16] = 1,
    [17] = 1,
    [18] = 0.3164,
}

-- S_ItemTip / ItemScore quality scale multipliers
Data.QUALITY_SCALE = {
    [5] = 1.3,
    [4] = 1.0,
    [3] = 0.85,
    [2] = 0.6,
    [1] = 0.25,
}

-- Character Frame slot frame names, alert indices, and short names (Slots 0 to 19)
Data.CHARACTER_SLOTS = {
    [0]  = { name = "CharacterAmmoSlot",          alert = nil, slot_name = "Ammo" },
    [1]  = { name = "CharacterHeadSlot",          alert = 1,   slot_name = "Head" },
    [2]  = { name = "CharacterNeckSlot",          alert = nil, slot_name = "Neck" },
    [3]  = { name = "CharacterShoulderSlot",      alert = 2,   slot_name = "Shoulder" },
    [4]  = { name = "CharacterShirtSlot",         alert = nil, slot_name = "Shirt" },
    [5]  = { name = "CharacterChestSlot",         alert = 3,   slot_name = "Chest" },
    [6]  = { name = "CharacterWaistSlot",         alert = 4,   slot_name = "Waist" },
    [7]  = { name = "CharacterLegsSlot",          alert = 5,   slot_name = "Legs" },
    [8]  = { name = "CharacterFeetSlot",          alert = 6,   slot_name = "Feet" },
    [9]  = { name = "CharacterWristSlot",         alert = 7,   slot_name = "Wrist" },
    [10] = { name = "CharacterHandsSlot",         alert = 8,   slot_name = "Hands" },
    [11] = { name = "CharacterFinger0Slot",       alert = nil, slot_name = "Finger0" },
    [12] = { name = "CharacterFinger1Slot",       alert = nil, slot_name = "Finger1" },
    [13] = { name = "CharacterTrinket0Slot",      alert = nil, slot_name = "Trinket0" },
    [14] = { name = "CharacterTrinket1Slot",      alert = nil, slot_name = "Trinket1" },
    [15] = { name = "CharacterBackSlot",          alert = nil, slot_name = "Back" },
    [16] = { name = "CharacterMainHandSlot",      alert = 9,   slot_name = "MainHand" },
    [17] = { name = "CharacterSecondaryHandSlot", alert = 10,  slot_name = "SecondaryHand" },
    [18] = { name = "CharacterRangedSlot",         alert = 11,  slot_name = "Ranged" },
    [19] = { name = "CharacterTabardSlot",        alert = nil, slot_name = "Tabard" },
}

-- Inspect Frame slot frame names (Slots 1 to 19)
Data.INSPECT_SLOTS = {
    [1]  = "InspectHeadSlot",
    [2]  = "InspectNeckSlot",
    [3]  = "InspectShoulderSlot",
    [4]  = "InspectShirtSlot",
    [5]  = "InspectChestSlot",
    [6]  = "InspectWaistSlot",
    [7]  = "InspectLegsSlot",
    [8]  = "InspectFeetSlot",
    [9]  = "InspectWristSlot",
    [10] = "InspectHandsSlot",
    [11] = "InspectFinger0Slot",
    [12] = "InspectFinger1Slot",
    [13] = "InspectTrinket0Slot",
    [14] = "InspectTrinket1Slot",
    [15] = "InspectBackSlot",
    [16] = "InspectMainHandSlot",
    [17] = "InspectSecondaryHandSlot",
    [18] = "InspectRangedSlot",
    [19] = "InspectTabardSlot",
}

-- Pre-populated dual-casing hex lookup to avoid forbidden string.lower/upper in Lua 5.0
Data.HEX_TO_QUALITY = {
    ["9d9d9d"] = 0, ["9D9D9D"] = 0,
    ["ffffff"] = 1, ["FFFFFF"] = 1,
    ["1eff00"] = 2, ["1EFF00"] = 2,
    ["0070dd"] = 3, ["0070DD"] = 3,
    ["a335ee"] = 4, ["A335EE"] = 4,
    ["ff8000"] = 5, ["FF8000"] = 5,
    ["e6cc80"] = 6, ["E6CC80"] = 6,
}

-- Fallback quality colors in case GetItemQualityColor is unavailable
Data.QUALITY_COLORS = {
    [0] = { 0.62, 0.62, 0.62 }, -- Poor (Gray)
    [1] = { 1.00, 1.00, 1.00 }, -- Common (White)
    [2] = { 0.12, 1.00, 0.00 }, -- Uncommon (Green)
    [3] = { 0.00, 0.44, 0.87 }, -- Rare (Blue)
    [4] = { 0.64, 0.21, 0.93 }, -- Epic (Purple)
    [5] = { 1.00, 0.50, 0.00 }, -- Legendary (Orange)
    [6] = { 0.90, 0.80, 0.502 }, -- Artifact (Red/Gold)
}

-- Quality threshold display names
Data.QUALITY_NAMES = {
    [0] = "Poor+",
    [1] = "Common+",
    [2] = "Uncommon+",
    [3] = "Rare+",
    [4] = "Epic+",
    [5] = "Legendary+",
}

-- Durability alert status codes & colors
Data.DURABILITY_BROKEN = 100   -- Broken item (Red)
Data.DURABILITY_WARNING = 99  -- Low durability warning (Yellow)
Data.DURABILITY_COLORS = {
    [100] = { 0.9, 0.0, 0.0 }, -- Broken: Red
    [99]  = { 1.0, 1.0, 0.0 }, -- Low: Yellow
}

-- Glow visual configuration
Data.GLOW_CONFIG = {
    texture    = "Interface\\Buttons\\UI-ActionButton-Border",
    blend_mode = "ADD",
    alpha      = 0.8,
    width      = 70,
    height     = 70,
}

-- Swimming gear catalog, sorted by slot and priority descending
OzGear.Data.SWIM_SLOTS = {
    {
        slot = 1,
        items = {
            { id = 56023, name = "深海的凝视" },
        }
    },
    {
        slot = 5,
        items = {
            { id = 83494, name = "船长大衣" },
            { id = 42101, name = "鱼人鳞片外套" },
        }
    },
    {
        slot = 6,
        items = {
            { id = 7052,  name = "碧蓝丝质腰带" },
        }
    },
    {
        slot = 8,
        items = {
            { id = 80720, name = "深渊迈步者" },
            { id = 65028, name = "鱼人脚蹼" },
        }
    },
    {
        slot = 16,
        is_two_hand = true,
        items = {
            { id = 60860, name = "流动元素之戟" },
        }
    },
    {
        is_trinket = true,
        candidate_slots = { 14, 13 },
        items = {
            { id = 40061, name = "雷瑟斯潮汐纹章" },
            { id = 60470, name = "凯奇·努恩的冰珠" },
            { id = 58079, name = "珠光碎片" },
        }
    },
}

-- Riding gear catalog, sorted by priority descending
OzGear.Data.RIDING_SLOTS = {
    {
        slot = 8,
        items = {
            { id = 61182, name = "瑟银马刺", enchant = "瑟银马刺", enchant_en = "Thorium Spurs" },
            { id = 58296, name = "软泥行进之靴" },
            { id = 7969,  name = "秘银马刺", enchant = "秘银马刺", enchant_en = "Mithril Spurs", enchant_id = 464 },
        }
    },
    {
        is_trinket = true,
        candidate_slots = { 14, 13 },
        items = {
            { id = 60501, name = "鞭笞马鞭" },
            { id = 11122, name = "棍子上的胡萝卜" },
            { id = 50524, name = "侏儒赛车钥匙" },
            { id = 50525, name = "地精赛车钥匙" },
        }
    },
}

-- Plainsrunning gear catalog (Tauren travel form), sorted by priority descending
OzGear.Data.PLAINRUNNING_SLOTS = {
    {
        slot = 8,
        items = {
            { id = 51284, name = "猞猁之足" },
            { id = 33280, name = "枯萎信使之靴" },
            { id = 20052, name = "高地皮甲长靴" },
            { id = 20186, name = "污染者的皮甲长靴" },
            { id = 20050, name = "高地链甲护胫" },
            { id = 20154, name = "污染者的链甲护胫" },
            { id = 20049, name = "高地板层甲护胫" },
            { id = 20208, name = "污染者的板甲护胫" },
            { id = 20054, name = "高地布质长靴" },
            { id = 20159, name = "污染者的布质长靴" },
        }
    },
    {
        slot = 16,
        is_two_hand = true,
        items = {
            { id = 13505, name = "瑞文戴尔之剑" },
            { id = 60860, name = "流动元素之戟" },
        }
    },
}
