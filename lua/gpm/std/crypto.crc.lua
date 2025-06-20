local _G = _G

local std = _G.gpm.std
---@class gpm.std.crypto
local crypto = std.crypto

local string = std.string
local string_len = string.len
local string_byte = string.byte

local bit = std.bit
local bit_band = bit.band
local bit_rshift = bit.rshift
local bit_bnot, bit_bxor = bit.bnot, bit.bxor

local glua_util = _G.util
if glua_util.CRC == nil then

    local crc32_lookup = {}

    for i = 0, 255, 1 do
        local crc = i

        for _ = 1, 8 do
            if bit_band( crc, 1 ) == 1 then
                crc = bit_bxor( bit_rshift( crc, 1 ), 0xedb88320 )
            else
                crc = bit_rshift( crc, 1 )
            end
        end

        crc32_lookup[ i ] = crc
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-32 checksum of a string.
    ---
    ---@param str string The string to calculate the CRC-32 checksum of.
    ---@return integer checksum The CRC-32 checksum of the string.
    ---@diagnostic disable-next-line: duplicate-set-field
    function crypto.crc32( str )
        local crc = 0xFFFFFFFF

        for i = 1, string_len( str ), 1 do
            crc = bit_bxor( bit_rshift( crc, 8 ), crc32_lookup[ bit_band( bit_bxor( crc, string_byte( str, i ) ), 0xFF ) ] )
        end

        return bit_band( bit_bnot( crc ), 0xffffffff )
    end

else

    crypto.crc32 = glua_util.CRC

end
