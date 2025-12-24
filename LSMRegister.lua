local Blackjack = _G.Blackjack
local LSM = LibStub("LibSharedMedia-3.0")

local LSMRegister = {}

function LSMRegister:OnInitialize()
    self:RegisterFonts()
    self:RegisterSounds()
end

function LSMRegister:RegisterFonts()
    local fontDir = "Interface\\AddOns\\Blackjack\\Media\\Fonts\\"

    local fontMappings = {
        {"Avant Garde LT Bold", "AvantGardeLTBold.ttf"},
        -- Add more font mappings here as you add font files
        -- Format: {"Display Name", "filename.ttf"}
    }

    -- Register fonts that have corresponding files
    for _, mapping in ipairs(fontMappings) do
        local displayName, fileName = mapping[1], mapping[2]
        local fontPath = fontDir .. fileName

        -- let WoW handle missing files I cba
        LSM:Register("font", displayName, fontPath)
    end
end

function LSMRegister:RegisterSounds()
    local soundDir = "Interface\\AddOns\\Blackjack\\Media\\Sounds\\"

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

        -- Try to register, but don't fail if already registered
        local existing = LSM:Fetch("sound", displayName)
        if not existing then
            LSM:Register("sound", displayName, soundPath)
        end
    end
end

Blackjack:RegisterModule("LSMRegister", LSMRegister)
