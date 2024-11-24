local _G = _G
local std = _G.gpm.std

--[[

https://wiki.facepunch.com/gmod/Global.DisableClipping



]]

local panel = {}

if std.CLIENT then
    panel.getHUD = _G.GetHUDPanel
end

if std.MENU then
    panel.getOverlay = _G.GetOverlayPanel
end

return panel
