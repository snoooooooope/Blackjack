local Blackjack = _G.Blackjack
local LibStub = _G.LibStub
local LSM = LibStub("LibSharedMedia-3.0")
local LibWindow = LibStub("LibWindow-1.1")

local BuiltInSounds = {
    "Interrupted", "Attention", "Chime", "Kite", "Kick", "Pop", "Immunity", 
    "Dispel", "Trinket", "Warning", "Drinking", "Resurrection", "Reflect", 
    "Grounding Totem", "Purge", "Stealth", "Bell"
}

local Config = {
    frame = nil,
    currentTab = nil,
    initialized = false
}

-- Theme Constants
local Theme = {
    bg = {0.1, 0.1, 0.1, 0.95},
    border = {0, 0, 0, 1},
    header = {0.15, 0.15, 0.15, 1},
    rowOdd = {0.15, 0.15, 0.15, 0.5},
    rowEven = {0.2, 0.2, 0.2, 0.5},
    button = {0.2, 0.2, 0.2, 1},
    buttonHover = {0.3, 0.3, 0.3, 1},
    text = {0.9, 0.9, 0.9, 1},
    accent = {0.4, 0.6, 1, 1},
    editbox = {0.15, 0.15, 0.15, 0.8},
}

local function ApplyDarkBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropColor(unpack(Theme.bg))
    frame:SetBackdropBorderColor(unpack(Theme.border))
end

local function ApplyButtonStyle(button)
    ApplyDarkBackdrop(button)
    button:SetBackdropColor(unpack(Theme.button))
    button:SetScript("OnEnter", function(self) self:SetBackdropColor(unpack(Theme.buttonHover)) end)
    button:SetScript("OnLeave", function(self) self:SetBackdropColor(unpack(Theme.button)) end)
    local text = button:GetFontString()
    if text then text:SetTextColor(unpack(Theme.text)) end
end

function Config:OnInitialize(db)
    self.db = db or Blackjack.db
    self.db.profile = self.db.profile or {}
    self.db.profile.notifications = self.db.profile.notifications or {}
    self.db.profile.filters = self.db.profile.filters or {}
    self.db.profile.notifications.font = self.db.profile.notifications.font or {}
    self.db.profile.windowSettings = self.db.profile.windowSettings or {}
    self.db.profile.spellSettings = self.db.profile.spellSettings or {}
end

function Config:EnsureInitialized()
    if not self.initialized then
        self:CreatePanel()
        self.initialized = true
    end
end

function Config:ToggleConfig()
    self:EnsureInitialized()
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        if not self.currentTab then self:ShowTab(self.tabs[1].name) end
        self.frame:Show()
        self.frame:Raise()
    end
end

function Config:CreatePanel()
    if self.frame then return end

    self.frame = CreateFrame("Frame", "BlackjackConfigFrame", UIParent)
    self.frame:SetSize(900, 600)
    self.frame:SetPoint("CENTER")
    ApplyDarkBackdrop(self.frame)
    self.frame:SetMovable(true)
    self.frame:SetResizable(true)
    self.frame:SetMinResize(850, 500)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", self.frame.StartMoving)
    self.frame:SetScript("OnDragStop", function()
        self.frame:StopMovingOrSizing()
        LibWindow.SavePosition(self.frame)
    end)
    self.frame:Hide()

    local title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 20, -15)
    title:SetText("~ Blackjack ~")
    title:SetTextColor(unpack(Theme.accent))

    local close = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() self.frame:Hide() end)

    local resize = CreateFrame("Button", nil, self.frame)
    resize:SetSize(16, 16)
    resize:SetPoint("BOTTOMRIGHT", -5, 5)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resize:SetScript("OnMouseDown", function() self.frame:StartSizing("BOTTOMRIGHT") end)
    resize:SetScript("OnMouseUp", function() self.frame:StopMovingOrSizing(); LibWindow.SavePosition(self.frame) end)

    self.frame.obj = self
    LibWindow.RegisterConfig(self.frame, self.db.profile.windowSettings)
    LibWindow.RestorePosition(self.frame)
    LibWindow.MakeDraggable(self.frame)

    self.tabsContainer = CreateFrame("Frame", nil, self.frame)
    self.tabsContainer:SetPoint("TOPLEFT", 20, -50)
    self.tabsContainer:SetPoint("BOTTOMLEFT", 20, 20)
    self.tabsContainer:SetWidth(140)
    ApplyDarkBackdrop(self.tabsContainer)
    self.tabsContainer:SetBackdropColor(unpack(Theme.header))

    self.contentContainer = CreateFrame("Frame", nil, self.frame)
    self.contentContainer:SetPoint("TOPLEFT", self.tabsContainer, "TOPRIGHT", 10, 0)
    self.contentContainer:SetPoint("BOTTOMRIGHT", -20, 20)
    ApplyDarkBackdrop(self.contentContainer)
    self.contentContainer:SetBackdropColor(0.15, 0.15, 0.15, 0.5)

    self.tabs = {
        { name = "General",       func = self.CreateGeneralTab },
        { name = "Notifications", func = self.CreateNotificationsTab },
        { name = "Filters",       func = self.CreateFiltersTab }
    }
    self:CreateTabs()
