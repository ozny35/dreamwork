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
local table_reverse = table.reverse
local setmetatable = std.setmetatable
local math_floor, math_max, math_clamp = math.floor, math.max, math.clamp

---@alias BigInt gpm.std.BigInt
---@class gpm.std.BigInt: gpm.std.Object
---@field __class gpm.std.BigIntClass
---@field sign integer
---@field size integer
local BigInt = std.class.base( "BigInt" )

---@alias gpm.std.BigInt.Sign
---| integer
---| `-1`
---| `0`
---| `1`

---@protected
function BigInt:__bitcount()
    return #self * 8
end

---@protected
function BigInt:__tobool()
    return self[ 0 ] ~= 0
end

---@class gpm.std.BigIntClass: gpm.std.BigInt
---@overload fun( value: string | number, base: number? ): gpm.std.BigInt
local BigIntClass = std.class.create( BigInt )
std.BigInt = BigIntClass

---@class gpm.std.BigInt.bit
local bit = {}
BigIntClass.bit = bit

--- TODO
---@param object gpm.std.BigInt
---@return gpm.std.BigInt
local function copy( object )
    local object_copy = {
        [ 0 ] = object[ 0 ]
    }

    for index, value in ipairs( object ) do
        object_copy[ index ] = value
    end

    return setmetatable( object_copy, BigInt )
end

BigInt.copy = copy

--- TODO
---@return gpm.std.BigInt
local function new()
    return setmetatable( { [ 0 ] = 0 }, BigInt )
end

local one = setmetatable( { [ 0 ] = 1, 1 }, BigInt )
local negaive_one = setmetatable( { [ 0 ] = -1, 1 }, BigInt )

--- TODO
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

    std.rawset( self, key, value )
end

local tobigint

--- TODO
---@param object gpm.std.BigInt
---@param value gpm.std.BigInt
---@return integer
local function compare_unsigned( object, value )
    local other = tobigint( value )

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
---@param object gpm.std.BigInt
local function rstrip( object )
    local i = #object
    while i ~= 0 and object[ i ] == 0 do
        object[ i ], i = nil, i - 1
    end

    if i == 0 then
        object[ 0 ] = 0
    end

    return object
end

--- TODO
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

--- TODO
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
        local table_unpack = table.unpack

        do

            local string_format = string.format
            local table_concat = table.concat

            --- TODO
            ---@param object gpm.std.BigInt
            ---@param no_prefix? boolean
            ---@return string
            local function toHex( object, no_prefix )
                local sign = object[ 0 ]
                if sign == 0 then
                    return no_prefix and "0" or "0x0"
                end

                local byte_count = #object
                local result = string_reverse( string_format( "%x" .. string_rep( "%02x", byte_count - 1 ), table_unpack( object, 1, byte_count ) ) )

                if not no_prefix then
                    result = "0x" .. result
                end

                if sign == -1 then
                    result = "-" .. result
                end

                return result
            end

            BigInt.toHex = toHex

            --- TODO
            ---@param object gpm.std.BigInt
            ---@param no_prefix? boolean
            ---@return string
            local function toBin( object, no_prefix )
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
                            if i == byte_count then
                                break
                            end

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

            BigInt.toBin = toBin

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

            --- TODO
            ---@param object gpm.std.BigInt
            ---@param value integer
            ---@param no_prefix? boolean
            ---@return string
            local function toString( object, value, no_prefix )
                local base = math_clamp( value, 2, 36 )
                if base == 2 then
                    return toBin( object, no_prefix )
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

                for i = 1, #result, 1 do
                    result[ i ] = digits[ result[ i ] + 1 ]
                end

                local str = string_reverse( table_concat( result ) )

                if sign == -1 then
                    str = "-" .. str
                end

                return str
            end

            BigInt.toString = toString

            --- TODO
            ---@return string
            function BigInt:toDecimal()
                return toString( self, 10 )
            end

            BigInt.__tostring = BigInt.toDecimal

        end

        do

            ---@param sign gpm.std.BigInt.Sign
            ---@vararg integer
            ---@return BigInt
            function BigIntClass.fromBytes( sign, ... )
                return rstrip( setmetatable( { [ 0 ] = sign or 0, ... }, BigInt ) )
            end

            --- parse integer from an byte array
            ---@param object gpm.std.BigInt
            ---@param sing gpm.std.BigInt.Sign
            ---@vararg integer
            ---@return BigInt
            local function fromBytes( object, sing, ... )
                object[ 0 ] = sing

                local bytes = { ... }
                for index = 1, select( "#", ... ), 1 do
                    object[ index ] = bytes[ index ]
                end

                rstrip( object )
                return object
            end

            BigInt.fromBytes = fromBytes

            --- TODO
            ---@param str string
            ---@param big_endian? boolean
            ---@return BigInt
            function BigIntClass.fromBinary( str, big_endian )
                return fromBytes( new(), 1, string_byte( big_endian and string_reverse( str ) or str, 1, string_len( str ) ) )
            end

            --- TODO
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

    --- TODO
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

    --- TODO
    ---@param value string
    ---@param base? integer
    ---@return gpm.std.BigInt
    function BigIntClass.fromString( value, base )
        return from_string( new(), value, base )
    end

    do

        local isstring, isnumber = std.isstring, std.isnumber
        local debug_getmetatable = std.debug.getmetatable

        --- TODO
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

        ---@protected
        function BigInt:__new( value, base )
            return tobigint( value, base )
        end

    end

