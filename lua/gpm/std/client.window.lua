local _G = _G

local gpm = _G.gpm

local std = gpm.std
local console = std.console
local string_format = std.string.format
local command_run = console.Command.run
local console_Variable = console.Variable
local system_IsWindowed = _G.system.IsWindowed

local width, height = _G.ScrW(), _G.ScrH()

--- [CLIENT AND MENU]
---
--- The game's client window library.
---@class gpm.std.client.window
---@field width number The width of the game's window (in pixels).
---@field height number The height of the game's window (in pixels).
---@field focus boolean `true` if the game's window has focus, `false` otherwise.
local window = {
    flash = _G.system.FlashWindow,
    focus = true,
    width = width,
    height = height
}

do

    local system = _G.system
    if system ~= nil and system.HasFocus ~= nil then

        local system_HasFocus = system.HasFocus

        local has_focus = system_HasFocus()
        window.focus = has_focus

        _G.timer.Create( gpm.PREFIX .. " - system.HasFocus", 0.05, 0, function()
            if system_HasFocus() == has_focus then return end
            has_focus = not has_focus
            window.focus = has_focus
        end )

    end

end

do

    local SizeChanged = std.Hook( "client.window.SizeChanged" )
    window.SizeChanged = SizeChanged

    gpm.engine.hookCatch( "OnScreenSizeChanged", function( old_width, old_height, new_width, new_height )
        width, height = new_width, new_height
        window.width, window.height = new_width, new_height
        SizeChanged( new_width, new_height, old_width, old_height )
    end )

end

--- [CLIENT AND MENU]
---
--- Returns the width and height of the game's window (in pixels).
---@return number width The width of the game's window (in pixels).
---@return number height The height of the game's window (in pixels).
function window.getSize()
    return width, height
end

--- [CLIENT AND MENU]
---
--- Changes the resolution and display mode of the game window.
---@param new_width number The width of the game window.
---@param new_height number The height of the game window.
function window.setSize( new_width, new_height )
    command_run( string_format( "mat_setvideomode %d %d %d", new_width, new_height, system_IsWindowed() and 1 or 0 ) )
end

window.isInWindow = system_IsWindowed

--- [CLIENT AND MENU]
---
--- Returns whether the game window is fullscreen.
---@return boolean is_on `true` if the game window is fullscreen, `false` if not.
function window.isInFullscreen()
    return system_IsWindowed() == false
end

--- [CLIENT AND MENU]
---
--- Sets the fullscreen state of the game window.
---@param value boolean `true` to set the game window to fullscreen, `false` to set it to windowed.
function window.setFullscreen( value )
    command_run( string_format( "mat_setvideomode %d %d %d", width, height, value == true and 0 or 1 ) )
end

do

    local variable_getBoolean = console_Variable.getBoolean

    --- [CLIENT AND MENU]
    ---
    --- Returns whether the game is running in VSync mode.
    ---@return boolean is_on `true` if the game is running in VSync mode, `false` if not.
    function window.getVSync()
        return variable_getBoolean( "mat_vsync" )
    end

end

do

    local Variable_set = console_Variable.set

    --- [CLIENT AND MENU]
    ---
    --- Sets whether the game is running in VSync mode.
    ---@param value boolean `true` to enable VSync, `false` to disable it.
    function window.setVSync( value )
        Variable_set( "mat_vsync", value )
    end

end

return window
