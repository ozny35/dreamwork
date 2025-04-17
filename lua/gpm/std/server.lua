local _G = _G
local gpm = _G.gpm

---@class gpm.std
local std = gpm.std

local console_Variable = std.console.Variable
local engine_hookCatch = gpm.engine.hookCatch
local Hook = std.Hook

--- [SHARED AND MENU]
---
--- The game's server library.
---@class gpm.std.server
local server = std.server or {}

do

    local glua_engine = _G.engine
    server.getGamemodes = server.getGamemodes or glua_engine.GetGamemodes
    server.getGamemode = server.getGamemode or glua_engine.ActiveGamemode

end

if std.CLIENT and server.Tick == nil then

    --- [CLIENT]
    ---
    --- Called once every processed server frame during lag.
    local Tick = Hook( "server.Tick" )
    engine_hookCatch( "Think", Tick )
    server.Tick = Tick

end

if std.CLIENT_MENU then

    server.getFrameTime = _G.engine.ServerFrameTime

    local glua_permissions = _G.permissions
    server.grantPermission = glua_permissions.Grant
    server.revokePermission = glua_permissions.Revoke
    server.hasPermission = glua_permissions.IsGranted
    server.getAllPermissions = glua_permissions.GetAll

end

if std.MENU then

    --- [MENU]
    ---
    --- Called when the game details are updated.
    local GameDetails = std.Hook( "server.GameDetails" )
    engine_hookCatch( "GameDetails", GameDetails )
    server.GameDetails = GameDetails

end

do

    local game_GetIPAddress = _G.game.GetIPAddress -- missing in menu
    local string_match = std.string.match

    -- fallback
    if game_GetIPAddress == nil then
        function game_GetIPAddress()
            return "127.0.0.1:27015"
        end
    end

    server.getAddress = game_GetIPAddress

    --- [SHARED AND MENU]
    ---
    --- Returns the IP of the server.
    ---@return string: The IP of the server.
    function server.getIP()
        return string_match( game_GetIPAddress(), "(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?):" ) or "127.0.0.1"
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the port of the server.
    ---@return string: The port of the server.
    function server.getPort()
        return string_match( game_GetIPAddress(), ":(%d+)" ) or "27015"
    end

end

local sv_hostname = console_Variable( {
    name = "sv_hostname",
    description = "The publicly visible name of the server.",
    type = "string",
    flags = 8192
} )

do

    local hostname = console_Variable.get( "hostname", "string" )
    if hostname ~= nil then
        sv_hostname:set( hostname:get() )

        sv_hostname:addChangeCallback( "hostname", function( _, __, str )
            if hostname:get() == str then return end
            hostname:set( str )
        end )

        hostname:addChangeCallback( "sv_hostname", function( _, __, str )
            if sv_hostname:get() == str then return end
            sv_hostname:set( str )
        end )
    end

    --- [SHARED AND MENU]
    ---
    --- Gets the name of the server.
    ---@return string: The name of the server.
    function server.getName()
        ---@diagnostic disable-next-line: return-type-mismatch
        return sv_hostname:get()
    end

end

if std.SHARED then

    --- [SHARED]
    ---
    --- Checks if cheats are enabled.
    ---@return boolean: `true` if cheats are enabled, `false` if not.
    function server.isCheatsEnabled()
        return console_Variable.getBoolean( "sv_cheats" )
    end

    --- [SHARED]
    ---
    --- Enables or disables cheats.
    ---
    --- It gives all players access to commmands that would normally be abused or misused by players.
    ---@param bool boolean `true` to enable cheats, `false` to disable them.
    function server.setCheatsEnabled( bool )
        console_Variable.set( "sv_cheats", bool )
    end

    --- [SHARED]
    ---
    --- Checks if the server allows clients to run `lua_openscript_cl` and `lua_run_cl`.
    ---@return boolean: `true` if the server allows clients to run lua_openscript_cl and lua_run_cl, `false` if not.
    function server.isUserScriptsAllowed()
        return console_Variable.getBoolean( "sv_allowcslua" )
    end

end

