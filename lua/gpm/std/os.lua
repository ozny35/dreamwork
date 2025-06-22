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

-- TODO: think about separate lightweight `time` library for time operations, also port Date class from JS/TS
-- TODO: deprecate os library and move open folder into window library, other remove

if os.timestamp == nil then

    local math_floor = std.math.floor
    local os_clock = os.clock
    local os_time = os.time

    --- [SHARED AND MENU]
    ---
    --- Returns the current timestamp as milliseconds since the Unix epoch.
    ---
    --- **Note:** This is a light wrapper around `os.time() + os.clock() % 1` so it's not as accurate as real ms timestamp, but it's good enough for our needs.
    ---
    ---@return integer timestamp The current timestamp in milliseconds.
    function os.timestamp()
        return math_floor( ( os_time() + os_clock() % 1 ) * 1000 )
    end

end

if os.duration == nil then

    local string_gmatch = std.string.gmatch
    local raw_tonumber = std.raw.tonumber

    ---@type table<string, number>
    local duration_units = {
        ns = 1e-9,
        us = 1e-6,
        ms = 1e-3,
        s = 1,
        m = 60,
        h = 3600,
        d = 86400,
        w = 604800,
        mo = 2592000,
        y = 31536000
    }

    --- [SHARED AND MENU]
    ---
    --- Converts a duration string to a timestamp.
    ---
    --- The duration string can have the following units: `ns`, `us`, `ms`, `s`, `m`, `h`, `d`, `w`, `y`.
    ---
    --- | Suffix | Name         | Value                         |
    --- |--------|--------------|-------------------------------|
    --- | `ns`     | Nanosecond   | 1 / 1,000,000,000 seconds     |
    --- | `us`     | Microsecond  | 1 / 1,000,000 seconds         |
    --- | `ms`     | Millisecond  | 1 / 1,000 seconds             |
    --- | `s`      | Second       | 1 second                      |
    --- | `m`      | Minute       | 60 seconds                    |
    --- | `h`      | Hour         | 60 minutes                    |
    --- | `d`      | Day          | 24 hours                      |
    --- | `w`      | Week         | 7 days                        |
    --- | `mo`     | Month        | ~30 days                      |
    --- | `y`      | Year         | 365 days                      |
    ---
    ---@param duration_str string The duration string (3s, 1m2s, 2y, 10m, etc) to convert.
    ---@return number timestamp The timestamp corresponding to the duration string.
    function os.duration( duration_str )
        local timestamp = 0

        for value, unit in string_gmatch( duration_str, "(%d+%.?%d*)(%l*)" ) do
            local multiplier = duration_units[ unit or "s" ]
            if multiplier == nil then
                error( "unknown duration unit '" .. unit .. "'", 2 )
            else
                timestamp = timestamp + ( raw_tonumber( value, 10 ) or 0 ) * multiplier
            end
        end

        return timestamp
    end

end

-- TODO: move to global constants as ENDIANNESS or something
os.endianness = os.endianness or std.string.byte( std.string.dump( std.debug.fempty ), 7 ) == 0x00

if std.MENU then
    os.openFolder = os.openFolder or _G.OpenFolder or std.debug.fempty
end
