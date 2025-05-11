local _G = _G
local gpm = _G.gpm
local steamworks = _G.steamworks

---@class gpm.std
local std = gpm.std

local Future = std.Future
local isstring = std.isstring
local tonumber = std.tonumber
local Timer_wait = std.Timer.wait
local string_byte, string_sub = std.string.byte, std.string.sub

--- [SHARED AND MENU]
---
--- The Steam API library.
---
---@class gpm.std.steam
local steam = std.steam or {}
std.steam = steam

do

    local system = _G.system
    steam.time = steam.time or system.SteamTime
    steam.getAwayTime = steam.getAwayTime or system.UpTime
    steam.getAppTime = steam.getAppTime or system.AppTime

end

if steamworks ~= nil then

    local steamworks_RequestPlayerInfo = steamworks.RequestPlayerInfo

    --- Returns the name of the player with the given Steam ID.
    ---@param identifier gpm.std.steam.Identifier The SteamID64 of the player.
    ---@param timeout number | false | nil The timeout in seconds. Set to `false` to disable the timeout.
    ---@return string name The name of the player.
    ---@async
    function steam.getPlayerName( identifier, timeout )
        local f = Future()

        steamworks_RequestPlayerInfo( identifier:to64(), function( name )
            if isstring( name ) then
                ---@cast name string
                f:setResult( name )
            else
                f:setError( "failed to get player name for '" .. identifier:toSteam3() .. "', unknown error" )
            end
        end )

        if timeout ~= false then
            Timer_wait( function()
                if f:isPending() then
                    f:setError( "failed to get player name for '" .. identifier:toSteam3() .. "', timed out" )
                end
            end, timeout or 30 )
        end

        return f:await()
    end

    if std.MENU then

        local steamworks_Publish = steamworks.Publish

        --- [MENU]
        ---
        --- Publishes file to Steam Workshop.
        ---
        ---@param filePath string The absolute path to the addon file.
        ---@param imagePath string The absolute path to the image file.
        ---@param title string The title of the addon.
        ---@param description string? The description of the addon.
        ---@param tags string[] The tags for the addon.
        ---@param changeLog string? The changelog of the publication.
        ---@param timeout number | nil | false The timeout in seconds. Set to `false` to disable the timeout.
        ---@return string workshop_id The workshop ID of the published addon.
        ---@async
        function steam.publishItem( filePath, imagePath, title, description, tags, changeLog, timeout )
            -- TODO: make table structure instead arguments
            local f = Future()

            if string_byte( filePath, 1 ) == 0x2F --[[ / ]] then
                filePath = string_sub( filePath, 2 )
            else
                error( "invalid file path '" .. filePath .. "', expected absolute path" )
            end

            steamworks_Publish( filePath, imagePath, title, description or "", tags, function( wsid, errorMsg )
                if isstring( errorMsg ) then
                    f:setError( errorMsg )
                else
                    f:setResult( wsid )
                end
            end, nil, changeLog )

            if timeout ~= false then
                Timer_wait( function()
                    if f:isPending() then
                        f:setError( "failed to publish addon, timed out" )
                    end
                end, timeout or 30 )
            end

            return f:await()
        end

        --- [MENU]
        ---
        --- Updates an file on Steam Workshop.
        ---
        ---@param filePath string The absolute path to the addon file.
        ---@param imagePath string The absolute path to the image file.
        ---@param title string The title of the addon.
        ---@param description? string The description of the addon.
        ---@param tags string[] The tags for the addon.
        ---@param wsid string The workshop ID of the addon.
        ---@param changeLog string? The changelog of the publication.
        ---@param timeout number | nil | false The timeout in seconds. Set to `false` to disable the timeout.
        ---@return boolean success `true` if the update was successful, `false` otherwise.
        ---@async
        function steam.updateItem( filePath, imagePath, title, description, tags, wsid, changeLog, timeout )
            -- TODO: make table structure instead arguments
            local f = Future()

            if string_byte( filePath, 1 ) == 0x2F --[[ / ]] then
                filePath = string_sub( filePath, 2 )
            else
                error( "invalid file path '" .. filePath .. "', expected absolute path" )
            end

            steamworks_Publish( filePath, imagePath, title, description or "", tags, function( _, errorMsg )
                if isstring( errorMsg ) then
                    f:setError( errorMsg )
                else
                    f:setResult( true )
                end
            end, tonumber( wsid, 10 ), changeLog )

            if timeout ~= false then
                Timer_wait( function()
                    if f:isPending() then
                        f:setError( "failed to update addon '" .. wsid .. "', timed out" )
                    end
                end, timeout or 30 )
            end

            return f:await()
        end

    end

end
