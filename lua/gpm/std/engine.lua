local _G = _G
local glua_engine, glua_game, glua_util, system_IsWindowed = _G.engine, _G.game, _G.util, _G.system.IsWindowed
local std = _G.gpm.std
local debug, CLIENT_SERVER, CLIENT_MENU, SERVER = std.debug, std.CLIENT_SERVER, std.CLIENT_MENU, std.SERVER

local engine = {
    ["getTickCount"] = glua_engine.TickCount,
    ["getTickInterval"] = glua_engine.TickInterval
}

do

    local fnName, fn = debug.getupvalue( _G.Material, 1 )
    if fnName ~= "C_Material" then fn = nil end
    engine.Material = fn

end

if CLIENT_MENU then
    engine.IsInWindow = system_IsWindowed

    do

        local glua_achievements = _G.achievements
        local achievements_Count, achievements_GetName, achievements_GetDesc, achievements_GetCount, achievements_GetGoal, achievements_IsAchieved = glua_achievements.Count, glua_achievements.GetName, glua_achievements.GetDesc, glua_achievements.GetCount, glua_achievements.GetGoal, glua_achievements.IsAchieved

        --- Returns information about an achievement (name, description, value, etc.)
        ---@param id number The ID of achievement to retrieve name of. Note: IDs start from 0, not 1.
        ---@return table | nil: Returns nil if the ID is invalid.
        local function get( id )
            local goal = achievements_GetGoal( id )
            if goal == nil then return nil end

            local isAchieved = achievements_IsAchieved( id )

            return {
                name = achievements_GetName( id ),
                description = achievements_GetDesc( id ),
                value = isAchieved and goal or achievements_GetCount( id ),
                achieved = isAchieved,
                goal = goal
            }
        end

        local achievement = {
            getCount = achievements_Count,
            get = get
        }

        --- Checks if an achievement with the given ID exists.
        ---@param id number
        ---@return boolean: Returns true if the achievement exists.
        function achievement.exists( id )
            return achievements_IsAchieved( id ) ~= nil
        end

        --- Returns information about all achievements.
        ---@return table: The list of all achievements.
        ---@return number: The count of achievements.
        function achievement.getAll()
            local tbl, count = {}, achievements_Count()
            for index = 0, count - 1 do
                tbl[ index + 1 ] = get( index )
            end

            return tbl, count
        end

        engine.achievement = achievement

    end

end

if CLIENT_SERVER then
    engine.isDedicatedServer = glua_game.IsDedicated
    engine.isSinglePlayer = glua_game.SinglePlayer
    engine.getDifficulty = glua_game.GetSkillLevel
    engine.getIPAddress = glua_game.GetIPAddress
    engine.getTimeScale = glua_game.GetTimeScale

    engine.getActivityName = glua_util.GetActivityNameByID
    engine.getActivityID = glua_util.GetActivityIDByName

    engine.getAnimEventName = glua_util.GetAnimEventNameByID
    engine.getAnimEventID = glua_util.GetAnimEventIDByName

    engine.getModelMeshes = glua_util.GetModelMeshes
    engine.getModelInfo = glua_util.GetModelInfo

    engine.precacheModel = glua_util.PrecacheModel
    engine.precacheSound = glua_util.PrecacheSound

    -- TODO: Rework server name
    engine.getServerName = _G.GetHostName
end

if SERVER then
    engine.setDifficulty = glua_game.SetSkillLevel
    engine.setTimeScale = glua_game.SetTimeScale

    -- TODO: Rework server name
    engine.setServerName = function( str )

    end

    engine.exit = glua_engine.CloseServer
end

return engine
