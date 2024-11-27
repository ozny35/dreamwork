local _G = _G
local glua_engine = _G.engine

---@class gpm.std.gamemode
local gamemode = {
    getName = glua_engine.ActiveGamemode,
    getAll = glua_engine.GetGamemodes
}

--[[

    https://wiki.facepunch.com/gmod/Global.DeriveGamemode

]]

return gamemode
