local std = _G.gpm.std
---@class gpm.std.crypto
local crypto = std.crypto


local string = std.string
local string_len = string.len
local string_byte = string.byte

local bit = std.bit
local bit_bor = bit.bor
local bit_bxor = bit.bxor
local bit_lshift = bit.lshift
local bit_signfix = bit.signfix

--- [SHARED AND MENU]
---
--- Returns the Fletcher-16 checksum of the string.
---
--- See https://en.wikipedia.org/wiki/Fletcher%27s_checksum for the definition of the Fletcher-16 checksum.
---
---@param str string The string used to calculate the Fletcher-16 checksum.
---@return integer checksum The Fletcher-16 checksum, which is greater or equal to 0, and less than 2^16 (0x10000).
function crypto.fletcher16( str )
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
function crypto.fletcher32( str )
    local x, y = 0, 0

    for index = 1, string_len( str ), 1 do
        x = ( x + string_byte( str, index, index ) ) % 65535
        y = ( y + x ) % 65535
    end

    return bit_bor( bit_lshift( y, 16 ), x )
end

--- [SHARED AND MENU]
---
--- Returns the Fowler-Noll-Vo (FNV-0) [deprecated] hash of the string.
---
--- See https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function for the definition of the Fowler-Noll-Vo hash.
---
---@param str string The string used to calculate the Fowler-Noll-Vo hash.
---@return integer checksum The Fowler-Noll-Vo hash, which is greater or equal to 0, and less than 2^32 (0x100000000).
function crypto.fnv0( str )
    local hash = 0

    for index = 1, string_len( str ), 1 do
        hash = hash + bit_lshift( hash, 1 ) + bit_lshift( hash, 4 ) + bit_lshift( hash, 7 ) + bit_lshift( hash, 8 ) +bit_lshift( hash, 24 )
        hash = bit_bxor( hash, string_byte( str, index, index ) )
    end

    return bit_signfix( hash )
end

--- [SHARED AND MENU]
---
--- Returns the Fowler-Noll-Vo (FNV-1) hash of the string.
---
--- See https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function for the definition of the Fowler-Noll-Vo hash.
---
---@param str string The string used to calculate the Fowler-Noll-Vo hash.
---@return integer checksum The Fowler-Noll-Vo hash, which is greater or equal to 0, and less than 2^32 (0x100000000).
function crypto.fnv1( str )
    local hash = 0x811c9dc5

    for index = 1, string_len( str ), 1 do
        hash = hash + bit_lshift( hash, 1 ) + bit_lshift( hash, 4 ) + bit_lshift( hash, 7 ) + bit_lshift( hash, 8 ) +bit_lshift( hash, 24 )
        hash = bit_bxor( hash, string_byte( str, index, index ) )
    end

    return bit_signfix( hash )
end

--- [SHARED AND MENU]
---
--- Returns the Fowler-Noll-Vo (FNV-1a) hash of the string.
---
--- See https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function for the definition of the Fowler-Noll-Vo hash.
---
---@param str string The string used to calculate the Fowler-Noll-Vo hash.
---@return integer checksum The Fowler-Noll-Vo hash, which is greater or equal to 0, and less than 2^32 (0x100000000).
function crypto.fnv1a( str )
    local hash = 0x811c9dc5

    for index = 1, string_len( str ), 1 do
        hash = bit_bxor( hash, string_byte( str, index, index ) )
        hash = hash + bit_lshift( hash, 1 ) + bit_lshift( hash, 4 ) + bit_lshift( hash, 7 ) + bit_lshift( hash, 8 ) +bit_lshift( hash, 24 )
    end

    return bit_signfix( hash )
end
