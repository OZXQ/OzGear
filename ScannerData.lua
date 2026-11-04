--[[
    ScannerData.lua
    OzGear Built-in Database: Bilingual Patterns, Tokens, Enchants, and Classic Item Levels.
    Supports both zhCN (Simplified Chinese) and enUS (English) clients.
]]

OzGear = OzGear or {}
OzGear.ScannerData = OzGear.ScannerData or {}
local ScannerData = OzGear.ScannerData

-- 1. Lines to instantly discard during tooltip parsing (Zero-cost line rejection)
ScannerData.IGNORE_SUBSTRINGS = {
    "耐久度",
    "Durability",
    "职业：",
    "职业: ",
    "Classes:",
    "需要等级",
    "Requires Level",
    "使用：",
    "使用: ",
    "Use:",
    "灵魂绑定",
    "Soulbound",
    "装备后绑定",
    "Binds when equipped",
    "拾取后绑定",
    "Binds when picked up",
    "唯一",
    "Unique",
    "卖价：",
    "Sell Price:",
    "等级限制",
    "Requires",
    "速度 ",
    "Speed ",
    "每秒伤害",
    "damage per second",
    "击中时可能：",
    "Chance on hit:",
}

-- 2. Direct stat token dictionary for single line lookups like "+15 敏捷" or "+15 Agility"
ScannerData.TOKEN_LOOKUP = {
    -- English
    ["Strength"] = "STR",
    ["Agility"] = "AGI",
    ["Stamina"] = "STA",
    ["Intellect"] = "INT",
    ["Spirit"] = "SPI",
    ["Armor"] = "ARMOR",
    ["Reinforced Armor"] = "ARMOR",
    ["Attack Power"] = "ATTACKPOWER",
    ["Attack Power."] = "ATTACKPOWER",
    ["Ranged Attack Power"] = "RANGEDATTACKPOWER",
    ["All Stats"] = { "STR", "AGI", "STA", "INT", "SPI" },
    ["All Resistances"] = { "ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES" },
    ["Defense"] = "DEFENSE",
    ["Dodge"] = "DODGE",
    ["Parry"] = "PARRY",
    ["Block"] = "BLOCK",
    ["Block Value"] = "BLOCK",
    ["Hit"] = "TOHIT",
    ["Critical Strike"] = "CRIT",
    ["Crit"] = "CRIT",
    ["Spell Critical Strike"] = "SPELLCRIT",
    ["Spell Hit"] = "SPELLTOHIT",
    ["Spell Damage"] = "DMG",
    ["Healing"] = "HEAL",
    ["Healing Spells"] = "HEAL",
    ["Spell Damage and Healing"] = { "DMG", "HEAL" },
    ["Damage and Healing Spells"] = { "DMG", "HEAL" },
    ["Spell Healing and Damage"] = { "DMG", "HEAL" },
    ["Healing and Spell Damage"] = { "DMG", "HEAL" },
    ["Mana Regen"] = "MANAREG",
    ["Health Regen"] = "HEALTHREG",
    ["Fire Resistance"] = "FIRERES",
    ["Nature Resistance"] = "NATURERES",
    ["Frost Resistance"] = "FROSTRES",
    ["Shadow Resistance"] = "SHADOWRES",
    ["Arcane Resistance"] = "ARCANERES",
    ["Mana"] = "MANA",
    ["Health"] = "HEALTH",

    -- Chinese (zhCN)
    ["力量"] = "STR",
    ["敏捷"] = "AGI",
    ["耐力"] = "STA",
    ["智力"] = "INT",
    ["精神"] = "SPI",
    ["护甲"] = "ARMOR",
    ["强化护甲"] = "ARMOR",
    ["护甲值"] = "ARMOR",
    ["所有属性"] = { "STR", "AGI", "STA", "INT", "SPI" },
    ["攻击强度"] = { "ATTACKPOWER", "RANGEDATTACKPOWER" },
    ["攻击强度。"] = { "ATTACKPOWER", "RANGEDATTACKPOWER" },
    ["近战攻击强度"] = "ATTACKPOWER",
    ["远程攻击强度"] = "RANGEDATTACKPOWER",
    ["防御"] = "DEFENSE",
    ["防御技能"] = "DEFENSE",
    ["躲闪"] = "DODGE",
    ["闪避"] = "DODGE",
    ["闪躲"] = "DODGE",
    ["躲避"] = "DODGE",
    ["招架"] = "PARRY",
    ["格挡"] = "BLOCK",
    ["格挡值"] = "BLOCK",
    ["盾牌格挡"] = "BLOCK",
    ["命中"] = "TOHIT",
    ["法术命中"] = "SPELLTOHIT",
    ["致命"] = "CRIT",
    ["致命一击"] = "CRIT",
    ["暴击"] = "CRIT",
    ["法术暴击"] = "SPELLCRIT",
    ["法术致命一击"] = "SPELLCRIT",
    ["法术伤害"] = "DMG",
    ["治疗"] = "HEAL",
    ["治疗效果"] = "HEAL",
    ["法术治疗"] = "HEAL",
    ["治疗法术"] = "HEAL",
    ["法术伤害和治疗"] = { "DMG", "HEAL" },
    ["治疗和法术伤害"] = { "DMG", "HEAL" },
    ["伤害和治疗法术"] = { "DMG", "HEAL" },
    ["法术治疗和伤害"] = { "DMG", "HEAL" },
    ["提高法术伤害"] = "DMG",
    ["提高治疗效果"] = "HEAL",
    ["每5秒回复法力"] = "MANAREG",
    ["每5秒恢复法力"] = "MANAREG",
    ["法力回复"] = "MANAREG",
    ["每5秒回复生命"] = "HEALTHREG",
    ["每5秒恢复生命"] = "HEALTHREG",
    ["所有抗性"] = { "ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES" },
    ["所有魔法抗性"] = { "ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES" },
    ["火焰抗性"] = "FIRERES",
    ["自然抗性"] = "NATURERES",
    ["冰霜抗性"] = "FROSTRES",
    ["暗影抗性"] = "SHADOWRES",
    ["奥术抗性"] = "ARCANERES",
    ["生命值"] = "HEALTH",
    ["法力值"] = "MANA",
    ["急速"] = "HASTE",
    ["护甲穿透"] = "ARMORPENETRATION",
    ["法术穿透"] = "SPELLPENETRATION",
}

