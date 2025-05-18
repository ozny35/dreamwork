local _G = _G
local gpm = _G.gpm
local std = gpm.std

---@class gpm.std.os
local os = std.os

--- [CLIENT AND MENU]
---
--- The game's os window library.
---
---@class gpm.std.os.window
---@field width number The width of the game's window (in pixels).
---@field height number The height of the game's window (in pixels).
---@field focus boolean `true` if the game's window has focus, `false` otherwise.
local window = os.window or { focus = true }
os.window = window

local width, height = _G.ScrW(), _G.ScrH()
window.width, window.height = width, height

if window.SizeChanged == nil then

    local SizeChanged = std.Hook( "os.window.SizeChanged" )
    window.SizeChanged = SizeChanged

    gpm.engine.hookCatch( "OnScreenSizeChanged", function( old_width, old_height, new_width, new_height )
        width, height = new_width, new_height
        window.width, window.height = new_width, new_height
        SizeChanged( new_width, new_height, old_width, old_height )
    end )

end
