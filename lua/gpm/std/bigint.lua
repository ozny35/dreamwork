--[[
    Lua 5.1 Bigint by soupstream
    https://github.com/soupstream/lua-5.1-bigint
    Re-writed by Unknown Developer
]]

local _G = _G

---@class gpm.std
local std = _G.gpm.std

local math = std.math
local table = std.table
local string = std.string

local select = std.select
local setmetatable = std.setmetatable
local table_reversed, table_unpack = table.reversed, table.unpack
local math_floor, math_max, math_clamp = math.floor, math.max, math.clamp


--- [SHARED AND MENU]
---
--- The big integer object.
---@alias BigInt gpm.std.BigInt
---@class gpm.std.BigInt: gpm.std.Object
---@field __class gpm.std.BigIntClass
---@operator add(any): gpm.std.BigInt
---@operator sub(any): gpm.std.BigInt
---@operator mul(any): gpm.std.BigInt
---@operator div(any): gpm.std.BigInt
---@operator mod(any): gpm.std.BigInt
---@operator pow(any): gpm.std.BigInt
---@field sign integer `-1` if negative, `0` if zero, `1` if positive.
---@field size integer The number of bytes that make up the big integer.
local BigInt = std.class.base( "BigInt" )

--- [SHARED AND MENU]
---
--- The big integer sign.
---@alias gpm.std.BigInt.Sign
---| integer
---| `-1`
---| `0`
---| `1`

---@return integer
---@protected
function BigInt:__bitcount()
    return #self * 8
end

---@return boolean
---@protected
function BigInt:__tobool()
    return self[ 0 ] ~= 0
end

--- [SHARED AND MENU]
---
--- The big integer class.
---@class gpm.std.BigIntClass: gpm.std.BigInt
---@overload fun( value: string | number, base: number? ): gpm.std.BigInt
local BigIntClass = std.class.create( BigInt )
std.BigInt = BigIntClass

---@class gpm.std.BigInt.bit
local bit = {}
BigIntClass.bit = bit

--- [SHARED AND MENU]
---
--- Makes a copy of the big integer.
---@param object gpm.std.BigInt
---@return gpm.std.BigInt
local function copy( object )
    local length = #object
    if length < 5 then
        return setmetatable( {
            [ 0 ] = object[ 0 ],
            object[ 1 ], object[ 2 ], object[ 3 ], object[ 4 ]
        }, BigInt )
    elseif length < 9 then
        return setmetatable( {
            [ 0 ] = object[ 0 ],
            object[ 1 ], object[ 2 ], object[ 3 ], object[ 4 ],
            object[ 5 ], object[ 6 ], object[ 7 ], object[ 8 ]
        }, BigInt )
    elseif length < 17 then
        return setmetatable( {
            [ 0 ] = object[ 0 ],
            object[ 1 ], object[ 2 ], object[ 3 ], object[ 4 ],
            object[ 5 ], object[ 6 ], object[ 7 ], object[ 8 ],
            object[ 9 ], object[ 10 ], object[ 11 ], object[ 12 ],
            object[ 13 ], object[ 14 ], object[ 15 ], object[ 16 ]
        }, BigInt )

    elseif length < 33 then
        return setmetatable( {
            [ 0 ] = object[ 0 ],
            object[ 1 ], object[ 2 ], object[ 3 ], object[ 4 ],
            object[ 5 ], object[ 6 ], object[ 7 ], object[ 8 ],
            object[ 9 ], object[ 10 ], object[ 11 ], object[ 12 ],
            object[ 13 ], object[ 14 ], object[ 15 ], object[ 16 ],
            object[ 17 ], object[ 18 ], object[ 19 ], object[ 20 ],
            object[ 21 ], object[ 22 ], object[ 23 ], object[ 24 ],
            object[ 25 ], object[ 26 ], object[ 27 ], object[ 28 ],
            object[ 29 ], object[ 30 ], object[ 31 ], object[ 32 ]
        }, BigInt )
    else
        return setmetatable( {
            [ 0 ] = object[ 0 ],
            table_unpack( object, 1, length )
        }, BigInt )
    end
