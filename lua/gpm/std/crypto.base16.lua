local std = _G.gpm.std

---@class gpm.std.crypto
local crypto = std.crypto

local string = std.string
local string_len = string.len
local string_byte, string_char = string.byte, string.char

local bit = std.bit
local bit_band, bit_bor = bit.band, bit.bor
local bit_lshift, bit_rshift = bit.lshift, bit.rshift

local table = std.table
local table_concat = table.concat
local table_unpack = table.unpack

local math_min = std.math.min

--- [SHARED AND MENU]
---
--- Base16 (hexadecimal) encoding/decoding functions.
---
--- See https://en.wikipedia.org/wiki/Base16
---
---@class gpm.std.crypto.base16
local base16 = crypto.base16 or {}
crypto.base16 = base16

--- [SHARED AND MENU]
---
--- The base16 encoding/decoding alphabet.
---
---@class gpm.std.crypto.base16.Alphabet
---@field [1] table<integer, integer> The encoding map.
---@field [2] table<integer, integer> The decoding map.

do

    local table_remove = std.table.remove

    --- [SHARED AND MENU]
    ---
    --- Creates a base16 alphabet with encoding and decoding maps.
    ---
    ---@param alphabet_str string The alphabet string.
    ---@return gpm.std.crypto.base16.Alphabet alphabet The alphabet.
    function base16.alphabet( alphabet_str )
        if string_len( alphabet_str ) ~= 16 then
            error( "alphabet must be 16 characters long", 2 )
        end

        local encode_map = { string_byte( alphabet_str, 1, 16 ) }
        encode_map[ 0 ] = table_remove( encode_map, 1 )

        local decode_map = {}

        for i = 0, 15, 1 do
            local byte = encode_map[ i ]
            if decode_map[ byte ] == nil then
                decode_map[ byte ] = i
            elseif byte > 32 and byte < 127 then
                error( "alphabet characters must be unique, duplicate character: '" .. string_char( byte ) .. "' [" .. ( i + 1 ) .. "]", 2 )
            else
                error( "alphabet characters must be unique, duplicate character: '\\" .. byte .. "' [" .. ( i + 1 ) .. "]", 2 )
            end
        end

        return { encode_map, decode_map }
    end

end

local standard = base16.alphabet( "0123456789ABCDEF" )

--- [SHARED AND MENU]
---
--- Encodes the specified string to base16.
---
---@param raw_str string The string to encode.
---@param alphabet? gpm.std.crypto.base16.Alphabet The alphabet to use.
---@return string The encoded string.
function base16.encode( raw_str, alphabet )
    if alphabet == nil then
        alphabet = standard
    end

    local encode_map = alphabet[ 1 ]

    ---@type table<integer, integer>
    local bytes = {}

    ---@type integer
    local byte_count = 0

    for i = 1, string_len( raw_str ), 1 do
        local uint8 = string_byte( raw_str, i, i )

        byte_count = byte_count + 1
        bytes[ byte_count ] = encode_map[ bit_rshift( uint8, 4 ) ]

        byte_count = byte_count + 1
        bytes[ byte_count ] = encode_map[ bit_band( uint8, 0x0F ) ]
    end

    local segments, segment_count = {}, 0

    local position = 1

    while byte_count ~= 0 do
        local block_size = math_min( byte_count, 8000 )

        segment_count = segment_count + 1
        segments[ segment_count ] = string_char( table_unpack( bytes, position, block_size ) )

        byte_count = byte_count - block_size
        position = position + block_size
    end

    return table_concat( segments, "", 1, segment_count )
end

--- [SHARED AND MENU]
---
--- Decodes the specified base16 string to a string.
---
---@param base16_str string The base16 string to decode.
---@param alphabet? gpm.std.crypto.base16.Alphabet The alphabet to use.
---@return string str_raw The decoded string.
function base16.decode( base16_str, alphabet )
    local base16_length = string_len( base16_str )
    if base16_length % 2 ~= 0 then
        error( "base16 string length must be even", 2 )
    end

    if alphabet == nil then
        alphabet = standard
    end

    local decode_map = alphabet[ 2 ]

    ---@type table<integer, integer>
    local bytes = {}

    ---@type integer
    local byte_count = 0

    for i = 1, base16_length, 2 do
        byte_count = byte_count + 1
        local uint8_1, uint8_2 = string_byte( base16_str, i, i + 1 )
        bytes[ byte_count ] = bit_bor( bit_lshift( decode_map[ uint8_1 ], 4 ), decode_map[ uint8_2 ] )
    end

    local segments, segment_count = {}, 0

    local position = 1

    while byte_count ~= 0 do
        local block_size = math_min( byte_count, 8000 )

        segment_count = segment_count + 1
        segments[ segment_count ] = string_char( table_unpack( bytes, position, block_size ) )

        byte_count = byte_count - block_size
        position = position + block_size
    end

    return table_concat( segments, "", 1, segment_count )
end

--- [SHARED AND MENU]
---
--- Validates the specified base16 string.
---
---@param base16_str string The base16 string to validate.
---@param alphabet? gpm.std.crypto.base16.Alphabet The alphabet to use.
---@return boolean is_valid `true` if the base16 string is valid, otherwise `false`.
function base16.validate( base16_str, alphabet )
    local base16_length = string_len( base16_str )
    if base16_length % 2 ~= 0 then
        return false
    end

    if alphabet == nil then
        alphabet = standard
    end

    local decode_map = alphabet[ 2 ]

    for i = 1, base16_length, 2 do
        local uint8_1, uint8_2 = string_byte( base16_str, i, i + 1 )
        if decode_map[ uint8_1 ] == nil or decode_map[ uint8_2 ] == nil then
            return false
        end
    end

    return true
end
