local Blackjack = _G.Blackjack
local LibStub = _G.LibStub
local LSM = LibStub("LibSharedMedia-3.0")
local bit = bit
local table = table
local GetTime = GetTime

local VisualAlerts = {
    frame = nil,
    text = nil,
    icon = nil,
    iconBorder = nil,
    hideTime = 0
}

local colorMap = {
    interrupt = { r = 1, g = 0, b = 0 },
    dispel = { r = 1, g = 1, b = 0 },
    purge = { r = 0.6, g = 0.4, b = 1 },
    offensive = { r = 1, g = 0.5, b = 0 },
    defensive = { r = 0, g = 1, b = 0 },
    personal = { r = 0, g = 1, b = 1 }
}
local defaultColor = { r = 1, g = 1, b = 1 }

local schoolNames = {
    [1] = "Physical",
    [2] = "Holy",
    [4] = "Fire",
    [8] = "Nature",
    [16] = "Frost",
    [32] = "Shadow",
    [64] = "Arcane"
}

function VisualAlerts:OnInitialize(db)
    self.db = db

    -- Create notification frame
    self.frame = CreateFrame("Frame", "BlackjackVisualAlertFrame", UIParent)
    self.frame:SetSize(300, 50)
    self.frame:SetPoint("CENTER", 0, 0)
    self.frame:Hide()
    
    self.frame:SetScript("OnUpdate", function(f, elapsed)
        if GetTime() > self.hideTime then
            f:Hide()
        end
    end)

    -- Create icon container frame
    local iconSize = self.db.profile.notifications.iconSize or 20
    self.iconContainer = CreateFrame("Frame", nil, self.frame)
    self.iconContainer:SetSize(iconSize, iconSize)
    self.iconContainer:SetPoint("LEFT", self.frame, "LEFT", 5, 0)
    self.iconContainer:SetClipsChildren(true)
    
    -- Create icon texture
    self.icon = self.iconContainer:CreateTexture(nil, "ARTWORK")
    self.icon:SetAllPoints()
    self.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    self.icon:SetDrawLayer("ARTWORK", 0)
    -- Set a default placeholder texture
    self.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    self.icon:SetBlendMode("BLEND")
    self.iconContainer:Hide()

    -- Create icon border
    self.iconBorder = self.frame:CreateTexture(nil, "OVERLAY")
    self.iconBorder:SetSize(iconSize + 2, iconSize + 2)
    self.iconBorder:SetPoint("CENTER", self.iconContainer, "CENTER", 0, 0)
    self.iconBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    self.iconBorder:SetBlendMode("ADD")
    self.iconBorder:SetAlpha(0.5)
    self.iconBorder:Hide()

    -- Create text
    self.text = self.frame:CreateFontString(nil, "OVERLAY")
    -- Position text absolutely from frame left
    local textLeft = 5 + iconSize + 10
    self.text:SetPoint("LEFT", self.frame, "LEFT", textLeft, 0)
    self.text:SetPoint("RIGHT", self.frame, "RIGHT", -5, 0)
    self.text:SetJustifyH("LEFT")
    self.text:SetWordWrap(false)
    self.text:SetNonSpaceWrap(false)
    self.text:SetDrawLayer("OVERLAY", 1)
    self:UpdateFont()

    self:InitializeLibWindow()
end

function VisualAlerts:InitializeLibWindow()
    local LibWindow = LibStub("LibWindow-1.1", true)

    if not LibWindow then
        print("Blackjack: LibWindow-1.1 not found - position saving disabled")
        return
    end

    -- Register the frame with LibWindow
    LibWindow.RegisterConfig(self.frame, self.db.profile.notifications, {
        prefix = "visualAlert_"
    })

    LibWindow.MakeDraggable(self.frame)

    LibWindow.EnableMouseWheelScaling(self.frame)

    LibWindow.RestorePosition(self.frame)
end

function VisualAlerts:UpdateFont()
    if self.db and self.db.profile and self.db.profile.notifications then
        local font = LSM:Fetch("font", self.db.profile.notifications.font)
        self.text:SetFont(font, self.db.profile.notifications.fontSize, "OUTLINE")
        
        -- Update icon size if it changed
        if self.iconContainer and self.icon then
            local iconSize = self.db.profile.notifications.iconSize or 20
            self.iconContainer:SetSize(iconSize, iconSize)
            if self.iconBorder then
                self.iconBorder:SetSize(iconSize + 2, iconSize + 2)
            end
            -- Reposition text based on new icon size
            if self.text then
                local textLeft = 5 + iconSize + 10
                self.text:ClearAllPoints()
                self.text:SetPoint("LEFT", self.frame, "LEFT", textLeft, 0)
                self.text:SetPoint("RIGHT", self.frame, "RIGHT", -5, 0)
            end
        end
    end
end

