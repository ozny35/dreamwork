--[[

    TODO:

    https://wiki.facepunch.com/gmod/gui.ScreenToVector ( Vector.FromScreen(X,Y) )

    https://wiki.facepunch.com/gmod/util.AimVector

    https://wiki.facepunch.com/gmod/Global.LocalToWorld
    https://wiki.facepunch.com/gmod/Global.WorldToLocal

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
local gpm = _G.gpm

---@class gpm.std
local std = gpm.std

local class = std.class

local isnumber = std.isnumber
local setmetatable = std.setmetatable

local math = std.math

local math_huge = math.huge
local math_abs = math.abs
local math_atan2, math_deg = math.atan2, math.deg
local math_sqrt = math.sqrt
local math_cos, math_sin, math_rad = math.cos, math.sin, math.rad
local math_lerp = math.lerp
local math_min, math_max = math.min, math.max


---@alias Vector2 gpm.std.Vector2
---@class gpm.std.Vector2: gpm.std.Object
---@field __class gpm.std.Vector2Class
---@operator add: Vector2
---@operator sub: Vector2
---@operator mul: Vector2
---@operator div: Vector2
---@operator unm: Vector2
local Vector2 = class.base( "Vector2" )

---@class gpm.std.Vector2Class: gpm.std.Vector2
---@field __base gpm.std.Vector2
---@overload fun( x: number, y: number ): Vector2
local Vector2Class = class.create( Vector2 )
std.Vector2 = Vector2Class

---@alias Vector3 gpm.std.Vector3
---@class gpm.std.Vector3: gpm.std.Object
---@field __class gpm.std.Vector3Class
---@operator add: Vector3
---@operator sub: Vector3
---@operator mul: Vector3
---@operator div: Vector3
---@operator unm: Vector3
---@field x number
---@field y number
---@field z number
local Vector3 = class.base( "Vector3" )

---@class gpm.std.Vector3Class: gpm.std.Vector3
---@field __base gpm.std.Vector3
---@overload fun( x: number, y: number, z: number ): Vector3
local Vector3Class = class.create( Vector3 )
Vector3Class.origin = setmetatable( { 0, 0, 0 }, Vector3 )
std.Vector3 = Vector3Class

---@alias Angle3 gpm.std.Angle3
---@class gpm.std.Angle3: gpm.std.Object
---@field __class gpm.std.Angle3Class
---@operator add: Angle3
---@operator sub: Angle3
---@operator mul: Angle3
---@operator div: Angle3
---@operator unm: Angle3
local Angle3 = class.base( "Angle3" )

---@class gpm.std.Angle3Class: gpm.std.Angle3
---@field __base gpm.std.Angle3
---@overload fun( pitch: number?, yaw: number?, roll: number? ): Angle3
local Angle3Class = class.create( Angle3 )
Angle3Class.zero = setmetatable( { 0, 0, 0 }, Angle3 )
std.Angle = Angle3Class

---@alias VMatrix gpm.std.VMatrix
---@class gpm.std.VMatrix: gpm.std.Object
---@field __class gpm.std.VMatrixClass
local VMatrix = class.base( "VMatrix" )

---@class gpm.std.VMatrixClass: gpm.std.VMatrix
---@field __base gpm.std.VMatrix
---@overload fun( ...: number? ): VMatrix
local VMatrixClass = class.create( VMatrix )
std.VMatrix = VMatrixClass

do

    local debug = std.debug

    debug.registermetatable( "Vector3", Vector3 )

    do

        local Vector = _G.Vector
        if Vector == nil then
            gpm.Logger:error( "Vector3: Vector function is missing!" )
        else
            gpm.transducers[ Vector3 ] = function( vec3 )
                return Vector( vec3[ 1 ], vec3[ 2 ], vec3[ 3 ] )
            end
        end

    end

    do

        local VECTOR = debug.findmetatable( "Vector" )
        if VECTOR == nil then
            gpm.Logger:error( "Vector3: Vector metatable is missing!" )
        else
            ---@cast VECTOR Vector
            local Unpack = VECTOR.Unpack

            gpm.transducers[ VECTOR ] = function( vector )
                return setmetatable( { Unpack( vector ) }, Vector3 )
            end
        end

    end

    debug.registermetatable( "Angle3", Angle3 )

    do

        local Angle = _G.Angle
        if Angle == nil then
            gpm.Logger:error( "Angle3: Angle function is missing!" )
        else
            gpm.transducers[ Angle3 ] = function( angle3 )
                return Angle( angle3[ 1 ], angle3[ 2 ], angle3[ 3 ] )
            end
        end

    end

    do

        local ANGLE = debug.findmetatable( "Angle" )
        if ANGLE == nil then
            gpm.Logger:error( "Angle3: Angle metatable is missing!" )
        else
            ---@cast ANGLE Angle
            local Unpack = ANGLE.Unpack

            gpm.transducers[ ANGLE ] = function( angle )
                return setmetatable( { Unpack( angle ) }, Angle3 )
            end
        end

    end

    debug.registermetatable( "VMatrix", VMatrix )

    do

        local Matrix = _G.Matrix
        if Matrix == nil then
            gpm.Logger:error( "VMatrix: Matrix function is missing!" )
        else
            gpm.transducers[ VMatrix ] = function( matrix )
                return Matrix( {
                    { matrix[ 1 ], matrix[ 2 ], matrix[ 3 ], matrix[ 4 ] },
                    { matrix[ 5 ], matrix[ 6 ], matrix[ 7 ], matrix[ 8 ] },
                    { matrix[ 9 ], matrix[ 10 ], matrix[ 11 ], matrix[ 12 ] },
                    { matrix[ 13 ], matrix[ 14 ], matrix[ 15 ], matrix[ 16 ] }
                } )
            end
        end

    end

    do

        local VMATRIX = debug.findmetatable( "VMatrix" )
        if VMATRIX == nil then
            gpm.Logger:error( "VMatrix: Matrix metatable is missing!" )
        else

            ---@cast VMATRIX VMatrix
            local Unpack = VMATRIX.Unpack

            gpm.transducers[ VMATRIX ] = function( matrix )
                return VMatrixClass( Unpack( matrix ) )
            end

        end

    end

    do

        local debug_getmetatable = debug.getmetatable

        --- [SHARED AND MENU]
        ---
        --- Returns `true` if the value is a `Vector3`.
        ---@param value any The value.
        ---@return boolean: `true` if the value is a `Vector3`, `false` otherwise.
        function std.isvector3( value )
            return debug_getmetatable( value ) == Vector3
        end

        --- [SHARED AND MENU]
        ---
        --- Returns `true` if the value is an `Angle3`.
        ---@param value any The value.
        ---@return boolean: `true` if the value is an `Angle3`, `false` otherwise.
        function std.isangle3( value )
            return debug_getmetatable( value ) == Angle3
        end

    end

end

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

--- Scales the vector.
---@param scale number The scale factor.
---@return Vector2: The scaled vector.
function Vector2:scale( scale )
    if scale == 0 or scale ~= scale then
        self[ 1 ] = 0
        self[ 2 ] = 0
    elseif scale == math_huge then
        self[ 1 ] = math_huge
        self[ 2 ] = math_huge
    else
        self[ 1 ] = self[ 1 ] * scale
        self[ 2 ] = self[ 2 ] * scale
    end

    return self
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

---@protected
---@param x number?
---@param y number?
---@param z number?
---@return Vector3
function Vector3:__new( x, y, z )
    return setmetatable( { x or 0, y or 0, z or 0 }, Vector3 )
end

do

    local key2index = {
        pitch = 1,
        p = 1,
        yaw = 2,
        y = 2,
        roll = 3,
        r = 3
    }

    ---@param key string | number
    ---@return number | function | nil
    function Angle3:__index( key )
        if isnumber( key ) then
            return rawget( self, key ) or 0
        else
            return rawget( self, key2index[ key ] or key ) or Angle3[ key ]
        end
    end

    function Angle3:__newindex( key, value )
        if isnumber( key ) then
            rawset( self, key, value )
        else
            rawset( self, key2index[ key ] or key, value )
        end
    end

end

do

    local key2index = {
        x = 1,
        y = 2,
        z = 3
    }

    ---@param key string | number
    ---@return number | function | nil
    function Vector3:__index( key )
        if isnumber( key ) then
            return rawget( self, key ) or 0
        end

        return rawget( self, key2index[ key ] or key ) or Vector3[ key ]
    end

    function Vector3:__newindex( key, value )
        if isnumber( key ) then
            rawset( self, key, value )
        else
            rawset( self, key2index[ key ] or key, value )
        end
    end

end

--- Returns the x, y, and z coordinates of the vector.
---@return number x: The x coordinate of the vector.
---@return number y: The y coordinate of the vector.
---@return number z: The z coordinate of the vector.
function Vector3:unpack()
    return self[ 1 ], self[ 2 ], self[ 3 ]
end

--- Sets the x, y, and z coordinates of the vector.
---@param x number The x coordinate of the vector.
---@param y number The y coordinate of the vector.
---@param z number The z coordinate of the vector.
function Vector3:setUnpacked( x, y, z )
    self[ 1 ] = x
    self[ 2 ] = y
    self[ 3 ] = z
end

--- Creates a copy of the vector.
---@return Vector3: The copy of the vector.
function Vector3:copy()
    return setmetatable( { self[ 1 ], self[ 2 ], self[ 3 ] }, Vector3 )
end

do

    local math_huge = math.huge

    --- Scales the vector.
    ---@param scale number The scale factor.
    ---@return Vector3: The scaled vector.
    function Vector3:scale( scale )
        if scale == 0 or scale ~= scale then
            self[ 1 ] = 0
            self[ 2 ] = 0
            self[ 3 ] = 0
        elseif scale == math_huge then
            self[ 1 ] = math_huge
            self[ 2 ] = math_huge
            self[ 3 ] = math_huge
        else
            self[ 1 ] = self[ 1 ] * scale
            self[ 2 ] = self[ 2 ] * scale
            self[ 3 ] = self[ 3 ] * scale
        end

        return self
    end

end

--- Returns a scaled copy of the vector.
---@param scale number The scale factor.
---@return Vector3: The scaled copy of the vector.
function Vector3:getScaled( scale )
    return self:copy():scale( scale )
end

--- Adds the vector to another vector.
---@param vector Vector3 The other vector.
---@return Vector3: The sum of the two vectors.
function Vector3:add( vector )
    self[ 1 ] = self[ 1 ] + vector[ 1 ]
    self[ 2 ] = self[ 2 ] + vector[ 2 ]
    self[ 3 ] = self[ 3 ] + vector[ 3 ]
    return self
end

--- Subtracts the vector from another vector.
---@param vector Vector3 The other vector.
---@return Vector3: The difference of the two vectors.
function Vector3:sub( vector )
    self[ 1 ] = self[ 1 ] - vector[ 1 ]
    self[ 2 ] = self[ 2 ] - vector[ 2 ]
    self[ 3 ] = self[ 3 ] - vector[ 3 ]
    return self
end

--- Multiplies the vector by another vector or a number.
---@param value Vector3 | number: The other vector or a number.
---@return Vector3: The product of the two vectors or the vector multiplied by a number.
function Vector3:mul( value )
    if isnumber( value ) then
        ---@cast value number
        return self:scale( value )
    end

    ---@cast value Vector3
    self[ 1 ] = self[ 1 ] * value[ 1 ]
    self[ 2 ] = self[ 2 ] * value[ 2 ]
    self[ 3 ] = self[ 3 ] * value[ 3 ]
    return self
end

--- Divides the vector by another vector or a number.
---@param value Vector3 | number: The other vector or a number.
---@return Vector3: The quotient of the two vectors or the vector divided by a number.
function Vector3:div( value )
    if isnumber( value ) then
        ---@cast value number
        return self:scale( 1 / value )
    end

    ---@cast value Vector3
    self[ 1 ] = self[ 1 ] / value[ 1 ]
    self[ 2 ] = self[ 2 ] / value[ 2 ]
    self[ 3 ] = self[ 3 ] / value[ 3 ]
    return self
end

--- Negates the vector.
---@return Vector3
function Vector3:negate()
    self[ 1 ] = -self[ 1 ]
    self[ 2 ] = -self[ 2 ]
    self[ 3 ] = -self[ 3 ]
    return self
end

---@param vector Vector3 The other vector.
---@return Vector3: The sum of the two vectors.
function Vector3:__add( vector )
    return self:copy():add( vector )
end

---@param vector Vector3 The other vector.
---@return Vector3: The difference of the two vectors.
function Vector3:__sub( vector )
    return self:copy():sub( vector )
end

---@param value Vector3 | number: The other vector or a number.
---@return Vector3: The product of the two vectors or the vector multiplied by a number.
function Vector3:__mul( value )
    return self:copy():mul( value )
end

---@param value Vector3 | number: The other vector or a number.
---@return Vector3: The quotient of the two vectors or the vector divided by a number.
function Vector3:__div( value )
    return self:copy():div( value )
end

---@return Vector3
function Vector3:__unm()
    return setmetatable( { -self[ 1 ], -self[ 2 ], -self[ 3 ] }, Vector3 )
end

---@param vector Vector3 The other vector.
---@return boolean: `true` if the two vectors are equal, `false` otherwise.
function Vector3:__eq( vector )
    return self[ 1 ] == vector[ 1 ] and self[ 2 ] == vector[ 2 ] and self[ 3 ] == vector[ 3 ]
end

--- Calculates the squared length of the vector.
---@param ignoreZ? boolean: `true` to ignore the z component of the vector, `false` otherwise.
---@return number: The squared length of the vector.
function Vector3:getLengthSqr( ignoreZ )
    return self[ 1 ] ^ 2 + self[ 2 ] ^ 2 + ( ignoreZ and 0 or ( self[ 3 ] ^ 2 ) )
end

do

    local math_sqrt = math.sqrt

    --- Calculates the length of the vector.
    ---@param ignoreZ? boolean: `true` to ignore the z component of the vector, `false` otherwise.
    ---@return number: The length of the vector.
    function Vector3:getLength( ignoreZ )
        return math_sqrt( self:getLengthSqr( ignoreZ ) )
    end

    --- Calculates the distance between two vectors.
    ---@param vector Vector3 The other vector.
    ---@return number: The distance between the two vectors.
    function Vector3:getDistance( vector )
        return math_sqrt( ( vector[ 1 ] - self[ 1 ] ) ^ 2 + ( vector[ 2 ] - self[ 2 ] ) ^ 2 + ( vector[ 3 ] - self[ 3 ] ) ^ 2 )
    end

end

--- Normalizes the vector.
---@return Vector3: The normalized vector.
function Vector3:normalize()
    local length = self:getLength()
    return length == 0 and self or self:scale( 1 / length )
end

--- Returns a normalized copy of the vector.
---@return Vector3: The normalized copy of the vector.
function Vector3:getNormalized()
    return self:copy():normalize()
end

--- Checks if the vector is zero.
---@return boolean: `true` if the vector is zero, `false` otherwise.
function Vector3:isZero()
    return self[ 1 ] == 0 and
           self[ 2 ] == 0 and
           self[ 3 ] == 0
end

--- Sets the vector to zero.
---@return Vector3: The zero vector.
function Vector3:zero()
    self[ 1 ] = 0
    self[ 2 ] = 0
    self[ 3 ] = 0
    return self
end

--- Calculates the dot product of two vectors.
---@param vector Vector3 The other vector.
---@return number: The dot product of two vectors.
function Vector3:dot( vector )
    return self[ 1 ] * vector[ 1 ] + self[ 2 ] * vector[ 2 ] + self[ 3 ] * vector[ 3 ]
end

--- Calculates the cross product of two vectors.
---@param vector Vector3 The other vector.
---@return Vector3: The cross product of two vectors.
function Vector3:cross( vector )
    local x1, y1, z1 = self:unpack()
    local x2, y2, z2 = vector:unpack()
    return setmetatable( {
        y1 * z2 - z1 * y2,
        z1 * x2 - x1 * z2,
        x1 * y2 - y1 * x2
    }, Vector3 )
end

--- Checks if the vector is within an axis-aligned box.
---@param vector Vector3 The other vector.
---@return boolean: `true` if the vector is within the box, `false` otherwise.
function Vector3:withinAABox( vector )
    if self[ 1 ] < math_min( self[ 1 ], vector[ 1 ] ) or self[ 1 ] > math_max( self[ 1 ], vector[ 1 ] ) then return false end
    if self[ 2 ] < math_min( self[ 2 ], vector[ 2 ] ) or self[ 2 ] > math_max( self[ 2 ], vector[ 2 ] ) then return false end
    if self[ 3 ] < math_min( self[ 3 ], vector[ 3 ] ) or self[ 3 ] > math_max( self[ 3 ], vector[ 3 ] ) then return false end
    return true
end

do

    local math_deg, math_asin, math_atan2 = math.deg, math.asin, math.atan2

    --- Returns the angle of the vector.
    ---@param up Vector3?: The direction of the angle.
    ---@return Angle3: The angle of the vector.
    function Vector3:toAngle( up )
        if self:isZero() then
            return setmetatable( { 0, 0, 0 }, Angle3 )
        end

        local forward = self:getNormalized()

        if up then
            local right = up:cross( forward ):normalize()

            return setmetatable( {
                math_deg( math_asin( -forward[ 3 ] ) ),
                math_deg( math_atan2( forward[ 2 ], forward[ 1 ] ) ),
                math_deg( math_atan2( right[ 3 ], forward:cross( right )[ 3 ] ) )
            }, Angle3 )
        end

        return setmetatable( {
            math_deg( math_asin( -forward[ 3 ] ) ),
            math_deg( math_atan2( forward[ 2 ], forward[ 1 ] ) ),
            0
        }, Angle3 )
    end

    local math_acos = math.acos

    --- Calculates the angle between two vectors.
    ---@param vector Vector3 The other vector.
    ---@return number degrees The angle between two vectors.
    function Vector3:getAngle( vector )
        return math_deg( math_acos( self:dot( vector ) / ( self:getLength() * vector:getLength() ) ) )
    end

end

--- Checks if the vector is equal to the given vector with the given tolerance.
---@param vector Vector3 The vector to check.
---@param tolerance number The tolerance to use.
---@return boolean: `true` if the vectors are equal, otherwise `false`.
function Vector3:isNear( vector, tolerance )
    return math_abs( self[ 1 ] - vector[ 1 ] ) <= tolerance and
           math_abs( self[ 2 ] - vector[ 2 ] ) <= tolerance and
           math_abs( self[ 3 ] - vector[ 3 ] ) <= tolerance
end

--- Rotates the vector by the given angle.
---@param angle Angle3 The angle to rotate by.
---@return Vector3: The rotated vector.
function Vector3:rotate( angle )
    local pitch, yaw, roll = math_rad( angle[ 1 ] ), math_rad( angle[ 2 ] ), math_rad( angle[ 3 ] )
    local ysin, ycos, psin, pcos, rsin, rcos = math_sin( yaw ), math_cos( yaw ), math_sin( pitch ), math_cos( pitch ), math_sin( roll ), math_cos( roll )
    local psin_rsin, psin_rcos = psin * rsin, psin * rcos
    local x, y, z = self:unpack()

    self[ 1 ] = x * ( ycos * pcos ) + y * ( ycos * psin_rsin - ysin * rcos ) + z * ( ycos * psin_rcos + ysin * rsin )
    self[ 2 ] = x * ( ysin * pcos ) + y * ( ysin * psin_rsin + ycos * rcos ) + z * ( ysin * psin_rcos - ycos * rsin )
    self[ 3 ] = x * ( -psin ) + y * ( pcos * rsin ) + z * ( pcos * rcos )

    return self
end

--- Returns a copy of the vector rotated by the given angle.
---@param angle Angle3 The angle to rotate by.
---@return Vector3: The rotated vector.
function Vector3:getRotated( angle )
    return self:copy():rotate( angle )
end

--- Linear interpolation between two vectors.
---@param vector Vector3 | number: The other vector or a number.
---@param frac number The interpolation factor.
---@return Vector3: The interpolated vector.
function Vector3:lerp( vector, frac )
    if isnumber( vector ) then
        ---@cast vector number
        self[ 1 ] = math_lerp( frac, self[ 1 ], vector )
        self[ 2 ] = math_lerp( frac, self[ 2 ], vector )
        self[ 3 ] = math_lerp( frac, self[ 3 ], vector )
    else
        ---@cast vector Vector3
        self[ 1 ] = math_lerp( frac, self[ 1 ], vector[ 1 ] )
        self[ 2 ] = math_lerp( frac, self[ 2 ], vector[ 2 ] )
        self[ 3 ] = math_lerp( frac, self[ 3 ], vector[ 3 ] )
    end

    return self
end

--- Returns a copy of the vector linearly interpolated between two vectors.
---@param vector Vector3 | number: The other vector or a number.
---@param frac number The interpolation factor.
---@return Vector3: The interpolated vector.
function Vector3:getLerped( vector, frac )
    return self:copy():lerp( vector, frac )
end

--- Projects the vector onto another vector.
---@param vector Vector3 The other vector.
---@return Vector3: The projected vector.
function Vector3:project( vector )
    local normalized = vector:getNormalized()
    local dot = self:dot( normalized )
    self[ 1 ] = normalized[ 1 ] * dot
    self[ 2 ] = normalized[ 2 ] * dot
    self[ 3 ] = normalized[ 3 ] * dot
    return self
end

--- Returns a copy of the vector projected onto another vector.
---@param vector Vector3 The other vector.
---@return Vector3: The projected vector.
function Vector3:getProjected( vector )
    return self:copy():project( vector )
end

--- Modifies the given vectors so that all of vector2's axis are larger than vector1's by switching them around.
---
--- Also known as ordering vectors.
---@param mins Vector3 The first vector to modify.
---@param maxs Vector3 The second vector to modify.
function Vector3Class.order( mins, maxs )
    local x1, y1, z1 = mins:unpack()
    local x2, y2, z2 = maxs:unpack()
    mins:setUnpacked( math_min( x1, x2 ), math_min( y1, y2 ), math_min( z1, z2 ) )
    maxs:setUnpacked( math_max( x1, x2 ), math_max( y1, y2 ), math_max( z1, z2 ) )
    return mins, maxs
end

-- Color class extension
do

    ---@class gpm.std.ColorClass
    local ColorClass = std.Color

    ---@class gpm.std.Color
    local Color = ColorClass.__base

    --- Creates a color object from vector.
    ---@param vector Vector3 The vector.
    ---@return Color: The color object.
    function ColorClass.fromVector3( vector )
        return setmetatable( {
            vector[ 1 ] * 255,
            vector[ 2 ] * 255,
            vector[ 3 ] * 255,
            255
        }, Color )
    end

    --- Returns the color as vector.
    ---@return Vector: The vector.
    function Color:toVector3()
        return setmetatable( {
            self[ 1 ] / 255,
            self[ 2 ] / 255,
            self[ 3 ] / 255
        }, Vector3 )
    end

end

--- Unpacks the angle.
---@return number pitch: The pitch angle.
---@return number yaw: The yaw angle.
---@return number roll: The roll angle.
function Angle3:unpack()
    return self[ 1 ], self[ 2 ], self[ 3 ]
end

--- Sets the angle from unpacked angles.
---@param pitch number?: The pitch angle.
---@param yaw number?: The yaw angle.
---@param roll number?: The roll angle.
---@return Angle3: The angle.
function Angle3:setUnpacked( pitch, yaw, roll )
    self[ 1 ] = pitch
    self[ 2 ] = yaw
    self[ 3 ] = roll
    return self
end

--- Returns a copy of the angle.
---@return Angle3: A copy of the angle.
function Angle3:copy()
    return setmetatable( { self:unpack() }, Angle3 )
end

---@protected
function Angle3:__new( pitch, yaw, roll )
    return setmetatable( { pitch, yaw, roll }, Angle3 )
end

--- Adds the angle.
---@param angle Angle3 The angle to add.
---@return Angle3: The sum of the angles.
function Angle3:add( angle )
    self[ 1 ] = self[ 1 ] + angle[ 1 ]
    self[ 2 ] = self[ 2 ] + angle[ 2 ]
    self[ 3 ] = self[ 3 ] + angle[ 3 ]
    return self
end

--- Subtracts the angle.
---@param angle Angle3 The angle to subtract.
---@return Angle3: The subtracted angle.
function Angle3:sub( angle )
    self[ 1 ] = self[ 1 ] - angle[ 1 ]
    self[ 2 ] = self[ 2 ] - angle[ 2 ]
    self[ 3 ] = self[ 3 ] - angle[ 3 ]
    return self
end

--- Multiplies the angle with a number or angle.
---@param angle number | Angle3: The angle to multiply with.
---@return Angle3: The multiplied angle.
function Angle3:mul( angle )
    if isnumber( angle ) then
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

--- Divides the angle with a number or angle.
---@param angle number | Angle3: The angle to divide with.
---@return Angle3: The divided angle.
function Angle3:div( angle )
    if isnumber( angle ) then
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

--- Negates the angle.
---@return Angle3: The negated angle.
function Angle3:negate()
    self[ 1 ] = -self[ 1 ]
    self[ 2 ] = -self[ 2 ]
    self[ 3 ] = -self[ 3 ]
    return self
end

---@param angle Angle3 The other angle.
---@return Angle3: The sum of the angles.
function Angle3:__add( angle )
    return self:copy():add( angle )
end

---@param angle Angle3 The angle to subtract.
---@return Angle3: The subtracted angle.
function Angle3:__sub( angle )
    return self:copy():sub( angle )
end

---@param angle number | Angle3: The angle to multiply with.
---@return Angle3: The multiplied angle.
function Angle3:__mul( angle )
    return self:copy():mul( angle )
end

---@param angle number | Angle3: The angle to divide with.
---@return Angle3: The divided angle.
function Angle3:__div( angle )
    return self:copy():div( angle )
end

---@return Angle3: The negated angle
function Angle3:__unm()
    return setmetatable( { -self[ 1 ], -self[ 2 ], -self[ 3 ] }, Angle3 )
end

---@param angle Angle3 The other angle.
---@return boolean: `true` if the angles are equal, `false` otherwise.
function Angle3:__eq( angle )
    return self[ 1 ] == angle[ 1 ] and self[ 2 ] == angle[ 2 ] and self[ 3 ] == angle[ 3 ]
end

--- Linearly interpolates the angle.
---@param angle Angle3 | number: The other angle.
---@param frac number The interpolation factor.
---@return Angle3: The interpolated angle.
function Angle3:lerp( angle, frac )
    if isnumber( angle ) then
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

--- Returns a copy of the angle linearly interpolated between two angles.
---@param angle Angle3 | number: The other angle.
---@param frac number The interpolation factor.
---@return Angle3: The interpolated angle.
function Angle3:getLerped( angle, frac )
    return self:copy():lerp( angle, frac )
end

--- Returns the forward direction of the angle.
---@return Vector3: The forward direction of the angle.
function Angle3:getForward()
    return setmetatable( { 1, 0, 0 }, Vector3 ):rotate( self )
end

--- Returns the backward direction of the angle.
---@return Vector3: The backward direction of the angle.
function Angle3:getBackward()
    return setmetatable( { -1, 0, 0 }, Vector3 ):rotate( self )
end

--- Returns the left direction of the angle.
---@return Vector3: The left direction of the angle.
function Angle3:getLeft()
    return setmetatable( { 0, 1, 0 }, Vector3 ):rotate( self )
end

--- Returns the right direction of the angle.
---@return Vector3: The right direction of the angle.
function Angle3:getRight()
    return setmetatable( { 0, -1, 0 }, Vector3 ):rotate( self )
end

--- Returns the up direction of the angle.
---@return Vector3: The up direction of the angle.
function Angle3:getUp()
    return setmetatable( { 0, 0, 1 }, Vector3 ):rotate( self )
end

--- Returns the down direction of the angle.
---@return Vector3: The down direction of the angle.
function Angle3:getDown()
    return setmetatable( { 0, 0, -1 }, Vector3 ):rotate( self )
end

do

    local math_angleNormalize = math.angleNormalize

    --- Normalizes the angle.
    ---@return Angle3: The normalized angle.
    function Angle3:normalize()
        self[ 1 ] = math_angleNormalize( self[ 1 ] )
        self[ 2 ] = math_angleNormalize( self[ 2 ] )
        self[ 3 ] = math_angleNormalize( self[ 3 ] )
        return self
    end

    --- Returns a normalized copy of the angle.
    ---@return Angle3: A normalized copy of the angle.
    function Angle3:getNormalized()
        return self:copy():normalize()
    end

end

--- Checks if the angle is within the given tolerance of the given angle.
---@param angle Angle3 The angle to check against.
---@param tolerance number The tolerance.
---@return boolean: `true` if the angle is within the given tolerance of the given angle.
function Angle3:isNear( angle, tolerance )
    return math_abs( self[ 1 ] - angle[ 1 ] ) <= tolerance and
           math_abs( self[ 2 ] - angle[ 2 ] ) <= tolerance and
           math_abs( self[ 3 ] - angle[ 3 ] ) <= tolerance
end

--- Checks if the angle is zero.
---@return boolean: `true` if the angle is zero, `false` otherwise.
function Angle3:isZero()
    return self[ 1 ] == 0 and self[ 2 ] == 0 and self[ 3 ] == 0
end

--- Sets the angle to zero.
---@return Angle3: The angle.
function Angle3:zero()
    self[ 1 ] = 0
    self[ 2 ] = 0
    self[ 3 ] = 0
    return self
end

--- Rotates the angle around the specified axis by the specified degrees.
---@param axis Vector3 The axis to rotate around as a normalized unit vector. When argument is not a unit vector, you will experience numerical offset errors in the rotated angle.
---@param rotation number The degrees to rotate around the specified axis.
function Angle3:rotate( axis, rotation )



    return self
end

--- Returns a new vector from world position and world angle.
---@param position Vector3 The local position.
---@param angle Angle3 The local angle.
---@param world_position Vector3 The world position.
---@param world_angle Angle3 The world angle.
---@return Vector3: The new vector.
---@return Angle3: The new angle.
function Vector3Class.translateToLocal( position, angle, world_position, world_angle )
    -- TODO: implement this function


end

--- Returns a new vector from local position and local angle.
---@param local_position Vector3 The local position.
---@param local_angle Angle3 The local angle.
---@param world_position Vector3 The world position.
---@param world_angle Angle3 The world angle.
---@return Vector3: The new vector.
---@return Angle3: The new angle.
function Vector3Class.translateToWorld( local_position, local_angle, world_position, world_angle )
    -- TODO: implement this function

end

--- Returns a new vector from screen position.
---@param view_angle Angle3 The view angle.
---@param view_fov number The view fov.
---@param x number The x position.
---@param y number The y position.
---@param screen_width number The screen width.
---@param screen_height number The screen height.
---@return Vector3: The view direction.
function Vector3Class.fromScreen( view_angle, view_fov, x, y, screen_width, screen_height )
    -- TODO: implement this function
end

do

    local string_format = std.string.format

    ---@protected
    ---@return string
    function Vector3:__tostring()
        return string_format( "Vector3: %p [%f, %f, %f]", self, self:unpack() )
    end

    ---@protected
    ---@return string
    function Angle3:__tostring()
        return string_format( "Angle3: %p [%f, %f, %f]", self, self:unpack() )
    end

end

-- for i = 0, 100, 25 do
--     local vx = i / 100
--     for j = 0, 100, 25 do
--         local vy = j / 100
--         for k = 0, 100, 25 do
--             local vz = k / 100
--             for rotation = 0, 360, 45 do
--                 local ap, ay, ar = 0, 0, 0

--                 print( Angle3Class( ap, ay, ar ):rotate( Vector3Class( vx, vy, vz ), rotation ) ) -- 0 -0 -90

--                 local a = _G.Angle( ap, ay, ar )
--                 a:RotateAroundAxis( _G.Vector( vx, vy, vz ), rotation )
--                 print( a )
--             end
--         end
--     end
-- end

-- do

--     local m = Matrix(
--         {
--             {1, 1, 1, 1},
--             {1, 1, 1, 1},
--             {1, 1, 1, 1},
--             {1, 1, 1, 1}
--         }
--     )

--     m:Identity()

--     m:Mul( Matrix(
--         {
--             {2, 0, 0, 0},
--             {0, 0, 0, 0},
--             {0, 0, 0, 0},
--             {0, 0, 0, 0}
--         }
--     ) )

--     m:Translate( Vector( 1, 2, 1 ) )

--     print( m )


-- end

--[[

    VMatrix structrue:

    {

        [  1 ] [  2 ] [  3 ] [  4 ] : number[] - row1
        [  5 ] [  6 ] [  7 ] [  8 ] : number[] - row2
        [  9 ] [ 10 ] [ 11 ] [ 12 ] : number[] - row3
        [ 13 ] [ 14 ] [ 15 ] [ 16 ] : number[] - row4

    }

--]]

---@protected
function VMatrix:__new( r1c1, r1c2, r1c3, r1c4, r2c1, r2c2, r2c3, r2c4, r3c1, r3c2, r3c3, r3c4, r4c1, r4c2, r4c3, r4c4 )
    return setmetatable( {
        r1c1 or 0, r1c2 or 0, r1c3 or 0, r1c4 or 0,
        r2c1 or 0, r2c2 or 0, r2c3 or 0, r2c4 or 0,
        r3c1 or 0, r3c2 or 0, r3c3 or 0, r3c4 or 0,
        r4c1 or 0, r4c2 or 0, r4c3 or 0, r4c4 or 0
    }, VMatrix )
end

---@protected
function VMatrix:__tostring()
    return string.format( "VMatrix: %p\n[\n%.2f %.2f %.2f %.2f,\n%.2f %.2f %.2f %.2f,\n%.2f %.2f %.2f %.2f,\n%.2f %.2f %.2f %.2f\n]", self, self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ], self[ 5 ], self[ 6 ], self[ 7 ], self[ 8 ], self[ 9 ], self[ 10 ], self[ 11 ], self[ 12 ], self[ 13 ], self[ 14 ], self[ 15 ], self[ 16 ] )
end

---@return VMatrix
function VMatrix:identity()
    self[  1 ], self[  2 ], self[  3 ], self[  4 ] = 1, 0, 0, 0
    self[  5 ], self[  6 ], self[  7 ], self[  8 ] = 0, 1, 0, 0
    self[  9 ], self[ 10 ], self[ 11 ], self[ 12 ] = 0, 0, 1, 0
    self[ 13 ], self[ 14 ], self[ 15 ], self[ 16 ] = 0, 0, 0, 1
    return self
end

function VMatrix:isIdentity()
    return
        self[  1 ] == 1 and self[  2 ] == 0 and self[  3 ] == 0 and self[  4 ] == 0 and
        self[  5 ] == 0 and self[  6 ] == 1 and self[  7 ] == 0 and self[  8 ] == 0 and
        self[  9 ] == 0 and self[ 10 ] == 0 and self[ 11 ] == 1 and self[ 12 ] == 0 and
        self[ 13 ] == 0 and self[ 14 ] == 0 and self[ 15 ] == 0 and self[ 16 ] == 1
end

---@return VMatrix
function VMatrix:copy()
    return VMatrixClass( self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ], self[ 5 ], self[ 6 ], self[ 7 ], self[ 8 ], self[ 9 ], self[ 10 ], self[ 11 ], self[ 12 ], self[ 13 ], self[ 14 ], self[ 15 ], self[ 16 ] )
