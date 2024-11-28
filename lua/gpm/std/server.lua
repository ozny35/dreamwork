local _G = _G
local std = _G.gpm.std

---@class gpm.std.server
local server = {}

if std.SERVER then
    server.log = _G.ServerLog

    local variable = std.console.variable
    local variable_setString = variable.setString

    --- Gets the download URL of the server.
    ---@return string: The download URL.
    function server.getDownloadURL()
        return variable.getString( "sv_downloadurl" )
    end

    --- Sets the download URL of the server.
    ---@param str string: The download URL to set.
    function server.setDownloadURL( str )
        variable_setString( "sv_downloadurl", str )
    end

    --- Checks if the server allows downloads.
    ---@return boolean: Whether the server allows downloads.
    function server.isDowloadAllowed()
        return variable.getBool( "sv_allowdownload" )
    end

    --- Allow clients to download files from the server.
    ---@param bool boolean: Whether the server allows downloads.
    function server.allowDownload( bool )
        variable.setBool( "sv_allowdownload", bool )
    end

    --- Checks if the server allows uploads.
    ---@return boolean: Whether the server allows uploads.
    function server.isUploadAllowed()
        return variable.getBool( "sv_allowupload" )
    end

    --- Allow clients to upload customizations files to the server.
    ---@param bool boolean: Whether the server allows uploads.
    function server.allowUpload( bool )
        variable.setBool( "sv_allowupload", bool )
    end

end

--[[

    https://wiki.facepunch.com/gmod/serverlist (std.server)
    https://wiki.facepunch.com/gmod/Global.CanAddServerToFavorites
    https://wiki.facepunch.com/gmod/Global.IsServerBlacklisted

    https://wiki.facepunch.com/gmod/permissions (std.server.permissions)

    https://wiki.facepunch.com/gmod/engine.ServerFrameTime

]]

return server