end

function Config:CreateTabs()
    local buttonHeight = 35
    for i, tab in ipairs(self.tabs) do
        local btn = CreateFrame("Button", nil, self.tabsContainer)
        btn:SetHeight(buttonHeight)
        btn:SetPoint("TOPLEFT", 0, -((i-1)*buttonHeight))
        btn:SetPoint("TOPRIGHT", 0, -((i-1)*buttonHeight))
        
        btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", tile = false, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
        btn:SetBackdropColor(0,0,0,0)
        
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", 15, 0)
        label:SetText(tab.name)
        label:SetTextColor(unpack(Theme.text))
        btn.label = label
        
        local bar = btn:CreateTexture(nil, "OVERLAY")
        bar:SetWidth(4)
        bar:SetPoint("TOPLEFT", 0, 0)
        bar:SetPoint("BOTTOMLEFT", 0, 0)
        bar:SetColorTexture(unpack(Theme.accent))
        bar:Hide()
        btn.bar = bar

        btn:SetScript("OnEnter", function() if self.currentTabName ~= tab.name then btn:SetBackdropColor(unpack(Theme.buttonHover)) end end)
        btn:SetScript("OnLeave", function() if self.currentTabName ~= tab.name then btn:SetBackdropColor(0,0,0,0) end end)
        btn:SetScript("OnClick", function() self:ShowTab(tab.name) end)
        tab.button = btn
    end
end

function Config:ShowTab(name)
    if self.currentTabFrame then self.currentTabFrame:Hide() end
    self.currentTabName = name

    for _, tab in ipairs(self.tabs) do
        if tab.name == name then
            tab.button.bar:Show()
            tab.button:SetBackdropColor(0.25, 0.25, 0.25, 1)
            tab.button.label:SetTextColor(1, 1, 1, 1)
            if not tab.frame then
                tab.frame = CreateFrame("Frame", nil, self.contentContainer)
                tab.frame:SetAllPoints()
                tab.func(self, tab.frame)
            end
            self.currentTabFrame = tab.frame
            tab.frame:Show()
        else
            tab.button.bar:Hide()
            tab.button:SetBackdropColor(0,0,0,0)
            tab.button.label:SetTextColor(unpack(Theme.text))
        end
    end
end

