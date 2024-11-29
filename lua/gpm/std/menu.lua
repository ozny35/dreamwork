local _G = _G
local std = _G.gpm.std
local glua_gui = _G.gui

---@class gpm.std.menu
local menu = {
    isVisible = glua_gui.IsGameUIVisible,
    open = glua_gui.ActivateGameUI,
    ---@diagnostic disable-next-line: deprecated
    close = glua_gui.HideGameUI or std.debug.fempty,
    openURL = glua_gui.OpenURL
}

if std.MENU then

    menu.getWorkshopStatus = _G.GetAddonStatus

    local RunGameUICommand = _G.RunGameUICommand
    menu.runCommand = RunGameUICommand

    --- Closes the menu and returns to the game.
    function menu.resume()
        RunGameUICommand( "ResumeGame" )
    end

    --- Opens the legacy server browser.
    function menu.openServerBrowser()
        RunGameUICommand( "OpenServerBrowser" )
    end

    --- Opens the Source "Load Game" dialog.
    function menu.openGameLoadDialog()
        RunGameUICommand( "OpenLoadGameDialog" )
    end

    --- Opens the Source "Save Game" dialog.
    function menu.openGameSaveDialog()
        RunGameUICommand( "OpenSaveGameDialog" )
    end

    --- Opens the "Mute Players" dialog that shows all players connected to the server and allows to mute them.
    function menu.openPlayerList()
        RunGameUICommand( "OpenPlayerListDialog" )
    end

    --- Disconnects from the current server.
    function menu.disconnect()
        RunGameUICommand( "Disconnect" )
    end

    --- Quits the game.
    ---@param noConfirm boolean: Whether to skip the confirmation prompt.
    --- NOTE: confirmation dialog is broken in Garry's mod and `noConfirm` do nothing.
    function menu.quit( noConfirm )
        RunGameUICommand( noConfirm and "QuitNoConfirm" or "Quit" )
    end

    ---@class gpm.std.menu.loading
    local loading = {
        getDefaultURL = _G.GetDefaultLoadingHTML,
        getFileCount = _G.NumDownloadables,
        getFiles = _G.GetDownloadables,
        getStatus = _G.GetLoadStatus,
        cancel = _G.CancelLoading,
    }

    menu.loading = loading

end

do

    local variable = std.console.variable

    ---@class gpm.std.menu.options
    local options = {}

    --- Gets the master volume.
    ---@return number: The volume, from 0 to 1.
    function options.getMasterVolume()
        return variable.getFloat( "volume" )
    end

    --- Gets the effects volume.
    ---@return number: The volume, from 0 to 1.
    function options.getEffectsVolume()
        return variable.getFloat( "volume_sfx" )
    end

    --- Gets the music volume.
    ---@return number: The volume, from 0 to 1.
    function options.getMusicVolume()
        return variable.getFloat( "snd_musicvolume" )
    end

    --- Gets the HEV suit volume.
    ---@return number: The volume, from 0 to 1.
    function options.getSuitVolume()
        return variable.getFloat( "suitvolume" )
    end

    --- Gets whether to mute the volume when the game loses focus.
    ---@return boolean: Whether to mute the volume.
    function options.getMuteVolumeOnLoseFocus()
        return variable.getBool( "snd_mute_losefocus" )
    end

    --- Returns the selected game language.<br>
    --- All language codes https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes.
    ---@return string: ISO 639-1 language code.
    function options.getLanguage()
        return variable.getString( "gmod_language" )
    end

    --- Returns whether the fast weapon switch is enabled.
    ---@return boolean: Whether the fast weapon switch is enabled.
    function options.getFastWeaponSwitch()
        return variable.getBool( "hud_fastswitch" )
    end

    --- Returns whether the quick info is enabled.
    ---@return boolean: Whether the quick info is enabled.
    function options.getQuickInfo()
        return variable.getBool( "hud_quickinfo" )
    end

    --- Returns whether the crosshair is enabled.
    ---@return boolean: Whether the crosshair is enabled.
    function options.getCrosshair()
        return variable.getBool( "crosshair" )
    end

    --- Returns whether the HUD render (health, ammo, etc) is enabled.
    ---@return boolean: Whether the HUD render is enabled.
    function options.getDrawHUD()
        return variable.getBool( "cl_drawhud" )
    end

    --- Returns the mouse sensitivity.
    ---@return number: The mouse sensitivity.
    function options.getMouseSensitivity()
        return variable.getFloat( "sensitivity" )
    end

    --- Returns whether the loading URL is enabled.
    ---@return boolean: Whether the loading URL is enabled.
    function options.isCustomLoadingScreenAllowed()
        return variable.getBool( "cl_enable_loadingurl" )
    end

    if std.MENU then

        --- Sets the master volume.
        ---@param volume number: The volume to set, from 0 to 1.
        function options.setMasterVolume( volume )
            variable.setFloat( "volume", volume )
        end

        --- Sets the effects volume.
        ---@param volume number: The volume to set, from 0 to 1.
        function options.setEffectsVolume( volume )
            variable.setFloat( "volume_sfx", volume )
        end

        --- Sets the music volume.
        ---@param volume number: The volume to set, from 0 to 1.
        function options.setMusicVolume( volume )
            variable.setFloat( "snd_musicvolume", volume )
        end

        --- Sets the HEV suit volume.
        ---@param volume number: The volume to set, from 0 to 1.
        function options.setSuitVolume( volume )
            variable.setFloat( "suitvolume", volume )
        end

        --- Sets whether to mute the volume when the game loses focus.
        ---@param mute boolean: Whether to mute the volume.
        function options.setMuteVolumeOnLoseFocus( mute )
            variable.setBool( "snd_mute_losefocus", mute )
        end

        --- Sets the selected game language.<br>
        --- All language codes https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes.
        ---@param language string: ISO 639-1 language code.
        function options.setLanguage( language )
            variable.setString( "gmod_language", language )
        end

        --- Sets whether the fast weapon switch is enabled.
        ---@param value boolean: Whether the fast weapon switch is enabled.
        function options.setFastWeaponSwitch( value )
            variable.setBool( "hud_fastswitch", value )
        end

        --- Sets whether the quick info is enabled.
        ---@param value boolean: Whether the quick info is enabled.
        function options.setQuickInfo( value )
            variable.setBool( "hud_quickinfo", value )
        end

        --- Sets whether the crosshair is enabled.
        ---@param value boolean: Whether the crosshair is enabled.
        function options.setCrosshair( value )
            variable.setBool( "crosshair", value )
        end

        --- Sets whether the HUD render (health, ammo, etc) is enabled.
        ---@param value boolean: Whether the HUD render is enabled.
        function options.setDrawHUD( value )
            variable.setBool( "cl_drawhud", value )
        end

        --- Sets the mouse sensitivity.
        ---@param value number: The mouse sensitivity.
        function options.setMouseSensitivity( value )
            variable.setFloat( "sensitivity", value )
        end

        --- Sets whether the loading URL is enabled.
        ---@param value boolean: Whether the loading URL is enabled.
        function options.allowCustomLoadingScreen( value )
            variable.setBool( "cl_enable_loadingurl", value )
        end

    end

    if std.MENU then
        --- Opens the options dialog.
        function options.open()
            RunGameUICommand( "OpenOptionsDialog" )
        end
    end

    menu.options = options

end

return menu
