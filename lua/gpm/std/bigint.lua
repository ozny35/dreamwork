--[[
    Lua 5.1 Bigint by soupstream
    https://github.com/soupstream/lua-5.1-bigint/tree/master
    Modified by Unknown Developer
]]

local _G = _G

---@class gpm.std
local std = _G.gpm.std

local bigint_digits = {
    "0", "1", "2",
    "3", "4", "5",
    "6", "7", "8",
    "9", "a", "b",
    "c", "d", "e",
    "f", "g", "h",
    "i", "j", "k",
    "l", "m", "n",
    "o", "p", "q",
    "r", "s", "t",
    "u", "v", "w",
    "x", "y", "z"
}

local bigint_constructor
local bigint_ensureBigInt

local getmetatable, setmetatable = std.getmetatable, std.setmetatable
local isstring, isnumber, istable = std.isstring, std.isnumber, std.istable

local math = std.math
local math_floor, math_max, math_clamp = math.floor, math.max, math.clamp

local table_concat, table_reverse, table_unpack
do
    local table = std.table
    table_concat, table_reverse, table_unpack = table.concat, table.reverse, table.unpack
end

local string_sub, string_len, string_rep, string_byte, string_char, string_format
do
    local string = std.string
    string_sub, string_len, string_rep, string_byte, string_char, string_format = string.sub, string.len, string.rep, string.byte, string.char, string.format
end

---@alias BigInt gpm.std.BigInt
---@class gpm.std.BigInt: gpm.std.Object
---@field __class gpm.std.BigIntClass
---@field sign integer
local BigInt = std.class.base( "BigInt" )

function BigInt:__bitcount()
    return #self * 8
end

function BigInt:__tobool()
    return self[ 0 ] ~= 0
end

---@class gpm.std.BigIntClass: gpm.std.BigInt
---@overload fun( value: string | number | BigInt | table, base: number? ): BigInt
local BigIntClass = std.class.create( BigInt )

---@class gpm.std.BigInt.bit
local bit = {}
BigIntClass.bit = bit

--[[

    big int:
    [-1] - sign
    [0] - length
    [1-...] - bytes

]]

--- TODO
---@param object BigInt
---@return BigInt
local function bigint_copy( object )
    local copy = {}

    for index, value in ipairs( object ) do
        copy[ index ] = value
    end

    return setmetatable( copy, BigInt )
end

BigInt.copy = bigint_copy

--- TODO
---@return BigInt
local function bigint_new()
    return setmetatable( { [ 0 ] = 0 }, BigInt )
end

local bigint_one = setmetatable( { [ 0 ] = 1, 1 }, BigInt )
local bigint_negaive_one = setmetatable( { [ 0 ] = -1, 1 }, BigInt )

--- TODO
---@param object BigInt
---@return BigInt
local function bigint_zero( object )
    object[ 0 ] = 0

    for i = 1, #object, 1 do
        object[ i ] = nil
    end

    return object
end

function BigInt:__index( key )
    return key == "sign" and self[ 0 ] or BigInt[ key ]
end

function BigInt:__newindex( key, value )
    if key == "sign" then
        local sign = math_clamp( value, -1, 1 )

        if self[ 0 ] == 0 or sign == self[ 0 ] then
            return self
        elseif sign == 0 then
            bigint_zero( self )
            return self
        elseif sign == -1 or sign == 1 then
            self[ 0 ] = sign
            return self
        end

        std.error( "invalid sign", 2 )
    end

    std.rawset( self, key, value )
end

--- TODO
---@param object BigInt
---@param value BigInt
---@return integer
local function bigint_compare_unsigned( object, value )
    local other = bigint_ensureBigInt( value )
    local byte_count1, byte_count2 = #object, #other

    if byte_count1 < byte_count2 then
        return -1
    elseif byte_count1 > byte_count2 then
        return 1
    end

    for i = byte_count1, 1, -1 do
        if object[ i ] < other[ i ] then
            return -1
        elseif object[ i ] > other[ i ] then
            return 1
        end
    end

    return 0
end

--- TODO
---@param object BigInt
local function bigint_rstrip( object )
    local i = #object
    while i ~= 0 and object[ i ] == 0 do
        object[ i ], i = nil, i - 1
    end

    if i == 0 then
        object[ 0 ] = 0
    end
end

--- TODO
---@param object BigInt
---@param number integer
---@return BigInt
local function bigint_fromnumber( object, number )
    if number < 0 then
        number = -number
        object[ 0 ] = -1
    elseif number > 0 then
        object[ 0 ] = 1
    end

    local index = 0
    while number > 0 do
        index = index + 1
        object[ index ] = number % 256
        number = math_floor( number * 0.00390625 )
    end

    return object
end

BigInt.fromNumber = bigint_fromnumber

--- TODO
---@param value integer
---@return BigInt
function BigIntClass.fromNumber( value )
    return bigint_fromnumber( bigint_new(), value )
end

