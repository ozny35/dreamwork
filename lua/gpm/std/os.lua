local _G = _G

---@type oslib
local glua_os = _G.os

---@class gpm.std
local std = _G.gpm.std

--- [SHARED AND MENU]
---
--- Library for interacting with the operating system.
---
---@class gpm.std.os : oslib
---@field name string The name of the operating system.
---@field arch string The architecture of the operating system.
---@field endianness boolean `true` if the operating system is big endianness, `false` if not.
local os = std.os or {}
std.os = os

do

    local jit = std.jit
    local jit_os = jit.os

    os.name = jit_os
    os.arch = jit.arch

    std.OSX = jit_os == "OSX"
    std.LINUX = jit_os == "Linux"
    std.WINDOWS = jit_os == "Windows"

end

if glua_os == nil then
    error( "os library not found, yep it's over." )
end

os.date = os.date or glua_os.date
os.time = os.time or glua_os.time
os.clock = os.clock or glua_os.clock
os.difftime = os.difftime or glua_os.difftime

os.endianness = os.endianness or std.string.byte( std.string.dump( std.debug.fempty ), 7 ) == 0x00

if std.MENU then
    os.openFolder = os.openFolder or _G.OpenFolder or std.debug.fempty
end
