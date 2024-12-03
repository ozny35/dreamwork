local _G = _G
local glua_math, isnumber = _G.math, _G.isnumber
local math_abs, math_atan, math_ceil, math_min, math_max, math_random, math_sqrt, math_floor, math_log, math_deg, math_pi = glua_math.abs, glua_math.atan, glua_math.ceil, glua_math.min, glua_math.max, glua_math.random, glua_math.sqrt, glua_math.floor, glua_math.log, glua_math.deg, glua_math.pi

local e = glua_math.exp( 1 )
local ln2 = math_log( 2 )

local nan = 0 / 0
local inf = 1 / 0
local neg_inf = -inf

local atan = function( y, x )
    if x == nil then
        return math_atan( y )
    elseif y == 0 then
      return 0.0
    elseif x == 0 then
        return math_pi / 2
    end

    return math_atan( y / x )
end

---@class gpm.std.math
---@field e number A variable containing the mathematical constant e. (2.7182818284590)
---@field ln2 number A variable containing the mathematical constant natural logarithm of 2. (0.69314718055995)
---@field nan number A variable containing number "not a number". (nan)
---@field inf number A variable containing positive infinity. (inf)
---@field pi number A variable containing the mathematical constant pi. (3.1415926535898)
---@field ninf number A variable containing negative infinity. (-inf)
---@field huge number The float value HUGE_VAL, a value larger than any other numeric value. (inf)
---@field ln10 number A variable containing the mathematical constant natural logarithm of 10. (2.3025850929940)
---@field log10e number A variable containing the mathematical constant logarithm of 10 to the base e. (0.43429448190325)
---@field log2e number A variable containing the mathematical constant logarithm of 2 to the base e. (1.4426950408889)
---@field sqrt2 number A variable containing the mathematical constant square root of 2. (1.4142135623731)
---@field sqrt1_2 number A variable containing the mathematical constant square root of 1/2. (0.70710678118655)
---@field maxinteger number A variable containing the maximum 32bit integer. (2147483647)
---@field mininteger number A variable containing the minimum 32bit integer. (-2147483648)
local math = {
    e = e,
    ln2 = ln2,
    nan = nan,
    inf = inf,
    pi = math_pi,
    ninf = neg_inf,
    huge = glua_math.huge,
    ln10 = math_log( 10.0 ),
    log10e = math_log( e, 10.0 ),
    log2e = math_log( e, 2.0 ),
    sqrt2 = math_sqrt( 2.0 ),
    sqrt1_2 = math_sqrt( 0.5 ),
    maxinteger = 0x7FFFFFFF,
    mininteger = -0x80000000,

    -- Lua 5.1 functions
    abs = math_abs,
    exp = glua_math.exp,
    fmod = glua_math.fmod,
    modf = glua_math.modf,
    sqrt = math_sqrt,

    sin = glua_math.sin,
    cos = glua_math.cos,
    tan = glua_math.tan,

    asin = glua_math.asin,
    acos = glua_math.acos,
    atan = atan,

    atan2 = glua_math.atan2, -- deprecated in Lua 5.3
    sinh = glua_math.sinh, -- deprecated in Lua 5.3
    cosh = glua_math.cosh, -- deprecated in Lua 5.3
    tanh = glua_math.tanh, -- deprecated in Lua 5.3

    min = math_min,
    max = math_max,
    ceil = math_ceil,
    floor = math_floor,

    log = math_log,
    log10 = glua_math.log10, -- deprecated in Lua 5.3

    deg = math_deg,
    rad = glua_math.rad,

    random = math_random,
    randomseed = glua_math.randomseed,

    frexp = glua_math.frexp or function( x )
        if x == 0 then
            return 0.0, 0.0
        end

        local exponent = math_floor( math_log( math_abs( x ) ) / ln2 )
        if exponent > 0.0 then
            x = x * ( 2.0 ^ -exponent )
        else
            x = x / ( 2.0 ^ exponent )
        end

        if math_abs( x ) >= 1.0 then
            return x / 2.0, exponent + 1
        else
            return x, exponent
        end
    end,

    ldexp = glua_math.ldexp or function( x, exponent )
        return x * 2.0 ^ exponent
    end
}

--- Checks if a number is a boolean.
---@param x number The number to check.
---@return boolean
function math.isbool( x )
    return x == 0 or x == 1 and ( x % 1 ) == 0
end

--- Checks if a number is a byte.
---@param x number The number to check.
---@return boolean
function math.isbyte( x )
    return x >= 0 and x <= 255 and ( x % 1 ) == 0
end

