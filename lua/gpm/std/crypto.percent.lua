local std = _G.gpm.std
---@class gpm.std.crypto
local crypto = std.crypto

local string = std.string
local string_len = string.len
local string_char, string_byte = string.char, string.byte

local table_concat = std.table.concat

--- [SHARED AND MENU]
---
--- Percent (URL/URI) encoding/decoding library.
---
--- Percent-encoding is a mechanism to encode 8-bit characters that have specific meaning in the context of URLs.
---
--- It is sometimes called **URL encoding**.
---
--- The encoding consists of substitution: A '%' followed by the hexadecimal representation of the ASCII value of the replace character.
---
--- See https://en.wikipedia.org/wiki/Percent-encoding & https://datatracker.ietf.org/doc/html/rfc3986#section-2.1
---
---@class gpm.std.crypto.percent
local percent = crypto.percent or {}
crypto.percent = percent

--- [SHARED AND MENU]
---
--- Creates a character whitelist for the given pattern.
---
---@param pattern_str string The pattern.
---@param base? table The base table, optional.
---@return table whitelist The character whitelist.
function percent.whitelist( pattern_str, base )
    local whitelist = {}

    if base ~= nil then
        for uint8 in std.raw.pairs( base ) do
            whitelist[ uint8 ] = true
        end
    end

    pattern_str = "[" .. pattern_str .. "]"

    for uint8 = 0, 255, 1 do
        local char_str = string_char( uint8 )
        if string.match( char_str, pattern_str ) then
            whitelist[ uint8 ] = true
        end
    end

    return whitelist
end

do

    local bytepack_writeHex8 = crypto.bytepack.writeHex8

    local default_whitelist = percent.whitelist( "%w%-_%.~" )

    --- [SHARED AND MENU]
    ---
    --- Encodes the specified string to percent encoding.
    ---
    ---@param raw_str string The string to encode.
    ---@param whitelist? table The character whitelist, optional.
    ---@return string percent_str The encoded string.
    function percent.encode( raw_str, whitelist )
        local segments, segment_count = {}, 0

        if whitelist == nil then
            whitelist = default_whitelist
        end

        local uint8_last

        for i = 1, string_len( raw_str ), 1 do
            local uint8 = string_byte( raw_str, i, i )

            if whitelist[ uint8 ] then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_char( uint8 )
            elseif uint8 == 0x0A --[[ "\n" ]] and uint8_last ~= 0x0D --[[ "\r" ]] then
                segment_count = segment_count + 1
                segments[ segment_count ] = "%0D%0A"
            elseif uint8 == 0x20 --[[ " " ]] then
                segment_count = segment_count + 1
                segments[ segment_count ] = "+"
            else
                segment_count = segment_count + 1
                segments[ segment_count ] = string_char( 0x25, bytepack_writeHex8( uint8 ) )
            end

            uint8_last = uint8
        end

        return table_concat( segments, "", 1, segment_count )
    end

    do

        local math_min = std.math.min

        ---@type table<integer, boolean>
        local hex_bytes = {
            [ 0x30 ] = true,
            [ 0x31 ] = true,
            [ 0x32 ] = true,
            [ 0x33 ] = true,
            [ 0x34 ] = true,
            [ 0x35 ] = true,
            [ 0x36 ] = true,
            [ 0x37 ] = true,
            [ 0x38 ] = true,
            [ 0x39 ] = true,
            [ 0x41 ] = true,
            [ 0x42 ] = true,
            [ 0x43 ] = true,
            [ 0x44 ] = true,
            [ 0x45 ] = true,
            [ 0x46 ] = true,
            [ 0x61 ] = true,
            [ 0x62 ] = true,
            [ 0x63 ] = true,
            [ 0x64 ] = true,
            [ 0x65 ] = true,
            [ 0x66 ] = true
        }

        --- [SHARED AND MENU]
        ---
        --- Validates the specified percent string.
        ---
        ---@param percent_str string The percent string to validate.
        ---@param whitelist? table The character whitelist, optional.
        ---@return boolean is_valid `true` if the percent string is valid, otherwise `false`.
        ---@return nil | string err_msg The error message.
        function percent.validate( percent_str, whitelist )
            local percent_str_length = string_len( percent_str ) + 1
            local position = 1

            if whitelist == nil then
                whitelist = default_whitelist
            end

            while position ~= percent_str_length do
                local uint8_0 = string_byte( percent_str, position, position )
                if uint8_0 == 0x25 --[[ "%" ]] then
                    local uint8_1, uint8_2 = string_byte( percent_str, position + 1, position + 2 )
                    if hex_bytes[ uint8_1 ] == nil or hex_bytes[ uint8_2 ] == nil then
                        return false, "string contains invalid characters"
                    end

                    position = math_min( position + 3, percent_str_length )
                elseif uint8_0 == 0x2B --[[ "+" ]] or whitelist[ uint8_0 ] ~= nil then
                    position = position + 1
                else
                    return false, "string contains invalid characters"
                end
            end

            return true
        end

    end

end

do

    local bytepack_readHex8 = crypto.bytepack.readHex8
    local math_min = std.math.min

    --- [SHARED AND MENU]
    ---
    --- Decodes the specified string from percent encoding.
    ---
    ---@param percent_str string The string to decode.
    ---@param ignore_spaces? boolean Ignore spaces, optional.
    ---@return string raw_str The decoded string.
    function percent.decode( percent_str, ignore_spaces )
        local position, str_length = 1, string_len( percent_str )
        local segments, segment_count = {}, 0

        while position ~= str_length do
            local uint8 = string_byte( percent_str, position, position )
            if uint8 == 0x25 --[[ "%" ]] then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_char( bytepack_readHex8( string_byte( percent_str, position + 1, position + 2 ) ) )
                position = math_min( position + 3, str_length )
            elseif uint8 == 0x2B --[[ "+" ]] and not ignore_spaces then
                segment_count = segment_count + 1
                segments[ segment_count ] = "\32"
                position = position + 1
            else
                segment_count = segment_count + 1
                segments[ segment_count ] = string_char( uint8 )
                position = position + 1
            end
        end

        return table_concat( segments, "", 1, segment_count )
    end

end
