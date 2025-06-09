-- Based on https://gist.github.com/x4fx77x4f/5b97e803825d3dc16f6e9c5227ec6a04
local _G = _G

---@class gpm.std
local std = _G.gpm.std
local math = std.math

--- [SHARED AND MENU]
---
--- The bit library.
---
---@class gpm.std.bit
local bit = std.bit or {}
std.bit = bit

if _G.bit ~= nil then

    local glua_bit = _G.bit

    bit.band = bit.band or glua_bit.band
    bit.bor = bit.bor or glua_bit.bor

    bit.bnot = bit.bnot or glua_bit.bnot
    bit.bxor = bit.bxor or glua_bit.bxor

    bit.arshift = bit.arshift or glua_bit.arshift
    bit.lshift = bit.lshift or glua_bit.lshift
    bit.rshift = bit.rshift or glua_bit.rshift

    bit.rol = bit.rol or glua_bit.rol
    bit.ror = bit.ror or glua_bit.ror

    bit.bswap = bit.bswap or glua_bit.bswap

    bit.tobit = bit.tobit or glua_bit.tobit
    bit.tohex = bit.tohex or glua_bit.tohex

end

if bit.tohex == nil then

    local string_format = std.string.format

    --- [SHARED AND MENU]
    ---
    --- Returns the hexadecimal representation of the number with the specified digits.
    ---@param value integer The value to be converted.
    ---@param length integer? The number of digits. Defaults to 8.
    ---@return string str The hexadecimal representation.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.tohex( value, length )
        return string_format( "%0" .. ( length or 8 ) .. "X", value )
    end

end

if bit.tobit == nil then

    --- [SHARED AND MENU]
    ---
    --- Normalizes the specified value and clamps it in the range of a signed 32bit integer.
    ---
    ---@param value integer The value to be normalized.
    ---@return integer result The normalized value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.tobit( value )
        value = value % 0x100000000
        return ( value >= 0x80000000 ) and ( value - 0x100000000 ) or value
    end

end

local math_floor = math.floor
local bit_tobit = bit.tobit

if bit.arshift == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the arithmetically shifted value.
    ---@param value integer The value to be manipulated.
    ---@param shift integer Amounts of bits to shift.
    ---@return integer result The arithmetically shifted value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.arshift( value, shift )
        return bit_tobit( math_floor( value / ( 2 ^ shift ) ) * ( value >= 0x80000000 and -1 or 1 ) )
    end

end

if bit.lshift == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the left shifted value.
    ---@param value integer The value to be manipulated.
    ---@param shift integer Amounts of bits to shift left by.
    ---@return integer result The left shifted value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.lshift( value, shift )
        if shift > 31 then
            return 0
        else
            return bit_tobit( value * ( 2 ^ shift ) )
        end
    end

end

if bit.rshift == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the right shifted value.
    ---
    ---@param value integer The value to be manipulated.
    ---@param shift integer Amounts of bits to shift right by.
    ---@return integer result The right shifted value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.rshift( value, shift )
        if shift > 31 then
            return 0
        else
            return bit_tobit( math_floor( value / ( 2 ^ shift ) ) )
        end
    end

end

if bit.bswap == nil then

    --- [SHARED AND MENU]
    ---
    --- Swaps the byte order of a 32-bit integer.
    ---
    ---@param value integer The 32-bit integer to be byte-swapped.
    ---@return integer result The byte-swapped value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.bswap( value )
        return bit_tobit( ( ( value % 0x100 ) * 0x1000000 ) + ( ( math_floor( value / 0x100 ) % 0x100 ) * 0x10000 ) + ( ( math_floor( value / 0x10000 ) % 0x100 ) * 0x100 ) + ( math_floor( value / 0x1000000 ) % 0x100 ) )
    end

end

if bit.bnot == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the bitwise `not` of the value.
    ---
    ---@param value integer The value to be manipulated.
    ---@return integer result The bitwise `not` of the value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.bnot( value )
        local result = 0
        for i = 0, 31, 1 do
            if value % 2 == 0 then
                result = result + 2 ^ i
            end

            value = math_floor( value * 0.5 )
        end

        return bit_tobit( result )
    end

end