local bigint_fromstring
do

    local string_len = string.len

    do

        local string_reverse = string.reverse


        -- TODO: rewrite to 2 functions
        function BigIntClass.fromBytes( binary, little_endian )
            local object = { [ 0 ] = 1, string_byte( little_endian and binary or string_reverse( binary ), 1, string_len( binary ) ) }
            setmetatable( object, BigInt )
            bigint_rstrip( object )
            return object
        end

    end


    local tonumber = std.tonumber

    --- TODO
    ---@param object BigInt
    ---@param str string
    ---@param base? integer
    ---@return BigInt
    function bigint_fromstring( object, str, base )
        local digits_start, digits_end = 1, string_len( str )

        if string_byte( str, digits_start ) == 0x2d then -- "-"
            digits_start = digits_start + 1
            object[ 0 ] = -1
        else
            object[ 0 ] = 1
        end

        if string_byte( str, digits_start ) == 0x30 then -- "0"
            digits_start = digits_start + 1

            local prefix = string_byte( str, digits_start )
            if ( base == nil or base == 16 ) and prefix == 0x78 then      -- "x"
                base = 16
                digits_start = digits_start + 1
            elseif ( base == nil or base == 2 ) and prefix == 0x62 then   -- "b"
                base = 2
                digits_start = digits_start + 1
            end
        end

        while string_byte( str, digits_start ) == 0x30 do -- "0"
            digits_start = digits_start + 1
        end

        if digits_start > digits_end then
            object[ 0 ] = 0
            return object
        end

        base = math_clamp( base or 10, 2, 36 )
        if base == 2 or base == 16 then
            -- fast bin/hex parser
            local width = base == 16 and 2 or 8

            local i = 1
            for j = digits_end, digits_start, -width do
                if j - width + 1 <= digits_start then
                    object[ i ] = tonumber( string_sub( str, digits_start, j ), base )
                else
                    object[ i ] = tonumber( string_sub( str, j - width + 1, j ), base )
                end

                i = i + 1
            end

            return object
        end

        -- general parser
        local j, carry = 1, 0
        for i = digits_start, digits_end, 1 do
            -- multiply by base
            j, carry = 1, 0
            while object[ j ] ~= nil or carry ~= 0 do
                local product = ( object[ j ] or 0 ) * base + carry
                object[ j ] = product % 256
                carry = math_floor( product * 0.00390625 )
                j = j + 1
            end

            -- add digit
            j, carry = 1, tonumber( string_sub( str, i, i ), base )
            while carry ~= 0 do
                local sum = ( object[ j ] or 0 ) + carry
                object[ j ] = sum % 256
                carry = math_floor( sum * 0.00390625 )
                j = j + 1
            end
        end

        return object
    end

    BigInt.fromString = bigint_fromstring

    --- TODO
    ---@param value string
    ---@param base? integer
    ---@return BigInt
    function BigIntClass.fromString( value, base )
        return bigint_fromstring( bigint_new(), value, base )
    end

end

local bigint_maxnumber

-- determine the max accurate integer supported by this build of Lua
if 0x1000000 == 0x1000001 then
    -- max integer that can be accurately represented by a float
    bigint_maxnumber = bigint_fromstring( bigint_new(), "0xffffff" )
else
    -- double
    bigint_maxnumber = bigint_fromstring( bigint_new(), "0x1FFFFFFFFFFFFF" )
end

BigIntClass.MaxNumber = bigint_maxnumber

--- TODO
---@param object BigInt
---@return integer
local function bigint_tonumber( object )
    if bigint_compare_unsigned( object, bigint_maxnumber ) == 1 then
        std.error( "big integer is too big to be converted to lua number", 2 )
    end

    local result = 0
    for i = #object, 1, -1 do
        result = ( result * 256 ) + object[ i ]
    end

    return result * object[ 0 ]
end

BigInt.tonumber = bigint_tonumber

--- parse integer from an byte array
---@param object BigInt
---@param bytes integer[] an array of bytes
---@param little_endian? boolean
---@return BigInt
local function bigint_from_bytes( object, bytes, little_endian )
    object[ 0 ] = 1

    for index, value in ipairs( little_endian and bytes or table_reverse( bytes ) ) do
        object[ index ] = value
    end

    bigint_rstrip( object )
    return object
end

--- TODO
---@param array integer[]
---@param little_endian? boolean
---@return BigInt
function BigIntClass.fromArray( array, little_endian )
    local object

    if little_endian then
        object = {}
        for index, value in ipairs( array ) do
            object[ index ] = value
        end
    else
        object = table_reverse( array )
    end

    object[ 0 ] = 1

    setmetatable( object, BigInt )
    bigint_rstrip( object )

    return object
end

do

    --- TODO
    ---@param object BigInt
    ---@return boolean
    local function bigint_is_even( object )
        return object[ 0 ] == 0 or object[ 1 ] % 2 == 0
    end

    BigInt.isEven = bigint_is_even

    --- TODO
    ---@param object BigInt
    ---@return boolean
    function BigInt:isOdd( object )
        return not bigint_is_even( object )
    end

