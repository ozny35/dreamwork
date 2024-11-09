local _G, debug, glua_engine, glua_game, system_IsWindowed, CLIENT_SERVER, CLIENT_MENU, SERVER = ...
local util = _G.util

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

    library.getActivityName = util.GetActivityNameByID
    library.getActivityID = util.GetActivityIDByName

    library.getAnimEventName = util.GetAnimEventNameByID
    library.getAnimEventID = util.GetAnimEventIDByName

    library.getModelMeshes = util.GetModelMeshes
    library.getModelInfo = util.GetModelInfo

    library.precacheModel = util.PrecacheModel
    library.precacheSound = util.PrecacheSound

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