if std.SERVER then

    server.log = _G.ServerLog

    --- [SERVER]
    ---
    --- Gets the download URL of the server.
    ---@return string: The download URL.
    function server.getDownloadURL()
        return console_Variable.getString( "sv_downloadurl" )
    end

    --- [SERVER]
    ---
    --- Sets the download URL of the server.
    ---@param str string The download URL to set.
    function server.setDownloadURL( str )
        console_Variable.set( "sv_downloadurl", str )
    end

    --- [SERVER]
    ---
    --- Checks if the server allows downloads.
    ---@return boolean: Whether the server allows downloads.
    function server.isDowloadAllowed()
        return console_Variable.getBoolean( "sv_allowdownload" )
    end

    --- [SERVER]
    ---
    --- Allow clients to download files from the server.
    ---@param bool boolean Whether the server allows downloads.
    function server.allowDownload( bool )
        console_Variable.set( "sv_allowdownload", bool )
    end

    --- [SERVER]
    ---
    --- Checks if the server allows uploads.
    ---@return boolean: Whether the server allows uploads.
    function server.isUploadAllowed()
        return console_Variable.getBoolean( "sv_allowupload" )
    end

    --- [SERVER]
    ---
    --- Allow clients to upload customizations files to the server.
    ---@param bool boolean Whether the server allows uploads.
    function server.allowUpload( bool )
        console_Variable.set( "sv_allowupload", bool )
    end

    ---@alias gpm.std.SERVER_REGION
    ---| number # The region of the world to report this server in.
    ---| `0`	US - East
    ---| `1`	US - West
    ---| `2`	South America
    ---| `3`	Europe
    ---| `4`	Asia
    ---| `5`	Australia
    ---| `6`	Middle East
    ---| `7`	Africa
    ---| `255`	World (default)

    --- [SERVER]
    ---
    --- Gets the console_Variable requested by the server browser to determine in which part of the world the server is located.
    ---@return gpm.std.SERVER_REGION: The region of the world to report this server in.
    function server.getRegion()
        return console_Variable.getNumber( "sv_region" )
    end

    --- [SERVER]
    ---
    --- Sets the console_Variable requested by the server browser to determine in which part of the world the server is located.
    ---@param region gpm.std.SERVER_REGION: The region of the world to report this server in.
    function server.setRegion( region )
        console_Variable.set( "sv_region", region )
    end

    --- [SERVER]
    ---
    --- Checks if the server is hidden from the master server.
    ---@return boolean: `true` if the server is hidden, `false` if not.
    function server.isHidden()
        return console_Variable.getBoolean( "hide_server" )
    end

    --- [SERVER]
    ---
    --- Hides/unhides the server from the master server.
    ---@param bool boolean `true` to hide the server, `false` to unhide it.
    function server.setHidden( bool )
        console_Variable.set( "hide_server", bool )
    end

    --- [SERVER]
    ---
    --- Allow clients to run `lua_openscript_cl` and `lua_run_cl`.
    ---@param bool boolean `true` to allow clients to run lua_openscript_cl and lua_run_cl, `false` to disallow them.
    function server.allowUserScripts( bool )
        console_Variable.set( "sv_allowcslua", bool )
    end

    --- [SERVER]
    ---
    --- Sets the name of the server.
    ---@param str string The name to set.
    function server.setName( str )
        return sv_hostname:set( str )
    end

    --[[

        TODO:

        - lua_networkvar_bytespertick: Allows you to control how many bytes are networked each tick.
            This should affect all NW functions. not NW2

        - gmod_sneak_attack: If set to 0 disables HL2's sneak attack, where headshotting
            NPCs that haven't seen the player would result in an instant kill.

        - sv_infinite_aux_power: This boolean ConVar enables/disables infinite suit power on the server. (For usual only on Half-Life 2 and modifications)
            when sv_infinite_aux_power is non-zero players will have infinitive suit power.

        https://wiki.facepunch.com/gmod/Blocked_ConCommands

        https://developer.valvesoftware.com/wiki/Console_Command_List

    --]]

    if server.getGamemodeTitle == nil then

        --- [SERVER]
        ---
        --- Returns the title of the gamemode in the server browser.
        ---@return string: The title of the gamemode.
        function server.getGamemodeTitle()
            return _G.hook.Call( "GetGameDescription" ) or "unknown"
        end

    end

    if server.setGamemodeTitile == nil then

        local title = nil

        engine_hookCatch( "GetGameDescription", function()
            return title
        end )

        --- [SERVER]
        ---
        --- Sets the title of the gamemode in the server browser.
        ---@param str string The title to set.
        function server.setGamemodeTitile( str )
            title = str
        end

    end

end

