local _G = _G

---@class gpm.std
local std = _G.gpm.std

--- [SHARED AND MENU]
---
--- Steam API library.
---
---@class gpm.std.steam
local steam = std.steam or {}
std.steam = steam

local glua_system = _G.system
if glua_system ~= nil then

    steam.getAwayTime = steam.getAwayTime or glua_system.UpTime or function() return 0 end
    steam.getAppTime = steam.getAppTime or glua_system.AppTime or function() return 0 end
    steam.time = steam.time or glua_system.SteamTime or std.os.time

end
