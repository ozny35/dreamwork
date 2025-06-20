local _G = _G
local std = _G.gpm.std
---@class gpm.std.crypto
local crypto = std.crypto

local pack_readUInt32 = crypto.pack.readUInt32
local glua_util = _G.util

--- [SHARED AND MENU]
---
--- The lzma format is a lossless data compression algorithm that is used to compress large files.
---
---@class gpm.std.crypto.lzma
---@field PROPS_SIZE number The size of the lzma properties in bytes.
local lzma = crypto.lzma or { PROPS_SIZE = 5 }
crypto.lzma = lzma

lzma.compress = lzma.compress or glua_util.Compress or function() return "" end
lzma.decompress = lzma.decompress or glua_util.Decompress or lzma.compress

--- [SHARED AND MENU]
---
--- Returns the decompressed size of the given string.
---
---@param str string Compressed string.
---@return integer size The decompressed size in bytes.
function lzma.size( str )
    return pack_readUInt32( str, false, 6 ) or 0
end
