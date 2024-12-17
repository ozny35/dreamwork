local _G = _G
local std, steamworks = _G.gpm.std, _G.steamworks
local Future, is_string, tonumber, timer_simple = std.Future, std.is.string, std.tonumber, std.timer.simple

local steam = {}

do

    local steamworks_RequestPlayerInfo = steamworks.RequestPlayerInfo

    --- Returns the name of the player with the given Steam ID.
    ---@return string: The name of the player.
    ---@async
    function steam.getPlayerName( sid64 )
        local f = Future()

        steamworks_RequestPlayerInfo( sid64, function( name )
            if is_string( name ) then
                ---@cast name string
                f:setResult( name )
            else
                f:setError( "failed to get player name for '" .. sid64 .. "', unknown error" )
            end
        end )

        timer_simple( 30, function()
            if f:isPending() then
                f:setError( "failed to get player name for '" .. sid64 .. "', timed out" )
            end
        end )

        return f:await()
    end

end

do

    local steamworks_Publish = steamworks.Publish

    --- Publishes file to Steam Workshop.
    ---@param filePath string: The absolute path to the addon file.
    ---@param imagePath string: The absolute path to the image file.
    ---@param title string: The title of the addon.
    ---@param description string?: The description of the addon.
    ---@param tags string[]: The tags for the addon.
    ---@param changeLog string?: The changelog of the publication.
    ---@return string: The workshop ID of the published addon.
    ---@async
    function steam.publishItem( filePath, imagePath, title, description, tags, changeLog )
        local f = Future()

        steamworks_Publish( filePath, imagePath, title, description or "", tags, function( wsid, errorMsg )
            if is_string( errorMsg ) then
                f:setError( errorMsg )
            else
                f:setResult( wsid )
            end
        end, nil, changeLog )

        return f:await()
    end

    --- Updates an file on Steam Workshop.
    ---@param filePath string: The absolute path to the addon file.
    ---@param imagePath string: The absolute path to the image file.
    ---@param title string: The title of the addon.
    ---@param description? string: The description of the addon.
    ---@param tags string[]: The tags for the addon.
    ---@param wsid string: The workshop ID of the addon.
    ---@param changeLog string?: The changelog of the publication.
    ---@param timeout number | nil | false: The timeout in seconds. Set to `false` to disable the timeout.
    ---@return boolean: `true` if the update was successful, `false` otherwise.
    ---@async
    function steam.updateItem( filePath, imagePath, title, description, tags, wsid, changeLog, timeout )
        local f = Future()

        steamworks_Publish( filePath, imagePath, title, description or "", tags, function( _, errorMsg )
            if is_string( errorMsg ) then
                f:setError( errorMsg )
            else
                f:setResult( true )
            end
        end, tonumber( wsid, 10 ), changeLog )

        if timeout ~= false then
            timer_simple( timeout or 30, function()
                if f:isPending() then
                    f:setError( "failed to update addon '" .. wsid .. "', timed out" )
                end
            end )
        end

        return f:await()
    end

end

-- TODO: https://github.com/Pika-Software/steam-api
-- ...

return steam