end

---@param matrix VMatrix
---@return VMatrix
function VMatrix:multiply( matrix )
    self[ 1 ] = self[ 1 ] * matrix[ 1 ] + self[ 2 ] * matrix[ 5 ] + self[ 3 ] * matrix[ 9 ] + self[ 4 ] * matrix[ 13 ]
	self[ 2 ] = self[ 1 ] * matrix[ 2 ] + self[ 2 ] * matrix[ 6 ] + self[ 3 ] * matrix[ 10 ] + self[ 4 ] * matrix[ 14 ]
	self[ 3 ] = self[ 1 ] * matrix[ 3 ] + self[ 2 ] * matrix[ 7 ] + self[ 3 ] * matrix[ 11 ] + self[ 4 ] * matrix[ 15 ]
	self[ 4 ] = self[ 1 ] * matrix[ 4 ] + self[ 2 ] * matrix[ 8 ] + self[ 3 ] * matrix[ 12 ] + self[ 4 ] * matrix[ 16 ]

	self[ 5 ] = self[ 5 ] * matrix[ 1 ] + self[ 6 ] * matrix[ 5 ] + self[ 7 ] * matrix[ 9 ] + self[ 8 ] * matrix[ 13 ]
	self[ 6 ] = self[ 5 ] * matrix[ 2 ] + self[ 6 ] * matrix[ 6 ] + self[ 7 ] * matrix[ 10 ] + self[ 8 ] * matrix[ 14 ]
	self[ 7 ] = self[ 5 ] * matrix[ 3 ] + self[ 6 ] * matrix[ 7 ] + self[ 7 ] * matrix[ 11 ] + self[ 8 ] * matrix[ 15 ]
	self[ 8 ] = self[ 5 ] * matrix[ 4 ] + self[ 6 ] * matrix[ 8 ] + self[ 7 ] * matrix[ 12 ] + self[ 8 ] * matrix[ 16 ]

	self[ 9 ] = self[ 9 ] * matrix[ 1 ] + self[ 10 ] * matrix[ 5 ] + self[ 11 ] * matrix[ 9 ] + self[ 12 ] * matrix[ 13 ]
	self[ 10 ] = self[ 9 ] * matrix[ 2 ] + self[ 10 ] * matrix[ 6 ] + self[ 11 ] * matrix[ 10 ] + self[ 12 ] * matrix[ 14 ]
	self[ 11 ] = self[ 9 ] * matrix[ 3 ] + self[ 10 ] * matrix[ 7 ] + self[ 11 ] * matrix[ 11 ] + self[ 12 ] * matrix[ 15 ]
	self[ 12 ] = self[ 9 ] * matrix[ 4 ] + self[ 10 ] * matrix[ 8 ] + self[ 11 ] * matrix[ 12 ] + self[ 12 ] * matrix[ 16 ]

	self[ 13 ] = self[ 13 ] * matrix[ 1 ] + self[ 14 ] * matrix[ 5 ] + self[ 15 ] * matrix[ 9 ] + self[ 16 ] * matrix[ 13 ]
	self[ 14 ] = self[ 13 ] * matrix[ 2 ] + self[ 14 ] * matrix[ 6 ] + self[ 15 ] * matrix[ 10 ] + self[ 16 ] * matrix[ 14 ]
	self[ 15 ] = self[ 13 ] * matrix[ 3 ] + self[ 14 ] * matrix[ 7 ] + self[ 15 ] * matrix[ 11 ] + self[ 16 ] * matrix[ 15 ]
	self[ 16 ] = self[ 13 ] * matrix[ 4 ] + self[ 14 ] * matrix[ 8 ] + self[ 15 ] * matrix[ 12 ] + self[ 16 ] * matrix[ 16 ]

    return self
