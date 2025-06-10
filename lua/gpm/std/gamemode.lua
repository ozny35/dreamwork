local _G = _G

---@class gpm.std
local std = _G.gpm.std

---@alias Gamemode gpm.std.Gamemode
---@class gpm.std.Gamemode : gpm.std.Object
---@field __class gpm.std.GamemodeClass
---@field name string
local Gamemode = std.class.base( "Gamemode" )

---@protected
function Gamemode:__init()

end

---@class gpm.std.GamemodeClass : gpm.std.Gamemode
---@field __base gpm.std.Gamemode
---@overload fun(): Gamemode
local GamemodeClass = std.class.create( Gamemode )
std.Gamemode = GamemodeClass

-- TODO: make gamemode class and gamemode handler
