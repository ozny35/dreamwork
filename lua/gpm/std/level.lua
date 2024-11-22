local _G = _G
local glua_game, glua_engine = _G.game, _G.engine

local std = _G.gpm.std
local CLIENT_SERVER, SERVER = std.CLIENT_SERVER, std.SERVER

---@class gpm.std.level
local level

if CLIENT_SERVER then
    level = {
        cleanup = glua_game.CleanUpMap,
        getEntity = glua_game.GetWorld,

        removeClientRagdolls = glua_game.RemoveRagdolls,

        getName = glua_game.GetMap,
        startSpot = glua_game.StartSpot,
    }

    local file_Exists = _G.file.Exists

    --- Checks if a map/level exists.
    ---@param name string The map/level name in maps/*.bsp folder.
    ---@param gamePath? string An optional argument specifying the search location, as an example for addon searches.
    ---@return boolean
    local function exists( name, gamePath )
        return file_Exists( "maps/" .. name .. ".bsp", gamePath or "GAME" )
    end

    level.exists = exists

    if SERVER then
        local glua_navmesh = _G.navmesh

        local navmesh = {
            getEditCursorPosition = glua_navmesh.GetEditCursorPosition,
            getPlayerSpawnName = glua_navmesh.GetPlayerSpawnName,
            setPlayerSpawnName = glua_navmesh.SetPlayerSpawnName,
            clearWalkableSeeds = glua_navmesh.ClearWalkableSeeds,
            addWalkableSeed = glua_navmesh.AddWalkableSeed,
            getGroundHeight = glua_navmesh.GetGroundHeight,
            isGenerating = glua_navmesh.IsGenerating,
            generate = glua_navmesh.BeginGeneration,
            isLoaded = glua_navmesh.IsLoaded,
            reset = glua_navmesh.Reset,
            load = glua_navmesh.Load,
            save = glua_navmesh.Save,
            area = std.setmetatable( {
                getNearest = glua_navmesh.GetNearestNavArea,
                getBlocked = glua_navmesh.GetBlockedAreas,
                getByIndex = glua_navmesh.GetNavAreaByID,
                getByPosition = glua_navmesh.GetNavArea,
                getCount = glua_navmesh.GetNavAreaCount,
                getMarked = glua_navmesh.GetMarkedArea,
                setMarked = glua_navmesh.SetMarkedArea,
                getAll = glua_navmesh.GetAllNavAreas,
                create = glua_navmesh.CreateNavArea,
                findInBox = glua_navmesh.FindInBox,
                find = glua_navmesh.Find,
            }, {
                __index = std.findMetatable( "CNavArea" )
            } ),
            ladder = std.setmetatable( {
                getByIndex = glua_navmesh.GetNavLadderByID,
                getMarked = glua_navmesh.GetMarkedLadder,
                setMarked = glua_navmesh.SetMarkedLadder,
                create = glua_navmesh.CreateNavLadder,
            }, {
                __index = std.findMetatable( "CNavLadder" )
            } )
        }

        --- Checks if a map/level navmesh exists.
        ---@param name string The map/level name in maps/*.nav folder.
        ---@param gamePath? string An optional argument specifying the search location, as an example for addon searches.
        ---@return boolean
        function navmesh.exists( name, gamePath )
            return file_Exists( "maps/" .. name .. ".nav", gamePath or "GAME" )
        end

        level.navmesh = navmesh

        local command_run = std.console.command.run

        --- It will end the current game, load the specified map and start a new game on it. Players are not kicked from the server.
        ---@param name string
        ---@return boolean isSuccessful
        function level.change( name )
            if exists( name ) then
                command_run( "changelevel", name )
                return true
            else
                return false
            end
        end
    end
else
    level = {
        getName = glua_game.GetMap
    }
end


if SERVER then
    level.getCounter = glua_game.GetGlobalCounter
    level.setCounter = glua_game.SetGlobalCounter
    level.setLightStyle = glua_engine.LightStyle
    level.getVersion = glua_game.GetMapVersion
    level.getLoadType = glua_game.MapLoadType
    level.getState = glua_game.GetGlobalState
    level.setState = glua_game.SetGlobalState
    level.getNextMap = glua_game.GetMapNext
    level.sendCommand = _G.hammer.SendCommand
end

return level
