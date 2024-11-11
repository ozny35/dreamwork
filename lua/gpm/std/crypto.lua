local _G = _G
local util = _G.util

local crypto = {}
crypto.deflate = _G.include( "gpm/3rd-party/deflate.lua" )

--- @class gpm.std.crypto.lzma
--- @field PROPS_SIZE number The size of the lzma properties.
local lzma = { PROPS_SIZE = 5 }
crypto.lzma = lzma

lzma.decompress = util.Decompress
lzma.compress = util.Compress

do

    local string_byte = _G.string.byte

    --- Returns the decompressed size of the given string.
    --- @param str string Compressed string.
    --- @return number
    function lzma.size( str )
        if str == 0 then
            return 0
        end

        local size = 0
        for i = 6, 19 do
            size = size + string_byte( str, i ) * 2 ^ ( 8 * ( i - 6 ) )
        end

        return size
    end

end

crypto.json = { deserialize = util.JSONToTable, serialize = util.TableToJSON }
crypto.base64 = { decode = util.Base64Decode, encode = util.Base64Encode }
crypto.sha256 = util.SHA256
crypto.crc32 = util.CRC
crypto.sha1 = util.SHA1
crypto.md5 = util.MD5

return crypto
