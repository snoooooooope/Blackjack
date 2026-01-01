local Blackjack = _G.Blackjack
local LibStub = _G.LibStub
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local LibWindow = LibStub("LibWindow-1.1")

local Config = {
    frame = nil,
    currentTab = nil,
    initialized = false
}

function Config:OnInitialize(db)
    self.db = db or Blackjack.db
    self.db.profile = self.db.profile or {}
    self.db.profile.notifications = self.db.profile.notifications or {}
    self.db.profile.filters = self.db.profile.filters or {}
    self.db.profile.notifications.font = self.db.profile.notifications.font or {}
    self.db.profile.notifications.fontSize = self.db.profile.notifications.fontSize or {}
    self.db.profile.notifications.iconSize = self.db.profile.notifications.iconSize or {}
    self.db.profile.notifications.enabled = self.db.profile.notifications.enabled or {}
    self.db.profile.notifications.sound = self.db.profile.notifications.sound or {}
    self.db.profile.windowSettings = self.db.profile.windowSettings or {}
end
 
function Config:CreateWhitelistTab(content)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("Whitelist")
    title:SetTextColor(1,1,0)

    -- Scrollable list of whitelist entries
    local scrollFrame = CreateFrame("ScrollFrame", nil, content)
    scrollFrame:SetPoint("TOPLEFT", 10, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    content:SetScript("OnSizeChanged", function(self, width, height)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
        local scrollChild = scrollFrame:GetScrollChild()
        if scrollChild then
            scrollChild:SetWidth(scrollFrame:GetWidth())
        end
    end)
    local scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollBar:SetMinMaxValues(0,1)
    scrollBar:SetValueStep(1)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)

    local function refresh()
        for _, child in ipairs({scrollChild:GetChildren()}) do child:Hide() end
        local i = 0
        for spellId, _ in pairs(Blackjack.modules.Filters:GetWhitelist()) do
            i = i + 1
            -- row positioning for whitelist (50px rows)
            local rowHeight = 50
            local rowY = -((i-1) * rowHeight)
            local baselineY = rowY  -- All elements align to this baseline

            -- grid-based column positions for whitelist
            local width = scrollFrame:GetWidth()
            local margin = math.max(10, width * 0.02)

            -- Define grid columns as percentages of width
            local col1 = margin  -- Spell ID column
            local col2 = margin + math.max(120, width * 0.15)  -- Alert text column
            local col3 = margin + math.max(280, width * 0.35)  -- Sound dropdown column
            local col4 = margin + math.max(480, width * 0.65)  -- Preview button column
            local col5 = width - margin - 80  -- Remove button column

            local alertTextPos = col2
            local soundPos = col3
            local previewPos = col4
            local removeBtnPos = col5

            local txt = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            txt:SetPoint("TOPLEFT", margin, baselineY + 2)
            txt:SetText(tostring(spellId))
            local btn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
            btn:SetSize(60, 20)
            btn:SetPoint("TOPLEFT", removeBtnPos, baselineY + 2)
            btn:SetText("Remove")
            btn:SetScript("OnClick", function()
                Blackjack.modules.Filters:RemoveFromWhitelist(spellId)
                refresh()
            end)

            -- Per-spell custom text and sound (global scope)
            if not self.db.profile.spellSettings then self.db.profile.spellSettings = {} end
            if not self.db.profile.spellSettings["GLOBAL"] then self.db.profile.spellSettings["GLOBAL"] = {} end
            local gs = self.db.profile.spellSettings["GLOBAL"][spellId] or {}

            local textLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            textLabel:SetPoint("TOPLEFT", alertTextPos, baselineY + 2)
            textLabel:SetText("Alert Text:")
            local textEdit = CreateFrame("EditBox", nil, scrollChild)
            -- Calculate width based on space available in column (from label to next column)
            local availableWidth = col3 - alertTextPos - 10  -- Space between alert text and sound dropdown
            local alertTextWidth = math.min(160, availableWidth * 0.7)  -- Use 70% of available space for whitelist
            textEdit:SetSize(alertTextWidth, 18)
            textEdit:SetPoint("TOPLEFT", alertTextPos + 65, baselineY + 2)
            textEdit:SetFontObject("GameFontNormal")
            textEdit:SetText(gs.customText or "")
            local bg = textEdit:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.1, 0.1, 0.1, 1)
            textEdit:SetScript("OnEnterPressed", function(selfBox)
                local val = selfBox:GetText() or ""
                if not self.db.profile.spellSettings["GLOBAL"] then self.db.profile.spellSettings["GLOBAL"] = {} end
                if not self.db.profile.spellSettings["GLOBAL"][spellId] then self.db.profile.spellSettings["GLOBAL"][spellId] = {} end
                self.db.profile.spellSettings["GLOBAL"][spellId].customText = val
                -- ensure whitelisted
                Blackjack.modules.Filters:AddToWhitelist(spellId)
            end)

            local sounds = self:GetRegisteredSounds()
            local currentSound = (gs.sound or self.db.profile.notifications.alertSound or sounds[1])
            local dd = self:CreateDropdown(scrollChild, "Sound", sounds, currentSound, soundPos, baselineY + 2, function(value)
                if not self.db.profile.spellSettings["GLOBAL"] then self.db.profile.spellSettings["GLOBAL"] = {} end
                if not self.db.profile.spellSettings["GLOBAL"][spellId] then self.db.profile.spellSettings["GLOBAL"][spellId] = {} end
                self.db.profile.spellSettings["GLOBAL"][spellId].sound = value
                Blackjack.modules.Filters:AddToWhitelist(spellId)
            end, 140)
        local preview = self:CreatePreviewButton(scrollChild, function() return (self.db.profile.spellSettings["GLOBAL"] and self.db.profile.spellSettings["GLOBAL"][spellId] and self.db.profile.spellSettings["GLOBAL"][spellId].sound) or currentSound end, previewPos, baselineY + 2)
        end
        scrollChild:SetSize(scrollFrame:GetWidth(), math.max(1, i * 50))
    end

    -- Add spell by ID
    local addBox = self:CreateEditBox(content, "Spell ID:", 0, 10, -40, function(value)
        if value and value > 0 then
            Blackjack.modules.Filters:AddToWhitelist(value)
            refresh()
        end
    end)

    refresh()
