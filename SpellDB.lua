local Blackjack = _G.Blackjack
local bit = bit

-- Spell type constants for better readability
local SPELL_FLAGS = {
    INTERRUPT = 1,
    DISPEL = 2,
    PURGE = 4,
    BUFF = 8,
    DEBUFF = 16,
    PERSONAL = 32
}

-- Helper function for debugging
local function getTableKeys(tbl)
    local keys = {}
    for k, v in pairs(tbl) do
        table.insert(keys, tostring(k))
    end
    table.sort(keys) -- Sort for consistent output
    return table.concat(keys, ", ")
end

local SpellDB = {
    data = {},
    spellNames = {},
    flags = {}
}

function SpellDB:OnInitialize(db)
    self.db = db
    if Blackjack:IsDebugEnabled() then
        print("SpellDB: Initializing spell database")
    end

    -- Load spell data
    self:LoadSpellData()
end

function SpellDB:LoadSpellData()
    -- Initialize flags for spell classification
    self.flags = SPELL_FLAGS

    -- Load all spells from the config system
    self:LoadAllSpellsFromConfig()

    if Blackjack:IsDebugEnabled() then
        local spellCount = self:GetSpellCount()
        print("SpellDB: Loaded", spellCount, "spells")

        local interruptCount = 0
        for _, spellData in pairs(self.data) do
            if spellData.type == "interrupt" then
                interruptCount = interruptCount + 1
            end
        end
        print("SpellDB: Including", interruptCount, "interrupt spells")
    end
end

function SpellDB:LoadAllSpellsFromConfig()
    -- Get all spells from the config
    local allSpells = {}
    local classList = {"WARRIOR", "DEATHKNIGHT", "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK"}

    for _, className in ipairs(classList) do
        local classSpells = self:GetSpellsForClass(className)
        if classSpells then
            for _, spellData in ipairs(classSpells) do
                allSpells[spellData.id] = {name = spellData.name, type = spellData.type}
            end
        end
    end

    -- Load spells into database
    for spellId, spellData in pairs(allSpells) do
        local name, _, _, _, _, _, _, _, _, texture = GetSpellInfo(spellId)
        if name then
            self.data[spellId] = {
                name = name,
                texture = texture,
                flags = self:GetFlagsForType(spellData.type),
                type = spellData.type
            }
            self.spellNames[name:lower()] = spellId
        else
            if Blackjack:IsDebugEnabled() then
                Blackjack:DebugMessage("Could not get spell info for ID: " .. spellId .. " expected: " .. spellData.name)
            end
        end
    end
end


function SpellDB:GetSpellType(flags)
    if bit.band(flags, self.flags.DEBUFF) ~= 0 then
        return "offensive"
    elseif bit.band(flags, self.flags.BUFF) ~= 0 then
        return "defensive"
    elseif bit.band(flags, self.flags.PERSONAL) ~= 0 then
        return "personal"
    end
    return "other"
end

function SpellDB:GetFlagsForType(spellType)
    local flagMap = {
        interrupt = SPELL_FLAGS.INTERRUPT,
        offensive = SPELL_FLAGS.DEBUFF,
        defensive = SPELL_FLAGS.BUFF,
        personal = SPELL_FLAGS.PERSONAL
    }
    return flagMap[spellType] or 0
end

function SpellDB:GetSpellInfo(spellId)
    local info = self.data[spellId]
    if not info then
        -- Debug: Log missing spell info
        if Blackjack:IsDebugEnabled() then
            Blackjack:DebugMessage("No data for spellId: " .. spellId .. " available spells: " .. self:GetSpellCount())
        end
        return {}
    end
    return info
end

function SpellDB:GetSpellIdByName(name)
    return self.spellNames[name:lower()]
end

function SpellDB:GetSpellCount()
    local count = 0
    for _ in pairs(self.data) do
        count = count + 1
    end
    return count
end

function SpellDB:IsInterrupt(spellId)
    local data = self.data[spellId]
    return data and bit.band(data.flags, self.flags.INTERRUPT) ~= 0
end

function SpellDB:IsDispel(spellId)
    local data = self.data[spellId]
    return data and bit.band(data.flags, self.flags.DISPEL) ~= 0
end