function VisualAlerts:Show(alertType, spellInfo, targetInfo)
    if not self.db.profile.notifications.enabled then return end
    if not spellInfo or not spellInfo.name then return end

    if alertType == "miss" and (not self.db.profile.notifications.showMisses) then return end
    
    -- Custom text override (per-spell or provided)
    local displayText = nil
    if targetInfo and targetInfo.customText and targetInfo.customText ~= "" then
        displayText = targetInfo.customText
    elseif spellInfo.customText and spellInfo.customText ~= "" then
        displayText = spellInfo.customText
    else
        -- Choose font size: use missFontSize for miss alerts if configured
        local font = LSM:Fetch("font", self.db.profile.notifications.font)
        local size = self.db.profile.notifications.fontSize
        if alertType == "miss" and self.db.profile.notifications.missFontSize then
            size = self.db.profile.notifications.missFontSize
        end
        if font and size then
            self.text:SetFont(font, size, "OUTLINE")
        end

        local color = self:GetAlertColor(alertType)
        displayText = spellInfo.name

        if targetInfo then
            if alertType == "interrupt" and targetInfo.interruptedSpell then
                local schoolName = self:GetSchoolName(targetInfo.school)
                displayText = "Kicked: " .. targetInfo.interruptedSpell .. " (" .. schoolName .. ")"
            elseif alertType == "dispel" and targetInfo.dispelledSpell then
                displayText = "Dispelled: " .. targetInfo.dispelledSpell
            elseif alertType == "purge" and targetInfo.dispelledSpell then
                displayText = "Purged: " .. targetInfo.dispelledSpell
            elseif alertType == "miss" and targetInfo and targetInfo.missType then
                local spellName = spellInfo.name or targetInfo.spellName or "Unknown"
                local missType = tostring(targetInfo.missType):upper()
                local verb
                if missType:find("DODGE") then
                    verb = "Dodged!"
                elseif missType:find("PARRY") then
                    verb = "Parried!"
                elseif missType:find("MISS") then
                    verb = "Missed!"
                else
                    verb = missType:sub(1,1):upper() .. missType:sub(2):lower() .. "!"
                end
                displayText = spellName .. " " .. verb
            end
        end
        self._lastColor = color
    end

    self.text:SetText(displayText)
    local color = self._lastColor or self:GetAlertColor(alertType)
    self.text:SetTextColor(color.r, color.g, color.b)
    
    -- Set icon texture if available and icons are enabled
    if self.db.profile.notifications.showIcons ~= false then
        local textureToUse = nil
        
        if spellInfo and spellInfo.texture then
            textureToUse = spellInfo.texture
        elseif spellInfo and spellInfo.id then
            -- Try to get texture from spell ID if available
            local _, _, texture = GetSpellInfo(spellInfo.id)
            if texture and texture ~= "" then
                textureToUse = texture
            end
        end
        
        if textureToUse and textureToUse ~= "" then
            -- Ensure icon is properly set up as a texture
            self.icon:SetTexture(textureToUse)
            self.icon:SetDrawLayer("ARTWORK", 0)
            self.iconContainer:Show()
            if self.iconBorder then 
                self.iconBorder:SetDrawLayer("OVERLAY", 0)
                self.iconBorder:Show() 
            end
        else
            -- Use placeholder icon if texture not found
            self.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            self.icon:SetDrawLayer("ARTWORK", 0)
            self.iconContainer:Show()
            if self.iconBorder then 
                self.iconBorder:SetDrawLayer("OVERLAY", 0)
                self.iconBorder:Show() 
            end
        end
        -- Position text absolutely based on icon size
        local iconSize = self.db.profile.notifications.iconSize or 20
        local textLeft = 5 + iconSize + 10
        self.text:ClearAllPoints()
        self.text:SetPoint("LEFT", self.frame, "LEFT", textLeft, 0)
        self.text:SetPoint("RIGHT", self.frame, "RIGHT", -5, 0)
    else
        self.iconContainer:Hide()
        if self.iconBorder then self.iconBorder:Hide() end
        -- Reposition text to left edge when icons are disabled
        self.text:ClearAllPoints()
        self.text:SetPoint("LEFT", self.frame, "LEFT", 5, 0)
        self.text:SetPoint("RIGHT", self.frame, "RIGHT", -5, 0)
    end
    
    local duration = self.db.profile.notifications.alertDuration or 3.0
    self.hideTime = GetTime() + duration
    self.frame:Show()
end

function VisualAlerts:GetAlertColor(alertType)
    return colorMap[alertType:lower()] or defaultColor
end

function VisualAlerts:GetSchoolName(school)
    if school and school > 0 then
        local result = ""
        if bit.band(school, 1) ~= 0 then result = result .. "Physical/" end
        if bit.band(school, 2) ~= 0 then result = result .. "Holy/" end
        if bit.band(school, 4) ~= 0 then result = result .. "Fire/" end
        if bit.band(school, 8) ~= 0 then result = result .. "Nature/" end
        if bit.band(school, 16) ~= 0 then result = result .. "Frost/" end
        if bit.band(school, 32) ~= 0 then result = result .. "Shadow/" end
        if bit.band(school, 64) ~= 0 then result = result .. "Arcane/" end
        
        if result ~= "" then
            return result:sub(1, -2)
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
    
    -- Show a test icon if icons are enabled
    if self.iconContainer and self.db.profile.notifications.showIcons ~= false then
        local _, _, texture = GetSpellInfo(118) -- Polymorph icon as test
        if texture then
            self.icon:SetTexture(texture)
            self.iconContainer:Show()
            if self.iconBorder then self.iconBorder:Show() end
        else
            self.iconContainer:Hide()
            if self.iconBorder then self.iconBorder:Hide() end
        end
    elseif self.iconContainer then
        self.iconContainer:Hide()
        if self.iconBorder then self.iconBorder:Hide() end
    end
    
    local duration = self.db.profile.notifications.alertDuration or 3.0
    self.hideTime = GetTime() + duration
    self.frame:Show()
end

-- Register module
Blackjack:RegisterModule("VisualAlerts", VisualAlerts)
