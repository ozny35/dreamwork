local _G = _G
local std, glua_os = _G.gpm.std, _G.os

---@class gpm.std.os
local os = {
    name = std.jit.os,
    arch = std.jit.arch,
    clock = glua_os.clock,
    difftime = glua_os.difftime,
    setClipboardText = _G.SetClipboardText
}

do

    local is_host_big_endian = std.string.byte( std.string.dump( std.debug.fempty ), 7 ) == 0x00

    --- [SHARED AND MENU]
    --- Returns the endianness of the current machine.
    ---@return string: The endianness of the current machine.
    function os.endianness()
        return is_host_big_endian and "big" or "little"
    end

end

do

    local has_battery = false
    local level = 100

    --- [SHARED AND MENU]
    --- Returns the current battery level.
    ---@return number: The battery level, between 0 and 100.
    function os.getBatteryLevel()
        return level
    end

    --- [SHARED AND MENU]
    --- Checks if the system has a battery.
    ---@return boolean: `true` if the system has a battery, `false` if not.
    function os.hasBattery()
        return has_battery
    end


    if _G.system then

        local system = _G.system

        os.uptime = system.UpTime
        os.apptime = system.AppTime
        os.country = system.GetCountry

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

local bit = std.bit

do

    local bit_band, bit_rshift = bit.band, bit.rshift
    local glua_os_time = glua_os.time

    --- [SHARED AND MENU]
    --- Converts a DOS date and time to a Unix timestamp.
    ---@param time number The time to convert.
    ---@param date number The date to convert.
    ---@return number seconds The Unix timestamp.
    function os.dos2unix( time, date )
        local data = { year = 1980, month = 1, day = 1, hour = 0, min = 0, sec = 0 }

        if time then
            data.hour = bit_rshift( bit_band( time, 0xF800 ), 11 )
            data.min = bit_rshift( bit_band( time, 0x07E0 ), 5 )
            data.sec = bit_band( time, 0x001F ) * 2
        end

        if date then
            data.year = 1980 + bit_rshift( bit_band( date, 0xFE00 ), 9 )
            data.month = bit_rshift( bit_band( date, 0x01E0 ), 5 )
            data.day = bit_band( date, 0x001F )
        end

        return glua_os_time( data )
    end

    os.time = glua_os_time

end

do

    local bit_bor, bit_lshift = bit.bor, bit.lshift
    local math_fdiv = _G.gpm.std.math.fdiv
    local glua_os_date = glua_os.date

    --- [SHARED AND MENU]
    --- Converts a Unix timestamp to a DOS date and time.
    ---@param seconds number The Unix timestamp to convert.
    ---@return number time The DOS time.
    ---@return number date The DOS date.
    function os.unix2dos( seconds )
        local data = glua_os_date( "*t", seconds )
        ---@diagnostic disable-next-line: param-type-mismatch, return-type-mismatch
        return bit_bor( bit_lshift( data.hour, 11 ), bit_lshift( data.min, 5 ), math_fdiv( data.sec, 2 ) ), bit_bor( bit_lshift( data.year - 1980, 9 ), bit_lshift( data.month, 5 ), data.day )
    end

    os.date = glua_os_date

end

return os