end

function Config:CreateBlacklistTab(content)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("Blacklist")
    title:SetTextColor(1,1,0)

    local scrollFrame = CreateFrame("ScrollFrame", nil, content)
    scrollFrame:SetPoint("TOPLEFT", 10, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    -- Make scroll frame resize with content
    content:SetScript("OnSizeChanged", function(self, width, height)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
        local scrollChild = scrollFrame:GetScrollChild()
        if scrollChild then
            scrollChild:SetWidth(scrollFrame:GetWidth())
        end
    end)

    local scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollBar:SetMinMaxValues(0,1)
    scrollBar:SetValueStep(1)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)

    local function refresh()
        for _, child in ipairs({scrollChild:GetChildren()}) do child:Hide() end
        local i = 0
        for spellId, _ in pairs(Blackjack.modules.Filters:GetBlacklist()) do
            i = i + 1
            -- row positioning for blacklist (50px rows)
            local rowHeight = 50
            local rowY = -((i-1) * rowHeight)
            local baselineY = rowY  -- All elements align to this baseline

            -- Create grid-based column positions for blacklist
            local width = scrollFrame:GetWidth()
            local margin = math.max(10, width * 0.02)

            -- Define grid columns as percentages of width
            local col1 = margin  -- Spell ID column
            local col2 = margin + math.max(120, width * 0.15)  -- Alert text column
            local col3 = margin + math.max(280, width * 0.35)  -- Sound dropdown column
            local col4 = margin + math.max(480, width * 0.65)  -- Preview button column
            local col5 = width - margin - 80  -- Remove button column

            local alertTextPos = col2
            local soundPos = col3
            local previewPos = col4
            local removeBtnPos = col5

            local txt = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            txt:SetPoint("TOPLEFT", margin, baselineY + 2)
            txt:SetText(tostring(spellId))
            local btn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
            btn:SetSize(60, 20)
            btn:SetPoint("TOPLEFT", removeBtnPos, baselineY + 2)
            btn:SetText("Remove")
            btn:SetScript("OnClick", function()
                Blackjack.modules.Filters:RemoveFromBlacklist(spellId)
                refresh()
            end)

            -- Per-spell custom text and sound (global scope)
            if not self.db.profile.spellSettings then self.db.profile.spellSettings = {} end
            if not self.db.profile.spellSettings["GLOBAL"] then self.db.profile.spellSettings["GLOBAL"] = {} end
            local gs = self.db.profile.spellSettings["GLOBAL"][spellId] or {}

            local textLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            textLabel:SetPoint("TOPLEFT", alertTextPos, baselineY + 2)
            textLabel:SetText("Alert Text:")
            local textEdit = CreateFrame("EditBox", nil, scrollChild)
            -- Calculate width based on space available in column (from label to next column)
            local availableWidth = col3 - alertTextPos - 10  -- Space between alert text and sound dropdown
            local alertTextWidth = math.min(160, availableWidth * 0.7)  -- Use 70% of available space for whitelist
            textEdit:SetSize(alertTextWidth, 18)
            textEdit:SetPoint("TOPLEFT", alertTextPos + 55, baselineY + 2)
            textEdit:SetFontObject("GameFontNormal")
            textEdit:SetText(gs.customText or "")
            local bg = textEdit:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.1, 0.1, 0.1, 1)
            textEdit:SetScript("OnEnterPressed", function(selfBox)
                local val = selfBox:GetText() or ""
                if not self.db.profile.spellSettings["GLOBAL"] then self.db.profile.spellSettings["GLOBAL"] = {} end
                if not self.db.profile.spellSettings["GLOBAL"][spellId] then self.db.profile.spellSettings["GLOBAL"][spellId] = {} end
                self.db.profile.spellSettings["GLOBAL"][spellId].customText = val
                -- ensure blacklisted entry keeps override
                Blackjack.modules.Filters:AddToBlacklist(spellId)
            end)

            local sounds = self:GetRegisteredSounds()
            local currentSound = (gs.sound or self.db.profile.notifications.alertSound or sounds[1])
            local dd = self:CreateDropdown(scrollChild, "Sound", sounds, currentSound, soundPos, baselineY + 2, function(value)
                if not self.db.profile.spellSettings["GLOBAL"] then self.db.profile.spellSettings["GLOBAL"] = {} end
                if not self.db.profile.spellSettings["GLOBAL"][spellId] then self.db.profile.spellSettings["GLOBAL"][spellId] = {} end
                self.db.profile.spellSettings["GLOBAL"][spellId].sound = value
                Blackjack.modules.Filters:AddToBlacklist(spellId)
            end, 140)
        local preview = self:CreatePreviewButton(scrollChild, function() return (self.db.profile.spellSettings["GLOBAL"] and self.db.profile.spellSettings["GLOBAL"][spellId] and self.db.profile.spellSettings["GLOBAL"][spellId].sound) or currentSound end, previewPos, baselineY + 2)
        end
        scrollChild:SetSize(scrollFrame:GetWidth(), math.max(1, i * 50))
    end

    local addBox = self:CreateEditBox(content, "Spell ID:", 0, 10, -40, function(value)
        if value and value > 0 then
            Blackjack.modules.Filters:AddToBlacklist(value)
            refresh()
        end
    end)

    refresh()
