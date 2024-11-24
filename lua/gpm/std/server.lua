local _G = _G
local std = _G.gpm.std

---@class gpm.std.server
local server = {}

if std.SERVER then
    server.log = _G.ServerLog
end

--[[

    https://wiki.facepunch.com/gmod/serverlist (std.server)
    https://wiki.facepunch.com/gmod/Global.CanAddServerToFavorites
    https://wiki.facepunch.com/gmod/Global.IsServerBlacklisted

    https://wiki.facepunch.com/gmod/permissions (std.server.permissions)

    https://wiki.facepunch.com/gmod/engine.ServerFrameTime

]]

return server