end

--- TODO
---@return boolean
function BigInt:isZero()
    return self[ 0 ] == 0
end

--- TODO
---@return boolean
local function bigint_is_one( object )
    return object[ 2 ] == nil and object[ 1 ] == 1
end

BigInt.isOne = bigint_is_one

--- TODO
---@param object BigInt
---@return BigInt
local function bigint_unm( object )
    local sign = object[ 0 ]
    if sign ~= 0 then
        object[ 0 ] = -object[ 0 ]
    end

    return object
end

BigInt.unm = bigint_unm

--- TODO
---@return BigInt
function BigInt:__unm()
    return bigint_unm( bigint_copy( self ) )
end

--- TODO
---@param object BigInt
---@return BigInt
local function bigint_abs( object )
    if object[ 0 ] < 0 then
        object[ 0 ] = 1
    end

    return object
end

BigInt.abs = bigint_abs

local bigint_bit_lshift
do

    local bigint_bit_rshift

    --- TODO
    ---@param object BigInt
    ---@param shift integer
    ---@return BigInt
    function bigint_bit_lshift( object, shift )
        if object[ 0 ] == 0 or shift == 0 then
            return object
        elseif shift < 0 then
            return bigint_bit_rshift( object, -shift )
        end

        -- shift whole bytes
        local shift_bytes, byte_count = math_floor( shift * 0.125 ), #object

        for i = byte_count + 1, byte_count + shift_bytes, 1 do
            object[ i ] = 0
        end

        for i = byte_count + shift_bytes, shift_bytes + 1, -1 do
            object[ i ] = object[ i - shift_bytes ]
        end

        for i = shift_bytes, 1, -1 do
            object[ i ] = 0
        end

        byte_count = byte_count + shift_bytes

        -- shift bits
        local shift_bits = shift % 8
        if shift_bits == 0 then
            return object
        end

        local shift_size, unshift_size = 2 ^ shift_bits, 2 ^ ( 8 - shift_bits )

        for i = byte_count, shift_bytes + 1, -1 do
            local overflow = math_floor( object[ i ] / unshift_size )
            object[ i ] = ( object[ i ] * shift_size ) % 256

            if overflow ~= 0 then
                object[ i + 1 ] = ( object[ i + 1 ] or 0 ) + overflow
            end
        end

        return object
    end

    BigInt.lshift = bigint_bit_lshift

    --- TODO
    ---@param object BigInt
    ---@param shift integer
    ---@return BigInt
    function bit.lshift( object, shift )
        return bigint_bit_lshift( bigint_copy( object ), shift )
    end

    --- TODO
    ---@param object BigInt
    ---@param shift integer
    ---@return BigInt
    function bigint_bit_rshift( object, shift )
        if object[ 0 ] == 0 or shift == 0 then
            return object
        elseif shift < 0 then
            return bigint_bit_lshift( object, -shift )
        end

        -- shift whole bytes
        local shift_bytes, byte_count = math_floor( shift / 8 ), #object
        if shift_bytes >= byte_count then
            bigint_zero( object )
            return object
        end

        for i = shift_bytes + 1, byte_count, 1 do
            object[ i - shift_bytes ] = object[ i ]
        end

        for i = byte_count - shift_bytes + 1, byte_count, 1 do
            object[ i ] = nil
        end

        byte_count = byte_count - shift_bytes

        -- shift bits
        local shift_bits = shift % 8
        if shift_bits == 0 then
            return object
        end

        local shift_size, unshift_size = 2 ^ shift_bits, 2 ^ ( 8 - shift_bits )

        for i = 1, byte_count, 1 do
            local overflow = object[ i ] % shift_size
            object[ i ] = math_floor( object[ i ] / shift_size )

            if i ~= 1 then
                object[ i - 1 ] = object[ i - 1 ] + overflow * unshift_size
            end
        end

        -- strip zero
        if object[ byte_count ] == 0 then
            object[ byte_count ] = nil

            if byte_count == 1 then
                object[ 0 ] = 0
            end
        end

        return object
    end

    BigInt.rshift = bigint_bit_rshift

    --- TODO
    ---@param object BigInt
    ---@param shift integer
    ---@return BigInt
    function bit.rshift( object, shift )
        return bigint_bit_rshift( bigint_copy( object ), shift )
    end

end