end

function Config:EnsureInitialized()
    if not self.initialized then
        self:CreatePanel()
        self.initialized = true
    end
    if not self.db then
        self.db = Blackjack.db
    end
end

function Config:CreatePanel()
    if self.frame then return end

    -- Main configuration frame
    self.frame = CreateFrame("Frame", "BlackjackConfigFrame", UIParent)
    self.frame:SetSize(900, 700)
    self.frame:SetPoint("CENTER")
    self.frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    self.frame:SetMovable(true)
    self.frame:SetResizable(true)
    self.frame:SetMinResize(600, 400)
    self.frame:SetMaxResize(1400, 1000)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", self.frame.StartMoving)
    self.frame:SetScript("OnDragStop", self.frame.StopMovingOrSizing)
    self.frame:Hide()

    -- Create resize grip
    local resizeGrip = CreateFrame("Button", nil, self.frame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", -5, 5)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:GetParent():StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeGrip:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:GetParent():StopMovingOrSizing()
            -- Save the new size
            LibWindow.SavePosition(self:GetParent())
            -- Update content layout
            self:GetParent().obj:UpdateLayout()
        end
    end)

    -- Store reference to Config object for resize callbacks
    self.frame.obj = self

    -- Register with LibWindow
    LibWindow.RegisterConfig(self.frame, self.db.profile.windowSettings or {})
    LibWindow.RestorePosition(self.frame)
    LibWindow.MakeDraggable(self.frame)

    local title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -15)
    title:SetText("~ Blackjack ~")

    local close = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() self.frame:Hide() end)

    self.tabs = {
        { name = "General",       func = self.CreateGeneralTab },
        { name = "Notifications", func = self.CreateNotificationsTab },
        { name = "Filters",       func = self.CreateFiltersTab }
    }

    self:CreateTabs()
end

function Config:CreateTabs()
    local tabWidth = 100
    local tabHeight = 25

    for i, tab in ipairs(self.tabs) do
        local btn = CreateFrame("Button", nil, self.frame)
        btn:SetSize(tabWidth, tabHeight)
        btn:SetPoint("TOPLEFT", 20 + ((i - 1) * (tabWidth + 5)), -50)

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("CENTER")
        label:SetText(tab.name)
        btn.label = label

        btn:SetScript("OnClick", function()
            self:ShowTab(tab.name)
        end)

        local tex = btn:CreateTexture()
        tex:SetAllPoints()
        tex:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        btn:SetNormalTexture(tex)
    end
end

function Config:ShowTab(name)
    if self.currentTab then
        self.currentTab:Hide()
    end

    for _, tab in ipairs(self.tabs) do
        if tab.name == name then
            if not tab.content then
                tab.content = CreateFrame("Frame", nil, self.frame)
                tab.content:SetAllPoints()
                tab.func(self, tab.content)
            end
            self.currentTab = tab.content
            tab.content:Show()

            -- Update layout for current content
            self:UpdateLayout()

            -- Clear focus to prevent auto-selection of edit boxes
            C_Timer.After(0.1, function()
                if tab.content and tab.content:IsShown() then
                    local focusFrame = GetCurrentKeyBoardFocus()
                    if focusFrame and focusFrame:GetParent() == tab.content then
                        focusFrame:ClearFocus()
                    end
                end
            end)

            break
        end
    end
end

function Config:CreateGeneralTab(content)
    if not self.db or not self.db.profile then return end

    -- Add debug enable/disable button
    local debugCheck = self:CreateCheckbox(content, "Enable Debug Messages", 10, -10)
    debugCheck:SetChecked(self.db.profile.debug)
    debugCheck:SetScript("OnClick", function(cb)
        self.db.profile.debug = cb:GetChecked()
        Blackjack:DebugMessage("Debug mode " .. (self.db.profile.debug and "enabled" or "disabled"))
    end)

    local missCheck = self:CreateCheckbox(content, "Show missed, dodged & parried spells", 10, -40)
    missCheck:SetChecked(self.db.profile.notifications.showMisses)

    local missFontValue = self.db.profile.notifications.missFontSize or 14
    local missFontEdit = self:CreateEditBox(content, "Font size:", missFontValue, 10, -70,
        function(value)
            self.db.profile.notifications.missFontSize = value
            if Blackjack.modules.VisualAlerts then
                Blackjack.modules.VisualAlerts:UpdateFont()
            end
        end
    )

    if not self.db.profile.notifications.showMisses then
        missFontEdit:Hide()
        if missFontEdit.label then missFontEdit.label:Hide() end
    end

    missCheck:SetScript("OnClick", function(cb)
        self.db.profile.notifications.showMisses = cb:GetChecked()
        Blackjack:DebugMessage("ShowMisses " .. (self.db.profile.notifications.showMisses and "enabled" or "disabled"))
        if self.db.profile.notifications.showMisses then
            missFontEdit:Show()
            if missFontEdit.label then missFontEdit.label:Show() end
        else
            missFontEdit:Hide()
            if missFontEdit.label then missFontEdit.label:Hide() end
        end
    end)
end

