local _G = _G
local std = _G.gpm.std
local glua_vgui = _G.vgui

--[[

https://wiki.facepunch.com/gmod/Global.DisableClipping

https://wiki.facepunch.com/gmod/vgui

]]

local panel = {
    getMain = glua_vgui.GetWorldPanel,
    getHovered = vgui.GetHoveredPanel
}

if std.CLIENT then
    panel.getHUD = _G.GetHUDPanel
end

if std.MENU then
    panel.getOverlay = _G.GetOverlayPanel
end

return panel