end

local maxnumber

-- determine the max accurate integer supported by this build of Lua
if 0x1000000 == 0x1000001 then
    maxnumber = from_string( new(), "0xffffff" )
else
    maxnumber = from_string( new(), "0x1FFFFFFFFFFFFF" )
end

BigIntClass.MaxNumber = maxnumber

--- TODO
---@param object gpm.std.BigInt
---@return integer
local function tonumber( object )
    if compare_unsigned( object, maxnumber ) == 1 then
        std.error( "big integer is too big to be converted to lua number", 2 )
    end

    local result = 0
    for i = #object, 1, -1 do
        result = ( result * 256 ) + object[ i ]
    end

    return result * object[ 0 ]
end

BigInt.tonumber = tonumber
BigInt.__tonumber = tonumber

do

    --- TODO
    ---@param object gpm.std.BigInt
    ---@return boolean
    local function is_even( object )
        return object[ 0 ] == 0 or object[ 1 ] % 2 == 0
    end

    BigInt.isEven = is_even

    --- TODO
    ---@return boolean
    function BigInt:isOdd()
        return not is_even( self )
    end

end

--- TODO
---@return boolean
function BigInt:isZero()
    return self[ 0 ] == 0
end

--- TODO
---@return boolean
local function is_one( object )
    return object[ 2 ] == nil and object[ 1 ] == 1
end

BigInt.isOne = is_one

--- TODO
---@param object gpm.std.BigInt
---@return gpm.std.BigInt
local function unm( object )
    local sign = object[ 0 ]
    if sign ~= 0 then
        object[ 0 ] = -object[ 0 ]
    end

    return object
end

BigInt.unm = unm

--- TODO
---@return gpm.std.BigInt
function BigInt:__unm()
    return unm( copy( self ) )
end

--- TODO
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

    --- TODO
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

    --- TODO
    ---@param object gpm.std.BigInt
    ---@param shift integer
    ---@return gpm.std.BigInt
    function bit.lshift( object, shift )
        return bit_lshift( copy( object ), shift )
    end

    --- TODO
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
        local shift_bytes, byte_count = math_floor( shift / 8 ), #object
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

    --- TODO
    ---@param object gpm.std.BigInt
    ---@param shift integer
    ---@return gpm.std.BigInt
    function bit.rshift( object, shift )
        return bit_rshift( copy( object ), shift )
    end

end

do

    --- TODO
    ---@param object gpm.std.BigInt
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    local function bor( object, value )
        local other = tobigint( value )

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

    --- TODO
    ---@param object gpm.std.BigInt
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    function bit.bor( object, value )
        return bor( copy( object ), value )
    end

end

do

    --- TODO
    ---@param object gpm.std.BigInt
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    local function band( object, value )
        local other = tobigint( value )

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

    --- TODO
    ---@param object gpm.std.BigInt
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    function bit.band( object, value )
        return band( copy( object ), value )
    end

end

do

    --- TODO
    ---@param object gpm.std.BigInt
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    local function bxor( object, value )
        local other = tobigint( value )

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

    --- TODO
    ---@param object gpm.std.BigInt
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    function bit.bxor( object, value )
        return bxor( copy( object ), value )
    end

end

local bnot
do

    --- TODO
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

    --- TODO
    ---@param object gpm.std.BigInt
    ---@param size integer
    ---@return gpm.std.BigInt
    function bit.bnot( object, size )
        return bnot( copy( object ), size )
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

