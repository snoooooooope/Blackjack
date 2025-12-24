local Blackjack = _G.Blackjack
local LibStub = _G.LibStub
local LSM = LibStub("LibSharedMedia-3.0")

local SoundAlerts = {}

function SoundAlerts:OnInitialize(db)
    self.db = db
end

function SoundAlerts:Play(alertType)
    if not self.db.profile.notifications.sound then return end

    local soundKey = self:GetSoundForAlert(alertType)

    -- Try LSM first, then fallback to direct path
    local sound = LSM:Fetch("sound", soundKey)
    if sound and sound ~= "Interface\\Quiet.ogg" then
        self:PlayWithAddonVolume(sound)
    else
        local directPath = "Interface\\AddOns\\Blackjack\\Media\\Sounds\\" .. soundKey .. ".mp3"
        self:PlayWithAddonVolume(directPath)
    end
end

function SoundAlerts:PlayWithAddonVolume(soundPath)
    PlaySoundFile(soundPath, "SFX")
end

function SoundAlerts:GetSoundForAlert(alertType)
    local soundMap = {
        interrupt = "Kick",  -- Use the registered sound name
        dispel = "Dispel",    -- Use the registered sound name
        offensive = "Attention",  -- Use the registered sound name
        defensive = "Chime",     -- Use the registered sound name
        personal = "Bell",       -- Use the registered sound name
        test = "Attention"       -- For test notifications
    }
    return soundMap[alertType:lower()] or "Attention"
end

function SoundAlerts:PlayTest()
    self:Play("test")
end

-- Register module
Blackjack:RegisterModule("SoundAlerts", SoundAlerts)
