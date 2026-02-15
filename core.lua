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
        IconScale = 1.0, -- Default scale
    }
}

-- GUI Layout
local options = {
    name = "BlizzTotemRelocator",
    type = "group",
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
            name = "Reset to Defaults",
            type = "execute",
            confirm = true,
            desc = "Reset all settings to their original values.",
            func = function() 
                db:ResetProfile() 
                BlizzTotemRelocator:UpdateLayout()
            end,
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
                    desc = "Adjust the size of the Totem icons.",
                    type = "range",
                    min = 0.5, max = 2.5, step = 0.05,
                    isPercent = true,
                    set = function(_, val) db.profile.IconScale = val; BlizzTotemRelocator:UpdateLayout() end,
                    get = function() return db.profile.IconScale end,
                    order = 2,
                },
                ParentAnchor = {
                    name = "Parent Point",
                    type = "select",
                    values = anchorPoints,
                    set = function(_, val) db.profile.ParentAnchor = val; BlizzTotemRelocator:UpdateLayout() end,
                    get = function() return db.profile.ParentAnchor end,
                    order = 3,
                },
                TotemAnchor = {
                    name = "Totem Point",
                    type = "select",
                    values = anchorPoints,
                    set = function(_, val) db.profile.TotemAnchor = val; BlizzTotemRelocator:UpdateLayout() end,
                    get = function() return db.profile.TotemAnchor end,
                    order = 4,
                },
                XOffset = {
                    name = "X Offset",
                    type = "range", min = -500, max = 500, step = 1,
                    set = function(_, val) db.profile.XOffset = val; BlizzTotemRelocator:UpdateLayout() end,
                    get = function() return db.profile.XOffset end,
                    order = 5,
                },
                YOffset = {
                    name = "Y Offset",
                    type = "range", min = -500, max = 500, step = 1,
                    set = function(_, val) db.profile.YOffset = val; BlizzTotemRelocator:UpdateLayout() end,
                    get = function() return db.profile.YOffset end,
                    order = 6,
                },
            }
        }
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
        
        -- Apply Scale
        TotemFrame:SetScale(db.profile.IconScale)
    end
    
    for button in TotemFrame.totemPool:EnumerateActive() do
        ModifyTotemButton(button)
    end
end

function BlizzTotemRelocator:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("MyTotemDB", defaults, true)
    db = self.db
    
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BlizzTotemRelocator", options)
    
    -- Fix: Capture the category object and the ID
    local category, categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BlizzTotemRelocator", "BlizzTotemRelocator")
    
    self:RegisterChatCommand("btr", function() 
        -- Corrected for 11.x and 12.x interface
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory(categoryID)
        end
    end)

    hooksecurefunc(TotemButtonMixin, "OnLoad", ModifyTotemButton)
    TotemFrame:HookScript("OnShow", function() self:UpdateLayout() end)
    
    -- Initial delay call
    C_Timer.After(1, function() self:UpdateLayout() end)
end