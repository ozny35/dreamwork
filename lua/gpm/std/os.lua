local _G = _G

---@class gpm.std
local std = _G.gpm.std

--- [SHARED AND MENU]
---
--- Library for interacting with the operating system.
---
---@class gpm.std.os
---@field name string The name of the operating system.
---@field arch string The architecture of the operating system.
---@field endianness boolean `true` if the operating system is big endianness, `false` if not.
local os = std.os or {}
std.os = os

do

    os.name = std.jit.os
    os.arch = std.jit.arch

    local glua_os = _G.os
    if glua_os == nil then
        error( "os library not found, it's over" )
    end

    ---@cast glua_os oslib

    os.date = os.date or glua_os.date
    os.time = os.time or glua_os.time
    os.clock = os.clock or glua_os.clock
    os.difftime = os.difftime or glua_os.difftime

end

os.endianness = std.string.byte( std.string.dump( std.debug.fempty ), 7 ) == 0x00

if std.MENU then
    os.openFolder = _G.OpenFolder
else
    os.openFolder = std.debug.fempty
end
