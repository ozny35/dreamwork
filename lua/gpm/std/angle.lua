local _G = _G
local glua_Angle = _G.Angle

local gpm = _G.gpm
local std = gpm.std
local debug = std.debug
local debug_setmetatable = debug.setmetatable

local ANGLE = debug.findmetatable( "Angle" )
if ANGLE == nil then return end
---@cast ANGLE Angle

--[[

    TODO: Make angle class
    https://wiki.facepunch.com/gmod/Global.LerpAngle

]]

---@alias Angle gpm.std.Angle
---@class gpm.std.Angle: gpm.std.Object
---@field __class gpm.std.AngleClass
local Angle = std.class.base( "Angle" )

do

    local ANGLE_Unpack = ANGLE.Unpack
    local string_format = std.string.format

    ---@protected
    ---@private
    function Angle:__tostring()
        return string_format( "Angle: %p [%d, %d, %d]", self, ANGLE_Unpack( self ) )
    end

end

---@protected
function Angle.__new( pitch, yaw, roll )
    local angle = glua_Angle( pitch, yaw, roll )
    debug_setmetatable( angle, Angle )
    return angle
end

---@class gpm.std.AngleClass: gpm.std.Angle
---@field __base gpm.std.Angle
---@overload fun(): Angle
local AngleClass = std.class.create( Angle )

-- print( AngleClass( 1, 0, 0 ) )

return AngleClass