end

---@return Vector3
function VMatrix:getForward()
    return std.Vector3( self[ 1 ], self[ 5 ], self[ 9 ] )
end

---@param vector Vector3
---@return VMatrix
function VMatrix:setForward( vector )
    self[ 1 ], self[ 5 ], self[ 9 ] = vector[ 1 ], vector[ 2 ], vector[ 3 ]
    return self
end

---@return Vector3
function VMatrix:getLeft()
    return std.Vector3( self[ 2 ], self[ 6 ], self[ 10 ] )
end

---@param vector Vector3
---@return VMatrix
function VMatrix:setLeft( vector )
    self[ 2 ], self[ 6 ], self[ 10 ] = vector[ 1 ], vector[ 2 ], vector[ 3 ]
    return self
end

---@return Vector3
function VMatrix:getUp()
    return std.Vector3( self[ 3 ], self[ 7 ], self[ 11 ] )
end

---@param vector Vector3
---@return VMatrix
function VMatrix:setUp( vector )
    self[ 3 ], self[ 7 ], self[ 11 ] = vector[ 1 ], vector[ 2 ], vector[ 3 ]
    return self
end

---@return Vector3
function VMatrix:getTranslation()
    return std.Vector3( self[ 4 ], self[ 8 ], self[ 12 ] )