-- 3. Passive Equip and Set Bonus Patterns (Bilingual zhCN & enUS)
ScannerData.EQUIP_PATTERNS = {
    -- Critical Strike
    { pattern = "使你造成致命一击的几率提高(%d+)%%", effect = "CRIT" },
    { pattern = "使你打出致命一击的几率提高(%d+)%%", effect = "CRIT" },
    { pattern = "提高你的致命一击几率(%d+)%%", effect = "CRIT" },
    { pattern = "使你的致命一击几率提高(%d+)%%", effect = "CRIT" },
    { pattern = "致命一击几率提高%s*(%d+)%%", effect = "CRIT" },
    { pattern = "Improves your chance to get a critical strike by (%d+)%%", effect = "CRIT" },
    { pattern = "使你的远程武器造成致命一击的几率提高(%d+)%%", effect = "RANGEDCRIT" },
    { pattern = "Improves your chance to get a critical strike with missile weapons by (%d+)%%", effect = "RANGEDCRIT" },

    -- Hit Chance
    { pattern = "使你击中目标的几率提高(%d+)%%", effect = "TOHIT" },
    { pattern = "使你的命中几率提高(%d+)%%", effect = "TOHIT" },
    { pattern = "命中几率提高(%d+)%%", effect = "TOHIT" },
    { pattern = "Improves your chance to hit by (%d+)%%", effect = "TOHIT" },
    { pattern = "使你的物理攻击和法术击中敌人的几率提高(%d)%%", effect = { "TOHIT", "SPELLTOHIT", "RANGEDTOHIT" } },
    { pattern = "Improves your chance to hit with spells and attacks by (%d+)%%", effect = { "TOHIT", "SPELLTOHIT", "RANGEDTOHIT" } },

    -- Spell Hit & Spell Crit
    { pattern = "使你的法术击中敌人的几率提高(%d+)%%", effect = "SPELLTOHIT" },
    { pattern = "提高法术命中几率(%d+)%%", effect = "SPELLTOHIT" },
    { pattern = "Improves your chance to hit with spells by (%d+)%%", effect = "SPELLTOHIT" },
    { pattern = "使你的法术造成致命一击的几率提高(%d+)%%", effect = "SPELLCRIT" },
    { pattern = "提高你的法术造成致命一击的几率(%d+)%%", effect = "SPELLCRIT" },
    { pattern = "提高法术造成致命一击的几率(%d+)%%", effect = "SPELLCRIT" },
    { pattern = "使你的神圣系法术的致命一击和极效治疗几率提高(%d+)%%", effect = "HOLYCRIT" },
    { pattern = "使你的神圣法术造成致命一击的几率提高(%d+)%%", effect = "HOLYCRIT" },
    { pattern = "使你的自然系法术造成致命一击的几率提高(%d+)%%", effect = "NATURECRIT" },
    { pattern = "Improves your chance to get a critical strike with spells by (%d+)%%", effect = "SPELLCRIT" },
    { pattern = "Improves your chance to get a critical strike with Holy spells by (%d+)%%", effect = "HOLYCRIT" },
    { pattern = "Improves your chance to get a critical strike with Nature spells by (%d+)%%", effect = "NATURECRIT" },

    -- Spell Damage and Healing
    { pattern = "提高所有法术和魔法效果所造成的伤害和治疗效果，最多(%d+)点", effect = { "DMG", "HEAL" } },
    { pattern = "提高法术和魔法效果所造成的伤害和治疗效果，最多(%d+)点", effect = { "DMG", "HEAL" } },
    { pattern = "法术伤害和治疗效果增加(%d+)", effect = { "DMG", "HEAL" } },
    { pattern = "Increases damage and healing done by magical spells and effects by up to (%d+)", effect = { "DMG", "HEAL" } },
    { pattern = "提高法术所造成的治疗效果，最多(%d+)点", effect = "HEAL" },
    { pattern = "提高法术和魔法效果所造成的治疗效果，最多(%d+)点", effect = "HEAL" },
    { pattern = "使法术的治疗效果提高最多(%d+)点", effect = "HEAL" },
    { pattern = "使治疗法术和效果所回复的生命值提高(%d+)点", effect = "HEAL" },
    { pattern = "Increases healing done by spells and effects by up to (%d+)", effect = "HEAL" },
    { pattern = "Increases damage done by magical spells and effects by up to (%d+)", effect = "DMG" },

    -- Elemental Spell Damage
    { pattern = "提高奥术法术和效果所造成的伤害，最多(%d+)点", effect = "ARCANEDMG" },
    { pattern = "提高火焰法术和效果所造成的伤害，最多(%d+)点", effect = "FIREDMG" },
    { pattern = "提高冰霜法术和效果所造成的伤害，最多(%d+)点", effect = "FROSTDMG" },
    { pattern = "提高神圣法术和效果所造成的伤害，最多(%d+)点", effect = "HOLYDMG" },
    { pattern = "提高自然法术和效果所造成的伤害，最多(%d+)点", effect = "NATUREDMG" },
    { pattern = "提高暗影法术和效果所造成的伤害，最多(%d+)点", effect = "SHADOWDMG" },
    { pattern = "使暗影法术所造成的伤害提高最多(%d+)点", effect = "SHADOWDMG" },
    { pattern = "使暗影法术和效果所造成的伤害提高(%d+)点", effect = "SHADOWDMG" },
    { pattern = "奥术伤害提高(%d+)", effect = "ARCANEDMG" },
    { pattern = "Increases damage done by Arcane spells and effects by up to (%d+)", effect = "ARCANEDMG" },
    { pattern = "Increases damage done by Fire spells and effects by up to (%d+)", effect = "FIREDMG" },
    { pattern = "Increases damage done by Frost spells and effects by up to (%d+)", effect = "FROSTDMG" },
    { pattern = "Increases damage done by Holy spells and effects by up to (%d+)", effect = "HOLYDMG" },
    { pattern = "Increases damage done by Nature spells and effects by up to (%d+)", effect = "NATUREDMG" },
    { pattern = "Increases damage done by Shadow spells and effects by up to (%d+)", effect = "SHADOWDMG" },

    -- MP5 and HP5 (Regeneration)
    { pattern = "每5秒回复(%d+)点法力值", effect = "MANAREG" },
    { pattern = "每5秒恢复(%d+)点法力值", effect = "MANAREG" },
    { pattern = "Restores (%d+) mana per 5 sec", effect = "MANAREG" },
    { pattern = "Restores (%d+) mana every 5 sec", effect = "MANAREG" },
    { pattern = "每5秒回复(%d+)点生命值", effect = "HEALTHREG" },
    { pattern = "每5秒恢复(%d+)点生命值", effect = "HEALTHREG" },
    { pattern = "Restores (%d+) health per 5 sec", effect = "HEALTHREG" },
    { pattern = "Restores (%d+) health every 5 sec", effect = "HEALTHREG" },
    { pattern = "使你的生命值和法力值回复提高(%d+)点", effect = { "MANAREG", "HEALTHREG" } },

    -- Defensive & Shield
    { pattern = "防御技能提高(%d+)点", effect = "DEFENSE" },
    { pattern = "防御增加(%d+)点", effect = "DEFENSE" },
    { pattern = "Increased Defense %+(%d+)", effect = "DEFENSE" },
    { pattern = "Increases Defense by (%d+)", effect = "DEFENSE" },
    { pattern = "使你躲闪攻击的几率提高(%d+)%%", effect = "DODGE" },
    { pattern = "Increases your chance to dodge an attack by (%d+)%%", effect = "DODGE" },
    { pattern = "使你招架攻击的几率提高(%d+)%%", effect = "PARRY" },
    { pattern = "Increases your chance to parry an attack by (%d+)%%", effect = "PARRY" },
    { pattern = "使你用盾牌格挡攻击的几率提高(%d+)%%", effect = "TOBLOCK" },
    { pattern = "使你的盾牌格挡几率提高(%d+)%%", effect = "TOBLOCK" },
    { pattern = "Increases your chance to block attacks with a shield by (%d+)%%", effect = "TOBLOCK" },
    { pattern = "使你的盾牌的格挡值提高(%d+)点", effect = "BLOCK" },
    { pattern = "使你的盾牌格挡值提高(%d+)点", effect = "BLOCK" },
    { pattern = "格挡值提高(%d+)点", effect = "BLOCK" },
    { pattern = "Increases the block value of your shield by (%d+)", effect = "BLOCK" },
    { pattern = "(%d+)点格挡", effect = "BLOCK" },
    { pattern = "(%d+)格挡", effect = "BLOCK" },

    -- Attack Power
    { pattern = "%+(%d+) 攻击强度", effect = { "ATTACKPOWER", "RANGEDATTACKPOWER" } },
    { pattern = "攻击强度提高(%d+)点", effect = { "ATTACKPOWER", "RANGEDATTACKPOWER" } },
    { pattern = "%+(%d+) Attack Power", effect = { "ATTACKPOWER", "RANGEDATTACKPOWER" } },
    { pattern = "Increases Attack Power by (%d+)", effect = { "ATTACKPOWER", "RANGEDATTACKPOWER" } },
    { pattern = "%+(%d+) 远程攻击强度", effect = "RANGEDATTACKPOWER" },
    { pattern = "%+(%d+) ranged Attack Power", effect = "RANGEDATTACKPOWER" },
    { pattern = "在猎豹、熊、巨熊或枭兽形态下的攻击强度提高(%d+)点", effect = "ATTACKPOWER" },
    { pattern = "%+(%d+) Attack Power in Cat, Bear, Dire Bear, and Moonkin forms only", effect = "ATTACKPOWER" },
    { pattern = "与亡灵作战时的攻击强度提高(%d+)点", effect = "ATTACKPOWERUNDEAD" },

    -- Armor Penetration & Spell Penetration & Haste
    { pattern = "你的攻击无视目标(%d+)点护甲", effect = "ARMORPENETRATION" },
    { pattern = "Your attacks ignore (%d+) of the target's armor", effect = "ARMORPENETRATION" },
    { pattern = "%+(%d+) 护甲穿透", effect = "ARMORPENETRATION" },
    { pattern = "使你的法术目标的魔法抗性降低(%d+)点", effect = "SPELLPENETRATION" },
    { pattern = "将你的法术目标的魔法抗性降低(%d+)点", effect = "SPELLPENETRATION" },
    { pattern = "Decreases the magical resistances of your spell targets by (%d+)", effect = "SPELLPENETRATION" },
    { pattern = "%+(%d+) 法术穿透", effect = "SPELLPENETRATION" },
    { pattern = "使你的攻击速度和施法速度提高(%d+)%%", effect = "HASTE" },
    { pattern = "使你的攻击和施法速度提高(%d+)%%", effect = "HASTE" },
    { pattern = "Increases your attack and casting speed by (%d+)%%", effect = "HASTE" },
    { pattern = "%+(%d+)%% 急速", effect = "HASTE" },

    -- Weapon Skills
    { pattern = "双手剑技能提高(%d+)点", effect = "WEAPONSKILL_TWOHAND_SWORD" },
    { pattern = "双手斧技能提高(%d+)点", effect = "WEAPONSKILL_TWOHAND_AXE" },
    { pattern = "双手锤技能提高(%d+)点", effect = "WEAPONSKILL_TWOHAND_MACE" },
    { pattern = "单手剑技能提高(%d+)点", effect = "WEAPONSKILL_ONEHAND_SWORD" },
    { pattern = "单手斧技能提高(%d+)点", effect = "WEAPONSKILL_ONEHAND_AXE" },
    { pattern = "单手锤技能提高(%d+)点", effect = "WEAPONSKILL_ONEHAND_MACE" },
    { pattern = "匕首技能提高(%d+)点", effect = "WEAPONSKILL_DAGGER" },
    { pattern = "长柄武器技能提高(%d+)点", effect = "WEAPONSKILL_POLEARMS" },
    { pattern = "徒手战斗技能提高(%d+)点", effect = "WEAPONSKILL_FIST" },
    { pattern = "Increased Two%-handed Swords %+(%d+)", effect = "WEAPONSKILL_TWOHAND_SWORD" },
    { pattern = "Increased Two%-handed Axes %+(%d+)", effect = "WEAPONSKILL_TWOHAND_AXE" },
    { pattern = "Increased Two%-handed Maces %+(%d+)", effect = "WEAPONSKILL_TWOHAND_MACE" },
    { pattern = "Increased Swords %+(%d+)", effect = "WEAPONSKILL_ONEHAND_SWORD" },
    { pattern = "Increased Axes %+(%d+)", effect = "WEAPONSKILL_ONEHAND_AXE" },
    { pattern = "Increased Maces %+(%d+)", effect = "WEAPONSKILL_ONEHAND_MACE" },
    { pattern = "Increased Daggers %+(%d+)", effect = "WEAPONSKILL_DAGGER" },
    { pattern = "Increased Polearms %+(%d+)", effect = "WEAPONSKILL_POLEARMS" },
    { pattern = "Increased Fist Weapons %+(%d+)", effect = "WEAPONSKILL_FIST" },
}