end


BigInt.copy = copy

--- [SHARED AND MENU]
---
--- Creates a new big integer object that equals zero.
---@return gpm.std.BigInt
local function new()
    return setmetatable( { [ 0 ] = 0 }, BigInt )
end

local one = setmetatable( { [ 0 ] = 1, 1 }, BigInt )
local negaive_one = setmetatable( { [ 0 ] = -1, 1 }, BigInt )

--- [SHARED AND MENU]
---
--- Sets the big integer object to zero, removing all values.
---@param object gpm.std.BigInt
---@return gpm.std.BigInt
local function zero( object )
    object[ 0 ] = 0

    for i = 1, #object, 1 do
        object[ i ] = nil
    end

    return object
end

---@protected
function BigInt:__index( key )
    if key == "sign" then
        return self[ 0 ]
    elseif key == 0 then
        return 0
    elseif key == "size" then
        return #self
    end

    return BigInt[ key ]
end

do

    local raw_set = std.raw.set

    ---@protected
    function BigInt:__newindex( key, value )
        if key == "sign" then
            local sign = math_clamp( value, -1, 1 )

            if self[ 0 ] == 0 or sign == self[ 0 ] then
                return self
            elseif sign == 0 then
                zero( self )
                return self
            elseif sign == -1 or sign == 1 then
                self[ 0 ] = sign
                return self
            end

            std.error( "invalid sign", 2 )
        end

        raw_set( self, key, value )
    end

end

local tobigint

--- [SHARED AND MENU]
---
--- Performs an unsigned comparison between two big integers.
---@param object gpm.std.BigInt
---@param value any
---@return integer
local function compare_unsigned( object, value )
    local other = tobigint( value )
    ---@cast other gpm.std.BigInt

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

--- [SHARED AND MENU]
---
--- Removes leading zeros from the big integer.
---@param object gpm.std.BigInt
local function rstrip( object )
    local i = #object
    while i ~= 0 and object[ i ] == 0 do
        object[ i ] = nil
        i = i - 1
    end

    if i == 0 then
        object[ 0 ] = 0
    end

    return object
end

BigInt.rstrip = rstrip

--- [SHARED AND MENU]
---
--- Sets a big integer object from a lua_number (must be an integer).
---@param object gpm.std.BigInt
---@param number integer
---@return gpm.std.BigInt
local function from_number( object, number )
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

BigInt.fromNumber = from_number

--- [SHARED AND MENU]
---
--- Converts a lua_number (must be an integer) to a new big integer.
---@param value integer
---@return gpm.std.BigInt
function BigIntClass.fromNumber( value )
    return from_number( new(), value )
end