function SpellDB:GetSpellsForClass(class)
    -- Return relevant spells for each class that users might want to filter
    local classSpells = {
        DEATHKNIGHT = {
            {id = 49576, name = "Death Grip", type = "interrupt"},
            {id = 47528, name = "Mind Freeze", type = "interrupt"},
            {id = 48707, name = "Anti-Magic Shell", type = "defensive"},
            {id = 48792, name = "Icebound Fortitude", type = "defensive"},
            {id = 49203, name = "Hungering Cold", type = "offensive"},
            {id = 49206, name = "Summon Gargoyle", type = "offensive"}
        },
        DRUID = {
            {id = 33786, name = "Cyclone", type = "offensive"},
            {id = 2637, name = "Hibernate", type = "offensive"},
            {id = 339, name = "Entangling Roots", type = "offensive"},
            {id = 29166, name = "Innervate", type = "defensive"},
            {id = 17116, name = "Nature's Swiftness", type = "defensive"}
        },
        HUNTER = {
            {id = 14326, name = "Scare Beast", type = "offensive"},
            {id = 34490, name = "Silencing Shot", type = "interrupt"},
            {id = 14309, name = "Freezing Trap", type = "offensive"},
            {id = 19503, name = "Scatter Shot", type = "offensive"},
            {id = 5384, name = "Feign Death", type = "defensive"}
        },
        MAGE = {
            {id = 118, name = "Polymorph", type = "offensive"},
            {id = 31661, name = "Dragon's Breath", type = "offensive"},
            {id = 122, name = "Frost Nova", type = "offensive"},
            {id = 45438, name = "Ice Block", type = "defensive"},
            {id = 12051, name = "Evocation", type = "defensive"},
            {id = 2139, name = "Counterspell", type = "interrupt"}
        },
        PALADIN = {
            {id = 10326, name = "Turn Evil", type = "offensive"},
            {id = 20066, name = "Repentance", type = "offensive"},
            {id = 10308, name = "Hammer of Justice", type = "interrupt"},
            {id = 10278, name = "Hand of Protection", type = "defensive"},
            {id = 6940, name = "Hand of Sacrifice", type = "defensive"},
            {id = 642, name = "Divine Shield", type = "defensive"}
        },
        PRIEST = {
            {id = 8122, name = "Psychic Scream", type = "offensive"},
            {id = 15487, name = "Silence", type = "interrupt"},
            {id = 6346, name = "Fear Ward", type = "defensive"},
            {id = 33206, name = "Pain Suppression", type = "defensive"},
            {id = 10060, name = "Power Infusion", type = "defensive"},
            {id = 10890, name = "Psychic Scream", type = "offensive"}
        },
        ROGUE = {
            {id = 2094, name = "Blind", type = "offensive"},
            {id = 1776, name = "Gouge", type = "offensive"},
            {id = 6770, name = "Sap", type = "offensive"},
            {id = 5277, name = "Evasion", type = "defensive"},
            {id = 1856, name = "Vanish", type = "defensive"},
            {id = 1766, name = "Kick", type = "interrupt"}
        },
        SHAMAN = {
            {id = 51514, name = "Hex", type = "offensive"},
            {id = 39796, name = "Stoneclaw Totem", type = "defensive"},
            {id = 8177, name = "Grounding Totem", type = "defensive"},
            {id = 16190, name = "Mana Tide Totem", type = "defensive"},
            {id = 57994, name = "Wind Shear", type = "interrupt"}
        },
        WARLOCK = {
            {id = 6789, name = "Death Coil", type = "offensive"},
            {id = 5782, name = "Fear", type = "offensive"},
            {id = 5484, name = "Howl of Terror", type = "offensive"},
            {id = 6229, name = "Shadow Ward", type = "defensive"}
        },
        WARRIOR = {
            {id = 6552, name = "Pummel", type = "interrupt"},
            {id = 72, name = "Shield Bash", type = "interrupt"},
            {id = 676, name = "Disarm", type = "offensive"},
            {id = 871, name = "Shield Wall", type = "defensive"},
            {id = 12975, name = "Last Stand", type = "defensive"},
            {id = 20230, name = "Retaliation", type = "offensive"}
        }
    }

    return classSpells[class] or {}
end

Blackjack:RegisterModule("SpellDB", SpellDB)
