local _G = _G
local std = _G.gpm.std
---@class gpm.std.crypto
local crypto = std.crypto

local glua_util = _G.util

--- [SHARED AND MENU]
---
--- The KeyValues format is used in the Source engine to store meta data for resources, scripts, materials, VGUI elements, and more..
---
---@class gpm.std.crypto.vdf
local vdf = crypto.vdf or {}
crypto.vdf = vdf

vdf.serialize = vdf.serialize or glua_util.TableToKeyValues
vdf.deserialize = vdf.deserialize or glua_util.KeyValuesToTable
