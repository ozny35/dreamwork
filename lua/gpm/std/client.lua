local _G = _G
local gpm = _G.gpm
local std = gpm.std
local file = std.file
local path = file.path
local string = std.string
local tonumber = std.tonumber
local glua_render = _G.render

---@class gpm.std.client
---@field ScreenWidth number: The width of the game's window (in pixels).
---@field ScreenHeight number: The height of the game's window (in pixels).
local client = {
    openURL = _G.gui.OpenURL,
    getDXLevel = glua_render.GetDXLevel,
    isSupportsHDR = glua_render.SupportsHDR,
    isSupportsPixelShaders14 = glua_render.SupportsPixelShaders_1_4,
    isSupportsPixelShaders20 = glua_render.SupportsPixelShaders_2_0,
    isSupportsVertexShaders20 = glua_render.SupportsVertexShaders_2_0
}

if std.CLIENT then
    client.getViewEntity = _G.GetViewEntity
    client.getEyeVector = _G.EyeVector
    client.getEyeAngles = _G.EyeAngles
    client.getEyePosition = _G.EyePos
    client.getEntity = _G.LocalPlayer
end

if std.MENU then
    client.isConnected = _G.IsInGame
    client.isConnecting = _G.IsInLoading
else
    --- Checks if the client is connected to the server.<br>
    --- NOTE: It always returns `true` on the client.
    ---@return boolean: `true` if connected, `false` if not.
    function client.isConnected() return true end

    --- Checks if the client has connected to the server (looks at the loading screen).<br>
    --- NOTE: It always returns `false` on the client.
    ---@return boolean: `true` if connecting, `false` if not.
    function client.isConnecting() return false end

end

do

    local command_run = std.console.command.run

    --- Disconnect game from server.
    function client.disconnect()
        return command_run( "disconnect" )
    end

    --- Retry connection to last server.
    function client.retry()
        return command_run( "retry" )
    end

    --- Take a screenshot.
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
        --- Connect to a server.
        ---@param address string: The address of the server.
        function client.connect( address )
            command_run( "connect", address )
        end
    else
        client.connect = _G.JoinServer
    end

end

do

    local width, height = _G.ScrW(), _G.ScrH()

    local screen = {
        width = width,
        height = height
    }

    do

        local hook = std.hook

        hook.add( "OnScreenSizeChanged", gpm.PREFIX .. "::ScreenSize", function( old_width, old_height, new_width, new_height )
            width, height = new_width, new_height
            screen.width, screen.height = new_width, new_height
            hook.run( "ScreenSizeChanged", new_width, new_height, old_width, old_height )
        end, hook.PRE )

    end

    --- Returns the width and height of the game's window (in pixels).
    ---@return number: The width of the game's window (in pixels).
    ---@return number: The height of the game's window (in pixels).
    function screen.getResolution()
        return width, height
    end

    -- https://music.youtube.com/watch?v=78PjJ1soEZk (01:00)
    if std.CLIENT then
        screen.shake = _G.util.ScreenShake
    end

    client.screen = screen

end

return client
