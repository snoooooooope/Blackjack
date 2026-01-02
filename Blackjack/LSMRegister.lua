local Blackjack = _G.Blackjack
local LSM = LibStub("LibSharedMedia-3.0")

local LSMRegister = {}

function LSMRegister:OnInitialize()
    self:RegisterFonts()
    self:RegisterSounds()
end

function LSMRegister:RegisterFonts()
    local addonName = Blackjack.addonName or "Blackjack"
    local fontDir = "Interface\\AddOns\\" .. addonName .. "\\Media\\Fonts\\"

    local fontMappings = {
        {"Avant Garde LT Bold", "AvantGardeLTBold.ttf"},
    }

    -- Register fonts that have corresponding files
    for _, mapping in ipairs(fontMappings) do
        local displayName, fileName = mapping[1], mapping[2]
        local fontPath = fontDir .. fileName

        -- Always register to ensure availability
        LSM:Register("font", displayName, fontPath)
    end
end

function LSMRegister:RegisterSounds()
    local addonName = Blackjack.addonName or "Blackjack"
    local soundDir = "Interface\\AddOns\\" .. addonName .. "\\Media\\Sounds\\"

    -- List of sound display names and their corresponding file name
    local soundMappings = {
        {"Interrupted", "Interrupted.mp3"},
        {"Attention", "Attention.mp3"},
        {"Chime", "Chime.mp3"},
        {"Kite", "Kite.mp3"},
        {"Kick", "Kick.mp3"},
        {"Pop", "Pop.mp3"},
        {"Immunity", "Immunity.mp3"},
        {"Dispel", "Dispel.mp3"},
        {"Trinket", "Trinket.mp3"},
        {"Warning", "Warning.mp3"},
        {"Drinking", "Drinking.mp3"},
        {"Resurrection", "Resurrection.mp3"},
        {"Reflect", "Reflect.mp3"},
        {"Grounding Totem", "GroundingTotem.mp3"},
        {"Purge", "Purge.mp3"},
        {"Stealth", "Stealth.mp3"},
        {"Bell", "Bell.mp3"}
    }

    -- Register sounds that have corresponding files
    for _, mapping in ipairs(soundMappings) do
        local displayName, fileName = mapping[1], mapping[2]
        local soundPath = soundDir .. fileName

        -- Always register to ensure custom sounds are available
        LSM:Register("sound", displayName, soundPath)
    end
end

Blackjack:RegisterModule("LSMRegister", LSMRegister)
