-- Register Addon
BlizzTotemRelocator = LibStub("AceAddon-3.0"):NewAddon("BlizzTotemRelocator", "AceConsole-3.0")
local db

local anchorPoints = {
    ["TOPLEFT"] = "Top Left", ["TOP"] = "Top", ["TOPRIGHT"] = "Top Right",
    ["LEFT"] = "Left", ["CENTER"] = "Center", ["RIGHT"] = "Right",
    ["BOTTOMLEFT"] = "Bottom Left", ["BOTTOM"] = "Bottom", ["BOTTOMRIGHT"] = "Bottom Right",
}

local defaults = {
    profile = {
        ParentFrameName = "UUF_Player",
        ParentAnchor = "BOTTOMLEFT",
        TotemAnchor = "TOPLEFT",
        UseSquareMask = true,
        XOffset = -22,
        YOffset = 3,
        IconScale = 1.0,
    }
}

-- GUI Layout
local options = {
    name = "BlizzTotemRelocator",
    type = "group",
    args = {
        -- Main Settings Tab
        settings = {
            name = "General Settings",
            type = "group",
            order = 1,
            args = {
                UseSquareMask = {
                    name = "Use Square Mask",
                    desc = "Requires UI Reload to fully revert if disabled.",
                    type = "toggle",
                    set = function(_, val) db.profile.UseSquareMask = val; BlizzTotemRelocator:UpdateLayout() end,
                    get = function() return db.profile.UseSquareMask end,
                    order = 1,
                },
                reset = {
                    name = "Reset Current Profile",
                    type = "execute",
                    confirm = true,
                    func = function() db:ResetProfile(); BlizzTotemRelocator:UpdateLayout() end,
                    order = 2,
                },
                positioning = {
                    name = "Positioning & Scale",
                    type = "group",
                    inline = true,
                    order = 3,
                    args = {
                        ParentFrameName = {
                            name = "Parent Frame",
                            type = "input",
                            set = function(_, val) db.profile.ParentFrameName = val; BlizzTotemRelocator:UpdateLayout() end,
                            get = function() return db.profile.ParentFrameName end,
                            order = 1,
                        },
                        IconScale = {
                            name = "Icon Scale",
                            type = "range", min = 0.5, max = 2.5, step = 0.05, isPercent = true,
                            set = function(_, val) db.profile.IconScale = val; BlizzTotemRelocator:UpdateLayout() end,
                            get = function() return db.profile.IconScale end,
                            order = 2,
                        },
                        ParentAnchor = { name = "Parent Point", type = "select", values = anchorPoints, 
                            set = function(_, val) db.profile.ParentAnchor = val; BlizzTotemRelocator:UpdateLayout() end,
                            get = function() return db.profile.ParentAnchor end, order = 3 },
                        TotemAnchor = { name = "Totem Point", type = "select", values = anchorPoints, 
                            set = function(_, val) db.profile.TotemAnchor = val; BlizzTotemRelocator:UpdateLayout() end,
                            get = function() return db.profile.TotemAnchor end, order = 4 },
                        XOffset = { name = "X Offset", type = "range", min = -500, max = 500, step = 1,
                            set = function(_, val) db.profile.XOffset = val; BlizzTotemRelocator:UpdateLayout() end,
                            get = function() return db.profile.XOffset end, order = 5 },
                        YOffset = { name = "Y Offset", type = "range", min = -500, max = 500, step = 1,
                            set = function(_, val) db.profile.YOffset = val; BlizzTotemRelocator:UpdateLayout() end,
                            get = function() return db.profile.YOffset end, order = 6 },
                    }
                }
            }
        },
        -- Profiles Tab (Added this)
        profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(LibStub("AceDB-3.0"):New("MyTotemDB", defaults))
    }
}

local function ModifyTotemButton(button)
    if not db.profile.UseSquareMask then return end
    
    button.Border:Hide()
    local atlas = C_Texture.GetAtlasInfo("SquareMask")
    if atlas then
        button.Icon.TextureMask:SetTexture(atlas.file or atlas.filename)
        button.Icon.TextureMask:SetTexCoord(atlas.leftTexCoord, atlas.rightTexCoord, atlas.topTexCoord, atlas.bottomTexCoord)
        
        button.Icon.Cooldown:SetSwipeTexture(atlas.file or atlas.filename)
        button.Icon.Cooldown:SetTexCoordRange({x=atlas.leftTexCoord, y=atlas.topTexCoord}, {x=atlas.rightTexCoord, y=atlas.bottomTexCoord})
    end
end

function BlizzTotemRelocator:UpdateLayout()
    local parent = _G[db.profile.ParentFrameName]
    if TotemFrame and parent then
        TotemFrame:SetParent(parent)
        TotemFrame:ClearAllPoints()
        TotemFrame:SetPoint(db.profile.TotemAnchor, parent, db.profile.ParentAnchor, db.profile.XOffset, db.profile.YOffset)
        TotemFrame:SetScale(db.profile.IconScale)
    end
    for button in TotemFrame.totemPool:EnumerateActive() do
        ModifyTotemButton(button)
    end
end

function BlizzTotemRelocator:OnInitialize()
    -- Initialize DB with Profiles
    self.db = LibStub("AceDB-3.0"):New("MyTotemDB", defaults, true)
    db = self.db
    
    -- Tell the DB to refresh the UI whenever the profile changes
    self.db.RegisterCallback(self, "OnProfileChanged", "UpdateLayout")
    self.db.RegisterCallback(self, "OnProfileCopied", "UpdateLayout")
    self.db.RegisterCallback(self, "OnProfileReset", "UpdateLayout")

    -- Setup Options
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BlizzTotemRelocator", options)
    
    local category, categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BlizzTotemRelocator", "BlizzTotemRelocator")
    
    self:RegisterChatCommand("btr", function() 
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory(categoryID)
        end
    end)

    hooksecurefunc(TotemButtonMixin, "OnLoad", ModifyTotemButton)
    TotemFrame:HookScript("OnShow", function() self:UpdateLayout() end)
    C_Timer.After(1, function() self:UpdateLayout() end)
end