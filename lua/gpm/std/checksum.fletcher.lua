local std = _G.gpm.std

---@class gpm.std.checksum
local checksum = std.checksum

local string = std.string
local string_len = string.len
local string_byte = string.byte

local bit = std.bit
local bit_bor = bit.bor
local bit_lshift = bit.lshift

--- [SHARED AND MENU]
---
--- Returns the Fletcher-16 checksum of the string.
---
--- See https://en.wikipedia.org/wiki/Fletcher%27s_checksum for the definition of the Fletcher-16 checksum.
---
---@param str string The string used to calculate the Fletcher-16 checksum.
---@return integer checksum The Fletcher-16 checksum, which is greater or equal to 0, and less than 2^16 (0x10000).
function checksum.fletcher16( str )
    local x, y = 0, 0

    for index = 1, string_len( str ), 1 do
        x = ( x + string_byte( str, index, index ) ) % 255
        y = ( y + x ) % 255
    end

    return bit_bor( bit_lshift( y, 8 ), x )
end

--- [SHARED AND MENU]
---
--- Returns the Fletcher-32 checksum of the string.
---
--- See https://en.wikipedia.org/wiki/Fletcher%27s_checksum for the definition of the Fletcher-32 checksum.
---
---@param str string The string used to calculate the Fletcher-32 checksum.
---@return integer checksum The Fletcher-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
function checksum.fletcher32( str )
    local x, y = 0, 0

    for index = 1, string_len( str ), 1 do
        x = ( x + string_byte( str, index, index ) ) % 65535
        y = ( y + x ) % 65535
    end

    return bit_bor( bit_lshift( y, 16 ), x )
end
