local _G = _G
local std = _G.gpm.std
local console = std.console
local string_format = std.string.format
local command_run = console.Command.run
local console_Variable = console.Variable
local system_IsWindowed = _G.system.IsWindowed

local width, height = _G.ScrW(), _G.ScrH()

--- [CLIENT AND MENU] The game's client window library.
---@class gpm.std.client.window
---@field width number: The width of the game's window (in pixels).
---@field height number: The height of the game's window (in pixels).
local window = {
    width = width,
    height = height,
}

do

    local glua_system = _G.system
    window.flash = glua_system.FlashWindow
    window.hasFocus = glua_system.HasFocus

end

do

    local hook = std.hook

    hook.add( "OnScreenSizeChanged", gpm.PREFIX .. "::ScreenSize", function( old_width, old_height, new_width, new_height )
        width, height = new_width, new_height
        window.width, window.height = new_width, new_height
        hook.run( "ScreenSizeChanged", new_width, new_height, old_width, old_height )
    end, hook.PRE )

end

--- [CLIENT AND MENU] Returns the width and height of the game's window (in pixels).
---@return number: The width of the game's window (in pixels).
---@return number: The height of the game's window (in pixels).
function window.getSize()
    return width, height
end

--- [CLIENT AND MENU] Changes the resolution and display mode of the game window.
---@param new_width number: The width of the game window.
---@param new_height number: The height of the game window.
function window.setSize( new_width, new_height )
    command_run( string_format( "mat_setvideomode %d %d %d", new_width, new_height, system_IsWindowed() and 1 or 0 ) )
end

window.isWindowed = system_IsWindowed

--- [CLIENT AND MENU] Returns whether the game window is fullscreen.
---@return boolean: `true` if the game window is fullscreen, `false` if not.
function window.getFullscreen()
    return system_IsWindowed() == false
end

--- [CLIENT AND MENU] Sets the fullscreen state of the game window.
---@param value boolean: `true` to set the game window to fullscreen, `false` to set it to windowed.
function window.setFullscreen( value )
    command_run( string_format( "mat_setvideomode %d %d %d", width, height, value == true and 0 or 1 ) )
end

do

    local variable_getBoolean = console_Variable.getBoolean

    --- [CLIENT AND MENU] Returns whether the game is running in VSync mode.
    ---@return boolean: `true` if the game is running in VSync mode, `false` if not.
    function window.getVSync()
        return variable_getBoolean( "mat_vsync" )
    end

end

do

    local Variable_set = console_Variable.set

    --- [CLIENT AND MENU] Sets whether the game is running in VSync mode.
    ---@param value boolean: `true` to enable VSync, `false` to disable it.
    function window.setVSync( value )
        Variable_set( "mat_vsync", value )
    end

end

return window
