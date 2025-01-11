--[[

    TODO: Make vector class
    TODO: https://wiki.facepunch.com/gmod/gui.ScreenToVector ( Vector.FromScreen(X,Y) )

    https://wiki.facepunch.com/gmod/util.AimVector

    https://wiki.facepunch.com/gmod/Global.Vector
    https://wiki.facepunch.com/gmod/Global.LerpVector

    https://wiki.facepunch.com/gmod/Global.LocalToWorld
    https://wiki.facepunch.com/gmod/Global.WorldToLocal

    https://wiki.facepunch.com/gmod/Global.OrderVectors

    https://wiki.facepunch.com/gmod/util.IsInWorld

    https://wiki.facepunch.com/gmod/util.IntersectRayWithOBB

    https://wiki.facepunch.com/gmod/util.IntersectRayWithPlane

    https://wiki.facepunch.com/gmod/util.IntersectRayWithSphere

    https://wiki.facepunch.com/gmod/util.IsBoxIntersectingSphere

    https://wiki.facepunch.com/gmod/util.IsOBBIntersectingOBB

    https://wiki.facepunch.com/gmod/util.IsPointInCone

    https://wiki.facepunch.com/gmod/util.IsRayIntersectingRay

    https://wiki.facepunch.com/gmod/util.IsSkyboxVisibleFromPoint

    https://wiki.facepunch.com/gmod/util.IsSphereIntersectingCone

    https://wiki.facepunch.com/gmod/util.IsSphereIntersectingSphere


    https://wiki.facepunch.com/gmod/gui.ScreenToVector
    https://wiki.facepunch.com/gmod/Vector:ToScreen

]]

local _G = _G

---@class gpm.std
local std = _G.gpm.std

local setmetatable = std.setmetatable

local math = std.math
local math_cos, math_sin, math_rad = math.cos, math.sin, math.rad
local math_lerp = math.lerp
local math_sqrt = math.sqrt


-- ---@class gpm.std.vector
-- local vector = {
--     localToWorld = _G.LocalToWorld,
--     worldToLocal = _G.WorldToLocal
-- }

-- return vector


---@alias Vector3 gpm.std.Vector3
---@class gpm.std.Vector3: gpm.std.Object
---@field __class gpm.std.Vector3Class
local Vector3 = std.class.base( "Vector3" )

---@class gpm.std.Vector3Class: gpm.std.Vector3
---@field __base gpm.std.Vector3
---@overload fun( x: number, y: number, z: number ): Vector3
local Vector3Class = std.class.create( Vector3 )

do

    local string_format = std.string.format

    ---@protected
    ---@private
    function Vector3:__tostring()
        return string_format( "Vector3: %p [%f, %f, %f]", self, self[ 1 ], self[ 2 ], self[ 3 ] )
    end

end

---@protected
function Vector3.__new( x, y, z )
    return setmetatable( { x, y, z }, Vector3 )
end

function Vector3:__add( self, vector )
    return setmetatable( { self[ 1 ] + vector[ 1 ], self[ 2 ] + vector[ 2 ], self[ 3 ] + vector[ 3 ] }, Vector3 )
end

function Vector3:__sub( self, vector )
    return setmetatable( { self[ 1 ] - vector[ 1 ], self[ 2 ] - vector[ 2 ], self[ 3 ] - vector[ 3 ] }, Vector3 )
end

function Vector3:__eq( self, vector )
    return self[ 1 ] == vector[ 1 ] and self[ 2 ] == vector[ 2 ] and self[ 3 ] == vector[ 3 ]
end

function Vector3:normalize()
    local length = math_sqrt( self[ 1 ] ^ 2 + self[ 2 ] ^ 2 + self[ 3 ] ^ 2 )
    self[ 1 ] = self[ 1 ] / length
    self[ 2 ] = self[ 2 ] / length
    self[ 3 ] = self[ 3 ] / length
end

function Vector3:getNormalized()
    local length = math_sqrt( self[ 1 ] ^ 2 + self[ 2 ] ^ 2 + self[ 3 ] ^ 2 )
    return setmetatable( { self[ 1 ] / length, self[ 2 ] / length, self[ 3 ] / length }, Vector3 )
end

function Vector3:getLength()
    return math_sqrt( self[ 1 ] ^ 2 + self[ 2 ] ^ 2 + self[ 3 ] ^ 2 )
end

function Vector3:getLengthSqr()
    return self[ 1 ] ^ 2 + self[ 2 ] ^ 2 + self[ 3 ] ^ 2
end

function Vector3:getLength2D()
    return math_sqrt( self[ 1 ] ^ 2 + self[ 2 ] ^ 2 )
end

function Vector3:getLength2DSqr()
    return self[ 1 ] ^ 2 + self[ 2 ] ^ 2
end

function Vector3:getDistance( vector )
    return math_sqrt( ( self[ 1 ] - vector[ 1 ] ) ^ 2 + ( self[ 2 ] - vector[ 2 ] ) ^ 2 + ( self[ 3 ] - vector[ 3 ] ) ^ 2 )
end

function Vector3:copy()
    return setmetatable( { self[ 1 ], self[ 2 ], self[ 3 ] }, Vector3 )
end

function Vector3:isZero()
    return self[ 1 ] == 0 and self[ 2 ] == 0 and self[ 3 ] == 0
end

function Vector3:dot( vector )
    return self[ 1 ] * vector[ 1 ] + self[ 2 ] * vector[ 2 ] + self[ 3 ] * vector[ 3 ]
end

function Vector3:cross( vector )
    return setmetatable( { self[ 2 ] * vector[ 3 ] - self[ 3 ] * vector[ 2 ], self[ 3 ] * vector[ 1 ] - self[ 1 ] * vector[ 3 ], self[ 1 ] * vector[ 2 ] - self[ 2 ] * vector[ 1 ] }, Vector3 )
end

return Vector3Class
