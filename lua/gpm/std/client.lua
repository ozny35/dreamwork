local _G = _G
local gpm = _G.gpm
local std = gpm.std
local File = std.File
local path = File.path
local string = std.string
local tonumber = std.tonumber
local glua_render = _G.render

--- [CLIENT AND MENU] The game's client library.
---@class gpm.std.client
local client = {
    openURL = _G.gui.OpenURL,
    getDXLevel = glua_render.GetDXLevel,
    isSupportsHDR = glua_render.SupportsHDR,
    isSupportsPixelShaders14 = glua_render.SupportsPixelShaders_1_4,
    isSupportsPixelShaders20 = glua_render.SupportsPixelShaders_2_0,
    isSupportsVertexShaders20 = glua_render.SupportsVertexShaders_2_0
}

if std.CLIENT then
    local LocalPlayer = _G.LocalPlayer
    client.getEntity = LocalPlayer

    -- https://music.youtube.com/watch?v=78PjJ1soEZk (01:00)
    client.screenShake = _G.util.ScreenShake
    client.getViewEntity = _G.GetViewEntity
    client.getEyeVector = _G.EyeVector
    client.getEyeAngles = _G.EyeAngles
    client.getEyePosition = _G.EyePos

    do

        local voice_chat_state = false

        -- TODO: replace with new hook system
        -- local hook = std.hook
        -- hook.add( "PlayerStartVoice", "client.getVoiceChat", function( ply )
        --     if ply ~= LocalPlayer() then return end
        --     voice_chat_state = true
        -- end, hook.PRE )

        -- hook.add( "PlayerEndVoice", "client.getVoiceChat", function( ply )
        --     if ply ~= LocalPlayer() then return end
        --     voice_chat_state = true
        -- end, hook.PRE )

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

    --- [CLIENT AND MENU] Checks if the client is connected to the server.
    ---
    --- NOTE: It always returns `true` on the client.
    ---@return boolean: `true` if connected, `false` if not.
    function client.isConnected() return true end

    --- [CLIENT AND MENU] Checks if the client has connected to the server (looks at the loading screen).
    ---
    --- NOTE: It always returns `false` on the client.
    ---@return boolean: `true` if connecting, `false` if not.
    function client.isConnecting() return false end

end

do

    local command_run = std.console.Command.run

    --- [CLIENT AND MENU] Disconnect game from server.
    function client.disconnect()
        command_run( "disconnect" )
    end

    --- [CLIENT AND MENU] Retry connection to last server.
    function client.retry()
        command_run( "retry" )
    end

    --- [CLIENT AND MENU] Take a screenshot.
    ---@param quality integer: The quality of the screenshot (0-100), only used if `useTGA` is `false`.
    ---@param fileName string: The name of the screenshot.
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
            count = ( tonumber( string.sub( path.stripExtension( last_one, false ), #fileName + 2 ), 10 ) or 0 ) + 1
        end

        fileName = string.format( "%s_%04d", fileName, count )
        command_run( "jpeg", fileName, quality or 90 )
        return true, "/screenshots/" .. fileName .. ".jpg"
    end

    if std.CLIENT then
        --- [CLIENT AND MENU] Connects client to the specified server.
        ---@param address string?: The address of the server. ( IP:Port like `127.0.0.1:27015` )
        client.connect = _G.permissions.AskToConnect or function( address ) command_run( "connect", address ) end
    else
        client.connect = _G.JoinServer or _G.permissions.Connect
    end

end

---@class gpm.std.client.window
client.window = include( "client.window.lua" )

return client
