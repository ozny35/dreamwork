local _G = _G

---@class dreamwork.std
local std = _G.dreamwork.std

--- [SHARED AND MENU]
---
--- Steam API library.
---
---@class dreamwork.std.steam
local steam = std.steam or {}
std.steam = steam

local glua_system = _G.system
if glua_system ~= nil then

    steam.getAwayTime = steam.getAwayTime or glua_system.UpTime or function() return 0 end
    steam.getAppTime = steam.getAppTime or glua_system.AppTime or steam.getAwayTime
    steam.time = steam.time or glua_system.SteamTime or std.time.now

end
