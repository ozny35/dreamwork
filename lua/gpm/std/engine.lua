local _G = _G
local glua_engine, glua_game, glua_util, system_IsWindowed = _G.engine, _G.game, _G.util, _G.system.IsWindowed
local std = _G.gpm.std
local debug, CLIENT_SERVER, CLIENT_MENU, SERVER = std.debug, std.CLIENT_SERVER, std.CLIENT_MENU, std.SERVER

local library = {
    ["getTickCount"] = glua_engine.TickCount,
    ["getTickInterval"] = glua_engine.TickInterval
}

do

    local name, fn = debug.getupvalue( _G.Material, 1 )
    if name ~= "C_Material" then fn = debug.fempty end
    library.Material = fn or debug.fempty

end

if CLIENT_MENU then
    library.IsInWindow = system_IsWindowed
end

if CLIENT_SERVER then
    library.isDedicatedServer = glua_game.IsDedicated
    library.isSinglePlayer = glua_game.SinglePlayer
    library.getDifficulty = glua_game.GetSkillLevel
    library.getIPAddress = glua_game.GetIPAddress
    library.getTimeScale = glua_game.GetTimeScale

    library.getActivityName = glua_util.GetActivityNameByID
    library.getActivityID = glua_util.GetActivityIDByName

    library.getAnimEventName = glua_util.GetAnimEventNameByID
    library.getAnimEventID = glua_util.GetAnimEventIDByName

    library.getModelMeshes = glua_util.GetModelMeshes
    library.getModelInfo = glua_util.GetModelInfo

    library.precacheModel = glua_util.PrecacheModel
    library.precacheSound = glua_util.PrecacheSound

    -- TODO: Rework server name
    library.getServerName = _G.GetHostName
end

if SERVER then
    library.setDifficulty = glua_game.SetSkillLevel
    library.setTimeScale = glua_game.SetTimeScale

    -- TODO: Rework server name
    library.setServerName = function( str )

    end

    library.exit = glua_engine.CloseServer
end

return library