--- TODO
---@vararg integer
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

--- TODO
---@vararg integer
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

--- TODO
---@param object gpm.std.BigInt
---@param value gpm.std.BigInt
---@return gpm.std.BigInt
local function add( object, value )
    local other = tobigint( value )

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

--- TODO
---@param value gpm.std.BigInt
---@return gpm.std.BigInt
function BigInt:__add( value )
    return add( copy( self ), value )
end

--- TODO
---@param object gpm.std.BigInt
---@param value gpm.std.BigInt
---@return gpm.std.BigInt
local function sub( object, value )
    return add( object, unm( tobigint( value ) ) )
end

BigInt.sub = sub

--- TODO
---@param value gpm.std.BigInt
---@return gpm.std.BigInt
function BigInt:__sub( value )
    return sub( copy( self ), value )
end

--- TODO
---@param object gpm.std.BigInt
---@param value gpm.std.BigInt
---@return gpm.std.BigInt
local function mul( object, value )
    local other = tobigint( value )

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
            unm( other )
        end

        return other
    end

    if is_one( other ) then
        if other[ 0 ] == -1 then
            unm( object )
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

--- TODO
---@param value gpm.std.BigInt
---@return gpm.std.BigInt
function BigInt:__mul( value )
    return mul( copy( self ), value )
end

do

    --- TODO
    ---@param object gpm.std.BigInt
    ---@param value gpm.std.BigInt
    ---@param ignore_remainder? boolean
    ---@return gpm.std.BigInt
    ---@return gpm.std.BigInt
    local function full_div( object, value, ignore_remainder )
        local other = tobigint( value )

        -- division of/by 0
        if object[ 0 ] == 0 then
            return object, object
        elseif other[ 0 ] == 0 then
            return other, other
        end

        -- division by 1
        if is_one( other ) then
            if other[ 0 ] == -1 then
                unm( object )
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

        local reversed, length = table_reverse( result )

        for index = 1, length, 1 do
            b2[ index ] = reversed[ index ]
        end

        rstrip( b2 )

        if b1[ 0 ] ~= 0 and sign2 == -1 then
            b1[ 0 ] = -1
        end

        return b2, b1
    end

    --- TODO
    ---@param object gpm.std.BigInt
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    local function div( object, value )
        local quotient, _ = full_div( object, value, true )
        return quotient
    end

    BigInt.div = div

    --- TODO
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    function BigInt:__div( value )
        return div( copy( self ), value )
    end

    --- TODO
    ---@param object gpm.std.BigInt
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    local function mod( object, value )
        local _, remainder = full_div( object, value, false )
        return remainder
    end

    BigInt.mod = mod

    --- TODO
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    function BigInt:__mod( value )
        return mod( copy( self ), value )
    end

end

do

    --- calculate log2 by finding highest 1 bit
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

    --- return log2 if it's an integer, else nil
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

    --- TODO
    ---@param object gpm.std.BigInt
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
    local function pow( object, value )
        local other = tobigint( value )

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
            bit_lshift( object_copy, ( tonumber( object_copy ) - 1 ) * power )
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

    --- TODO
    ---@param value gpm.std.BigInt
    ---@return gpm.std.BigInt
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

    --- TODO
    ---@param a gpm.std.BigInt
    ---@param value gpm.std.BigInt
    ---@return integer
    local function compare( a, value )
        local b = tobigint( value )

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

    --- TODO
    ---@param other gpm.std.BigInt
    ---@return boolean
    function BigInt:eq( other )
        return compare( self, other ) == 0
    end

    --- TODO
    ---@param other gpm.std.BigInt
    ---@return boolean
    function BigInt:ne( other )
        return compare( self, other ) ~= 0
    end

    --- TODO
    ---@param other gpm.std.BigInt
    ---@return boolean
    function BigInt:lt( other )
        return compare( self, other ) == -1
    end

    --- TODO
    ---@param other gpm.std.BigInt
    ---@return boolean
    function BigInt:le( other )
        return compare( self, other ) <= 0
    end

    --- TODO
    ---@param other gpm.std.BigInt
    ---@return boolean
    function BigInt:gt( other )
        return compare( self, other ) == 1
    end

    --- TODO
    ---@param other gpm.std.BigInt
    ---@return boolean
    function BigInt:ge( other )
        return compare( self, other ) >= 0
    end

    BigInt.__eq = BigInt.eq
    BigInt.__lt = BigInt.lt
    BigInt.__le = BigInt.le

end
