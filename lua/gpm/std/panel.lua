local _G = _G

---@class gpm.std
local std = _G.gpm.std

local glua_vgui = _G.vgui

--[[

https://wiki.facepunch.com/gmod/Global.DisableClipping

https://wiki.facepunch.com/gmod/vgui

]]

---@alias Panel gpm.std.Panel
---@class gpm.std.Panel : gpm.std.Object
---@field __class gpm.std.PanelClass
local Panel = std.class.base( "Panel" )

---@protected
function Panel:__init()

    -- TODO

end

---@class gpm.std.PanelClass : gpm.std.Panel
---@field __base gpm.std.Panel
---@overload fun(): Panel
local PanelClass = std.class.create( Panel )
std.Panel = PanelClass

local transducers = gpm.transducers

do

    local vgui_GetWorldPanel = glua_vgui.GetWorldPanel

    function PanelClass:getMain()
        return transducers[ vgui_GetWorldPanel() ]
    end

end

do

    local vgui_GetHoveredPanel = glua_vgui.GetHoveredPanel

    function PanelClass:getHovered()
        return transducers[ vgui_GetHoveredPanel() ]
    end

end

if std.CLIENT then

    local GetHUDPanel = _G.GetHUDPanel

    function PanelClass:getHUD()
        return transducers[ GetHUDPanel() ]
    end

end

if std.MENU then

    local GetOverlayPanel = _G.GetOverlayPanel

    function PanelClass:getOverlay()
        return transducers[ GetOverlayPanel() ]
    end

end
