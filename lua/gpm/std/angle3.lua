local _G = _G

local gpm = _G.gpm
local std = gpm.std
local debug, math = std.debug, std.math
local setmetatable = std.setmetatable

local math_cos, math_sin, math_rad = math.cos, math.sin, math.rad

local Vector3 = std.Vector3

-- local ANGLE = debug.findmetatable( "Angle" )
-- if ANGLE == nil then return end
-- ---@cast ANGLE Angle

--[[

    TODO: Make angle class
    https://wiki.facepunch.com/gmod/Global.LerpAngle

]]

---@alias Angle3 gpm.std.Angle3
---@class gpm.std.Angle3: gpm.std.Object
---@field __class gpm.std.Angle3Class
local Angle3 = std.class.base( "Angle3" )

---@class gpm.std.Angle3Class: gpm.std.Angle3
---@field __base gpm.std.Angle3
---@overload fun( pitch: number, yaw: number, roll: number ): Angle3
local Angle3Class = std.class.create( Angle3 )

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

-- Addition

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
function Angle3:__add( angle )
    return setmetatable( {
        self[ 1 ] + angle[ 1 ],
        self[ 2 ] + angle[ 2 ],
        self[ 3 ] + angle[ 3 ]
    }, Angle3 )
end

-- Subtraction

---
---@param angle Angle3
---@return Angle3
function Angle3:sub( angle )
    self[ 1 ] = self[ 1 ] - angle[ 1 ]
    self[ 2 ] = self[ 2 ] - angle[ 2 ]
    self[ 3 ] = self[ 3 ] - angle[ 3 ]
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

-- Multiplication
function Angle3:mul( angle )
    self[ 1 ] = self[ 1 ] * angle[ 1 ]
    self[ 2 ] = self[ 2 ] * angle[ 2 ]
    self[ 3 ] = self[ 3 ] * angle[ 3 ]
    return self
end

---
---@param angle Angle3
---@return Angle3
function Angle3:__mul( angle )
    return setmetatable( {
        self[ 1 ] * angle[ 1 ],
        self[ 2 ] * angle[ 2 ],
        self[ 3 ] * angle[ 3 ]
    }, Angle3 )
end

-- Division

---
---@param angle Angle3
---@return Angle3
function Angle3:div( angle )
    self[ 1 ] = self[ 1 ] / angle[ 1 ]
    self[ 2 ] = self[ 2 ] / angle[ 2 ]
    self[ 3 ] = self[ 3 ] / angle[ 3 ]
    return self
end

---
---@param angle Angle3
---@return Angle3
function Angle3:__div( angle )
    return setmetatable( {
        self[ 1 ] / angle[ 1 ],
        self[ 2 ] / angle[ 2 ],
        self[ 3 ] / angle[ 3 ]
    }, Angle3 )
end

---
---@param angle Angle3
---@param frac number
---@return Angle3
function Angle3:lerp( angle, frac )
    self[ 1 ] = math_lerp( frac, self[ 1 ], angle[ 1 ] )
    self[ 2 ] = math_lerp( frac, self[ 2 ], angle[ 2 ] )
    self[ 3 ] = math_lerp( frac, self[ 3 ], angle[ 3 ] )
    return self
end

---
---@param angle1 Angle3
---@param angle2 Angle3
---@param frac number
---@return Angle3
function Angle3Class.lerp( angle1, angle2, frac )
    return setmetatable( {
        math_lerp( frac, angle1[ 1 ], angle2[ 1 ] ),
        math_lerp( frac, angle1[ 2 ], angle2[ 2 ] ),
        math_lerp( frac, angle1[ 3 ], angle2[ 3 ] )
    }, Angle3 )
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

return Angle3Class