if bit.band == nil then

    --- [SHARED AND MENU]
    ---
    --- Performs the bitwise `and for all values specified.
    ---
    ---@param value integer The value to be manipulated.
    ---@param ... integer? Values bit and with.
    ---@return integer result The bitwise `and` result between all values.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.band( value, ... )
        local args = { value, ... }
        local result = 0xFFFFFFFF

        local bits = {}
        for i = 1, select( "#", value, ... ), 1 do
            local x = args[ i ]
            for j = 1, 32, 1 do
                if x % 2 == 0 and bits[ j ] == nil then
                    bits[ j ] = true
                    result = result - 2 ^ ( j - 1 )
                end

                x = math_floor( x * 0.5 )
            end
        end

        return bit_tobit( result )
    end

end

if bit.bor == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the bitwise `or` of all values specified.
    ---
    ---@param value integer The value to be manipulated.
    ---@param ... integer? Values bit or with.
    ---@return integer result The bitwise `or` result between all values.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.bor( value, ... )
        local args = { value, ... }
        local result = 0

        local bits = {}
        for i = 1, select( "#", value, ... ), 1 do
            local x = args[ i ]
            for j = 1, 32, 1 do
                if x % 2 ~= 0 and bits[ j ] == nil then
                    bits[ j ] = true
                    result = result + 2 ^ ( j - 1 )
                end

                x = math_floor( x * 0.5 )
            end
        end

        return bit_tobit( result )
    end

end

if bit.bxor == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the bitwise `xor` of all values specified.
    ---
    ---@param value integer The value to be manipulated.
    ---@param ... integer? Values bit xor with.
    ---@return integer result Result of bitwise `xor` operation.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.bxor( value, ... )
        local args = { value, ... }

        local bits = {}
        for i = 1, select( "#", value, ... ), 1 do
            local x = args[ i ]
            for j = 1, 32, 1 do
                if x % 2 ~= 0 then
                    bits[ i ] = not bits[ i ]
                end

                x = math_floor( x * 0.5 )
            end
        end

        local output = 0
        for i = 1, 32, 1 do
            if bits[ i ] == true then
                output = output + 2 ^ ( i - 1 )
            end
        end

        return bit_tobit( output )
    end

end

local bit_lshift, bit_rshift = bit.lshift, bit.rshift
local bit_band, bit_bor = bit.band, bit.bor

if bit.rol == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the left rotated value.
    ---
    ---@param value integer The value to be manipulated.
    ---@param shift integer Amounts of bits to rotate left by.
    ---@return integer result The left rotated value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.rol( value, shift )
        return bit_bor( bit_lshift( value, shift ), bit_rshift( value, 32 - shift ) )
    end

end

if bit.ror == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the right rotated value.
    ---
    ---@param value integer The value to be manipulated.
    ---@param shift integer Amounts of bits to rotate right by.
    ---@return integer result The right rotated value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.ror( value, shift )
        return bit_bor( bit_rshift( value, shift ), bit_lshift( value, 32 - shift ) )
    end

end

if bit.btest == nil then

    --- [SHARED AND MENU]
    ---
    --- Performs the bitwise `test for all values specified.
    ---
    ---@param value integer The value to be tested.
    ---@param ... integer? The values to be tested.
    ---@return boolean result `true` if all values are `true`, `false` otherwise.
    function bit.btest( value, ... )
        return bit_band( value, ... ) ~= 0
    end

end

if bit.extract == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the unsigned number formed by the bits field to field + width - 1 from n. Bits are numbered from 0 (least significant) to 31 (most significant).
    ---
    --- All accessed bits must be in the range [0, 31].
    ---
    ---@param value integer The value to be manipulated.
    ---@param field integer The starting bit.
    ---@param width integer? The number of bits to extract.
    ---@return integer result The extracted value.
    function bit.extract( value, field, width )
        return bit_band( bit_rshift( value, field ), 2 ^ ( width or 1 ) - 1 )
    end

end

if bit.replace == nil then

    local bit_bnot = bit.bnot

    --- [SHARED AND MENU]
    ---
    --- Replaces the bits field to field + width - 1 with the specified value.
    ---
    ---@param value integer The value to be manipulated.
    ---@param extract integer The value to be extracted.
    ---@param field integer The starting bit.
    ---@param width integer? The number of bits to extract.
    ---@return number result The modified value.
    function bit.replace( value, extract, field, width )
        local mask = 2 ^ ( width or 1 ) - 1
        return bit_band( value, bit_bnot( bit_lshift( mask, field ) ) ) + bit_lshift( bit_band( extract, mask ), field )
    end

end
