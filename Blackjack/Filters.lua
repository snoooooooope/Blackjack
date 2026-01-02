local Blackjack = _G.Blackjack

local Filters = {
    whitelist = {},
    blacklist = {},
    classFilters = nil
}

function Filters:OnInitialize(db)
    self.db = db
    self:LoadFilters()
    
    if self.db.profile and self.db.profile.filters then
        self.classFilters = self.db.profile.filters
    end
end

function Filters:LoadFilters()
    if self.db and self.db.profile then
        self.whitelist = self.db.profile.whitelist or {}
        self.blacklist = self.db.profile.blacklist or {}
    end
end

function Filters:IsFiltered(spellId)
    if self.blacklist[spellId] then
        return true
    end
    if not next(self.whitelist) then
        return false
    end
    return not self.whitelist[spellId]
end

function Filters:IsSpellEnabled(class, spellId)
    local filters = self.classFilters
    if not filters then 
        if not self.db or not self.db.profile or not self.db.profile.filters then return true end
        filters = self.db.profile.filters
        self.classFilters = filters
    end
    
    local classData = filters[class]
    if not classData then return true end
    
    -- If not explicitly set, default to enabled
    return classData[spellId] ~= false
end

function Filters:SetSpellEnabled(class, spellId, enabled)
    if not self.db or not self.db.profile then return end
    if not self.db.profile.filters then self.db.profile.filters = {} end
    if not self.db.profile.filters[class] then self.db.profile.filters[class] = {} end
    self.db.profile.filters[class][spellId] = enabled
    
    -- Update cache
    self.classFilters = self.db.profile.filters
end

function Filters:IsAllFiltersEnabled()
    local filters = self.classFilters or (self.db and self.db.profile and self.db.profile.filters)
    if not filters then return true end
    return filters.enabled ~= false
end

function Filters:SetAllFiltersEnabled(enabled)
    if not self.db or not self.db.profile then return end
    if not self.db.profile.filters then self.db.profile.filters = {} end
    self.db.profile.filters.enabled = enabled
    
    -- Update cache
    self.classFilters = self.db.profile.filters
end

Blackjack:RegisterModule("Filters", Filters)

-- Convenience API for whitelist/blacklist management
function Filters:AddToWhitelist(spellId)
    if not self.db or not self.db.profile then return end
    if not self.db.profile.whitelist then self.db.profile.whitelist = {} end
    self.db.profile.whitelist[spellId] = true
    self.whitelist = self.db.profile.whitelist
end

function Filters:RemoveFromWhitelist(spellId)
    if not self.db or not self.db.profile or not self.db.profile.whitelist then return end
    self.db.profile.whitelist[spellId] = nil
    self.whitelist = self.db.profile.whitelist
end

function Filters:GetWhitelist()
    return self.whitelist or {}
end

function Filters:AddToBlacklist(spellId)
    if not self.db or not self.db.profile then return end
    if not self.db.profile.blacklist then self.db.profile.blacklist = {} end
    self.db.profile.blacklist[spellId] = true
    self.blacklist = self.db.profile.blacklist
end

function Filters:RemoveFromBlacklist(spellId)
    if not self.db or not self.db.profile or not self.db.profile.blacklist then return end
    self.db.profile.blacklist[spellId] = nil
    self.blacklist = self.db.profile.blacklist
end

function Filters:GetBlacklist()
    return self.blacklist or {}
end