end

---@param vector Vector3
---@return VMatrix
function VMatrix:setTranslation( vector )
    self[ 4 ], self[ 8 ], self[ 12 ] = vector[ 1 ], vector[ 2 ], vector[ 3 ]
    return self
end

---@param vector Vector3
---@return VMatrix
function VMatrix:translate( vector )
    return self:multiply( VMatrixClass():identity():setTranslation( vector ) )
end

---@param row integer
---@param column integer
---@return number
function VMatrix:getField( row, column )
    return self[ ( math.clamp( row, 1, 4 ) - 1 ) * 4 + math.clamp( column, 1, 4 ) ]
end

---@param row integer
---@param column integer
---@param value number
---@return VMatrix
function VMatrix:setField( row, column, value )
    self[ ( math.clamp( row, 1, 4 ) - 1 ) * 4 + math.clamp( column, 1, 4 ) ] = value
    return self
end

function VMatrix:inverse()
    local mat = {
        [ 1 ] = {
            self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ], 1, 0, 0, 0
        },
        [ 2 ] = {
            self[ 5 ], self[ 6 ], self[ 7 ], self[ 8 ], 0, 1, 0, 0
        },
        [ 3 ] = {
            self[ 9 ], self[ 10 ], self[ 11 ], self[ 12 ], 0, 0, 1, 0
        },
        [ 4 ] = {
            self[ 13 ], self[ 14 ], self[ 15 ], self[ 16 ], 0, 0, 0, 1
        }
    }

    local rowMap = { 1, 2, 3, 4 }

    -- Row reduction
    for iRow = 1, 4 do
        local fLargest = 0.00001
        local iLargest = -1

        for iTest = iRow, 4 do
            local fTest = math.abs( mat[ rowMap[ iTest ] ][ iRow ] )
            if fTest > fLargest then
                iLargest = iTest
                fLargest = fTest
            end
        end

        if iLargest == -1 then
            return false, nil
        end

        -- Swap rows
        rowMap[iLargest], rowMap[iRow] = rowMap[iRow], rowMap[iLargest]
        local pRow = mat[rowMap[iRow]]

        -- Normalize row
        local mul = 1.0 / pRow[ iRow ]
        for j = 1, 8, 1 do
            pRow[ j ] = pRow[ j ] * mul
        end

        pRow[ iRow ] = 1.0

        -- Eliminate column
        for i = 1, 4 do
            if i ~= iRow then
                local pScaleRow = mat[rowMap[i]]
                local mul = -pScaleRow[iRow]
                for j = 1, 8 do
                    pScaleRow[j] = pScaleRow[j] + pRow[j] * mul
                end

                pScaleRow[iRow] = 0.0
            end
        end
    end


    -- Extract inverse matrix
    local dst = {}

    for i = 1, 4 do
        dst[ i ] = {}
        local pIn = mat[ rowMap[ i ] ]
        for j = 1, 4 do
            dst[ i ][ j ] = pIn[ j + 4 ]
        end
    end

    return true, dst
end

--- Does a fast inverse, assuming the matrix only contains translation and rotation.
function VMatrix:inverseTranslation()

    local dst = VMatrixClass(
        self[ 1 ], self[ 2 ], self[ 3 ], 0,
        self[ 5 ], self[ 6 ], self[ 7 ], 0,
        self[ 9 ], self[ 10 ], self[ 11 ], 0,
        0, 0, 0, 0
    )
end


-- print( VMatrixClass():identity():copy():multiply( VMatrixClass( 2 ) ):translate( std.Vector3( 1, 2, 1 )) )