function Config:CreateNotificationsTab(content)
    if not self.db or not self.db.profile then return end

    local enableCheck = self:CreateCheckbox(content, "Enable Notifications", 10, -10)
    enableCheck:SetChecked(self.db.profile.notifications.enabled)
    enableCheck:SetScript("OnClick", function(cb)
        self.db.profile.notifications.enabled = cb:GetChecked()
    end)

    local soundCheck = self:CreateCheckbox(content, "Enable Sounds", 10, -50)
    soundCheck:SetChecked(self.db.profile.notifications.sound)
    soundCheck:SetScript("OnClick", function(cb)
        self.db.profile.notifications.sound = cb:GetChecked()
    end)

    self:CreateEditBox(content, "Font Size:", self.db.profile.notifications.fontSize, 10, -100,
        function(value)
            self.db.profile.notifications.fontSize = value
            Blackjack.modules.VisualAlerts:UpdateFont()
        end
    )

    self:CreateEditBox(content, "Icon Size:", self.db.profile.notifications.iconSize, 10, -130,
        function(value)
            self.db.profile.notifications.iconSize = value
        end
    )

    -- Position controls for VisualAlerts
    self:CreateEditBox(content, "Alert X Pos:", self.db.profile.notifications.visualAlert_x or 0, 300, -10,
        function(value)
            self.db.profile.notifications.visualAlert_x = value
            -- Update position if VisualAlerts is active
            if Blackjack.modules.VisualAlerts and Blackjack.modules.VisualAlerts.frame then
                Blackjack.modules.VisualAlerts.frame:ClearAllPoints()
                Blackjack.modules.VisualAlerts.frame:SetPoint(
                    self.db.profile.notifications.visualAlert_point or "CENTER",
                    UIParent,
                    self.db.profile.notifications.visualAlert_point or "CENTER",
                    self.db.profile.notifications.visualAlert_x or 0,
                    self.db.profile.notifications.visualAlert_y or 0
                )
            end
        end
    )

    self:CreateEditBox(content, "Alert Y Pos:", self.db.profile.notifications.visualAlert_y or 0, 300, -40,
        function(value)
            self.db.profile.notifications.visualAlert_y = value
            -- Update position if VisualAlerts is active
            if Blackjack.modules.VisualAlerts and Blackjack.modules.VisualAlerts.frame then
                Blackjack.modules.VisualAlerts.frame:ClearAllPoints()
                Blackjack.modules.VisualAlerts.frame:SetPoint(
                    self.db.profile.notifications.visualAlert_point or "CENTER",
                    UIParent,
                    self.db.profile.notifications.visualAlert_point or "CENTER",
                    self.db.profile.notifications.visualAlert_x or 0,
                    self.db.profile.notifications.visualAlert_y or 0
                )
            end
        end
    )

    -- Get fonts registered
    local availableFonts = self:GetRegisteredFonts()
    local currentFont = self.db.profile.notifications.font or "Avant Garde LT Bold"

    self:CreateDropdown(content, "Notification Font", availableFonts,
        currentFont, 10, -170,
        function(value)
            self.db.profile.notifications.font = value
            Blackjack.modules.VisualAlerts:UpdateFont()
        end,
        200
    )

    -- Sound control buttons (inspired by SoundAlerter's approach, I literally just ripped the code from there)
    -- Addon sounds only button
    local addonOnlyButton = CreateFrame("Button", nil, content)
    addonOnlyButton:SetSize(100, 22)
    addonOnlyButton:SetPoint("TOPLEFT", 10, -220)

    -- Create addon only button textures
    local normalTexture = addonOnlyButton:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints()
    normalTexture:SetColorTexture(0.3, 0.3, 0.3, 1)
    addonOnlyButton:SetNormalTexture(normalTexture)

    local highlightTexture = addonOnlyButton:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints()
    highlightTexture:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    addonOnlyButton:SetHighlightTexture(highlightTexture)

    -- Create addon only button text
    local text = addonOnlyButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER")
    text:SetText("Addon Sounds Only")
    addonOnlyButton.text = text

    addonOnlyButton:SetScript("OnClick", function()
        -- Set other game sounds to minimum, keep Blackjack sounds audible
        SetCVar("Sound_AmbienceVolume", "0")
        SetCVar("Sound_SFXVolume", "0")
        SetCVar("Sound_MusicVolume", "0")
        print("Blackjack: Addon sounds only enabled. Other game sounds muted.")
    end)

    -- Reset sounds button
    local resetButton = CreateFrame("Button", nil, content)
    resetButton:SetSize(100, 22)
    resetButton:SetPoint("TOPLEFT", 120, -220)

    -- Create reset button textures
    local resetNormal = resetButton:CreateTexture(nil, "BACKGROUND")
    resetNormal:SetAllPoints()
    resetNormal:SetColorTexture(0.3, 0.3, 0.3, 1)
    resetButton:SetNormalTexture(resetNormal)

    local resetHighlight = resetButton:CreateTexture(nil, "HIGHLIGHT")
    resetHighlight:SetAllPoints()
    resetHighlight:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    resetButton:SetHighlightTexture(resetHighlight)

    -- Create reset button text
    local resetText = resetButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetText:SetPoint("CENTER")
    resetText:SetText("Reset Sounds")
    resetButton.text = resetText

    resetButton:SetScript("OnClick", function()
        -- Reset all sound volumes to default
        SetCVar("Sound_MasterVolume", "1.0")
        SetCVar("Sound_AmbienceVolume", "1.0")
        SetCVar("Sound_SFXVolume", "1.0")
        SetCVar("Sound_MusicVolume", "1.0")
        print("Blackjack: Sound volumes reset to defaults.")
    end)

    -- Create test notification button moved to bottom right
    local testButton = CreateFrame("Button", nil, content)
    testButton:SetSize(120, 25)
    testButton:SetPoint("TOPLEFT", 50, -260)

    -- Create test notification button textures
    local normalTexture = testButton:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints()
    normalTexture:SetColorTexture(0.3, 0.3, 0.3, 1)
    testButton:SetNormalTexture(normalTexture)

    local highlightTexture = testButton:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints()
    highlightTexture:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    testButton:SetHighlightTexture(highlightTexture)

    -- Create test notification button text
    local text = testButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText("Test Notification")
    testButton.text = text

    testButton:SetScript("OnClick", function()
        -- Trigger a test notification (visual + sound)
        if Blackjack.modules.VisualAlerts then
            -- Ensure VisualAlerts is initialized
            if not Blackjack.modules.VisualAlerts.text then
                Blackjack.modules.VisualAlerts:OnInitialize(Blackjack.db)
            end
            Blackjack.modules.VisualAlerts:ShowTestNotification()
        else
            print("Blackjack: VisualAlerts module not found")
        end

        -- Also play test sound through SoundAlerts
        if Blackjack.modules.SoundAlerts then
            -- Ensure SoundAlerts is initialized with database
            if not Blackjack.modules.SoundAlerts.db then
                Blackjack.modules.SoundAlerts:OnInitialize(Blackjack.db)
            end
            Blackjack.modules.SoundAlerts:PlayTest()
        else
            print("Blackjack: SoundAlerts module not found")
        end
    end)

    -- Get available sounds registered
    local availableSounds = self:GetRegisteredSounds()

    -- Add sound selection dropdowns for different events
    self:CreateDropdown(content, "Alert Sound", availableSounds,
        self.db.profile.notifications.alertSound or "Attention", 250, -200,
        function(value)
            self.db.profile.notifications.alertSound = value
        end
    )

    self:CreatePreviewButton(content, function() return self.db.profile.notifications.alertSound or "Attention" end, 450, -200)

    self:CreateDropdown(content, "Interrupt Sound", availableSounds,
        self.db.profile.notifications.interruptSound or "Kick", 250, -240,
        function(value)
            self.db.profile.notifications.interruptSound = value
        end
    )

    self:CreatePreviewButton(content, function() return self.db.profile.notifications.interruptSound or "Kick" end, 450, -240)

    self:CreateDropdown(content, "Dispel Sound", availableSounds,
        self.db.profile.notifications.dispelSound or "Dispel", 250, -280,
        function(value)
            self.db.profile.notifications.dispelSound = value
        end
    )

    self:CreatePreviewButton(content, function() return self.db.profile.notifications.dispelSound or "Dispel" end, 450, -280)
end

function Config:CreateFiltersTab(content)
    if not self.db or not self.db.profile then return end

    -- Create sub-tabs for filter management
    self.filterTabs = {
        { name = "General",     func = self.CreateGeneralFiltersTab },
        { name = "Death Knight", func = self.CreateClassFiltersTab, class = "DEATHKNIGHT" },
        { name = "Druid",       func = self.CreateClassFiltersTab, class = "DRUID" },
        { name = "Hunter",      func = self.CreateClassFiltersTab, class = "HUNTER" },
        { name = "Mage",        func = self.CreateClassFiltersTab, class = "MAGE" },
        { name = "Paladin",     func = self.CreateClassFiltersTab, class = "PALADIN" },
        { name = "Priest",      func = self.CreateClassFiltersTab, class = "PRIEST" },
        { name = "Rogue",       func = self.CreateClassFiltersTab, class = "ROGUE" },
        { name = "Shaman",      func = self.CreateClassFiltersTab, class = "SHAMAN" },
        { name = "Warlock",     func = self.CreateClassFiltersTab, class = "WARLOCK" },
        { name = "Warrior",     func = self.CreateClassFiltersTab, class = "WARRIOR" }
        ,{ name = "Whitelist",   func = self.CreateWhitelistTab },
        { name = "Blacklist",   func = self.CreateBlacklistTab }
    }

    -- Create sub-tab buttons
    local tabWidth = 80
    local tabHeight = 20
    local startX = 10
    local startY = -10

    for i, tab in ipairs(self.filterTabs) do
        local btn = CreateFrame("Button", nil, content)
        btn:SetSize(tabWidth, tabHeight)

        -- Calculate position (growing down)
        local x = startX
        local y = startY - ((i-1) * (tabHeight + 2))

        btn:SetPoint("TOPLEFT", x, y)

        -- Create filter sub-tab button textures
        local normalTexture = btn:CreateTexture(nil, "BACKGROUND")
        normalTexture:SetAllPoints()
        normalTexture:SetColorTexture(0.2, 0.2, 0.2, 1)
        btn:SetNormalTexture(normalTexture)

        local highlightTexture = btn:CreateTexture(nil, "HIGHLIGHT")
        highlightTexture:SetAllPoints()
        highlightTexture:SetColorTexture(0.4, 0.4, 0.4, 1)
        btn:SetHighlightTexture(highlightTexture)

        -- Create text
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER")
        text:SetText(tab.name)
        btn.text = text

        btn:SetScript("OnClick", function()
            self:ShowFilterSubTab(tab.name)
        end)

        tab.button = btn
    end

    -- Create filter content area for sub-tabs
    self.filterContent = CreateFrame("Frame", nil, content)
    self.filterContent:SetAllPoints()

    -- Show default filter sub-tab (General)
    self:ShowFilterSubTab("General")
end

function Config:UpdateLayout()
    if not self.frame then return end

    local width, height = self.frame:GetSize()

    -- Update tab content area
    if self.currentTab then
        self.currentTab:SetPoint("TOPLEFT", 20, -80)
        self.currentTab:SetPoint("BOTTOMRIGHT", -20, 20)

        -- Update scroll children width to match new content width
        self:UpdateScrollContentWidth(self.currentTab)
    end

    -- Update filter content area
    if self.filterContent then
        self.filterContent:SetPoint("TOPLEFT", 100, -10)
        self.filterContent:SetPoint("BOTTOMRIGHT", -10, 10)

        -- Update scroll children in filter content
        self:UpdateScrollContentWidth(self.filterContent)
    end
end

function Config:UpdateScrollContentWidth(parentFrame)
    -- Find all scroll frames in the parent and update their content width
    for _, child in ipairs({parentFrame:GetChildren()}) do
        if child:GetObjectType() == "ScrollFrame" then
            -- Update scroll child width to match scroll frame width
            local scrollChild = child:GetScrollChild()
            if scrollChild then
                local newWidth = child:GetWidth()
                scrollChild:SetWidth(newWidth)
                -- Reposition elements in the scroll child based on new width
                self:UpdateElementPositions(scrollChild, newWidth)
            end
        end
    end
end

function Config:UpdateElementPositions(scrollChild, width)
    -- Determine if this is whitelist/blacklist (50px rows) or class filters (25px rows)
    local hasRemoveButton = false
    for _, child in ipairs({scrollChild:GetChildren()}) do
        if child:GetObjectType() == "Button" and child:GetText() == "Remove" then
            hasRemoveButton = true
            break
        end
    end

    -- Create grid-based column positions for consistent alignment
    local margin = math.max(10, width * 0.02)

    local col1 = margin  -- Spell name/ID column
    local col2 = margin + math.max(120, width * 0.15)  -- Alert text column
    local col3 = margin + math.max(280, width * 0.35)  -- Sound dropdown column
    local col4 = margin + math.max(480, width * 0.65)  -- Preview button column
    local col5 = width - margin - 80  -- Checkbox/remove button column

    -- Determine row height based on content type
    local rowHeight = hasRemoveButton and 50 or 25  -- 50px for whitelist/blacklist, 25px for class filters

    -- Update positions of all elements in the scroll child using grid columns
    for _, child in ipairs({scrollChild:GetChildren()}) do
        local objType = child:GetObjectType()
        local currentY = select(2, child:GetPoint())
        local rowIndex = math.floor((-currentY + (rowHeight/2)) / rowHeight)
        local baselineY = -(rowIndex * rowHeight)

        -- Add slight vertical offset for text elements in taller rows (whitelist/blacklist)
        local textOffset = (rowHeight == 50) and 2 or 0

        if objType == "FontString" then
            -- Spell name/ID labels - column 1
            if child:GetText() and not child:GetText():find(":") then  -- Not a label like "Alert Text:"
                child:SetPoint("TOPLEFT", col1, baselineY + textOffset)
            end
        elseif objType == "CheckButton" then
            -- Enable/disable checkboxes (class filters) or remove buttons (whitelist/blacklist) - column 5
            child:SetPoint("TOPLEFT", col5, baselineY + textOffset)
        elseif objType == "EditBox" then
            -- Alert text edit boxes - column 2 (with offset for label)
            child:SetPoint("TOPLEFT", col2 + 55, baselineY + textOffset)
        elseif objType == "Frame" and child.GetName and child:GetName() and child:GetName():find("Dropdown") then
            -- Sound dropdowns - column 3
            child:SetPoint("TOPLEFT", col3, baselineY + textOffset)
        elseif objType == "Button" and child:GetWidth() == 60 then  -- Preview buttons are 60 wide
            -- Preview buttons - column 4
            child:SetPoint("TOPLEFT", col4, baselineY + textOffset)
        end

        -- Handle labels for edit boxes - column 2
        if objType == "FontString" and child:GetText() and child:GetText():find("Alert Text:") then
            child:SetPoint("TOPLEFT", col2, baselineY + textOffset)
        end
    end
end

function Config:ShowFilterSubTab(name)
    -- Hide current sub-tab content
    if self.currentFilterTab then
        self.currentFilterTab:Hide()
    end

    -- Update button appearances
    for _, tab in ipairs(self.filterTabs) do
        if tab.name == name then
            tab.button.text:SetTextColor(1, 1, 0)  -- Yellow for selected
        else
            tab.button.text:SetTextColor(1, 1, 1)  -- White for unselected
        end
    end

    -- Show selected sub-tab
    for _, tab in ipairs(self.filterTabs) do
        if tab.name == name then
            if not tab.content then
                tab.content = CreateFrame("Frame", nil, self.filterContent)
                tab.content:SetAllPoints()
                tab.func(self, tab.content, tab.class)
            end
            self.currentFilterTab = tab.content
            tab.content:Show()
            break
        end
    end
end

function Config:CreateGeneralFiltersTab(content)
    local info = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetPoint("TOPLEFT", 10, -10)
    info:SetText("General Filter Settings")
    info:SetTextColor(1, 1, 0)

    -- General filter options
    local enableAllCheck = self:CreateCheckbox(content, "Enable All Filters", 10, -40)
    enableAllCheck:SetChecked(Blackjack.modules.Filters:IsAllFiltersEnabled())
    enableAllCheck:SetScript("OnClick", function(cb)
        Blackjack.modules.Filters:SetAllFiltersEnabled(cb:GetChecked())
    end)

    local info2 = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info2:SetPoint("TOPLEFT", 10, -80)
    info2:SetText("Use class-specific tabs to configure\nspell filters for each class.")
end

function Config:CreateClassFiltersTab(content, class)
    if not class then return end

    local className = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    className:SetPoint("TOPLEFT", 10, -10)
    className:SetText(class .. " Filters")
    className:SetTextColor(1, 1, 0)

    -- Get spells
    local spells = Blackjack.modules.SpellDB:GetSpellsForClass(class)

    if #spells == 0 then
        local noSpells = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noSpells:SetPoint("TOPLEFT", 10, -40)
        noSpells:SetText("No spells configured for " .. class)
        return
    end

    -- Create list of spells
    local scrollFrame = CreateFrame("ScrollFrame", nil, content)
    scrollFrame:SetPoint("TOPLEFT", 10, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    -- Make scroll frame resize with content
    content:SetScript("OnSizeChanged", function(self, width, height)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
        -- Update scroll content width
        local scrollChild = scrollFrame:GetScrollChild()
        if scrollChild then
            scrollChild:SetWidth(scrollFrame:GetWidth())
        end
    end)

    -- Create scroll bar
    local scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollBar:SetMinMaxValues(0, 1)
    scrollBar:SetValueStep(1)
    scrollBar:SetValue(0)
    scrollBar:SetWidth(16)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), #spells * 25)
    scrollFrame:SetScrollChild(scrollChild)

    -- Set up scrolling
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local maxVal = math.max(0, #spells * 25 - scrollFrame:GetHeight())
        local newVal = math.max(0, math.min(maxVal, current - delta * 25))
        scrollBar:SetValue(newVal)
    end)

    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollChild:SetPoint("TOPLEFT", 0, value)
    end)

    for i, spellInfo in ipairs(spells) do
        -- Calculate consistent row positioning
        local rowHeight = 25
        local rowY = -((i-1) * rowHeight)
        local baselineY = rowY  -- All elements align to this baseline

        -- Create grid-based column positions
        local width = scrollFrame:GetWidth()
        local margin = math.max(10, width * 0.02)

        -- Define grid columns as percentages of width
        local col1 = margin  -- Spell name column
        local col2 = margin + math.max(120, width * 0.15)  -- Alert text column
        local col3 = margin + math.max(280, width * 0.35)  -- Sound dropdown column
        local col4 = margin + math.max(480, width * 0.65)  -- Preview button column
        local col5 = width - margin - 80  -- Checkbox column

        local spellNameWidth = col2 - col1 - margin
        local alertTextPos = col2
        local soundPos = col3
        local previewPos = col4
        local checkboxPos = col5

        -- Spell name
        local spellName = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        spellName:SetPoint("TOPLEFT", margin, baselineY)
        spellName:SetText(spellInfo.name or spellInfo.id)

        -- Enable/disable checkbox
        local spellCheck = self:CreateCheckbox(scrollChild, "", checkboxPos, baselineY)
        spellCheck:SetChecked(Blackjack.modules.Filters:IsSpellEnabled(class, spellInfo.id))
        spellCheck:SetScript("OnClick", function(cb)
            Blackjack.modules.Filters:SetSpellEnabled(class, spellInfo.id, cb:GetChecked())
        end)
        -- Ensure spellSettings table exists
        if not self.db.profile.spellSettings then self.db.profile.spellSettings = {} end
        if not self.db.profile.spellSettings[class] then self.db.profile.spellSettings[class] = {} end
        local classSettings = self.db.profile.spellSettings[class]
        local s = classSettings[spellInfo.id] or {}

        -- Alert text edit box
        local textLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        textLabel:SetPoint("TOPLEFT", alertTextPos, baselineY)
        textLabel:SetText("Alert Text:")
        local textEdit = CreateFrame("EditBox", nil, scrollChild)
        -- Calculate width based on space available in column (from label to next column)
        local availableWidth = col3 - alertTextPos - 10  -- Space between alert text and sound dropdown
        local alertTextWidth = math.min(120, availableWidth * 0.6)  -- Use 60% of available space
        textEdit:SetSize(alertTextWidth, 20)
        textEdit:SetPoint("TOPLEFT", alertTextPos + 55, baselineY)
        textEdit:SetFontObject("GameFontNormal")
        textEdit:SetText(s.customText or "")
        local bg = textEdit:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.1, 1)
        textEdit:SetScript("OnEnterPressed", function(selfBox)
            local val = selfBox:GetText() or ""
            if not self.db.profile.spellSettings[class] then self.db.profile.spellSettings[class] = {} end
            if not self.db.profile.spellSettings[class][spellInfo.id] then self.db.profile.spellSettings[class][spellInfo.id] = {} end
            self.db.profile.spellSettings[class][spellInfo.id].customText = val
            -- update local reference
            classSettings[spellInfo.id] = self.db.profile.spellSettings[class][spellInfo.id]
            -- ensure this spell is whitelisted so custom alerts always show
            Blackjack.modules.Filters:AddToWhitelist(spellInfo.id)
        end)

        -- Sound dropdown
        local sounds = self:GetRegisteredSounds()
        local currentSound = (s.sound or self.db.profile.notifications.alertSound or sounds[1])
        local dd = self:CreateDropdown(scrollChild, "Sound", sounds, currentSound, soundPos, baselineY, function(value)
            if not self.db.profile.spellSettings[class] then self.db.profile.spellSettings[class] = {} end
            if not self.db.profile.spellSettings[class][spellInfo.id] then self.db.profile.spellSettings[class][spellInfo.id] = {} end
            self.db.profile.spellSettings[class][spellInfo.id].sound = value
            -- ensure this spell is whitelisted when assigning a custom sound
            Blackjack.modules.Filters:AddToWhitelist(spellInfo.id)
        end, 140)
        -- Preview button next to dropdown
        local previewPos = soundPos + 140 + math.max(50, width * 0.07)
        local preview = self:CreatePreviewButton(scrollChild, function() return (self.db.profile.spellSettings[class] and self.db.profile.spellSettings[class][spellInfo.id] and self.db.profile.spellSettings[class][spellInfo.id].sound) or currentSound end, previewPos, baselineY)
    end
