local std = _G.gpm.std
local math = std.math

local setmetatable = std.setmetatable
local isnumber = std.isnumber

---@alias Vector2 gpm.std.Vector2
---@class gpm.std.Vector2: gpm.std.Object
---@field __class gpm.std.Vector2Class
---@operator add: Vector2
---@operator sub: Vector2
---@operator mul: Vector2
---@operator div: Vector2
---@operator unm: Vector2
local Vector2 = std.class.base( "Vector2" )

---@protected
function Vector2:__new( x, y )
    return setmetatable( { x or 0, y or 0 }, Vector2 )
end

--- Returns the x and y coordinates of the vector.
---@return number x: The x coordinate of the vector.
---@return number y: The y coordinate of the vector.
function Vector2:unpack()
    return self[ 1 ], self[ 2 ]
end

--- Sets the x and y coordinates of the vector.
---@param x number The x coordinate of the vector.
---@param y number The y coordinate of the vector.
function Vector2:setUnpacked( x, y )
    self[ 1 ] = x
    self[ 2 ] = y
end

--- Creates a copy of the vector.
---@return Vector2: The copy of the vector.
function Vector2:copy()
    return setmetatable( { self[ 1 ], self[ 2 ] }, Vector2 )
end

do

    local math_nan, math_inf = math.nan, math.inf

    --- Scales the vector.
    ---@param scale number The scale factor.
    ---@return Vector2: The scaled vector.
    function Vector2:scale( scale )
        if scale == 0 or scale == math_nan then
            self[ 1 ] = 0
            self[ 2 ] = 0
        elseif scale == math_inf then
            self[ 1 ] = math_inf
            self[ 2 ] = math_inf
        else
            self[ 1 ] = self[ 1 ] * scale
            self[ 2 ] = self[ 2 ] * scale
        end

        return self
    end

end

--- Returns a scaled copy of the vector.
---@param scale number The scale factor.
---@return Vector2: The scaled copy of the vector.
function Vector2:getScaled( scale )
    return self:copy():scale( scale )
end

--- Adds the vector to another vector.
---@param vector Vector2 The other vector.
---@return Vector2: The sum of the two vectors.
function Vector2:add( vector )
    self[ 1 ] = self[ 1 ] + vector[ 1 ]
    self[ 2 ] = self[ 2 ] + vector[ 2 ]
    return self
end

--- Subtracts the vector from another vector.
---@param other Vector2 The other vector.
---@return Vector2: The difference of the two vectors.
function Vector2:sub( other )
    self[ 1 ] = self[ 1 ] - other[ 1 ]
    self[ 2 ] = self[ 2 ] - other[ 2 ]
    return self
end

--- Multiplies the vector by another vector or a number.
---@param other Vector2 | number: The other vector or a number.
---@return Vector2: The product of the two vectors or the vector multiplied by a number.
function Vector2:mul( other )
    if isnumber( other ) then
        ---@cast other number
        return self:scale( other )
    else
        ---@cast other Vector2
        self[ 1 ] = self[ 1 ] * other[ 1 ]
        self[ 2 ] = self[ 2 ] * other[ 2 ]
    end

    return self
end

--- Divides the vector by another vector or a number.
---@param other Vector2 | number: The other vector or a number.
---@return Vector2: The quotient of the two vectors or the vector divided by a number.
function Vector2:div( other )
    if isnumber( other ) then
        ---@cast other number
        return self:scale( 1 / other )
    else
        ---@cast other Vector2
        self[ 1 ] = self[ 1 ] / other[ 1 ]
        self[ 2 ] = self[ 2 ] / other[ 2 ]
    end

    return self
end

--- Negates the vector.
---@return Vector2
function Vector2:negate()
    self[ 1 ] = -self[ 1 ]
    self[ 2 ] = -self[ 2 ]
    return self
end

---@param other Vector2 The other vector.
---@return Vector2: The sum of the two vectors.
function Vector2:__add( other )
    return self:copy():add( other )
end

---@param other Vector2 The other vector.
---@return Vector2: The difference of the two vectors.
function Vector2:__sub( other )
    return self:copy():sub( other )
