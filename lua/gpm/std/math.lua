local _G = _G
local glua_math, std = _G.math, _G.gpm.std
local math_abs, math_atan, math_ceil, math_min, math_max, math_random, math_sqrt, math_floor, math_log, math_deg, math_pi = glua_math.abs, glua_math.atan, glua_math.ceil, glua_math.min, glua_math.max, glua_math.random, glua_math.sqrt, glua_math.floor, glua_math.log, glua_math.deg, glua_math.pi

local e = glua_math.exp( 1 )
local ln2 = math_log( 2 )

local huge = glua_math.huge
local tiny = -huge

local function atan( y, x )
    if x == nil then
        return math_atan( y )
    elseif y == 0 then
      return 0.0
    elseif x == 0 then
        return math_pi / 2
    end

    return math_atan( y / x )
end

--- [SHARED AND MENU]
--- The powerful math library.
---@class gpm.std.math
---@field e number A variable containing the mathematical constant e. (2.7182818284590)
---@field ln2 number A variable containing the mathematical constant natural logarithm of 2. (0.69314718055995)
---@field nan number A variable containing number "not a number". (nan)
---@field pi number A variable containing the mathematical constant pi. (3.1415926535898)
---@field huge number A variable that effectively represents infinity, in the sense that in any numerical comparison every number will be less than this. (inf)
---@field tiny number A variable that effectively represents negative infinity, in the sense that in any numerical comparison every number will be greater than this. (-inf)
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
    huge = huge,
    tiny = tiny,
    nan = 0 / 0,
    pi = math_pi,
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
---@return boolean: `true` if the number is a boolean, otherwise `false`.
function math.isbool( x )
    return x == 0 or x == 1 and ( x % 1 ) == 0
end

--- Checks if a number is a byte.
---@param x number The number to check.
---@return boolean: `true` if the number is an integer, otherwise `false`.
function math.isbyte( x )
    return x >= 0 and x <= 255 and ( x % 1 ) == 0
end

--- Checks if a number is an unsigned byte.
---@param x number The number to check.
---@return boolean: `true` if the number is an integer, otherwise `false`.
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
---@return boolean: `true` if the number is an integer, otherwise `false`.
function math.isushort( x )
    return x >= 0 and x <= 65535 and ( x % 1 ) == 0
end

--- Checks if a number is a long integer.
---@param x number The number to check.
---@return boolean: `true` if the number is an integer, otherwise `false`.
function math.islong( x )
    return x >= -2147483648 and x <= 2147483647 and ( x % 1 ) == 0
end

--- Checks if a number is an unsigned long integer.
--- @param x number: The number to check.
function math.isulong( x )
    return x >= 0 and x <= 4294967295 and ( x % 1 ) == 0
end

--- Checks if a number is an unsigned integer.
---@param x number The number to check.
---@return boolean: `true` if the number is an integer, otherwise `false`.
function math.isuint( x )
    return x >= 0 and ( x % 1 ) == 0
end

--- Checks if a number is an signed integer.
---@param x number The number to check.
---@return boolean: `true` if the number is an integer, otherwise `false`.
 function math.isint( x )
    return ( x % 1 ) == 0
end

--- Checks if a number is a float.
---@param x number The number to check.
---@return boolean: `true` if the number is a float, otherwise `false`.
function math.isfloat( x )
    return ( x % 1 ) ~= 0 and x >= 1.175494351E-38 and x <= 3.402823466E+38
end

--- Checks if a number is a double.
---@param x number The number to check.
---@return boolean: `true` if the number is a double, otherwise `false`.
function math.isdouble( x )
    return ( x % 1 ) ~= 0 and ( x < 1.175494351E-38 or x > 3.402823466E+38 )
end

--- Checks if a number is positive or negative infinity.
---@param x number The number to check.
---@return boolean: `true` if the number is positive or negative infinity, otherwise `false`.
function math.isinf( x )
    return x == huge or x == tiny
end

--- Checks if a number is NaN.
---@param x number The number to check.
---@return boolean: `true` if the number is NaN, otherwise `false`.
function math.isnan( x )
    return x ~= x
end

--- Checks if a number is finite.
---@param x number The number to check.
---@return boolean: `true` if the number is finite, otherwise `false`.
function math.isfinite( x )
    return x ~= huge and x ~= tiny and x == x
end

--- Checks if two numbers are equal with a given tolerance.
---@param a number The first number to check.
---@param b number The second number to check.
---@param tolerance number The maximum difference between the numbers.
---@return boolean: `true` if the numbers are equal within the tolerance, otherwise `false`.
function math.isequalwith( a, b, tolerance )
    return math_abs( a - b ) <= tolerance
end

--- Checks if a number is divisible by another number without remainder.
---@param a number The first number to check.
---@param b number The second number to check.
---@return boolean: `true` if the first number is divisible by the second number, otherwise `false`.
function math.isdivideable( a, b )
    return ( a % b ) == 0
end

