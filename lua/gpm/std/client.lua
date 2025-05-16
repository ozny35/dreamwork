local _G = _G
local gpm = _G.gpm

---@class gpm.std
local std = gpm.std

--- [CLIENT AND MENU]
---
--- The game's client library.
---
---@class gpm.std.client
---@field entity gpm.std.Player | nil The local player entity object that is associated with the client.
local client = std.client or {}
std.client = client

client.getServerTime = client.getServerTime or _G.CurTime

if _G.render ~= nil then

    local glua_render = _G.render

    do

        local directx_level = glua_render.GetDXLevel() * 0.1
        client.SupportedDirectX = directx_level
        client.SupportsHDR = directx_level >= 8

    end

    client.SupportsPixelShadersV1 = glua_render.SupportsPixelShaders_1_4()
    client.SupportsPixelShadersV2 = glua_render.SupportsPixelShaders_2_0()
    client.SupportedVertexShaders = glua_render.SupportsVertexShaders_2_0()

end

if std.CLIENT then

    do

        local ENTITY = std.debug.findmetatable( "Entity" ) ---@cast ENTITY Entity
        local ENTITY_IsValid = ENTITY.IsValid
        local LocalPlayer = _G.LocalPlayer

        std.setmetatable( client, {
            __index = function( _, key )
                if key == "entity" then
                    local entity = LocalPlayer()
                    if entity and ENTITY_IsValid( entity ) then
                        local player = gpm.transducers[ entity ]
                        client.entity = player
                        return player
                    end
                end

                return nil
            end
        } )

    end

    -- https://music.youtube.com/watch?v=78PjJ1soEZk (01:00)
    client.screenShake = _G.util.ScreenShake
    client.getViewEntity = _G.GetViewEntity
    client.getEyeVector = _G.EyeVector
    client.getEyeAngles = _G.EyeAngles
    client.getEyePosition = _G.EyePos

    do

        local voice_chat_state = false

        gpm.engine.hookCatch( "PlayerStartVoice", function( entity )
            if entity ~= client.entity then return end
            voice_chat_state = true
        end )

        gpm.engine.hookCatch( "PlayerEndVoice", function( entity )
            if entity ~= client.entity then return end
            voice_chat_state = false
        end )

        function client.getVoiceChat()
            return voice_chat_state
        end

    end

    client.setVoiceChat = _G.permissions.EnableVoiceChat

end

if std.MENU then
    client.isConnected = _G.IsInGame
    client.isConnecting = _G.IsInLoading
else

    --- [CLIENT AND MENU]
    ---
    --- Checks if the client is connected to the server.
    ---
    --- NOTE: It always returns `true` on the client.
    ---@return boolean bool The `true` if connected, `false` if not.
    ---@diagnostic disable-next-line: duplicate-set-field
    function client.isConnected() return true end

    --- [CLIENT AND MENU]
    ---
    --- Checks if the client has connected to the server (looks at the loading screen).
    ---
    --- NOTE: It always returns `false` on the client.
    ---@return boolean bool The `true` if connecting, `false` if not.
    ---@diagnostic disable-next-line: duplicate-set-field
    function client.isConnecting() return false end

end

do

    local console = std.console
    local console_Command = console.Command
    local console_Variable = console.Variable

    if std.CLIENT then

        --- [CLIENT AND MENU]
        ---
        --- Disconnects the client from the server.
        ---
        function client.disconnect()
            console_Command.run( "disconnect" )
        end

    else

        --- [CLIENT AND MENU]
        ---
        --- Disconnects the client from the server.
        ---
        function client.disconnect()
            std.menu.run( "Disconnect" )
        end

    end

    --- [CLIENT AND MENU]
    ---
    --- Retry connection to last server.
    function client.retry()
        console_Command.run( "retry" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Take a screenshot.
    ---@param quality integer The quality of the screenshot (0-100), only used if `useTGA` is `false`.
    ---@param fileName string The name of the screenshot.
    function client.screencap( quality, fileName )
        if std.menu.visible then
            return false, "The menu is open, can't take a screenshot."
        end

        if fileName == nil then
            fileName = std.level.getName()
        end

        local files = file.find( "/screenshots/" .. fileName .. "*.jpg" )
        local last_one, count = files[ #files ], nil
        if last_one == nil then
            count = 0
        else
            count = ( std.tonumber( std.string.sub( std.file.path.stripExtension( last_one, false ), #fileName + 2 ), 10 ) or 0 ) + 1
        end

        fileName = std.string.format( "%s_%04d", fileName, count )
        console_Command.run( "jpeg", fileName, quality or 90 )
        return true, "/screenshots/" .. fileName .. ".jpg"
    end

    if std.CLIENT then
        client.connect = client.connect or _G.permissions.AskToConnect
    else
        client.connect = client.connect or _G.JoinServer or _G.permissions.Connect
    end

    if client.connect == nil then

        --- [CLIENT AND MENU]
        ---
        --- Connects client to the specified server.
        ---
        ---@param address string? The address of the server. ( IP:Port like `127.0.0.1:27015` )
        ---@diagnostic disable-next-line: duplicate-set-field
        function client.connect( address )
            console_Command.run( "connect", address )
        end

    end

    --- [CLIENT AND MENU]
    ---
    --- Checks if close captions are enabled.
    ---
    ---@return boolean result `true` if close captions are enabled, `false` otherwise.
    function game.getCloseCaptions()
        console_Variable.getBoolean( "closecaption" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Enables or disables close captions.
    ---
    ---@param enable boolean `true` to enable close captions, `false` to disable them.
    function game.setCloseCaptions( enable )
        console_Variable.set( "closecaption", enable )
    end

end
