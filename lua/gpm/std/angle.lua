local _G = _G

local gpm = _G.gpm
local std = gpm.std
local debug, math = std.debug, std.math
local setmetatable = std.setmetatable

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

    local string_format = std.string.format

    ---@protected
    ---@private
    function Angle:__tostring()
        return string_format( "Angle: %p [%f, %f, %f]", self, self[ 1 ], self[ 2 ], self[ 3 ] )
    end

end

---@protected
function Angle.__new( pitch, yaw, roll )
    return setmetatable( { pitch, yaw, roll }, Angle )
end

-- Addition

---
---@param other Angle
---@return Angle
function Angle:add( other )
    self[ 1 ] = self[ 1 ] + other[ 1 ]
    self[ 2 ] = self[ 2 ] + other[ 2 ]
    self[ 3 ] = self[ 3 ] + other[ 3 ]
    return self
end

---
---@param other Angle
---@return Angle
function Angle:__add( other )
    return setmetatable( {
        self[ 1 ] + other[ 1 ],
        self[ 2 ] + other[ 2 ],
        self[ 3 ] + other[ 3 ]
    }, Angle )
end

-- Subtraction

---
---@param other Angle
---@return Angle
function Angle:sub( other )
    self[ 1 ] = self[ 1 ] - other[ 1 ]
    self[ 2 ] = self[ 2 ] - other[ 2 ]
    self[ 3 ] = self[ 3 ] - other[ 3 ]
    return self
end

---
---@param other Angle
---@return Angle
function Angle:__sub( other )
    return setmetatable( {
        self[ 1 ] - other[ 1 ],
        self[ 2 ] - other[ 2 ],
        self[ 3 ] - other[ 3 ]
    }, Angle )
end

-- Multiplication
function Angle:mul( other )
    self[ 1 ] = self[ 1 ] * other[ 1 ]
    self[ 2 ] = self[ 2 ] * other[ 2 ]
    self[ 3 ] = self[ 3 ] * other[ 3 ]
    return self
end

---
---@param other Angle
---@return Angle
function Angle:__mul( other )
    return setmetatable( {
        self[ 1 ] * other[ 1 ],
        self[ 2 ] * other[ 2 ],
        self[ 3 ] * other[ 3 ]
    }, Angle )
end

-- Division

---
---@param other Angle
---@return Angle
function Angle:div( other )
    self[ 1 ] = self[ 1 ] / other[ 1 ]
    self[ 2 ] = self[ 2 ] / other[ 2 ]
    self[ 3 ] = self[ 3 ] / other[ 3 ]
    return self
end

---
---@param other Angle
---@return Angle
function Angle:__div( other )
    return setmetatable( {
        self[ 1 ] / other[ 1 ],
        self[ 2 ] / other[ 2 ],
        self[ 3 ] / other[ 3 ]
    }, Angle )
end

-- Lerp

do

    local math_lerp = math.lerp

    ---
    ---@param other Angle
    ---@param frac number
    ---@return Angle
    function Angle:lerp( other, frac )
        self[ 1 ] = math_lerp( frac, self[ 1 ], other[ 1 ] )
        self[ 2 ] = math_lerp( frac, self[ 2 ], other[ 2 ] )
        self[ 3 ] = math_lerp( frac, self[ 3 ], other[ 3 ] )
        return self
    end

    ---
    ---@param other Angle
    ---@param frac number
    ---@return Angle
    function Angle:__lerp( other, frac )
        return setmetatable( {
            math_lerp( frac, self[ 1 ], other[ 1 ] ),
            math_lerp( frac, self[ 2 ], other[ 2 ] ),
            math_lerp( frac, self[ 3 ], other[ 3 ] )
        }, Angle )
    end

end

---@class gpm.std.AngleClass: gpm.std.Angle
---@field __base gpm.std.Angle
---@overload fun(): Angle
local AngleClass = std.class.create( Angle )

-- print( AngleClass( 10.11, 0, 0 ) )

return Angle
