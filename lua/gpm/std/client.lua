local _G = _G
local gpm = _G.gpm
local std = gpm.std

--- [CLIENT AND MENU]
---
--- The game's client library.
---@class gpm.std.client
---@field entity gpm.std.Player | nil The local player entity object that is associated with the client.
local client = std.client or {}

if _G.gui ~= nil then
    client.openURL = _G.gui.OpenURL
end

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
    function client.isConnected() return true end

    --- [CLIENT AND MENU]
    ---
    --- Checks if the client has connected to the server (looks at the loading screen).
    ---
    --- NOTE: It always returns `false` on the client.
    ---@return boolean bool The `true` if connecting, `false` if not.
    function client.isConnecting() return false end

end

do

    local command_run = std.console.Command.run

    --- [CLIENT AND MENU]
    ---
    --- Disconnect game from server.
    function client.disconnect()
        command_run( "disconnect" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Retry connection to last server.
    function client.retry()
        command_run( "retry" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Take a screenshot.
    ---@param quality integer The quality of the screenshot (0-100), only used if `useTGA` is `false`.
    ---@param fileName string The name of the screenshot.
    function client.screencap( quality, fileName )
        if std.menu.isVisible() then
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
        command_run( "jpeg", fileName, quality or 90 )
        return true, "/screenshots/" .. fileName .. ".jpg"
    end

    if std.CLIENT then
        --- [CLIENT AND MENU]
        ---
        --- Connects client to the specified server.
        ---@param address string?: The address of the server. ( IP:Port like `127.0.0.1:27015` )
        client.connect = _G.permissions.AskToConnect or function( address ) command_run( "connect", address ) end
    else
        client.connect = _G.JoinServer or _G.permissions.Connect
    end

end

return client
