local _G = _G

local gpm = _G.gpm
local engine = gpm.engine

---@class gpm.std
local std = gpm.std

local debug = std.debug
local console_Variable = std.console.Variable

local glua_engine = _G.engine
local glua_game = _G.game
local glua_util = _G.util

--- [SHARED AND MENU]
---
--- The game library.
---
---@class gpm.std.game
local game = std.game or {}
std.game = game

game.getUptime = game.getUptime or _G.SysTime
game.addDebugInfo = game.addDebugInfo or _G.DebugInfo
game.getFrameTime = game.getFrameTime or _G.FrameTime
game.getTickCount = game.getTickCount or glua_engine.TickCount
game.getTickInterval = game.getTickInterval or glua_engine.TickInterval

do


    --- [SHARED AND MENU]
    ---
    --- Returns an array of tables corresponding to all games from which Garry's Mod supports mounting content.
    ---@return table: Array of tables with the following fields: `appid`, `title`, `folder`, `owned`, `installed`, `mounted`.
    ---@return integer: The length of the list.
    function game.getAll()
        local games = engine.games
        local lst, length = {}, 0

        for i = 1, engine.game_count, 1 do
            local data = games[ i ]
            length = length + 1
            lst[ length ] = {
                appid = data.depot,
                folder = data.folder,
                installed = data.installed,
                mounted = data.mounted,
                owned = data.owned,
                title = data.title
            }
        end

        return lst, length
    end

    local mounted_games = engine.mounted_games

    --- [SHARED AND MENU]
    ---
    --- Checks whether or not a game is currently mounted.
    ---
    ---@param folder_name string The folder name of the game.
    ---@return boolean: Returns `true` if the game is mounted, `false` otherwise.
    function game.isMounted( folder_name )
        if folder_name == "episodic" or folder_name == "ep2" or folder_name == "lostcoast" then
            folder_name = "hl2"
        end

        return mounted_games[ folder_name ] == true
    end

end

if std.MENU then

    local SetMounted = glua_game.SetMounted
    local tostring = std.tostring

    --- [MENU]
    ---
    --- Mounts or unmounts a game content to the client.
    ---
    ---@param appID number Steam AppID of the game.
    ---@param value boolean `true` to mount, `false` to unmount.
    function game.setMount( appID, value )
        SetMounted( tostring( appID ), true )
    end

end

do

    local fnName, fn = debug.getupvalue( _G.Material, 1 )
    if fnName ~= "C_Material" then fn = nil end
    game.Material = fn

end

if std.CLIENT_MENU then
    do

        ---@class gpm.std.game.demo
        local demo = {
            getTotalPlaybackTicks = glua_engine.GetDemoPlaybackTotalTicks,
            getPlaybackStartTick = glua_engine.GetDemoPlaybackStartTick,
            getPlaybackSpeed = glua_engine.GetDemoPlaybackTimeScale,
            getPlaybackTick = glua_engine.GetDemoPlaybackTick,
            isRecording = glua_engine.IsRecordingDemo,
            isPlaying = glua_engine.IsPlayingDemo
        }

        if std.MENU then
            demo.getFileDetails = _G.GetDemoFileDetails
        end

        game.demo = demo

    end

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

        game.achievement = achievement

    end

end

if std.CLIENT then
    game.getTimeoutInfo = _G.GetTimeoutInfo
end

if std.SHARED then

    game.getAbsoluteFrameTime = glua_engine.AbsoluteFrameTime
    game.isDedicatedServer = glua_game.IsDedicated
    game.isSinglePlayer = glua_game.SinglePlayer
    game.getDifficulty = glua_game.GetSkillLevel
    game.getTimeScale = glua_game.GetTimeScale
    game.getRealTime = _G.RealTime

    game.getActivityName = glua_util.GetActivityNameByID
    game.getActivityID = glua_util.GetActivityIDByName

    game.getAnimEventName = glua_util.GetAnimEventNameByID
    game.getAnimEventID = glua_util.GetAnimEventIDByName

    game.getModelMeshes = glua_util.GetModelMeshes
    game.getModelInfo = glua_util.GetModelInfo

    -- TODO: https://wiki.facepunch.com/gmod/Global.PrecacheSentenceFile
    -- TODO: https://wiki.facepunch.com/gmod/Global.PrecacheSentenceGroup

    game.precacheModel = glua_util.PrecacheModel
    game.precacheSound = glua_util.PrecacheSound

    if std.SERVER then
        game.precacheScene = _G.PrecacheScene
    end

    game.getFrameNumber = _G.FrameNumber

    --- [SHARED]
    ---
    --- Checks if Half-Life 2 aux suit power stuff is enabled.
    ---@return boolean: `true` if Half-Life 2 aux suit power stuff is enabled, `false` if not.
    function game.getHL2Suit()
        return console_Variable.getBoolean( "gmod_suit" )
    end

end

if std.SERVER then

    game.setDifficulty = glua_game.SetSkillLevel
    game.setTimeScale = glua_game.SetTimeScale
    game.print = _G.PrintMessage

    --- [SERVER]
    ---
    --- Enables Half-Life 2 aux suit power stuff.
    ---@param bool boolean `true` to enable Half-Life 2 aux suit power stuff, `false` to disable it.
    function game.setHL2Suit( bool )
        console_Variable.set( "gmod_suit", bool == true )
    end

    game.exit = glua_engine.CloseServer

end

if std.MENU then

    local steamworks_ApplyAddons = _G.steamworks.ApplyAddons
    local Command_run = std.console.Command.run

    --- Reloads addons.
    ---@param reloadType number?: The reload type.
    ---
    --- `0`: reload workshop addons
    ---
    --- `1`: reload legacy addons
    ---
    --- `2`: reload all addons
    function game.reloadAddons( reloadType )
        if reloadType == nil then
            steamworks_ApplyAddons()
        elseif reloadType == 1 then
            Command_run( "reload_legacy_addons" )
        elseif reloadType == 2 then
            Command_run( "reload_legacy_addons" )
            steamworks_ApplyAddons()
        end
    end

end

