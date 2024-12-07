local _G = _G
local std = _G.gpm.std
local glua_input, glua_gui, glua_vgui = _G.input, _G.gui, _G.vgui

---@class gpm.std.input
local input = {}

-- TODO: https://wiki.facepunch.com/gmod/input
-- TODO: https://wiki.facepunch.com/gmod/motionsensor
-- TODO: https://wiki.facepunch.com/gmod/gui

do

    ---@clas gpm.std.input.cursor
    local cursor = {
        isVisible = glua_vgui.CursorVisible,
        setVisible = glua_gui.EnableScreenClicker or std.debug.fempty,
        isHoveringWorld = glua_vgui.IsHoveringWorld,
        getPosition = glua_input.GetCursorPos,
        setPosition = glua_input.SetCursorPos
    }

    input.cursor = cursor

end

return input
