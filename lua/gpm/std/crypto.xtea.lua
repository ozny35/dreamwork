-- Based on https://github.com/somesocks/lua-lockbox/blob/master/lockbox/cipher/xtea.lua
local std = _G.gpm.std
local bit = std.bit

local bit_band, bit_bxor, bit_lshift, bit_rshift = bit.band, bit.bxor, bit.lshift, bit.rshift
local string_char, string_byte = std.string.char, std.string.byte

---@class gpm.std.crypto
local crypto = std.crypto

--- [SHARED AND MENU]
---
--- XTEA encryption functions.
---@class gpm.std.crypto.xtea
local xtea = {}
crypto.xtea = xtea

local str2key, data2word
do

    local bit_bor = bit.bor

    ---@param str string
    ---@return integer[]
    function str2key( str )
        local b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16 = string_byte( str, 1, 16 )

        if b16 == nil then
            std.error( "insufficient key length", 3 )
        end

        return {
            [ 0 ] = bit_bor( bit_lshift( bit_bor( bit_lshift( bit_bor( bit_lshift( b1, 8 ), b2 ), 8 ), b3 ), 8 ), b4 ),
            [ 1 ] = bit_bor( bit_lshift( bit_bor( bit_lshift( bit_bor( bit_lshift( b5, 8 ), b6 ), 8 ), b7 ), 8 ), b8 ),
            [ 2 ] = bit_bor( bit_lshift( bit_bor( bit_lshift( bit_bor( bit_lshift( b9, 8 ), b10 ), 8 ), b11 ), 8 ), b12 ),
            [ 3 ] = bit_bor( bit_lshift( bit_bor( bit_lshift( bit_bor( bit_lshift( b13, 8 ), b14 ), 8 ), b15 ), 8 ), b16 )
        }
    end

    ---@param data string The block of data to convert.
    ---@param start_position? integer The start position of the block of data.
    ---@param big_endian? boolean Whether the block of data is big-endian.
    ---@return integer y
    ---@return integer z
    function data2word( data, start_position, big_endian )
        if start_position == nil then
            start_position = 1
        end

        local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( data, start_position, start_position + 7 )

        if b8 == nil then
            std.error( "insufficient data length", 3 )
        end

        if not big_endian then
            b8, b7, b6, b5, b4, b3, b2, b1 = b1, b2, b3, b4, b5, b6, b7, b8
        end

        return bit_bor( bit_lshift( bit_bor( bit_lshift( bit_bor( bit_lshift( b1, 8 ), b2 ), 8 ), b3 ), 8 ), b4 ),
            bit_bor( bit_lshift( bit_bor( bit_lshift( bit_bor( bit_lshift( b5, 8 ), b6 ), 8 ), b7 ), 8 ), b8 )
    end

end

---@param y integer
---@param z integer
---@param big_endian? boolean
---@return string
local function word2data( y, z, big_endian )
    local b8 = bit_band( z, 0xFF )
    z = bit_rshift( z, 8 )

    local b7 = bit_band( z, 0xFF )
    z = bit_rshift( z, 8 )

    local b6 = bit_band( z, 0xFF )
    z = bit_rshift( z, 8 )

    local b5 = bit_band( z, 0xFF )

    local b4 = bit_band( y, 0xFF )
    y = bit_rshift( y, 8 )

    local b3 = bit_band( y, 0xFF )
    y = bit_rshift( y, 8 )

    local b2 = bit_band( y, 0xFF )
    y = bit_rshift( y, 8 )

    local b1 = bit_band( y, 0xFF )

    if not big_endian then
        b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
    end

    return string_char( b1, b2, b3, b4, b5, b6, b7, b8 )
end

--- [SHARED AND MENU]
---
--- Encrypts a block of data using XTEA.
---
--- ATTENTION:
---
---     Block length is always 8 bytes.
---     Key length is always 16 bytes.
---
--- See https://en.wikipedia.org/wiki/XTEA for the algorithm.
---
---@param key string The key to encrypt with, must be 16 bytes.
---@param data string The block of data to encrypt, must be 8 bytes.
---@param start_position? integer The start position of the block of data.
---@param big_endian? boolean Whether the block of data is big-endian.
---@param num_rounds? integer The number of rounds to encrypt the block of data.
---@return string encrypted The encrypted block of data.
function xtea.encrypt( key, data, start_position, big_endian, num_rounds )
    local y, z = data2word( data, start_position, true )
    local k = str2key( key )
    local sum = 0

    if num_rounds == nil then
        num_rounds = 32
    end

    for _ = 1, num_rounds do
        y = bit_band( y + bit_bxor( bit_bxor( bit_lshift( z, 4 ), bit_rshift( z, 5 ) ) + z, sum + k[ bit_band( sum, 3 ) ] ), 0xFFFFFFFF )
        sum = bit_band( sum + 0x9e3779b9, 0xFFFFFFFF )
        z = bit_band( z + bit_bxor( bit_bxor( bit_lshift( y, 4 ), bit_rshift( y, 5 ) ) + y, sum + k[ bit_band( bit_rshift( sum, 11 ), 3 ) ] ), 0xFFFFFFFF )
    end

    return word2data( y, z, big_endian )
end

--- [SHARED AND MENU]
---
--- Decrypts a block of data using XTEA.
---
--- ATTENTION:
---
---     Block length is always 8 bytes.
---     Key length is always 16 bytes.
---
--- See https://en.wikipedia.org/wiki/XTEA for the algorithm.
---
---@param key string The key to decrypt with, must be 16 bytes.
---@param data string The block of data to decrypt, must be 8 bytes.
---@param start_position? integer The start position of the block of data.
---@param big_endian? boolean Whether the block of data is big-endian.
---@param num_rounds? integer The number of rounds to decrypt the block of data.
---@return string decrypted The decrypted block of data.
function xtea.decrypt( key, data, start_position, big_endian, num_rounds )
    local y, z = data2word( data, start_position, big_endian )
    local k = str2key( key )

    if num_rounds == nil then
        num_rounds = 32
    end

    local sum = bit_band( 0x9e3779b9 * num_rounds, 0xFFFFFFFF )

    for _ = 1, num_rounds do
        z = bit_band( z + 0x100000000 - bit_bxor( bit_bxor( bit_lshift( y, 4 ), bit_rshift( y, 5 ) ) + y, sum + k[ bit_band( bit_rshift( sum, 11 ), 3 ) ] ), 0xFFFFFFFF )
        sum = bit_band( sum + 0x100000000 - 0x9e3779b9, 0xFFFFFFFF )
        y = bit_band( y + 0x100000000 - bit_bxor( bit_bxor( bit_lshift( z, 4 ), bit_rshift( z, 5 ) ) + z, sum + k[ bit_band( sum, 3 ) ] ), 0xFFFFFFFF )
    end

    return word2data( y, z, true )
end