-- 4. Fixed Text Patterns (ZG enchants, oils, multi-stat enchants)
ScannerData.FIXED_PATTERNS = {
    { pattern = "赞达拉魔力徽章", stats = { DMG = 18, HEAL = 18 } },
    { pattern = "赞达拉魔精徽记", stats = { DMG = 18, HEAL = 18 } },
    { pattern = "Zandalar Signet of Mojo", stats = { DMG = 18, HEAL = 18 } },
    { pattern = "赞达拉宁静徽章", stats = { HEAL = 33 } },
    { pattern = "赞达拉宁静徽记", stats = { HEAL = 33 } },
    { pattern = "Zandalar Signet of Serenity", stats = { HEAL = 33 } },
    { pattern = "赞达拉力量徽章", stats = { ATTACKPOWER = 30, RANGEDATTACKPOWER = 30 } },
    { pattern = "赞达拉力量徽记", stats = { ATTACKPOWER = 30, RANGEDATTACKPOWER = 30 } },
    { pattern = "Zandalar Signet of Might", stats = { ATTACKPOWER = 30, RANGEDATTACKPOWER = 30 } },
    { pattern = "卓越巫师之油", stats = { DMG = 36, HEAL = 36, SPELLCRIT = 1 } },
    { pattern = "Brilliant Wizard Oil", stats = { DMG = 36, HEAL = 36, SPELLCRIT = 1 } },
    { pattern = "卓越法力之油", stats = { MANAREG = 12, HEAL = 25 } },
    { pattern = "Brilliant Mana Oil", stats = { MANAREG = 12, HEAL = 25 } },
    { pattern = "巫师之油", stats = { DMG = 24, HEAL = 24 } },
    { pattern = "Wizard Oil", stats = { DMG = 24, HEAL = 24 } },
    { pattern = "次级巫师之油", stats = { DMG = 16, HEAL = 16 } },
    { pattern = "Lesser Wizard Oil", stats = { DMG = 16, HEAL = 16 } },
    { pattern = "初级巫师之油", stats = { DMG = 8, HEAL = 8 } },
    { pattern = "Minor Wizard Oil", stats = { DMG = 8, HEAL = 8 } },
    { pattern = "法力之油", stats = { MANAREG = 8 } },
    { pattern = "Mana Oil", stats = { MANAREG = 8 } },
    { pattern = "次级法力之油", stats = { MANAREG = 8 } },
    { pattern = "Lesser Mana Oil", stats = { MANAREG = 8 } },
    { pattern = "初级法力之油", stats = { MANAREG = 4 } },
    { pattern = "Minor Mana Oil", stats = { MANAREG = 4 } },
    { pattern = "法术伤害%+15点，法术致命一击率%+1%%", stats = { DMG = 15, HEAL = 15, SPELLCRIT = 1 } },
    { pattern = "治疗%+31点，每5秒回复5点法力值", stats = { HEAL = 31, MANAREG = 5 } },
    { pattern = "耐力%+16点，护甲%+100点", stats = { STA = 16, ARMOR = 100 } },
    { pattern = "攻击强度%+26点，致命一击率%+1%%", stats = { ATTACKPOWER = 26, RANGEDATTACKPOWER = 26, CRIT = 1 } },
    { pattern = "恒金渔线", stats = { FISHING = 5 } },
}

