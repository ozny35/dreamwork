local _G = _G

local std = _G.gpm.std
---@class gpm.std.crypto
local crypto = std.crypto

local glua_util = _G.util

--- [SHARED AND MENU]
---
---
---
---@class gpm.std.crypto.json
local json = crypto.json or {}
crypto.json = json

if json.deserialize == nil then

    local util_JSONToTable = glua_util.JSONToTable or std.debug.fempty

    --- [SHARED AND MENU]
    ---
    --- Deserialize a JSON string into a table.
    ---
    ---@param str string The JSON string to deserialize.
    ---@return table | nil tbl The deserialized table or `nil` if the deserialization failed.
    function json.deserialize( str )
        return util_JSONToTable( str, true, true )
    end

end

json.serialize = json.serialize or glua_util.TableToJSON or function() return "" end
