local std = _G.gpm.std
---@class gpm.std.crypto
local crypto = std.crypto

local utf8 = std.string.utf8

--- [SHARED AND MENU]
---
--- The unicode library provides functions for the manipulation of unicode encoded UTF-8 strings.
---
---@class gpm.std.crypto.unicode
local unicode = crypto.unicode or {}
crypto.unicode = unicode

-- TODO: make this library

-- do

-- 	local raw_tonumber = std.raw.tonumber
-- 	local string_gsub = string.gsub

-- 	local function s( str )
-- 		return raw_tonumber( str, 16 )
-- 	end

-- 	function utf8.escape( str, isSequence )
-- 		---@diagnostic disable-next-line: redundant-return-value
-- 		return string_gsub( string_gsub( str, isSequence and "\\[uU]([0-9a-fA-F]+)" or "[uU]%+([0-9a-fA-F]+)", hex2char ), "\\.", escapeToChar ), nil
-- 	end

-- end
