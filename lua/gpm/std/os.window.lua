local _G = _G
local gpm = _G.gpm
local std = gpm.std

---@class gpm.std.os
local os = std.os

--- [CLIENT AND MENU]
---
--- The game's os window library.
---@class gpm.std.os.window
---@field width number The width of the game's window (in pixels).
---@field height number The height of the game's window (in pixels).
---@field focus boolean `true` if the game's window has focus, `false` otherwise.
local window = os.window or { focus = true }
os.window = window

local width, height = _G.ScrW(), _G.ScrH()
window.width, window.height = width, height

local glua_system = _G.system
if glua_system == nil then
    local debug_fempty = std.debug.fempty
    window.isWindowed = debug_fempty
    window.flash = debug_fempty
else

    window.isWindowed = window.isWindowed or glua_system.IsWindowed or std.debug.fempty
    window.flash = window.flash or glua_system.FlashWindow or std.debug.fempty

    if glua_system.HasFocus ~= nil then

        local system_HasFocus = glua_system.HasFocus

        local has_focus = system_HasFocus()
        window.focus = has_focus

        _G.timer.Create( gpm.PREFIX .. " - system.HasFocus", 0.05, 0, function()
            if system_HasFocus() == has_focus then return end
            has_focus = not has_focus
            window.focus = has_focus
        end )

    end

end

if window.isFullscreen == nil then

    local system_IsWindowed = window.isWindowed

    --- [CLIENT AND MENU]
    ---
    --- Returns whether the game window is fullscreen.
    ---@return boolean is_on `true` if the game window is fullscreen, `false` if not.
    function window.isFullscreen()
        return not system_IsWindowed()
    end

end

if window.SizeChanged == nil then

    local SizeChanged = std.Hook( "os.window.SizeChanged" )
    window.SizeChanged = SizeChanged

    gpm.engine.hookCatch( "OnScreenSizeChanged", function( old_width, old_height, new_width, new_height )
        width, height = new_width, new_height
        window.width, window.height = new_width, new_height
        SizeChanged( new_width, new_height, old_width, old_height )
    end )

end