do

    --- TODO
    ---@param object BigInt
    ---@param value BigInt
    ---@return BigInt
    local function bigint_bor( object, value )
        local other = bigint_ensureBigInt( value )

        if other[ 0 ] == 0 then
            return object
        elseif object[ 0 ] == 0 then
            return bigint_abs( other )
        elseif bigint_compare_unsigned( object, other ) == 0 then
            return object
        end

        for i = 1, math_max( #object, #other ), 1 do
            local bit_number = 1
            local result = 0

            local byte_value1 = object[ i ]
            local byte_value1_copy = byte_value1

            if byte_value1 == nil then
                byte_value1 = 0
            end

            local byte_value2 = other[ i ] or 0

            for _ = 1, 8, 1 do
                if ( byte_value1 % 2 ) >= 1 or ( byte_value2 % 2 ) >= 1 then
                    result = result + bit_number
                end

                byte_value1, byte_value2 = byte_value1 * 0.5, byte_value2 * 0.5
                bit_number = bit_number * 2
            end

            if result ~= byte_value1_copy then
                object[ i ] = result
            end
        end

        return object
    end

    BigInt.bor = bigint_bor

    --- TODO
    ---@param object BigInt
    ---@param value BigInt
    ---@return BigInt
    function bit.bor( object, value )
        return bigint_bor( bigint_copy( object ), value )
    end

end

do

    --- TODO
    ---@param object BigInt
    ---@param value BigInt
    ---@return BigInt
    local function bigint_band( object, value )
        local other = bigint_ensureBigInt( value )

        if object[ 0 ] == 0 then
            return object
        elseif other[ 0 ] == 0 then
            return bigint_abs( other )
        elseif bigint_compare_unsigned( object, other ) == 0 then
            return object
        end

        local changed = false

        for i = 1, math_max( #object, #other ), 1 do
            local bit_number = 1
            local result = 0

            local byte_value1 = object[ i ] or 0
            local byte_value2 = other[ i ] or 0
            local byte_value1_copy = byte_value1

            for _ = 1, 8, 1 do
                if ( byte_value1 % 2 ) >= 1 and ( byte_value2 % 2 ) >= 1 then
                    result = result + bit_number
                end

                byte_value1, byte_value2 = byte_value1 * 0.5, byte_value2 * 0.5
                bit_number = bit_number * 2
            end

            if result ~= byte_value1_copy then
                object[ i ] = result
                changed = true
            end
        end

        if changed then
            bigint_rstrip( object )
        end

        return object
    end

    BigInt.band = bigint_band

    --- TODO
    ---@param object BigInt
    ---@param value BigInt
    ---@return BigInt
    function bit.band( object, value )
        return bigint_band( bigint_copy( object ), value )
    end

end

do

    --- TODO
    ---@param object BigInt
    ---@param value BigInt
    ---@return BigInt
    local function bigint_bxor( object, value )
        local other = bigint_ensureBigInt( value )

        if other[ 0 ] == 0 then
            return object
        elseif object[ 0 ] == 0 then
            bigint_abs( other )
            return other
        elseif bigint_compare_unsigned( object, other ) == 0 then
            bigint_zero( object )
            return object
        end

        for i = 1, math_max( #object, #other ), 1 do
            local byte_value1, byte_value2 = object[ i ] or 0, other[ i ] or 0
            local bit_number = 1
            local result = 0

            for _ = 1, 8, 1 do
                if ( ( byte_value1 % 2 ) >= 1 ) ~= ( ( byte_value2 % 2 ) >= 1 ) then
                    result = result + bit_number
                end

                byte_value1, byte_value2 = byte_value1 * 0.5, byte_value2 * 0.5
                bit_number = bit_number * 2
            end

            object[ i ] = result
        end

        bigint_rstrip( object )
        return object
    end

    BigInt.bxor = bigint_bxor

    function bit.bxor( object, value )
        return bigint_bxor( bigint_copy( object ), value )
    end

end

local bigint_bnot
do

    --- TODO
    ---@param object BigInt
    ---@param value integer
    ---@return BigInt
    function bigint_bnot( object, value )
        if object[ 0 ] == 0 then
            object[ 0 ], object[ 1 ] = 1, 0xff
            return object
        end

        local byte_count = #object

        for i = 1, byte_count, 1 do
            local bit_number = 1
            local result = 0

            local byte_value = object[ i ]
            for _ = 1, 8, 1 do
                if ( byte_value % 2 ) < 1 then
                    result = result + bit_number
                end

                byte_value = byte_value * 0.5
                bit_number = bit_number * 2
            end

            object[ i ] = result
        end

        for i = byte_count + 1, math_max( value or byte_count, 1 ), 1 do
            object[ i ] = 0xff
        end

        bigint_rstrip( object )
        return object
    end

    BigInt.bnot = bigint_bnot

    --- TODO
    ---@param object BigInt
    ---@param size integer
    ---@return BigInt
    function bit.bnot( object, size )
        return bigint_bnot( bigint_copy( object ), size )
    end

end

--- TODO
---@param index integer
---@return boolean | nil
function BigInt:getBit( index )
    index = math_max( index, 1 )
    if index < 1 then
        return nil
    elseif self[ 0 ] == 0 then
        return false
    end

    index = index - 1

    local byte_value = self[ math_floor( index / 8 ) + 1 ]
    if byte_value == nil or byte_value == 0 then
        return false
    else
        return math_floor( byte_value / ( 2 ^ ( index % 8 ) ) ) % 2 == 1
    end
end

do

    local select = std.select

    --- TODO
    ---@vararg integer
    ---@return BigInt
    function BigInt:setBits( ... )
        local arg_count = select( "#", ... )
        if arg_count == 0 then return self end

        local args = { ... }
        local changed = false
        local byte_count = #self

        for i = 1, arg_count, 1 do
            local selected_bit = math_max( args[ i ], 1 ) - 1

            local byte_number = math_floor( selected_bit / 8 ) + 1
            if byte_number > byte_count then
                for j = byte_count + 1, byte_number, 1 do
                    self[ j ] = 0
                end

                changed = true
                byte_count = byte_number
            end

            local bit_number = 2 ^ ( selected_bit % 8 )
            local byte_value = self[ byte_number ]

            if ( byte_value / bit_number ) % 2 < 1 then
                self[ byte_number ] = byte_value + bit_number
            end
        end

        if changed and self[ 0 ] == 0 then
            self[ 0 ] = 1
        end

        return self
    end

    --- TODO
    ---@vararg integer
    ---@return BigInt
    function BigInt:unsetBits( ... )
        if self[ 0 ] == 0 then return self end

        local arg_count = select( "#", ... )
        if arg_count == 0 then return self end

        local changed = false
        local args = { ... }

        for i = 1, arg_count, 1 do
            local selected_bit = math_max( args[ i ], 1 ) - 1
            local byte_number = math_floor( selected_bit / 8 ) + 1

            local byte_value = self[ byte_number ]
            if byte_value ~= nil then
                local bit_number = 2 ^ ( selected_bit % 8 )
                if ( byte_value / bit_number ) % 2 >= 1 then
                    self[ byte_number ] = byte_value - bit_number
                    changed = true
                end
            end
        end

        if changed then
            bigint_rstrip( self )
        end

        return self
    end

end

--- TODO
---@param object BigInt
---@param value BigInt
---@return BigInt
local function bigint_add( object, value )
    local other = bigint_ensureBigInt( value )

    -- addition of 0
    if other[ 0 ] == 0 then
        return object
    elseif object[ 0 ] == 0 then
        return other
    end

    -- determine sign, operation, and order of operands
    local subtract, swap_order, change_sign = false, false,false

    if object[ 0 ] == other[ 0 ] then
        if #object < #other then
            swap_order = true
        end
    else
        local compare_result = bigint_compare_unsigned( object, other )
        if compare_result == 0 then
            bigint_zero( object )
            return object
        elseif compare_result == -1 then
            swap_order, change_sign = true, true
        end

        subtract = true
    end

    -- perform operation
    local b1, b2

    if swap_order then
        b1, b2 = other, object
    else
        b1, b2 = object, other
    end

    local byte_count1, byte_count2 = #b1, #b2
    local carry = 0

    for i = 1, byte_count1, 1 do
        local total

        if subtract then
            total = ( b1[ i ] or 0 ) - ( b2[ i ] or 0 ) + carry
        else
            total = ( b1[ i ] or 0 ) + ( b2[ i ] or 0 ) + carry
        end

        if not subtract and total >= 256 then
            object[ i ], carry = total - 256, 1
        elseif subtract and total < 0 then
            object[ i ], carry = total + 256, -1
        else
            object[ i ], carry = total, 0
        end

        -- end loop as soon as possible
        if i >= byte_count2 and carry == 0 then
            if swap_order then
                -- just need to copy remaining bytes
                for j = i + 1, byte_count1, 1 do
                    object[ j ] = b1[ j ]
                end
            end

            break
        end
    end

    if carry > 0 then
        object[ byte_count1 + 1 ] = carry
    end

    if subtract then
        bigint_rstrip( object )
    end

    if change_sign then
        object[ 0 ] = -object[ 0 ]
    end

    return object
end

BigInt.add = bigint_add

--- TODO
---@param value BigInt
---@return BigInt
function BigInt:__add( value )
    return bigint_add( bigint_copy( self ), value )
end

--- TODO
---@param object BigInt
---@param value BigInt
---@return BigInt
local function bigint_sub( object, value )
    return bigint_add( object, bigint_unm( bigint_ensureBigInt( value ) ) )
end

BigInt.sub = bigint_sub

--- TODO
---@param value BigInt
---@return BigInt
function BigInt:__sub( value )
    return bigint_sub( bigint_copy( self ), value )
end

--- TODO
---@param object BigInt
---@param value BigInt
---@return BigInt
local function bigint_mul( object, value )
    local other = bigint_ensureBigInt( value )

    -- multiplication by 0
    if object[ 0 ] == 0 then
        return object
    elseif other[ 0 ] == 0 then
        object[ 0 ] = 0

        for i = 1, #object, 1 do
            object[ i ] = nil
        end

        return object
    end

    -- multiplication by 1
    if bigint_is_one( object ) then
        if object[ 0 ] == -1 then
            bigint_unm( other )
        end

        return other
    end

    if bigint_is_one( other ) then
        if other[ 0 ] == -1 then
            bigint_unm( object )
        end

        return object
    end

    -- general multiplication
    local b1, b2 = object, other
    local byte_count1, byte_count2 = #b1, #b2

    if byte_count2 > byte_count1 then
        -- swap order so that number with more b1 comes first
        b1, b2, byte_count1, byte_count2 = other, object, byte_count2, byte_count1
    end

    local result = {}
    local carry = 0

    for i = 1, byte_count2, 1 do
        if b2[ i ] == 0 then
            if result[ i ] == nil then
                result[ i ] = 0
            end
        else

            -- multiply each byte
            local j = 1
            while j <= byte_count1 do
                local ri = i + j - 1
                local product = b1[ j ] * b2[ i ] + carry + ( result[ ri ] or 0 )

                -- add product to result
                result[ ri ] = product % 256
                carry = math_floor( product * 0.00390625 )
                j = j + 1
            end

            -- finish adding carry
            while carry ~= 0 do
                local ri = i + j - 1
                local sum = ( result[ ri ] or 0 ) + carry

                result[ ri ] = sum % 256
                carry = math_floor( sum * 0.00390625 )
                j = j + 1
            end

        end
    end

    object[ 0 ] = object[ 0 ] * other[ 0 ]

    for i = 1, #result, 1 do
        object[ i ] = result[ i ]
    end

    return object
end

BigInt.mul = bigint_mul

--- TODO
---@param value BigInt
---@return BigInt
function BigInt:__mul( value )
    return bigint_mul( bigint_copy( self ), value )
end

do

    --- TODO
    ---@param object BigInt
    ---@param value BigInt
    ---@param ignore_remainder? boolean
    ---@return BigInt
    ---@return BigInt
    local function bigint_full_div( object, value, ignore_remainder )
        local other = bigint_ensureBigInt( value )

        -- division of/by 0
        if object[ 0 ] == 0 then
            return object, object
        elseif other[ 0 ] == 0 then
            return other, other
        end

        -- division by 1
        if bigint_is_one( other ) then
            if other[ 0 ] == -1 then
                bigint_unm( object )
            end

            return object, bigint_new()
        end

        -- division by bigger number or object
        local compare_result = bigint_compare_unsigned( object, other )
        if compare_result == -1 then
            if object[ 0 ] == other[ 0 ] then
                return bigint_new(), object
            elseif ignore_remainder then
                return bigint_new(), object
            end

            return bigint_new(), bigint_add( object, other )
        elseif compare_result == 0 then
            if object[ 0 ] == other[ 0 ] then
                return setmetatable( { [ 0 ] = 1, 1 }, BigInt ), bigint_new()
            end

            return setmetatable( { [ 0 ] = -1, 1 }, BigInt ), bigint_new()
        end

        -- general division
        local b1, b2 = object:copy(), other:copy()
        local byte_count1, byte_count2 = #b1, #b2

        local result = {}
        local ri = 1

        local di = byte_count1 - byte_count2 + 1
        while di >= 1 do
            local factor = 0
            repeat

                -- check if divisor is smaller
                local found_factor = false

                local size = byte_count2
                if di + size <= byte_count1 and b1[ di + size ] ~= 0 then
                    size = size + 1
                end

                for i = size, 1, -1 do
                    local byte_value1 = b1[ di + i - 1 ] or 0
                    local byte_value2 = b2[ i ] or 0
                    if byte_value2 < byte_value1 then
                        found_factor = false
                        break
                    elseif byte_value2 > byte_value1 then
                        found_factor = true
                        break
                    end
                end

                -- subtract divisor
                if not found_factor then
                    factor = factor + 1
                    local carry = 0
                    local i = 1

                    while i <= size or carry ~= 0 do
                        local j = di + i - 1
                        local diff = ( b1[ j ] or 0 ) - ( b2[ i ] or 0 ) + carry
                        if diff < 0 then
                            carry = -1
                            diff = diff + 256
                        else
                            carry = 0
                        end

                        b1[ j ] = diff
                        i = i + 1
                    end
                end
            until found_factor

            -- set digit
            result[ ri ] = factor
            ri = ri + 1

            di = di - 1
        end

        local sign1, sign2 = b1[ 0 ], b2[ 0 ]
        bigint_rstrip( b1 )

        -- if remainder is negative, add divisor to make it positive
        if not ignore_remainder and sign1 == -sign2 and b1[ 0 ] ~= 0 then
            bigint_add( b1, b2 )
        end

        b2[ 0 ] = sign1 * sign2

        local reversed_result = table_reverse( result )

        for i = 1, #reversed_result, 1 do
            b2[ i ] = reversed_result[ i ]
        end

        bigint_rstrip( b2 )

        if b1[ 0 ] ~= 0 and sign2 == -1 then
            b1[ 0 ] = -1
        end

        return b2, b1
    end

    --- TODO
    ---@param object BigInt
    ---@param value BigInt
    ---@return BigInt
    local function bigint_div( object, value )
        local quotient, _ = bigint_full_div( object, value, true )
        return quotient
    end

    BigInt.div = bigint_div

    --- TODO
    ---@param value BigInt
    ---@return BigInt
    function BigInt:__div( value )
        return bigint_div( bigint_copy( self ), value )
    end

    --- TODO
    ---@param object BigInt
    ---@param value BigInt
    ---@return BigInt
    local function bigint_mod( object, value )
        local _, remainder = bigint_full_div( object, value, false )
        return remainder
    end

    BigInt.mod = bigint_mod

    --- TODO
    ---@param value BigInt
    ---@return BigInt
    function BigInt:__mod( value )
        return bigint_mod( bigint_copy( self ), value )
    end

end

do

    --- calculate log2 by finding highest 1 bit
    ---@return BigInt | nil
    function BigInt:log2()
        if self[ 0 ] == 0 then return nil end

        local byte_count = #self
        local byte_number = ( byte_count - 1 ) * 8

        local byte = self[ byte_count ]

        while byte >= 1 do
            byte_number = byte_number + 1
            byte = byte * 0.5
        end

        return bigint_fromnumber( bigint_new(), byte_number - 1 )
    end

end

do

    --- return log2 if it's an integer, else nil
    ---@return integer | nil
    local function bigint_log2( object )
        if object[ 0 ] == 0 then return nil end

        local index, power = 1, 0
        local failed = false

        while object[ index ] ~= nil do
            local byte_value = object[ index ]
            for _ = 1, 8, 1 do
                if byte_value % 2 == 0 then
                    if not failed then
                        power = power + 1
                    end
                elseif failed then
                    return nil
                else
                    failed = true
                end

                byte_value = byte_value * 0.5
            end

            index = index + 1
        end

        return power
    end

    --- TODO
    ---@param object BigInt
    ---@param value BigInt
    ---@return BigInt
    local function bigint_pow( object, value )
        local other = bigint_ensureBigInt( value )

        if other[ 0 ] == 0 then
            return setmetatable( { [ 0 ] = 1, 1 }, BigInt )
        elseif other[ 0 ] == -1 then
            bigint_zero( object )
            return object
        elseif bigint_is_one( other ) then
            return object
        end

        local sign = object[ 0 ]
        if sign == -1 and other[ 1 ] % 2 == 0 then
            sign = 1
        end

        -- fast exponent if self is a power of 2
        local power = bigint_log2( object )
        if power ~= nil then
            -- assumes other isn't so big that precision becomes an issue
            local object_copy = bigint_copy( object )
            bigint_bit_lshift( object_copy, ( bigint_tonumber( object_copy ) - 1 ) * power )
            object_copy.sign = sign
            return object_copy
        end

        -- multiply by self repeatedly
        local other_copy = bigint_copy( other )

        bigint_abs( other_copy )
        bigint_add( other_copy, bigint_negaive_one )

        local object_copy = bigint_copy( object )

        while other_copy[ 0 ] ~= 0 do
            bigint_mul( object_copy, object )
            bigint_add( other_copy, bigint_negaive_one )
        end

        object_copy[ 0 ] = sign
        return object_copy
    end

    BigInt.pow = bigint_pow

    --- TODO
    ---@param value BigInt
    ---@return BigInt
    function BigInt:__pow( value )
        return bigint_pow( bigint_copy( self ), value )
    end

end

--- convert 2's complement unsigned number to signed
---@param byte_amt integer
---@return BigInt
function BigInt:toSigned( byte_amt )
    local byte_count = #self

    local size = math_max( byte_amt or byte_count, 1 )
    if byte_count > size then
        std.error( "twos complement overflow", 2 )
    end

    if self[ 0 ] == 1 and ( self[ size ] or 0 ) > 0x7f then
        bigint_bnot( self, size )
        bigint_add( self, bigint_one )
        self[ 0 ] = -1
    end

    return self
end

--- convert 2's complement signed number to unsigned
---@param byte_amt integer
---@return BigInt
function BigInt:toUnsigned( byte_amt )
    local byte_count = #self

    local size = math_max( byte_amt or byte_count, 1 )
    if byte_count > size then
        std.error( "twos complement overflow", 2 )
    end

    if self[ 0 ] == -1 then
        self[ 0 ] = 1
        bigint_bnot( self, size )
        bigint_add( self, bigint_one )
    end

    return self
end

do

    --- TODO
    ---@param a BigInt
    ---@param value BigInt
    ---@return integer
    local function compare( a, value )
        local b = bigint_ensureBigInt( value )

        if a[ 0 ] > b[ 0 ] then
            return 1
        elseif a[ 0 ] < b[ 0 ] then
            return -1
        end

        local compare_result = bigint_compare_unsigned( a, b )
        if compare_result == 0 then
            return 0
        elseif a[ 0 ] == 1 then
            return compare_result
        elseif a[ 0 ] == -1 then
            return -compare_result
        else
            return 0
        end
    end

    function BigInt:eq( other )
        return compare( self, other ) == 0
    end

    function BigInt:ne( other )
        return compare( self, other ) ~= 0
    end

    function BigInt:lt( other )
        return compare( self, other ) == -1
    end

    function BigInt:le( other )
        return compare( self, other ) <= 0
    end

    function BigInt:gt( other )
        return compare( self, other ) == 1
    end

    function BigInt:ge( other )
        return compare( self, other ) >= 0
    end

    BigInt.__eq = BigInt.eq
    BigInt.__lt = BigInt.lt
    BigInt.__le = BigInt.le

end

-- convert to string of bytes
function BigInt:toBinary( size, little_endian )
    -- avoid copying array
    local byte_count = #self

    size = math_max( size or byte_count, 1 )
    if byte_count < size then
        for i = byte_count + 1, size, 1 do
            self[ i ] = 0
        end
    end

    local byteStr
    if little_endian then
        byteStr = string_char( table_unpack( self, 1, size ) )
    elseif byte_count <= size then
        byteStr = string_char( table_unpack( table_reverse( self ), 1 ) )
    else
        byteStr = string_char( table_unpack( table_reverse( self ), byte_count - size + 1, byte_count ) )
    end

    -- restore original state
    for i = size, byte_count + 1, -1 do
        self[ i ] = nil
    end

    return byteStr
end






---@param self BigInt
---@param value string | integer | BigInt | integer[]
---@param base integer | nil
---@return gpm.std.BigInt
function bigint_constructor( self, value, base )
    if isstring( value ) then
        ---@cast value string
        return bigint_fromstring( self, value, base )
    end

    if isnumber( value ) then
        ---@cast value number
        return bigint_fromnumber( self, value )
    end

    if getmetatable( value ) == BigInt then
        ---@cast value gpm.std.BigInt
        return value
    end

    if istable( value ) then
        ---@cast value integer[]
        return bigint_from_bytes( self, value, true )
    end

    error( "cannot construct bigint from type: " .. std.type( value ) )
end

---@protected
function BigInt:__init( value, base )
    self[ 0 ] = 0
    bigint_constructor( self, value, base )
end

-- fast hex base conversion
function BigInt:ToHex( no_prefix )
    if self[ 0 ] == 0 then
        if no_prefix then
            return "0"
        end

        return "0x0"
    end

    local bytes = table_reverse( self )
    local byte_count = #bytes

    local result = string_format( "%x" .. string_rep( "%02x", byte_count - 1 ), table_unpack( bytes, 1, byte_count ) )
    if not no_prefix then
        result = "0x" .. result
    end

    if self[ 0 ] == -1 then
        result = "-" .. result
    end

    return result
end

-- fast bin base conversion
function BigInt:ToBin( no_prefix )
    if self[ 0 ] == 0 then
        if no_prefix then
            return "0"
        end

        return "0b0"
    end

    local t = {}
    local bytesCount = #self

    for i = 1, bytesCount, 1 do
        local byte = self[ i ]
        local start = ( i - 1 ) * 8 + 1
        for j = start, start + 7, 1 do
            if byte == 0 then
                if i == bytesCount then
                    break
                end

                t[ j ] = 0
            else
                t[ j ] = byte % 2
                byte = math_floor( byte / 2 )
            end
        end
    end

    local result = table_concat( table_reverse( t ) )
    if not no_prefix then
        result = "0b" .. result
    end

    if self[ 0 ] == -1 then
        result = "-" .. result
    end

    return result
end

-- general base conversion
function BigInt:ToBase( base )
    base = math_clamp( base, 1, 36 )

    if base == 2 then
        return self:ToBin( true )
    elseif base == 16 then
        return self:ToHex( true )
    end

    if self[ 0 ] == 0 then
        return "0"
    end

    local result = {}

    local j, carry = 1, 0
    for i = #self, 1, -1 do
        -- multiply by 256
        j, carry = 1, 0
        while result[ j ] ~= nil or carry ~= 0 do
            local product = ( result[ j ] or 0 ) * 256 + carry
            result[ j ] = product % base
            j, carry = j + 1, math_floor( product / base )
        end

        -- add byte
        j, carry = 1, self[ i ]
        while carry ~= 0 do
            local sum = ( result[ j ] or 0 ) + carry
            result[ j ] = sum % base
            j, carry = j + 1, math_floor( sum / base )
        end
    end

    result = table_reverse( result )

    for i = #result, 1, -1 do
        result[ i ] = bigint_digits[ result[ i ] + 1 ]
    end

    local str = table_concat( result )
    if self[ 0 ] == -1 then
        str = "-" .. str
    end

    return str
end

function BigInt:toDecimal()
    return self:ToBase( 10 )
end


-- BigInt.__idiv = ensureSelfIsBigInt( BigInt.Div )
BigInt.__tostring = BigInt.toDecimal

function bigint_ensureBigInt( obj )
    if getmetatable( obj ) == BigInt then
        return obj
    end

    return bigint_constructor( bigint_new(), obj )
end

return BigIntClass