-- 5. Direct Enchant ID Lookup Table (O(1) Integer Map)
-- Item link format: item:itemId:enchantId:suffixId:uniqueId
ScannerData.ENCHANT_LOOKUP = {
    [15] = { ARMOR = 8, STA = 1 },     -- Light Armor Kit
    [16] = { ARMOR = 16, STA = 2 },    -- Medium Armor Kit
    [17] = { ARMOR = 24, STA = 3 },    -- Heavy Armor Kit
    [18] = { ARMOR = 32, STA = 4 },    -- Thick Armor Kit
    [24] = { MANA = 5 },               -- Minor Mana (Chest)
    [28] = { ARCANERES = 4, FIRERES = 4, FROSTRES = 4, NATURERES = 4, SHADOWRES = 4 },
    [30] = { DMG = 1 },                -- Crude Scope
    [32] = { DMG = 2 },                -- Standard Scope
    [33] = { DMG = 3 },                -- Accurate Scope
    [34] = { HASTE = 3 },              -- Iron Counterweight
    [43] = { BLOCK = 0 },              -- Iron Shield Spike
    [65] = { ARCANERES = 1, FIRERES = 1, FROSTRES = 1, NATURERES = 1, SHADOWRES = 1 },
    [68] = { STR = 1 },                -- Minor Strength
    [80] = { INT = 3 },                -- Minor Intellect (2H)
    [242] = { HEALTH = 25 },           -- Lesser Health (Chest)
    [243] = { SPI = 1 },               -- Minor Spirit (Bracer)
    [246] = { MANA = 20 },             -- Lesser Mana (Chest)
    [248] = { STR = 1 },               -- Minor Strength
    [254] = { HEALTH = 35 },           -- Health (Chest)
    [256] = { FIRERES = 5 },           -- Lesser Fire Resistance (Cloak)
    [354] = { INT = 5 },               -- Greater Intellect (Boots)
    [357] = { STR = 7 },               -- Greater Strength (Gloves)
    [370] = { SPI = 7 },               -- Greater Spirit (Boots)
    [432] = { DMG = 7, HEAL = 7 },     -- Spell Damage (Bracer)
    [463] = { BLOCK = 0 },             -- Mithril Shield Spike
    [663] = { DMG = 5 },               -- Deadly Scope
    [664] = { DMG = 7 },               -- Sniper Scope
    [744] = { ARMOR = 20 },            -- Lesser Protection (Cloak)
    [783] = { ARMOR = 10 },            -- Minor Protection (Cloak)
    [804] = { SHADOWRES = 10 },        -- Lesser Shadow Resistance (Cloak)
    [805] = { DMG = 4 },               -- Greater Impact (Weapon)
    [823] = { STR = 3 },               -- Lesser Strength (Bracer)
    [843] = { MANA = 30 },             -- Mana (Chest)
    [847] = { STR = 1, AGI = 1, STA = 1, INT = 1, SPI = 1 }, -- Minor Stats (Chest)
    [850] = { HEALTH = 50 },           -- Greater Health (Chest)
    [857] = { MANA = 50 },             -- Greater Mana (Chest)
    [863] = { TOBLOCK = 2 },           -- Lesser Block (Shield)
    [866] = { STR = 2, AGI = 2, STA = 2, INT = 2, SPI = 2 }, -- Lesser Stats (Chest)
    [884] = { ARMOR = 30 },            -- Greater Defense (Cloak)
    [903] = { ARCANERES = 3, FIRERES = 3, FROSTRES = 3, NATURERES = 3, SHADOWRES = 3 },
    [905] = { INT = 3 },               -- Intellect (Bracer)
    [908] = { HEALTH = 75 },           -- Superior Health (Chest)
    [910] = { STEALTH = 5 },           -- Stealth (Cloak)
    [911] = { HASTE = 0 },             -- Minor Speed (Boots)
    [913] = { MANA = 65 },             -- Superior Mana (Chest)
    [923] = { DEFENSE = 3 },           -- Deflection (Bracer)
    [924] = { DEFENSE = 1 },           -- Minor Deflection (Bracer)
    [925] = { DEFENSE = 2 },           -- Lesser Deflection (Bracer)
    [926] = { FROSTRES = 8 },          -- Frost Resistance (Shield)
    [928] = { STR = 3, AGI = 3, STA = 3, INT = 3, SPI = 3 }, -- Stats (Chest)
    [930] = { RIDING = 1 },            -- Riding Skill (Gloves)
    [931] = { HASTE = 1 },             -- Minor Haste (Gloves)
    [963] = { DMG = 7 },               -- Greater Impact (2H)
    [1068] = { STA = 7 },              -- Greater Stamina (Boots)
    [1257] = { ARCANERES = 15 },       -- Greater Arcane Res (Cloak)
    [1503] = { HEALTH = 100 },         -- Lesser Arcanum of Constitution
    [1504] = { ARMOR = 125 },          -- Lesser Arcanum of Tenacity
    [1505] = { FIRERES = 20 },         -- Lesser Arcanum of Resilience
    [1506] = { STR = 8 },              -- Lesser Arcanum of Voracity (STR)
    [1507] = { AGI = 8 },              -- Lesser Arcanum of Voracity (AGI)
    [1508] = { STA = 8 },              -- Lesser Arcanum of Voracity (STA)
    [1509] = { INT = 8 },              -- Lesser Arcanum of Voracity (INT)
    [1510] = { SPI = 8 },              -- Lesser Arcanum of Voracity (SPI)
    [1883] = { INT = 7 },              -- Greater Intellect (Bracer)
    [1884] = { SPI = 9 },              -- Superior Spirit (Bracer)
    [1885] = { STR = 9 },              -- Superior Strength (Bracer)
    [1886] = { STA = 9 },              -- Superior Stamina (Bracer)
    [1888] = { ARCANERES = 5, FIRERES = 5, FROSTRES = 5, NATURERES = 5, SHADOWRES = 5 }, -- Greater Resistance (Cloak)
    [1889] = { ARMOR = 70 },           -- Superior Defense (Cloak)
    [1890] = { STA = 7 },              -- Greater Stamina (Boots)
    [1891] = { STR = 4, AGI = 4, STA = 4, INT = 4, SPI = 4 }, -- Greater Stats (Chest)
    [1892] = { HEALTH = 100 },         -- Major Health (Chest)
    [1893] = { MANA = 100 },           -- Major Mana (Chest)
    [1894] = { DMG = 0 },              -- Icy Chill
    [1896] = { DMG = 9 },              -- Superior Impact (2H)
    [1898] = { LIFEDRAIN = 1 },        -- Lifestealing
    [1899] = { DMG = 0 },              -- Unholy Weapon
    [1900] = { STR = 0 },              -- Crusader
    [1903] = { SPI = 9 },              -- Major Spirit (2H)
    [1904] = { INT = 9 },              -- Major Intellect (2H)
    [2443] = { FROSTDMG = 7 },         -- Winter's Might
    [2463] = { FIRERES = 7 },          -- Fire Resistance (Cloak)
    [2483] = { FIRERES = 5 },          -- Flame Dawn Mantle
    [2484] = { FROSTRES = 5 },         -- Frost Dawn Mantle
    [2485] = { ARCANERES = 5 },        -- Arcane Dawn Mantle
    [2486] = { NATURERES = 5 },        -- Nature Dawn Mantle
    [2487] = { SHADOWRES = 5 },        -- Shadow Dawn Mantle
    [2488] = { ARCANERES = 5, FIRERES = 5, FROSTRES = 5, NATURERES = 5, SHADOWRES = 5 },
    [2503] = { ARMOR = 40, STA = 5 },  -- Molten Armor Kit
    [2504] = { DMG = 30, HEAL = 30 },  -- Spell Power (Weapon)
    [2505] = { HEAL = 55 },            -- Healing Power (Weapon)
    [2523] = { TOHIT = 3, RANGEDTOHIT = 3 }, -- Biznicks Accurascope
    [2543] = { HASTE = 1 },            -- Arcanum of Rapidity
    [2544] = { DMG = 8, HEAL = 8 },    -- Arcanum of Focus
    [2545] = { DODGE = 1 },            -- Arcanum of Protection
    [2563] = { STR = 15 },             -- Strength (Weapon)
    [2564] = { AGI = 15 },             -- Agility (Weapon)
    [2565] = { MANAREG = 4 },          -- Mana Regeneration (Bracer)
    [2566] = { HEAL = 24 },            -- Healing Power (Bracer)
    [2567] = { SPI = 20 },             -- Mighty Spirit (Weapon)
    [2568] = { INT = 22 },             -- Mighty Intellect (Weapon)
    [2583] = { ATTACKPOWER = 30, RANGEDATTACKPOWER = 30 }, -- Zandalar Signet of Might
    [2584] = { ATTACKPOWER = 28, DODGE = 1 },
    [2587] = { HEAL = 24, STA = 10 },
    [2588] = { DMG = 18, HEAL = 18 },  -- Zandalar Signet of Mojo
    [2590] = { HEAL = 33 },            -- Zandalar Signet of Serenity
    [2604] = { HEAL = 33 },            -- Zandalar Signet of Serenity
    [2605] = { DMG = 18, HEAL = 18 },  -- Zandalar Signet of Mojo
    [2606] = { ATTACKPOWER = 30, RANGEDATTACKPOWER = 30 }, -- Zandalar Signet of Might
    [2681] = { NATURERES = 10 },       -- Savage Guard
    [2682] = { FROSTRES = 10 },        -- Ice Guard
    [2683] = { SHADOWRES = 10 },       -- Shadow Guard
    [2715] = { STA = 16, ARMOR = 100 },-- Scourge's Vitality
    [2716] = { ATTACKPOWER = 26, RANGEDATTACKPOWER = 26, CRIT = 1 }, -- Scourge's Resilience
    [2717] = { DMG = 15, HEAL = 15, SPELLCRIT = 1 },                -- Scourge's Sight
    [2721] = { HEAL = 31, MANAREG = 5 },                             -- Scourge's Power
}

