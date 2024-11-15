local _G = _G
local glua_os, system, jit, bit = _G.os, _G.system, _G.jit, _G.bit
local glua_os_time, glua_os_date = glua_os.time, glua_os.date

---@class gpm.std.os
local os = {
    ["arch"] = jit.arch,
    ["name"] = jit.os,
    ["date"] = glua_os_date,
    ["time"] = glua_os_time,
    ["clock"] = glua_os.clock,
    ["difftime"] = glua_os.difftime,
    ["flashWindow"] = system.FlashWindow,
    ["battery"] = system.BatteryPower,
    ["steamTime"] = system.SteamTime,
    ["country"] = system.GetCountry,
    ["hasFocus"] = system.HasFocus,
    ["appTime"] = system.AppTime,
    ["uptime"] = system.UpTime
}

do

    local bit_band, bit_rshift = bit.band, bit.rshift

    ---Converts a DOS date and time to a Unix timestamp.
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

end

do

    local bit_bor, bit_lshift = bit.bor, bit.lshift
    local math_fdiv = _G.gpm.std.math.fdiv

    ---Converts a Unix timestamp to a DOS date and time.
    ---@param seconds number The Unix timestamp to convert.
    ---@return number time The DOS time.
    ---@return number date The DOS date.
    function os.unix2dos( seconds )
        local data = glua_os_date( "*t", seconds )
        ---@diagnostic disable-next-line: param-type-mismatch
        return bit_bor( bit_lshift( data.hour, 11 ), bit_lshift( data.min, 5 ), math_fdiv( data.sec, 2 ) ), bit_bor( bit_lshift( data.year - 1980, 9 ), bit_lshift( data.month, 5 ), data.day )
    end

end

return os
