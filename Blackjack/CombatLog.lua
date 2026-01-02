local Blackjack = _G.Blackjack

local select = select
local type = type
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local bit = bit
local UnitGUID = UnitGUID
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitIsEnemy = UnitIsEnemy
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local wipe = wipe or table.wipe

local CombatLog = {}

local targetInfoCache = {}

function CombatLog:OnInitialize(db)
    self.db = db
    self.spellDB = Blackjack.modules.SpellDB
    self.filters = Blackjack.modules.Filters
    -- Cache player GUID
    self.playerGUID = UnitGUID("player")

    self.playerClass = select(2, UnitClass("player"))
end

function CombatLog:OnEnable()
    Blackjack.addon:RegisterEvent("COMBAT_LOG_EVENT", function(...)
        self:ProcessEvent(...)
    end)

    Blackjack.addon:RegisterEvent("PLAYER_REGEN_ENABLED", function()
    end)
end

function CombatLog:ProcessEvent(...)
    -- 3.3.5a COMBAT_LOG_EVENT format:
    -- timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSpellSchool
    
    local event = select(3, ...)

    local isInterrupt = (event == "SPELL_INTERRUPT")
    local isDispel = (event == "SPELL_DISPEL")
    local isMiss = (event == "SWING_MISSED" or event == "RANGE_MISSED" or event == "SPELL_MISSED")
    
    if not (isInterrupt or isDispel or isMiss or 
            event == "SPELL_CAST_SUCCESS" or 
            event == "SPELL_AURA_APPLIED" or 
            event == "SPELL_AURA_REMOVED" or 
            event == "SPELL_SUMMON") then
        return
    end

    local sourceGUID = select(4, ...)
    local sourceName = select(5, ...)
    local sourceFlags = select(6, ...)
    local destName = select(8, ...)
    
    local spellId, spellName, extraSpellName, extraSpellSchool
    
    if event == "SWING_MISSED" then
        extraSpellName = select(10, ...) 
    elseif event == "RANGE_MISSED" or event == "SPELL_MISSED" then
         spellId = select(10, ...)
         spellName = select(11, ...)
         extraSpellName = select(13, ...)
    else
        spellId = select(10, ...)
        spellName = select(11, ...)
        -- spellSchool = select(12, ...)
        -- extraSpellId = select(13, ...)
        extraSpellName = select(14, ...)
        extraSpellSchool = select(15, ...)
    end

    -- Debug logging
    if Blackjack.db.profile.debug and (isInterrupt or isDispel) then
        Blackjack:DebugMessage("Interrupt/Dispel: " .. event .. " spellId: " .. tostring(spellId) .. " spellName: " .. tostring(spellName))
    end

    local shouldTrack = false
    local alertType = nil
    
    -- Clear reuse table
    wipe(targetInfoCache)
    local targetInfo = targetInfoCache
    local isPlayerAction = false
    local spellInfo = nil

    -- Handle misses / dodges / parries
    if sourceGUID == self.playerGUID and isMiss then
        if Blackjack.db.profile.debug then
            Blackjack:DebugMessage("CombatLog: Player miss event detected: " .. event)
        end
        shouldTrack = true
        alertType = "miss"
        isPlayerAction = true
        targetInfo.missType = extraSpellName or "Miss"
        targetInfo.spellName = spellName or "Unknown"

        if spellId then
            spellInfo = self.spellDB:GetSpellInfo(spellId)
            if spellInfo then
                spellInfo.id = spellId
            end
        end
        if not spellInfo or not spellInfo.name then
            local _, _, texture = GetSpellInfo(spellId)
            spellInfo = { 
                id = spellId, 
                name = spellName or "Unknown", 
                texture = texture, 
                type = "personal" 
            }
        end
    end

    if not spellInfo and spellId then
        spellInfo = self.spellDB:GetSpellInfo(spellId)
        if spellInfo then
            spellInfo.id = spellId
        end
    end

    if (not spellInfo or not spellInfo.name) and not shouldTrack then
         if Blackjack.db.profile.debug and spellId then
             Blackjack:DebugMessage("No spell info for spellId: " .. tostring(spellId))
         end
        return
    end

    -- Track player interrupts and dispels
    if sourceGUID == self.playerGUID then
        if isInterrupt then
            if Blackjack.db.profile.debug then
                print("CombatLog: Processing player interrupt")
            end
            shouldTrack = true
            alertType = "interrupt"
            isPlayerAction = true
            targetInfo.interruptedSpell = extraSpellName or "Unknown Spell"
            targetInfo.school = extraSpellSchool or 0

        elseif isDispel then
             if Blackjack.db.profile.debug then
                print("CombatLog: Processing player dispel/purge")
            end
            shouldTrack = true
            isPlayerAction = true
            if spellInfo and spellInfo.type == "purge" then
                alertType = "purge"
            else
                alertType = "dispel"
            end
            targetInfo.dispelledSpell = extraSpellName or "Unknown Spell"
            targetInfo.school = extraSpellSchool or 0
        end
    else
        -- Handle enemy spell casts
        if spellInfo and spellInfo.type then
            local isEnemy = false
            
            -- Check sourceFlags for enemy reaction
            if sourceFlags then
                local inEnemyMask = bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE)
                isEnemy = inEnemyMask ~= 0
            end

            -- If not determined by flags, try to check by unit name or GUID
            if not isEnemy and sourceGUID then
                if sourceName and UnitExists(sourceName) then
                    isEnemy = UnitIsEnemy("player", sourceName)
                end
                -- Fallback: check by GUID if name check didn't work
                if not isEnemy then
                    isEnemy = UnitIsEnemy("player", sourceGUID)
                end
            end

            -- Track if enemy
            if isEnemy then
                shouldTrack = self.filters:IsSpellEnabled(self.playerClass, spellId)
                alertType = spellInfo.type
            end
        end
    end

    if shouldTrack and (isPlayerAction or self.filters:IsAllFiltersEnabled()) then
        local customSound = nil
        if self.db and self.db.profile and self.db.profile.spellSettings then
            local classSettings = self.db.profile.spellSettings[self.playerClass] or {}
            local globalSettings = self.db.profile.spellSettings["GLOBAL"] or {}
            local s = classSettings[spellId] or globalSettings[spellId]
            if s then
                if s.customText then
                    targetInfo.customText = s.customText
                end
                if s.sound then
                    customSound = s.sound
                end
            end
        end

        self:HandleSpellEvent(event, spellInfo, destName, sourceName, alertType, targetInfo, customSound)
    end