local from_string
do

    local string_byte = string.byte
    local string_len = string.len

    do

        local string_reverse, string_rep = string.reverse, string.rep

        do

            local string_format = string.format
            local table_concat = table.concat

            --- [SHARED AND MENU]
            ---
            --- Converts the big integer to a hex string.
            ---@param object gpm.std.BigInt
            ---@param no_prefix? boolean
            ---@return string
            local function toHex( object, no_prefix )
                if no_prefix == nil then no_prefix = false end

                local sign = object[ 0 ]
                if sign == 0 then
                    return no_prefix and "0" or "0x0"
                end

                local byte_count = #object
                local str = string_reverse( string_format( "%x" .. string_rep( "%02x", byte_count - 1 ), table_unpack( object, 1, byte_count ) ) )

                if not no_prefix then
                    str = "0x" .. str
                end

                if sign == -1 then
                    str = "-" .. str
                end

                return str
            end

            BigInt.toHex = toHex

            --- [SHARED AND MENU]
            ---
            --- Converts the big integer to a binary [01] string.
            ---@param object gpm.std.BigInt
            ---@param no_prefix? boolean
            ---@return string
            local function toBinaryString( object, no_prefix )
                if no_prefix == nil then no_prefix = true end

                local sign = object[ 0 ]
                if sign == 0 then
                    if no_prefix then
                        return "0"
                    end

                    return "0b0"
                end

                local byte_count = #object
                local result = {}

                for i = 1, byte_count, 1 do
                    local byte_value = object[ i ]

                    local from = ( i - 1 ) * 8 + 1
                    for j = from, from + 7, 1 do
                        if byte_value == 0 then
                            -- if i == byte_count then
                            --     break
                            -- end

                            result[ j ] = 0
                        else
                            result[ j ] = byte_value % 2
                            byte_value = math_floor( byte_value * 0.5 )
                        end
                    end
                end

                local str = string_reverse( table_concat( result ) )

                if not no_prefix then
                    str = "0b" .. str
                end

                if sign == -1 then
                    str = "-" .. str
                end

                return str
            end

            BigInt.toBinaryString = toBinaryString

            local digits = {
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

            --- [SHARED AND MENU]
            ---
            --- Converts the big integer to a string in the specified (or not) base.
            ---@param object gpm.std.BigInt
            ---@param value integer
            ---@param no_prefix? boolean
            ---@return string
            local function toString( object, value, no_prefix )
                if value == nil then value = 10 end

                local base = math_clamp( value, 2, 36 )
                if base == 2 then
                    return toBinaryString( object, no_prefix )
                elseif base == 16 then
                    return toHex( object, no_prefix )
                end

                local sign = object[ 0 ]
                if sign == 0 then
                    return "0"
                end

                local result = {}

                local j, carry = 1, 0
                for i = #object, 1, -1 do
                    -- multiply by 256
                    j, carry = 1, 0
                    while result[ j ] ~= nil or carry ~= 0 do
                        local product = ( result[ j ] or 0 ) * 256 + carry
                        result[ j ] = product % base
                        j, carry = j + 1, math_floor( product / base )
                    end

                    -- add byte
                    j, carry = 1, object[ i ]
                    while carry ~= 0 do
                        local sum = ( result[ j ] or 0 ) + carry
                        result[ j ] = sum % base
                        j, carry = j + 1, math_floor( sum / base )
                    end
                end

                local length = #result
                for i = 1, length, 1 do
                    result[ i ] = digits[ result[ i ] + 1 ]
                end

                local str
                if length == 0 then
                    str = "0"
                else
                    str = string_reverse( table_concat( result, "", 1, length ) )
                end

                if sign == -1 then
                    str = "-" .. str
                end

                return str
            end

            BigInt.toString = toString
            BigInt.__tostring = toString

            -- ---@return string
            -- ---@protected
            -- function BigInt:__tostring()
            --     return string_format( "Big Integer: %p [%s][%dbit]", self, toString( self, 10, true ), #self * 8 )
            -- end

            --- [SHARED AND MENU]
            ---
            --- Converts the big integer to a decimal string.
            ---@return string
            function BigInt:toDecimal()
                return toString( self, 10 )
            end

        end

        do

            --- [SHARED AND MENU]
            ---
            --- Creates a new big integer object from an byte array and a sign.
            ---@param sign gpm.std.BigInt.Sign
            ---@param ... integer
            ---@return BigInt
            function BigIntClass.fromBytes( sign, ... )
                return setmetatable( { [ 0 ] = sign or 0, ... }, BigInt )
            end

            --- [SHARED AND MENU]
            ---
            --- Sets a big integer object from an byte array and a sign.
            ---@param object gpm.std.BigInt
            ---@param sing gpm.std.BigInt.Sign
            ---@param ... integer
            ---@return BigInt
            local function fromBytes( object, sing, ... )
                object[ 0 ] = sing

                local bytes = { ... }
                for index = 1, select( "#", ... ), 1 do
                    object[ index ] = bytes[ index ]
                end

                return object
            end

            BigInt.fromBytes = fromBytes

            --- [SHARED AND MENU]
            ---
            --- Creates a new big integer object from a binary data string.
            ---@param str string
            ---@param big_endian? boolean
            ---@return BigInt
            function BigIntClass.fromBinary( str, big_endian )
                return fromBytes( new(), 1, string_byte( big_endian and string_reverse( str ) or str, 1, string_len( str ) ) )
            end

            --- [SHARED AND MENU]
            ---
            --- Sets a big integer object from a binary data string.
            ---@param str string
            ---@param big_endian? boolean
            ---@return BigInt
            function BigInt:fromBinary( str, big_endian )
                return fromBytes( new(), 1, string_byte( big_endian and string_reverse( str ) or str, 1, string_len( str ) ) )
            end

        end

        do

            local string_char = string.char
            local math_min = math.min

            --- [SHARED AND MENU]
            ---
            --- Converts the big integer to a binary string [01].
            ---@param size? integer
            ---@param big_endian? boolean
            ---@return string
            function BigInt:toBinary( size, big_endian )
                local byte_count = #self
                if byte_count == 0 then
                    return string_rep( "\0", size or byte_count or 1 )
                elseif size == nil then
                    size = byte_count
                elseif size < 1 then
                    return ""
                end

                local sub_size = math_min( size, byte_count )

                local str = string_char( table_unpack( self, 1, sub_size ) )

                if sub_size < size then
                    str = str .. string_rep( "\0", size - sub_size )
                end

                if big_endian then
                    return string_reverse( str )
                else
                    return str
                end
            end

        end

    end

    local string_sub = string.sub
    local tonumber = std.tonumber

    --- [SHARED AND MENU]
    ---
    --- Sets a big integer object from a decimal string with an optional base.
    ---@param object gpm.std.BigInt
    ---@param str string
    ---@param base? integer
    ---@return gpm.std.BigInt
    function from_string( object, str, base )
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

    BigInt.fromString = from_string

    --- [SHARED AND MENU]
    ---
    --- Creates a big integer object from a decimal string with an optional base.
    ---@param value string
    ---@param base? integer
    ---@return gpm.std.BigInt
    function BigIntClass.fromString( value, base )
        return from_string( new(), value, base )
    end

    do

        local isstring, isnumber = std.isstring, std.isnumber
        local debug_getmetatable = std.debug.getmetatable

        --- [SHARED AND MENU]
        ---
        --- Converts a given value to a big integer object.
        ---@param value any
        ---@param base? integer
        ---@return gpm.std.BigInt
        function tobigint( value, base )
            if debug_getmetatable( value ) == BigInt then
                return value
            elseif isstring( value ) then
                return from_string( new(), value, base )
            elseif isnumber( value ) then
                return from_number( new(), value )
            end

            local number = tonumber( value, base )
            if number == nil then
                std.error( "value must be a string or number to be converted to big integer", 2 )
            end

            ---@cast number integer

            return from_number( new(), number )
        end

        ---@param value any
        ---@param base? integer
        ---@return gpm.std.BigInt
        ---@protected
        function BigInt:__new( value, base )
            return tobigint( value, base )
        end

    end

end

local toInteger
do

    local max_number

    -- determine the max accurate integer supported by this build of Lua
    if 0x1000000 == 0x1000001 then
        max_number = from_string( new(), "0xffffff" )
    else
        max_number = from_string( new(), "0x1FFFFFFFFFFFFF" )
    end

    --- [SHARED AND MENU]
    ---
    --- Converts a big integer object to a lua_number (always an integer).
    ---@param object gpm.std.BigInt
    ---@return integer
    function toInteger( object )
        if compare_unsigned( object, max_number ) == 1 then
            std.error( "big integer is too big to be converted to lua number", 2 )
        end

        local result = 0
        for i = #object, 1, -1 do
            result = ( result * 256 ) + object[ i ]
        end

        return result * object[ 0 ]
    end

    BigInt.toInteger = toInteger
    BigInt.__tonumber = toInteger

end

do

    --- [SHARED AND MENU]
    ---
    --- Checks if a big integer object is even.
    ---@param object gpm.std.BigInt
    ---@return boolean
    local function is_even( object )
        return object[ 0 ] == 0 or object[ 1 ] % 2 == 0
    end

    BigInt.isEven = is_even

    --- [SHARED AND MENU]
    ---
    --- Checks if a big integer object is odd.
    ---@return boolean
    function BigInt:isOdd()
        return not is_even( self )
    end

end

--- [SHARED AND MENU]
---
--- Checks if a big integer object is zero.
---@return boolean
function BigInt:isZero()
    return self[ 0 ] == 0
end

--- [SHARED AND MENU]
---
--- Checks if a big integer object is one.
---@return boolean
local function is_one( object )
    return object[ 2 ] == nil and object[ 1 ] == 1
end

BigInt.isOne = is_one

--- [SHARED AND MENU]
---
--- Negates a big integer object.
---@param object gpm.std.BigInt
---@return gpm.std.BigInt
local function negate( object )
    local sign = object[ 0 ]
    if sign ~= 0 then
        object[ 0 ] = -object[ 0 ]
    end

    return object
end

BigInt.negate = negate

---@return gpm.std.BigInt
---@protected
function BigInt:__unm()
    return negate( copy( self ) )
end

--- [SHARED AND MENU]
---
--- Makes a big integer object absolute (simply removes the sign).
---@param object gpm.std.BigInt
---@return gpm.std.BigInt
local function abs( object )
    if object[ 0 ] < 0 then
        object[ 0 ] = 1
    end

    return object
end

BigInt.abs = abs

local bit_lshift
do

    local bit_rshift

    --- [SHARED AND MENU]
    ---
    --- Shifts a big integer object to the left by a given number of bits (positive or negative).
    ---@param object gpm.std.BigInt
    ---@param shift integer
    ---@return gpm.std.BigInt
    function bit_lshift( object, shift )
        if object[ 0 ] == 0 or shift == 0 then
            return object
        elseif shift < 0 then
            return bit_rshift( object, -shift )
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

    BigInt.lshift = bit_lshift

    --- [SHARED AND MENU]
    ---
    --- Creates a new big integer object that is the result of shifting a given big integer object to the left by a given number of bits.
    ---@param object gpm.std.BigInt
    ---@param shift integer
    ---@return gpm.std.BigInt
    function bit.lshift( object, shift )
        return bit_lshift( copy( object ), shift )
    end

    --- [SHARED AND MENU]
    ---
    --- Shifts a big integer object to the right by a given number of bits (positive or negative).
    ---@param object gpm.std.BigInt
    ---@param shift integer
    ---@return gpm.std.BigInt
    function bit_rshift( object, shift )
        if object[ 0 ] == 0 or shift == 0 then
            return object
        elseif shift < 0 then
            return bit_lshift( object, -shift )
        end

        -- shift whole bytes
        local shift_bytes, byte_count = math_floor( shift * 0.125 ), #object
        if shift_bytes >= byte_count then
            zero( object )
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

    BigInt.rshift = bit_rshift

    --- [SHARED AND MENU]
    ---
    --- Creates a new big integer object that is the result of shifting a given big integer object to the right by a given number of bits.
    ---@param object gpm.std.BigInt
    ---@param shift integer
    ---@return gpm.std.BigInt
    function bit.rshift( object, shift )
        return bit_rshift( copy( object ), shift )
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise OR operation between two big integer objects.
    ---@param object gpm.std.BigInt
    ---@param value any
    ---@return gpm.std.BigInt
    local function bor( object, value )
        local other = tobigint( value )
        ---@cast other gpm.std.BigInt

        if other[ 0 ] == 0 then
            return object
        elseif object[ 0 ] == 0 then
            return abs( other )
        elseif compare_unsigned( object, other ) == 0 then
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

    BigInt.bor = bor

    --- [SHARED AND MENU]
    ---
    --- Creates a new big integer object that is the result of a bitwise OR operation between two big integer objects.
    ---@param value gpm.std.BigInt
    ---@param ... any
    ---@return gpm.std.BigInt
    function bit.bor( value, ... )
        local object = copy( value )
        local args = { ... }

        for i = 1, select( '#', ... ), 1 do
            bor( object, args[ i ] )
        end

        return object
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise AND operation between two big integer objects.
    ---@param object gpm.std.BigInt
    ---@param value any
    ---@return gpm.std.BigInt
    local function band( object, value )
        local other = tobigint( value )
        ---@cast other gpm.std.BigInt

        if object[ 0 ] == 0 then
            return object
        elseif other[ 0 ] == 0 then
            return abs( other )
        elseif compare_unsigned( object, other ) == 0 then
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
            rstrip( object )
        end

        return object
    end

    BigInt.band = band

    --- [SHARED AND MENU]
    ---
    --- Creates a new big integer object that is the result of a bitwise AND operation between two big integer objects.
    ---@param value gpm.std.BigInt
    ---@param ... any
    ---@return gpm.std.BigInt
    function bit.band( value, ... )
        local object = copy( value )
        local args = { ... }

        for i = 1, select( '#', ... ), 1 do
            band( object, args[ i ] )
        end

        return object
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise XOR operation between two big integer objects.
    ---@param object gpm.std.BigInt
    ---@param value any
    ---@return gpm.std.BigInt
    local function bxor( object, value )
        local other = tobigint( value )
        ---@cast other gpm.std.BigInt

        if other[ 0 ] == 0 then
            return object
        elseif object[ 0 ] == 0 then
            abs( other )
            return other
        elseif compare_unsigned( object, other ) == 0 then
            zero( object )
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

        rstrip( object )
        return object
    end

    BigInt.bxor = bxor

    --- [SHARED AND MENU]
    ---
    --- Creates a new big integer object that is the result of a bitwise XOR operation between two big integer objects.
    ---@param value gpm.std.BigInt
    ---@param ... any
    ---@return gpm.std.BigInt
    function bit.bxor( value, ... )
        local object = copy( value )
        local args = { ... }

        for i = 1, select( '#', ... ), 1 do
            bxor( object, args[ i ] )
        end

        return object
    end

end

local bnot
do

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise NOT operation on a big integer object.
    ---@param object gpm.std.BigInt
    ---@param value integer
    ---@return gpm.std.BigInt
    function bnot( object, value )
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

        rstrip( object )
        return object
    end

    BigInt.bnot = bnot

    --- [SHARED AND MENU]
    ---
    --- Creates a new big integer object that is the result of a bitwise NOT operation on a big integer object.
    ---@param object gpm.std.BigInt
    ---@param size integer
    ---@return gpm.std.BigInt
    function bit.bnot( object, size )
        return bnot( copy( object ), size )
    end

end

--- [SHARED AND MENU]
---
--- Returns the value of a given bit in a big integer object.
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

--- [SHARED AND MENU]
---
--- Sets `true` of one or more bits in a big integer object.
---@param ... integer
---@return gpm.std.BigInt
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

--- [SHARED AND MENU]
---
--- Unsets `false` of one or more bits in a big integer object.
---@param ... integer
---@return gpm.std.BigInt
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
        rstrip( self )
    end

    return self
end

--- [SHARED AND MENU]
---
--- Adds big integer to a big integer object.
---@param object gpm.std.BigInt
---@param value any
---@return gpm.std.BigInt
local function add( object, value )
    local other = tobigint( value )
    ---@cast other gpm.std.BigInt

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
        local compare_result = compare_unsigned( object, other )
        if compare_result == 0 then
            zero( object )
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
        rstrip( object )
    end

    if change_sign then
        object[ 0 ] = -object[ 0 ]
    end

    return object
end

BigInt.add = add

---@param value gpm.std.BigInt
---@return gpm.std.BigInt
---@protected
function BigInt:__add( value )
    return add( copy( self ), value )
end

--- [SHARED AND MENU]
---
--- Subtracts big integer from a big integer object.
---@param object gpm.std.BigInt
---@param value any
---@return gpm.std.BigInt
local function sub( object, value )
    return add( object, negate( tobigint( value ) ) )
end

BigInt.sub = sub

---@param value gpm.std.BigInt
---@return gpm.std.BigInt
---@protected
function BigInt:__sub( value )
    return sub( copy( self ), value )
end

--- [SHARED AND MENU]
---
--- Multiplies big integer with a big integer object.
---@param object gpm.std.BigInt
---@param value any
---@return gpm.std.BigInt
local function mul( object, value )
    local other = tobigint( value )
    ---@cast other gpm.std.BigInt

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
    if is_one( object ) then
        if object[ 0 ] == -1 then
            negate( other )
        end

        return other
    end

    if is_one( other ) then
        if other[ 0 ] == -1 then
            negate( object )
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

BigInt.mul = mul

---@param value gpm.std.BigInt
---@return gpm.std.BigInt
---@protected
function BigInt:__mul( value )
    return mul( copy( self ), value )
end

do

    --- [SHARED AND MENU]
    ---
    --- Divides big integer by a big integer object and returns the quotient and remainder.
    ---@param object gpm.std.BigInt
    ---@param value any
    ---@param ignore_remainder? boolean
    ---@return gpm.std.BigInt
    ---@return gpm.std.BigInt
    local function full_div( object, value, ignore_remainder )
        local other = tobigint( value )
        ---@cast other gpm.std.BigInt

        -- division of/by 0
        if object[ 0 ] == 0 then
            return object, object
        elseif other[ 0 ] == 0 then
            return other, other
        end

        -- division by 1
        if is_one( other ) then
            if other[ 0 ] == -1 then
                negate( object )
            end

            return object, new()
        end

        -- division by bigger number or object
        local compare_result = compare_unsigned( object, other )
        if compare_result == -1 then
            if object[ 0 ] == other[ 0 ] then
                return new(), object
            elseif ignore_remainder then
                return new(), object
            end

            return new(), add( object, other )
        elseif compare_result == 0 then
            if object[ 0 ] == other[ 0 ] then
                return setmetatable( { [ 0 ] = 1, 1 }, BigInt ), new()
            end

            return setmetatable( { [ 0 ] = -1, 1 }, BigInt ), new()
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
        rstrip( b1 )

        -- if remainder is negative, add divisor to make it positive
        if not ignore_remainder and sign1 == -sign2 and b1[ 0 ] ~= 0 then
            add( b1, b2 )
        end

        b2[ 0 ] = sign1 * sign2

        local reversed, length = table_reversed( result )

        for index = 1, length, 1 do
            b2[ index ] = reversed[ index ]
        end

        rstrip( b2 )

        if b1[ 0 ] ~= 0 and sign2 == -1 then
            b1[ 0 ] = -1
        end

        return b2, b1
    end

    --- [SHARED AND MENU]
    ---
    --- Divides big integer by a big integer object.
    ---@param object gpm.std.BigInt
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    local function div( object, value )
        local quotient, _ = full_div( object, value, true )
        return quotient
    end

    BigInt.div = div

    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    ---@protected
    function BigInt:__div( value )
        return div( copy( self ), value )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the remainder from dividing two big integers.
    ---@param object gpm.std.BigInt
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    local function mod( object, value )
        local _, remainder = full_div( object, value, false )
        return remainder
    end

    BigInt.mod = mod

    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    ---@protected
    function BigInt:__mod( value )
        return mod( copy( self ), value )
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Returns the log2 of a big integer object. ( calculate log2 by finding highest 1 bit )
    ---@return gpm.std.BigInt | nil
    function BigInt:log2()
        if self[ 0 ] == 0 then return nil end

        local byte_count = #self
        local byte_number = ( byte_count - 1 ) * 8

        local byte = self[ byte_count ]

        while byte >= 1 do
            byte_number = byte_number + 1
            byte = byte * 0.5
        end

        return from_number( new(), byte_number - 1 )
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Returns the log2 of a big integer object. ( return log2 if it's an integer, else nil )
    ---@param object gpm.std.BigInt
    ---@return integer | nil
    local function log2( object )
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

    --- [SHARED AND MENU]
    ---
    --- Raises a big integer object to a power.
    ---@param object gpm.std.BigInt
    ---@param value any
    ---@return gpm.std.BigInt
    local function pow( object, value )
        local other = tobigint( value )
        ---@cast other gpm.std.BigInt

        if other[ 0 ] == 0 then
            return setmetatable( { [ 0 ] = 1, 1 }, BigInt )
        elseif other[ 0 ] == -1 then
            zero( object )
            return object
        elseif is_one( other ) then
            return object
        end

        local sign = object[ 0 ]
        if sign == -1 and other[ 1 ] % 2 == 0 then
            sign = 1
        end

        -- fast exponent if self is a power of 2
        local power = log2( object )
        if power ~= nil then
            -- assumes other isn't so big that precision becomes an issue
            local object_copy = copy( object )
            bit_lshift( object_copy, ( toInteger( object_copy ) - 1 ) * power )
            object_copy.sign = sign
            return object_copy
        end

        -- multiply by self repeatedly
        local other_copy = copy( other )

        abs( other_copy )
        add( other_copy, negaive_one )

        local object_copy = copy( object )

        while other_copy[ 0 ] ~= 0 do
            mul( object_copy, object )
            add( other_copy, negaive_one )
        end

        object_copy[ 0 ] = sign
        return object_copy
    end

    BigInt.pow = pow

    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    ---@protected
    function BigInt:__pow( value )
        return pow( copy( self ), value )
    end

end

--- convert 2's complement unsigned number to signed
---@param byte_amt integer
---@return gpm.std.BigInt
function BigInt:toSigned( byte_amt )
    local byte_count = #self

    local size = math_max( byte_amt or byte_count, 1 )
    if byte_count > size then
        std.error( "twos complement overflow", 2 )
    end

    if self[ 0 ] == 1 and ( self[ size ] or 0 ) > 0x7f then
        bnot( self, size )
        add( self, one )
        self[ 0 ] = -1
    end

    return self
end

--- convert 2's complement signed number to unsigned
---@param byte_amt integer
---@return gpm.std.BigInt
function BigInt:toUnsigned( byte_amt )
    local byte_count = #self

    local size = math_max( byte_amt or byte_count, 1 )
    if byte_count > size then
        std.error( "twos complement overflow", 2 )
    end

    if self[ 0 ] == -1 then
        self[ 0 ] = 1
        bnot( self, size )
        add( self, one )
    end

    return self
end

do

    --- [SHARED AND MENU]
    ---
    --- Compares big integer objects.
    ---@param a gpm.std.BigInt
    ---@param value any
    ---@return integer
    local function compare( a, value )
        local b = tobigint( value )
        ---@cast b gpm.std.BigInt

        if a[ 0 ] > b[ 0 ] then
            return 1
        elseif a[ 0 ] < b[ 0 ] then
            return -1
        end

        local compare_result = compare_unsigned( a, b )
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

    --- [SHARED AND MENU]
    ---
    --- Checks if two big integer objects are equal.
    ---@param other gpm.std.BigInt
    ---@return boolean
    function BigInt:eq( other )
        return compare( self, other ) == 0
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if two big integer objects are not equal.
    ---@param other gpm.std.BigInt
    ---@return boolean
    function BigInt:ne( other )
        return compare( self, other ) ~= 0
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if one big integer object is less than another.
    ---@param other gpm.std.BigInt
    ---@return boolean
    function BigInt:lt( other )
        return compare( self, other ) == -1
    end

    --- [SHARED AND MENU]
    --- Checks if one big integer object is less than or equal to another.
    ---@param other gpm.std.BigInt
    ---@return boolean
    function BigInt:le( other )
        return compare( self, other ) <= 0
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if one big integer object is greater than another.
    ---@param other gpm.std.BigInt
    ---@return boolean
    function BigInt:gt( other )
        return compare( self, other ) == 1
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if one big integer object is greater than or equal to another.
    ---@param other gpm.std.BigInt
    ---@return boolean
    function BigInt:ge( other )
        return compare( self, other ) >= 0
    end

    BigInt.__eq = BigInt.eq
    BigInt.__lt = BigInt.lt
    BigInt.__le = BigInt.le

end
