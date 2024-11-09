local _G, dofile, assert, error, pairs, tostring, type, string, table = ...
local string_byte = string.byte
local util = _G.util

return {
    ["deflate"] = dofile( "/gpm/3rd-party/deflate.lua", assert, error, pairs, tostring, type, string, table ),
    ["lzma"] = {
        ["decompress"] = util.Decompress,
        ["compress"] = util.Compress,
        ["size"] = function( str )
            if str == 0 then
                return 0
            end

            local size = 0
            for i = 6, 19 do
                size = size + string_byte( str, i ) * 2 ^ ( 8 * ( i - 6 ) )
            end

            return size
        end,
        ["PROPS_SIZE"] = 5
    },
    ["base64"] = {
        ["decode"] = util.Base64Decode,
        ["encode"] = util.Base64Encode
    },
    ["json"] = {
        ["deserialize"] = util.JSONToTable,
        ["serialize"] = util.TableToJSON
    },
    ["sha256"] = util.SHA256,
    ["crc32"] = util.CRC,
    ["sha1"] = util.SHA1,
    ["md5"] = util.MD5,
}