--- Checks if a number is a boolean.
---@param x number The number to check.
---@return boolean: `true` if the number is a boolean, otherwise `false`.
function math.isbool( x )
    return x == 0 or x == 1
end

--- Checks if a number is even.
---@param x number The number to check.
---@return boolean: `true` if the number is even, otherwise `false`.
function math.iseven( x )
    return x == 0 or ( x % 2 ) == 0
end

--- Checks if a number is odd.
---@param x number The number to check.
---@return boolean: `true` if the number is odd, otherwise `false`.
function math.isodd( x )
    return x ~= 0 and ( x % 2 ) ~= 0
end

--- Checks if a number is positive.
---@param x number The number to check.
---@return boolean: `true` if the number is positive, otherwise `false`.
function math.ispositive( x )
    return x > 0 or ( 1 / x ) == huge
end

--- Checks if a number is negative.
---@param x number The number to check.
---@return boolean: `true` if the number is negative, otherwise `false`.
function math.isnegative( x )
    return x < 0 or ( 1 / x ) == tiny
end

--- Returns the sign of a number as 1 or -1.
---@param x number The number to check.
---@return number: `1` if the number is positive, `-1` if the number is negative.
local function sign( x )
    return x > 0 and 1 or -1
end

math.sign = sign

--- Rounds the given value to the nearest whole number or to the given decimal places.
---@param number number The number to round.
---@param decimals? number: The number of decimal places to round to.
---@return number: The rounded number.
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
---@return number: The rounded number.
function math.snap( number, step )
    return math_floor( ( number / step ) + 0.5 ) * step
end

do

    --- Returns the integer part of the given number.
    ---@param number number The number to truncate.
    ---@return number: The integer part of the number.
    local function math_trunc( number )
        return ( number < 0 and math_ceil or math_floor )( number )
    end

    math.trunc = math_trunc

    --- Splits a number into its integer and fractional parts.
    ---@param x number The number to split.
    ---@return number: The integer part of the number.
    ---@return number: The fractional part of the number.
    function math.split( x )
        return math_trunc( x ), x % 1
    end

end

--- Returns the natural logarithm of the given number.
---@param x number The number to calculate the logarithm of.
---@return number: The natural logarithm of the number.
function math.log1p( x )
    return math_log( x + 1 )
end

--- Returns the base 2 logarithm of the given number.
---@param x number The number to calculate the logarithm of.
---@return number: The base 2 logarithm of the number.
function math.log2( x )
    return math_log( x ) / ln2
end

--- Returns a random floating point number in the range [a, b).
---@param a number The minimum value.
---@param b number The maximum value.
---@return number: The random floating point number.
function math.randomf( a, b )
    return a + ( b - a ) * math_random()
end

--- Returns floor addition of two numbers.
---@param a number The first number.
---@param b number The second number.
---@return number: The floor of the addition.
function math.fadd( a, b )
    return math_floor( a + b )
end

--- Returns floor subtraction of two numbers.
---@param a number The first number.
---@param b number The second number.
---@return number: The floor of the subtraction.
function math.fsub( a, b )
    return math_floor( a - b )
end

