local Blackjack = _G.Blackjack
local LibStub = _G.LibStub
local LSM = LibStub("LibSharedMedia-3.0")

local SoundAlerts = {}

function SoundAlerts:OnInitialize(db)
    self.db = db
end

function SoundAlerts:Play(alertType, soundKey)
    if not self.db.profile.notifications.sound then return end

    local key = soundKey or self:GetSoundForAlert(alertType)

    -- Try LSM first, then fallback to direct path
    local sound = LSM:Fetch("sound", key)
    if sound and sound ~= "Interface\\Quiet.ogg" then
        self:PlayWithAddonVolume(sound)
    else
        local directPath = "Interface\\AddOns\\Blackjack\\Media\\Sounds\\" .. key .. ".mp3"
        self:PlayWithAddonVolume(directPath)
    end
end

function SoundAlerts:PlayWithAddonVolume(soundPath)
    PlaySoundFile(soundPath, "SFX")
end

function SoundAlerts:GetSoundForAlert(alertType)
    local soundMap = {
        interrupt = "Kick",
        dispel = "Dispel",
        purge = "Purge",
        offensive = "Attention",
        defensive = "Chime",
        personal = "Bell",
        test = "Attention"
    }
    return soundMap[alertType:lower()] or "Attention"
end

function SoundAlerts:PlayTest()
    self:Play("test")
end

-- Register module
Blackjack:RegisterModule("SoundAlerts", SoundAlerts)