function Config:CreateScrollList(parent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetPoint("TOPLEFT", 10, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    local scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollBar:SetMinMaxValues(0, 1)
    scrollBar:SetValueStep(1)
    scrollBar:SetWidth(16)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    scrollFrame:SetScript("OnSizeChanged", function(self, w, h) scrollChild:SetWidth(w) end)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur, min, max = scrollBar:GetValue(), scrollBar:GetMinMaxValues()
        scrollBar:SetValue(math.min(max, math.max(min, cur - (delta * 40))))
    end)
    scrollBar:SetScript("OnValueChanged", function(self, value) scrollFrame:SetVerticalScroll(value) end)
    
    return scrollFrame, scrollChild, scrollBar
end

function Config:GetDefaultSoundForSpellType(spellType)
    -- Return appropriate default sound based on spell type
    if spellType == "interrupt" then
        return "Interrupted"
    elseif spellType == "offensive" then
        return "Warning"
    elseif spellType == "defensive" then
        return "Attention"
    elseif spellType == "personal" then
        return "Chime"
    else
        return "Attention"
    end
end

function Config:CreateSpellRow(parent, index, spellId, spellName, data, rowType, onAction, spellType)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(40)
    row:SetPoint("LEFT", 0, 0)
    row:SetPoint("RIGHT", 0, 0)
    
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(index % 2 == 0 and Theme.rowEven or Theme.rowOdd))
    
    -- Action Button (Rightmost)
    local actionContainer = CreateFrame("Frame", nil, row)
    actionContainer:SetSize(70, 30)
    actionContainer:SetPoint("RIGHT", -5, 0)
    
    if rowType == "checkbox" then
        local cb = self:CreateCheckbox(actionContainer, "", 0, 0)
        cb:ClearAllPoints()
        cb:SetPoint("CENTER", 0, 0)
        cb:SetChecked(onAction(nil, "get"))
        cb:SetScript("OnClick", function(self) onAction(self:GetChecked(), "set") end)
    elseif rowType == "remove" then
        local btn = self:CreateButton(actionContainer, "Remove", 60, 20, 0, 0)
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", 0, 0)
        ApplyDarkBackdrop(btn)
        btn:SetBackdropColor(0.5, 0.1, 0.1, 0.8)
        btn:SetScript("OnClick", function() onAction() end)
    end
    
    -- Sound Dropdown (Left of Preview)
    local sounds = self:GetRegisteredSounds()
    local defaultSound = data.sound or self:GetDefaultSoundForSpellType(spellType)
    
    -- Preview Button (Left of Action) - uses same default logic as dropdown
    local previewBtn = self:CreatePreviewButton(row, function() 
        return data.sound or self:GetDefaultSoundForSpellType(spellType) 
    end, 0, 0)
    previewBtn:ClearAllPoints()
    previewBtn:SetSize(24, 24)
    previewBtn:SetText(">")
    previewBtn:SetPoint("RIGHT", actionContainer, "LEFT", -5, 0)
    local dd = self:CreateDropdown(row, nil, sounds, defaultSound, 0, 0, function(val)
        data.sound = val
        Config:PersistSpellSetting(spellId, data)
    end, 130)
    dd:ClearAllPoints()
    dd:SetPoint("RIGHT", previewBtn, "LEFT", -10, -2)
    
    -- Spell Name (Leftmost)
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("LEFT", 10, 0)
    nameText:SetWidth(170)
    nameText:SetJustifyH("LEFT")
    nameText:SetText(spellName or spellId)
    nameText:SetTextColor(unpack(Theme.accent))
    
    -- Alert Text EditBox (Fills remaining space)
    local edit = self:CreateEditBox(row, nil, data.customText, 0, 0, function(val)
        data.customText = val
        Config:PersistSpellSetting(spellId, data)
    end)
    edit:ClearAllPoints()
    edit:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
    edit:SetPoint("RIGHT", dd, "LEFT", -15, 0)
    edit:SetHeight(22)
    -- Placeholder
    if not data.customText or data.customText == "" then edit:SetText("") end
    
    return row
end

function Config:PersistSpellSetting(spellId, data)
    local context = self.currentFilterContext or "GLOBAL"
    if context == "whitelist" or context == "blacklist" then context = "GLOBAL" end
    
    if not self.db.profile.spellSettings[context] then self.db.profile.spellSettings[context] = {} end
    self.db.profile.spellSettings[context][spellId] = data
    
    if context ~= "GLOBAL" then
        Blackjack.modules.Filters:AddToWhitelist(spellId)
    end
end

