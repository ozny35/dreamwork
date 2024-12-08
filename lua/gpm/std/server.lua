local _G = _G
local gpm = _G.gpm
local std = gpm.std
local variable = std.console.variable
local variable_setString = variable.setString

---@class gpm.std.server
local server = {}

if std.CLIENT_MENU then

    server.getFrameTime = _G.engine.ServerFrameTime

    local glua_permissions = _G.permissions
    server.grantPermission = glua_permissions.Grant
    server.revokePermission = glua_permissions.Revoke
    server.hasPermission = glua_permissions.IsGranted
    server.getAllPermissions = glua_permissions.GetAll

end

-- GM:GameDetails( server_name, loading_url, map_name, max_players, player_steamid64, gamemode_name )
if std.MENU then

    local function gameDetails( server_name, loading_url, map_name, max_players, player_steamid64, gamemode_name )
        std.hook.run( "GameDetails", server_name, loading_url, map_name, max_players, player_steamid64, gamemode_name )
    end

    if std.is.fn( _G.GameDetails ) then
        _G.GameDetails = gpm.detour.attach( _G.GameDetails, function( fn, ... )
            gameDetails( ... )
            return fn( ... )
        end )
    else
        _G.GameDetails = gameDetails
    end

end

do

    local game_GetIPAddress = _G.game.GetIPAddress -- Must be added in our custom main menu binary
    local string_match = _G.string.match

    server.getAddress = game_GetIPAddress

    --- [SHARED AND MENU] Returns the IP of the server.
    ---@return string: The IP of the server.
    function server.getIP()
        return string_match( game_GetIPAddress(), "(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?):" ) or "127.0.0.1"
    end

    --- [SHARED AND MENU] Returns the port of the server.
    ---@return string: The port of the server.
    function server.getPort()
        return string_match( game_GetIPAddress(), ":(%d+)" ) or "27015"
    end

end

if std.SHARED then

    --- [SHARED] Checks if cheats are enabled.
    ---@return boolean: `true` if cheats are enabled, `false` if not.
    function server.isCheatsEnabled()
        return variable.getBool( "sv_cheats" )
    end

    --- [SHARED] Enables or disables cheats.
    ---
    --- It gives all players access to commmands that would normally be abused or misused by players.
    ---@param bool boolean: `true` to enable cheats, `false` to disable them.
    function server.setCheatsEnabled( bool )
        variable.setBool( "sv_cheats", bool )
    end

end

if std.SERVER then

    server.log = _G.ServerLog

    --- [SERVER] Gets the download URL of the server.
    ---@return string: The download URL.
    function server.getDownloadURL()
        return variable.getString( "sv_downloadurl" )
    end

    --- [SERVER] Sets the download URL of the server.
    ---@param str string: The download URL to set.
    function server.setDownloadURL( str )
        variable_setString( "sv_downloadurl", str )
    end

    --- [SERVER] Checks if the server allows downloads.
    ---@return boolean: Whether the server allows downloads.
    function server.isDowloadAllowed()
        return variable.getBool( "sv_allowdownload" )
    end

    --- [SERVER] Allow clients to download files from the server.
    ---@param bool boolean: Whether the server allows downloads.
    function server.allowDownload( bool )
        variable.setBool( "sv_allowdownload", bool )
    end

    --- [SERVER] Checks if the server allows uploads.
    ---@return boolean: Whether the server allows uploads.
    function server.isUploadAllowed()
        return variable.getBool( "sv_allowupload" )
    end

    --- [SERVER] Allow clients to upload customizations files to the server.
    ---@param bool boolean: Whether the server allows uploads.
    function server.allowUpload( bool )
        variable.setBool( "sv_allowupload", bool )
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

    --- [SERVER] Gets the variable requested by the server browser to determine in which part of the world the server is located.
    ---@return gpm.std.SERVER_REGION: The region of the world to report this server in.
    function server.getRegion()
        return variable.getInt( "sv_region" )
    end

    --- [SERVER] Sets the variable requested by the server browser to determine in which part of the world the server is located.
    ---@param region gpm.std.SERVER_REGION: The region of the world to report this server in.
    function server.setRegion( region )
        variable.setInt( "sv_region", region )
    end

    --[[

        TODO:

        - hide_server: Whether the server should be hidden from the master server

        - sv_allowcslua: Allow clients on the server to run lua_openscript_cl and lua_run_cl.

        - sv_kickerrornum: Disconnects any client that exceeds this amount of client-side errors.
            A value of 0 disables this functionality.

        - lua_networkvar_bytespertick: Allows you to control how many bytes are networked each tick.
            This should affect all NW functions. not NW2

        - gmod_sneak_attack: If set to 0 disables HL2's sneak attack, where headshotting
            NPCs that haven't seen the player would result in an instant kill.

        - gmod_suit: Set to non zero to enable Half-Life 2 aux suit power stuff.

        - sv_infinite_aux_power: This boolean ConVar enables/disables infinite suit power on the server. (For usual only on Half-Life 2 and modifications)
            when sv_infinite_aux_power is non-zero players will have infinitive suit power.

    --]]

