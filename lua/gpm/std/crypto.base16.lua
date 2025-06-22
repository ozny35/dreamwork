local std = _G.gpm.std
---@class gpm.std.crypto
local crypto = std.crypto

local string_byte, string_char = std.string.byte, std.string.char
local bytepack_writeHex8 = crypto.bytepack.writeHex8
local bytepack_readHex8 = crypto.bytepack.readHex8
local table_concat = std.table.concat
local string_len = std.string.len

--- [SHARED AND MENU]
---
--- Base16 (hexadecimal) encoding/decoding functions.
---
--- See https://en.wikipedia.org/wiki/Hexadecimal
---
---@class gpm.std.crypto.base16
local base16 = crypto.base16 or {}
crypto.base16 = base16

--- [SHARED AND MENU]
---
--- Encodes the specified string to base16.
---
---@param raw_str string The string to encode.
---@return string The encoded string.
function base16.encode( raw_str )
    local segments, segment_count = {}, 0

    for index = 1, string_len( raw_str ), 1 do
        segment_count = segment_count + 1
        segments[ segment_count ] = string_char( bytepack_writeHex8( string_byte( raw_str, index, index ) ) )
    end

    return table_concat( segments, "", 1, segment_count )
end

--- [SHARED AND MENU]
---
--- Decodes the specified base16 string to a string.
---
---@param base16_str string The base16 string to decode.
---@return string str_raw The decoded string.
function base16.decode( base16_str )
    local base16_length = string_len( base16_str )
    if base16_length % 2 ~= 0 then
        error( "base16 (hexadecimal) string length must be even", 2 )
    end

    local segments, segment_count = {}, 0

    for index = 1, base16_length, 2 do
        segment_count = segment_count + 1
        segments[ segment_count ] = string_char( bytepack_readHex8( string_byte( base16_str, index, index + 1 ) ) )
    end

    return table_concat( segments, "", 1, segment_count )
end

--- [SHARED AND MENU]
---
--- Validates the specified base16 string.
---
---@param base16_str string The base16 string to validate.
---@return boolean is_valid `true` if the base16 string is valid, otherwise `false`.
function base16.validate( base16_str )
    local base16_length = string_len( base16_str )
    if base16_length % 2 ~= 0 then
        return false
    end

    for index = 1, base16_length, 2 do
        if bytepack_readHex8( string_byte( base16_str, index, index + 1 ) ) == nil then
            return false
        end
    end

    return true
end
