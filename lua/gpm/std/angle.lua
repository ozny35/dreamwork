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

---@class gpm.std.AngleClass: gpm.std.Angle
---@field __base gpm.std.Angle
---@overload fun(): Angle
local AngleClass = std.class.create( Angle )

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
---@param angle Angle
---@return Angle
function Angle:add( angle )
    self[ 1 ] = self[ 1 ] + angle[ 1 ]
    self[ 2 ] = self[ 2 ] + angle[ 2 ]
    self[ 3 ] = self[ 3 ] + angle[ 3 ]
    return self
end

---
---@param angle Angle
---@return Angle
function Angle:__add( angle )
    return setmetatable( {
        self[ 1 ] + angle[ 1 ],
        self[ 2 ] + angle[ 2 ],
        self[ 3 ] + angle[ 3 ]
    }, Angle )
end

-- Subtraction

---
---@param angle Angle
---@return Angle
function Angle:sub( angle )
    self[ 1 ] = self[ 1 ] - angle[ 1 ]
    self[ 2 ] = self[ 2 ] - angle[ 2 ]
    self[ 3 ] = self[ 3 ] - angle[ 3 ]
    return self
end

---
---@param angle Angle
---@return Angle
function Angle:__sub( angle )
    return setmetatable( {
        self[ 1 ] - angle[ 1 ],
        self[ 2 ] - angle[ 2 ],
        self[ 3 ] - angle[ 3 ]
    }, Angle )
end

-- Multiplication
function Angle:mul( angle )
    self[ 1 ] = self[ 1 ] * angle[ 1 ]
    self[ 2 ] = self[ 2 ] * angle[ 2 ]
    self[ 3 ] = self[ 3 ] * angle[ 3 ]
    return self
end

---
---@param angle Angle
---@return Angle
function Angle:__mul( angle )
    return setmetatable( {
        self[ 1 ] * angle[ 1 ],
        self[ 2 ] * angle[ 2 ],
        self[ 3 ] * angle[ 3 ]
    }, Angle )
end

-- Division

---
---@param angle Angle
---@return Angle
function Angle:div( angle )
    self[ 1 ] = self[ 1 ] / angle[ 1 ]
    self[ 2 ] = self[ 2 ] / angle[ 2 ]
    self[ 3 ] = self[ 3 ] / angle[ 3 ]
    return self
end

---
---@param angle Angle
---@return Angle
function Angle:__div( angle )
    return setmetatable( {
        self[ 1 ] / angle[ 1 ],
        self[ 2 ] / angle[ 2 ],
        self[ 3 ] / angle[ 3 ]
    }, Angle )
end

-- Lerp
do

    local math_lerp = math.lerp

    ---
    ---@param angle Angle
    ---@param frac number
    ---@return Angle
    function Angle:lerp( angle, frac )
        self[ 1 ] = math_lerp( frac, self[ 1 ], angle[ 1 ] )
        self[ 2 ] = math_lerp( frac, self[ 2 ], angle[ 2 ] )
        self[ 3 ] = math_lerp( frac, self[ 3 ], angle[ 3 ] )
        return self
    end

    ---
    ---@param angle1 Angle
    ---@param angle2 Angle
    ---@param frac number
    ---@return Angle
    function AngleClass.lerp( angle1, angle2, frac )
        return setmetatable( {
            math_lerp( frac, angle1[ 1 ], angle2[ 1 ] ),
            math_lerp( frac, angle1[ 2 ], angle2[ 2 ] ),
            math_lerp( frac, angle1[ 3 ], angle2[ 3 ] )
        }, Angle )
    end

end

-- print( AngleClass( 10.11, 0, 0 ) )

return Angle
