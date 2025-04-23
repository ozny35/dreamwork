local _G = _G

---@class gpm.std
local std = _G.gpm.std

--- [SHARED AND MENU]
---
--- Library for interacting with the operating system.
---
---@class gpm.std.os
local os = std.os or {}
std.os = os

do

    os.name = std.jit.os
    os.arch = std.jit.arch

    local glua_os = _G.os
    if glua_os == nil then
        std.error( "os library not found" )
    end

    ---@cast glua_os oslib

    os.date = os.date or glua_os.date
    os.time = os.time or glua_os.time
    os.clock = os.clock or glua_os.clock
    os.difftime = os.difftime or glua_os.difftime

end

do

    local is_host_big_endian = std.string.byte( std.string.dump( std.debug.fempty ), 7 ) == 0x00

    --- [SHARED AND MENU]
    ---
    --- Returns the endianness of the current machine.
    ---
    ---@return string: The endianness of the current machine.
    function os.endianness()
        return is_host_big_endian and "big" or "little"
    end

end

do

    local has_battery = false
    local level = 100

    --- [SHARED AND MENU]
    ---
    --- Returns the current battery level.
    ---
    ---@return number: The battery level, between 0 and 100.
    function os.getBatteryLevel()
        return level
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the system has a battery.
    ---
    ---@return boolean: `true` if the system has a battery, `false` if not.
    function os.hasBattery()
        return has_battery
    end

    if _G.system ~= nil then
        local system = _G.system

        os.country = os.country or system.GetCountry

        if system.BatteryPower ~= nil then

            local system_BatteryPower = system.BatteryPower

            local function update_battery()
                local battery_power = system_BatteryPower()
                has_battery = battery_power ~= 255
                level = has_battery and battery_power or 100
            end

            update_battery()

            _G.timer.Create( gpm.PREFIX .. " - system.BatteryPower", 1, 0, update_battery )

        end

    end

end

if std.MENU then
    os.openFolder = _G.OpenFolder
else
    os.openFolder = std.debug.fempty
end

return os
