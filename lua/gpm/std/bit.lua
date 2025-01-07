local _G = _G
local glua_bit = _G.bit
local debug_getmetatable = _G.gpm.std.debug.getmetatable

--- [SHARED AND MENU] The bit library.
---@class gpm.std.bit
local bit = {}

do

    local bit_arshift = glua_bit.arshift

    -- [SHARED AND MENU] Returns the arithmetically shifted value.
    ---@generic V
    ---@param value V: The value to be manipulated.
    ---@param shift number: Amounts of bits to shift.
    ---@return V: The arithmetically shifted value.
    function bit.arshift( value, shift )
        local metatable = debug_getmetatable( value )
        if metatable == nil then
            return bit_arshift( value, shift )
        else
            local fn = metatable.__shar
            if fn == nil then
                return bit_arshift( value, shift )
            end

            return fn( value, shift )
        end
    end

end

do

    local bit_lshift = glua_bit.lshift

    --- [SHARED AND MENU] Returns the left shifted value.
    ---@generic V
    ---@param value V: The value to be manipulated.
    ---@param shift number: Amounts of bits to shift left by.
    ---@return V: The left shifted value.
    function bit.lshift( value, shift )
        local metatable = debug_getmetatable( value )
        if metatable == nil then
            return bit_lshift( value, shift )
        else
            local fn = metatable.__shl
            if fn == nil then
                return bit_lshift( value, shift )
            else
                return fn( value, shift )
            end
        end
    end

end

do

    local bit_rshift = glua_bit.rshift

    --- [SHARED AND MENU] Returns the right shifted value.
    ---@generic V
    ---@param value V: The value to be manipulated.
    ---@param shift number: Amounts of bits to shift right by.
    ---@return V: The right shifted value.
    function bit.rshift( value, shift )
        local metatable = debug_getmetatable( value )
        if metatable == nil then
            return bit_rshift( value, shift )
        else
            local fn = metatable.__shr
            if fn == nil then
                return bit_rshift( value, shift )
            else
                return fn( value, shift )
            end
        end
    end

end

do

    local bit_rol = glua_bit.rol

    --- [SHARED AND MENU] Returns the left rotated value.
    ---@generic V
    ---@param value V: The value to be manipulated.
    ---@param shift number: Amounts of bits to rotate left by.
    ---@return V: The left rotated value.
    function bit.rol( value, shift )
        local metatable = debug_getmetatable( value )
        if metatable == nil then
            return bit_rol( value, shift )
        else
            local fn = metatable.__rol
            if fn == nil then
                return bit_rol( value, shift )
            else
                return fn( value, shift )
            end
        end
    end

end

do

    local bit_ror = glua_bit.ror

    --- [SHARED AND MENU] Returns the right rotated value.
    ---@generic V
    ---@param value V: The value to be manipulated.
    ---@param shift number: Amounts of bits to rotate right by.
    ---@return V: The right rotated value.
    function bit.ror( value, shift )
        local metatable = debug_getmetatable( value )
        if metatable == nil then
            return bit_ror( value, shift )
        else
            local fn = metatable.__ror
            if fn == nil then
                return bit_ror( value, shift )
            else
                return fn( value, shift )
            end
        end
    end

end

do

    local bit_band = glua_bit.band

    --- [SHARED AND MENU] Performs the bitwise `and for all values specified.
    ---@generic V
    ---@param value V: The value to be manipulated.
    ---@param ... V?: Values bit to perform bitwise `and` with.
    ---@return V: Result of bitwise `and` operation.
    function bit.band( value, ... )
        local metatable = debug_getmetatable( value )
        if metatable == nil then
            return bit_band( value, ... )
        else
            local fn = metatable.__band
            if fn == nil then
                return bit_band( value, ... )
            else
                return fn( value, ... )
            end
        end
    end

end

do

    local bit_bnot = glua_bit.bnot

    --- [SHARED AND MENU] Returns the bitwise `not` of the value.
    ---@generic V
    ---@param value V: The value to be inverted.
    ---@return V: Result of bitwise `not` operation.
    function bit.bnot( value )
        local metatable = debug_getmetatable( value )
        if metatable == nil then
            return bit_bnot( value )
        else
            local fn = metatable.__bnot
            if fn == nil then
                return bit_bnot( value )
            else
                return fn( value )
            end
        end
    end

end

do

    local bit_bor = glua_bit.bor

    --- [SHARED AND MENU] Returns the bitwise `or` of all values specified.
    ---@generic V
    ---@param value V: The first value.
    ---@param ... V: Extra values to be evaluated.
    ---@return V: The bitwise `or` result between all values.
    function bit.bor( value, ... )
        local metatable = debug_getmetatable( value )
        if metatable == nil then
            return bit_bor( value, ... )
        else
            local fn = metatable.__bor
            if fn == nil then
                return bit_bor( value, ... )
            else
                return fn( value, ... )
            end
        end
    end

end

do

    local bit_bxor = glua_bit.bxor

    --- [SHARED AND MENU] Returns the bitwise `xor` of all values specified.
    ---@generic V
    ---@param value V: The value to be manipulated.
    ---@param ... V: Values bit xor with.
    ---@return V: Result of bitwise `xor` operation.
    function bit.bxor( value, ... )
        local metatable = debug_getmetatable( value )
        if metatable == nil then
            return bit_bxor( value, ... )
        else
            local fn = metatable.__bxor
            if fn == nil then
                return bit_bxor( value, ... )
            else
                return fn( value, ... )
            end
        end
    end

end

do

    local bit_bswap = glua_bit.bswap

    --- [SHARED AND MENU] Swaps the byte order.
    ---@generic V
    ---@param value V: The value to be byte swapped.
    ---@return V: The byte swapped value.
    function bit.bswap( value )
        local metatable = debug_getmetatable( value )
        if metatable == nil then
            return bit_bswap( value )
        else
            local fn = metatable.__bswap
            if fn == nil then
                return bit_bswap( value )
            else
                return fn( value )
            end
        end
    end

end

do

    local bit_tobit = glua_bit.tobit

    --- [SHARED AND MENU] Normalizes the specified value and clamps it in the range of a signed 32bit integer.
    ---@param value any: The value to be normalized.
    ---@return number: The normalized value.
    function bit.tobit( value )
        local metatable = debug_getmetatable( value )
        if metatable == nil then
            return bit_tobit( value )
        else
            local fn = metatable.__tobit
            if fn == nil then
                return bit_tobit( value )
            else
                return fn( value )
            end
        end
    end

end

do

    local bit_tohex = glua_bit.tohex

    --- [SHARED AND MENU] Returns the hexadecimal representation of the number with the specified digits.
    ---@param value any: The value to be converted.
    ---@param length number: The number of digits. Defaults to 8.
    ---@return string: The hexadecimal representation.
    function bit.tohex( value, length )
        if length == nil then length = 8 end

        local metatable = debug_getmetatable( value )
        if metatable == nil then
            return bit_tohex( value, length )
        else
            local fn = metatable.__tohex
            if fn == nil then
                return bit_tohex( value, length )
            else
                return fn( value, length )
            end
        end
    end

end

return bit