-- Hook DrawFilterContent to capture context
Config.OriginalDrawFilterContent = Config.DrawFilterContent
function Config:DrawFilterContent(category)
    self.currentFilterContext = category[2]
    
    -- Clear previous
    if self.filterScroll then self.filterScroll:Hide() end
    if self.filterOptions then self.filterOptions:Hide() end
    
    local name, context = category[1], category[2]
    
    if name == "General" then
        local f = CreateFrame("Frame", nil, self.filterContent)
        f:SetAllPoints()
        self.filterOptions = f
        
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 0, -10)
        title:SetText("Global Filter Settings")
        title:SetTextColor(unpack(Theme.accent))
        
        local cb = self:CreateCheckbox(f, "Enable All Class Filters", 10, -50)
        cb:SetChecked(Blackjack.modules.Filters:IsAllFiltersEnabled())
        cb:SetScript("OnClick", function(s) Blackjack.modules.Filters:SetAllFiltersEnabled(s:GetChecked()) end)
        return
    end
    
    local scroll, scrollChild, scrollBar = self:CreateScrollList(self.filterContent)
    self.filterScroll = scroll
    
    local spells = {}
    local rowType = "checkbox"
    
    if context == "whitelist" then
        rowType = "remove"
        for id in pairs(Blackjack.modules.Filters:GetWhitelist()) do
            local info = Blackjack.modules.SpellDB:GetSpellInfo(id)
            local spellType = info and info.type or nil
            table.insert(spells, { id = id, name = info and info.name or "Unknown ("..id..")", type = spellType })
        end
        self:CreateEditBox(self.filterContent, "Add Spell ID:", "", 0, -10, function(val)
            local id = tonumber(val)
            if id and id > 0 then
                Blackjack.modules.Filters:AddToWhitelist(id)
                self:DrawFilterContent(category)
            end
        end)
    elseif context == "blacklist" then
        rowType = "remove"
        for id in pairs(Blackjack.modules.Filters:GetBlacklist()) do
            local info = Blackjack.modules.SpellDB:GetSpellInfo(id)
            local spellType = info and info.type or nil
            table.insert(spells, { id = id, name = info and info.name or "Unknown ("..id..")", type = spellType })
        end
        self:CreateEditBox(self.filterContent, "Add Spell ID:", "", 0, -10, function(val)
            local id = tonumber(val)
            if id and id > 0 then
                Blackjack.modules.Filters:AddToBlacklist(id)
                self:DrawFilterContent(category)
            end
        end)
    else
        local classSpells = Blackjack.modules.SpellDB:GetSpellsForClass(context)
        for _, s in ipairs(classSpells) do table.insert(spells, { id = s.id, name = s.name, type = s.type }) end
    end
    
    table.sort(spells, function(a,b) return a.name < b.name end)
    
    local rowHeight = 40
    for i, spell in ipairs(spells) do
        local settingsContext = (context == "whitelist" or context == "blacklist") and "GLOBAL" or context
        local settings = self.db.profile.spellSettings[settingsContext] and self.db.profile.spellSettings[settingsContext][spell.id]
        if not settings then settings = {} end
        
        local function OnAction(val, mode)
            if context == "whitelist" then
                Blackjack.modules.Filters:RemoveFromWhitelist(spell.id)
                self:DrawFilterContent(category)
            elseif context == "blacklist" then
                Blackjack.modules.Filters:RemoveFromBlacklist(spell.id)
                self:DrawFilterContent(category)
            else
                if mode == "get" then return Blackjack.modules.Filters:IsSpellEnabled(context, spell.id)
                else Blackjack.modules.Filters:SetSpellEnabled(context, spell.id, val) end
            end
        end
        
        local row = self:CreateSpellRow(scrollChild, i, spell.id, spell.name, settings, rowType, OnAction, spell.type)
        row:SetPoint("TOPLEFT", 0, -((i-1)*rowHeight))
        row:SetPoint("TOPRIGHT", 0, -((i-1)*rowHeight))
    end
    
    scrollChild:SetHeight(math.max(1, #spells * rowHeight))
    scrollBar:SetMinMaxValues(0, math.max(0, (#spells * rowHeight) - scroll:GetHeight()))
end

-------------------------------------------------------------------------------
-- TABS & HELPERS
-------------------------------------------------------------------------------

function Config:CreateGeneralTab(content)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("General Settings")
    title:SetTextColor(unpack(Theme.accent))
    
    local cb1 = self:CreateCheckbox(content, "Enable Debug Messages", 20, -50)
    cb1:SetChecked(self.db.profile.debug)
    cb1:SetScript("OnClick", function(s) self.db.profile.debug = s:GetChecked() end)
    
    local cb2 = self:CreateCheckbox(content, "Show missed, dodged & parried spells", 20, -90)
    cb2:SetChecked(self.db.profile.notifications.showMisses)
    cb2:SetScript("OnClick", function(s) self.db.profile.notifications.showMisses = s:GetChecked() end)
    
    self:CreateEditBox(content, "Miss Font Size:", self.db.profile.notifications.missFontSize or 14, 20, -140, function(v)
        self.db.profile.notifications.missFontSize = tonumber(v)
        if Blackjack.modules.VisualAlerts then Blackjack.modules.VisualAlerts:UpdateFont() end
    end)
end

function Config:CreateNotificationsTab(content)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("Notification Settings")
    title:SetTextColor(unpack(Theme.accent))
    
    local col1, col2 = 20, 300
    
    local cb1 = self:CreateCheckbox(content, "Enable Visual Alerts", col1, -50)
    cb1:SetChecked(self.db.profile.notifications.enabled)
    cb1:SetScript("OnClick", function(s) self.db.profile.notifications.enabled = s:GetChecked() end)
    
    local cb2 = self:CreateCheckbox(content, "Enable Sound Alerts", col1, -90)
    cb2:SetChecked(self.db.profile.notifications.sound)
    cb2:SetScript("OnClick", function(s) self.db.profile.notifications.sound = s:GetChecked() end)
    
    local cb3 = self:CreateCheckbox(content, "Show Spell Icons", col1, -130)
    cb3:SetChecked(self.db.profile.notifications.showIcons ~= false)
    cb3:SetScript("OnClick", function(s) 
        self.db.profile.notifications.showIcons = s:GetChecked()
        if Blackjack.modules.VisualAlerts then Blackjack.modules.VisualAlerts:UpdateFont() end
    end)
    
    self:CreateEditBox(content, "Font Size:", self.db.profile.notifications.fontSize, col1, -170, function(v)
        self.db.profile.notifications.fontSize = tonumber(v)
        if Blackjack.modules.VisualAlerts then Blackjack.modules.VisualAlerts:UpdateFont() end
    end)
    
    self:CreateDropdown(content, "Font Face", self:GetRegisteredFonts(), self.db.profile.notifications.font, col1, -210, function(v)
        self.db.profile.notifications.font = v
        if Blackjack.modules.VisualAlerts then Blackjack.modules.VisualAlerts:UpdateFont() end
    end, 200)
    
    self:CreateEditBox(content, "Position X:", self.db.profile.notifications.visualAlert_x, col2, -50, function(v)
        self.db.profile.notifications.visualAlert_x = tonumber(v)
        if Blackjack.modules.VisualAlerts then Blackjack.modules.VisualAlerts:InitializeLibWindow() end
    end)
    
    self:CreateEditBox(content, "Position Y:", self.db.profile.notifications.visualAlert_y, col2, -90, function(v)
        self.db.profile.notifications.visualAlert_y = tonumber(v)
        if Blackjack.modules.VisualAlerts then Blackjack.modules.VisualAlerts:InitializeLibWindow() end
    end)
    
    self:CreateEditBox(content, "Icon Size:", self.db.profile.notifications.iconSize, col2, -130, function(v)
        self.db.profile.notifications.iconSize = tonumber(v)
        if Blackjack.modules.VisualAlerts then Blackjack.modules.VisualAlerts:UpdateFont() end
    end)
    
    self:CreateEditBox(content, "Alert Duration:", self.db.profile.notifications.alertDuration or 1.5, col2, -170, function(v)
        local duration = tonumber(v)
        if duration and duration > 0 then
            self.db.profile.notifications.alertDuration = duration
        else
            self.db.profile.notifications.alertDuration = 1.5
        end
    end)
    
    local yStart = -250
    local h = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOPLEFT", 20, yStart)
    h:SetText("Default Sounds")
    h:SetTextColor(unpack(Theme.text))
    
    local function Row(lbl, key, y)
        local l = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        l:SetPoint("TOPLEFT", 20, y)
        l:SetText(lbl)
        local current = self.db.profile.notifications[key] or "Attention"
        self:CreateDropdown(content, nil, self:GetRegisteredSounds(), current, 120, y+5, function(v) self.db.profile.notifications[key] = v end, 150)
        self:CreatePreviewButton(content, function() return self.db.profile.notifications[key] or "Attention" end, 310, y+3)
    end
    Row("General Alert:", "alertSound", yStart - 30)
    Row("Interrupt:", "interruptSound", yStart - 70)
    Row("Dispel:", "dispelSound", yStart - 110)
    
    local btnTest = self:CreateButton(content, "Test Alert", 120, 25, 20, -400)
    btnTest:SetScript("OnClick", function() 
        if Blackjack.modules.VisualAlerts then Blackjack.modules.VisualAlerts:ShowTestNotification() end 
        if Blackjack.modules.SoundAlerts then Blackjack.modules.SoundAlerts:PlayTest() end
    end)
end

function Config:CreateFiltersTab(content)
    local sidebar = CreateFrame("Frame", nil, content)
    sidebar:SetPoint("TOPLEFT", 0, 0)
    sidebar:SetPoint("BOTTOMLEFT", 0, 0)
    sidebar:SetWidth(120)
    ApplyDarkBackdrop(sidebar)
    sidebar:SetBackdropColor(unpack(Theme.header))
    
    self.filterContent = CreateFrame("Frame", nil, content)
    self.filterContent:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0)
    self.filterContent:SetPoint("BOTTOMRIGHT", 0, 0)
    
    local cats = {
        { "General", nil }, { "Whitelist", "whitelist" }, { "Blacklist", "blacklist" },
        { "Death Knight", "DEATHKNIGHT" }, { "Druid", "DRUID" }, { "Hunter", "HUNTER" },
        { "Mage", "MAGE" }, { "Paladin", "PALADIN" }, { "Priest", "PRIEST" },
        { "Rogue", "ROGUE" }, { "Shaman", "SHAMAN" }, { "Warlock", "WARLOCK" }, { "Warrior", "WARRIOR" },
    }
    
    self.activeFilterBtn = nil
    for i, cat in ipairs(cats) do
        local btn = self:CreateButton(sidebar, cat[1], 110, 25, 5, -5 - ((i-1)*28))
        btn:SetScript("OnClick", function()
            if self.activeFilterBtn then self.activeFilterBtn:SetBackdropColor(unpack(Theme.button)) end
            self.activeFilterBtn = btn
            btn:SetBackdropColor(unpack(Theme.accent))
            self:DrawFilterContent(cat)
        end)
        if i == 1 then btn:GetScript("OnClick")(btn) end
    end
end

-- Widget Factories
function Config:CreateButton(parent, text, w, h, x, y)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w, h)
    btn:SetPoint("TOPLEFT", x, y)
    ApplyButtonStyle(btn)
    local t = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t:SetPoint("CENTER")
    t:SetText(text)
    btn:SetFontString(t)
    return btn
end

function Config:CreateCheckbox(parent, text, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    local t = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    t:SetText(text)
    cb.label = t
    return cb
end

function Config:CreateEditBox(parent, label, current, x, y, callback)
    if label then
        local l = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        l:SetPoint("TOPLEFT", x, y)
        l:SetText(label)
    end
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetPoint("TOPLEFT", x + (label and 100 or 0), y + 6)
    eb:SetSize(100, 25)
    eb:SetFontObject("GameFontHighlight")
    eb:SetTextInsets(5,5,0,0)
    eb:SetText(tostring(current or ""))
    ApplyDarkBackdrop(eb)
    eb:SetBackdropColor(unpack(Theme.editbox))
    eb:SetAutoFocus(false)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus(); if callback then callback(self:GetText()) end end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:SetText(tostring(current or "")) end)
    return eb
end

function Config:CreateDropdown(parent, label, options, current, x, y, callback, width)
    local dd = CreateFrame("Frame", "BlackjackDD"..math.random(100000), parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", x, y)
    UIDropDownMenu_SetWidth(dd, width or 120)
    UIDropDownMenu_JustifyText(dd, "LEFT")
    UIDropDownMenu_Initialize(dd, function()
        for _, v in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = v
            info.func = function() 
                UIDropDownMenu_SetSelectedValue(dd, v)
                UIDropDownMenu_SetText(dd, v)
                if callback then callback(v) end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(dd, current)
    UIDropDownMenu_SetText(dd, current)
    return dd
end

function Config:CreatePreviewButton(parent, getSound, x, y)
    local btn = self:CreateButton(parent, ">", 20, 20, x, y)
    btn:SetScript("OnClick", function()
        local s = getSound()
        if s then
            local path = LSM:Fetch("sound", s)
            if not path or path == "Interface\\Quiet.ogg" then
                 local addon = Blackjack.addonName or "Blackjack"
                 path = "Interface\\AddOns\\"..addon.."\\Media\\Sounds\\"..s..".mp3"
            end
            PlaySoundFile(path, "SFX")
        end
    end)
    return btn
end

function Config:GetRegisteredFonts()
    local list = LSM:List("font")
    table.sort(list)
    return list
end

function Config:GetRegisteredSounds()
    local list = LSM:List("sound")
    local set = {}
    for _, v in ipairs(list) do set[v] = true end
    
    for _, v in ipairs(BuiltInSounds) do
        if not set[v] then
            table.insert(list, v)
        end
    end
    table.sort(list)
    return list
end

Blackjack:RegisterModule("Config", Config)