end


function Config:CreateCheckbox(parent, text, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)

    -- Create checkbox text label
    local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    label:SetText(text or "")

    -- Expose label for callers so they can anchor other controls to it
    cb.label = label

    return cb
end

function Config:CreateSlider(parent, text, min, max, value, x, y, callback)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetSize(200, 20)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(min, max)
    slider:SetValue(value or min)
    slider:SetValueStep(0.1)

    -- Create slider background texture
    local bg = slider:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    -- Create slider thumb texture
    local thumb = slider:CreateTexture(nil, "ARTWORK")
    thumb:SetSize(16, 16)
    thumb:SetColorTexture(0.8, 0.8, 0.8, 1)
    slider:SetThumbTexture(thumb)

    -- Create slider text label with current value
    local label = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOM", slider, "TOP", 0, 5)

    -- Function to update slider text label with current value
    local function updateLabel(val)
        label:SetText(string.format("%s (%.1f)", text or "", val))
    end

    -- Slider text label initial value
    updateLabel(value or min)

    -- Create min/max slider text labels
    local minLabel = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
    minLabel:SetText(tostring(min))

    local maxLabel = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    maxLabel:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
    maxLabel:SetText(tostring(max))

    slider:SetScript("OnValueChanged", function(_, val)
        updateLabel(val)
        if callback then callback(val) end
    end)

    return slider
