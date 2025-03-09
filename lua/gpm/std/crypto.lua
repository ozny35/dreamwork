local _G = _G
local gpm, util = _G.gpm, _G.util

---@class gpm.std
local std = gpm.std

--- [SHARED AND MENU]
--- crypto library
---@class gpm.std.crypto
local crypto = {}

---@class gpm.std.crypto.lzma
---@field PROPS_SIZE number The size of the lzma properties.
local lzma = {
    decompress = util.Decompress,
    compress = util.Compress,
    PROPS_SIZE = 5
}

crypto.lzma = lzma

do

    local string = std.string
    local string_len = string.len
    local string_byte = string.byte

    --- Returns the decompressed size of the given string.
    ---@param str string Compressed string.
    ---@return number: The decompressed size in bytes.
    function lzma.size( str )
        if string_len( str ) < 20 then return 0 end

        local size = 0
        for i = 6, 19 do
            size = size + string_byte( str, i ) * 2 ^ ( 8 * ( i - 6 ) )
        end

        return size
    end

end

--- The KeyValues format is used in the Source engine to store meta data for resources, scripts, materials, VGUI elements, and more..
---@class gpm.std.crypto.vdf
crypto.vdf = { deserialize = util.KeyValuesToTable, serialize = util.TableToKeyValues }

--- The JSON format is used to store data in a human-readable format.
---@class gpm.std.crypto.json
crypto.json = { deserialize = util.JSONToTable, serialize = util.TableToJSON }

--- The base64 format is used to encode data as a string of characters.
---@class gpm.std.crypto.base64
crypto.base64 = { decode = util.Base64Decode, encode = util.Base64Encode }

crypto.sha256 = util.SHA256
crypto.crc32 = util.CRC
crypto.sha1 = util.SHA1
crypto.md5 = util.MD5

return crypto
