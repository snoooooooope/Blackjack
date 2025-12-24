local Blackjack = _G.Blackjack

local CombatLog = {}

function CombatLog:OnInitialize(db)
    self.db = db
    self.spellDB = Blackjack.modules.SpellDB
    self.filters = Blackjack.modules.Filters
    -- Cache player GUID
    self.playerGUID = UnitGUID("player")
end

function CombatLog:OnEnable()
    -- Register combat log event
    Blackjack.addon:RegisterEvent("COMBAT_LOG_EVENT", function(...)
        self:ProcessEvent(...)
    end)

    -- Register for combat state changes
    Blackjack.addon:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        -- Combat ended
    end)
end

function CombatLog:ProcessEvent(...)

    -- 3.3.5a COMBAT_LOG_EVENT format:
    -- "COMBAT_LOG_EVENT", timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSpellSchool
    local _, timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSpellSchool = ...

    -- Debug: Only log interrupt/dispel events when debug is enabled
    if Blackjack:IsDebugEnabled() and (event == "SPELL_INTERRUPT" or event == "SPELL_DISPEL") then
        Blackjack:DebugMessage("Interrupt/Dispel: " .. event .. " spellId: " .. spellId .. " spellName: " .. spellName)
    end

    -- Get spell information first
    local spellInfo = self.spellDB:GetSpellInfo(spellId)
    if not spellInfo or not spellInfo.name then
        if Blackjack:IsDebugEnabled() then
            Blackjack:DebugMessage("No spell info for spellId: " .. spellId)
        end
        return
    end

    local playerClass = select(2, UnitClass("player"))
    local shouldTrack = false
    local alertType = nil
    local targetInfo = nil
    local isPlayerAction = false

    -- Track player interrupts and dispels
    if sourceGUID == self.playerGUID then
        if event == "SPELL_INTERRUPT" then
            if Blackjack:IsDebugEnabled() then
                print("CombatLog: Processing player interrupt")
            end
            shouldTrack = true
            alertType = "interrupt"
            isPlayerAction = true
            -- Get information about what was interrupted (extraSpellId/Name/School)
            targetInfo = {
                interruptedSpell = extraSpellName or "Unknown Spell",
                school = extraSpellSchool or 0
            }
        elseif event == "SPELL_DISPEL" then
            if Blackjack:IsDebugEnabled() then
                print("CombatLog: Processing player dispel")
            end
            shouldTrack = true
            alertType = "dispel"
            isPlayerAction = true
            -- Get information about what was dispelled (extraSpellId/Name/School)
            targetInfo = {
                dispelledSpell = extraSpellName or "Unknown Spell",
                school = extraSpellSchool or 0
            }
        end
    else
        -- Check if source is an enemy
        local isEnemy = false
        if sourceFlags then
            local inEnemyMask = bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE)
            isEnemy = inEnemyMask ~= 0
        end

        if not isEnemy and sourceGUID then
            if UnitExists(sourceName) then
                isEnemy = UnitIsEnemy("player", sourceName) or UnitIsEnemy("player", sourceGUID)
            end
        end

        if isEnemy then
            shouldTrack = self.filters:IsSpellEnabled(playerClass, spellId)
            alertType = spellInfo.type
        end
    end

    -- Trigger alerts if enabled
    -- Player actions bypass global filter check
    if shouldTrack and (isPlayerAction or self.filters:IsAllFiltersEnabled()) then
        self:HandleSpellEvent(event, spellInfo, destName, sourceName, alertType, targetInfo)
    end
end

function CombatLog:HandleSpellEvent(event, spellInfo, target, source, alertType, targetInfo)
    -- Use provided alertType if available, otherwise determine from spell
    local finalAlertType = alertType or spellInfo.type

    if Blackjack.modules.VisualAlerts then
        Blackjack.modules.VisualAlerts:Show(finalAlertType, spellInfo, targetInfo)
    end

    if Blackjack.modules.SoundAlerts then
        Blackjack.modules.SoundAlerts:Play(finalAlertType)
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

if Blackjack:IsDebugEnabled() then
    print("CombatLog.lua: Registering CombatLog module")
end
Blackjack:RegisterModule("CombatLog", CombatLog)
if Blackjack:IsDebugEnabled() then
    print("CombatLog.lua: CombatLog module registered")
end
