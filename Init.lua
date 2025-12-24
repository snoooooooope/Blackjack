local addonName = ...
local LibStub = _G.LibStub
local version = "1.0.0"

-- Get the main addon table from Core.lua
local Blackjack = _G.Blackjack
_G[addonName] = Blackjack

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

    -- Initialize modules
    self:InitializeModule("LSMRegister")
    self:InitializeModule("SpellDB")
    self:InitializeModule("Filters")
    self:InitializeModule("CombatLog")
    self:InitializeModule("SoundAlerts")
    self:InitializeModule("VisualAlerts")
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