-- 6. Self-Contained Classic Raid / Dungeon / PvP Item Level Catalog
-- Provides instant fallback if SuperWoW is disabled or local client DBC has not loaded.
ScannerData.ITEM_LEVEL_CATALOG = {
    -- Tier 1 Sets (Molten Core - ilvl 66)
    [16820] = 66, [16821] = 66, [16822] = 66, [16823] = 66, [16824] = 66, [16825] = 66, [16826] = 66, [16827] = 66, -- Nightslayer
    [16833] = 66, [16834] = 66, [16835] = 66, [16836] = 66, [16837] = 66, [16838] = 66, [16839] = 66, [16840] = 66, -- Cenarion
    [16845] = 66, [16846] = 66, [16847] = 66, [16848] = 66, [16849] = 66, [16850] = 66, [16851] = 66, [16852] = 66, -- Giantstalker
    [16795] = 66, [16796] = 66, [16797] = 66, [16798] = 66, [16799] = 66, [16800] = 66, [16801] = 66, [16802] = 66, -- Arcanist
    [16811] = 66, [16812] = 66, [16813] = 66, [16814] = 66, [16815] = 66, [16816] = 66, [16817] = 66, [16818] = 66, -- Prophecy
    [16804] = 66, [16805] = 66, [16806] = 66, [16807] = 66, [16808] = 66, [16809] = 66, [16810] = 66, [16803] = 66, -- Felheart
    [16861] = 66, [16862] = 66, [16863] = 66, [16864] = 66, [16865] = 66, [16866] = 66, [16867] = 66, [16868] = 66, -- Might
    [16853] = 66, [16854] = 66, [16855] = 66, [16856] = 66, [16857] = 66, [16858] = 66, [16859] = 66, [16860] = 66, -- Lawbringer
    [16841] = 66, [16842] = 66, [16843] = 66, [16844] = 66, [16837] = 66, [16838] = 66, [16839] = 66, [16840] = 66, -- Earthfury

    -- Tier 2 Sets (Blackwing Lair / Ragnaros / Onyxia - ilvl 76)
    [16905] = 76, [16906] = 76, [16907] = 76, [16908] = 76, [16909] = 76, [16910] = 76, [16911] = 76, [16832] = 76, -- Bloodfang
    [16897] = 76, [16898] = 76, [16899] = 76, [16900] = 76, [16901] = 76, [16902] = 76, [16903] = 76, [16904] = 76, -- Stormrage
    [16935] = 76, [16936] = 76, [16937] = 76, [16938] = 76, [16939] = 76, [16940] = 76, [16941] = 76, [16942] = 76, -- Dragonstalker
    [16912] = 76, [16913] = 76, [16914] = 76, [16915] = 76, [16916] = 76, [16917] = 76, [16918] = 76, [16919] = 76, -- Netherwind
    [16920] = 76, [16921] = 76, [16922] = 76, [16923] = 76, [16924] = 76, [16925] = 76, [16926] = 76, [16927] = 76, -- Transcendence
    [16928] = 76, [16929] = 76, [16930] = 76, [16931] = 76, [16932] = 76, [16933] = 76, [16934] = 76, [16935] = 76, -- Nemesis
    [16959] = 76, [16960] = 76, [16961] = 76, [16962] = 76, [16963] = 76, [16964] = 76, [16965] = 76, [16966] = 76, -- Wrath
    [16951] = 76, [16952] = 76, [16953] = 76, [16954] = 76, [16955] = 76, [16956] = 76, [16957] = 76, [16958] = 76, -- Judgement
    [16943] = 76, [16944] = 76, [16945] = 76, [16946] = 76, [16947] = 76, [16948] = 76, [16949] = 76, [16950] = 76, -- Ten Storms

    -- Tier 2.5 Sets (Ahn'Qiraj 40 - ilvl 78 to 81)
    [21359] = 78, [21360] = 78, [21361] = 81, [21362] = 78, [21364] = 78, -- Deathdealer
    [21353] = 78, [21354] = 78, [21355] = 81, [21356] = 78, [21357] = 78, -- Genesis
    [21365] = 78, [21366] = 78, [21367] = 81, [21368] = 78, [21370] = 78, -- Striker's
    [21343] = 78, [21344] = 78, [21345] = 81, [21346] = 78, [21348] = 78, -- Enigma
    [21349] = 78, [21350] = 78, [21351] = 81, [21352] = 78, [21358] = 78, -- Oracle
    [21334] = 78, [21335] = 78, [21336] = 81, [21337] = 78, [21338] = 78, -- Doomcaller
    [21329] = 78, [21330] = 78, [21331] = 81, [21332] = 78, [21333] = 78, -- Conqueror
    [21387] = 78, [21388] = 78, [21389] = 81, [21390] = 78, [21391] = 78, -- Avenger
    [21372] = 78, [21373] = 78, [21374] = 81, [21375] = 78, [21376] = 78, -- Stormcaller

    -- Tier 3 Sets (Naxxramas - ilvl 86 to 90)
    [22476] = 86, [22477] = 86, [22478] = 86, [22479] = 86, [22480] = 86, [22481] = 86, [22482] = 86, [22483] = 86, [23063] = 86, -- Bonescythe
    [22488] = 86, [22489] = 86, [22490] = 86, [22491] = 86, [22492] = 86, [22493] = 86, [22494] = 86, [22495] = 86, [23064] = 86, -- Dreamwalker
    [22436] = 86, [22437] = 86, [22438] = 86, [22439] = 86, [22440] = 86, [22441] = 86, [22442] = 86, [22443] = 86, [23067] = 86, -- Cryptstalker
    [22496] = 86, [22497] = 86, [22498] = 86, [22499] = 86, [22500] = 86, [22501] = 86, [22502] = 86, [22503] = 86, [23062] = 86, -- Frostfire
    [22512] = 86, [22513] = 86, [22514] = 86, [22515] = 86, [22516] = 86, [22517] = 86, [22518] = 86, [22519] = 86, [23061] = 86, -- Faith
    [22504] = 86, [22505] = 86, [22506] = 86, [22507] = 86, [22508] = 86, [22509] = 86, [22510] = 86, [22511] = 86, [23065] = 86, -- Plagueheart
    [22416] = 86, [22417] = 86, [22418] = 86, [22419] = 86, [22420] = 86, [22421] = 86, [22422] = 86, [22423] = 86, [23059] = 86, -- Dreadnaught
    [22424] = 86, [22425] = 86, [22426] = 86, [22427] = 86, [22428] = 86, [22429] = 86, [22430] = 86, [22431] = 86, [23066] = 86, -- Redemption
    [22464] = 86, [22465] = 86, [22466] = 86, [22467] = 86, [22468] = 86, [22469] = 86, [22470] = 86, [22471] = 86, [23060] = 86, -- Earthshatter

    -- Tier 0 Sets (Dungeon Blues - ilvl 58 to 62)
    [16674] = 60, [16675] = 60, [16676] = 60, [16677] = 60, [16678] = 60, [16679] = 60, [16680] = 60, [16681] = 60, -- Shadowcraft
    [16698] = 60, [16699] = 60, [16700] = 60, [16701] = 60, [16702] = 60, [16703] = 60, [16704] = 60, [16705] = 60, -- Wildheart
    [16682] = 60, [16683] = 60, [16684] = 60, [16685] = 60, [16686] = 60, [16687] = 60, [16688] = 60, [16689] = 60, -- Magister's
    [16690] = 60, [16691] = 60, [16692] = 60, [16693] = 60, [16694] = 60, [16695] = 60, [16696] = 60, [16697] = 60, -- Devout
    [16730] = 60, [16731] = 60, [16732] = 60, [16733] = 60, [16734] = 60, [16735] = 60, [16736] = 60, [16737] = 60, -- Valor
    [16721] = 60, [16722] = 60, [16723] = 60, [16724] = 60, [16725] = 60, [16726] = 60, [16727] = 60, [16728] = 60, -- Lightforge
    [16666] = 60, [16667] = 60, [16668] = 60, [16669] = 60, [16670] = 60, [16671] = 60, [16672] = 60, [16673] = 60, -- Elements

    -- Tier 0.5 Sets (Dungeon Upgrade Epics/Blues - ilvl 65 to 68)
    [22002] = 68, [22003] = 68, [22004] = 68, [22005] = 68, [22006] = 68, [22007] = 68, [22008] = 68, [22009] = 68, -- Darkmantle
    [22106] = 68, [22107] = 68, [22108] = 68, [22109] = 68, [22110] = 68, [22111] = 68, [22112] = 68, [22113] = 68, -- Feralheart
    [22010] = 68, [22011] = 68, [22012] = 68, [22013] = 68, [22014] = 68, [22015] = 68, [22016] = 68, [22017] = 68, -- Beastmaster
    [22062] = 68, [22063] = 68, [22064] = 68, [22065] = 68, [22066] = 68, [22067] = 68, [22068] = 68, [22069] = 68, -- Sorcerer's
    [22078] = 68, [22079] = 68, [22080] = 68, [22081] = 68, [22082] = 68, [22083] = 68, [22084] = 68, [22085] = 68, -- Virtuous
    [22070] = 68, [22071] = 68, [22072] = 68, [22073] = 68, [22074] = 68, [22075] = 68, [22076] = 68, [22077] = 68, -- Deathmist
    [21994] = 68, [21995] = 68, [21996] = 68, [21997] = 68, [21998] = 68, [21999] = 68, [22000] = 68, [22001] = 68, -- Heroism
    [22086] = 68, [22087] = 68, [22088] = 68, [22089] = 68, [22090] = 68, [22091] = 68, [22092] = 68, [22093] = 68, -- Soulforge
    [22094] = 68, [22095] = 68, [22096] = 68, [22097] = 68, [22098] = 68, [22099] = 68, [22100] = 68, [22101] = 68, -- Five Thunders

    -- Zul'Gurub Sets & Rewards (ilvl 65 to 68)
    [19828] = 65, [19829] = 65, [19830] = 65, [19956] = 68, [19957] = 68, -- Madcap's
    [19838] = 65, [19839] = 65, [19840] = 65, [19958] = 68, [19959] = 68, -- Haruspex's
    [19831] = 65, [19832] = 65, [19833] = 65, [19960] = 68, [19961] = 68, -- Predator's
    [19844] = 65, [19845] = 65, [19846] = 65, [19962] = 68, [19963] = 68, -- Illusionist's
    [19841] = 65, [19842] = 65, [19843] = 65, [19964] = 68, [19965] = 68, -- Confessor's
    [19847] = 65, [19848] = 65, [19849] = 65, [19966] = 68, [19967] = 68, -- Demoniac's
    [19822] = 65, [19823] = 65, [19824] = 65, [19968] = 68, [19969] = 68, -- Vindicator's
    [19825] = 65, [19826] = 65, [19827] = 65, [19970] = 68, [19971] = 68, -- Freethinker's
    [19834] = 65, [19835] = 65, [19836] = 65, [19972] = 68, [19973] = 68, -- Augur's
    [19896] = 65, [19910] = 65,                                           -- The Twin Blades of Hakkar / Primal Blessing
    [19717] = 68, [19718] = 68, [19719] = 68, [19720] = 68,               -- ZG Heart / Head trinkets

    -- PvP Honor Gear (Ranks 10, 12, 13, 14 - ilvl 65 to 74)
    [16453] = 71, [16454] = 71, [16455] = 71, [16456] = 71, [16457] = 71, [16458] = 71, -- Field Marshal / Warlord
    [18844] = 74, [18843] = 74, [18847] = 74, [18838] = 74, [18827] = 74, [18836] = 74, -- Grand Marshal / High Warlord Weapons
    [18831] = 74, [18842] = 74, [18837] = 74, [18835] = 74, [18840] = 74,

    -- Iconic Classic Raid Weapons & Trinkets
    [17182] = 80, -- Sulfuras, Hand of Ragnaros
    [19019] = 80, -- Thunderfury, Blessed Blade of the Windseeker
    [22589] = 90, -- Atiesh (Mage)
    [22630] = 90, -- Atiesh (Warlock)
    [22631] = 90, -- Atiesh (Priest)
    [22632] = 90, -- Atiesh (Druid)
    [19364] = 81, -- Ashkandi, Greatsword of the Brotherhood
    [19379] = 83, -- Neltharion's Tear
    [19406] = 77, -- Drake Fang Talisman
    [19360] = 83, -- Lok'amir il Romathis
    [19356] = 83, -- Staff of the Shadow Flame
    [19365] = 77, -- Claw of the Black Drake
    [19351] = 77, -- Chromatically Tempered Sword
    [19352] = 77, -- Maladath, Runed Blade of the Black Flight
    [18832] = 66, -- Brutality Blade
    [18805] = 66, -- Core Hound Tooth
    [18816] = 73, -- Perdition's Blade
    [17068] = 75, -- Deathbringer
    [17075] = 69, -- Vis'kag the Bloodletter
    [18348] = 66, -- Quel'Serrar
    [18423] = 66, -- Head of Onyxia (Bloodcaller / Tooth of Gnarr)
    [19377] = 77, -- Prestor's Talisman of Connivery
    [19382] = 77, -- Pure Elementium Band
    [19376] = 77, -- Archimtiros' Ring of Reckoning
    [21134] = 81, -- Dark Edge of Insanity
    [21581] = 88, -- Gauntlets of Annihilation
    [22812] = 85, -- Nerubian Slavemaker
    [22807] = 83, -- The Castigator
    [23054] = 89, -- Gressil, Dawn of Ruin
    [23014] = 83, -- Iblis, Blade of the Fallen Seraph
    [23577] = 83, -- The Hungering Cold
    [23056] = 89, -- Kingsfall
    [22691] = 86, -- Corrupted Ashbringer
    [19288] = 66, -- Darkmoon Card: Blue Dragon
    [19289] = 66, -- Darkmoon Card: Maelstrom
    [19290] = 66, -- Darkmoon Card: Heroism
    [19291] = 66, -- Darkmoon Card: Twisting Nether
}