end

---@param other Vector2 | number: The other vector or a number.
---@return Vector2: The product of the two vectors or the vector multiplied by a number.
function Vector2:__mul( other )
    if isnumber( other ) then
        ---@cast other number
        return setmetatable( { self[ 1 ] * other, self[ 2 ] * other }, Vector2 )
    else
        ---@cast other Vector2
        return setmetatable( { self[ 1 ] * other[ 1 ], self[ 2 ] * other[ 2 ] }, Vector2 )
    end
end

---@param other Vector2 | number: The other vector or a number.
---@return Vector2: The quotient of the two vectors or the vector divided by a number.
function Vector2:__div( other )
    if isnumber( other ) then
        ---@cast other number
        local multiplier = 1 / other
        return setmetatable( { self[ 1 ] * multiplier, self[ 2 ] * multiplier }, Vector2 )
    else
        ---@cast other Vector2
        return setmetatable( { self[ 1 ] / other[ 1 ], self[ 2 ] / other[ 2 ] }, Vector2 )
    end
end

---@return Vector3
function Vector2:__unm()
    return setmetatable( { -self[ 1 ], -self[ 2 ] }, Vector2 )
end

---@param vector Vector2 The other vector.
---@return boolean: `true` if the two vectors are equal, `false` otherwise.
function Vector2:__eq( vector )
    return self[ 1 ] == vector[ 1 ] and self[ 2 ] == vector[ 2 ]
end

--- Calculates the squared length of the vector.
---@return number: The squared length of the vector.
function Vector2:getLengthSqr()
    return self[ 1 ] ^ 2 + self[ 2 ] ^ 2
end

do

    local math_sqrt = math.sqrt

    --- Calculates the length of the vector.
    ---@return number: The length of the vector.
    function Vector2:getLength()
        return math_sqrt( self:getLengthSqr() )
    end

    --- Calculates the distance between two vectors.
    ---@param vector Vector2 The other vector.
    ---@return number: The distance between the two vectors.
    function Vector2:getDistance( vector )
        return math_sqrt( ( vector[ 1 ] - self[ 1 ] ) ^ 2 + ( vector[ 2 ] - self[ 2 ] ) ^ 2 )
    end

end

--- Normalizes the vector.
---@return Vector2: The normalized vector.
function Vector2:normalize()
    local length = self:getLength()
    return length == 0 and self or self:scale( 1 / length )
end

--- Returns a normalized copy of the vector.
---@return Vector2: The normalized copy of the vector.
function Vector2:getNormalized()
    return self:copy():normalize()
end

--- Checks if the vector is zero.
---@return boolean: `true` if the vector is zero, `false` otherwise.
function Vector2:isZero()
    return self[ 1 ] == 0 and
           self[ 2 ] == 0
end

--- Sets the vector to zero.
---@return Vector2: The zero vector.
function Vector2:zero()
    self[ 1 ] = 0
    self[ 2 ] = 0
    return self
end

--- Calculates the dot product of two vectors.
---@param vector Vector2 The other vector.
---@return number: The dot product of two vectors.
function Vector2:dot( vector )
    return self[ 1 ] * vector[ 1 ] + self[ 2 ] * vector[ 2 ]
end

--- Calculates the cross product of two vectors.
---@param vector Vector2 The other vector.
---@return number: The cross product of two vectors.
function Vector2:cross( vector )
    return self[ 1 ] * vector[ 2 ] - self[ 2 ] * vector[ 1 ]
end

do

    local math_atan2, math_deg = math.atan2, math.deg

    --- Returns the angle of the vector.
    ---@param up? Vector2: The direction of the angle.
    ---@return number: The angle of the vector.
    function Vector2:getAngle( up )
        if up then
            return up:getAngle() + self:getAngle()
        else
            return 360 - math_deg( math_atan2( self[ 1 ], self[ 2 ] ) )
        end
    end

end

---@class gpm.std.Vector2Class: gpm.std.Vector2
---@field __base gpm.std.Vector2
---@overload fun( x: number, y: number ): Vector2
local Vector2Class = std.class.create( Vector2 )

return Vector2Class

