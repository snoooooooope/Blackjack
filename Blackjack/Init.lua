local addonName = ...
local LibStub = _G.LibStub
local version = "1.1.1"

-- Get the main addon table from Core.lua
local Blackjack = _G.Blackjack
_G[addonName] = Blackjack
Blackjack.addonName = addonName

function Blackjack:Initialize()

    -- Create AceAddon instance
    local AceAddon = LibStub("AceAddon-3.0")
    self.addon = AceAddon:NewAddon(addonName,
        "AceEvent-3.0",
        "AceConsole-3.0",
        "AceHook-3.0"
    )

    -- Initialize database
    self:InitializeDatabase()

    self:InitializeModule("LSMRegister")
    self:InitializeModule("SpellDB")
    self:InitializeModule("Filters")
    self:InitializeModule("SoundAlerts")
    self:InitializeModule("VisualAlerts")
    
    -- CombatLog depends on SpellDB and Filters
    self:InitializeModule("CombatLog")
    
    -- Config depends on everything
    self:InitializeModule("Config")

    -- Commands
    self.addon:RegisterChatCommand("bj", function(input)
        self:HandleChatCommand(input)
    end)
    self.addon:RegisterChatCommand("blackjack", function(input)
        self:HandleChatCommand(input)
    end)

    print("|cFF9932CCBlackjack|r - |cFF33FF99v" .. version .. "|r loaded")
end

-- Start initialization after all files are loaded (deferred to next frame)
C_Timer.After(0, function() Blackjack:Initialize() end)
