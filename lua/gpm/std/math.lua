local math, isnumber = ...
local math_abs, math_atan, math_ceil, math_min, math_max, math_random, math_sqrt, math_floor, math_log, math_deg, math_pi = math.abs, math.atan, math.ceil, math.min, math.max, math.random, math.sqrt, math.floor, math.log, math.deg, math.pi

local e = math.exp( 1 )
local ln2 = math_log( 2 )

local nan = 0 / 0
local inf = 1 / 0
local neg_inf = -inf

local ispositive = function( number )
    return number > 0 or ( 1 / number ) == inf
end

local sign = function( number )
    return ispositive( number ) and 1 or -1
end

local angleNormal = function( angle )
    return ( ( angle + 180 ) % 360 ) - 180
end

local magnitude = function( x1, y1, x2, y2 )
    return math_sqrt( ( ( x2 - x1 ) ^ 2 ) + ( ( y2 - y1 ) ^ 2 ) )
end

local inrage = function( number, from, to )
    return number >= from and number <= to
end

local triangleSign = function( x1, y1, x2, y2, x3, y3 )
    return ( x1 - x3 ) * ( y2 - y3 ) - ( x2 - x3 ) * ( y1 - y3 )
end

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

local one_third = 1 / 3

return {
    -- Lua 5.1 functions
    ["abs"] = math_abs,
    ["exp"] = math.exp,
    ["fmod"] = math.fmod,
    ["modf"] = math.modf,
    ["sqrt"] = math_sqrt,

    ["sin"] = math.sin,
    ["cos"] = math.cos,
    ["tan"] = math.tan,

    ["asin"] = math.asin,
    ["acos"] = math.acos,
    ["atan"] = atan,

    ["atan2"] = math.atan2, -- deprecated in Lua 5.3
    ["sinh"] = math.sinh, -- deprecated in Lua 5.3
    ["cosh"] = math.cosh, -- deprecated in Lua 5.3
    ["tanh"] = math.tanh, -- deprecated in Lua 5.3

    ["min"] = math_min,
    ["max"] = math_max,

    ["ceil"] = math_ceil,
    ["floor"] = math_floor,

    ["log"] = math_log,
    ["log10"] = math.log10, -- deprecated in Lua 5.3

    ["deg"] = math_deg,
    ["rad"] = math.rad,

    ["random"] = math_random,
    ["randomseed"] = math.randomseed,

    ["frexp"] = math.frexp or function( x )
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
    ["ldexp"] = math.ldexp or function( x, exponent )
        return x * 2.0 ^ exponent
    end,

    -- Constants
    ["e"] = e,
    ["ln2"] = ln2,
    ["nan"] = nan,
    ["inf"] = inf,
    ["pi"] = math_pi,
    ["ninf"] = neg_inf,
    ["huge"] = math.huge,
    ["ln10"] = math_log( 10.0 ),
    ["log10e"] = math_log( e, 10.0 ),
    ["log2e"] = math_log( e, 2.0 ),
    ["sqrt2"] = math_sqrt( 2.0 ),
    ["sqrt1_2"] = math_sqrt( 0.5 ),
    ["maxinteger"] = 0x7FFFFFFF,
    ["mininteger"] = -0x80000000,

    -- Functions
    ["isinf"] = function( number )
        return number == inf or number == neg_inf
    end,
    ["isnan"] = function( number )
        return number == nan
    end,
    ["isfinite"] = function( number )
        return number ~= inf and number ~= neg_inf and number ~= nan
    end,
    ["isuint"] = function( number )
        return number >= 0 and ( number % 1 ) == 0
    end,
    ["isint"] = function( number )
        return ( number % 1 ) == 0
    end,
    ["isfloat"] = function( number )
        return ( number % 1 ) ~= 0
    end,
    ["isequalwith"] = function( a, b, tolerance )
        return math_abs( a - b ) <= tolerance
    end,
    ["isdivideable"] = function( a, b )
        return ( a % b ) == 0
    end,
    ["isbool"] = function( number )
        return number == 0 or number == 1
    end,
    ["iseven"] = function( number )
        return number == 0 or ( number % 2 ) == 0
    end,
    ["isodd"] = function( number )
        return number ~= 0 and ( number % 2 ) ~= 0
    end,
    ["ispositive"] = ispositive,
    ["isnegative"] = function( number )
        return number < 0 or ( 1 / number ) == neg_inf
    end,
    ["sign"] = sign,
    ["round"] = function( number, decimals )
        if decimals then
            local multiplier = 10 ^ decimals
            return math_floor( ( number * multiplier ) + 0.5 ) / multiplier
        end

        return math_floor( number + 0.5 )
    end,
    ["snap"] = function( number, step )
        return math_floor( ( number / step ) + 0.5 ) * step
    end,
    ["trunc"] = function( number, decimals )
        if decimals then
            local multiplier = 10 ^ decimals
            return ( number < 0 and math_ceil or math_floor )( number * multiplier ) / multiplier
        end

        return ( number < 0 and math_ceil or math_floor )( number )
    end,
    ["log1p"] = function( number )
        return math_log( number + 1 )
    end,
    ["log2"] = function( number )
        return math_log( number ) / ln2
    end,
    ["randomf"] = function( a, b )
        return a + ( b - a ) * math_random()
    end,
    ["fdiv"] = function( a, b )
        return math_floor( a / b )
    end,
    ["hypot"] = function( ... )
        local number, args = 0, { ... }
        for index = 1, #args do
            number = number + ( args[ index ] ^ 2 )
        end

        return math_sqrt( number )
    end,
    ["cbrt"] = function( number )
        return number ^ one_third
    end,
    ["root"] = function( a, b )
        return a ^ ( 1 / b )
    end,
    ["timef"] = function( from, to, time )
        return ( from - to ) / ( time - to )
    end,
    ["approach"] = function( current, target, change )
        local diff = target - current
        return current + sign( diff ) * math_min( math_abs( diff ), change )
    end,
    ["split"] = function( number )
        return math_floor( number ), number % 1
    end,
    ["clamp"] = function( number, min, max )
        return math_min( math_max( number, min ), max )
    end,
    ["lerp"] = function( fraction, from, to )
        return from + ( to - from ) * fraction
    end,
    ["ilerp"] = function( fraction, from, to )
        return ( fraction - from ) / ( to - from )
    end,
    ["remap"] = function( number, inMin, inMax, outMin, outMax  )
        return outMin + ( outMax - outMin ) * ( number - inMin ) / ( inMax - inMin )
    end,
    ["inrage"] = inrage,
    ["type"] = function( x )
        if isnumber( x ) then
            return ( x % 1 ) == 0 and "integer" or "float"
        end

        return nil
    end,
    ["angle"] = function( x1, y1, x2, y2 )
        return math_deg( atan( y2 - y1, x2 - x1 ) )
    end,
    ["angleNormal"] = angleNormal,
    ["angleDifference"] = function( a, b )
        local diff = angleNormal( a - b )
        if diff < 180 then
            return diff
        end

        return diff - 360
    end,
    ["magnitude"] = magnitude,
    ["direction"] = function( x1, y1, x2, y2 )
        local diff = magnitude( x1, y1, x2, y2 )
        if diff == 0 then
            return 0, 0
        end

        return ( x2 - x1 ) / diff, ( y2 - y1 ) / diff
    end,
    ["dot"] = function( x1, y1, x2, y2 )
        return x1 * x2 + y1 * y2
    end,
    ["triangleSign"] = triangleSign,
    ["inRect"] = function( x, y, x1, y1, x2, y2 )
        return inrage( x, x1, x2 ) and inrage( y, y1, y2 )
    end,
    ["inCircle"] = function( x, y, cx, cy, r )
        return ( x - cx ) ^ 2 + ( y - cy ) ^ 2 <= r ^ 2
    end,
    ["onTangent"] = function( x, y, x1, y1, x2, y2 )
        return triangleSign( x, y, x1, y1, x2, y2 ) == 0
    end,
    ["inTriangle"] = function( x, y, x1, y1, x2, y2, x3, y3 )
        return ( triangleSign( x, y, x1, y1, x2, y2 ) * triangleSign( x, y, x2, y2, x3, y3 ) ) > 0
    end,
    ["inPoly"] = function( x, y, poly )
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
    end,
    ["bit2byte"] = function( x )
        return math_ceil( x / 8 )
    end,
    ["byte2bit"] = function( x )
        return math_ceil( x ) * 8
    end
}