--- Checks if a number is an unsigned byte.
---@param x number The number to check.
---@return boolean
function math.isubyte( x )
    return x >= -128 and x <= 127 and ( x % 1 ) == 0
end

--- Checks if a number is a short integer.
---@param x number The number to check.
---@return boolean
function math.isshort( x )
    return x >= -32768 and x <= 32767 and ( x % 1 ) == 0
end

--- Checks if a number is an unsigned short integer.
---@param x number The number to check.
---@return boolean
function math.isushort( x )
    return x >= 0 and x <= 65535 and ( x % 1 ) == 0
end

--- Checks if a number is a long integer.
---@param x number The number to check.
---@return boolean
function math.islong( x )
    return x >= -2147483648 and x <= 2147483647 and ( x % 1 ) == 0
end

--- Checks if a number is an unsigned long integer.
--- @param x number The number to check.
function math.isulong( x )
    return x >= 0 and x <= 4294967295 and ( x % 1 ) == 0
end

--- Checks if a number is an unsigned integer.
---@param x number The number to check.
---@return boolean
function math.isuint( x )
    return x >= 0 and ( x % 1 ) == 0
end

--- Checks if a number is an signed integer.
---@param x number The number to check.
---@return boolean
 function math.isint( x )
    return ( x % 1 ) == 0
end

--- Checks if a number is a float.
---@param x number The number to check.
---@return boolean
function math.isfloat( x )
    return ( x % 1 ) ~= 0 and x >= 1.175494351E-38 and x <= 3.402823466E+38
end

--- Checks if a number is a double.
---@param x number The number to check.
---@return boolean
function math.isdouble( x )
    return ( x % 1 ) ~= 0 and ( x < 1.175494351E-38 or x > 3.402823466E+38 )
end

--- Checks if a number is positive or negative infinity.
---@param x number The number to check.
---@return boolean
function math.isinf( x )
    return x == inf or x == neg_inf
end

--- Checks if a number is NaN.
---@param x number The number to check.
---@return boolean
function math.isnan( x )
    return x == nan
end

--- Checks if a number is finite.
---@param x number The number to check.
---@return boolean
function math.isfinite( x )
    return x ~= inf and x ~= neg_inf and x ~= nan
end

--- Checks if two numbers are equal with a given tolerance.
---@param a number The first number to check.
---@param b number The second number to check.
---@param tolerance number The maximum difference between the numbers.
---@return boolean
function math.isequalwith( a, b, tolerance )
    return math_abs( a - b ) <= tolerance
end

--- Checks if a number is divisible by another number without remainder.
---@param a number The first number to check.
---@param b number The second number to check.
---@return boolean
function math.isdivideable( a, b )
    return ( a % b ) == 0
end

--- Checks if a number is a boolean.
---@param x number The number to check.
---@return boolean
function math.isbool( x )
    return x == 0 or x == 1
end

--- Checks if a number is even.
---@param x number The number to check.
---@return boolean
function math.iseven( x )
    return x == 0 or ( x % 2 ) == 0
end

--- Checks if a number is odd.
---@param x number The number to check.
---@return boolean
function math.isodd( x )
    return x ~= 0 and ( x % 2 ) ~= 0
end

--- Checks if a number is positive.
---@param x number The number to check.
---@return boolean
local function ispositive( x )
    return x > 0 or ( 1 / x ) == inf
end

math.ispositive = ispositive

--- Checks if a number is negative.
---@param x number The number to check.
---@return boolean
function math.isnegative( x )
    return x < 0 or ( 1 / x ) == neg_inf
end

--- Returns the sign of a number as 1 or -1.
---@param x number The number to check.
---@return number
local function sign( x )
    return ispositive( x ) and 1 or -1
end

math.sign = sign

--- Rounds the given value to the nearest whole number or to the given decimal places.
---@param number number The number to round.
---@param decimals? number The number of decimal places to round to.
---@return number
function math.round( number, decimals )
    if decimals then
        local multiplier = 10 ^ decimals
        return math_floor( ( number * multiplier ) + 0.5 ) / multiplier
    end

    return math_floor( number + 0.5 )
end

--- Returns the smallest integer greater than or equal to the given number.
---@param number number The number to round.
---@param step number The step size to round to.
---@return number
function math.snap( number, step )
    return math_floor( ( number / step ) + 0.5 ) * step
end

--- Returns number without fractional part, ignoring the argument sign.
---@param number number The number to round.
---@param decimals? number The number of decimal places to round to.
---@return number
function math.trunc( number, decimals )
    if decimals then
        local multiplier = 10 ^ decimals
        return ( number < 0 and math_ceil or math_floor )( number * multiplier ) / multiplier
    end

    return ( number < 0 and math_ceil or math_floor )( number )
