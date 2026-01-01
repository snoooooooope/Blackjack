local Blackjack = _G.Blackjack

local Filters = {
    whitelist = {},
    blacklist = {}
}

function Filters:OnInitialize(db)
    self.db = db
    self:LoadFilters()
end

function Filters:LoadFilters()
    -- Load filters from DB or defaults
    self.whitelist = self.db.profile.whitelist or {}
    self.blacklist = self.db.profile.blacklist or {}
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
    if not self.db or not self.db.profile then return true end
    if not self.db.profile.filters then return true end
    if not self.db.profile.filters[class] then return true end
    -- If not explicitly set, default to enabled
    return self.db.profile.filters[class][spellId] ~= false
end

function Filters:SetSpellEnabled(class, spellId, enabled)
    if not self.db or not self.db.profile then return end
    if not self.db.profile.filters then self.db.profile.filters = {} end
    if not self.db.profile.filters[class] then self.db.profile.filters[class] = {} end
    self.db.profile.filters[class][spellId] = enabled
end

function Filters:IsAllFiltersEnabled()
    if not self.db or not self.db.profile then return true end
    return self.db.profile.filters and self.db.profile.filters.enabled ~= false
end

function Filters:SetAllFiltersEnabled(enabled)
    if not self.db or not self.db.profile then return end
    if not self.db.profile.filters then self.db.profile.filters = {} end
    self.db.profile.filters.enabled = enabled
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
    return self.db and self.db.profile and self.db.profile.whitelist or {}
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
    return self.db and self.db.profile and self.db.profile.blacklist or {}
end