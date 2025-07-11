local std = _G.gpm.std
---@class gpm.std.encoding
local encoding = std.encoding

local string = std.string
local utf8 = std.encoding.utf8

--- [SHARED AND MENU]
---
--- Punycode encoding/decoding library.
---
--- See https://en.wikipedia.org/wiki/Punycode
---
---@class gpm.std.encoding.punycode
local punycode = encoding.punycode or {}
encoding.punycode = punycode

