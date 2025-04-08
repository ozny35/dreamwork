local _G = _G
local gpm, glua_util = _G.gpm, _G.util

---@class gpm.std
local std = gpm.std

local string = std.string
local string_byte, string_len = string.byte, string.len

--- [SHARED AND MENU]
---
--- crypto library
---@class gpm.std.crypto
local crypto = {}

---@class gpm.std.crypto.lzma
---@field PROPS_SIZE number The size of the lzma properties.
local lzma = {
    decompress = glua_util.Decompress,
    compress = glua_util.Compress,
    PROPS_SIZE = 5
}

crypto.lzma = lzma

--- Returns the decompressed size of the given string.
---@param str string Compressed string.
---@return number size The decompressed size in bytes.
function lzma.size( str )
    if string_len( str ) < 20 then return 0 end

    local size = 0
    for i = 6, 19 do
        size = size + string_byte( str, i ) * 2 ^ ( 8 * ( i - 6 ) )
    end

    return size
end

--- The KeyValues format is used in the Source engine to store meta data for resources, scripts, materials, VGUI elements, and more..
---@class gpm.std.crypto.vdf
crypto.vdf = { deserialize = glua_util.KeyValuesToTable, serialize = glua_util.TableToKeyValues }

--- The JSON format is used to store data in a human-readable format.
---@class gpm.std.crypto.json
crypto.json = { deserialize = glua_util.JSONToTable, serialize = glua_util.TableToJSON }

--- The base64 format is used to encode data as a string of characters.
---@class gpm.std.crypto.base64
crypto.base64 = { decode = glua_util.Base64Decode, encode = glua_util.Base64Encode }

crypto.sha256 = glua_util.SHA256
crypto.crc32 = glua_util.CRC
crypto.sha1 = glua_util.SHA1
crypto.md5 = glua_util.MD5

--- Calculate the Adler-32 checksum of the string.
---
--- See RFC1950 Page 9 https://tools.ietf.org/html/rfc1950 for the definition of Adler-32 checksum.
---@param str string The string used to calculate the Adler-32 checksum.
---@return number checksum The Adler-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
function crypto.adler32( str )
    local length = string_len( str )
    local i, a, b = 1, 1, 0

    while ( i <= length - 15 ) do
        local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16 = string_byte( str, i, i + 15 )
        b = ( b + 16 * a + 16 * x1 + 15 * x2 + 14 * x3 + 13 * x4 + 12 * x5 + 11 * x6 + 10 * x7 + 9 * x8 + 8 * x9 + 7 * x10 + 6 * x11 + 5 * x12 + 4 * x13 + 3 * x14 + 2 * x15 + x16 ) % 65521
        a = ( a + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11 + x12 + x13 + x14 + x15 + x16 ) % 65521
        i = i + 16
    end

    while ( i <= length ) do
        local x = string_byte( str, i, i )
        a = ( a + x ) % 65521
        b = ( b + a ) % 65521
        i = i + 1
    end

    return ( b * 0x10000 + a ) % 0x100000000
end

return crypto
