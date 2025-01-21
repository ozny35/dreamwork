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
local is_number = std.is.number

local math = std.math
local math_abs, math_asin, math_atan2 = math.abs, math.asin, math.atan2
local math_cos, math_sin, math_rad = math.cos, math.sin, math.rad
local math_lerp, math_sqrt = math.lerp, math.sqrt
local math_min, math_max = math.min, math.max

-- ---@class gpm.std.vector
-- local vector = {
--     localToWorld = _G.LocalToWorld,
--     worldToLocal = _G.WorldToLocal
-- }

-- return vector


---@alias Vector3 gpm.std.Vector3
---@class gpm.std.Vector3: gpm.std.Object
---@field __class gpm.std.Vector3Class
---@operator add: Vector3
---@operator sub: Vector3
---@operator mul: Vector3 | number
---@operator div: Vector3 | number
local Vector3 = std.class.base( "Vector3" )

---@class gpm.std.Vector3Class: gpm.std.Vector3
---@field __base gpm.std.Vector3
---@overload fun( x: number, y: number, z: number ): Vector3
local Vector3Class = std.class.create( Vector3 )
std.Vector3 = Vector3Class

---@alias Angle3 gpm.std.Angle3
---@class gpm.std.Angle3: gpm.std.Object
---@field __class gpm.std.Angle3Class
---@operator add: Angle3
---@operator sub: Angle3
---@operator mul: Angle3 | number
---@operator div: Angle3 | number
local Angle3 = std.class.base( "Angle3" )

---@class gpm.std.Angle3Class: gpm.std.Angle3
---@field __base gpm.std.Angle3
---@overload fun( pitch: number, yaw: number, roll: number ): Angle3
local Angle3Class = std.class.create( Angle3 )
Vector3Class.Angle = Angle3Class

do

    local string_format = std.string.format

    ---@private
    ---@protected
    ---@return string
    function Vector3:__tostring()
        return string_format( "Vector3: %p [%f, %f, %f]", self, self[ 1 ], self[ 2 ], self[ 3 ] )
    end

end

---@protected
---@param x number?
---@param y number?
---@param z number?
---@return Vector3
function Vector3.__new( x, y, z )
    return setmetatable( { x, y, z }, Vector3 )
end

---@param key string | number
---@return number | function | nil
function Angle3:__index( key )
    if is_number( key ) then
        return rawget( self, key ) or 0
    else
        return rawget( Angle3, key )
    end
end

---@param key string | number
---@return number | function | nil
function Vector3:__index( key )
    if is_number( key ) then
        return rawget( self, key ) or 0
    else
        return rawget( Vector3, key )
    end
end

-- TODO: https://github.com/thegrb93/StarfallEx/blob/master/lua/starfall/libs_sh/vectors.lua#L391

---
---@param vector Vector3
---@return Vector3
function Vector3:__add( vector )
    return setmetatable( { self[ 1 ] + vector[ 1 ], self[ 2 ] + vector[ 2 ], self[ 3 ] + vector[ 3 ] }, Vector3 )
end

---
---@param value Vector3
---@return Vector3
function Vector3:add( value )
    self[ 1 ] = self[ 1 ] + value[ 1 ]
    self[ 2 ] = self[ 2 ] + value[ 2 ]
    self[ 3 ] = self[ 3 ] + value[ 3 ]
    return self
end

---
---@param vector Vector3
---@return Vector3
function Vector3:__sub( vector )
    return setmetatable( {
        self[ 1 ] - vector[ 1 ],
        self[ 2 ] - vector[ 2 ],
        self[ 3 ] - vector[ 3 ]
    }, Vector3 )
end

---
---@param value Vector3 | number
---@return Vector3
function Vector3:sub( value )
    self[ 1 ] = self[ 1 ] - value[ 1 ]
    self[ 2 ] = self[ 2 ] - value[ 2 ]
    self[ 3 ] = self[ 3 ] - value[ 3 ]
    return self
end