if std.MENU then

    local glua_serverlist = _G.serverlist
    local Timer_wait = std.Timer.wait
    local Future = std.Future

    do

        local serverlist_PingServer = glua_serverlist.PingServer

        --- [MENU]
        ---
        --- Queries a server for its information/ping.
        ---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
        ---@param timeout number? The timeout in seconds. Set to `false` to disable the timeout.
        ---@return gpm.std.server.Info info The server information.
        ---@async
        function server.ping( address, timeout )
            local f = Future()

            serverlist_PingServer( address, function( server_ping, server_name, gamemode_title, level_name, player_count, player_limit, bot_count, has_password, last_played_time, server_address, gamemode_name, gamemode_workshopid, is_anonymous_server, gmod_version, server_localization, gamemode_category )
                f:setResult( {
                    ping = server_ping,
                    name = server_name,
                    version = gmod_version,
                    level_name = level_name,
                    address = server_address,
                    country = server_localization,
                    last_played_time = last_played_time,
                    has_password = has_password,
                    is_anonymous = is_anonymous_server,
                    player_count = player_count,
                    player_limit = player_limit,
                    bot_count = bot_count,
                    human_count = player_count - bot_count,
                    gamemode_name = gamemode_name,
                    gamemode_title = gamemode_title,
                    gamemode_wsid = gamemode_workshopid,
                    gamemode_category = gamemode_category
                } )
            end )

            if timeout ~= false then
                Timer_wait( function()
                    if f:isPending() then
                        f:setError( "timed out" )
                    end
                end, timeout or 30 )
            end

            return f:await()
        end

    end

    do

        local serverlist_PlayerList = glua_serverlist.PlayerList

        --- [MENU]
        ---
        --- Queries a server for it's player list.
        ---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
        ---@param timeout number?: The timeout in seconds. Set to `false` to disable the timeout.
        ---@async
        function server.getPlayers( address, timeout )
            local f = Future()

            serverlist_PlayerList( address, function( data )
                if data == nil then
                    f:setError( "failed to get player list" )
                else
                    f:setResult( data )
                end
            end )

            if timeout ~= false then
                Timer_wait( function()
                    if f:isPending() then
                        f:setError( "timed out" )
                    end
                end, timeout or 30 )
            end

            return f:await()
        end

    end

    --- [MENU]
    ---
    --- Queries the master server for server list.
    ---@param data gpm.std.server.QueryData The query data to send to the master server.
    function server.getAll( data )
        ---@diagnostic disable-next-line: inject-field
        data.GameDir = data.directory
        data.directory = nil

        ---@diagnostic disable-next-line: inject-field
        data.Type = data.type
        data.type = nil

        ---@diagnostic disable-next-line: inject-field
        data.AppID = data.appid
        data.appid = nil

        ---@diagnostic disable-next-line: inject-field
        data.Callback = data.server_queried
        data.server_queried = nil

        ---@diagnostic disable-next-line: inject-field
        data.CallbackFailed = data.query_failed
        data.query_failed = nil

        ---@diagnostic disable-next-line: inject-field
        data.Finished = data.finished
        data.finished = nil

        glua_serverlist.Query( data )
    end

    server.isInBlacklist = _G.IsServerBlacklisted

    do

        local serverlist_IsCurrentServerFavorite = glua_serverlist.IsCurrentServerFavorite
        local serverlist_IsServerFavorite = glua_serverlist.IsServerFavorite

        --- [MENU]
        ---
        --- Returns true if the given server address is in their favorites.
        ---@param address string?: The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
        ---@return boolean: `true` if the given server is in player favorites, `false` if not.
        function server.isInFavorites( address )
            if address == nil then
                return serverlist_IsCurrentServerFavorite()
            else
                return serverlist_IsServerFavorite( address )
            end
        end

    end

    local serverlist_AddCurrentServerToFavorites = glua_serverlist.AddCurrentServerToFavorites

    do

        local serverlist_AddServerToFavorites = glua_serverlist.AddServerToFavorites

        --- [MENU]
        ---
        --- Adds the given server address to their favorites.
        ---@param address string?: The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
        function server.addToFavorites( address )
            if address == nil then
                ---@diagnostic disable-next-line: redundant-parameter
                serverlist_AddCurrentServerToFavorites( true )
            else
                serverlist_AddServerToFavorites( address )
            end
        end

    end

    do

        local serverlist_RemoveServerFromFavorites = glua_serverlist.RemoveServerFromFavorites

        --- [MENU]
        ---
        --- Removes the given server address from their favorites.
        ---@param address string?: The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
        function server.removeFromFavorites( address )
            if address == nil then
                ---@diagnostic disable-next-line: redundant-parameter
                serverlist_AddCurrentServerToFavorites( false )
            else
                serverlist_RemoveServerFromFavorites( address )
            end
        end

    end

end

return server
