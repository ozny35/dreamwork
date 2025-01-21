local _G = _G
local std = _G.gpm.std

local number_metatable = std.debug.findmetatable( "number" )
if number_metatable == nil then
    error( "bit: number metatable not found" )
else
    local bit = _G.bit
    number_metatable.__shar = bit.arshift
    number_metatable.__shl = bit.lshift
    number_metatable.__shr = bit.rshift
    number_metatable.__rol = bit.rol
    number_metatable.__ror = bit.ror
    number_metatable.__band = bit.band
    number_metatable.__bnot = bit.bnot
    number_metatable.__bor = bit.bor
    number_metatable.__bxor = bit.bxor
    number_metatable.__bswap = bit.bswap
    number_metatable.__tobit = bit.tobit
    number_metatable.__tohex = bit.tohex
end

local debug_getmetatable = std.debug.getmetatable

--- [SHARED AND MENU] The bit library.
---@class gpm.std.bit
local bit = {}

--- [SHARED AND MENU] Returns the arithmetically shifted value.
---@generic V
---@param value V: The value to be manipulated.
---@param shift integer: Amounts of bits to shift.
---@return V: The arithmetically shifted value.
function bit.arshift( value, shift )
    local metatable = debug_getmetatable( value )
    return metatable and metatable.__shar( value, shift )
end

--- [SHARED AND MENU] Returns the left shifted value.
---@generic V
---@param value V: The value to be manipulated.
---@param shift integer: Amounts of bits to shift left by.
---@return V: The left shifted value.
function bit.lshift( value, shift )
    local metatable = debug_getmetatable( value )
    return metatable and metatable.__shl( value, shift )
end

--- [SHARED AND MENU] Returns the right shifted value.
---@generic V
---@param value V: The value to be manipulated.
---@param shift integer: Amounts of bits to shift right by.
---@return V: The right shifted value.
function bit.rshift( value, shift )
    local metatable = debug_getmetatable( value )
    return metatable and metatable.__shr( value, shift )
end

--- [SHARED AND MENU] Returns the left rotated value.
---@generic V
---@param value V: The value to be manipulated.
---@param shift integer: Amounts of bits to rotate left by.
---@return V: The left rotated value.
function bit.rol( value, shift )
    local metatable = debug_getmetatable( value )
    return metatable and metatable.__rol( value, shift )
end

--- [SHARED AND MENU] Returns the right rotated value.
---@generic V
---@param value V: The value to be manipulated.
---@param shift integer: Amounts of bits to rotate right by.
---@return V: The right rotated value.
function bit.ror( value, shift )
    local metatable = debug_getmetatable( value )
    return metatable and metatable.__ror( value, shift )
end

--- [SHARED AND MENU] Performs the bitwise `and for all values specified.
---@generic V
---@param value V: The value to be manipulated.
---@param ... V?: Values bit to perform bitwise `and` with.
---@return V: Result of bitwise `and` operation.
function bit.band( value, ... )
    local metatable = debug_getmetatable( value )
    return metatable and metatable.__band( value, ... )
end

--- [SHARED AND MENU] Returns the bitwise `not` of the value.
---@generic V
---@param value V: The value to be inverted.
---@return V: Result of bitwise `not` operation.
function bit.bnot( value )
    local metatable = debug_getmetatable( value )
    return metatable and metatable.__bnot( value )
end

--- [SHARED AND MENU] Returns the bitwise `or` of all values specified.
---@generic V
---@param value V: The first value.
---@param ... V: Extra values to be evaluated.
---@return V: The bitwise `or` result between all values.
function bit.bor( value, ... )
    local metatable = debug_getmetatable( value )
    return metatable and metatable.__bor( value, ... )
end

--- [SHARED AND MENU] Returns the bitwise `xor` of all values specified.
---@generic V
---@param value V: The value to be manipulated.
---@param ... V: Values bit xor with.
---@return V: Result of bitwise `xor` operation.
function bit.bxor( value, ... )
    local metatable = debug_getmetatable( value )
    return metatable and metatable.__bxor( value, ... )
end

--- [SHARED AND MENU] Swaps the byte order.
---@generic V
---@param value V: The value to be byte swapped.
---@return V: The byte swapped value.
function bit.bswap( value )
    local metatable = debug_getmetatable( value )
    return metatable and metatable.__bswap( value )
end

--- [SHARED AND MENU] Normalizes the specified value and clamps it in the range of a signed 32bit integer.
---@param value any: The value to be normalized.
---@return integer: The normalized value.
function bit.tobit( value )
    local metatable = debug_getmetatable( value )
    return metatable and metatable.__tobit( value )
end

--- [SHARED AND MENU] Returns the hexadecimal representation of the number with the specified digits.
---@param value any: The value to be converted.
---@param length integer: The number of digits. Defaults to 8.
---@return string: The hexadecimal representation.
function bit.tohex( value, length )
    local metatable = debug_getmetatable( value )
    return metatable and metatable.__tohex( value, length or 8 )
end

return bit