---
---@param value Vector3 | number
---@return Vector3
function Vector3:__mul( value )
    if is_number( value ) then
        ---@cast value number
        return setmetatable( { self[ 1 ] * value, self[ 2 ] * value, self[ 3 ] * value }, Vector3 )
    else
        ---@cast value Vector3
        return setmetatable( { self[ 1 ] * value[ 1 ], self[ 2 ] * value[ 2 ], self[ 3 ] * value[ 3 ] }, Vector3 )
    end
end

---
---@param value Vector3 | number
---@return Vector3
function Vector3:mul( value )
    if is_number( value ) then
        ---@cast value number
        self[ 1 ] = self[ 1 ] * value
        self[ 2 ] = self[ 2 ] * value
        self[ 3 ] = self[ 3 ] * value
    else
        ---@cast value Vector3
        self[ 1 ] = self[ 1 ] * value[ 1 ]
        self[ 2 ] = self[ 2 ] * value[ 2 ]
        self[ 3 ] = self[ 3 ] * value[ 3 ]
    end

    return self
end

---
---@param value Vector3 | number
---@return Vector3
function Vector3:__div( value )
    if is_number( value ) then
        ---@cast value number
        return setmetatable( { self[ 1 ] / value, self[ 2 ] / value, self[ 3 ] / value }, Vector3 )
    else
        ---@cast value Vector3
        return setmetatable( { self[ 1 ] / value[ 1 ], self[ 2 ] / value[ 2 ], self[ 3 ] / value[ 3 ] }, Vector3 )
    end
end

---
---@param value Vector3 | number
---@return Vector3
function Vector3:div( value )
    if is_number( value ) then
        ---@cast value number
        self[ 1 ] = self[ 1 ] / value
        self[ 2 ] = self[ 2 ] / value
        self[ 3 ] = self[ 3 ] / value
    else
        ---@cast value Vector3
        self[ 1 ] = self[ 1 ] / value[ 1 ]
        self[ 2 ] = self[ 2 ] / value[ 2 ]
        self[ 3 ] = self[ 3 ] / value[ 3 ]
    end

    return self
end

---
---@param vector Vector3
---@return boolean
function Vector3:__eq( vector )
    return self[ 1 ] == vector[ 1 ] and self[ 2 ] == vector[ 2 ] and self[ 3 ] == vector[ 3 ]
end

---
---@return Vector3
function Vector3:normalize()
    local length = math_sqrt( self[ 1 ] ^ 2 + self[ 2 ] ^ 2 + self[ 3 ] ^ 2 )
    self[ 1 ] = self[ 1 ] / length
    self[ 2 ] = self[ 2 ] / length
    self[ 3 ] = self[ 3 ] / length
    return self
end

---
---@return Vector3
function Vector3:getNormalized()
    local length = math_sqrt( self[ 1 ] ^ 2 + self[ 2 ] ^ 2 + self[ 3 ] ^ 2 )
    return setmetatable( { self[ 1 ] / length, self[ 2 ] / length, self[ 3 ] / length }, Vector3 )
end

---
---@return number
function Vector3:getLength()
    return math_sqrt( self[ 1 ] ^ 2 + self[ 2 ] ^ 2 + self[ 3 ] ^ 2 )
end

---
---@return number
function Vector3:getLengthSqr()
    return self[ 1 ] ^ 2 + self[ 2 ] ^ 2 + self[ 3 ] ^ 2
end

---
---@return number
function Vector3:getLength2D()
    return math_sqrt( self[ 1 ] ^ 2 + self[ 2 ] ^ 2 )
end

---
---@return number
function Vector3:getLength2DSqr()
    return self[ 1 ] ^ 2 + self[ 2 ] ^ 2
end

---
---@param vector Vector3
---@return number
function Vector3:getDistance( vector )
    return math_sqrt( ( self[ 1 ] - vector[ 1 ] ) ^ 2 + ( self[ 2 ] - vector[ 2 ] ) ^ 2 + ( self[ 3 ] - vector[ 3 ] ) ^ 2 )
end

---
---@return Vector3
function Vector3:copy()
    return setmetatable( { self[ 1 ], self[ 2 ], self[ 3 ] }, Vector3 )
end