end

if std.MENU then

    local glua_serverlist = _G.serverlist
    local Future = std.Future

    do

        local serverlist_PingServer = glua_serverlist.PingServer
        local timer_Simple = _G.timer.Simple

        --- [MENU] Queries a server for its information/ping.
        ---@param address string: The address of the server. ( IP:Port like `127.0.0.1:27015` )
        ---@return ServerInfo: The server information.
        ---@async
        function server.ping( address )
            local f = Future()

            local finished = false
            serverlist_PingServer( address, function( server_ping, server_name, gamemode_title, map_name, player_count, player_limit, bot_count, has_password, last_played_time, server_address, gamemode_name, gamemode_workshopid, is_anonymous_server, gmod_version, server_localization, gamemode_category )
                finished = true

                f:setResult( {
                    ping = server_ping,
                    name = server_name,
                    map_name = map_name,
                    version = gmod_version,
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

            timer_Simple( 30, function()
                if finished then return end
                f:setError( "timed out" )
            end )

            return f:await()
        end

    end

    server.isInBlacklist = _G.IsServerBlacklisted

    do

        local serverlist_IsCurrentServerFavorite = glua_serverlist.IsCurrentServerFavorite
        local serverlist_IsServerFavorite = glua_serverlist.IsServerFavorite

        --- [MENU] Returns true if the given server address is in their favorites.
        ---@param address string?: The address of the server. ( IP:Port like `127.0.0.1:27015` )
        ---@return boolean: `true` if the given server is in player favorites, `false` if not.
        function server.isInFavorites( address )
            if address == nil then
                return serverlist_IsCurrentServerFavorite()
            else
                return serverlist_IsServerFavorite( address )
            end
        end

    end

    do

        local serverlist_AddCurrentServerToFavorites = glua_serverlist.AddCurrentServerToFavorites
        local serverlist_AddServerToFavorites = glua_serverlist.AddServerToFavorites

        --- [MENU] Adds the given server address to their favorites.
        ---@param address string?: The address of the server. ( IP:Port like `127.0.0.1:27015` )
        function server.addToFavorites( address )
            if address == nil then
                serverlist_AddCurrentServerToFavorites()
            else
                serverlist_AddServerToFavorites( address )
            end
        end

    end

    do

        local serverlist_RemoveServerFromFavorites = glua_serverlist.RemoveServerFromFavorites

        --- [MENU] Removes the given server address from their favorites.
        ---@param address string?: The address of the server. ( IP:Port like `127.0.0.1:27015` )
        function server.removeFromFavorites( address )
            if address == nil then
                serverlist_RemoveServerFromFavorites( server.getAddress() )
            else
                serverlist_RemoveServerFromFavorites( address )
            end
        end

    end

end

return server