end

function Config:CreateDropdown(parent, text, options, current, x, y, callback, width)
    -- Generate a unique name for the dropdown (this is to prevent conflicts with other dropdowns)
    local dropdownName = "BlackjackDropdown" .. math.random(100000, 999999)
    local dd = CreateFrame("Frame", dropdownName, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", x, y)

    -- Set width for proper text display (default 150, wider for fonts)
    UIDropDownMenu_SetWidth(dd, width or 130)

    -- Handle nil values safely
    text = text or "Select Option"
    current = current or (options and #options > 0 and options[1]) or "Unknown"
    options = options or {}

    -- Initialize dropdown menu with proper closure capture
    UIDropDownMenu_Initialize(dd, function()
        for _, option in ipairs(options) do
            UIDropDownMenu_AddButton({
                text = option,
                func = function()
                    local textField = _G[dd:GetName() .. "Text"]
                    if textField then
                        textField:SetText(option)
                    end
                    if callback then callback(option) end
                end
            })
        end
    end)

    -- Set initial display text using the dropdown's text field directly
    if current and current ~= "" then
        local textField = _G[dd:GetName() .. "Text"]
        if textField then
            textField:SetText(current)
        end
    end

    return dd
end

function Config:CreatePreviewButton(parent, getSoundNameFunc, x, y)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(60, 22)
    button:SetPoint("TOPLEFT", x, y)

    -- Create preview button textures
    local normalTexture = button:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints()
    normalTexture:SetColorTexture(0.3, 0.3, 0.3, 1)
    button:SetNormalTexture(normalTexture)

    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints()
    highlightTexture:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    button:SetHighlightTexture(highlightTexture)

    -- Create preview button text
    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText("Preview")
    button.text = text

    button:SetScript("OnClick", function()
        local soundName = getSoundNameFunc()
        if soundName and soundName ~= "" then
            local soundPath = "Interface\\AddOns\\Blackjack\\Media\\Sounds\\" .. soundName .. ".mp3"
            PlaySoundFile(soundPath)
        end
    end)

    return button
end

function Config:CreateEditBox(parent, label, currentValue, x, y, callback)
    -- Create edit box label
    local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", x, y)
    labelText:SetText(label)

    -- Create edit box
    local editBox = CreateFrame("EditBox", nil, parent)
    editBox:SetSize(50, 20)
    editBox:SetPoint("TOPLEFT", x + 80, y - 2)
    editBox:SetFontObject("GameFontNormal")
    editBox:SetText(tostring(currentValue or ""))

    -- Create background
    local bg = editBox:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 1)

    -- Create border
    local border = editBox:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetColorTexture(0.5, 0.5, 0.5, 1)

    -- Make edit box only focusable when clicked
    editBox:EnableKeyboard(false)  -- Disable keyboard input initially

    editBox:SetScript("OnMouseDown", function(self)
        self:EnableKeyboard(true)  -- Enable keyboard input when clicked
        self:SetFocus()
    end)

    -- Create OK button
    local okButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    okButton:SetSize(40, 20)
    okButton:SetPoint("TOPLEFT", x + 135, y - 2)
    okButton:SetText("OK")

    local function applyValue()
        editBox:ClearFocus()
        editBox:EnableKeyboard(false)  -- Disable keyboard input after applying
        local value = tonumber(editBox:GetText())
        if value and value == math.floor(value) then  -- Ensure it's an integer
            callback(value)
            currentValue = value
        else
            -- Reset to current value if invalid
            editBox:SetText(tostring(currentValue or ""))
        end
    end

    editBox:SetScript("OnEnterPressed", applyValue)
    okButton:SetScript("OnClick", applyValue)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:EnableKeyboard(false)  -- Disable keyboard input when escaping
        self:SetText(tostring(currentValue or ""))
    end)

    -- expose the label so callers can hide/show it if needed
    editBox.label = labelText
    return editBox
end

function Config:ToggleConfig()
    self:EnsureInitialized()

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        if not self.currentTab then
            self:ShowTab(self.tabs[1].name)
        end
        self.frame:Show()
        self.frame:Raise()
    end
end

function Config:GetRegisteredFonts()
    -- Return the list of fonts registered by this addon
    -- This should match the fonts registered in LSMRegister.lua
    return {
        "Avant Garde LT Bold",
        -- Add more font names here as you register them in LSMRegister.lua
    }
end

function Config:GetRegisteredSounds()
    -- Return the list of sounds registered by this addon
    -- This should match the sounds registered in LSMRegister.lua
    return {
        "Interrupted",
        "Attention",
        "Chime",
        "Kite",
        "Kick",
        "Pop",
        "Immunity",
        "Dispel",
        "Trinket",
        "Warning",
        "Drinking",
        "Resurrection",
        "Reflect",
        "Grounding Totem",
        "Purge",
        "Stealth",
        "Bell",
        -- Add more sound names here as you register them in LSMRegister.lua
    }
end

Blackjack:RegisterModule("Config", Config)
