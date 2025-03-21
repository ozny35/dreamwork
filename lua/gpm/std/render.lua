local _G = _G

---@class gpm.std
local std = _G.gpm.std

local glua_render = _G.render

---@class gpm.std.render
local render = std.render or {}
std.render = render

do

    local directx_level = glua_render.GetDXLevel() * 0.1
    render.SupportedDirectX = directx_level
    render.SupportsHDR = directx_level >= 8

end

render.SupportsPixelShadersV1 = glua_render.SupportsPixelShaders_1_4()
render.SupportsPixelShadersV2 = glua_render.SupportsPixelShaders_2_0()
render.SupportedVertexShaders = glua_render.SupportsVertexShaders_2_0()
