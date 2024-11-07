local glua_game, glua_engine, CLIENT_SERVER, SERVER = ...


local library
if CLIENT_SERVER then
    library = {
        ["cleanup"] = glua_game.CleanUpMap,
        ["getEntity"] = glua_game.GetWorld,

        ["removeClientRagdolls"] = glua_game.RemoveRagdolls,

        -- TODO: Write level.change
        ["change"] = function( levelName )

        end,
        ["getName"] = glua_game.GetMap,
        ["startSpot"] = glua_game.StartSpot,
    }
else
    library = {
        ["getName"] = glua_game.GetMap
    }
end


if SERVER then
    library.getCounter = glua_game.GetGlobalCounter
    library.setCounter = glua_game.SetGlobalCounter
    library.setLightStyle = glua_engine.LightStyle
    library.getVersion = glua_game.GetMapVersion
    library.getLoadType = glua_game.MapLoadType
    library.getState = glua_game.GetGlobalState
    library.setState = glua_game.SetGlobalState
    library.getNextMap = glua_game.GetMapNext
end

return library
