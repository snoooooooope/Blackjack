local Blackjack = _G.Blackjack
local LibStub = _G.LibStub
local LSM = LibStub("LibSharedMedia-3.0")

local VisualAlerts = {
    frame = nil,
    text = nil
}

function VisualAlerts:OnInitialize(db)
    self.db = db

    -- Create notification frame
    self.frame = CreateFrame("Frame", "BlackjackVisualAlertFrame", UIParent)
    self.frame:SetSize(200, 50)
    self.frame:SetPoint("CENTER", 0, 0)
    self.frame:Hide()

    -- Text
    self.text = self.frame:CreateFontString(nil, "OVERLAY")
    self.text:SetPoint("CENTER")
    self:UpdateFont()

    -- Initialize LibWindow for position saving
    self:InitializeLibWindow()
end

function VisualAlerts:InitializeLibWindow()
    local LibWindow = LibStub("LibWindow-1.1", true)

    if not LibWindow then
        print("Blackjack: LibWindow-1.1 not found - position saving disabled")
        return
    end

    -- Register the frame with LibWindow for position saving
    LibWindow.RegisterConfig(self.frame, self.db.profile.notifications, {
        prefix = "visualAlert_"
    })

    -- Make the frame draggable
    LibWindow.MakeDraggable(self.frame)

    -- Enable mouse wheel scaling (optional)
    LibWindow.EnableMouseWheelScaling(self.frame)

    -- Restore saved position
    LibWindow.RestorePosition(self.frame)
end

function VisualAlerts:UpdateFont()
    if self.db and self.db.profile and self.db.profile.notifications then
        local font = LSM:Fetch("font", self.db.profile.notifications.font)
        self.text:SetFont(font, self.db.profile.notifications.fontSize, "OUTLINE")
    end
end

function VisualAlerts:Show(alertType, spellInfo, targetInfo)
    if not self.db.profile.notifications.enabled then return end
    if not spellInfo or not spellInfo.name then return end

    local color = self:GetAlertColor(alertType)
    local displayText = spellInfo.name

    -- Information for interrupts and dispels
    if targetInfo then
        if alertType == "interrupt" and targetInfo.interruptedSpell then
            local schoolName = self:GetSchoolName(targetInfo.school)
            displayText = "Kicked: " .. targetInfo.interruptedSpell .. " (" .. schoolName .. ")"
        elseif alertType == "dispel" and targetInfo.dispelledSpell then
            displayText = "Dispelled: " .. targetInfo.dispelledSpell
        end
    end

    self.text:SetText(displayText)
    self.text:SetTextColor(color.r, color.g, color.b)
    self.frame:Show()

    C_Timer.After(3, function()
        if self.frame then
            self.frame:Hide()
        end
    end)
end

function VisualAlerts:GetAlertColor(alertType)
    local colorMap = {
        interrupt = { r = 1, g = 0, b = 0 },
        dispel = { r = 1, g = 1, b = 0 },
        offensive = { r = 1, g = 0.5, b = 0 },
        defensive = { r = 0, g = 1, b = 0 },
        personal = { r = 0, g = 1, b = 1 }
    }
    return colorMap[alertType:lower()] or { r = 1, g = 1, b = 1 }
end

function VisualAlerts:GetSchoolName(school)
    local schoolNames = {
        [1] = "Physical",
        [2] = "Holy",
        [4] = "Fire",
        [8] = "Nature",
        [16] = "Frost",
        [32] = "Shadow",
        [64] = "Arcane"
    }

    if school and school > 0 then
        local schools = {}
        for schoolBit, name in pairs(schoolNames) do
            if bit.band(school, schoolBit) ~= 0 then
                table.insert(schools, name)
            end
        end
        if #schools > 0 then
            return table.concat(schools, "/")
        end
    end

    return "Unknown"
end

function VisualAlerts:ShowTestNotification()
    if not self.text or not self.frame then
        print("Blackjack: VisualAlerts not properly initialized")
        return
    end

    self.text:SetText("Test Notification")
    self.text:SetTextColor(0.5, 0.8, 1)
    self.frame:Show()

    C_Timer.After(3, function()
        if self.frame then
            self.frame:Hide()
        end
    end)
end

-- Register module
Blackjack:RegisterModule("VisualAlerts", VisualAlerts)
