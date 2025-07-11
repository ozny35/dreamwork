local std = _G.gpm.std
---@class gpm.std.encoding
local encoding = std.encoding

local table_concat = std.table.concat

local bytepack = std.binary.bytepack
local bytepack_readHex8 = bytepack.readHex8
local bytepack_writeHex8 = bytepack.writeHex8

local string = std.string
local string_len = string.len
local string_byte, string_char = string.byte, string.char

--- [SHARED AND MENU]
---
--- Base16 (hexadecimal) encoding/decoding library.
---
--- See https://en.wikipedia.org/wiki/Hexadecimal
---
---@class gpm.std.encoding.base16
local base16 = encoding.base16 or {}
encoding.base16 = base16

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
    local segments, segment_count = {}, 0

    for index = 1, string_len( base16_str ), 2 do
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
---@return nil | string err_msg The error message.
function base16.validate( base16_str )
    local base16_length = string_len( base16_str )
    if base16_length % 2 ~= 0 then
        return false, "string length must be even"
    end

    for index = 1, base16_length, 2 do
        if bytepack_readHex8( string_byte( base16_str, index, index + 1 ) ) == nil then
            return false, "string contains invalid characters"
        end
    end

    return true
end

do

    local string_sub = string.sub

    --- [SHARED AND MENU]
    ---
    --- Escapes the specified base16 string.
    ---
    --- Escape sequence: `\xXX`
    ---
    ---@param base16_str string The base16 string to escape.
    ---@return string base16_escape_str The escaped base16 string.
    function base16.escape( base16_str )
        local segments, segment_count = {}, 0

        for index = 1, string_len( base16_str ), 2 do
            segment_count = segment_count + 1
            segments[ segment_count ] = "\\x" .. string_sub( base16_str, index, index + 1 )
        end

        return table_concat( segments, "", 1, segment_count )
    end

    --- [SHARED AND MENU]
    ---
    --- Unescapes the specified base16 string.
    ---
    --- Unescape sequence: `\xXX`
    ---
    ---@param base16_escape_str string The base16 string to unescape.
    ---@return string base16_str The unescaped base16 string.
    function base16.unescape( base16_escape_str )
        local base16_escape_str_length = string_len( base16_escape_str )
        local index = 1

        local segments, segment_count = {}, 0

        repeat
            if string_byte( base16_escape_str, index, index ) == 0x5C --[[ "\" ]] and string_byte( base16_escape_str, index + 1, index + 1 ) == 0x78 --[[ "x" ]] then
                index = index + 2

                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( base16_escape_str, index, index + 1 )
                index = index + 2
            else
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( base16_escape_str, index, index )
                index = index + 1
            end
        until index > base16_escape_str_length

        return table_concat( segments, "", 1, segment_count )
    end

end
