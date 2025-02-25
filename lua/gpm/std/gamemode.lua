local _G = _G
local glua_engine = _G.engine

local std = _G.gpm.std

---@class gpm.std.gamemode
local gamemode = {
    getName = glua_engine.ActiveGamemode,
    getAll = glua_engine.GetGamemodes,
    derive = _G.DeriveGamemode
}

-- TODO: make gamemode class and gamemode handler

return gamemode
