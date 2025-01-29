local std = _G.gpm.std

---@alias Vector2 gpm.std.Vector2
---@class gpm.std.Vector2: gpm.std.Object
---@field __class gpm.std.Vector2Class
---@operator add: Vector2
---@operator sub: Vector2
---@operator mul: Vector2
---@operator div: Vector2
---@operator unm: Vector2
local Vector2 = std.class.base( "Vector2" )

---@class gpm.std.Vector2Class: gpm.std.Vector2
---@field __base gpm.std.Vector2
---@overload fun( x: number, y: number ): Vector2
local Vector2Class = std.class.create( Vector2 )
std.Vector2 = Vector2Class

---@alias Angle2 gpm.std.Angle2
---@class gpm.std.Angle2: gpm.std.Object
---@field __class gpm.std.Angle2Class
---@operator add: Angle2
---@operator sub: Angle2
---@operator mul: Angle2
---@operator div: Angle2
---@operator unm: Angle2
local Angle2 = std.class.base( "Angle2" )

---@class gpm.std.Angle2Class: gpm.std.Angle2
---@field __base gpm.std.Angle2
---@overload fun( pitch: number?, yaw: number?, roll: number? ): Angle2
local Angle2Class = std.class.create( Angle2 )
Vector2Class.Angle = Angle2Class



-- TODO: lol, write the class methods



return Vector2Class

