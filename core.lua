-- Register Addon
TotemRecall = LibStub("AceAddon-3.0"):NewAddon("TotemRecall", "AceConsole-3.0")
local db

local anchorPoints = {
    ["TOPLEFT"] = "Top Left", ["TOP"] = "Top", ["TOPRIGHT"] = "Top Right",
    ["LEFT"] = "Left", ["CENTER"] = "Center", ["RIGHT"] = "Right",
    ["BOTTOMLEFT"] = "Bottom Left", ["BOTTOM"] = "Bottom", ["BOTTOMRIGHT"] = "Bottom Right",
}

local defaults = {
    profile = {
        ParentFrameName = "UIParent",
        ParentAnchor = "CENTER",
        TotemAnchor = "CENTER",
        UseSquareMask = true,
        XOffset = 0,
        YOffset = 0,
        IconScale = 1.0,
        IconSize = 37,      -- New default size
        IconSpacing = 2,    -- New default spacing
    }
}

-- GUI Layout
local options = {
    name = "TotemRecall",
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
                    set = function(_, val) db.profile.UseSquareMask = val; TotemRecall:UpdateLayout() end,
                    get = function() return db.profile.UseSquareMask end,
                    order = 1,
                },
                reset = {
                    name = "Reset Current Profile",
                    type = "execute",
                    confirm = true,
                    func = function() db:ResetProfile(); TotemRecall:UpdateLayout() end,
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
                            set = function(_, val) db.profile.ParentFrameName = val; TotemRecall:UpdateLayout() end,
                            get = function() return db.profile.ParentFrameName end,
                            order = 1,
                        },
                        IconScale = {
                            name = "Icon Scale",
                            type = "range", min = 0.5, max = 2.5, step = 0.05, isPercent = true,
                            set = function(_, val) db.profile.IconScale = val; TotemRecall:UpdateLayout() end,
                            get = function() return db.profile.IconScale end,
                            order = 2,
                        },
                        ParentAnchor = { name = "Parent Point", type = "select", values = anchorPoints, 
                            set = function(_, val) db.profile.ParentAnchor = val; TotemRecall:UpdateLayout() end,
                            get = function() return db.profile.ParentAnchor end, order = 3 },
                        TotemAnchor = { name = "Totem Point", type = "select", values = anchorPoints, 
                            set = function(_, val) db.profile.TotemAnchor = val; TotemRecall:UpdateLayout() end,
                            get = function() return db.profile.TotemAnchor end, order = 4 },
                        XOffset = { name = "X Offset", type = "range", min = -500, max = 500, step = 0.1,
                            set = function(_, val) db.profile.XOffset = val; TotemRecall:UpdateLayout() end,
                            get = function() return db.profile.XOffset end, order = 5 },
                        YOffset = { name = "Y Offset", type = "range", min = -500, max = 500, step = 0.1,
                            set = function(_, val) db.profile.YOffset = val; TotemRecall:UpdateLayout() end,
                            get = function() return db.profile.YOffset end, order = 6 },
                        -- IconSize = {
                        --     name = "Icon Size",
                        --     desc = "Sets the width and height of the totem icons.",
                        --     type = "range",
                        --     min = 10, max = 64, step = 1,
                        --     set = function(_, val) db.profile.IconSize = val; TotemRecall:UpdateLayout() end,
                        --     get = function(_) return db.profile.IconSize end,
                        --     order = 10,
                        -- },
                        IconSpacing = {
                            name = "Icon Spacing",
                            desc = "Sets the distance between icons (requires smaller icon size to see effect).",
                            type = "range",
                            min = -50, max = 50, step = 0.1,
                            set = function(_, val) db.profile.IconSpacing = val; TotemRecall:UpdateLayout() end,
                            get = function(_) return db.profile.IconSpacing end,
                            order = 11,
                        },    
                    }
                }
            }
        },
        -- Profiles Tab (Added this)
        profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(LibStub("AceDB-3.0"):New("MyTotemDB", defaults))
    }
}

local function ModifyTotemButton(button)
    -- Use the size from our settings
    button:SetSize(db.profile.IconSize, db.profile.IconSize)

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

function TotemRecall:UpdateLayout()
    local parent = _G[db.profile.ParentFrameName]
    if not TotemFrame or not parent then return end

    -- Position main container
    TotemFrame:SetParent(parent)
    TotemFrame:ClearAllPoints()
    TotemFrame:SetPoint(db.profile.TotemAnchor, parent, db.profile.ParentAnchor, db.profile.XOffset, db.profile.YOffset)
    TotemFrame:SetScale(db.profile.IconScale)

    -- Manually space buttons to override the default gap
    local lastButton = nil
    for button in TotemFrame.totemPool:EnumerateActive() do
        button:ClearAllPoints()
        if not lastButton then
            button:SetPoint("LEFT", TotemFrame, "LEFT", 0, 0)
        else
            -- Anchor to the right of the previous button using our spacing setting
            button:SetPoint("LEFT", lastButton, "RIGHT", db.profile.IconSpacing, 0)
        end
        
        ModifyTotemButton(button)
        lastButton = button
    end
end

function TotemRecall:OnInitialize()
    -- Initialize DB with Profiles
    self.db = LibStub("AceDB-3.0"):New("MyTotemDB", defaults, true)
    db = self.db
    
    -- Tell the DB to refresh the UI whenever the profile changes
    self.db.RegisterCallback(self, "OnProfileChanged", "UpdateLayout")
    self.db.RegisterCallback(self, "OnProfileCopied", "UpdateLayout")
    self.db.RegisterCallback(self, "OnProfileReset", "UpdateLayout")

    -- Setup Options
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("TotemRecall", options)
    
    local category, categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TotemRecall", "TotemRecall")
    
    -- Function to handle opening the menu with a combat check
    local function OpenMenu()
        if InCombatLockdown() then 
            print("|cFFFF0000TotemRecall:|r Options are disabled during combat.")
            return 
        end
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory(categoryID)
        end
    end

    -- Register both commands to use the same function
    self:RegisterChatCommand("tr", OpenMenu)
    self:RegisterChatCommand("totemrecall", OpenMenu)

    if _G["TotemButtonMixin"] then
        hooksecurefunc(TotemButtonMixin, "OnLoad", ModifyTotemButton)
    end

    -- Hook to ensure spacing is remembered when new totems are cast
    hooksecurefunc(TotemFrame, "Update", function() 
        self:UpdateLayout() 
    end)

    TotemFrame:HookScript("OnShow", function() self:UpdateLayout() end)
    C_Timer.After(1, function() self:UpdateLayout() end)
end