local Blackjack = _G.Blackjack
local LibStub = _G.LibStub
local LSM = LibStub("LibSharedMedia-3.0")
local PlaySoundFile = PlaySoundFile
local GetTime = GetTime

local SoundAlerts = {
    soundCache = {},
    lastSoundTime = 0
}

local soundMap = {
    interrupt = "Kick",
    dispel = "Dispel",
    purge = "Purge",
    offensive = "Attention",
    defensive = "Chime",
    personal = "Bell",
    test = "Attention"
}

function SoundAlerts:OnInitialize(db)
    self.db = db
end

function SoundAlerts:Play(alertType, soundKey)
    if not self.db.profile.notifications.sound then return end
    
    local now = GetTime()
    if now - self.lastSoundTime < 0.1 then return end

    local key = soundKey or soundMap[alertType:lower()] or "Attention"
    local soundPath

    -- Check cache first
    if self.soundCache[key] then
        soundPath = self.soundCache[key]
    else
        
        local lsmSound = LSM:Fetch("sound", key)
        if lsmSound and lsmSound ~= "Interface\\Quiet.ogg" then
            soundPath = lsmSound
        else
            soundPath = "Interface\\AddOns\\Blackjack\\Media\\Sounds\\" .. key .. ".mp3"
        end
        self.soundCache[key] = soundPath
    end

    if soundPath then
        self:PlayWithAddonVolume(soundPath)
        self.lastSoundTime = now
    end
end

function SoundAlerts:PlayWithAddonVolume(soundPath)
    PlaySoundFile(soundPath, "SFX")
end

function SoundAlerts:GetSoundForAlert(alertType)
    return soundMap[alertType:lower()] or "Attention"
end

function SoundAlerts:PlayTest()
    self:Play("test")
end

-- Register module
Blackjack:RegisterModule("SoundAlerts", SoundAlerts)
