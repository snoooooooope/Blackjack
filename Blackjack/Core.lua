local LibStub = _G.LibStub

-- Create main addon table
local Blackjack = {}
_G.Blackjack = Blackjack

-- Store module registry
Blackjack.modules = {}

function Blackjack:RegisterModule(name, module)
    self.modules[name] = module
end

function Blackjack:InitializeDatabase()
    -- Create database / defaults
    local defaults = {
        profile = {
            debug = false,
            filters = {
                enabled = true
            },
            notifications = {
                enabled = true,
                position = "CENTER",
                sound = true,
                font = "Avant Garde LT Bold",
                fontSize = 15,
                iconSize = 20,
                alertSound = "Attention",
                interruptSound = "Kick",
                dispelSound = "Dispel",
                -- LibWindow position data
                visualAlert_x = 0,
                visualAlert_y = 220,
                visualAlert_point = "CENTER",
                visualAlert_scale = 1.0
            }
        }
    }

    self.db = LibStub("AceDB-3.0"):New("BlackjackDB", defaults)

    -- Register for PLAYER_ENTERING_WORLD to load saved variables after the player is in-game
    self.addon:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:LoadSavedVariables()
        self.addon:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end)
end

function Blackjack:LoadSavedVariables()
    -- Copy saved profile data into the current database profile
    local savedVars = _G.BlackjackDB
    if savedVars and savedVars.profiles then
        local profileKey = self.db:GetCurrentProfile()
        local savedProfile = savedVars.profiles[profileKey]

        if savedProfile then
            -- Deep copy saved data into current profile
            self:CopyTable(savedProfile, self.db.profile)
        end
    end

    -- Register callback to save changes back to global saved variables
    self.db:RegisterCallback("OnProfileChanged", function()
        self:SaveToGlobal()
    end)
    self.db:RegisterCallback("OnProfileCopied", function()
        self:SaveToGlobal()
    end)
    self.db:RegisterCallback("OnProfileReset", function()
        self:SaveToGlobal()
    end)

    -- Also save on database changes (AceDB should do this automatically, but nothing ever works how it should)
    self.db:RegisterCallback("OnDatabaseShutdown", function()
        self:SaveToGlobal()
    end)
end

function Blackjack:SaveToGlobal()
    -- Ensure changes are saved to the global saved variables
    if not _G.BlackjackDB then
        _G.BlackjackDB = {}
    end
    if not _G.BlackjackDB.profiles then
        _G.BlackjackDB.profiles = {}
    end

    local profileKey = self.db:GetCurrentProfile()
    _G.BlackjackDB.profiles[profileKey] = self:DeepCopy(self.db.profile)
end

function Blackjack:CopyTable(source, dest)
    for k, v in pairs(source) do
        if type(v) == "table" and type(dest[k]) == "table" then
            self:CopyTable(v, dest[k])
        else
            dest[k] = v
        end
    end
end

function Blackjack:DeepCopy(obj)
    if type(obj) ~= "table" then return obj end
    local res = {}
    for k, v in pairs(obj) do
        res[k] = self:DeepCopy(v)
    end
    return res
end


function Blackjack:InitializeModule(name)
    local module = self.modules[name]
    if module and module.OnInitialize then
        module:OnInitialize(self.db)
    end
    if module and module.OnEnable then
        module:OnEnable()
    end
end

function Blackjack:HandleChatCommand(input)
    local command = self.addon:GetArgs(input, 1)

    if not command then
        self.addon:Print("Available commands:")
        self.addon:Print("/bj debug - Toggle debug messages")
        self.addon:Print("/bj config - Open configuration panel")
        self.addon:Print("/bj test - Test visual and sound alerts")
        return
    end

    command = command:lower() -- Case insensitive commands

    if command == "debug" then
        self.db.profile.debug = not self.db.profile.debug
        self.addon:Print("Debug mode", self.db.profile.debug and "enabled" or "disabled")
    elseif command == "config" then
        if self.modules.Config then
            self.modules.Config:ToggleConfig()
        else
            self.addon:Print("Configuration module not loaded")
        end
    elseif command == "test" then
        self.addon:Print("Testing Blackjack alerts...")
        -- Test visual alert
        if self.modules.VisualAlerts then
            self.modules.VisualAlerts:ShowTestNotification()
        else
            self.addon:Print("VisualAlerts module not available")
        end
        -- Test sound alert
        if self.modules.SoundAlerts then
            self.modules.SoundAlerts:PlayTest()
        else
            self.addon:Print("SoundAlerts module not available")
        end
    else
        self.addon:Print("Unknown command:", command)
        self.addon:Print("Available commands:")
        self.addon:Print("/bj debug - Toggle debug messages")
        self.addon:Print("/bj config - Open configuration panel")
        self.addon:Print("/bj test - Test visual and sound alerts")
    end
end

function Blackjack:IsDebugEnabled()
    return self.db and self.db.profile and self.db.profile.debug
end

function Blackjack:DebugMessage(msg)
    if self:IsDebugEnabled() then
        print("|cFF33FF99Blackjack|r:", msg)
    end
end

-- Blackjack is available globally as _G.Blackjack
-- Export via LibStub for modules to access
LibStub:NewLibrary("Blackjack-Core", 1, Blackjack)
