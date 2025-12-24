local Blackjack = _G.Blackjack
local LibStub = _G.LibStub
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

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
    self.frame:SetSize(600, 400)
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
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", self.frame.StartMoving)
    self.frame:SetScript("OnDragStop", self.frame.StopMovingOrSizing)
    self.frame:Hide()

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
                tab.content:SetPoint("TOPLEFT", 20, -80)
                tab.content:SetPoint("BOTTOMRIGHT", -20, 20)
                tab.func(self, tab.content)
            end
            self.currentTab = tab.content
            tab.content:Show()

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
    self.filterContent:SetPoint("TOPLEFT", 100, -10)
    self.filterContent:SetPoint("BOTTOMRIGHT", -10, 10)

    -- Show default filter sub-tab (General)
    self:ShowFilterSubTab("General")
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

    -- Create scrollable list of spells
    local scrollFrame = CreateFrame("ScrollFrame", nil, content)
    scrollFrame:SetPoint("TOPLEFT", 10, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    -- Create scroll bar (this is the scroll bar that appears when the list of spells is too long to fit on the screen)
    local scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollBar:SetMinMaxValues(0, 1)
    scrollBar:SetValueStep(1)
    scrollBar:SetValue(0)
    scrollBar:SetWidth(16)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(400, #spells * 25)
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
        local yPos = -((i-1) * 25)

        -- Spell name
        local spellName = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        spellName:SetPoint("TOPLEFT", 10, yPos)
        spellName:SetText(spellInfo.name or spellInfo.id)

        -- Enable/disable checkbox
        local spellCheck = self:CreateCheckbox(scrollChild, "", 300, yPos)
        spellCheck:SetChecked(Blackjack.modules.Filters:IsSpellEnabled(class, spellInfo.id))
        spellCheck:SetScript("OnClick", function(cb)
            Blackjack.modules.Filters:SetSpellEnabled(class, spellInfo.id, cb:GetChecked())
        end)
    end
end


function Config:CreateCheckbox(parent, text, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)

    -- Create checkbox text label
    local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    label:SetText(text or "")

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
            -- Try to play sound directly using file path
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