end

--- Returns the natural logarithm of the given number.
---@param x number The number to calculate the logarithm of.
---@return number
function math.log1p( x )
    return math_log( x + 1 )
end

--- Returns the base 2 logarithm of the given number.
---@param x number The number to calculate the logarithm of.
---@return number
function math.log2( x )
    return math_log( x ) / ln2
end

--- Returns a random floating point number in the range [a, b).
---@param a number The minimum value.
---@param b number The maximum value.
---@return number
function math.randomf( a, b )
    return a + ( b - a ) * math_random()
end

--- Returns floor division of two numbers. ( // from Lua 5.3 )
---@param a number The dividend.
---@param b number The divisor.
---@return number
function math.fdiv( a, b )
    return math_floor( a / b )
end

--- Returns the square root of the sum of squares of its arguments.
---@vararg number The numbers to calculate the square root of.
---@return number
function math.hypot( ... )
    local number, args = 0, { ... }
    for index = 1, #args do
        number = number + ( args[ index ] ^ 2 )
    end

    return math_sqrt( number )
end

do

    local one_third = 1 / 3

    --- Returns the cube root of the given number.
    ---@param x number The number to calculate the cube root of.
    ---@return number
    function math.cbrt( x )
        return x ^ one_third
    end

end

--- Returns the root of a given number with a given base.
---@param a number The number to calculate the root of.
---@param b number The base of the root.
---@return number
function math.root( a, b )
    return a ^ ( 1 / b )
end

--- Returns the fraction of where the current time is relative to the start and end times
---@param from number The start time.
---@param to number The end time.
---@param time number The current time.
---@return number
function math.timef( from, to, time )
    return ( from - to ) / ( time - to )
end

--- Gradually approaches the target value by the specified amount.
---@param current number The current value.
---@param target number The target value.
---@param change number The amount that the current value is allowed to change by to approach the target.
function math.approach( current, target, change )
    local diff = target - current
    return current + sign( diff ) * math_min( math_abs( diff ), change )
end

--- Splits a number into its integer and fractional parts.
---@param x number The number to split.
---@return number, number
function math.split( x )
    return math_floor( x ), x % 1
end

--- Clamps a number between a minimum and maximum value.
---@param number number The number to clamp.
---@param min number The minimum value.
---@param max number The maximum value.
---@return number
function math.clamp( number, min, max )
    return math_min( math_max( number, min ), max )
end

--- Performs a linear interpolation from the start number to the end number.
---@param fraction number The fraction of the way between the start and end numbers.
---@param from number The start number.
---@param to number The end number.
---@return number
function math.lerp( fraction, from, to )
    return from + ( to - from ) * fraction
end

--- Performs an inverse linear interpolation from the start number to the end number.
---@param fraction number The fraction of the way between the start and end numbers.
---@param from number The start number.
---@param to number The end number.
---@return number
function math.ilerp( fraction, from, to )
    return ( fraction - from ) / ( to - from )
end

--- Remaps a number from one range to another.
---@param number number The number to remap.
---@param inMin number The minimum value of the input range.
---@param inMax number The maximum value of the input range.
---@param outMin number The minimum value of the output range.
---@param outMax number The maximum value of the output range.
---@return number
function math.remap( number, inMin, inMax, outMin, outMax  )
    return outMin + ( outMax - outMin ) * ( number - inMin ) / ( inMax - inMin )
end

--- Checks if a number is in a range.
---@param number number The number to check.
---@param from number The minimum value of the range.
---@param to number The maximum value of the range.
---@return boolean
local function inrage( number, from, to )
    return number >= from and number <= to
end

math.inrage = inrage

--- Returns "integer" if x is an integer, "float" if it is a float, or nil if x is not a number.
---@param x number The number to get the type of.
---@return "integer" | "float" | nil
function math.type( x )
    if isnumber( x ) then
        return ( x % 1 ) == 0 and "integer" or "float"
    end

    return nil
end

--- Calculates the angle between two points.
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number
function math.angle( x1, y1, x2, y2 )
    return math_deg( atan( y2 - y1, x2 - x1 ) )
end

--- Returns the normalised angle between two points.
---@param angle number The angle to normalise.
---@return number
local function angleNormal( angle )
    return ( ( angle + 180 ) % 360 ) - 180
end

math.angleNormal = angleNormal

--- Returns the difference between two angles.
---@param a number The first angle.
---@param b number The second angle.
---@return number
function math.angleDifference( a, b )
    local diff = angleNormal( a - b )
    if diff < 180 then
        return diff
    end

    return diff - 360
end

--- Calculates the magnitude (distance) between two points.
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number
local function magnitude( x1, y1, x2, y2 )
    return math_sqrt( ( ( x2 - x1 ) ^ 2 ) + ( ( y2 - y1 ) ^ 2 ) )
end

math.magnitude = magnitude

--- Calculates the direction between two points.
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number x, number y
function math.direction( x1, y1, x2, y2 )
    local diff = magnitude( x1, y1, x2, y2 )
    if diff == 0 then
        return 0, 0
    end

    return ( x2 - x1 ) / diff, ( y2 - y1 ) / diff
end

--- Calculates the dot product between two points.
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number
function math.dot( x1, y1, x2, y2 )
    return x1 * x2 + y1 * y2
end

-- TODO:
local function triangleSign( x1, y1, x2, y2, x3, y3 )
    return ( x1 - x3 ) * ( y2 - y3 ) - ( x2 - x3 ) * ( y1 - y3 )
end

math.triangleSign = triangleSign

--- Checks if a point is within a rectangle.
---@param x number The x coordinate of the first point of the rectangle.
---@param y number The y coordinate of the first point of the rectangle.
---@param x1 number The x coordinate of the second point of the rectangle.
---@param y1 number The y coordinate of the second point of the rectangle.
---@param x2 number The x coordinate of the third point of the rectangle.
---@param y2 number The y coordinate of the third point of the rectangle.
---@return boolean
function math.inRect( x, y, x1, y1, x2, y2 )
    return inrage( x, x1, x2 ) and inrage( y, y1, y2 )
end

--- Checks if a point is within a circle.
---@param x number The x coordinate of the point.
---@param y number The y coordinate of the point.
---@param cx number The x coordinate of the center of the circle.
---@param cy number The y coordinate of the center of the circle.
---@param r number The radius of the circle.
---@return boolean
function math.inCircle( x, y, cx, cy, r )
    return ( x - cx ) ^ 2 + ( y - cy ) ^ 2 <= r ^ 2
end

--- Checks if the point is on the tangent.
---@param x number The x coordinate of the point to check.
---@param y number The y coordinate of the point to check.
---@param x1 number The x coordinate of the first point of the line.
---@param y1 number The y coordinate of the first point of the line.
---@param x2 number The x coordinate of the second point of the line.
---@param y2 number The y coordinate of the second point of the line.
---@return boolean
function math.onTangent( x, y, x1, y1, x2, y2 )
    return triangleSign( x, y, x1, y1, x2, y2 ) == 0
end

--- Checks if the point is in the triangle.
---@param x number The x coordinate of the point to check.
---@param y number The y coordinate of the point to check.
---@param x1 number The x coordinate of the first point of the triangle.
---@param y1 number The y coordinate of the first point of the triangle.
---@param x2 number The x coordinate of the second point of the triangle.
---@param y2 number The y coordinate of the second point of the triangle.
---@param x3 number The x coordinate of the third point of the triangle.
---@param y3 number The y coordinate of the third point of the triangle.
---@return boolean
function math.inTriangle( x, y, x1, y1, x2, y2, x3, y3 )
    return ( triangleSign( x, y, x1, y1, x2, y2 ) * triangleSign( x, y, x2, y2, x3, y3 ) ) > 0
end

--- Checks if the point is in the polygon.
---@param x number The x coordinate of the point to check.
---@param y number The y coordinate of the point to check.
---@param poly table The array of points of the polygon. [ [ x1, y1 ], [ x2, y2 ], [ x3, y3 ], ... ]
---@return boolean
function math.inPoly( x, y, poly )
    local inside = false

    local j = #poly
    for i = 1, j do
        local px, py, lpy = poly[ i ][ 1 ], poly[ i ][ 2 ], poly[ j ][ 2 ]
        if ( py < y and lpy >= y or lpy < y and py >= y ) and ( px + ( y - py ) / ( lpy - py ) * ( poly[ j ][ 1 ] - px ) < x ) then
            inside = not inside
        end

        j = i
    end

    return inside
end

--- Converts a bits number to a byte number.
---@param x number The bits number.
---@return number bytes The byte number.
function math.bit2byte( x )
    return math_ceil( x / 8 )
end

--- Converts a byte number to a bits number.
---@param x number The byte number.
---@return number bits The bits number.
function math.byte2bit( x )
    return math_ceil( x ) * 8
end

return math
