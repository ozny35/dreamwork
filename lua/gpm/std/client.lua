local _G = _G
local std = _G.gpm.std

---@class gpm.std.client
local client = {
    openURL = _G.gui.OpenURL
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

    function client.disconnect()
        command_run( "disconnect" )
    end

    function client.retry()
        command_run( "retry" )
    end

    if std.CLIENT then
        function client.connect( address )
            command_run( "connect", address )
        end
    else
        client.connect = _G.JoinServer
    end

end

return client
