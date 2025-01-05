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

    -- TODO: Add getProgress
    -- TODO: https://github.com/Pika-Software/atmosphere/blob/master/lua/menu/atmosphere/components/loading.lua

    menu.loading = loading

end

do

    local console = std.console
    local command = console.Command
    local console_Variable = console.Variable

    ---@class gpm.std.menu.options
    local options = {}

    --- Gets the master volume.
    ---@return number: The volume, from 0 to 1.
    function options.getMasterVolume()
        return console_Variable.getNumber( "volume" )
    end

    --- Gets the effects volume.
    ---@return number: The volume, from 0 to 1.
    function options.getEffectsVolume()
        return console_Variable.getNumber( "volume_sfx" )
    end

    --- Gets the music volume.
    ---@return number: The volume, from 0 to 1.
    function options.getMusicVolume()
        return console_Variable.getNumber( "snd_musicvolume" )
    end

    --- Gets the HEV suit volume.
    ---@return number: The volume, from 0 to 1.
    function options.getSuitVolume()
        return console_Variable.getNumber( "suitvolume" )
    end

    --- Gets whether to mute the volume when the game loses focus.
    ---@return boolean: Whether to mute the volume.
    function options.getMuteVolumeOnLoseFocus()
        return console_Variable.getBoolean( "snd_mute_losefocus" )
    end

    --- Returns the selected game language.<br>
    --- All language codes https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes.
    ---@return string: ISO 639-1 language code.
    function options.getLanguage()
        return console_Variable.getString( "gmod_language" )
    end

    --- Returns whether the fast weapon switch is enabled.
    ---@return boolean: Whether the fast weapon switch is enabled.
    function options.getFastWeaponSwitch()
        return console_Variable.getBoolean( "hud_fastswitch" )
    end

    --- Returns whether the quick info is enabled.
    ---@return boolean: Whether the quick info is enabled.
    function options.getQuickInfo()
        return console_Variable.getBoolean( "hud_quickinfo" )
    end

    --- Returns whether the crosshair is enabled.
    ---@return boolean: Whether the crosshair is enabled.
    function options.getCrosshair()
        return console_Variable.getBoolean( "crosshair" )
    end

    --- Returns whether the HUD render (health, ammo, etc) is enabled.
    ---@return boolean: Whether the HUD render is enabled.
    function options.getDrawHUD()
        return console_Variable.getBoolean( "cl_drawhud" )
    end

    --- Returns the mouse sensitivity.
    ---@return number: The mouse sensitivity.
    function options.getMouseSensitivity()
        return console_Variable.getNumber( "sensitivity" )
    end

    --- Returns whether the loading URL is enabled.
    ---@return boolean: Whether the loading URL is enabled.
    function options.isCustomLoadingScreenAllowed()
        return console_Variable.getBoolean( "cl_enable_loadingurl" )
    end

    if std.MENU then

        --- Sets the master volume.
        ---@param volume number: The volume to set, from 0 to 1.
        function options.setMasterVolume( volume )
            console_Variable.set( "volume", volume )
        end

        --- Sets the effects volume.
        ---@param volume number: The volume to set, from 0 to 1.
        function options.setEffectsVolume( volume )
            console_Variable.set( "volume_sfx", volume )
        end

        --- Sets the music volume.
        ---@param volume number: The volume to set, from 0 to 1.
        function options.setMusicVolume( volume )
            console_Variable.set( "snd_musicvolume", volume )
        end

        --- Sets the HEV suit volume.
        ---@param volume number: The volume to set, from 0 to 1.
        function options.setSuitVolume( volume )
            console_Variable.set( "suitvolume", volume )
        end

        --- Sets whether to mute the volume when the game loses focus.
        ---@param mute boolean: Whether to mute the volume.
        function options.setMuteVolumeOnLoseFocus( mute )
            console_Variable.set( "snd_mute_losefocus", mute )
        end

        --- Sets the selected game language.<br>
        --- All language codes https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes.
        ---@param language string: ISO 639-1 language code.
        function options.setLanguage( language )
            console_Variable.set( "gmod_language", language )
        end

        --- Sets whether the fast weapon switch is enabled.
        ---@param value boolean: Whether the fast weapon switch is enabled.
        function options.setFastWeaponSwitch( value )
            console_Variable.set( "hud_fastswitch", value )
        end

        --- Sets whether the quick info is enabled.
        ---@param value boolean: Whether the quick info is enabled.
        function options.setQuickInfo( value )
            console_Variable.set( "hud_quickinfo", value )
        end

        --- Sets whether the crosshair is enabled.
        ---@param value boolean: Whether the crosshair is enabled.
        function options.setCrosshair( value )
            console_Variable.set( "crosshair", value )
        end

        --- Sets whether the HUD render (health, ammo, etc) is enabled.
        ---@param value boolean: Whether the HUD render is enabled.
        function options.setDrawHUD( value )
            console_Variable.set( "cl_drawhud", value )
        end

        --- Sets the mouse sensitivity.
        ---@param value number: The mouse sensitivity.
        function options.setMouseSensitivity( value )
            console_Variable.set( "sensitivity", value )
        end

        --- Sets whether the loading URL is enabled.
        ---@param value boolean: Whether the loading URL is enabled.
        function options.allowCustomLoadingScreen( value )
            console_Variable.set( "cl_enable_loadingurl", value )
        end

        --- Changes the resolution and display mode of the game window.
        ---@param width number: The width of the game window.
        ---@param height number: The height of the game window.
        ---@param windowed boolean: Whether the game window is windowed.
        function options.setScreenResolution( width, height, windowed )
            command.run( "mat_setvideomode", width, height, windowed and 1 or 0 )
        end

        --[[

            - gmod_unload_test: Unload materials and models on disconnect. Unstable. Use at your own risk.

            - gmod_mcore_test

            - gmod_delete_temp_files: Delete temporary files downloaded from servers such as sprays.

            - fs_tellmeyoursecrets: Causes the Filesystem to print every action.

        ]]

        --- Opens the options dialog.
        function options.open()
            RunGameUICommand( "OpenOptionsDialog" )
        end

    end

    menu.options = options

end

return menu