end

function CombatLog:HandleSpellEvent(event, spellInfo, target, source, alertType, targetInfo, customSound)
    -- Use provided alertType if available, otherwise determine from spell
    local finalAlertType = alertType or spellInfo.type

    if Blackjack.modules.VisualAlerts then
        Blackjack.modules.VisualAlerts:Show(finalAlertType, spellInfo, targetInfo)
    end

    if Blackjack.modules.SoundAlerts then
        Blackjack.modules.SoundAlerts:Play(finalAlertType, customSound)
    end
end

function CombatLog:ParseEventType(event)
    if event == "SPELL_CAST_SUCCESS" then return "CAST_SUCCESS" end
    if event == "SPELL_AURA_APPLIED" then return "AURA_APPLIED" end
    if event == "SPELL_AURA_REMOVED" then return "AURA_REMOVED" end
    if event == "SPELL_INTERRUPT" then return "INTERRUPT" end
    if event == "SPELL_DISPEL" then return "DISPEL" end
    if event == "SPELL_SUMMON" then return "SUMMON" end
    return "OTHER"
end

if Blackjack.db and Blackjack.db.profile.debug then
    print("CombatLog.lua: Registering CombatLog module")
end
Blackjack:RegisterModule("CombatLog", CombatLog)
if Blackjack.db and Blackjack.db.profile.debug then
    print("CombatLog.lua: CombatLog module registered")
end