---
---@return boolean
function Vector3:isZero()
    return self[ 1 ] == 0 and self[ 2 ] == 0 and self[ 3 ] == 0
end

---
---@return Vector3
function Vector3:zero()
    self[ 1 ], self[ 2 ], self[ 3 ] = 0, 0, 0
    return self
end

---
---@return Vector3
function Vector3:negate()
    self[ 1 ], self[ 2 ], self[ 3 ] = -self[ 1 ], -self[ 2 ], -self[ 3 ]
    return self
end

---
---@return Vector3
function Vector3:__unm()
    return setmetatable( { -self[ 1 ], -self[ 2 ], -self[ 3 ] }, Vector3 )
end

---
---@param vector Vector3
---@return number
function Vector3:dot( vector )
    return self[ 1 ] * vector[ 1 ] + self[ 2 ] * vector[ 2 ] + self[ 3 ] * vector[ 3 ]
end

---
---@param vector Vector3
---@return Vector3
function Vector3:cross( vector )
    return setmetatable( { self[ 2 ] * vector[ 3 ] - self[ 3 ] * vector[ 2 ], self[ 3 ] * vector[ 1 ] - self[ 1 ] * vector[ 3 ], self[ 1 ] * vector[ 2 ] - self[ 2 ] * vector[ 1 ] }, Vector3 )
end

---
---@param vector Vector3
---@return boolean
function Vector3:withinAABox( vector )
    if self[ 1 ] < math_min( self[ 1 ], vector[ 1 ] ) or self[ 1 ] > math_max( self[ 1 ], vector[ 1 ] ) then return false end
    if self[ 2 ] < math_min( self[ 2 ], vector[ 2 ] ) or self[ 2 ] > math_max( self[ 2 ], vector[ 2 ] ) then return false end
    if self[ 3 ] < math_min( self[ 3 ], vector[ 3 ] ) or self[ 3 ] > math_max( self[ 3 ], vector[ 3 ] ) then return false end
    return true
end

do

    local math_deg = math.deg

    ---
    ---@return Angle3
    function Vector3:getAngle()
        local length = math_sqrt( self[ 1 ] ^ 2 + self[ 2 ] ^ 2 + self[ 3 ] ^ 2 )
        if length == 0 then
            return setmetatable( { 0, 0, 0 }, Angle3 )
        end

        return setmetatable( {
            math_deg( math_asin( -self[ 3 ] / length ) % 360 ),
            math_deg( math_atan2( self[ 2 ], self[ 1 ] ) % 360 ),
            0
        }, Angle3 )
    end

end

---
---@param vector Vector3
---@param tolerance number
---@return boolean
function Vector3:isEqualTol( vector, tolerance )
    return math_abs( self[ 1 ] - vector[ 1 ] ) < tolerance and math_abs( self[ 2 ] - vector[ 2 ] ) < tolerance and math_abs( self[ 3 ] - vector[ 3 ] ) < tolerance
end

---
---@param angle Angle3
---@return Vector3
function Vector3:rotate( angle )
    local pitch, yaw, roll = math_rad( angle[ 1 ] ), math_rad( angle[ 2 ] ), math_rad( angle[ 3 ] )
    local ysin, ycos, psin, pcos, rsin, rcos = math_sin( yaw ), math_cos( yaw ), math_sin( pitch ), math_cos( pitch ), math_sin( roll ), math_cos( roll )
    local psin_rsin, psin_rcos = psin * rsin, psin * rcos
    local x, y, z = self[ 1 ], self[ 2 ], self[ 3 ]

    self[ 1 ] = x * ( ycos * pcos ) + y * ( ycos * psin_rsin - ysin * rcos ) + z * ( ycos * psin_rcos + ysin * rsin )
    self[ 2 ] = x * ( ysin * pcos ) + y * ( ysin * psin_rsin + ycos * rcos ) + z * ( ysin * psin_rcos - ycos * rsin )
    self[ 3 ] = x * ( -psin ) + y * ( pcos * rsin ) + z * ( pcos * rcos )

    return self
end