--- Returns floor division of two numbers. ( // from Lua 5.3 )
---@param a number The dividend.
---@param b number The divisor.
---@return number: The floor of the division.
function math.fdiv( a, b )
    return math_floor( a / b )
end

--- Returns floor multiplication of two numbers.
---@param a number The first number.
---@param b number The second number.
---@return number: The floor of the multiplication.
function math.fmul( a, b )
    return math_floor( a * b )
end

--- Returns floor exponentiation of two numbers.
---@param a number The base.
---@param b number The exponent.
---@return number: The floor of the exponentiation.
function math.fpow( a, b )
    return math_floor( a ^ b )
end

--- Returns the square root of the sum of squares of its arguments.
---@param ... number: The numbers to calculate the square root of.
---@return number: The square root of the sum of squares of its arguments.
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
    ---@return number: The cube root of the number.
    function math.cbrt( x )
        return x ^ one_third
    end

end

--- Returns the root of a given number with a given base.
---@param a number The number to calculate the root of.
---@param b number The base of the root.
---@return number: The root of the number.
function math.root( a, b )
    return a ^ ( 1 / b )
end

--- Returns the fraction of where the current time is relative to the start and end times
---@param from number The start time.
---@param to number The end time.
---@param time number The current time.
---@return number: The fraction of the way between the start and end times.
function math.timef( from, to, time )
    return ( from - to ) / ( time - to )
end

--- Gradually approaches the target value by the specified amount.
---@param current number The current value.
---@param target number The target value.
---@param change number The amount that the current value is allowed to change by to approach the target.
---@return number: The approached value.
function math.approach( current, target, change )
    local diff = target - current
    return current + sign( diff ) * math_min( math_abs( diff ), change )
end

--- Clamps a number between a minimum and maximum value.
---@param number number The number to clamp.
---@param min number The minimum value.
---@param max number The maximum value.
---@return number: The clamped number.
function math.clamp( number, min, max )
    return math_min( math_max( number, min ), max )
end

--- Performs a linear interpolation from the start number to the end number.
---@param fraction number The fraction of the way between the start and end numbers.
---@param from number The start number.
---@param to number The end number.
---@return number: The interpolated value.
function math.lerp( fraction, from, to )
    return from + ( to - from ) * fraction
end

--- Performs an inverse linear interpolation from the start number to the end number.
---@param result number The interpolated value.
---@param from number The start number.
---@param to number The end number.
---@return number: The fraction of the way between the start and end numbers.
function math.ilerp( result, from, to )
    return ( result - from ) / ( to - from )
end

--- Performs a smooth interpolation from the start number to the end number.
---@param previous number The previous value.
---@param next number The next value.
---@param alpha number The amount of smoothing.
---@return number value The interpolated value.
function math.smooth( previous, next, alpha )
    return alpha * next + ( 1 - alpha ) * previous
end

--- Remaps a number from one range to another.
---@param number number The number to remap.
---@param inMin number The minimum value of the input range.
---@param inMax number The maximum value of the input range.
---@param outMin number The minimum value of the output range.
---@param outMax number The maximum value of the output range.
---@return number: The remapped value.
function math.remap( number, inMin, inMax, outMin, outMax  )
    return outMin + ( outMax - outMin ) * ( number - inMin ) / ( inMax - inMin )
end

--- Checks if a number is in a range.
---@param number number The number to check.
---@param from number The minimum value of the range.
---@param to number The maximum value of the range.
---@return boolean: `true` if the number is in the range, otherwise `false`.
local function inrage( number, from, to )
    return number >= from and number <= to
end

math.inrage = inrage

do

    local isnumber = std.isnumber

    --- Returns "integer" if x is an integer, "float" if it is a float, or nil if x is not a number.
    ---@param x number The number to get the type of.
    ---@return "integer" | "float" | nil: The type of the number.
    function math.type( x )
        if isnumber( x ) then
            return ( x % 1 ) == 0 and "integer" or "float"
        end

        return nil
    end

end

--- Calculates the angle between two points.
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number: The angle between the two points.
function math.angle( x1, y1, x2, y2 )
    return math_deg( atan( y2 - y1, x2 - x1 ) )
end

--- Returns the normalised angle between two points.
---@param angle number The angle to normalise.
---@return number: The normalised angle.
local function angleNormalize( angle )
    return ( ( angle + 180 ) % 360 ) - 180
end

math.angleNormalize = angleNormalize

--- Returns the difference between two angles.
---@param a number The first angle.
---@param b number The second angle.
---@return number: The difference between the angles.
function math.angleDifference( a, b )
    local diff = angleNormalize( a - b )
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
---@return number: The magnitude between the two points.
local function magnitude( x1, y1, x2, y2 )
    return math_sqrt( ( ( x2 - x1 ) ^ 2 ) + ( ( y2 - y1 ) ^ 2 ) )
end

math.magnitude = magnitude

--- Calculates the direction between two points.
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number x: The x coordinate of the direction.
---@return number y: The y coordinate of the direction.
function math.direction( x1, y1, x2, y2 )
    local diff = magnitude( x1, y1, x2, y2 )
    if diff == 0 then
        return 0, 0
    end

    return ( x2 - x1 ) / diff, ( y2 - y1 ) / diff
end

--- Calculates the euclidean modulus.
---@param numerator number The numerator.
---@param denominator number The denominator.
---@return number: The euclidean modulus.
function math.euclideanMod( numerator, denominator )
    local result = numerator % denominator
    return result < 0 and result + denominator or result
end

--- Checks if a number is near another number.
---@param a number The first number.
---@param b number?: The second number.
---@param tolerance number?: The maximum difference between the numbers.
---@return boolean: `true` if the numbers are near, otherwise `false`.
function math.isNear( a, b, tolerance )
    return math_abs( a - ( b or 0 ) ) <= ( tolerance or 0 )
end

--- Returns x with the same sign as y.
---@param x number The number to copy the sign of.
---@param y number The number to get the sign from.
---@return number: The number with the sign of y.
function math.copysign( x, y )
    return ( ( x > 0 and y > 0 ) or ( x < 0 and y < 0 ) ) and x or -x
end

--- Converts a bits number to a byte number.
---@param x number The bits number.
---@return number bytes: The byte number.
function math.bit2byte( x )
    return math_ceil( x / 8 )
end

--- Converts a byte number to a bits number.
---@param x number The byte number.
---@return number bits: The bits number.
function math.byte2bit( x )
    return math_ceil( x ) * 8
end

--- Returns the variance of a list.
---@param lst number[] The list.
---@param mean number The mean of the list.
---@return number result The variance of the list.
function math.variance( lst, mean )
    local summary, length = 0, #lst
    for i = 1, length, 1 do
        summary = summary + ( lst[ i ] - mean ) ^ 2
    end

    return summary / length
end

return math
