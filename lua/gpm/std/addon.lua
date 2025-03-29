---@class gpm.std
local std = _G.gpm.std

---@alias Addon gpm.std.Addon
---@class gpm.std.Addon: gpm.std.Object
---@field __class gpm.std.AddonClass
local Addon = std.class.base( "Addon" )

---@protected
function Addon:__init()
end

---@class gpm.std.AddonClass: gpm.std.Addon
---@field __base gpm.std.Addon
---@overload fun(): Addon
local AddonClass = std.class.create(Addon)
std.Addon = AddonClass