---
---@param angle Angle3
---@return Vector3
function Vector3:getRotated( angle )
    local pitch, yaw, roll = math_rad( angle[ 1 ] ), math_rad( angle[ 2 ] ), math_rad( angle[ 3 ] )
    local ysin, ycos, psin, pcos, rsin, rcos = math_sin( yaw ), math_cos( yaw ), math_sin( pitch ), math_cos( pitch ), math_sin( roll ), math_cos( roll )
    local psin_rsin, psin_rcos = psin * rsin, psin * rcos
    local x, y, z = self[ 1 ], self[ 2 ], self[ 3 ]

    return setmetatable( {
        x * ( ycos * pcos ) + y * ( ycos * psin_rsin - ysin * rcos ) + z * ( ycos * psin_rcos + ysin * rsin ),
        x * ( ysin * pcos ) + y * ( ysin * psin_rsin + ycos * rcos ) + z * ( ysin * psin_rcos - ycos * rsin ),
        x * ( -psin ) + y * ( pcos * rsin ) + z * ( pcos * rcos )
    }, Vector3 )
end

-- Color class extension
do

    ---@class gpm.std.ColorClass
    local ColorClass = std.Color

    ---@class gpm.std.Color
    local Color = ColorClass.__base

    --- Creates a color object from vector.
    ---@param vector Vector3: The vector.
    ---@return Color: The color object.
    function ColorClass.fromVector3( vector )
        return setmetatable(
            {
                r = vector[ 1 ] * 255,
                g = vector[ 2 ] * 255,
                b = vector[ 3 ] * 255,
                a = 255
            },
            Color
        )
    end

    --- Returns the color as vector.
    ---@return Vector
    function Color:toVector()
        return Vector( self.r / 255, self.g / 255, self.b / 255 )
    end

end

do

    local string_format = std.string.format

    ---@protected
    ---@private
    function Angle3:__tostring()
        return string_format( "Angle3: %p [%f, %f, %f]", self, self[ 1 ], self[ 2 ], self[ 3 ] )
    end

end

---@protected
function Angle3.__new( pitch, yaw, roll )
    return setmetatable( { pitch, yaw, roll }, Angle3 )
end


-- TODO: https://github.com/thegrb93/StarfallEx/blob/master/lua/starfall/libs_sh/angles.lua

---
---@param angle Angle3
---@return Angle3
function Angle3:__add( angle )
    return setmetatable( {
        self[ 1 ] + angle[ 1 ],
        self[ 2 ] + angle[ 2 ],
        self[ 3 ] + angle[ 3 ]
    }, Angle3 )
end

---
---@param angle Angle3
---@return Angle3
function Angle3:add( angle )
    self[ 1 ] = self[ 1 ] + angle[ 1 ]
    self[ 2 ] = self[ 2 ] + angle[ 2 ]
    self[ 3 ] = self[ 3 ] + angle[ 3 ]
    return self
end

---
---@param angle Angle3
---@return Angle3
function Angle3:__sub( angle )
    return setmetatable( {
        self[ 1 ] - angle[ 1 ],
        self[ 2 ] - angle[ 2 ],
        self[ 3 ] - angle[ 3 ]
    }, Angle3 )
end

---
---@param angle Angle3
---@return Angle3
function Angle3:sub( angle )
    self[ 1 ] = self[ 1 ] - angle[ 1 ]
    self[ 2 ] = self[ 2 ] - angle[ 2 ]
    self[ 3 ] = self[ 3 ] - angle[ 3 ]
    return self
end

---@param angle Angle3 | number
---@return Angle3
function Angle3:__mul( angle )
    if is_number( angle ) then
        ---@cast angle number
        return setmetatable( {
            self[ 1 ] * angle,
            self[ 2 ] * angle,
            self[ 3 ] * angle
        }, Angle3 )
    else
        ---@cast angle Angle3
        return setmetatable( {
            self[ 1 ] * angle[ 1 ],
            self[ 2 ] * angle[ 2 ],
            self[ 3 ] * angle[ 3 ]
        }, Angle3 )
    end
end

---
---@param angle Angle3 | number
---@return Angle3
function Angle3:mul( angle )
    if is_number( angle ) then
        ---@cast angle number
        self[ 1 ] = self[ 1 ] * angle
        self[ 2 ] = self[ 2 ] * angle
        self[ 3 ] = self[ 3 ] * angle
    else
        ---@cast angle Angle3
        self[ 1 ] = self[ 1 ] * angle[ 1 ]
        self[ 2 ] = self[ 2 ] * angle[ 2 ]
        self[ 3 ] = self[ 3 ] * angle[ 3 ]
    end

    return self
end

-- Division

---
---@param angle Angle3 | number
---@return Angle3
function Angle3:div( angle )
    if is_number( angle ) then
        self[ 1 ] = self[ 1 ] / angle
        self[ 2 ] = self[ 2 ] / angle
        self[ 3 ] = self[ 3 ] / angle
    else
        self[ 1 ] = self[ 1 ] / angle[ 1 ]
        self[ 2 ] = self[ 2 ] / angle[ 2 ]
        self[ 3 ] = self[ 3 ] / angle[ 3 ]
    end

    return self
end

---
---@param angle Angle3 | number
---@return Angle3
function Angle3:__div( angle )
    if is_number( angle ) then
        ---@cast angle number
        return setmetatable( {
            self[ 1 ] / angle,
            self[ 2 ] / angle,
            self[ 3 ] / angle
        }, Angle3 )
    else
        ---@cast angle Angle3
        return setmetatable( {
            self[ 1 ] / angle[ 1 ],
            self[ 2 ] / angle[ 2 ],
            self[ 3 ] / angle[ 3 ]
        }, Angle3 )
    end
end

function Angle3:__unm()
    return setmetatable( {
        -self[ 1 ],
        -self[ 2 ],
        -self[ 3 ]
    }, Angle3 )
end

function Angle3:__eq( angle )
    return self[ 1 ] == angle[ 1 ] and self[ 2 ] == angle[ 2 ] and self[ 3 ] == angle[ 3 ]
end

---
---@param angle Angle3 | number
---@param frac number
---@return Angle3
function Angle3:lerp( angle, frac )
    if is_number( angle ) then
        ---@cast angle number
        self[ 1 ] = math_lerp( frac, self[ 1 ], angle )
        self[ 2 ] = math_lerp( frac, self[ 2 ], angle )
        self[ 3 ] = math_lerp( frac, self[ 3 ], angle )
    else
        ---@cast angle Angle3
        self[ 1 ] = math_lerp( frac, self[ 1 ], angle[ 1 ] )
        self[ 2 ] = math_lerp( frac, self[ 2 ], angle[ 2 ] )
        self[ 3 ] = math_lerp( frac, self[ 3 ], angle[ 3 ] )
    end

    return self
end

---
---@param angle1 Angle3
---@param angle2 Angle3 | number
---@param frac number
---@return Angle3
function Angle3Class.lerp( angle1, angle2, frac )
    if is_number( angle2 ) then
        ---@cast angle2 number
        return setmetatable( {
            math_lerp( frac, angle1[ 1 ], angle2 ),
            math_lerp( frac, angle1[ 2 ], angle2 ),
            math_lerp( frac, angle1[ 3 ], angle2 )
        }, Angle3 )
    else
        ---@cast angle2 Angle3
        return setmetatable( {
            math_lerp( frac, angle1[ 1 ], angle2[ 1 ] ),
            math_lerp( frac, angle1[ 2 ], angle2[ 2 ] ),
            math_lerp( frac, angle1[ 3 ], angle2[ 3 ] )
        }, Angle3 )
    end
end

function Angle3:copy()
    return setmetatable( { self[ 1 ], self[ 2 ], self[ 3 ] }, Angle3 )
end

function Angle3:getForward()


end

-- local ang1 = _G.Angle3( 0, 0, 0 ):Forward()
-- local ang2 = Angle3Class( 0, 0, 90 ):getForward()

-- print(
--     ang1[ 1 ], ang2[ 1 ], "\n",
--     ang1[ 2 ], ang2[ 2 ], "\n",
--     ang1[ 3 ], ang2[ 3 ]

-- )


return Vector3Class
